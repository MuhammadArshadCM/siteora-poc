/**
 * Rule resolver: port of tools/evaluate.py (scope -> conditions -> precedence -> value).
 * Keep this file behaviourally identical to the Python reference; parity/ checks it.
 */
import { Db, lit } from "./db.js";
import { contains, eq, pyRound, truthy } from "./py.js";

/** A fact that is not known (distinct from a fact whose value is null). */
export const UNKNOWN: unique symbol = Symbol("UNKNOWN");
export type Unknown = typeof UNKNOWN;
export type Facts = Record<string, any>;

export interface Scope { level: string; lg?: string | null; zone?: string | null; precinct?: string | null; overlay?: string | null;
  local_plan?: string | null; local_plan_precinct?: string | null; exclude: boolean }
export interface Subject { id: string; exclude: boolean }
export interface Condition { group: number; fact: string; op: string; value: any }
export interface Source { ref: string; role: string; page?: string | null; url?: string | null; quote?: string | null; text?: string | null }
export interface Rule {
  rule_version_id: string; rule_id: string; topic: string; title: string; instrument_version_id: string; role: string; regime: string;
  enforceability: string; measurement_id: string | null; operator: string | null; value_expr: any; unit: string | null;
  permits_btb: boolean | null; on_noncompliance: string | null; verification: string; automatable: boolean;
  interpretation_notes: string | null; instrument: string; version_label: string;
  scopes: Scope[] | null; subjects: Subject[] | null; conditions: Condition[] | null; sources: Source[] | null; _via?: string;
}
export interface Relationship { from: string; to_rv: string | null; to_rule: string | null; type: string }
export interface Site { lg: string; zone?: string | null; precincts?: string[]; local_plans?: string[]; local_plan_precincts?: string[]; overlays?: string[] }
export interface Scenario {
  title?: string; assessment_date: string; site: Site; facts?: Facts;
  structures: { label: string; structure_type: string; facts?: Facts; boundaries?: { boundary_type: string }[] }[];
}
export interface Loaded { activeIvs: Set<string>; rules: Rule[]; rels: Relationship[]; parents: Record<string, string | null>; boundaryMeas: Set<string> }

// ----------------------------------------------------------------------------- data access
export async function load(db: Db, lg: string, date: string): Promise<Loaded> {
  const d = `'${date}'::date`;
  const activeIvs = await db.q<string[]>(`
      SELECT coalesce(json_agg(DISTINCT iv.instrument_version_id), '[]') FROM regs.instrument_versions iv
      WHERE (EXISTS (SELECT 1 FROM regs.instrument_applicability a WHERE a.instrument_version_id = iv.instrument_version_id
                      AND (a.lg_id IS NULL OR a.lg_id = ${lit(lg)}) AND a.effective_from <= ${d}
                      AND (a.effective_to IS NULL OR a.effective_to >= ${d})))
         OR (NOT EXISTS (SELECT 1 FROM regs.instrument_applicability a WHERE a.instrument_version_id = iv.instrument_version_id)
             AND coalesce(iv.effective_from, '1900-01-01') <= ${d} AND (iv.effective_to IS NULL OR iv.effective_to >= ${d}))`);
  const rules = await db.q<Rule[]>(`
      SELECT coalesce(json_agg(r), '[]') FROM (
        SELECT rv.rule_version_id, rv.rule_id, ru.topic, ru.title, rv.instrument_version_id, rv.role, rv.regime,
               rv.enforceability, rv.measurement_id, rv.operator, rv.value_expr, rv.unit, rv.permits_btb,
               rv.on_noncompliance, rv.verification, rv.automatable, rv.interpretation_notes,
               i.title AS instrument, iv.version_label,
               (SELECT json_agg(json_build_object('level', s.level, 'lg', s.lg_id, 'zone', s.zone_id, 'precinct', s.precinct_id,
                        'overlay', s.overlay_id, 'local_plan', s.local_plan_id, 'local_plan_precinct', s.local_plan_precinct_id,
                        'exclude', s.exclude)) FROM regs.rule_scopes s
                 WHERE s.rule_version_id = rv.rule_version_id) AS scopes,
               (SELECT json_agg(json_build_object('id', s.structure_type_id, 'exclude', s.exclude)) FROM regs.rule_subjects s
                 WHERE s.rule_version_id = rv.rule_version_id) AS subjects,
               (SELECT json_agg(json_build_object('group', c.group_no, 'fact', c.fact_id, 'op', c.operator, 'value', c.value))
                  FROM regs.rule_conditions c WHERE c.rule_version_id = rv.rule_version_id) AS conditions,
               (SELECT json_agg(json_build_object('ref', p.ref_label, 'role', s.role, 'page', p.page_label, 'url', coalesce(p.url_anchor, iv2.source_url), 'quote', s.quote, 'text', p.verbatim_text))
                  FROM regs.rule_sources s JOIN regs.provisions p USING (provision_id)
                  JOIN regs.instrument_versions iv2 ON iv2.instrument_version_id = p.instrument_version_id
                 WHERE s.rule_version_id = rv.rule_version_id) AS sources
        FROM regs.rule_versions rv JOIN regs.rules ru USING (rule_id)
        JOIN regs.instrument_versions iv ON iv.instrument_version_id = rv.instrument_version_id
        JOIN regs.instruments i ON i.instrument_id = iv.instrument_id
        WHERE rv.status = 'ACTIVE' AND rv.effective_from <= ${d} AND (rv.effective_to IS NULL OR rv.effective_to >= ${d})) r`);
  const rels = await db.q<Relationship[]>(`SELECT coalesce(json_agg(json_build_object('from', from_rule_version_id, 'to_rv', to_rule_version_id,
                           'to_rule', to_rule_id, 'type', type)), '[]') FROM regs.rule_relationships`);
  const parents = Object.fromEntries(await db.q<[string, string | null][]>(
    "SELECT coalesce(json_agg(json_build_array(structure_type_id, parent_id)), '[]') FROM regs.structure_types"));
  const boundaryMeas = new Set(await db.q<string[]>(`SELECT coalesce(json_agg(measurement_id), '[]') FROM regs.measurements
                                      WHERE (reference_geometry LIKE 'BOUNDARY%' OR reference_geometry = 'COMMON_BOUNDARY')
                                        AND reference_geometry <> 'BOUNDARY_ADJOINING_CANAL_OR_LAKE'`));
  return { activeIvs: new Set(activeIvs), rules, rels, parents, boundaryMeas };
}

// ----------------------------------------------------------------------------- expression language
const get = (facts: Facts, k: string): any => (Object.prototype.hasOwnProperty.call(facts, k) ? facts[k] : UNKNOWN);

/** Evaluate an expression AST. Returns a value, null (no value) or UNKNOWN (missing fact). */
export function ev(e: any, facts: Facts): any {
  if (e === null || e === undefined || typeof e === "number" || typeof e === "string" || typeof e === "boolean") return e ?? null;
  if ("var" in e) return get(facts, e.var);
  const op: string = e.op;
  if (op === "unencoded") return null;
  if (op === "case") {
    for (const w of e.when) {
      const c = ev(w.if, facts);
      if (c === UNKNOWN) return UNKNOWN;
      if (truthy(c)) return ev(w.then, facts);
    }
    return ev(e.else ?? null, facts);
  }
  if (op === "switch") {
    const k = ev(e.on, facts);
    if (k === UNKNOWN) return UNKNOWN;
    const cases = e.cases ?? {};
    // JSON object keys are strings: like Python's dict.get, only a string value can select a case
    const hit = typeof k === "string" && Object.prototype.hasOwnProperty.call(cases, k);
    return ev(hit ? cases[k as string] : (e.default ?? null), facts);
  }
  if (op === "interpolate") {
    const x = ev(e.x, facts);
    if (x === UNKNOWN) return UNKNOWN;
    const [x0, y0] = e.points[0], [x1, y1] = e.points[e.points.length - 1];
    if (!(x0 <= x && x <= x1)) return null;
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
  }
  if (op === "lookup_range") {
    let x = ev(e.x, facts);
    if (x === UNKNOWN) return UNKNOWN;
    x = pyRound(x, 3);
    for (const r of e.rows) if ((r.min ?? -Infinity) <= x && x <= (r.max ?? Infinity)) return r.value;
    return null;
  }
  const args = (e.args as any[]).map((a) => ev(a, facts));
  if (args.some((a) => a === UNKNOWN)) return UNKNOWN;
  if (args.some((a) => a === null)) return null;
  if (op === "min_of") return Math.min(...args[0]);
  if (op === "max_of") return Math.max(...args[0]);
  if (op === "avg_of") return (args[0] as number[]).reduce((s, v) => s + v, 0) / args[0].length;
  switch (op) {
    case "+": return args[0] + args[1];
    case "-": return args[0] - args[1];
    case "*": return args[0] * args[1];
    case "/": return args[0] / args[1];
    case "<=": return args[0] <= args[1];
    case "<": return args[0] < args[1];
    case ">=": return args[0] >= args[1];
    case ">": return args[0] > args[1];
    case "=": return eq(args[0], args[1]);
    case "ceil": return Math.ceil(args[0]);
    case "is_true": return truthy(args[0]);
    case "min": return Math.min(...args);
    case "max": return Math.max(...args);
  }
  throw new Error(`unknown operator ${op}`);
}

export function cond(c: Condition, facts: Facts): boolean | Unknown {
  const v = get(facts, c.fact);
  const want = c.value;
  if (c.op === "IS_NULL") return v === UNKNOWN || v === null;
  if (c.op === "IS_NOT_NULL") return !(v === UNKNOWN || v === null);
  if (v === UNKNOWN) return UNKNOWN;
  switch (c.op) {
    case "IS_TRUE": return v === true;
    case "IS_FALSE": return v === false;
    case "=": return eq(v, want);
    case "<>": return !eq(v, want);
    case ">=": return v >= want;
    case ">": return v > want;
    case "<=": return v <= want;
    case "<": return v < want;
    case "IN": return contains(want, v);
    case "NOT_IN": return !contains(want, v);
  }
  throw new Error(`unknown condition operator ${c.op}`);
}

/** DNF: true / false / UNKNOWN. */
export function conditionsHold(rule: Rule, facts: Facts): boolean | Unknown {
  const groups = new Map<number, Condition[]>();
  for (const c of rule.conditions ?? []) {
    if (!groups.has(c.group)) groups.set(c.group, []);
    groups.get(c.group)!.push(c);
  }
  if (!groups.size) return true;
  let anyUnknown = false;
  for (const cs of groups.values()) {
    const rs = cs.map((c) => cond(c, facts));
    if (rs.every((r) => r === true)) return true;
    if (!rs.some((r) => r === false)) anyUnknown = true;
  }
  return anyUnknown ? UNKNOWN : false;
}

// ----------------------------------------------------------------------------- scope / subject matching
export function ancestors(st: string | null, parents: Record<string, string | null>): string[] {
  const out: string[] = [];
  while (st) {
    out.push(st);
    st = parents[st] ?? null;
  }
  return out;
}

export function subjectMatches(rule: { subjects: Subject[] | null }, structure: string, parents: Record<string, string | null>): boolean {
  const chain = ancestors(structure, parents);
  const subs = rule.subjects ?? [];
  if (subs.some((s) => s.exclude && chain.includes(s.id))) return false;
  return subs.some((s) => !s.exclude && chain.includes(s.id));
}

const GROUPS: Record<string, string> = { LOCAL_GOVERNMENT: "lg", PLANNING_SCHEME: "lg", ZONE: "place", PRECINCT: "place",
  LOCAL_PLAN: "place", LOCAL_PLAN_PRECINCT: "place", OVERLAY: "overlay", STATE: "state" };

/** LG rows must match; place rows are alternatives; overlay rows are alternatives and must also match; a matching exclude removes the rule. */
export function scopeMatches(rule: { scopes: Scope[] | null }, site: Site): boolean {
  const scopes = rule.scopes && rule.scopes.length ? rule.scopes : [{ level: "STATE", exclude: false } as Scope];
  const hit = (s: Scope): boolean => {
    switch (s.level) {
      case "STATE": return true;
      case "LOCAL_GOVERNMENT": case "PLANNING_SCHEME": return s.lg === site.lg;
      case "ZONE": return (s.zone ?? null) === (site.zone ?? null);
      case "PRECINCT": return (site.precincts ?? []).includes(s.precinct as string);
      case "LOCAL_PLAN": return (site.local_plans ?? []).includes(s.local_plan as string);
      case "LOCAL_PLAN_PRECINCT": return (site.local_plan_precincts ?? []).includes(s.local_plan_precinct as string);
      case "OVERLAY": return (site.overlays ?? []).includes(s.overlay as string);
      default: return false;
    }
  };
  const includes = new Map<string, boolean[]>();
  for (const s of scopes) {
    const h = hit(s);
    if (s.exclude) {
      if (h) return false;
      continue;
    }
    const g = GROUPS[s.level] ?? s.level;
    if (!includes.has(g)) includes.set(g, []);
    includes.get(g)!.push(h);
  }
  return [...includes.values()].every((v) => v.some(Boolean));
}

// ----------------------------------------------------------------------------- resolution
export interface Result {
  structure: string; boundary: string | null; regime: string; topic: string; rule: string; state: string;
  title?: string; role?: string; measurement?: string | null; operator?: string | null; required?: any; unit?: string | null;
  on_noncompliance?: string | null; instrument?: string; sources?: string[]; source_detail?: Source[];
  interpretation_notes?: string | null; via?: string | null; why?: string;
}

export async function resolve(db: Db, scenario: Scenario, loaded?: Loaded): Promise<Result[]> {
  const site = scenario.site;
  const { activeIvs, rules, rels, parents, boundaryMeas } = loaded ?? await load(db, site.lg, scenario.assessment_date);
  return resolveWith({ activeIvs, rules, rels, parents, boundaryMeas }, scenario);
}

export function resolveWith(L: Loaded, scenario: Scenario): Result[] {
  const { activeIvs, rules, rels, parents, boundaryMeas } = L;
  const site = scenario.site;
  const byRv = new Map(rules.map((r) => [r.rule_version_id, r]));
  const results: Result[] = [];
  for (const item of scenario.structures) {
    const structure = item.structure_type;
    // one lot-level pass (height, site cover, size, barrier) + one pass per boundary (setbacks)
    const contexts: Record<string, any>[] = [{ boundary_type: null }, ...(item.boundaries ?? [])];
    const baseFacts = { ...(scenario.facts ?? {}), ...(item.facts ?? {}) };
    for (const ctx of contexts) {
      const facts = { ...baseFacts, ...ctx };
      const cand = new Map<string, Rule>();
      const status = new Map<string, boolean | Unknown>();
      const boundary: string | null = ctx.boundary_type ?? null;
      const lotPass = boundary === null;
      for (const r of rules) {
        if (!activeIvs.has(r.instrument_version_id) || !scopeMatches(r, site)) continue;
        if ((r.role === "REQUIREMENT" || r.role === "RELAXATION") && boundaryMeas.has(r.measurement_id as string) === lotPass) continue;
        if (!subjectMatches(r, structure, parents)) continue;
        const h = conditionsHold(r, facts);
        status.set(r.rule_version_id, h);
        if (h !== false) cand.set(r.rule_version_id, r);
      }
      // FALLS_BACK_TO: a listed row whose limits are exceeded hands the subject to the target row
      for (const rel of rels) {
        if (rel.type === "FALLS_BACK_TO" && status.get(rel.from) === false && rel.to_rv && byRv.has(rel.to_rv)) {
          const t = byRv.get(rel.to_rv)!;
          if (activeIvs.has(t.instrument_version_id) && conditionsHold(t, facts) !== false && !cand.has(t.rule_version_id))
            cand.set(t.rule_version_id, { ...t, _via: `falls back from ${rel.from}` });
        }
      }
      const removed = new Map<string, string>();
      for (const rel of rels) {
        if (!cand.has(rel.from)) continue;
        const targets = [...cand.entries()].filter(([rv, r]) => rv === rel.to_rv || r.rule_id === rel.to_rule).map(([rv]) => rv);
        if (rel.type === "OVERRIDES" || rel.type === "REPLACES" || (rel.type === "EXEMPTS" && status.get(rel.from) === true))
          for (const t of targets) removed.set(t, `${rel.type} by ${rel.from}`);
        if (rel.type === "RELAXES" && status.get(rel.from) === true)
          for (const t of targets) removed.set(t, `RELAXED by ${rel.from}`);
      }
      const live = [...cand.entries()].filter(([rv, r]) => !removed.has(rv) && (r.role === "REQUIREMENT" || r.role === "RELAXATION")).map(([, r]) => r);
      const unresolved = new Map<string, string>();
      const liveIds = new Set(live.map((r) => r.rule_version_id));
      for (const rel of rels) {
        if (rel.type !== "UNRESOLVED" || !liveIds.has(rel.from)) continue;
        for (const r of live) {
          if (r.rule_version_id === rel.to_rv || r.rule_id === rel.to_rule) {
            const msg = `unresolved interaction ${rel.from} / ${r.rule_version_id}`;
            unresolved.set(r.rule_version_id, msg);
            unresolved.set(rel.from, msg);
          }
        }
      }
      for (const r of live) {
        const req = ev(r.value_expr, facts);
        const state = (status.get(r.rule_version_id) === UNKNOWN || req === UNKNOWN || req === null
          || !r.automatable || unresolved.has(r.rule_version_id)) ? "MANUAL_REVIEW" : "DETERMINED";
        const primary = (r.sources ?? []).filter((s) => s.role === "PRIMARY");
        results.push({
          structure: item.label, boundary, regime: r.regime, topic: r.topic, rule: r.rule_version_id, title: r.title, role: r.role,
          measurement: r.measurement_id, operator: r.operator,
          required: req === null || req === UNKNOWN ? null : typeof req === "number" ? pyRound(req, 3) : req,
          unit: r.unit, state, on_noncompliance: r.on_noncompliance, instrument: `${r.instrument} (${r.version_label})`,
          sources: primary.map((s) => s.ref), source_detail: primary, interpretation_notes: r.interpretation_notes ?? null,
          via: r._via || unresolved.get(r.rule_version_id) || null,
        });
      }
      for (const [rv, why] of removed)
        results.push({ structure: item.label, boundary, rule: rv, state: "DISPLACED", why, topic: cand.get(rv)!.topic, regime: cand.get(rv)!.regime });
    }
  }
  return results;
}

/** Markdown report, same layout as `python tools/evaluate.py scenario.json` (examples/*.out.md). */
export function render(scenario: Scenario, res: Result[]): string {
  const out: string[] = [`# ${scenario.title}  (assessment date ${scenario.assessment_date})\n`];
  for (const s of [...new Set(res.map((r) => r.structure))]) {
    out.push(`## ${s}`);
    const live = res.filter((x) => x.structure === s && x.state !== "DISPLACED")
      .sort((a, b) => cmp3([a.regime, a.topic, String(a.boundary ?? "None")], [b.regime, b.topic, String(b.boundary ?? "None")]));
    for (const r of live) {
      let req: string;
      if (r.operator === "IS_TRUE" || r.operator === "IS_FALSE") req = r.operator === "IS_TRUE" ? "must hold" : "must not occur";
      else if (r.required === 0 && r.operator === ">=") req = "BTB permitted (0 m)";
      else req = `${r.operator} ${pyNum(r.required)} ${r.unit ?? ""}`;
      out.push(`- [${r.regime}] ${r.topic} ${r.boundary ? "(" + r.boundary + ")" : ""}: ${req}  [${r.state}]`);
      out.push(`    ${r.rule} — ${r.title}`);
      out.push(`    source: ${r.instrument} — ${(r.sources ?? []).join("; ")}` + (r.via ? `  (${r.via})` : ""));
    }
    const disp = res.filter((x) => x.structure === s && x.state === "DISPLACED");
    if (disp.length) {
      out.push("  displaced:");
      for (const x of disp) out.push(`    - ${x.rule} (${x.boundary ?? "None"}): ${x.why}`);
    }
    out.push("");
  }
  return out.join("\n") + "\n";
}

function cmp3(a: string[], b: string[]): number {
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return a[i] < b[i] ? -1 : 1;
  return 0;
}

/** Python-style number display for the report: None for null. (Integer-valued floats print as '6' here, '6.0' in
 *  Python; the parity test normalises that one difference.) */
function pyNum(v: any): string {
  if (v === null || v === undefined) return "None";
  if (v === true) return "True";
  if (v === false) return "False";
  return String(v);
}
