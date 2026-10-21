/**
 * Health check for every map service in poc/zoning_layers.json.
 *
 *   npm run check-services              all councils
 *   npm run check-services -- LOGAN     one council
 *
 * For each configured layer: is it reachable without a login, does the configured field still exist, and when was
 * its data last edited. Run it monthly or when a lookup starts failing. To update a source, edit the URL / field in
 * poc/zoning_layers.json and run this again (see docs/13-map-services.md).
 */
import { getJson } from "../core/geo.js";
import * as zoning from "../core/zoning.js";
import { exit, left } from "./fmt.js";

/** [purpose, url, field] for every layer a council config uses. */
function* layers(cfg: any): Generator<[string, string, string | null]> {
  if (cfg.zone_layer) {
    yield ["zone", cfg.zone_layer, cfg.zone_field ?? null];
    if (cfg.precinct_field) yield ["zone precinct (same layer)", cfg.zone_layer, cfg.precinct_field];
    if (cfg.local_plan_field) yield ["local plan (same layer)", cfg.zone_layer, cfg.local_plan_field];
  }
  for (const u of cfg.precinct_layers ?? []) yield ["zone precinct", u, cfg.precinct_layer_field ?? null];
  if (cfg.local_plan_layer) yield ["local plan", cfg.local_plan_layer, cfg.local_plan_layer_field ?? null];
  if (cfg.local_plan_precinct_layer)
    yield ["local plan precinct", cfg.local_plan_precinct_layer, cfg.local_plan_precinct_name_field || cfg.local_plan_precinct_code_field || null];
  for (const ov of cfg.overlay_layers ?? []) yield ["overlay: " + ov.name, ov.layer, ov.field];
}

async function check(url: string, field: string | null): Promise<[string, string, string | null]> {
  let j: any;
  try {
    j = await getJson(url, { f: "json" }, 30);
  } catch (e) {   // report every failure, keep going
    return ["FAIL", String((e as Error).message ?? e).slice(0, 90), null];
  }
  const fields = new Set<string>((j.fields ?? []).map((f: any) => f.name));
  if (field && fields.size && !fields.has(field))
    return ["FIELD?", `'${field}' missing; fields: ${[...fields].sort().join(", ").slice(0, 80)}`, j.name ?? null];
  const ts = j.editingInfo?.dataLastEditDate || j.editingInfo?.lastEditDate;
  const edited = ts ? new Date(ts).toISOString().slice(0, 10) : "n/a (MapServer)";
  return ["OK", `data last edited ${edited}`, j.name ?? null];
}

async function main(): Promise<number> {
  const cfg = zoning.loadConfig();
  const args = process.argv.slice(2).map((a) => a.toUpperCase());
  const want = args.length ? args : Object.keys(cfg).filter((k) => !k.startsWith("_"));
  let bad = 0;
  for (const lg of want) {
    const c = cfg[lg];
    if (!c) {
      console.log(`\n${lg}: not in poc/zoning_layers.json`);
      bad++;
      continue;
    }
    console.log(`\n${lg}  [${c.status}]  scheme: ${c.scheme_viewer || "-"}`);
    if (c.status !== "WORKING") {
      console.log(`  skipped: ${c.notes}`);
      continue;
    }
    for (const [purpose, url, field] of layers(c)) {
      const [status, msg, name] = await check(url, field);
      bad += status === "OK" ? 0 : 1;
      console.log(`  ${left(status, 6)} ${left(purpose, 55)} ${left(name || "", 38)} ${msg}\n         ${url}`);
    }
  }
  console.log(`\n${bad ? `${bad} layer(s) need attention` : "All layers OK"}`);
  return bad ? 1 : 0;
}

main().then(exit, (e) => { console.error(e); exit(1); });
