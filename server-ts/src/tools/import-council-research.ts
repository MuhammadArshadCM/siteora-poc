/**
 * Convert council research files (research/councils/*.json) into SQL seed files.
 *
 * Every quoted provision is loaded verbatim into regs.provisions, and every extracted rule becomes a DRAFT rule
 * version with automatable = false. Values are carried over exactly as extracted; nothing is inferred. Rules are
 * promoted to ACTIVE/automatable only by hand in db/031_council_curated.sql (and later curated files) after review.
 *
 *   npm run import-research              writes db/030_council_<slug>.sql
 *   npm run import-research -- --check   compares with the files on disk instead of writing (exit 1 if different)
 */
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";
import { pyRepr, pyStr, truthy } from "../core/py.js";
import { dumps, isNumber, loads } from "../core/pyjson.js";
import { parseArgs } from "./args.js";

const RESEARCH = path.join(ROOT, "research", "councils");
const OUT = path.join(ROOT, "db");
const RESEARCH_DATE = "2026-10-08";

export const COUNCILS: Record<string, [string, string, string]> = {
  brisbane: ["BRISBANE", "BCC", "BCC_CITY_PLAN_2014"],
  gold_coast: ["GOLD_COAST", "CGC", "CGC_CITY_PLAN"],
  moreton_bay: ["MORETON_BAY", "CMB", "MBRC_PLANNING_SCHEME_2016"],
  sunshine_coast: ["SUNSHINE_COAST", "SCC", "SCC_PLANNING_SCHEME_2014"],
  logan: ["LOGAN", "LCC", "LCC_PLANNING_SCHEME_2015"],
  ipswich: ["IPSWICH", "ICC", "ICC_CITY_PLAN_2025"],
  redland: ["REDLAND", "RCC", "RCC_CITY_PLAN_2018"],
};

// topic -> [measurement, operator used when the extracted operator is not a plain comparison, taxonomy topic]
const TOPICS: Record<string, [string, string, string]> = {
  FRONT_SETBACK: ["SCHEME_SETBACK_FRONT", ">=", "SETBACK.FRONTAGE"],
  SECONDARY_FRONTAGE_SETBACK: ["SCHEME_SETBACK_SECONDARY_FRONTAGE", ">=", "SETBACK.SECONDARY_ROAD"],
  SIDE_SETBACK: ["SCHEME_SETBACK_SIDE", ">=", "SETBACK.SIDE"],
  REAR_SETBACK: ["SCHEME_SETBACK_REAR", ">=", "SETBACK.REAR"],
  BUILT_TO_BOUNDARY: ["SCHEME_BTB_LENGTH", "<=", "SETBACK.SIDE_REAR.BTB"],
  GARAGE_CARPORT_FRONTAGE: ["SCHEME_GARAGE_CARPORT", ">=", "GARAGE.FRONTAGE"],
  SITE_COVER: ["SCHEME_SITE_COVER", "<=", "SITE_COVER"],
  BUILDING_HEIGHT: ["SCHEME_HEIGHT", "<=", "HEIGHT.BUILDING"],
  WALL_HEIGHT: ["SCHEME_HEIGHT", "<=", "HEIGHT.WALL"],
  OUTBUILDING_SIZE: ["SCHEME_OUTBUILDING_SIZE", "<=", "OUTBUILDING.SIZE"],
  POOL_SETBACK: ["SCHEME_POOL_SETBACK", ">=", "POOL.SETBACK"],
  LANDSCAPE_OR_IMPERVIOUS: ["SCHEME_LANDSCAPE", ">=", "LANDSCAPE.OPEN_SPACE"],
  SEPARATION: ["SCHEME_SEPARATION", ">=", "SEPARATION.BUILDINGS"],
  OTHER: ["SCHEME_OTHER", "=", "OTHER"],
};

// Which legacy QDC rules an alternative provision on this topic displaces (Building Act s33(4)).
const QDC_TARGETS: Record<string, string[]> = {
  FRONT_SETBACK: ["QDC12.A1a.ROAD_SETBACK", "QDC11.A1a.FRONTAGE_SETBACK"],
  SECONDARY_FRONTAGE_SETBACK: ["QDC12.A1a.ROAD_SETBACK", "QDC11.A1a.SIDE_TO_CORNER_STREET"],
  SIDE_SETBACK: ["QDC12.A2a.SIDE_REAR_CLEARANCE", "QDC11.A2a.SIDE_REAR_CLEARANCE"],
  REAR_SETBACK: ["QDC12.A2a.SIDE_REAR_CLEARANCE", "QDC11.A2a.SIDE_REAR_CLEARANCE"],
  BUILT_TO_BOUNDARY: ["QDC12.A2d.CLASS10A_WITHIN_CLEARANCE", "QDC11.A2d.CLASS10A_WITHIN_CLEARANCE"],
  SITE_COVER: ["QDC12.A3.SITE_COVER", "QDC11.A3.SITE_COVER"],
  BUILDING_HEIGHT: ["QDC12.A4.BUILDING_HEIGHT", "QDC11.A4.BUILDING_HEIGHT"],
};

const KIND: Record<string, string> = {
  ACCEPTABLE_OUTCOME: "ACCEPTABLE_OUTCOME",
  PERFORMANCE_OUTCOME: "PERFORMANCE_OUTCOME",
  TABLE: "TABLE",
  ACCEPTED_DEVELOPMENT_REQUIREMENT: "ACCEPTED_DEVELOPMENT_REQUIREMENT",
  DEFINITION: "DEFINITION",
  OTHER: "OTHER",
};

const VERIF = new Set(["VERIFIED_VERBATIM", "COUNCIL_FACTSHEET", "SECONDARY_SOURCE_ONLY", "UNVERIFIED"]);

export function readResearch(file: string): any {
  return loads(fs.readFileSync(file, "utf-8").replace(/^﻿/, ""));
}

export const PLACES: Record<string, any> = readResearch(path.join(ROOT, "research", "places.json")).councils;

/** Python slice s[:n] (by code point, not UTF-16 unit). */
const cut = (s: string, n: number) => Array.from(s).slice(0, n).join("");

/** SQL literal using dollar quoting that cannot collide with the text. */
function q(s: unknown): string {
  if (s === null || s === undefined) return "NULL";
  const t = pyStr(s);
  let tag = "$q$";
  let n = 0;
  while (t.includes(tag)) {
    n++;
    tag = `$q${n}$`;
  }
  return `${tag}${t}${tag}`;
}

export function slug(s: string): string {
  return cut(s.toUpperCase().replace(/[^A-Z0-9]+/g, "_").replace(/^_+|_+$/g, ""), 100);
}

/** Prefix place ids with the authority code (places.json stores them unqualified). */
function qualify(row: Record<string, any>, authority: string): Record<string, any> {
  const out = { ...row };
  for (const k of ["zone", "precinct", "local_plan", "local_plan_precinct"]) if (k in out) out[k] = `${authority}:${out[k]}`;
  if ("overlay" in out) out.overlay = `${authority}:OV:${out.overlay}`;
  return out;
}

/** Map a research rule's zone strings to scope rows using research/places.json. Throws on a zone string that
 *  places.json does not cover, so new research cannot silently create pseudo-zones. */
function placeScopes(r: any, places: any, authority: string): [any[], string[]] {
  for (const [pattern, rows] of Object.entries<any[]>(places.rule_key_scopes ?? {}))
    if (new RegExp(pattern).test(r.rule_key)) return [rows.map((x) => qualify(x, authority)), []];
  const scopes: any[] = [], notes: string[] = [];
  for (const z of r.zones || []) {
    if (!(z in places.raw_scopes)) throw new Error(`${authority} rule ${r.rule_key}: zone string not in research/places.json: ${pyRepr(z)}`);
    const rows = places.raw_scopes[z];
    if (rows === "UNMAPPED") {
      notes.push(`Zone text '${z}' could not be mapped to a scheme place; rule left council-wide.`);
      continue;
    }
    if (!truthy(rows)) return [[], notes];   // 'all zones' etc. => no place restriction
    scopes.push(...rows.map((x: any) => qualify(x, authority)));
  }
  return [scopes, notes];
}

function subjectsFor(scope: string | null | undefined): [string[], boolean] {
  const s = (scope || "").toLowerCase();
  let out: string[] = [];
  const any = (ks: string[]) => ks.some((k) => s.includes(k));
  if (s.includes("pool")) out.push("POOL");
  if (any(["class 10", "outbuilding", "shed", "garage", "carport", "non-habitable"])) out.push("CLASS_10A");
  if (any(["dwelling", "house", "class 1"])) out.push("CLASS_1");
  if (any(["deck", "patio", "pergola", "verandah"])) out.push("OUTDOOR_STRUCTURE");
  if (s.includes("structure") && !out.length) out.push("ANY");
  if (any(["all buildings", "buildings and structures", "any building"])) out = ["ANY"];
  return [out.length ? out : ["ANY"], !out.length];
}

const dateOrNone = (s: unknown) => (typeof s === "string" && /^\d{4}-\d{2}-\d{2}$/.test(s) ? s : null);

/** The SQL for one council, as written to disk (CRLF line endings, like the original Python generator on Windows). */
export function build(slugName: string): [string, number] | null {
  const file = path.join(RESEARCH, `${slugName}.json`);
  if (!fs.existsSync(file)) return null;
  const d = readResearch(file);
  const [lg, authority, inst] = COUNCILS[slugName];
  const ps = d.planning_scheme;
  const commenced = dateOrNone(ps.version_commenced);
  const eff = commenced || RESEARCH_DATE;
  const iv = `${inst}@${eff}`;
  const urls: string[] = ps.official_urls || [];
  const L: string[] = [];
  const w = (s: string) => L.push(s);
  w(`-- Generated by server-ts/src/tools/import-council-research.ts (npm run import-research) from research/councils/${slugName}.json`);
  w("-- DO NOT EDIT BY HAND: re-run the generator. Places come from research/places.json;");
  w("-- curated rules live in db/031_council_curated.sql and db/032_council_curated_batch2.sql.");
  w("SET search_path = regs, public;\n");
  w("INSERT INTO instruments (instrument_id, authority_id, lg_id, kind, force, title, notes) VALUES "
    + `(${q(inst)}, ${q(authority)}, ${q(lg)}, 'PLANNING_SCHEME', 'STATUTORY_INSTRUMENT', ${q(ps.name)}, ${q(ps.notes)});`);
  w("INSERT INTO instrument_versions (instrument_version_id, instrument_id, version_label, effective_from, status, source_url, retrieved_at, notes) VALUES "
    + `(${q(iv)}, ${q(inst)}, ${q(ps.version)}, ${q(eff)}, 'ACTIVE', ${q(urls.length ? urls[0] : null)}, ${q(RESEARCH_DATE)}, `
    + `${q(commenced ? null : "Commencement date UNVERIFIED; research date used as effective_from.")});`);
  w("INSERT INTO instrument_applicability (instrument_version_id, lg_id, regime, effective_from, basis_provision_id, confidence, notes) VALUES "
    + `(${q(iv)}, ${q(lg)}, 'PLANNING', ${q(eff)}, NULL, ${q(commenced ? "VERIFIED_VERBATIM" : "UNVERIFIED")}, 'Version in force at research date; earlier versions not loaded.');\n`);

  // Places (from research/places.json) and overlays (from the research file)
  const places = PLACES[slugName];
  if (places.authority !== authority) throw new Error(`${slugName}: places.json authority ${places.authority} != ${authority}`);
  for (const z of places.zones)
    w("INSERT INTO zones (zone_id, instrument_id, zone_code, name, regulated_zone_id, dwelling_house_permitted, dwelling_house_basis) VALUES "
      + `(${q(authority + ":" + z.code)}, ${q(inst)}, ${q(z.code)}, ${q(z.name)}, ${q(z.regulated)}, `
      + `${z.dwelling_house_permitted === null || z.dwelling_house_permitted === undefined ? "NULL" : String(z.dwelling_house_permitted).toLowerCase()}, ${q(z.basis)});`);
  for (const pr of places.precincts)
    w("INSERT INTO precincts (precinct_id, zone_id, name) VALUES "
      + `(${q(authority + ":" + pr.zone + "/" + pr.code)}, ${q(authority + ":" + pr.zone)}, ${q(pr.name)});`);
  for (const lp of places.local_plans) {
    w("INSERT INTO local_plans (local_plan_id, instrument_id, name, plan_type) VALUES "
      + `(${q(authority + ":" + lp.code)}, ${q(inst)}, ${q(lp.name)}, ${q(lp.type)});`);
    for (const pr of lp.precincts)
      w("INSERT INTO local_plan_precincts (local_plan_precinct_id, local_plan_id, name) VALUES "
        + `(${q(authority + ":" + lp.code + "/" + pr.code)}, ${q(authority + ":" + lp.code)}, ${q(pr.name)});`);
  }
  const overlays = new Map<string, string>();
  for (const r of d.rules ?? []) if (truthy(r.overlay)) { const k = `${authority}:OV:${slug(r.overlay)}`; if (!overlays.has(k)) overlays.set(k, r.overlay); }
  for (const o of d.overlays_affecting_siting ?? []) { const k = `${authority}:OV:${slug(o.overlay)}`; if (!overlays.has(k)) overlays.set(k, o.overlay); }
  for (const [oid, name] of [...overlays].sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)))
    w(`INSERT INTO overlays (overlay_id, instrument_id, name) VALUES (${q(oid)}, ${q(inst)}, ${q(name)});`);
  w("");

  const seen = new Set<string>();
  const prov = (ref: string, kind: string, text: unknown, ver: unknown, url: unknown = null, page: unknown = null,
                code: unknown = null, notes: unknown = null, researchKey: string | null = null) => {
    ref = cut(ref, 200);
    if (researchKey === null) {          // label must be unique among non-keyed provisions
      const base = ref;
      let n = 1;
      while (seen.has(ref)) { n++; ref = `${base} #${n}`; }
      seen.add(ref);
    }
    let v = typeof ver === "string" && VERIF.has(ver) ? ver : "UNVERIFIED";
    if (!truthy(text)) v = "UNVERIFIED";
    w(`SELECT define_provision(${q(iv)}, ${q(ref)}, '${kind}', ${q(text)}, '${v}', ${q(page)}, NULL, ${q(code)}, NULL, ${q(url)}, ${q(notes)}, ${q(researchKey)});`);
    return ref;
  };

  (d.qdc_qhc_relationship?.quotes ?? []).forEach((x: any, i: number) =>
    prov(`QDC relationship: ${truthy(x.clause) ? pyStr(x.clause) : i}`, "APPLICATION", x.text, "VERIFIED_VERBATIM", x.source_url));
  for (const x of d.definitions ?? [])
    prov(`def ${x.term}`, "DEFINITION", x.text, "VERIFIED_VERBATIM", x.source_url, null, x.clause);
  for (const x of d.levels_of_assessment ?? [])
    prov(`LOA ${pyStr(x.clause)} ${pyStr(x.use_or_work)} / ${pyStr(x.zone)}`, "LEVEL_OF_ASSESSMENT", x.quote,
      "VERIFIED_VERBATIM", x.source_url, null, null, `Level: ${pyStr(x.level)}. Conditions: ${pyStr(x.conditions)}`);
  for (const x of d.overlays_affecting_siting ?? [])
    prov(`overlay ${x.overlay} ${truthy(x.clause) ? pyStr(x.clause) : ""}`.trim(), "OTHER", x.quote, "VERIFIED_VERBATIM",
      x.source_url, null, x.code, x.effect);
  w("");

  const ruleIds: string[] = [];
  for (const r of d.rules ?? []) {
    prov(truthy(r.clause) ? r.clause : r.rule_key, KIND[r.provision_type] ?? "OTHER", r.verbatim_text, r.verification_status,
      r.source_url, r.page_or_anchor, r.code, r.measurement_notes, r.rule_key);
    if (r.provision_type === "DEFINITION") continue;
    const topic = truthy(r.topic) ? r.topic : "OTHER";
    const [meas, defaultOp, tax] = TOPICS[topic] ?? TOPICS.OTHER;
    const st = truthy(r.structured) ? r.structured : {};
    const op = st.operator ?? null, val = st.value ?? null;
    const simple = [">=", "<=", "="].includes(op) && isNumber(val);
    const value = simple ? val : { op: "unencoded", text: truthy(st.formula_text) ? st.formula_text : (r.verbatim_text ?? null),
      extracted_value: val, extracted_operator: op };
    const alt = String(truthy(r.alternative_provision_to_qdc_qhc) ? r.alternative_provision_to_qdc_qhc : "UNKNOWN").trim().split(/\s+/)[0].toUpperCase();
    const ptype = r.provision_type ?? null;
    let regime: string, outcome: string;
    if (alt === "YES") [regime, outcome] = ["BUILDING", "REFERRAL_TO_LOCAL_GOVERNMENT"];
    else [regime, outcome] = ["PLANNING", ptype === "PERFORMANCE_OUTCOME" ? "ASSESS_AGAINST_PERFORMANCE_OUTCOME" : "PLANNING_APPROVAL_REQUIRED"];
    const enf = ptype === "PERFORMANCE_OUTCOME" ? "DISCRETIONARY" : "DEEMED_TO_COMPLY";
    const [subjects, defaulted] = subjectsFor(r.structure_scope);
    const [place, placeNotes] = placeScopes(r, places, authority);
    const scopes: any[] = [{ level: "LOCAL_GOVERNMENT", lg }, ...place];
    if (truthy(r.overlay)) scopes.push({ level: "OVERLAY", overlay: `${authority}:OV:${slug(r.overlay)}` });
    const notes = [`AUTO-IMPORTED (draft). Extracted structure: ${dumps(st)}`,
      truthy(r.lot_conditions) ? `Lot conditions (not encoded): ${pyStr(r.lot_conditions)}` : null,
      truthy(r.local_plan) ? `Local plan: ${pyStr(r.local_plan)}` : null,
      `Structure scope '${pyStr(r.structure_scope)}' mapped by keyword to ${pyStr(subjects)}` + (defaulted ? " (default)" : ""),
      `Alternative provision to QDC/QHC: ${pyStr(r.alternative_provision_to_qdc_qhc)}`,
      truthy(r.notes) ? `Researcher notes: ${pyStr(r.notes)}` : null, ...placeNotes];
    const doc = {
      rule_id: `${authority}.${r.rule_key}`, instrument_version: iv, topic: tax,
      title: cut(truthy(r.clause) ? r.clause : r.rule_key, 200),
      role: "REQUIREMENT", regime, enforceability: enf,
      provision_kind: KIND[ptype] ?? "OTHER", measurement: meas,
      operator: [">=", "<=", "="].includes(op) ? op : defaultOp, value, unit: st.unit ?? null,
      on_noncompliance: outcome, effective_from: eff,
      verification: VERIF.has(r.verification_status) ? r.verification_status : "UNVERIFIED",
      automatable: false, scopes, subjects,
      sources: [{ key: r.rule_key, role: "PRIMARY" }],
      interpretation_notes: notes.filter((n) => truthy(n)).join("\n"),
    };
    w(`SELECT define_rule(${q(dumps(doc))}::jsonb);`);
    const rv = `${doc.rule_id}@${eff}`;
    ruleIds.push(rv);
    w(`UPDATE rule_versions SET status = 'DRAFT' WHERE rule_version_id = ${q(rv)};`);
    if (alt === "YES")
      for (const target of QDC_TARGETS[topic] ?? [])
        w("INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes) VALUES "
          + `(${q(rv)}, ${q(target)}, 'OVERRIDES', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM', `
          + "'Alternative provision (Building Act s33(4)): QDC applies only to the extent this provision does not. Scope must be confirmed per rule (zone/precinct/structure).');");
  }
  w("");
  for (const oq of d.open_questions ?? [])
    w(`INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES (${q(lg)}, ${q(inst)}, 'MEDIUM', ${q(oq)});`);
  return [(L.join("\n") + "\n").replace(/\n/g, "\r\n"), ruleIds.length];
}

export function outFile(slugName: string): string {
  return path.join(OUT, `030_council_${slugName}.sql`);
}

function main(): void {
  const a = parseArgs(process.argv.slice(2), { booleans: ["check"] });
  let differ = 0;
  for (const name of Object.keys(COUNCILS)) {
    const res = build(name);
    if (res === null) {
      console.log(`${name}: no research file`);
      continue;
    }
    const [sql, n] = res;
    if (a.check) {
      const same = fs.existsSync(outFile(name)) && fs.readFileSync(outFile(name), "utf-8") === sql;
      differ += same ? 0 : 1;
      console.log(`${name}: ${n} draft rules — ${same ? "matches" : "DIFFERS from"} ${path.basename(outFile(name))}`);
    } else {
      fs.writeFileSync(outFile(name), sql, "utf-8");
      console.log(`${name}: ${n} draft rules`);
    }
  }
  if (differ) process.exit(1);
}

if (process.argv[1] && import.meta.url.endsWith(path.basename(process.argv[1]).replace(/\\/g, "/"))) main();
