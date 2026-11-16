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
                      [--corner] [--canal] [--battle-axe-lot yes|no] [--carport-unenclosed yes|no] [--attached yes|no] [--roofed yes|no] [--enclosed yes|no] [--street-type access|collector]
                      [--other-building-on-boundary yes|no] [--btb-length M] [--pool-wall-height M] [--pool-wall-above-coping M]
                      [--pre1946-setback M] [--zone ZONE_ID] [--precinct ID ...] [--date YYYY-MM-DD] [--json]

  --slope            lot slope %
  --window-distance  distance to neighbour's habitable window (m)
  --other-building-on-boundary  QDC A2(d): is any other building or part (any class, incl. the existing house)
                      also within the 1.5 m clearance along this same boundary? The 9 m combined-length limit
                      counts all of them together, not just this structure -- answering "no" lets this structure's
                      own footprint stand in for the total; answering "yes" (or leaving it blank) needs the actual
                      combined length via --btb-length, since guessing understates the total and could wrongly
                      pass a boundary that's really over the limit.
  --btb-length       combined length (m) of every building/part within the clearance along this boundary,
                      including the existing house -- only meaningful with --other-building-on-boundary yes.
  --pool-wall-height  height (m) of a solid wall/fence between the pool and this boundary (QDC A2(e)); >= 1.8 m,
                      with --pool-wall-above-coping >= 1.0 m, lets the pool come within the clearance (down to 0 m).
                      Left blank, never guessed: the base clearance still resolves on its own, this relaxation
                      just stays manual review until answered.
  --pool-wall-above-coping  height (m) the solid wall/fence's top sits above the pool coping (QDC A2(e)).
  --subdivision-lot  lot created through a residential subdivision approval (Gold Coast Emerging community zone)
  --corner           lot is on a road corner
  --canal            lot adjoins a canal or lake
  --battle-axe-lot   lot is a battle-axe/rear lot (behind another lot, with a narrow access handle) -- not derivable
                      from parcel geometry in this POC; some councils (e.g. Gold Coast) require a larger setback on
                      a rear lot than the general figure, so left unanswered this stays manual review rather than
                      assuming "no"
  --carport-unenclosed  Logan Table 9.3.2.3.1 AO4(a) only: the carport is open on the front and both sides -- no
                      garage doors or walls there -- though the rear may attach to the house. Not the same as
                      --enclosed (a carport with its rear against the house still counts as unenclosed here);
                      answering "yes" lets a conforming 6m x 6m, <=3.5m carport go to the front boundary instead of
                      the zone's road setback.
  --street-type       access|collector: the frontage street's functional classification (QDC MP 1.1 Table A1).
                      Auto-derived for most councils; set this yourself if it comes back unresolved, or to
                      override a derived guess you know is wrong. A road bigger than a collector (arterial,
                      highway, etc.) is outside Table A1 entirely -- leave this unset for those, it stays manual review.
  --pre1946-setback  average front setback (m) of the nearest pre-1946 houses on the same street -- only used
                      when the lot is in Brisbane's Traditional building character overlay; needs a site/aerial-photo
                      determination of which neighbouring houses are pre-1946, this is never auto-derived.
  --zone             zone id override, e.g. BCC:LOW_DENSITY_RESIDENTIAL
  --precinct         precinct id override (repeatable)
  --date             assessment date (default today)`;

// CLI flag -> engine input name (the same names the web form and /api/rules use)
const INPUTS: Record<string, string> = {
  height: "height_m", length: "length_m", width: "width_m", "mean-height": "mean_height_m", slope: "lot_slope_pct",
  "window-distance": "window_distance_m", "subdivision-lot": "lot_from_residential_subdivision", attached: "is_attached_to_dwelling", roofed: "is_roofed", enclosed: "is_enclosed",
  "street-type": "street_type", "pre1946-setback": "pre1946_setback_m", "battle-axe-lot": "is_battle_axe_lot",
  "carport-unenclosed": "carport_is_unenclosed",
  "other-building-on-boundary": "other_building_on_boundary", "btb-length": "btb_length_m",
  "pool-wall-height": "pool_wall_height_m", "pool-wall-above-coping": "pool_wall_top_above_coping_m",
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
  console.log(`\nApplicable rules:${res.confidence ? `  (${res.confidence.summary})` : ""}`);
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
