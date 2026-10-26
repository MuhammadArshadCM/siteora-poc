/**
 * Address (or zone) + proposed structure -> applicable rules, values and sources. Port of poc/siteora_poc/engine.py.
 *   1. locate   address -> point -> council, parcel, PDA, zone/precincts, overlays, site constraints
 *   2. facts    property facts + structure inputs, each with its provenance
 *   3. resolve  evaluate.ts (scope, conditions, precedence, versions)
 *   4. explain  missing inputs, council rules not applicable, clauses not yet encoded
 */
import { Db, lit } from "./db.js";
import { today } from "./env.js";
import * as evaluate from "./evaluate.js";
import * as geo from "./geo.js";
import { cmpTuple, LookupError, pyRound, pyStr, unique, urlencode, ValueError } from "./py.js";
import * as site from "./site.js";
import * as zoning from "./zoning.js";

export const STRUCTURES: Record<string, string> = {
  SHED: "Shed", GARAGE: "Garage (enclosed)", CARPORT: "Carport", PATIO: "Patio (roofed)",
  PERGOLA: "Pergola", DECK: "Deck", DETACHED_LAUNDRY: "Detached laundry", GATEHOUSE: "Gatehouse",
  POOL_INGROUND: "In-ground swimming pool", POOL_ABOVEGROUND: "Above-ground swimming pool",
  POOL_FENCE: "Pool fence / barrier",
};

export async function councilPlaces(db: Db, lgId: string): Promise<[any[], any[]]> {
  const zones = await db.q(`SELECT coalesce(json_agg(json_build_object('zone_id', z.zone_id, 'name', z.name,
                        'dwelling_house_permitted', z.dwelling_house_permitted) ORDER BY z.name), '[]')
                     FROM regs.zones z JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = ${lit(lgId)}`);
  const precincts = await db.q(`SELECT coalesce(json_agg(json_build_object('precinct_id', p.precinct_id, 'zone_id', p.zone_id, 'name', p.name)
                        ORDER BY p.name), '[]') FROM regs.precincts p JOIN regs.zones z USING (zone_id)
                        JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = ${lit(lgId)}`);
  return [zones, precincts];
}

export async function councilLocalPlans(db: Db, lgId: string): Promise<[any[], any[]]> {
  const lps = await db.q(`SELECT coalesce(json_agg(json_build_object('local_plan_id', l.local_plan_id, 'name', l.name)), '[]')
                   FROM regs.local_plans l JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = ${lit(lgId)}`);
  const lpps = await db.q(`SELECT coalesce(json_agg(json_build_object('local_plan_precinct_id', x.local_plan_precinct_id,
                        'local_plan_id', x.local_plan_id, 'name', x.name)), '[]')
                    FROM regs.local_plan_precincts x JOIN regs.local_plans l USING (local_plan_id)
                    JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = ${lit(lgId)}`);
  return [lps, lpps];
}

/** Step 1: everything we can learn about the property from public data. */
const NOT_CHECKED: Record<string, (council: string) => string> = {
  Bushfire: (council) => `Bushfire hazard is NOT checked automatically for ${council}: no queryable public data. The Queensland Fire `
    + "Department's Bushfire Prone Area is published only as a picture map (shown on the map as 'Bushfire prone area (QFD)'), and the "
    + "council's own bushfire overlay is not public. Check the property on that map or in the council's planning scheme before siting.",
  Flood: (council) => `Flood is NOT checked automatically for ${council}: no public flood mapping is configured. Check the council's flood maps.`,
};

/** DCDB accuracy code ("STANDARD 1:2500 CADASTRAL MAP - 1.5M", "B&D ENTRY CONTROLLED - 0.1M" …) → metres. */
export function boundaryAccuracy(code: unknown, surveyed: unknown) {
  const m = /-\s*(\d+(?:\.\d+)?)\s*M\b/i.exec(String(code ?? ""));
  return { boundary_accuracy_m: m ? Number(m[1]) : null, boundary_accuracy_code: code ? String(code) : null,
    boundary_surveyed: surveyed === "Y" ? true : surveyed === "N" ? false : null };
}

/** A warning for a lookup whose service failed: what failed, why, and what it means for the result. Programming errors
 *  (TypeError / ReferenceError without a network cause) are not hidden: they are re-thrown. */
function unavailable(what: string, e: any, consequence: string): string {
  if ((e instanceof TypeError && !e.cause) || e instanceof ReferenceError) throw e;
  const why = String(e?.message ?? e).replace(/\s+/g, " ").slice(0, 160);
  return `${what} did not answer (${why}) — ${consequence}. Try again later.`;
}

export async function locate(db: Db, address?: string | null, lon?: number | null, lat?: number | null): Promise<any> {
  const loc: any = { warnings: [] as string[] };
  if (address) {
    const g = await geo.geocode(address);
    loc.geocode = g;
    lon = g.lon;
    lat = g.lat;
    if (g.unmatched_input) loc.warnings.push(`Matched '${g.address}' but these parts of the input did not match: ${g.unmatched_input}. Check it is the right property.`);
  }
  loc.lon = lon;
  loc.lat = lat;
  loc.council = await geo.councilAt(lon!, lat!);
  if (!loc.council.lg_id) throw new LookupError(`${loc.council.lga_name} is not one of the councils in the dataset`);
  const points: [number, number][] = [[lon!, lat!]];
  try {
    const p = await geo.parcelAt(lon!, lat!);
    loc.parcel = Object.fromEntries(["lot", "plan", "lotplan", "lot_area", "parcel_typ", "tenure"].map((k) => [k, p[k] ?? null]));
    // how far the mapped boundary can be from the true one (State DCDB accuracy code, e.g. "UPGRADE ADJUSTMENT - 1M"):
    // a site plan's setbacks measured from this outline carry the same uncertainty
    const acc = boundaryAccuracy(p.acc_code, p.surv_ind);
    Object.assign(loc.parcel, acc);
    if (acc.boundary_accuracy_m === null || acc.boundary_accuracy_m > 0.5)
      loc.warnings.push(acc.boundary_accuracy_m === null
        ? `The State cadastre gives no accuracy for this lot's boundary (${p.acc_code ?? "no code"}): confirm boundaries from the survey plan before measuring setbacks.`
        : `The mapped lot boundary is accurate only to ±${acc.boundary_accuracy_m} m (State cadastre: ${p.acc_code}). Setbacks measured from it can be out by that much: `
          + "for a site plan, take boundaries from the registered survey plan or an identification survey, especially where the setback is small.");
    Object.assign(loc.parcel, geo.parcelMetrics(p.rings));
    loc.parcel_geometry = p.rings;   // lon/lat rings, for the map
    // Brisbane: draw Council's own outline, as the City Plan map does (the checks above and below still use the State DCDB)
    if (loc.council.lg_id === "BRISBANE" && p.lotplan) {
      try {
        const bcc = await geo.bccParcelRings(String(p.lotplan));
        if (bcc) loc.parcel_map_geometry = bcc;
      } catch { /* the State outline is drawn instead */ }
    }
    const ring = p.rings.reduce((best, r) => (r.length > best.length ? r : best), p.rings[0]);
    const inner = ring.slice(0, -1);
    points.push([inner.reduce((s, [x]) => s + x, 0) / (ring.length - 1), inner.reduce((s, [, y]) => s + y, 0) / (ring.length - 1)]);
    if (["SP", "BUP", "GTP"].some((pre) => String(p.plan ?? "").startsWith(pre)) && p.parcel_typ !== "Lot Type Parcel")
      loc.warnings.push("Parcel may be part of a community titles / strata scheme — check which lot the work is on.");
  } catch (e) {
    if (e instanceof LookupError) {
      loc.parcel = null;
      loc.warnings.push(e.message);
    } else {
      loc.parcel = null;
      (loc.lookup_failures ??= {}).parcel = true;
      loc.warnings.push(unavailable("The State land parcel (cadastre) service", e,
        "lot area, width and depth are unknown, and site constraints were not checked"));
    }
  }
  // the address search and council lookup above are essential; the lookups below are not, so a service that fails
  // becomes a warning (and unknown facts → manual review) instead of failing the whole result
  try {
    loc.pda = await geo.pdaAt(lon!, lat!);
  } catch (e) {
    loc.pda = null;
    (loc.lookup_failures ??= {}).pda = true;
    loc.warnings.push(unavailable("The State Priority Development Area service", e, "check the property is not in a PDA"));
  }
  const lg: string = loc.council.lg_id;
  const [zones, precincts] = await councilPlaces(db, lg);
  const [lps, lpps] = await councilLocalPlans(db, lg);
  loc.zoning = { from_map: null, zone_id: null, precincts: [], local_plans: [], local_plan_precincts: [] };
  const cfg = zoning.loadConfig()[lg] ?? {};
  if (cfg.status !== "WORKING") {
    loc.warnings.push(`No public zoning map service for this council (${cfg.notes || "not configured"}) — choose the zone manually.`);
  } else {
    let z: zoning.Found | null = null;
    try {
      z = await zoning.lookup(lg, points);
    } catch (e) {
      (loc.lookup_failures ??= {}).zoning = true;
      loc.warnings.push(unavailable("The council zoning map service", e, "choose the zone manually"));
    }
    loc.zoning.from_map = z;
    if (z) {
      const [zid, pids, lpids, lppids, notes] = zoning.match(z, zones, precincts, lps, lpps);
      Object.assign(loc.zoning, { zone_id: zid, precincts: pids, local_plans: lpids, local_plan_precincts: lppids });
      loc.warnings.push(...notes);
    } else if (!loc.warnings.some((w: string) => w.startsWith("The council zoning map service"))) {
      loc.warnings.push("The council zoning map returned no zone at this property (e.g. road reserve) — choose the zone manually.");
    }
  }
  loc.overlays = [];
  if (cfg.overlay_layers) {
    loc.overlay_failures = [];
    loc.overlays = await zoning.overlays(lg, points, loc.overlay_failures);
    for (const f of loc.overlay_failures)
      loc.warnings.push(unavailable(`The ${f.name} map`, { message: f.error }, "rules that depend on this overlay are not resolved; check the council map"));
    if (!loc.overlay_failures.length) delete loc.overlay_failures;   // only reported when something failed
    for (const o of loc.overlays)
      if (!o.overlay_ids.length && !o.value_fact && !o.flag_fact) loc.warnings.push(`${o.name} '${o.text}' is not mapped to an overlay in the rules dataset.`);
  } else {
    loc.warnings.push("Overlays (character, flood, heritage, bushfire…) are not looked up for this council — overlay rules are not shown.");
  }
  loc.available_zones = zones;
  loc.available_precincts = precincts;
  loc.site_constraints = await site.constraints(lg, loc.parcel_geometry);
  // hazards that matter for siting but have no queryable public data for this council: say so, never skip silently
  const covered = new Set(site.layersFor(lg).map((l: any) => l.category));
  const notChecked = ["Bushfire", "Flood"].filter((c) => !covered.has(c));
  if (notChecked.length) {
    loc.not_checked = notChecked;
    for (const c of notChecked) loc.warnings.push(NOT_CHECKED[c](loc.council.lga_name));
  }
  loc.sources = sources(loc, cfg);
  return loc;
}

/** Links a person can open: the exact point query, the layer description, the layer on the ArcGIS Map Viewer. */
function links(layer: string, lon: number, lat: number) {
  const q = urlencode({ geometry: `${lon},${lat}`, geometryType: "esriGeometryPoint", inSR: geo.SR,
    spatialRel: "esriSpatialRelIntersects", outFields: "*", returnGeometry: "false", f: "html" });
  const service = layer.slice(0, layer.lastIndexOf("/"));
  return { layer, query_url: `${layer}/query?${q}`, layer_url: `${layer}?f=html`,
    viewer_url: "https://www.arcgis.com/apps/mapviewer/index.html?" + urlencode({ url: service, center: `${lon},${lat}`, level: 18 }) };
}

/** Every map service consulted for this property, with what it returned. */
export function sources(loc: any, cfg: any): any[] {
  const { lon, lat } = loc;
  const z = loc.zoning?.from_map ?? {};
  const p = loc.parcel ?? {};
  const failed = loc.lookup_failures ?? {};
  const out: any[] = [
    { what: "Address → point", source: "QldLocator geocoder (Queensland Government)",
      result: loc.geocode?.address || "coordinates entered", ...links(geo.GEOCODER.slice(0, geo.GEOCODER.lastIndexOf("/")), lon, lat),
      query_url: geo.GEOCODER + "?" + urlencode({ SingleLine: loc.geocode?.address ?? "", f: "html" }) },
    { what: "Council", source: "State LGA boundaries", result: loc.council.lga_name, ...links(geo.LGA_LAYER, lon, lat) },
    { what: "Land parcel", source: "State cadastre (DCDB)", result: p.lotplan || (failed.parcel ? "lookup failed (service did not answer)" : "not found"), ...links(geo.PARCEL_LAYER, lon, lat) },
    { what: "Priority Development Area", source: "State PDA boundaries", result: loc.pda?.pda_name || (failed.pda ? "lookup failed (service did not answer)" : "not in a PDA"), ...links(geo.PDA_LAYER, lon, lat) },
  ];
  if (cfg.zone_layer)
    out.push({ what: "Zone", source: "Council zoning map",
      result: z.zone_text || (cfg.status !== "WORKING" ? "blocked" : failed.zoning ? "lookup failed (service did not answer)" : "no zone at this point"), ...links(cfg.zone_layer, lon, lat) });
  for (const layer of cfg.precinct_layers ?? [])
    out.push({ what: "Zone precinct", source: "Council zoning map", result: z.precinct_text || "none", ...links(layer, lon, lat) });
  if (cfg.local_plan_layer)
    out.push({ what: "Local / neighbourhood plan", source: "Council map", result: z.local_plan_text || "none", ...links(cfg.local_plan_layer, lon, lat) });
  if (cfg.local_plan_precinct_layer)
    out.push({ what: "Local plan precinct", source: "Council map", result: z.local_plan_precinct_text || z.local_plan_precinct_code || "none",
      ...links(cfg.local_plan_precinct_layer, lon, lat) });
  if (loc.parcel_map_geometry)
    out.push({ what: "Lot outline drawn on the map", source: "Brisbane City Council property parcels",
      result: p.lotplan, ...links(geo.BCC_PARCEL_LAYER, lon, lat) });
  const hits = new Map<string, string[]>();
  for (const o of loc.overlays ?? []) {
    if (!hits.has(o.source)) hits.set(o.source, []);
    hits.get(o.source)!.push(o.text);
  }
  for (const ov of cfg.overlay_layers ?? [])
    out.push({ what: "Overlay", source: ov.name,
      result: (hits.get(ov.layer) ?? []).join("; ") || ((loc.overlay_failures ?? []).some((x: any) => x.layer === ov.layer) ? "lookup failed (service did not answer)" : "not on this property"),
      hit: hits.has(ov.layer), ...links(ov.layer, lon, lat) });
  return out;
}

type FactMap = Record<string, { value: any; source: string }>;

/** Step 2: facts with provenance. inputs = user-supplied values (strings/numbers/bools). */
export function buildFacts(loc: any, structure: string, inputs: Record<string, any>): FactMap {
  const facts: FactMap = {};
  const put = (name: string, value: any, source: string) => {
    if (value !== null && value !== undefined && value !== "") facts[name] = { value, source };
  };
  const parcel = loc.parcel ?? {};
  const area = parcel.lot_area || null;
  put("lot_area_m2", area ? area : parcel.computed_area_m2, area ? "Registered lot area (DCDB)" : "Computed from parcel outline");
  put("lot_width_m", parcel.est_width_m, "ESTIMATED from parcel outline (minimum bounding rectangle)");
  put("road_frontage_m", parcel.est_width_m, "ESTIMATED: assumed equal to lot width");
  put("average_lot_depth_m", parcel.est_depth_m, "ESTIMATED from parcel outline");
  if (parcel.rectangularity !== null && parcel.rectangularity !== undefined)
    put("lot_is_rectangular_or_near", parcel.rectangularity >= 0.9, `ESTIMATED: rectangularity ${pyStr(parcel.rectangularity)} (>= 0.9)`);
  put("in_priority_development_area", Boolean(loc.pda), "Priority Development Areas layer (Queensland Government)");
  for (const [fact, v] of Object.entries(site.factsFrom(loc.site_constraints ?? [])))
    put(fact, v, "Network / constraint map: " + (v ? "mapped on or near the lot" : "nothing mapped on the lot (maps can be incomplete)"));
  // value overlays (e.g. a mapped maximum height); the lowest value governs if polygons overlap
  for (const o of (loc.overlays ?? []).filter((o: any) => o.value_fact && o.value !== null && o.value !== undefined)
    .slice().sort((a: any, b: any) => b.value - a.value))
    put(o.value_fact, o.value, `${o.name} map: '${o.text}'`);
  const zoneId = loc.zoning.zone_id;
  const zone = loc.available_zones.find((z: any) => z.zone_id === zoneId) ?? null;
  if (zone && zone.dwelling_house_permitted !== null) put("zone_permits_dwelling_house", zone.dwelling_house_permitted, "regs.zones (scheme table of assessment)");
  for (const [fact, hit] of Object.entries(zoning.overlayFlags(loc.council.lg_id, loc.overlays ?? [],
    (loc.overlay_failures ?? []).map((f: any) => f.layer))))
    put(fact, hit, "Council overlay map (" + (hit ? "inside" : "outside") + " the mapped area)");
  if (loc.council.lg_id === "LOGAN" && zone && zone.dwelling_house_permitted && !("dwelling_house_code_applies" in facts))
    put("dwelling_house_code_applies", true, "ASSUMED: lot is in a 'residential area' on Logan's Residential overlay (not checked)");
  // Assumptions a POC has to make; all are listed in the output
  put("land_is_regulated_land", true, "ASSUMED: lot has (or will have) a dwelling");
  put("in_wind_region_c", false, "ASSUMED: SEQ councils are not in Wind Region C");
  put("planning_assessment_required", false, "ASSUMED: house is accepted development (no planning application)");
  put("development_footprint_exists", false, "ASSUMED: no approved plan of development / footprint");
  // User inputs (structure + things public data cannot tell us)
  const blank = (k: string) => inputs[k] === null || inputs[k] === undefined || inputs[k] === "";
  const num = (k: string): number | null => {
    if (blank(k)) return null;
    const n = Number(String(inputs[k]).trim());
    if (!Number.isFinite(n)) throw new ValueError(`could not convert string to float: ${JSON.stringify(String(inputs[k]))}`);
    return n;
  };
  const yes = (k: string): boolean | null => (blank(k) ? null : ["1", "true", "yes", "on"].includes(String(inputs[k]).toLowerCase()));
  const h = num("height_m"), length = num("length_m"), width = num("width_m");
  put("structure_height_m", h, "User input");
  put("building_height_m", h, "User input (height)");
  put("part_height_m", h, "User input (height; tallest part)");
  put("structure_height_above_ground_m", h, "User input (height)");
  put("wall_height_m", num("wall_height_m") || h, num("wall_height_m") ? "User input" : "User input (height, used as wall height)");
  put("mean_height_m", num("mean_height_m") || h, num("mean_height_m") ? "User input" : "ASSUMED: mean height = height (conservative)");
  put("width_m", width, "User input (width)");
  if (length && width) {
    put("plan_area_m2", pyRound(length * width, 2), "User input (length x width)");
    put("longest_side_m", Math.max(length, width), "User input");
    put("btb_length_on_boundary_m", num("btb_length_m") || Math.max(length, width),
      num("btb_length_m") ? "User input" : "ASSUMED: longest side runs along the boundary");
    put("btb_max_single_part_length_m", Math.max(length, width), "User input");
    put("total_outbuilding_floor_area_m2", pyRound((num("existing_outbuildings_m2") || 0) + length * width, 2),
      "User input (this structure + existing outbuildings)");
    put("total_outbuilding_roofed_area_m2", facts.total_outbuilding_floor_area_m2.value, "As floor area");
  }
  for (const k of ["is_roofed", "is_enclosed", "is_attached_to_dwelling"]) put(k, yes(k), "User input");
  let v = yes("in_front_of_main_building_line");
  put("in_front_of_main_building_line", Boolean(v), v !== null ? "User input" : "ASSUMED: behind the main building line of the house");
  // Not available from public data in this POC: default to "no" and say so
  for (const [k, what] of [["is_corner_lot", "a corner lot"], ["adjoins_canal_or_lake", "next to a canal or lake"]]) {
    v = yes(k);
    put(k, Boolean(v), v !== null ? "User input" : `ASSUMED: not ${what} (not checked)`);
  }
  // Gold Coast Emerging community zone: setbacks and site cover differ for a lot created through a residential
  // subdivision approval. Not in public data, so no default: unanswered, those rules go to manual review.
  v = yes("lot_from_residential_subdivision");
  if (v !== null) put("lot_from_residential_subdivision", v, "User input");
  if (num("lot_slope_pct") !== null) put("lot_slope_pct", num("lot_slope_pct"), "User input");
  else put("lot_slope_pct", 0, "ASSUMED: flat lot (height limits rise on slopes over 15 %; enter the slope if steep)");
  put("distance_to_adjoining_habitable_window_m", num("window_distance_m"), "User input");
  // Not available from public data in this POC (which lot has an existing detached dwelling, and its road setback):
  // optional "neighbour road setback" inputs. Not in public data, so no default when left blank (as for
  // lot_from_residential_subdivision above) — unanswered, the rules that need it stay manual review, same as today.
  // Entered, they resolve QDC MP 1.1/1.2 A1(a)(ii)/(iii) (road setback aligned with an adjoining dwelling) and every
  // council rule keyed on has_adjoining_dwelling / adjoining_road_setbacks_m. "False" is never assumed here: a smaller
  // neighbour-aligned setback must never be shown as DETERMINED just because the field was left blank.
  {
    const adj = [num("adjoining_setback_1_m"), num("adjoining_setback_2_m")].filter((n): n is number => n !== null);
    if (adj.length) {
      put("has_adjoining_dwelling", true, "User input (adjoining road setback entered)");
      put("adjoining_road_setbacks_m", adj, "User input (adjoining road setback(s))");
      put("adjoining_dwellings_both_sides", adj.length === 2,
        adj.length === 2 ? "User input (both adjoining setbacks entered)"
          : "ASSUMED: only one adjoining setback entered — not treated as an existing detached dwelling on both adjoining lots");
      put("any_adjoining_setback_3_to_6m", adj.some((n) => n >= 3 && n <= 6), "DERIVED: from the adjoining road setback(s) entered");
      put("both_adjoining_setbacks_le_3m", adj.length === 2 && adj.every((n) => n <= 3), "DERIVED: from the adjoining road setbacks entered");
    }
  }
  put("pool_coping_height_m", structure.startsWith("POOL_") && structure !== "POOL_FENCE" ? h : null, "User input (height)");
  if (structure.startsWith("POOL")) {
    put("pool_capable_depth_m", 1.5, "ASSUMED: pool holds 300 mm or more");
    put("pool_is_indoor", false, "ASSUMED: outdoor pool");
    put("solid_wall_between_pool_and_boundary_height_m", 0, "ASSUMED: no solid wall between pool and boundary");
    put("solid_wall_top_above_coping_m", 0, "ASSUMED");
    put("solid_fence_above_pool_deck_m", 0, "ASSUMED");
  }
  if (structure === "POOL_FENCE") {
    put("barrier_height_mm", h ? h * 1000 : null, "User input (height)");
    put("ncz_side", "OUTSIDE", "ASSUMED: non-climbable zone on the outside");
    put("ncz_required", true, "ASSUMED");
    put("barrier_has_cranked_top", false, "ASSUMED");
  }
  put("wall_is_maintenance_free", true, "ASSUMED: prefinished steel / masonry");
  put("is_garage_under_main_roof", ["GARAGE", "CARPORT", "SHED"].includes(structure) ? false : null, "ASSUMED: detached");
  put("weather_control_attached_to_btb_part", true, "ASSUMED: eaves belong to the same building");
  return facts;
}

export function boundaries(facts: FactMap) {
  const b = [{ boundary_type: "PRIMARY_FRONTAGE" }, { boundary_type: "SIDE" }, { boundary_type: "REAR" }];
  if (facts.is_corner_lot?.value) b.splice(1, 0, { boundary_type: "SECONDARY_FRONTAGE_ROAD" });
  return b;
}

export async function applicableInstruments(db: Db, lgId: string, date: string): Promise<any[]> {
  return db.q(`SELECT coalesce(json_agg(json_build_object('instrument', i.title, 'version', iv.version_label,
                        'regime', a.regime, 'from', a.effective_from, 'to', a.effective_to, 'end_condition', a.end_condition,
                        'basis', p.ref_label) ORDER BY a.regime, i.title), '[]')
                    FROM regs.instrument_applicability a JOIN regs.instrument_versions iv USING (instrument_version_id)
                    JOIN regs.instruments i ON i.instrument_id = iv.instrument_id
                    LEFT JOIN regs.provisions p ON p.provision_id = a.basis_provision_id
                    WHERE (a.lg_id = ${lit(lgId)} OR a.lg_id IS NULL) AND a.effective_from <= ${lit(date)}
                      AND (a.effective_to IS NULL OR a.effective_to >= ${lit(date)})`);
}

/** Facts referenced by MANUAL_REVIEW rules that we do not have. */
export async function missingInputs(db: Db, results: evaluate.Result[], facts: Record<string, any>) {
  const ids = unique(results.filter((r) => r.state === "MANUAL_REVIEW").map((r) => r.rule)).sort();
  if (!ids.length) return [];
  const inlist = ids.map(lit).join(",");
  const used: string[] = await db.q(`SELECT coalesce(json_agg(DISTINCT f), '[]') FROM (
                      SELECT fact_id AS f FROM regs.rule_conditions WHERE rule_version_id IN (${inlist})
                      UNION SELECT v #>> '{}' FROM regs.rule_versions rv, jsonb_path_query(rv.value_expr, 'lax $.**.var') v
                      WHERE rv.rule_version_id IN (${inlist})) x`);
  const desc = Object.fromEntries(await db.q<[string, string][]>(`SELECT coalesce(json_agg(json_build_array(fact_id, description)), '[]') FROM regs.facts
                        WHERE fact_id IN (${used.map(lit).join(",") || "''"})`));
  return used.filter((u) => !(u in facts) && u !== "boundary_type").map((u) => ({ fact: u, description: desc[u] ?? null }));
}

/** Plain-language reason a rule in scope did not apply: the conditions that failed. */
function whyNot(rule: evaluate.Rule, facts: Record<string, any>): string {
  const show = (v: any) => (Array.isArray(v) ? v.map(pyStr).join(", ") : v);
  const reasons: string[] = [];
  const groups = new Map<number, evaluate.Condition[]>();
  for (const c of rule.conditions ?? []) {
    if (!groups.has(c.group)) groups.set(c.group, []);
    groups.get(c.group)!.push(c);
  }
  for (const cs of groups.values()) {
    const failed = cs.filter((c) => c.fact !== "boundary_type" && evaluate.cond(c, facts) === false);
    reasons.push(failed.map((c) => `needs ${c.fact} ${c.value !== null ? c.op : c.op.toLowerCase().replace(/_/g, " ")}`
      + `${c.value === null ? "" : " " + pyStr(show(c.value))} (here: ${pyStr(facts[c.fact] ?? null)})`).join(" and ")
      || "applies only to a boundary type this lot does not have");
  }
  return unique(reasons).join(" — or — ") || "conditions not met";
}

/** Setback-category topics, matching the project's own `regs.v_setback_rules` view (docs/03-schema.md):
 *  everything under SETBACK.* (front/side/rear/secondary/waterway/BTB/…) or SEPARATION.*. Used to filter the response
 *  to "setbacks only" — garage/pool/height/site-cover rules etc. are left out, matching the established definition
 *  rather than a new one invented for this filter. */
export const isSetbackTopic = (topic: string): boolean => topic.startsWith("SETBACK.") || topic.startsWith("SEPARATION.");

/** Council rules for this place that did NOT produce a result, and council clauses not yet encoded.
 *  scope === "setbacks" narrows both to setback-category topics (see isSetbackTopic). */
export async function councilExplanation(db: Db, scenario: evaluate.Scenario, results: evaluate.Result[], loaded: evaluate.Loaded,
  scope: "all" | "setbacks" | "maps" = "all") {
  const s = scenario.site, facts = scenario.facts ?? {}, st = scenario.structures[0].structure_type;
  const { rules, parents } = loaded;
  const seen = new Set(results.map((r) => r.rule));
  const isCouncil = (r: evaluate.Rule) => (r.scopes ?? []).some((x) => x.level === "LOCAL_GOVERNMENT" && x.lg === s.lg);
  const inScope = (topic: string) => scope !== "setbacks" || isSetbackTopic(topic);
  const notApplied: any[] = [];
  let elsewhere = 0;
  for (const r of rules) {
    if (!isCouncil(r) || seen.has(r.rule_version_id) || !["REQUIREMENT", "RELAXATION"].includes(r.role) || !inScope(r.topic)) continue;
    if (!evaluate.scopeMatches(r, s)) {
      elsewhere += 1;
      continue;
    }
    const why = !evaluate.subjectMatches(r, st, parents) ? `does not cover a ${STRUCTURES[st].toLowerCase()}` : whyNot(r, facts);
    notApplied.push({ rule: r.rule_version_id, title: r.title, why, sources: (r.sources ?? []).filter((x) => x.role === "PRIMARY").map((x) => x.ref) });
  }
  const drafts: any[] = await db.q(`SELECT coalesce(json_agg(d), '[]') FROM (
        SELECT rv.rule_version_id, ru.topic, rv.regime,
               (SELECT string_agg(p.ref_label, '; ') FROM regs.rule_sources s JOIN regs.provisions p USING (provision_id)
                 WHERE s.rule_version_id = rv.rule_version_id AND s.role = 'PRIMARY') AS ref,
               (SELECT p.code_name FROM regs.rule_sources s JOIN regs.provisions p USING (provision_id)
                 WHERE s.rule_version_id = rv.rule_version_id AND s.role = 'PRIMARY' LIMIT 1) AS code, ru.title,
               (SELECT json_agg(json_build_object('level', s.level, 'lg', s.lg_id, 'zone', s.zone_id, 'precinct', s.precinct_id,
                        'overlay', s.overlay_id, 'local_plan', s.local_plan_id, 'local_plan_precinct', s.local_plan_precinct_id,
                        'exclude', s.exclude)) FROM regs.rule_scopes s WHERE s.rule_version_id = rv.rule_version_id) AS scopes
        FROM regs.rule_versions rv JOIN regs.rules ru USING (rule_id)
        WHERE rv.status = 'DRAFT' AND EXISTS (SELECT 1 FROM regs.rule_scopes s WHERE s.rule_version_id = rv.rule_version_id
                                               AND s.lg_id = ${lit(s.lg)})) d`);
  const pending = drafts.filter((d) => evaluate.scopeMatches(d, s) && inScope(d.topic))
    .map((d) => ({ rule: d.rule_version_id, topic: d.topic, regime: d.regime, source: d.ref, code: d.code, title: d.title }));
  const byCode = new Map<string, any[]>();
  for (const d of pending) {
    const k = d.code || "Other";
    if (!byCode.has(k)) byCode.set(k, []);
    byCode.get(k)!.push(d);
  }
  return { in_scope_not_applicable: notApplied, other_places_count: elsewhere,
    not_yet_encoded: [...byCode.entries()].sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0)).map(([code, v]) => ({ code, count: v.length, clauses: v })) };
}

export interface RunOptions {
  address?: string | null; lon?: number | null; lat?: number | null; zoneId?: string | null; precincts?: string[] | null; assessmentDate?: string | null;
  /** "all" (default): everything, unchanged. "setbacks": location is still resolved (rules need the zone/overlay
   *  facts), but only setback-category rules (see isSetbackTopic) are returned — no rule evaluation is skipped, only
   *  what comes back is narrowed. "maps": the rule engine is not run at all — cheaper, not just a narrower reply. */
  scope?: "all" | "setbacks" | "maps";
}

const LOCATION_FIELDS = ["geocode", "lon", "lat", "council", "parcel", "parcel_geometry", "pda", "zoning", "overlays", "sources",
  "site_constraints", "lookup_failures", "overlay_failures", "not_checked"];

export async function run(db: Db, structure: string, inputs: Record<string, any>, o: RunOptions = {}) {
  if (!(structure in STRUCTURES)) throw new ValueError(`structure must be one of ${pyStr(Object.keys(STRUCTURES).sort())}`);
  const date = o.assessmentDate || today();
  const scope = o.scope ?? "all";
  const loc = await locate(db, o.address, o.lon, o.lat);
  if (o.zoneId) {   // manual override / no map service
    if (!loc.available_zones.some((z: any) => z.zone_id === o.zoneId))
      throw new ValueError(`Zone ${o.zoneId} is not a zone of ${loc.council.lga_name}. Valid: ${loc.available_zones.map((z: any) => z.zone_id).join(", ")}`);
    const valid = new Set(loc.available_precincts.map((x: any) => x.precinct_id));
    const bad = (o.precincts ?? []).filter((p) => !valid.has(p));
    if (bad.length) throw new ValueError(`Unknown precinct(s) for this council: ${pyStr(bad)}`);
    loc.zoning.zone_id = o.zoneId;
    loc.zoning.manual = true;
    loc.zoning.precincts = o.precincts ?? [];
  }
  if (scope === "maps") {
    // Maps-only: the rule engine (facts, DB rule load, resolve, council explanation) is not run at all.
    return {
      scope, assessment_date: date,
      structure: { type: structure, label: STRUCTURES[structure] },
      location: Object.fromEntries(LOCATION_FIELDS.filter((k) => k in loc).map((k) => [k, loc[k]])),
      scheme_viewer: zoning.loadConfig()[loc.council.lg_id]?.scheme_viewer ?? null,
      warnings: [...loc.warnings, ...(loc.zoning.zone_id ? [] : ["Zone unknown: only council-wide and State rules are shown."])],
      applicable_instruments: [], facts: {}, rules: [], displaced: [], missing_inputs: [], council_rules: null,
      available_zones: loc.available_zones, available_precincts: loc.available_precincts,
    };
  }
  const facts = buildFacts(loc, structure, inputs);
  const siteDef: evaluate.Site = { lg: loc.council.lg_id, zone: loc.zoning.zone_id, precincts: loc.zoning.precincts,
    local_plans: loc.zoning.local_plans, local_plan_precincts: loc.zoning.local_plan_precincts,
    overlays: unique<string>(loc.overlays.flatMap((x: any) => x.overlay_ids)).sort() };
  const scenario: evaluate.Scenario = { assessment_date: date, site: siteDef,
    facts: Object.fromEntries(Object.entries(facts).map(([k, v]) => [k, v.value])),
    structures: [{ label: STRUCTURES[structure], structure_type: structure, facts: {}, boundaries: boundaries(facts) }] };
  const loaded = await evaluate.load(db, siteDef.lg, date);
  const results = evaluate.resolveWith(loaded, scenario);
  const liveAll = results.filter((r) => r.state !== "DISPLACED")
    .sort((a, b) => cmpTuple([a.regime, String(a.boundary || ""), a.topic], [b.regime, String(b.boundary || ""), b.topic]));
  const live = scope === "setbacks" ? liveAll.filter((r) => isSetbackTopic(r.topic)) : liveAll;
  // Planning triggers (e.g. a zone where any building work needs an impact-assessable application) carry no siting
  // value, so the resolver does not return them: say so up front instead. Shown for both "all" and "setbacks" (they
  // bear on whether siting rules apply at all); "maps" never reaches here.
  const triggers = loaded.rules.filter((r) => r.role === "TRIGGER" && r.regime === "PLANNING" && loaded.activeIvs.has(r.instrument_version_id)
    && evaluate.scopeMatches(r, siteDef) && evaluate.subjectMatches(r, structure, loaded.parents))
    .map((r) => `Planning approval: ${r.title} (${r.rule_version_id}). ${r.interpretation_notes ?? ""}`.trim());
  return {
    scope,
    assessment_date: date,
    structure: { type: structure, label: STRUCTURES[structure] },
    location: Object.fromEntries(LOCATION_FIELDS.filter((k) => k in loc).map((k) => [k, loc[k]])),
    scheme_viewer: zoning.loadConfig()[loc.council.lg_id]?.scheme_viewer ?? null,
    warnings: [...triggers, ...loc.warnings,
      ...(loc.pda ? [`Inside Priority Development Area '${loc.pda.pda_name}': the PDA land use plan applies; QDC/QHC siting parts do not.`] : []),
      ...(loc.zoning.zone_id ? [] : ["Zone unknown: only council-wide and State rules are shown."])],
    applicable_instruments: await applicableInstruments(db, loc.council.lg_id, date),
    facts,
    rules: live,
    displaced: results.filter((r) => r.state === "DISPLACED" && (scope !== "setbacks" || isSetbackTopic(r.topic))),
    missing_inputs: await missingInputs(db, live, scenario.facts!),
    council_rules: await councilExplanation(db, scenario, results, loaded, scope),
    available_zones: loc.available_zones,
    available_precincts: loc.available_precincts,
  };
}
