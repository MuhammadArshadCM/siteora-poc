/**
 * Command line: npm run cli -- "15 Jubilee Terrace, Bardon QLD 4065" --structure SHED --height 3 --length 6 --width 4
 *
 * Prints the applicable rules per boundary with their source clause. --json prints the full response.
 * Database connection: poc/.env (PG_PASSWORD = ...; see .env.example) or PGHOST / PGPORT / PGDATABASE / PGUSER / PGPASSWORD
 * (defaults localhost:5432/siteora/postgres; environment variables win over .env).
 */
import { Db } from "../core/db.js";
import { loadEnv } from "../core/env.js";
import * as engine from "../core/engine.js";
import { LookupError, pyStr, ValueError } from "../core/py.js";
import { parseArgs, usage } from "./args.js";
import { exit, left } from "./fmt.js";

const USAGE = `
usage: npm run cli -- [address] [--lon LON --lat LAT] [--structure ${Object.keys(engine.STRUCTURES).sort().join("|")}]
                      [--height M] [--length M] [--width M] [--mean-height M] [--slope PCT] [--window-distance M] [--subdivision-lot yes|no]
                      [--corner] [--canal] [--attached yes|no] [--roofed yes|no] [--enclosed yes|no]
                      [--zone ZONE_ID] [--precinct ID ...] [--date YYYY-MM-DD] [--json]

  --slope            lot slope %
  --window-distance  distance to neighbour's habitable window (m)
  --subdivision-lot  lot created through a residential subdivision approval (Gold Coast Emerging community zone)
  --corner           lot is on a road corner
  --canal            lot adjoins a canal or lake
  --zone             zone id override, e.g. BCC:LOW_DENSITY_RESIDENTIAL
  --precinct         precinct id override (repeatable)
  --date             assessment date (default today)`;

// CLI flag -> engine input name (the same names the web form and /api/rules use)
const INPUTS: Record<string, string> = {
  height: "height_m", length: "length_m", width: "width_m", "mean-height": "mean_height_m", slope: "lot_slope_pct",
  "window-distance": "window_distance_m", "subdivision-lot": "lot_from_residential_subdivision", attached: "is_attached_to_dwelling", roofed: "is_roofed", enclosed: "is_enclosed",
};

async function main(): Promise<number> {
  let a;
  try {
    a = parseArgs(process.argv.slice(2), {
      booleans: ["corner", "canal", "json", "help"], repeatable: ["precinct"],
      defaults: { structure: "SHED", attached: "no", roofed: "yes", enclosed: "yes" },
    });
  } catch (e) {
    usage(USAGE, (e as Error).message);
  }
  if (a.help) usage(USAGE);
  const address = a._[0];
  const lon = a.lon !== undefined ? Number(a.lon) : undefined, lat = a.lat !== undefined ? Number(a.lat) : undefined;
  if (!address && (lon === undefined || lat === undefined)) usage(USAGE, "give an address or --lon/--lat");
  if (!(a.structure in engine.STRUCTURES)) usage(USAGE, `--structure must be one of ${Object.keys(engine.STRUCTURES).sort().join(", ")}`);
  const inputs: Record<string, string> = {};
  for (const [flag, name] of Object.entries(INPUTS)) if (a[flag] !== undefined) inputs[name] = a[flag];
  if (a.corner) inputs.is_corner_lot = "yes";
  if (a.canal) inputs.adjoins_canal_or_lake = "yes";

  loadEnv();
  const db = new Db();
  let res: any;
  try {
    res = await engine.run(db, a.structure, inputs, { address, lon, lat, zoneId: a.zone, precincts: a.precinct.length ? a.precinct : undefined,
      assessmentDate: a.date });
  } catch (e) {
    if (e instanceof LookupError || e instanceof ValueError) {
      console.log(`Error: ${e.message}`);
      return 2;
    }
    throw e;
  } finally {
    await db.close();
  }
  if (a.json) {
    console.log(JSON.stringify(res, null, 1));
    return 0;
  }
  const loc = res.location;
  console.log(`Address : ${loc.geocode?.address ?? "(coordinates)"}  [${loc.lat.toFixed(6)}, ${loc.lon.toFixed(6)}]`);
  console.log(`Council : ${loc.council.lga_name}`);
  const p = loc.parcel ?? {};
  console.log(`Lot     : ${pyStr(p.lotplan)}  area ${pyStr(p.lot_area)} m2  est. width ${pyStr(p.est_width_m)} m  depth ${pyStr(p.est_depth_m)} m`);
  const z = loc.zoning;
  console.log(`Zone    : ${z.zone_id || "UNKNOWN"}  precincts ${z.precincts?.length ? pyStr(z.precincts) : "-"}`
    + (z.from_map ? `  (map: ${z.from_map.zone_text})` : ""));
  console.log(`Overlays: ${(loc.overlays ?? []).map((o: any) => `${o.name} (${o.text})`).join("; ") || "-"}`);
  console.log(`NP/LP   : ${[...z.local_plans, ...z.local_plan_precincts].join(", ") || (z.from_map?.local_plan_text || "-")}`);
  console.log(`Date    : ${res.assessment_date}   Structure: ${res.structure.label}`);
  console.log("\nInstruments in force:");
  for (const i of res.applicable_instruments) console.log(`  [${i.regime}] ${i.instrument} — ${i.version}`);
  console.log("\nApplicable rules:");
  for (const r of res.rules) {
    let req: string;
    if (r.operator === "IS_TRUE" || r.operator === "IS_FALSE") req = r.operator === "IS_TRUE" ? "must hold" : "must not occur";
    else if (r.required === 0 && r.operator === ">=") req = "built to boundary permitted";
    else req = `${r.operator} ${pyStr(r.required)} ${r.unit || ""}`;
    const where = r.boundary || (r.topic === "SETBACK.WATERWAY" ? "canal/lake boundary" : "whole lot");
    console.log(`  ${left(where, 24)} ${left(r.topic, 28)} ${left(req, 28)} [${r.state}]`);
    console.log(`  ${left("", 24)} ${r.title}`);
    console.log(`  ${left("", 24)} ${r.instrument} — ${r.sources.join("; ")}`);
  }
  const c = res.council_rules;
  console.log(`\nCouncil rules in scope here that did not apply (${c.other_places_count} more apply only to other zones/overlays/plans):`);
  for (const x of c.in_scope_not_applicable) console.log(`  - ${x.title}\n      why not: ${x.why}`);
  if (c.not_yet_encoded.length) {
    console.log("Council clauses for this place not yet encoded as rules (read them yourself):");
    for (const g of c.not_yet_encoded) console.log(`  - ${g.code}: ${g.count} clause(s)`);
  }
  if (res.missing_inputs.length) {
    console.log("\nInputs that would resolve MANUAL_REVIEW items:");
    for (const m of res.missing_inputs) console.log(`  - ${m.fact}: ${m.description}`);
  }
  if (res.warnings.length) {
    console.log("\nWarnings:");
    for (const w of res.warnings) console.log(`  - ${w}`);
  }
  return 0;
}

main().then(exit, (e) => { console.error(e); exit(1); });
