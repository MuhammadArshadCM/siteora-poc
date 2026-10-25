/**
 * Validate the council front / side / rear setback records against their source provisions (read-only).
 *
 * For every council in validation/councils.json it:
 *   * runs the established pipeline checks (import-research --check, verify-load) and parses their per-council result;
 *   * audits every council setback rule version in the database: council/scheme links, topic vs measurement vs
 *     boundary_type condition, values and units, PRIMARY source text, quote and location, value present in the source,
 *     duplicates and conflicting values for identical applicability, DRAFT/SUPERSEDED consistency;
 *   * lists source provisions that are not in the primary (ACTIVE) dataset, and residential zones with no council rule;
 *   * fingerprints the regs tables before and after, to prove nothing was written.
 * Writes validation/*.csv. Never writes to the database.
 *
 *   npm run validate-setbacks
 *   npm run validate-setbacks -- --out <dir>     write the CSVs somewhere else (e.g. to compare two runs)
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Db, lit } from "../core/db.js";
import { loadEnv, ROOT } from "../core/env.js";
import { parseArgs } from "./args.js";
import { exit } from "./fmt.js";
import { build, outFile, readResearch } from "./import-council-research.js";

const VALIDATION = path.join(ROOT, "validation");
const TOOLS = path.dirname(fileURLToPath(import.meta.url));

/** Primary dataset: front, side and rear setbacks that reach Class 10 structures (Class 10a buildings and Class 10b
 *  structures). Garage/carport frontage setbacks, Class 10 built-to-boundary allowances and pool boundary setbacks are
 *  front/side/rear setbacks for Class 10, so they are primary too. Everything else setback-like is reported separately.
 *  An empty measurement list means any measurement is accepted. */
const PRIMARY: Record<string, { measurements: string[]; boundaries: string[] }> = {
  "SETBACK.FRONTAGE": { measurements: ["SCHEME_SETBACK_FRONT"], boundaries: ["PRIMARY_FRONTAGE"] },
  "SETBACK.SIDE": { measurements: ["SCHEME_SETBACK_SIDE"], boundaries: ["SIDE"] },
  "SETBACK.REAR": { measurements: ["SCHEME_SETBACK_REAR"], boundaries: ["REAR"] },
  "SETBACK.SIDE_REAR": { measurements: ["SCHEME_SETBACK_SIDE", "SCHEME_SETBACK_REAR"], boundaries: ["SIDE", "REAR"] },
  "GARAGE.FRONTAGE": { measurements: ["SCHEME_SETBACK_FRONT", "SCHEME_GARAGE_CARPORT"], boundaries: ["PRIMARY_FRONTAGE"] },
  "SETBACK.SIDE_REAR.BTB": { measurements: ["SCHEME_SETBACK_SIDE", "SCHEME_SETBACK_REAR"], boundaries: ["SIDE", "REAR"] },
  "POOL.SETBACK": { measurements: [], boundaries: ["PRIMARY_FRONTAGE", "SIDE", "REAR"] },
  "POOL.SETBACK.FRONTAGE": { measurements: [], boundaries: ["PRIMARY_FRONTAGE"] },
  "POOL.SETBACK.ROAD": { measurements: [], boundaries: ["PRIMARY_FRONTAGE"] },
  "POOL.SETBACK.SIDE_REAR": { measurements: [], boundaries: ["SIDE", "REAR"] },
};
const RELATED_TOPIC = /^(SETBACK\.|SEPARATION\.|GARAGE\.|POOL\.SETBACK)/;
const CATEGORY: Record<string, string[]> = {
  "SETBACK.FRONTAGE": ["FRONT"], "SETBACK.SIDE": ["SIDE"], "SETBACK.REAR": ["REAR"], "SETBACK.SIDE_REAR": ["SIDE", "REAR"],
  "GARAGE.FRONTAGE": ["FRONT"], "SETBACK.SIDE_REAR.BTB": ["SIDE", "REAR"], "POOL.SETBACK": ["FRONT", "SIDE", "REAR"],
  "POOL.SETBACK.FRONTAGE": ["FRONT"], "POOL.SETBACK.ROAD": ["FRONT"], "POOL.SETBACK.SIDE_REAR": ["SIDE", "REAR"],
};
const isFront = (topic: string) => CATEGORY[topic]?.length === 1 && CATEGORY[topic][0] === "FRONT";
/** Drafts carry keyword-mapped subjects only; these words in the provision show it reaches Class 10. */
const CLASS10_WORDS = /outbuilding|shed|garage|carport|class 10|non-habitable|structures?|swimming pool|pools?|car parking|car accommodation/i;
/** Reviewed drafts that are not gaps (see validation/curation_decisions.json). */
/** Structure types that are Class 10 (filled from regs.structure_types): the CLASS_10A / CLASS_10B subtrees, plus ANY. */
const CLASS10 = new Set<string>(["ANY"]);
const SETTLED = new Set(["OUT_OF_SCOPE", "EXCLUDED_CATEGORY", "DOCUMENTED_ABSENCE"]);
const VERIFIED = new Set(["VERIFIED_VERBATIM", "VERIFIED_FROM_FIGURE"]);

type Severity = "ERROR" | "WARNING" | "INFO";
interface Issue {
  council: string; lg_id: string; issue_type: string; severity: Severity; rule_version_id: string; status: string;
  topic: string; provision: string; source_url: string; detail: string; evidence: string; recommended_fix: string;
  resolution_status: string;
}

// ------------------------------------------------------------------ helpers

function csv(rows: Record<string, unknown>[], cols: string[]): string {
  const cell = (v: unknown) => {
    const s = v === null || v === undefined ? "" : typeof v === "object" ? JSON.stringify(v) : String(v);
    return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return [cols.join(","), ...rows.map((r) => cols.map((c) => cell(r[c])).join(","))].join("\n") + "\n";
}

const norm = (s: string) => s.toLowerCase().replace(/\|/g, " ").replace(/[‐-―]/g, "-").replace(/[‘’]/g, "'").replace(/\s+/g, " ").trim();
const fmtNum = (n: number) => String(Number(n.toFixed(4)));
const clip = (s: string | null | undefined, n = 300) => (s ?? "").replace(/\s+/g, " ").slice(0, n);

/** Numbers a value expression can return as the setback, and whether it is fixed, conditional or a formula. */
function outputs(e: any): { values: number[]; kind: string } {
  if (typeof e === "number") return { values: [e], kind: "FIXED" };
  if (e === null || typeof e !== "object") return { values: [], kind: "NONE" };
  if (e.op === "unencoded")
    return { values: typeof e.extracted_value === "number" ? [e.extracted_value] : [], kind: "UNENCODED" };
  if (e.op === "case") {
    const parts = [...(e.when ?? []).map((w: any) => outputs(w.then)), outputs(e.else)];
    return { values: parts.flatMap((p) => p.values), kind: parts.every((p) => p.kind === "FIXED") ? "CONDITIONAL" : "FORMULA" };
  }
  if (e.op === "min" || e.op === "max") return { values: (e.args ?? []).flatMap((a: any) => outputs(a).values), kind: "FORMULA" };
  return { values: [], kind: "FORMULA" };
}

/** Does the text state this many metres (or the same in millimetres)? "unit" = with a unit; "bare" = number only. */
const WORDS = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve",
  "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"];

function valueInText(n: number, text: string): "unit" | "bare" | "no" {
  if (n === 0 && /built (up )?to the [a-z ]*boundary|on the [a-z ]*boundary|zero setback|nil setback/i.test(text)) return "unit";
  if (Number.isInteger(n) && WORDS[n] && new RegExp(`\\b${WORDS[n]}\\s*(?:\\(\\d+\\)\\s*)?(?:metres?|meters?)\\b`, "i").test(text)) return "unit";
  // "0.75" also matches "0.750"; "6" also matches "6.0"
  const m = fmtNum(n).includes(".") ? fmtNum(n).replace(".", "\\.") + "0*" : fmtNum(n) + "(?:\\.0+)?";
  if (new RegExp(`(?<![\\d.])${m}\\s*(?:m\\b|metres?\\b|meters?\\b)`, "i").test(text)) return "unit";
  const mm = Math.round(n * 1000);
  const mmPat = String(mm).replace(/\B(?=(\d{3})+(?!\d))/g, ",?");
  if (n > 0 && new RegExp(`(?<![\\d.,])${mmPat}\\s*(?:mm|millimetres?)\\b`, "i").test(text)) return "unit";
  if (new RegExp(`(?<![\\d.])${m}(?![\\d.])`).test(text)) return "bare";
  return "no";
}

function boundaryValues(conditions: any[]): string[] {
  const out = new Set<string>();
  for (const c of conditions) if (c.fact_id === "boundary_type") for (const v of [c.value].flat()) out.add(String(v));
  return [...out].sort();
}

/** Run an established tool and return its stdout (the tools print one line per council). */
function runTool(script: string, args: string[] = []): { code: number; out: string } {
  const r = spawnSync(process.execPath, [path.join(TOOLS, script), ...args], { encoding: "utf-8", env: process.env });
  return { code: r.status ?? 1, out: (r.stdout ?? "") + (r.stderr ?? "") };
}

// ------------------------------------------------------------------ database reads

const FINGERPRINT_TABLES = ["instruments", "instrument_versions", "provisions", "rules", "rule_versions", "rule_scopes",
  "rule_subjects", "rule_conditions", "rule_sources", "rule_relationships", "open_issues", "zones", "precincts"];

async function fingerprint(db: Db): Promise<string> {
  const parts = await Promise.all(FINGERPRINT_TABLES.map((t) =>
    db.q<string>(`SELECT to_json(${lit(t)} || ':' || count(*) || ':' || coalesce(md5(string_agg(x::text, '|' ORDER BY x::text)), ''))::text FROM regs.${t} x`)));
  return parts.join(" ");
}

async function loadRecords(db: Db, lg: string): Promise<any[]> {
  return db.q(`
    SELECT coalesce(json_agg(x ORDER BY x.rule_version_id), '[]') FROM (
      SELECT rv.rule_version_id, rv.rule_id, r.topic, r.title, rv.status, rv.verification, rv.automatable, rv.role,
             rv.measurement_id, rv.operator, rv.value_expr, rv.unit, rv.effective_from, rv.effective_to,
             rv.interpretation_notes, i.instrument_id, i.lg_id AS instrument_lg, i.kind AS instrument_kind,
             iv.instrument_version_id, iv.instrument_id AS iv_instrument, iv.version_label, iv.effective_from AS iv_from,
             iv.effective_to AS iv_to, iv.status AS iv_status, iv.source_url AS iv_url,
             (SELECT coalesce(json_agg(json_build_object('level', s.level, 'lg', s.lg_id, 'place',
                       coalesce(s.zone_id, s.precinct_id, s.overlay_id, s.local_plan_id, s.local_plan_precinct_id), 'exclude', s.exclude)
                       ORDER BY s.level, coalesce(s.zone_id, s.precinct_id, s.overlay_id, s.local_plan_id, s.local_plan_precinct_id, s.lg_id)), '[]')
                FROM regs.rule_scopes s WHERE s.rule_version_id = rv.rule_version_id) AS scopes,
             (SELECT coalesce(json_agg(json_build_object('id', s.structure_type_id, 'exclude', s.exclude) ORDER BY s.structure_type_id), '[]')
                FROM regs.rule_subjects s WHERE s.rule_version_id = rv.rule_version_id) AS subjects,
             (SELECT coalesce(json_agg(json_build_object('group', c.group_no, 'fact_id', c.fact_id, 'op', c.operator, 'value', c.value)
                       ORDER BY c.group_no, c.fact_id, c.operator, c.value::text), '[]')
                FROM regs.rule_conditions c WHERE c.rule_version_id = rv.rule_version_id) AS conditions,
             (SELECT coalesce(json_agg(json_build_object('provision_id', p.provision_id, 'ref_label', p.ref_label,
                       'page', coalesce(p.page_label, p.pdf_page::text), 'url', p.url_anchor, 'text', p.verbatim_text,
                       'verification', p.verification, 'research_key', p.research_key, 'quote', s.quote,
                       'iv', p.instrument_version_id) ORDER BY p.provision_id), '[]')
                FROM regs.rule_sources s JOIN regs.provisions p USING (provision_id)
               WHERE s.rule_version_id = rv.rule_version_id AND s.role = 'PRIMARY') AS sources,
             (SELECT coalesce(string_agg(coalesce(s.quote, '') || ' ' || coalesce(p.verbatim_text, ''), ' ' ORDER BY p.provision_id), '')
                FROM regs.rule_sources s JOIN regs.provisions p USING (provision_id)
               WHERE s.rule_version_id = rv.rule_version_id AND s.role = 'SUPPLEMENTARY') AS supplementary_text,
             (SELECT coalesce(json_agg(rr.from_rule_version_id || ':' || f.status), '[]') FROM regs.rule_relationships rr
                JOIN regs.rule_versions f ON f.rule_version_id = rr.from_rule_version_id
               WHERE rr.type = 'REPLACES' AND rr.to_rule_version_id = rv.rule_version_id) AS replaced_by
        FROM regs.rule_versions rv
        JOIN regs.rules r USING (rule_id)
        JOIN regs.instruments i ON i.instrument_id = r.instrument_id
        JOIN regs.instrument_versions iv ON iv.instrument_version_id = rv.instrument_version_id
       WHERE i.kind = 'PLANNING_SCHEME'
         AND EXISTS (SELECT 1 FROM regs.rule_scopes s WHERE s.rule_version_id = rv.rule_version_id
                       AND s.level = 'LOCAL_GOVERNMENT' AND s.lg_id = ${lit(lg)})) x`);
}

// ------------------------------------------------------------------ main

async function main(): Promise<number> {
  const a = parseArgs(process.argv.slice(2), { defaults: { out: VALIDATION } });
  const outDir = path.resolve(a.out);
  fs.mkdirSync(outDir, { recursive: true });
  const cfg = JSON.parse(fs.readFileSync(path.join(VALIDATION, "councils.json"), "utf-8"));
  const decisionsFile = path.join(VALIDATION, "curation_decisions.json");
  const decisions = new Map<string, { decision: string; reason: string }>(
    (fs.existsSync(decisionsFile) ? JSON.parse(fs.readFileSync(decisionsFile, "utf-8")) : []).map((d: any) => [d.rule_id, d]));
  loadEnv();
  const db = new Db();

  const issues: Issue[] = [], missing: any[] = [], coverage: any[] = [], summary: any[] = [], audit: any[] = [];
  try {
    const before = await fingerprint(db);
    const tree: [string, string | null][] = await db.q("SELECT coalesce(json_agg(json_build_array(structure_type_id, parent_id)), '[]') FROM regs.structure_types");
    for (let grew = true; grew;) {
      grew = false;
      for (const [id, parent] of tree)
        if (!CLASS10.has(id) && (id === "CLASS_10A" || id === "CLASS_10B" || (parent && parent !== "ANY" && CLASS10.has(parent)))) { CLASS10.add(id); grew = true; }
    }

    // Pipeline: the established entry points, run once for all councils.
    const verify = runTool("verify-load.js");
    const lgCouncils: string[] = await db.q("SELECT coalesce(json_agg(lg_id ORDER BY lg_id), '[]') FROM regs.local_governments");

    for (const c of cfg.councils) {
      const issue = (i: Partial<Issue> & Pick<Issue, "issue_type" | "severity" | "detail">) => {
        const proposed = (cfg.proposed_changes ?? []).find((p: any) => p.rule_version_id === i.rule_version_id && p.issue_type === i.issue_type);
        issues.push({ council: c.name, lg_id: c.lg_id ?? "", rule_version_id: "", status: "", topic: "", provision: "",
          source_url: "", evidence: "", recommended_fix: "", resolution_status: "OPEN", ...i,
          ...(proposed ? { resolution_status: `FIX PENDING: ${proposed.change_set}` } : {}) });
      };
      const sc = c.source_check ?? {};
      const row: Record<string, any> = {
        council: c.name, lg_id: c.lg_id ?? "", spreadsheet_scheme: c.spreadsheet_scheme,
        db_scheme: "", db_version: "", db_effective_from: "", online_version_check: sc.status ?? "NOT_CHECKED",
        online_current_version: sc.current ?? "",
      };
      const covRow: Record<string, any> = {
        council: c.name, lg_id: c.lg_id ?? "", spreadsheet_scheme: c.spreadsheet_scheme, spreadsheet_url: c.spreadsheet_url,
        spreadsheet_link_status: sc.link_status ?? "", current_scheme_found: sc.current ?? "", version_status: sc.status ?? "NOT_CHECKED",
        source_format: sc.format ?? "", setback_code_location: sc.setback_location ?? "", evidence_url: sc.evidence_url ?? "",
        evidence_quote: sc.evidence ?? "", in_database: false, research_file: "", db_scheme: "", db_version: "",
        db_effective_from: "", db_source_url: "", provisions_in_db: 0, distinct_source_documents: 0, provisions_with_location: 0,
        open_issues_unresolved: 0, notes: sc.notes ?? "",
      };

      if (!c.lg_id || !lgCouncils.includes(c.lg_id)) {
        issue({ issue_type: "COUNCIL_NOT_IN_DATASET", severity: "ERROR",
          detail: "Council has no row in regs.local_governments, no research/councils file, no db/030 seed and no curated rules; nothing to validate.",
          evidence: `Planning scheme per spreadsheet: ${c.spreadsheet_scheme}. ${sc.status ? `Online check: ${sc.status} — ${sc.current ?? ""}` : "Online check not done."}`,
          source_url: sc.evidence_url ?? c.spreadsheet_url,
          recommended_fix: "Onboard via the established workflow: research/councils/<slug>.json (verbatim quotes) + research/places.json + COUNCILS entry in import-council-research.ts + authority/local_government rows in db/010, then curate.",
          resolution_status: "BLOCKED" });
        coverage.push(covRow);
        summary.push({ ...row, source_document_availability: sc.status ? `NOT HELD LOCALLY; online ${sc.link_status ?? "status unknown"}` : "NOT HELD LOCALLY",
          source_files_inspected: 0, existing_db_records: 0, records_examined: 0, verified_records: 0, value_mismatches: 0,
          classification_errors: 0, missing_setback_requirements: "UNKNOWN", unrelated_records: 0, duplicates: 0, manual_review_records: 0,
          pipeline_status: "NOT_RUN (no dataset)", data_integrity: "NOT_RUN", source_traceability: "NOT_RUN", scope_test: "NOT_RUN",
          regression_test: "N/A (not an original council)", overall_status: "BLOCKED",
          outstanding_issues: "No dataset: council not researched or loaded. Source documents not held locally." });
        continue;
      }

      // ---- pipeline status for this council
      const research = path.join(ROOT, "research", "councils", `${c.slug}.json`);
      const built = build(c.slug);
      const genSame = built !== null && fs.existsSync(outFile(c.slug)) && fs.readFileSync(outFile(c.slug), "utf-8") === built[0];
      const vl = verify.out.split(/\r?\n/).filter((l) => l.startsWith(c.slug.padEnd(15)));
      const vlOk = vl.length === 2 && vl.every((l) => / OK$/.test(l));
      const pipelineOk = genSame && vlOk;
      if (!genSame) issue({ issue_type: "PIPELINE_GENERATOR_DIFF", severity: "ERROR", detail: `db/030_council_${c.slug}.sql differs from what import-research generates from the research file.`, recommended_fix: "Re-run npm run import-research and reload, after reviewing the diff." });
      if (!vlOk) issue({ issue_type: "PIPELINE_VERIFY_LOAD", severity: "ERROR", detail: `verify-load did not report OK: ${vl.join(" / ") || "no output line"}`, recommended_fix: "Reload db/load_all.sql into a scratch DB and compare." });

      // ---- source coverage
      const d = readResearch(research);
      const src: any = await db.q(`SELECT json_build_object(
          'n', count(*), 'docs', count(DISTINCT coalesce(p.url_anchor, iv.source_url)), 'loc', count(*) FILTER (WHERE p.url_anchor IS NOT NULL OR p.page_label IS NOT NULL OR p.pdf_page IS NOT NULL),
          'iv', (SELECT json_agg(json_build_object('id', v.instrument_version_id, 'label', v.version_label, 'from', v.effective_from, 'to', v.effective_to, 'url', v.source_url, 'status', v.status, 'instrument', v.instrument_id))
                   FROM regs.instrument_versions v JOIN regs.instruments i2 USING (instrument_id) WHERE i2.lg_id = ${lit(c.lg_id)} AND i2.kind = 'PLANNING_SCHEME'),
          'issues', (SELECT count(*) FROM regs.open_issues o WHERE o.lg_id = ${lit(c.lg_id)} AND o.resolved_at IS NULL))
        FROM regs.provisions p JOIN regs.instrument_versions iv USING (instrument_version_id) JOIN regs.instruments i USING (instrument_id)
       WHERE i.lg_id = ${lit(c.lg_id)}`);
      const ivs: any[] = src.iv ?? [];
      if (ivs.length !== 1) issue({ issue_type: "SCHEME_VERSION_COUNT", severity: "ERROR", detail: `Expected one planning-scheme version, found ${ivs.length}`, evidence: JSON.stringify(ivs) });
      const iv = ivs[0] ?? {};
      Object.assign(covRow, { in_database: true, research_file: path.relative(ROOT, research).replace(/\\/g, "/"), db_scheme: d.planning_scheme?.name ?? iv.instrument,
        db_version: iv.label, db_effective_from: iv.from, db_source_url: iv.url, provisions_in_db: src.n, distinct_source_documents: src.docs,
        provisions_with_location: src.loc, open_issues_unresolved: src.issues });
      Object.assign(row, { db_scheme: covRow.db_scheme, db_version: iv.label, db_effective_from: iv.from });
      if (iv.to || iv.status !== "ACTIVE") issue({ issue_type: "SCHEME_VERSION_NOT_ACTIVE", severity: "ERROR", detail: `Scheme version ${iv.id} has status ${iv.status}, effective_to ${iv.to}` });
      if (sc.status === "UNCONFIRMED") issue({ issue_type: "SCHEME_VERSION_UNCONFIRMED", severity: "WARNING", detail: `Online check could not confirm a version: ${sc.current}`, source_url: sc.evidence_url, evidence: sc.evidence, recommended_fix: "Confirm the in-force version/amendment with the council." });
      else if (sc.status && sc.status !== "CURRENT") issue({ issue_type: "SCHEME_VERSION_NOT_CURRENT", severity: "ERROR", detail: `Online check: ${sc.status}; council publishes ${sc.current}`, source_url: sc.evidence_url, evidence: sc.evidence, recommended_fix: "Re-research the council against the current version." });
      if (sc.notes && /not confirm|unconfirmed|could not/i.test(sc.notes)) issue({ issue_type: "SCHEME_METADATA_UNCONFIRMED", severity: "WARNING", detail: sc.notes, source_url: sc.evidence_url, evidence: sc.evidence, recommended_fix: "Confirm the version label wording against the scheme document; values are unaffected." });
      if (!/^\d{4}-\d{2}-\d{2}$/.test(String(d.planning_scheme?.version_commenced))) issue({ issue_type: "SCHEME_COMMENCEMENT_UNVERIFIED", severity: "WARNING", detail: "Research file has no commencement date; research date used as effective_from." });
      coverage.push(covRow);

      // ---- record audit
      const recs = await loadRecords(db, c.lg_id);
      const setbackRecs = recs.filter((r) => RELATED_TOPIC.test(r.topic));
      // Class 10 reach: a subject (not excluded) in the Class 10a / 10b subtrees or ANY; drafts may instead show it in their text
      const reachesClass10 = (r: any) => r.subjects.some((x: any) => !x.exclude && CLASS10.has(x.id))
        || (r.status === "DRAFT" && CLASS10_WORDS.test(r.sources.map((s: any) => s.text ?? "").join(" ")));
      for (const r of setbackRecs) r.class10 = reachesClass10(r);
      const primary = setbackRecs.filter((r) => r.topic in PRIMARY && r.class10);
      const unrelated = setbackRecs.filter((r) => !(r.topic in PRIMARY && r.class10));
      const flagged = new Map<string, Set<string>>();
      const flag = (r: any, sev: Severity, type: string, detail: string, extra: Partial<Issue> = {}) => {
        const s = r.sources?.[0] ?? {};
        issue({ issue_type: type, severity: sev, detail, rule_version_id: r.rule_version_id, status: r.status, topic: r.topic,
          provision: s.ref_label ? `${s.ref_label}${s.page ? ` (${s.page})` : ""}` : "", source_url: s.url ?? r.iv_url ?? "",
          evidence: clip(s.quote ?? s.text), ...extra });
        if (!flagged.has(r.rule_version_id)) flagged.set(r.rule_version_id, new Set());
        flagged.get(r.rule_version_id)!.add(`${sev}:${type}`);
      };

      const counters = { mismatch: new Set<string>(), classification: new Set<string>(), duplicate: new Set<string>(), traceability: 0, integrity: 0 };
      // Drafts carry the researcher's topic only: widen SIDE drafts whose text covers rear too, recognise the
      // researcher's "no value in the scheme" notes, and spot drafts that are really an excluded category.
      for (const r of primary) {
        const s = r.sources[0] ?? {};
        const text = `${s.text ?? ""}`;
        r.cats = [...CATEGORY[r.topic]];
        r.note = null;
        if (r.status !== "DRAFT") continue;
        const decided = decisions.get(r.rule_id);
        if (decided) {
          r.decision = decided;
          if (SETTLED.has(decided.decision)) { r.note = decided.decision === "DOCUMENTED_ABSENCE" ? "ABSENCE" : "DECIDED"; continue; }
        }
        // every extracted cell says "Refer to standard(s) as in QDC": the scheme defers to the QDC (no council value)
        const cells = /"conditions": \[(.*?)\], "exceptions"/s.exec(r.interpretation_notes ?? "")?.[1]?.split(/",\s*"/) ?? [];
        if (cells.length && cells.every((x) => /refer to standards? (as )?in (the )?QDC/i.test(x))) {
          r.note = "ABSENCE";
          r.deferral = true;
          continue;
        }
        if (/^\s*\(/.test(text) && /\bno\b|\bonly\b/i.test(text)) {
          r.note = "ABSENCE";
          if (VERIFIED.has(s.verification))
            flag(r, "WARNING", "TRACE_RESEARCHER_NOTE_MARKED_VERBATIM", `Provision text is a researcher's note about what the scheme does not say, but is stored as ${s.verification}`,
              { recommended_fix: "Set the provision's verification to UNVERIFIED in research/councils/<slug>.json (it is not scheme text) and regenerate db/030." });
          if (/side\/rear|side and rear|side or rear/i.test(text)) r.cats = ["SIDE", "REAR"];
          continue;
        }
        if (r.topic === "SETBACK.SIDE" && /side and rear|side or rear|rear and side|side\/rear|all boundaries/i.test(text)) {
          r.cats = ["SIDE", "REAR"];
          flag(r, "WARNING", "CLASSIFICATION_DRAFT_TOPIC_NARROW", "Draft is tagged SIDE but the source text sets side AND rear setbacks",
            { recommended_fix: "Curate as SETBACK.SIDE_REAR (or two rules)." });
        }
        if (/seawall|foreshore|revetment|road widening|top of bank|easement|buffer/i.test(text) && /\b(side|rear)\b/i.test(text)) {
          flag(r, "WARNING", "CLASSIFICATION_DRAFT_AMBIGUOUS", `Draft tagged ${r.topic} names a side/rear boundary but serves an excluded purpose (seawall/revetment/road widening/buffer)`,
            { recommended_fix: "Planner to decide whether this is a boundary setback (primary) or an access/buffer requirement (related category)." });
        } else if (/seawall|foreshore|revetment|road widening|top of bank|easement|buffer/i.test(text)) {
          r.note = "EXCLUDED";
          flag(r, "WARNING", "CLASSIFICATION_DRAFT_EXCLUDED_CATEGORY", `Draft tagged ${r.topic} describes an excluded category (seawall/revetment/road widening/buffer), not a ${CATEGORY[r.topic].join("/").toLowerCase()} boundary setback`,
            { recommended_fix: "Re-tag to the related topic (e.g. SETBACK.WATERWAY / road widening) so it stays out of the primary dataset." });
        }
      }
      for (const r of primary) {
        if (r.status === "DRAFT" && r.decision) continue;   // reviewed (validation/curation_decisions.json)
        const spec = PRIMARY[r.topic];
        const lgScopes = r.scopes.filter((s: any) => s.level === "LOCAL_GOVERNMENT");
        const active = r.status === "ACTIVE";
        // integrity
        if (lgScopes.length !== 1 || lgScopes[0].lg !== c.lg_id || r.instrument_lg !== c.lg_id) {
          flag(r, "ERROR", "INTEGRITY_COUNCIL_LINK", `Council scope ${JSON.stringify(lgScopes.map((s: any) => s.lg))}, instrument council ${r.instrument_lg}`); counters.integrity++;
        }
        if (r.iv_instrument !== r.instrument_id) { flag(r, "ERROR", "INTEGRITY_SCHEME_LINK", `Rule instrument ${r.instrument_id} but version belongs to ${r.iv_instrument}`); counters.integrity++; }
        if (r.iv_to || r.iv_status !== "ACTIVE") { flag(r, "ERROR", "INTEGRITY_SCHEME_VERSION", `Rule points at scheme version ${r.instrument_version_id} (status ${r.iv_status}, to ${r.iv_to})`); counters.integrity++; }
        if (!r.subjects.length) { flag(r, "ERROR", "INTEGRITY_NO_STRUCTURE", "Rule has no structure subjects"); counters.integrity++; }
        if (r.effective_to && active) { flag(r, "ERROR", "INTEGRITY_ACTIVE_EXPIRED", `ACTIVE rule has effective_to ${r.effective_to}`); counters.integrity++; }
        const out = outputs(r.value_expr);
        if (active && out.kind === "UNENCODED") {
          if (r.automatable) { flag(r, "ERROR", "INTEGRITY_ACTIVE_UNENCODED", "ACTIVE automatable rule has an unencoded value"); counters.integrity++; }
          else flag(r, "WARNING", "MANUAL_REVIEW_QUALITATIVE", "ACTIVE rule is qualitative (unencoded value); always manual review", { evidence: clip(r.value_expr?.text) });
        }
        if (active && r.role !== "EXEMPTION" && r.unit !== "m") { flag(r, "ERROR", "INTEGRITY_UNIT", `Unit is ${JSON.stringify(r.unit)}, expected m`); counters.integrity++; }
        if (!active && r.unit && !/^(m|metres?)$/i.test(r.unit)) flag(r, "WARNING", "INTEGRITY_UNIT", `Draft unit ${JSON.stringify(r.unit)}`);
        for (const v of out.values) if (!(v >= 0 && v <= 500)) { flag(r, "ERROR", "INTEGRITY_VALUE_RANGE", `Setback value ${v} outside 0–500 m`); counters.integrity++; }
        if (active && r.role !== "EXEMPTION" && r.operator !== ">=") flag(r, "WARNING", "INTEGRITY_OPERATOR", `Operator ${r.operator} (minimum setbacks use >=)`);
        if (r.status === "SUPERSEDED" && !r.replaced_by.some((x: string) => x.endsWith(":ACTIVE"))) {
          flag(r, "ERROR", "INTEGRITY_SUPERSEDED_ORPHAN", "SUPERSEDED but no ACTIVE rule REPLACES it"); counters.integrity++;
        }

        // classification (topic vs measurement vs boundary condition); active requirements/relaxations only — drafts carry
        // no conditions, and exemptions (QDC A2(c)-style) carry no measurement or value
        if (active && r.role !== "EXEMPTION") {
          if (spec.measurements.length && !spec.measurements.includes(r.measurement_id)) {
            flag(r, "ERROR", "CLASSIFICATION_MEASUREMENT", `Topic ${r.topic} measured by ${r.measurement_id}`); counters.classification.add(r.rule_version_id);
          }
          const b = boundaryValues(r.conditions);
          if (!b.length) {
            // The engine has no implicit per-measurement boundary restriction: conditionsHold() on an empty/boundary-less
            // condition group returns true for every boundary pass (front, side, rear, secondary), so a rule with no
            // boundary_type condition is evaluated as a candidate on ALL of them, not just the one its topic/title implies.
            // Confirmed live by a user report (23 Oct 2026): LCC.C.CARPORT_TO_FRONT_BOUNDARY surfaced on side and rear.
            // A single-boundary topic (front-only / side-only / rear-only / secondary-only / garage-frontage) can NEVER
            // legitimately omit the condition; a multi-boundary topic (SIDE_REAR, POOL.SETBACK*) might, if its own
            // source text genuinely covers every one of those boundaries with the same value — still worth a reviewer's look.
            if (spec.boundaries.length === 1)
              flag(r, "ERROR", "CLASSIFICATION_NO_BOUNDARY_CONDITION",
                `No boundary_type condition on a single-boundary topic (${r.topic}): the rule is evaluated as a candidate on every boundary (front, side, rear, secondary), not only ${spec.boundaries[0]}.`,
                { recommended_fix: `Add {"fact": "boundary_type", "op": "=", "value": "${spec.boundaries[0]}"} to the rule's conditions.` });
            else
              flag(r, "WARNING", "CLASSIFICATION_NO_BOUNDARY_CONDITION",
                `No boundary_type condition on a multi-boundary topic (${r.topic}, ${spec.boundaries.join("/")}): confirm the source text covers every one of those boundaries with the same value, otherwise the rule leaks onto boundaries it shouldn't.`,
                { recommended_fix: "Add an explicit boundary_type IN [...] condition, or confirm the source text covers all these boundaries uniformly." });
            counters.classification.add(r.rule_version_id);
          }
          const wrong = b.filter((x) => !spec.boundaries.includes(x) && !(isFront(r.topic) && x.startsWith("SECONDARY_FRONTAGE")));
          if (wrong.length) { flag(r, "ERROR", "CLASSIFICATION_BOUNDARY", `Topic ${r.topic} applies to boundary ${wrong.join(", ")}`); counters.classification.add(r.rule_version_id); }
          if (b.length && !spec.boundaries.some((x) => b.includes(x))) { flag(r, "ERROR", "CLASSIFICATION_BOUNDARY", `Topic ${r.topic} has no ${spec.boundaries.join("/")} boundary condition (${b.join(", ")})`); counters.classification.add(r.rule_version_id); }
          if (r.topic === "SETBACK.SIDE" && b.includes("REAR")) { flag(r, "ERROR", "CLASSIFICATION_BOUNDARY", "SIDE topic also applied to REAR (should be SIDE_REAR)"); counters.classification.add(r.rule_version_id); }
          const quote = norm(r.sources.map((s: any) => `${s.quote ?? ""} ${s.text ?? ""}`).join(" ") + " " + r.supplementary_text);
          if (isFront(r.topic) && b.some((x) => x.startsWith("SECONDARY")) &&
              !/road|street|frontages|all (site )?boundaries|any boundary|each frontage|primary and secondary|secondary/.test(quote))
            flag(r, "WARNING", "CLASSIFICATION_SECONDARY_FRONTAGE_EXTENDED", `Front rule also applied to ${b.filter((x) => x.startsWith("SECONDARY")).join(", ")}, but the source text names only the front.`,
              { recommended_fix: "Confirm with the scheme/council whether the front setback also governs the secondary frontage; otherwise restrict to PRIMARY_FRONTAGE." });
          if (!isFront(r.topic) && !/side|rear|boundar/.test(quote)) {
            flag(r, "WARNING", "CLASSIFICATION_TEXT_SUSPECT", `Source text for ${r.topic} does not mention side/rear/boundary.`,
              { recommended_fix: "If the PRIMARY provision is a fragment, cite the provision holding its lead-in (e.g. 'minimum side and rear boundary clearances') as a SUPPLEMENTARY source; otherwise reclassify." }); counters.classification.add(r.rule_version_id);
          }
          if (!isFront(r.topic) && r.topic !== "SETBACK.SIDE_REAR.BTB" && /easement|buffer|canal|revetment|waterway|between (the )?buildings|separation/.test(quote) && !/side|rear|boundar/.test(quote)) {
            flag(r, "ERROR", "CLASSIFICATION_EXCLUDED_CATEGORY", "Text describes an excluded category (easement/buffer/waterway/separation)"); counters.classification.add(r.rule_version_id);
          }
        }

        // traceability
        if (!r.sources.length) { flag(r, "ERROR", "TRACE_NO_PRIMARY_SOURCE", "No PRIMARY source"); counters.traceability++; }
        for (const s of r.sources) {
          if (!s.text) { flag(r, "ERROR", "TRACE_EMPTY_SOURCE_TEXT", `Primary provision ${s.ref_label} has no verbatim text`); counters.traceability++; }
          if (!VERIFIED.has(s.verification) && r.note !== "ABSENCE") flag(r, active ? "ERROR" : "WARNING", "TRACE_SOURCE_UNVERIFIED", `Primary provision verification ${s.verification}`);
          if (!(s.url ?? r.iv_url)) { flag(r, "ERROR", "TRACE_NO_URL", "No source URL on provision or scheme version"); counters.traceability++; }
          if (!s.page && !s.url) flag(r, "WARNING", "TRACE_NO_LOCATION", "Provision has neither page nor URL anchor");
          if (s.iv !== r.instrument_version_id) { flag(r, "ERROR", "TRACE_SOURCE_OTHER_VERSION", `Source provision is in ${s.iv}, rule in ${r.instrument_version_id}`); counters.traceability++; }
          if (s.quote && s.text && s.quote.split(/\.\.\.|…/).map(norm).filter((q: string) => q.length > 2).some((q: string) => !norm(s.text).includes(q)))
            flag(r, "WARNING", "TRACE_QUOTE_NOT_IN_SOURCE", "Quote is not a verbatim substring of the stored provision text (after whitespace/table-separator normalisation).",
              { recommended_fix: "Compare quote with provision text; correct the quote if it was paraphrased." });
        }
        if (VERIFIED.has(r.verification) && r.sources.every((s: any) => !VERIFIED.has(s.verification))) {
          flag(r, "ERROR", "TRACE_VERIFIED_WITHOUT_EVIDENCE", "Rule marked verified but its source provision is not"); counters.traceability++;
        }
        // value vs source text
        const text = r.sources.map((s: any) => `${s.quote ?? ""} ${s.text ?? ""}`).join(" ") + " " + (r.supplementary_text ?? "");
        for (const v of out.values) {
          // a built-to-boundary allowance is 0 m by definition
          const hit = v === 0 && r.topic === "SETBACK.SIDE_REAR.BTB" ? "unit" : valueInText(v, text);
          if (hit === "no") {
            flag(r, active ? "ERROR" : "WARNING", "VALUE_NOT_IN_SOURCE", `Value ${fmtNum(v)} m not found in the quote or provision text`,
              { recommended_fix: "Check the value against the scheme; correct the rule or cite the provision that states it." });
            counters.mismatch.add(r.rule_version_id);
          } else if (hit === "bare") flag(r, "INFO", "VALUE_UNITLESS_IN_SOURCE", `Value ${fmtNum(v)} appears in the source without a unit`);
        }
        if (active && out.kind === "FORMULA") flag(r, "INFO", "VALUE_FORMULA", "Formula-based requirement: constants checked, expression to be confirmed by reviewer",
          { evidence: JSON.stringify(r.value_expr) });
        if (active && !r.automatable) flag(r, "WARNING", "MANUAL_REVIEW_NOT_AUTOMATABLE", "ACTIVE but automatable = false (engine routes to manual review)", { evidence: clip(r.interpretation_notes) });
      }

      // duplicates / conflicts among ACTIVE primary rules
      const groups = new Map<string, any[]>();
      for (const r of primary.filter((x) => x.status === "ACTIVE")) {
        const key = JSON.stringify([r.topic, r.measurement_id, r.scopes, r.subjects, r.conditions]);
        groups.set(key, [...(groups.get(key) ?? []), r]);
      }
      for (const g of groups.values()) {
        if (g.length < 2) continue;
        const same = new Set(g.map((r) => JSON.stringify(r.value_expr))).size === 1;
        for (const r of g) {
          flag(r, "ERROR", same ? "DUPLICATE_RECORD" : "CONFLICTING_VALUES", `${same ? "Identical" : "Different values for identical"} applicability with ${g.filter((x) => x !== r).map((x) => x.rule_version_id).join(", ")}`);
          counters.duplicate.add(r.rule_version_id);
        }
      }
      const dupProv: any[] = await db.q(`SELECT coalesce(json_agg(research_key), '[]') FROM (SELECT research_key FROM regs.provisions WHERE instrument_version_id = ${lit(iv.id)}
         AND research_key IS NOT NULL GROUP BY research_key HAVING count(*) > 1) x`);
      for (const k of dupProv) issue({ issue_type: "DUPLICATE_PROVISION", severity: "ERROR", detail: `research_key ${k} loaded more than once` });

      // ---- completeness
      const activeByProvision = new Set(primary.filter((r) => r.status === "ACTIVE").flatMap((r) => r.sources.map((s: any) => s.provision_id)));
      for (const r of primary.filter((x) => x.status === "DRAFT")) {
        const s = r.sources[0] ?? {};
        const out = outputs(r.value_expr);
        const [gap, assessment, action] =
          r.decision ? [`REVIEWED_${r.decision.decision}`, r.decision.reason, r.decision.decision === "MANUAL_REVIEW" ? "Manual review by a planner/certifier" : "None (reviewed; see validation/curation_decisions.json)"]
          : r.deferral ? ["DOCUMENTED_ABSENCE", "Scheme cell reads 'Refer to standard as in QDC': the council sets no value and the QDC MP 1.1/1.2 clearance applies — genuinely absent, not missing", "None (the draft is the record of the deferral)"]
          : r.note === "ABSENCE" ? ["DOCUMENTED_ABSENCE", "Researcher recorded that the scheme sets no council value here (QDC MP 1.1/1.2 default applies): genuinely absent, not missing", "None (keep as evidence); confirm against the current scheme on the next version update"]
          : r.note === "EXCLUDED" ? ["EXCLUDED_CATEGORY_DRAFT", "Not a front/side/rear setback (excluded category); belongs outside the primary dataset", "Re-tag the draft's topic"]
          : activeByProvision.has(s.provision_id) ? ["DRAFT_NOT_CURATED", "Provision already feeds an ACTIVE rule; draft may be redundant — confirm and supersede", "Confirm and supersede"]
          : ["DRAFT_NOT_CURATED", "Requirement is in the source and the database but not in the primary (ACTIVE) dataset", "Curate into db/03x (or document why it is excluded)"];
        missing.push({ council: c.name, lg_id: c.lg_id, gap_type: gap, category: r.cats.join("+"), zone_or_place: r.scopes.filter((x: any) => x.level !== "LOCAL_GOVERNMENT").map((x: any) => x.place).join("; ") || "council-wide",
          rule_version_id: r.rule_version_id, provision: s.ref_label ?? "", page: s.page ?? "", source_url: s.url ?? r.iv_url, extracted_value: out.values.map(fmtNum).join(" / "),
          source_extract: clip(s.text, 400), verification: s.verification, also_cited_by_active_rule: activeByProvision.has(s.provision_id),
          assessment, recommended_action: action });
      }
      // provisions that talk about front/side/rear setbacks but no setback rule cites them
      const cited = new Set(setbackRecs.flatMap((r) => r.sources.map((s: any) => s.provision_id)));
      const candidates: any[] = await db.q(`SELECT coalesce(json_agg(json_build_object('id', provision_id, 'ref', ref_label, 'page', coalesce(page_label, pdf_page::text), 'url', url_anchor, 'text', verbatim_text, 'kind', kind, 'v', verification) ORDER BY provision_id), '[]')
        FROM regs.provisions WHERE instrument_version_id = ${lit(iv.id)} AND kind NOT IN ('DEFINITION','LEVEL_OF_ASSESSMENT','APPLICATION')
         AND verbatim_text ~* '(set ?back|setbacks)' AND verbatim_text ~* '(front|side|rear|road|street)'`);
      for (const p of candidates.filter((p) => !cited.has(p.id))) {
        const ruleOf = recs.find((r) => r.sources.some((s: any) => s.provision_id === p.id));
        missing.push({ council: c.name, lg_id: c.lg_id, gap_type: "SOURCE_PROVISION_NOT_CLASSIFIED_AS_SETBACK", category: "UNKNOWN", zone_or_place: "",
          rule_version_id: ruleOf?.rule_version_id ?? "", provision: p.ref, page: p.page ?? "", source_url: p.url ?? iv.url, extracted_value: "",
          source_extract: clip(p.text, 400), verification: p.v, also_cited_by_active_rule: false,
          assessment: `Provision mentions setbacks but is filed under ${ruleOf ? ruleOf.topic : `provision kind ${p.kind}`}; may hold a front/side/rear requirement`,
          recommended_action: "Manual review: classify as primary setback, related category, or not a setback" });
      }
      // residential-type zones with no council rule per category
      const zones: any[] = await db.q(`SELECT coalesce(json_agg(json_build_object('id', z.zone_id, 'name', z.name, 'dh', z.dwelling_house_permitted,
          'precincts', (SELECT coalesce(json_agg(p.precinct_id), '[]') FROM regs.precincts p WHERE p.zone_id = z.zone_id)) ORDER BY z.zone_id), '[]')
        FROM regs.zones z JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = ${lit(c.lg_id)}`);
      for (const z of zones.filter((z) => z.dh !== false)) {
        for (const cat of ["FRONT", "SIDE", "REAR"]) {
          // FULL when a rule is zone-wide or every precinct of the zone is covered; PARTIAL when some precincts are
          const level = (pick: (r: any) => boolean) => {
            const covered = new Set<string>();
            for (const r of primary.filter((r) => pick(r) && r.cats.includes(cat))) {
              const places = r.scopes.filter((s: any) => s.level !== "LOCAL_GOVERNMENT" && !s.exclude).map((s: any) => s.place);
              if (!places.length || places.includes(z.id)) return "FULL";
              for (const p of places) if (z.precincts.includes(p) || p.startsWith(z.id + "/")) covered.add(p);
            }
            return z.precincts.length && z.precincts.every((p: string) => covered.has(p)) ? "FULL" : covered.size ? "PARTIAL" : "NONE";
          };
          const isActive = (r: any) => r.status === "ACTIVE", isAbsence = (r: any) => r.status === "DRAFT" && r.note === "ABSENCE";
          const act = level(isActive), dr = level((r) => r.status === "DRAFT" && r.note === null), absent = level(isAbsence);
          if (act === "FULL") continue;
          // council value where the scheme sets one, documented QDC deferral everywhere else: fully accounted for
          if (act !== "NONE" && level((r) => isActive(r) || isAbsence(r)) === "FULL") continue;
          if (act === "NONE" && dr === "NONE" && absent === "FULL") {
            missing.push({ council: c.name, lg_id: c.lg_id, gap_type: "ZONE_GENUINELY_ABSENT", category: cat, zone_or_place: `${z.id} (${z.name})`, rule_version_id: "", provision: "", page: "",
              source_url: iv.url, extracted_value: "", source_extract: "", verification: "", also_cited_by_active_rule: false,
              assessment: "Research records that the scheme sets no council value for this zone/category; QDC MP 1.1/1.2 applies", recommended_action: "None" });
            continue;
          }
          missing.push({ council: c.name, lg_id: c.lg_id, gap_type: act === "PARTIAL" ? "ZONE_PARTIAL_COVERAGE" : dr !== "NONE" ? "ZONE_DRAFT_ONLY" : "ZONE_NO_COUNCIL_RULE",
            category: cat, zone_or_place: `${z.id} (${z.name})`, rule_version_id: "", provision: "", page: "", source_url: iv.url, extracted_value: "", source_extract: "",
            verification: "", also_cited_by_active_rule: false,
            assessment: act === "PARTIAL" ? "Council rule covers only some precincts/places of this zone; elsewhere the QDC MP 1.1/1.2 default applies unless the scheme says otherwise"
              : dr !== "NONE" ? "Only an uncurated draft exists for this zone/category"
              : "No council provision in the research or database: either the scheme defers to QDC MP 1.1/1.2 (genuinely absent) or it was not researched — not determinable from held material",
            recommended_action: act === "PARTIAL" ? "None if the precinct scoping matches the scheme; otherwise research the rest of the zone" : "Check the zone code / dwelling house code table of the current scheme and record either the requirement or an explicit 'defers to QDC' note" });
        }
      }

      // ---- per-record audit rows
      for (const r of setbackRecs) {
        const s = r.sources[0] ?? {};
        const out = outputs(r.value_expr);
        const f = [...(flagged.get(r.rule_version_id) ?? [])];
        const isPrimary = r.topic in PRIMARY && r.class10;
        const verified = isPrimary && r.status === "ACTIVE" && VERIFIED.has(r.verification) && !f.some((x) => x.startsWith("ERROR"));
        audit.push({ council: c.name, lg_id: c.lg_id, rule_version_id: r.rule_version_id, dataset: isPrimary ? "PRIMARY_CLASS10" : r.topic in PRIMARY ? "NOT_CLASS10" : "RELATED_EXCLUDED", topic: r.topic,
          status: r.status, verification: r.verification, automatable: r.automatable, value_kind: out.kind, values_m: out.values.map(fmtNum).join(" / "),
          value_expr: r.value_expr, unit: r.unit ?? "", measurement: r.measurement_id ?? "", boundaries: boundaryValues(r.conditions).join(" "),
          structures: r.subjects.map((x: any) => (x.exclude ? "-" : "") + x.id).join(" "),
          places: r.scopes.filter((x: any) => x.level !== "LOCAL_GOVERNMENT").map((x: any) => `${x.level}:${x.place}${x.exclude ? "(excl)" : ""}`).join(" "),
          conditions: r.conditions.filter((x: any) => x.fact_id !== "boundary_type").map((x: any) => `${x.group}:${x.fact_id} ${x.op} ${JSON.stringify(x.value)}`).join("; "),
          scheme_version: r.instrument_version_id, provision: s.ref_label ?? "", page: s.page ?? "", source_url: s.url ?? r.iv_url ?? "", quote: clip(s.quote ?? s.text, 250),
          check_result: verified ? "VERIFIED" : r.topic in PRIMARY && !r.class10 ? "NOT_CLASS10" : !isPrimary ? "EXCLUDED_CATEGORY" : r.status !== "ACTIVE" ? `NOT_IN_PRIMARY_DATASET (${r.status})` : "NEEDS_REVIEW",
          flags: f.join(" ") });
      }

      // ---- council summary
      const activePrimary = primary.filter((r) => r.status === "ACTIVE");
      const verifiedN = audit.filter((x) => x.lg_id === c.lg_id && x.check_result === "VERIFIED").length;
      const myIssues = issues.filter((x) => x.lg_id === c.lg_id);
      const reviewRecs = new Set(myIssues.filter((x) => x.rule_version_id && x.severity === "WARNING" && primary.some((r) => r.rule_version_id === x.rule_version_id && r.status === "ACTIVE")).map((x) => x.rule_version_id));
      const errs = myIssues.filter((x) => x.severity === "ERROR");
      const myMissing = missing.filter((x) => x.lg_id === c.lg_id && !["DOCUMENTED_ABSENCE", "ZONE_GENUINELY_ABSENT", "EXCLUDED_CATEGORY_DRAFT",
        "REVIEWED_OUT_OF_SCOPE", "REVIEWED_EXCLUDED_CATEGORY", "REVIEWED_DOCUMENTED_ABSENCE"].includes(x.gap_type));
      const has = (re: RegExp) => errs.some((x) => re.test(x.issue_type));
      const integrity = has(/^(INTEGRITY|DUPLICATE|CONFLICT|SCHEME_VERSION_(COUNT|NOT_ACTIVE))/) ? "FAIL" : "PASS";
      const trace = has(/^(TRACE|VALUE)/) ? "FAIL" : myIssues.some((x) => /^TRACE/.test(x.issue_type)) ? "PASS_WITH_WARNINGS" : "PASS";
      const scope = has(/^CLASSIFICATION/) ? "FAIL" : myIssues.some((x) => /^CLASSIFICATION/.test(x.issue_type)) ? "PASS_WITH_WARNINGS" : "PASS";
      const regression = cfg.regression_councils.includes(c.lg_id) ? (pipelineOk ? "PASS" : "FAIL") : "N/A";
      const overall = !pipelineOk || errs.length ? "FAIL"
        : (myIssues.some((x) => x.severity === "WARNING") || myMissing.length || sc.status !== "CURRENT") ? "PASS_WITH_WARNINGS" : "PASS";
      const top = [...new Set(myIssues.filter((x) => x.severity !== "INFO").map((x) => x.issue_type))].map((t) => `${t} x${myIssues.filter((x) => x.issue_type === t).length}`);
      const gapTypes = [...new Set(myMissing.map((x) => x.gap_type))].map((t) => `${t} x${myMissing.filter((x) => x.gap_type === t).length}`);
      summary.push({ ...row, source_document_availability: `research file + ${src.n} verbatim provisions in DB (${src.docs} source document/URL${src.docs === 1 ? "" : "s"}); source PDFs/ePlan pages not archived locally`,
        source_files_inspected: src.docs, existing_db_records: setbackRecs.length, records_examined: setbackRecs.length,
        primary_records: primary.length, primary_active_records: activePrimary.length, verified_records: verifiedN,
        value_mismatches: [...counters.mismatch].filter((id) => activePrimary.some((r) => r.rule_version_id === id)).length,
        draft_value_mismatches: [...counters.mismatch].filter((id) => !activePrimary.some((r) => r.rule_version_id === id)).length,
        classification_errors: [...new Set(errs.filter((x) => /^CLASSIFICATION/.test(x.issue_type)).map((x) => x.rule_version_id))].length,
        missing_setback_requirements: myMissing.length, unrelated_records: unrelated.length, duplicates: counters.duplicate.size,
        manual_review_records: reviewRecs.size, pipeline_status: pipelineOk ? "PASS" : "FAIL", data_integrity: integrity, source_traceability: trace,
        scope_test: scope, regression_test: regression, overall_status: overall, outstanding_issues: [...top, ...gapTypes].join("; ") });
    }

    // Regression: the original councils not in the 14 (pipeline only)
    for (const lg of cfg.regression_councils.filter((x: string) => !cfg.councils.some((c: any) => c.lg_id === x))) {
      const slug = lg.toLowerCase();
      const built = build(slug);
      const ok = built !== null && fs.readFileSync(outFile(slug), "utf-8") === built[0]
        && verify.out.split(/\r?\n/).filter((l) => l.startsWith(slug.padEnd(15))).every((l) => / OK$/.test(l));
      console.log(`[regression] ${lg} (outside the 14): pipeline ${ok ? "PASS" : "FAIL"}`);
    }

    const after = await fingerprint(db);
    console.log(`[database] fingerprint ${before === after ? "unchanged" : "CHANGED"} during the run`);
    if (before !== after) throw new Error("database changed during a read-only validation run");
    fs.writeFileSync(path.join(outDir, "db_fingerprint.txt"), after.split(" ").join("\n") + "\n");
  } finally {
    await db.close();
  }

  const SUMMARY_COLS = ["council", "lg_id", "spreadsheet_scheme", "db_scheme", "db_version", "db_effective_from", "online_version_check", "online_current_version",
    "source_document_availability", "source_files_inspected", "existing_db_records", "records_examined", "primary_records", "primary_active_records",
    "verified_records", "value_mismatches", "draft_value_mismatches", "classification_errors", "missing_setback_requirements", "unrelated_records", "duplicates",
    "manual_review_records", "pipeline_status", "data_integrity", "source_traceability", "scope_test", "regression_test", "overall_status", "outstanding_issues"];
  const ISSUE_COLS = ["issue_id", "council", "lg_id", "severity", "issue_type", "rule_version_id", "status", "topic", "provision", "source_url", "detail", "evidence", "recommended_fix", "resolution_status"];
  const sevOrder = { ERROR: 0, WARNING: 1, INFO: 2 };
  issues.sort((x, y) => x.council.localeCompare(y.council) || sevOrder[x.severity] - sevOrder[y.severity] || x.issue_type.localeCompare(y.issue_type) || x.rule_version_id.localeCompare(y.rule_version_id));
  const numbered = issues.map((x, i) => ({ issue_id: `V${String(i + 1).padStart(4, "0")}`, ...x }));
  const write = (f: string, rows: any[], cols: string[]) => fs.writeFileSync(path.join(outDir, f), csv(rows, cols), "utf-8");
  write("council_validation_summary.csv", summary, SUMMARY_COLS);
  write("validation_issues.csv", numbered, ISSUE_COLS);
  write("missing_setbacks.csv", missing, ["council", "lg_id", "gap_type", "category", "zone_or_place", "rule_version_id", "provision", "page", "source_url", "extracted_value", "source_extract", "verification", "also_cited_by_active_rule", "assessment", "recommended_action"]);
  write("source_coverage.csv", coverage, ["council", "lg_id", "spreadsheet_scheme", "spreadsheet_url", "spreadsheet_link_status", "current_scheme_found", "version_status", "source_format", "setback_code_location", "evidence_url", "evidence_quote", "in_database", "research_file", "db_scheme", "db_version", "db_effective_from", "db_source_url", "provisions_in_db", "distinct_source_documents", "provisions_with_location", "open_issues_unresolved", "notes"]);
  write("setback_records_audit.csv", audit, ["council", "lg_id", "rule_version_id", "dataset", "topic", "status", "verification", "automatable", "value_kind", "values_m", "value_expr", "unit", "measurement", "boundaries", "structures", "places", "conditions", "scheme_version", "provision", "page", "source_url", "quote", "check_result", "flags"]);
  if (!fs.existsSync(path.join(outDir, "change_log.csv")))
    write("change_log.csv", [], ["change_id", "date", "council", "table", "record_id", "field", "old_value", "new_value", "reason", "evidence", "backup_file", "approved_by"]);

  for (const s of summary) console.log(`${s.overall_status.padEnd(19)} ${s.council.padEnd(36)} primary ${String(s.primary_active_records ?? 0).padStart(3)} active, ${String(s.verified_records).padStart(3)} verified, ${String(s.manual_review_records).padStart(2)} review, ${String(s.missing_setback_requirements).padStart(3)} gaps`);
  console.log(`issues: ${issues.filter((x) => x.severity === "ERROR").length} error, ${issues.filter((x) => x.severity === "WARNING").length} warning, ${issues.filter((x) => x.severity === "INFO").length} info → ${path.relative(ROOT, outDir) || "."}`);
  return 0;
}

main().then(exit, (e) => { console.error(e); exit(1); });
