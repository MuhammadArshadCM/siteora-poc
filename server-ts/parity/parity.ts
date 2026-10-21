/**
 * Parity / regression test: the TypeScript code must keep giving the answers recorded from the original Python
 * reference implementation (parity/golden/*.json, recorded 2026-10-16 before the Python code was retired).
 *
 *   npm run parity                     all parts (part 3 calls live council / State map services)
 *   npm run parity:offline             without part 3 (database only, no internet)
 *   npm run parity -- --record         re-record the golden files from the current TypeScript output
 *                                      (only after reviewing a reported difference and deciding it is correct)
 *
 * 0. Comparator self-check   a deliberately wrong result must be caught
 * 1. Python primitives       pyRound / truthiness / urlencode against values recorded from real Python
 * 2. Rule evaluator          every examples/*.json scenario: resolve() vs golden/examples.json, and the report vs
 *                            the recorded examples/*.out.md
 * 3. Engine end to end       parity/cases.json (all 7 councils, 2026 and 2029 dates, manual zone, error cases):
 *                            engine.run() vs golden/engine.json, full API response (live map services)
 * 4. SQL generator           research/councils/*.json → db/030_council_*.sql reproduces the files byte for byte
 *
 * Comparison is semantic: numbers numerically (1e-9), null == missing key, rule lists in canonical order, and the one
 * cosmetic difference normalised — Python printed integer-valued floats as "612.0", JavaScript prints "612".
 * Exit code 0 = parity, 1 = differences (listed).
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Db } from "../src/core/db.js";
import { loadEnv, ROOT } from "../src/core/env.js";
import * as engine from "../src/core/engine.js";
import * as evaluate from "../src/core/evaluate.js";
import { pyRound, truthy, urlencode, LookupError, ValueError } from "../src/core/py.js";
import { ServiceUnavailable } from "../src/core/geo.js";
import { build, COUNCILS, outFile } from "../src/tools/import-council-research.js";

loadEnv();
const HERE = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..", "parity");
const GOLDEN = path.join(HERE, "golden");
const offline = process.argv.includes("--offline");
const record = process.argv.includes("--record");
let failures = 0;
let skipped = 0;   // cases skipped because a service did not answer (not counted as failures)

const golden = (name: string) => JSON.parse(fs.readFileSync(path.join(GOLDEN, name), "utf-8"));
const saveGolden = (name: string, v: unknown) => fs.writeFileSync(path.join(GOLDEN, name), JSON.stringify(v), "utf-8");

// ----------------------------------------------------------------------------- comparison
const normStr = (s: string) => s.replace(/(\d)\.0(?!\d)/g, "$1");

function canon(v: any): any {
  if (Array.isArray(v)) {
    const xs = v.map(canon);
    if (xs.length && xs.every((x) => x && typeof x === "object" && !Array.isArray(x) && "rule" in x)) {
      const key = (x: any) => JSON.stringify([x.structure ?? "", x.boundary ?? "", x.rule, x.state ?? ""]);
      return xs.sort((a, b) => (key(a) < key(b) ? -1 : key(a) > key(b) ? 1 : 0));
    }
    return xs;
  }
  if (v && typeof v === "object") {
    const out: Record<string, any> = {};
    for (const k of Object.keys(v).sort()) {
      if (v[k] === undefined || v[k] === null) continue;
      out[k] = canon(v[k]);
      // a site constraint's values / details have no meaningful order (services return features in any order)
      if ((k === "values" || k === "details") && Array.isArray(out[k]))
        out[k] = [...out[k]].sort((a: any, b: any) => (JSON.stringify(a) < JSON.stringify(b) ? -1 : JSON.stringify(a) > JSON.stringify(b) ? 1 : 0));
    }
    return out;
  }
  return v;
}

function diff(a: any, b: any, p: string, out: string[]): void {
  if (out.length > 40) return;
  if (typeof a === "number" && typeof b === "number") {
    if (Math.abs(a - b) > 1e-9 * Math.max(1, Math.abs(a))) out.push(`${p}: expected=${a} ts=${b}`);
    return;
  }
  if (typeof a === "string" && typeof b === "string") {
    if (normStr(a) !== normStr(b)) out.push(`${p}: expected=${JSON.stringify(a).slice(0, 160)} ts=${JSON.stringify(b).slice(0, 160)}`);
    return;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    if (a.length !== b.length) out.push(`${p}: length expected=${a.length} ts=${b.length}`);
    for (let i = 0; i < Math.min(a.length, b.length); i++) diff(a[i], b[i], `${p}[${i}]`, out);
    return;
  }
  if (a && b && typeof a === "object" && typeof b === "object") {
    for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
      if (!(k in a)) out.push(`${p}.${k}: not expected (ts=${JSON.stringify(b[k]).slice(0, 80)})`);
      else if (!(k in b)) out.push(`${p}.${k}: missing in ts (expected=${JSON.stringify(a[k]).slice(0, 80)})`);
      else diff(a[k], b[k], `${p}.${k}`, out);
    }
    return;
  }
  if (a !== b) out.push(`${p}: expected=${JSON.stringify(a)} ts=${JSON.stringify(b)}`);
}

function report(name: string, d: string[], note = ""): void {
  if (d.length) {
    failures++;
    console.log(`  FAIL  ${name}${note}`);
    for (const x of d.slice(0, 15)) console.log(`          ${x}`);
    if (d.length > 15) console.log(`          … ${d.length - 15} more`);
  } else console.log(`  ok    ${name}${note}`);
}

// ----------------------------------------------------------------------------- 0. the comparator itself
function partSelfCheck(): void {
  console.log("0. Comparator self-check (a deliberately wrong result must be caught)");
  const good = [{ rule: "A@1", state: "DETERMINED", required: 6.0, boundary: "SIDE", sources: ["A1(a)"] }];
  const cases: [string, any][] = [
    ["value", [{ ...good[0], required: 5.9 }]], ["state", [{ ...good[0], state: "MANUAL_REVIEW" }]],
    ["missing rule", []], ["extra key", [{ ...good[0], via: "x" }]], ["text", [{ ...good[0], sources: ["A1(b)"] }]],
  ];
  const missed = cases.filter(([, bad]) => { const d: string[] = []; diff(canon(good), canon(bad), "x", d); return d.length === 0; });
  const ok: string[] = []; diff(canon(good), canon([{ ...good[0], required: 6 }]), "x", ok);
  report("detects changed value / state / missing rule / extra field / text; accepts 6.0 == 6",
    [...missed.map(([n]) => `not detected: ${n}`), ...ok.map((x) => `false alarm: ${x}`)]);
}

// ----------------------------------------------------------------------------- 1. primitives
function partPrimitives(): void {
  console.log("1. Python primitives (values recorded from real Python)");
  const g = golden("primitives.json");
  const d: string[] = [];
  g.round.values.forEach((x: number, i: number) => g.round.digits.forEach((n: number, j: number) => {
    const t = pyRound(x, n);
    if (t !== g.round.expected[i][j]) d.push(`round(${x}, ${n}): python=${g.round.expected[i][j]} ts=${t}`);
  }));
  report("round() half-to-even on exact binary values", d);
  report("truthiness", g.truthiness.values.map((x: any, i: number) =>
    truthy(x) !== g.truthiness.expected[i] ? `bool(${JSON.stringify(x)}): python=${g.truthiness.expected[i]} ts=${truthy(x)}` : "").filter(Boolean));
  const u = urlencode(g.urlencode.params);
  report("urlencode (quote_plus)", u === g.urlencode.expected ? [] : [`python=${g.urlencode.expected}`, `ts    =${u}`]);
}

// ----------------------------------------------------------------------------- 2. evaluator
async function partEvaluator(db: Db): Promise<void> {
  console.log("2. Rule evaluator — examples/*.json (database only)");
  const files = fs.readdirSync(path.join(ROOT, "examples")).filter((f) => f.endsWith(".json")).sort();
  const want: Record<string, any[]> = record ? {} : golden("examples.json");
  const got: Record<string, any[]> = {};
  for (const file of files) {
    const scen: evaluate.Scenario = JSON.parse(fs.readFileSync(path.join(ROOT, "examples", file), "utf-8"));
    const ts = await evaluate.resolve(db, scen);
    got[file] = JSON.parse(JSON.stringify(ts));
    if (!record) {
      const d: string[] = [];
      if (!(file in want)) d.push("no golden result for this example (run with --record after reviewing it)");
      else diff(canon(want[file]), canon(got[file]), file, d);
      report(`${file}: resolve() JSON`, d, ` (${ts.length} results)`);
    }
    const md = path.join(ROOT, "examples", file.replace(/\.json$/, ".out.md"));
    if (fs.existsSync(md)) {
      const a = normStr(fs.readFileSync(md, "utf-8").replace(/\r\n/g, "\n")).split("\n");
      const b = normStr(evaluate.render(scen, ts)).split("\n");
      const lines: string[] = [];
      for (let i = 0; i < Math.max(a.length, b.length); i++) if (a[i] !== b[i]) lines.push(`line ${i + 1}: recorded=${JSON.stringify(a[i])} ts=${JSON.stringify(b[i])}`);
      report(`${file}: report == recorded ${path.basename(md)}`, lines);
    }
  }
  if (record) {
    saveGolden("examples.json", got);
    console.log(`  recorded golden/examples.json (${files.length} examples)`);
  }
}

// ----------------------------------------------------------------------------- 3. engine
function dropTransient(x: any, transient: Set<string>): void {
  const sc = x?.ok?.location?.site_constraints;
  if (Array.isArray(sc)) x.ok.location.site_constraints = sc.filter((r: any) => !transient.has(`${r.layer}|${r.name}`));
}

async function tsEngine(db: Db, c: any): Promise<any> {
  let ts: any;
  try {
    ts = { ok: await engine.run(db, c.structure, c.inputs ?? {}, { address: c.address, lon: c.lon, lat: c.lat, zoneId: c.zone_id,
      precincts: c.precincts, assessmentDate: c.date }) };
  } catch (e) {
    if (e instanceof ServiceUnavailable) return { error: e.message, outage: e.message };   // a required service is down
    if (!(e instanceof LookupError || e instanceof ValueError)) throw e;
    ts = { error: (e as Error).message };
  }
  return JSON.parse(JSON.stringify(ts));
}

/** Which lookup failed because its service did not answer (empty string when none did). */
function outage(ts: any): string {
  if (ts?.outage) return String(ts.outage).slice(0, 120);
  const loc = ts?.ok?.location ?? {};
  return [...Object.keys(loc.lookup_failures ?? {}), ...(loc.overlay_failures ?? []).map((f: any) => f.name)].join(", ");
}

function compare(id: string, want: any, ts: any): { d: string[]; transient: Set<string> } {
  // a map service that failed during one run only (timeout) is not a code difference: drop that layer from both
  const transient = new Set<string>();
  for (const side of [want, ts])
    for (const r of side?.ok?.location?.site_constraints ?? []) if (r.status !== "ok") transient.add(`${r.layer}|${r.name}`);
  want = structuredClone(want);
  dropTransient(want, transient);
  dropTransient(ts, transient);
  const d: string[] = [];
  diff(canon(want), canon(ts), id, d);
  return { d, transient };
}

async function partEngine(db: Db): Promise<void> {
  console.log("3. Engine end to end — parity/cases.json (live map services)");
  const cases: any[] = JSON.parse(fs.readFileSync(path.join(HERE, "cases.json"), "utf-8"));
  const want: Record<string, any> = record ? {} : golden("engine.json");
  const got: Record<string, any> = {};
  for (const c of cases) {
    let ts = await tsEngine(db, c);
    if (record) {
      // never record a result made while a service was down: it would become the expected answer
      for (let attempt = 0; outage(ts) && attempt < 2; attempt++) ts = await tsEngine(db, c);
      if (outage(ts)) {
        console.log(`  NOT recorded ${c.id}: ${outage(ts)} did not answer — run --record again later`);
        got[c.id] = (golden("engine.json") as any)[c.id];
        skipped++;
        continue;
      }
      got[c.id] = ts;
      console.log(`  recorded ${c.id}`);
      continue;
    }
    got[c.id] = ts;
    if (!(c.id in want)) {
      report(c.id, ["no golden result for this case (run with --record after reviewing it)"]);
      continue;
    }
    let { d, transient } = compare(c.id, want[c.id], ts);
    let note = "";
    if (d.length) {
      // a slow layer can answer differently on a second call: run the case again; only a repeated difference counts
      ts = await tsEngine(db, c);
      ({ d, transient } = compare(c.id, want[c.id], ts));
      note = d.length ? ", repeated on re-run" : ", passed on re-run";
    }
    const n = ts.ok ? ` (${ts.ok.rules.length} rules, ${ts.ok.location.site_constraints?.length ?? 0} constraint layers)` : " (error case)";
    if (d.length && outage(ts)) {
      // a required lookup (parcel, zoning, PDA, an overlay) did not answer twice: a service outage, not a code difference
      console.log(`  SKIP  ${c.id}${n}: ${outage(ts)} did not answer (service outage) — run again later`);
      skipped++;
      continue;
    }
    report(c.id, d, n + (transient.size ? `, ${transient.size} transient service error(s) excluded` : "") + note);
  }
  if (record) saveGolden("engine.json", got);
}

// ----------------------------------------------------------------------------- 4. SQL generator
function partGenerator(): void {
  console.log("4. SQL generator — research/councils/*.json → db/030_council_*.sql");
  for (const name of Object.keys(COUNCILS)) {
    const res = build(name);
    if (!res) continue;
    const file = outFile(name);
    const same = fs.existsSync(file) && fs.readFileSync(file, "utf-8") === res[0];
    report(`${path.basename(file)} (${res[1]} draft rules)`, same ? [] :
      ["generated SQL differs from the file on disk: run `npm run import-research`, review the diff and reload the database"]);
  }
}

const db = new Db();
try {
  if (record) console.log("RECORD MODE: golden files are rewritten from the current TypeScript output\n");
  partSelfCheck();
  partPrimitives();
  await partEvaluator(db);
  if (!offline) await partEngine(db);
  else console.log("3. Engine end to end — skipped (--offline)");
  partGenerator();
} finally {
  await db.close();
}
const skipNote = skipped ? ` (${skipped} case(s) skipped: a map service did not answer — run again later)` : "";
console.log(failures ? `\nPARITY FAILED: ${failures} check(s) differ${skipNote}`
  : `\nPARITY OK: the TypeScript code matches the recorded reference results${skipNote}`);
process.exit(failures ? 1 : 0);
