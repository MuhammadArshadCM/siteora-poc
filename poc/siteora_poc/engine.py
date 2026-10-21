# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/core/engine.ts
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Address (or zone) + proposed structure -> applicable rules, values and sources.
#
# Pipeline:
#   1. locate   address -> point -> council, parcel (lot/plan, area, outline), PDA, zone/precincts
#   2. facts    combine property facts + structure inputs; every fact carries its provenance
#   3. resolve  tools/evaluate.py resolves the rules (scope, conditions, precedence, versions)
#   4. explain  group results by boundary; list inputs that would remove MANUAL_REVIEW states
# """
# import datetime as dt
# import urllib.parse
# import pathlib
# import sys
#
# sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / "tools"))
# import evaluate  # noqa: E402
#
# from . import geo, site, zoning  # noqa: E402
#
# STRUCTURES = {
#     "SHED": "Shed", "GARAGE": "Garage (enclosed)", "CARPORT": "Carport", "PATIO": "Patio (roofed)",
#     "PERGOLA": "Pergola", "DECK": "Deck", "DETACHED_LAUNDRY": "Detached laundry", "GATEHOUSE": "Gatehouse",
#     "POOL_INGROUND": "In-ground swimming pool", "POOL_ABOVEGROUND": "Above-ground swimming pool",
#     "POOL_FENCE": "Pool fence / barrier",
# }
#
#
# class Db:
#     def __init__(self, host="localhost", port="5432", db="siteora", user="postgres"):
#         self.host, self.port, self.db, self.user = host, port, db, user
#
#     def q(self, sql):
#         return evaluate.query(self, sql)
#
#
# def _lit(s):
#     return "'" + str(s).replace("'", "''") + "'"
#
#
# def council_places(db, lg_id):
#     zones = db.q(f"""SELECT coalesce(json_agg(json_build_object('zone_id', z.zone_id, 'name', z.name,
#                         'dwelling_house_permitted', z.dwelling_house_permitted) ORDER BY z.name), '[]')
#                      FROM regs.zones z JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = {_lit(lg_id)}""")
#     precincts = db.q(f"""SELECT coalesce(json_agg(json_build_object('precinct_id', p.precinct_id, 'zone_id', p.zone_id, 'name', p.name)
#                         ORDER BY p.name), '[]') FROM regs.precincts p JOIN regs.zones z USING (zone_id)
#                         JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = {_lit(lg_id)}""")
#     return zones, precincts
#
#
# def council_local_plans(db, lg_id):
#     lps = db.q(f"""SELECT coalesce(json_agg(json_build_object('local_plan_id', l.local_plan_id, 'name', l.name)), '[]')
#                    FROM regs.local_plans l JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = {_lit(lg_id)}""")
#     lpps = db.q(f"""SELECT coalesce(json_agg(json_build_object('local_plan_precinct_id', x.local_plan_precinct_id,
#                         'local_plan_id', x.local_plan_id, 'name', x.name)), '[]')
#                     FROM regs.local_plan_precincts x JOIN regs.local_plans l USING (local_plan_id)
#                     JOIN regs.instruments i USING (instrument_id) WHERE i.lg_id = {_lit(lg_id)}""")
#     return lps, lpps
#
#
# def locate(db, address=None, lon=None, lat=None):
#     """Steps 1: everything we can learn about the property from public data."""
#     loc = {"warnings": []}
#     if address:
#         g = geo.geocode(address)
#         loc["geocode"] = g
#         lon, lat = g["lon"], g["lat"]
#         if g.get("unmatched_input"):
#             loc["warnings"].append(f"Matched '{g['address']}' but these parts of the input did not match: {g['unmatched_input']}. Check it is the right property.")
#     loc["lon"], loc["lat"] = lon, lat
#     loc["council"] = geo.council_at(lon, lat)
#     if not loc["council"]["lg_id"]:
#         raise LookupError(f"{loc['council']['lga_name']} is not one of the 7 councils in the dataset")
#     points = [(lon, lat)]
#     try:
#         p = geo.parcel_at(lon, lat)
#         loc["parcel"] = {k: p[k] for k in ("lot", "plan", "lotplan", "lot_area", "parcel_typ", "tenure")}
#         loc["parcel"].update(geo.parcel_metrics(p["rings"]))
#         loc["parcel_geometry"] = p["rings"]   # lon/lat rings, for the map
#         ring = max(p["rings"], key=len)
#         points.append((sum(x for x, _ in ring[:-1]) / (len(ring) - 1), sum(y for _, y in ring[:-1]) / (len(ring) - 1)))
#         if (p.get("plan") or "").startswith(("SP", "BUP", "GTP")) and p.get("parcel_typ") != "Lot Type Parcel":
#             loc["warnings"].append("Parcel may be part of a community titles / strata scheme — check which lot the work is on.")
#     except LookupError as e:
#         loc["parcel"] = None
#         loc["warnings"].append(str(e))
#     loc["pda"] = geo.pda_at(lon, lat)
#     lg = loc["council"]["lg_id"]
#     zones, precincts = council_places(db, lg)
#     lps, lpps = council_local_plans(db, lg)
#     loc["zoning"] = {"from_map": None, "zone_id": None, "precincts": [], "local_plans": [], "local_plan_precincts": []}
#     cfg = zoning.load_config().get(lg, {})
#     if cfg.get("status") != "WORKING":
#         loc["warnings"].append(f"No public zoning map service for this council ({cfg.get('notes') or 'not configured'}) — choose the zone manually.")
#     else:
#         z = zoning.lookup(lg, points)
#         loc["zoning"]["from_map"] = z
#         if z:
#             zid, pids, lpids, lppids, notes = zoning.match(z, zones, precincts, lps, lpps)
#             loc["zoning"].update(zone_id=zid, precincts=pids, local_plans=lpids, local_plan_precincts=lppids)
#             loc["warnings"] += notes
#         else:
#             loc["warnings"].append("The council zoning map returned no zone at this property (e.g. road reserve) — choose the zone manually.")
#     loc["overlays"] = []
#     if cfg.get("overlay_layers"):
#         loc["overlays"] = zoning.overlays(lg, points)
#         for o in loc["overlays"]:
#             if not o["overlay_ids"] and not o.get("value_fact") and not o.get("flag_fact"):
#                 loc["warnings"].append(f"{o['name']} '{o['text']}' is not mapped to an overlay in the rules dataset.")
#     else:
#         loc["warnings"].append("Overlays (character, flood, heritage, bushfire…) are not looked up for this council — overlay rules are not shown.")
#     loc["available_zones"] = zones
#     loc["available_precincts"] = precincts
#     loc["site_constraints"] = site.constraints(lg, loc.get("parcel_geometry"))
#     loc["sources"] = sources(loc, cfg)
#     return loc
#
#
# def _links(layer, lon, lat):
#     """Links a person can open: the exact point query (readable HTML), the layer description, and the layer
#     on the ArcGIS Map Viewer centred on the property."""
#     q = urllib.parse.urlencode({"geometry": f"{lon},{lat}", "geometryType": "esriGeometryPoint", "inSR": 4326,
#                                 "spatialRel": "esriSpatialRelIntersects", "outFields": "*", "returnGeometry": "false", "f": "html"})
#     service = layer.rsplit("/", 1)[0]
#     return {"layer": layer, "query_url": f"{layer}/query?{q}", "layer_url": f"{layer}?f=html",
#             "viewer_url": "https://www.arcgis.com/apps/mapviewer/index.html?"
#                           + urllib.parse.urlencode({"url": service, "center": f"{lon},{lat}", "level": 18})}
#
#
# def sources(loc, cfg):
#     """Every map service consulted for this property, with what it returned."""
#     lon, lat = loc["lon"], loc["lat"]
#     z = (loc.get("zoning") or {}).get("from_map") or {}
#     p = loc.get("parcel") or {}
#     out = [{"what": "Address → point", "source": "QldLocator geocoder (Queensland Government)",
#             "result": (loc.get("geocode") or {}).get("address") or "coordinates entered", **_links(geo.GEOCODER.rsplit("/", 1)[0], lon, lat),
#             "query_url": geo.GEOCODER + "?" + urllib.parse.urlencode({"SingleLine": (loc.get("geocode") or {}).get("address", ""), "f": "html"})},
#            {"what": "Council", "source": "State LGA boundaries", "result": loc["council"]["lga_name"], **_links(geo.LGA_LAYER, lon, lat)},
#            {"what": "Land parcel", "source": "State cadastre (DCDB)", "result": p.get("lotplan") or "not found", **_links(geo.PARCEL_LAYER, lon, lat)},
#            {"what": "Priority Development Area", "source": "State PDA boundaries", "result": (loc.get("pda") or {}).get("pda_name") or "not in a PDA",
#             **_links(geo.PDA_LAYER, lon, lat)}]
#     if cfg.get("zone_layer"):
#         out.append({"what": "Zone", "source": "Council zoning map", "result": z.get("zone_text") or ("blocked" if cfg.get("status") != "WORKING" else "no zone at this point"),
#                     **_links(cfg["zone_layer"], lon, lat)})
#     for layer in cfg.get("precinct_layers", []):
#         out.append({"what": "Zone precinct", "source": "Council zoning map", "result": z.get("precinct_text") or "none", **_links(layer, lon, lat)})
#     if cfg.get("local_plan_layer"):
#         out.append({"what": "Local / neighbourhood plan", "source": "Council map", "result": z.get("local_plan_text") or "none",
#                     **_links(cfg["local_plan_layer"], lon, lat)})
#     if cfg.get("local_plan_precinct_layer"):
#         out.append({"what": "Local plan precinct", "source": "Council map",
#                     "result": z.get("local_plan_precinct_text") or z.get("local_plan_precinct_code") or "none", **_links(cfg["local_plan_precinct_layer"], lon, lat)})
#     hits = {}
#     for o in loc.get("overlays", []):
#         hits.setdefault(o["source"], []).append(o["text"])
#     for ov in cfg.get("overlay_layers", []):
#         out.append({"what": "Overlay", "source": ov["name"], "result": "; ".join(hits.get(ov["layer"], [])) or "not on this property",
#                     "hit": ov["layer"] in hits, **_links(ov["layer"], lon, lat)})
#     return out
#
#
# def build_facts(loc, structure, inputs):
#     """Step 2: facts with provenance. inputs = user-supplied values (strings/numbers/bools)."""
#     facts = {}
#
#     def put(name, value, source):
#         if value is not None and value != "":
#             facts[name] = {"value": value, "source": source}
#
#     parcel = loc.get("parcel") or {}
#     area = parcel.get("lot_area") or None
#     put("lot_area_m2", area if area else parcel.get("computed_area_m2"),
#         "Registered lot area (DCDB)" if area else "Computed from parcel outline")
#     put("lot_width_m", parcel.get("est_width_m"), "ESTIMATED from parcel outline (minimum bounding rectangle)")
#     put("road_frontage_m", parcel.get("est_width_m"), "ESTIMATED: assumed equal to lot width")
#     put("average_lot_depth_m", parcel.get("est_depth_m"), "ESTIMATED from parcel outline")
#     if parcel.get("rectangularity") is not None:
#         put("lot_is_rectangular_or_near", parcel["rectangularity"] >= 0.9, f"ESTIMATED: rectangularity {parcel['rectangularity']} (>= 0.9)")
#     put("in_priority_development_area", bool(loc.get("pda")), "Priority Development Areas layer (Queensland Government)")
#     for fact, v in site.facts_from(loc.get("site_constraints", [])).items():
#         put(fact, v, "Network / constraint map: " + ("mapped on or near the lot" if v else "nothing mapped on the lot (maps can be incomplete)"))
#     # value overlays (e.g. a mapped maximum height); the lowest value governs if polygons overlap
#     for o in sorted((o for o in loc.get("overlays", []) if o.get("value_fact") and o.get("value") is not None),
#                     key=lambda o: o["value"], reverse=True):
#         put(o["value_fact"], o["value"], f"{o['name']} map: '{o['text']}'")
#     zone_id = loc["zoning"]["zone_id"]
#     zone = next((z for z in loc["available_zones"] if z["zone_id"] == zone_id), None)
#     if zone and zone["dwelling_house_permitted"] is not None:
#         put("zone_permits_dwelling_house", zone["dwelling_house_permitted"], "regs.zones (scheme table of assessment)")
#     for fact, hit in zoning.overlay_flags(loc["council"]["lg_id"], loc.get("overlays", [])).items():
#         put(fact, hit, "Council overlay map (" + ("inside" if hit else "outside") + " the mapped area)")
#     if loc["council"]["lg_id"] == "LOGAN" and zone and zone["dwelling_house_permitted"] and "dwelling_house_code_applies" not in facts:
#         put("dwelling_house_code_applies", True, "ASSUMED: lot is in a 'residential area' on Logan's Residential overlay (not checked)")
#     # Assumptions a POC has to make; all are listed in the output
#     put("land_is_regulated_land", True, "ASSUMED: lot has (or will have) a dwelling")
#     put("in_wind_region_c", False, "ASSUMED: SEQ councils are not in Wind Region C")
#     put("planning_assessment_required", False, "ASSUMED: house is accepted development (no planning application)")
#     put("development_footprint_exists", False, "ASSUMED: no approved plan of development / footprint")
#     # User inputs (structure + things public data cannot tell us)
#     num = lambda k: float(inputs[k]) if inputs.get(k) not in (None, "") else None
#     yes = lambda k: None if inputs.get(k) in (None, "") else str(inputs[k]).lower() in ("1", "true", "yes", "on")
#     h, length, width = num("height_m"), num("length_m"), num("width_m")
#     put("structure_height_m", h, "User input")
#     put("building_height_m", h, "User input (height)")
#     put("part_height_m", h, "User input (height; tallest part)")
#     put("structure_height_above_ground_m", h, "User input (height)")
#     put("wall_height_m", num("wall_height_m") or h, "User input" if num("wall_height_m") else "User input (height, used as wall height)")
#     put("mean_height_m", num("mean_height_m") or h, "User input" if num("mean_height_m") else "ASSUMED: mean height = height (conservative)")
#     if length and width:
#         put("plan_area_m2", round(length * width, 2), "User input (length x width)")
#         put("longest_side_m", max(length, width), "User input")
#         put("btb_length_on_boundary_m", num("btb_length_m") or max(length, width),
#             "User input" if num("btb_length_m") else "ASSUMED: longest side runs along the boundary")
#         put("btb_max_single_part_length_m", max(length, width), "User input")
#         put("total_outbuilding_floor_area_m2", round((num("existing_outbuildings_m2") or 0) + length * width, 2),
#             "User input (this structure + existing outbuildings)")
#         put("total_outbuilding_roofed_area_m2", facts["total_outbuilding_floor_area_m2"]["value"], "As floor area")
#     for k, src in (("is_roofed", "User input"), ("is_enclosed", "User input"), ("is_attached_to_dwelling", "User input")):
#         put(k, yes(k), src)
#     v = yes("in_front_of_main_building_line")
#     put("in_front_of_main_building_line", bool(v), "User input" if v is not None else "ASSUMED: behind the main building line of the house")
#     # Not available from public data in this POC: default to "no" and say so
#     for k, what in (("is_corner_lot", "a corner lot"), ("adjoins_canal_or_lake", "next to a canal or lake")):
#         v = yes(k)
#         put(k, bool(v), "User input" if v is not None else f"ASSUMED: not {what} (not checked)")
#     if num("lot_slope_pct") is not None:
#         put("lot_slope_pct", num("lot_slope_pct"), "User input")
#     else:   # every slope-dependent height limit is higher on steep land, so flat is the conservative default
#         put("lot_slope_pct", 0, "ASSUMED: flat lot (height limits rise on slopes over 15 %; enter the slope if steep)")
#     put("distance_to_adjoining_habitable_window_m", num("window_distance_m"), "User input")
#     put("pool_coping_height_m", h if structure.startswith("POOL_") and structure != "POOL_FENCE" else None, "User input (height)")
#     if structure.startswith("POOL"):
#         put("pool_capable_depth_m", 1.5, "ASSUMED: pool holds 300 mm or more")
#         put("pool_is_indoor", False, "ASSUMED: outdoor pool")
#         put("solid_wall_between_pool_and_boundary_height_m", 0, "ASSUMED: no solid wall between pool and boundary")
#         put("solid_wall_top_above_coping_m", 0, "ASSUMED")
#         put("solid_fence_above_pool_deck_m", 0, "ASSUMED")
#     if structure == "POOL_FENCE":
#         put("barrier_height_mm", h * 1000 if h else None, "User input (height)")
#         put("ncz_side", "OUTSIDE", "ASSUMED: non-climbable zone on the outside")
#         put("ncz_required", True, "ASSUMED")
#         put("barrier_has_cranked_top", False, "ASSUMED")
#     put("wall_is_maintenance_free", True, "ASSUMED: prefinished steel / masonry")
#     put("is_garage_under_main_roof", False if structure in ("GARAGE", "CARPORT", "SHED") else None, "ASSUMED: detached")
#     put("weather_control_attached_to_btb_part", True, "ASSUMED: eaves belong to the same building")
#     return facts
#
#
# def boundaries(facts):
#     b = [{"boundary_type": "PRIMARY_FRONTAGE"}, {"boundary_type": "SIDE"}, {"boundary_type": "REAR"}]
#     if (facts.get("is_corner_lot") or {}).get("value"):
#         b.insert(1, {"boundary_type": "SECONDARY_FRONTAGE_ROAD"})
#     return b
#
#
# def applicable_instruments(db, lg_id, date):
#     return db.q(f"""SELECT coalesce(json_agg(json_build_object('instrument', i.title, 'version', iv.version_label,
#                         'regime', a.regime, 'from', a.effective_from, 'to', a.effective_to, 'end_condition', a.end_condition,
#                         'basis', p.ref_label) ORDER BY a.regime, i.title), '[]')
#                     FROM regs.instrument_applicability a JOIN regs.instrument_versions iv USING (instrument_version_id)
#                     JOIN regs.instruments i ON i.instrument_id = iv.instrument_id
#                     LEFT JOIN regs.provisions p ON p.provision_id = a.basis_provision_id
#                     WHERE (a.lg_id = {_lit(lg_id)} OR a.lg_id IS NULL) AND a.effective_from <= {_lit(date)}
#                       AND (a.effective_to IS NULL OR a.effective_to >= {_lit(date)})""")
#
#
# def missing_inputs(db, results, facts):
#     """Facts referenced by MANUAL_REVIEW rules that we do not have."""
#     ids = sorted({r["rule"] for r in results if r.get("state") == "MANUAL_REVIEW"})
#     if not ids:
#         return []
#     inlist = ",".join(_lit(i) for i in ids)
#     used = db.q(f"""SELECT coalesce(json_agg(DISTINCT f), '[]') FROM (
#                       SELECT fact_id AS f FROM regs.rule_conditions WHERE rule_version_id IN ({inlist})
#                       UNION SELECT v #>> '{{}}' FROM regs.rule_versions rv, jsonb_path_query(rv.value_expr, 'lax $.**.var') v
#                       WHERE rv.rule_version_id IN ({inlist})) x""")
#     desc = dict(db.q(f"""SELECT coalesce(json_agg(json_build_array(fact_id, description)), '[]') FROM regs.facts
#                         WHERE fact_id IN ({','.join(_lit(u) for u in used) or "''"})"""))
#     return [{"fact": u, "description": desc.get(u)} for u in used if u not in facts and u != "boundary_type"]
#
#
# def _why_not(rule, facts):
#     """Plain-language reason a rule in scope did not apply: the conditions that failed."""
#     show = lambda v: ", ".join(map(str, v)) if isinstance(v, list) else v
#     reasons = []
#     groups = {}
#     for c in rule["conditions"] or []:
#         groups.setdefault(c["group"], []).append(c)
#     for cs in groups.values():
#         failed = [c for c in cs if c["fact"] != "boundary_type" and evaluate.cond(c, facts) is False]
#         reasons.append(" and ".join(f"needs {c['fact']} {c['op'] if c['value'] is not None else c['op'].lower().replace('_', ' ')}"
#                                     f"{'' if c['value'] is None else ' ' + str(show(c['value']))} (here: {facts.get(c['fact'])})" for c in failed)
#                        or "applies only to a boundary type this lot does not have")
#     return " — or — ".join(dict.fromkeys(reasons)) or "conditions not met"
#
#
# def council_explanation(db, scenario, results):
#     """Council rules for this place that did NOT produce a result, and council clauses not yet encoded.
#
#     So a 'State rules only' answer explains itself: e.g. small-lot rules exist for this zone but the lot
#     is 450 m2 or more."""
#     site, facts, st = scenario["site"], scenario["facts"], scenario["structures"][0]["structure_type"]
#     _, rules, _, parents, _ = evaluate.load(db, site["lg"], scenario["assessment_date"])
#     seen = {r["rule"] for r in results}
#     is_council = lambda r: any(s["level"] == "LOCAL_GOVERNMENT" and s["lg"] == site["lg"] for s in r["scopes"] or [])
#     not_applied, elsewhere = [], 0
#     for r in rules:
#         if not is_council(r) or r["rule_version_id"] in seen or r["role"] not in ("REQUIREMENT", "RELAXATION"):
#             continue
#         if not evaluate.scope_matches(r, site):
#             elsewhere += 1
#             continue
#         why = (f"does not cover a {STRUCTURES[st].lower()}" if not evaluate.subject_matches(r, st, parents)
#                else _why_not(r, facts))
#         not_applied.append({"rule": r["rule_version_id"], "title": r["title"], "why": why,
#                             "sources": [s["ref"] for s in (r["sources"] or []) if s["role"] == "PRIMARY"]})
#     drafts = db.q(f"""SELECT coalesce(json_agg(d), '[]') FROM (
#         SELECT rv.rule_version_id, ru.topic, rv.regime,
#                (SELECT string_agg(p.ref_label, '; ') FROM regs.rule_sources s JOIN regs.provisions p USING (provision_id)
#                  WHERE s.rule_version_id = rv.rule_version_id AND s.role = 'PRIMARY') AS ref,
#                (SELECT p.code_name FROM regs.rule_sources s JOIN regs.provisions p USING (provision_id)
#                  WHERE s.rule_version_id = rv.rule_version_id AND s.role = 'PRIMARY' LIMIT 1) AS code, ru.title,
#                (SELECT json_agg(json_build_object('level', s.level, 'lg', s.lg_id, 'zone', s.zone_id, 'precinct', s.precinct_id,
#                         'overlay', s.overlay_id, 'local_plan', s.local_plan_id, 'local_plan_precinct', s.local_plan_precinct_id,
#                         'exclude', s.exclude)) FROM regs.rule_scopes s WHERE s.rule_version_id = rv.rule_version_id) AS scopes
#         FROM regs.rule_versions rv JOIN regs.rules ru USING (rule_id)
#         WHERE rv.status = 'DRAFT' AND EXISTS (SELECT 1 FROM regs.rule_scopes s WHERE s.rule_version_id = rv.rule_version_id
#                                                AND s.lg_id = {_lit(site["lg"])})) d""")
#     pending = [{"rule": d["rule_version_id"], "topic": d["topic"], "regime": d["regime"], "source": d["ref"], "code": d["code"], "title": d["title"]}
#                for d in drafts if evaluate.scope_matches(d, site)]
#     by_code = {}
#     for d in pending:
#         by_code.setdefault(d["code"] or "Other", []).append(d)
#     return {"in_scope_not_applicable": not_applied, "other_places_count": elsewhere,
#             "not_yet_encoded": [{"code": k, "count": len(v), "clauses": v} for k, v in sorted(by_code.items())]}
#
#
# def run(db, structure, inputs, address=None, lon=None, lat=None, zone_id=None, precincts=None, assessment_date=None):
#     if structure not in STRUCTURES:
#         raise ValueError(f"structure must be one of {sorted(STRUCTURES)}")
#     date = assessment_date or dt.date.today().isoformat()
#     loc = locate(db, address, lon, lat)
#     if zone_id:                                   # manual override / no map service
#         if zone_id not in {z["zone_id"] for z in loc["available_zones"]}:
#             raise ValueError(f"Zone {zone_id} is not a zone of {loc['council']['lga_name']}. "
#                              f"Valid: {', '.join(z['zone_id'] for z in loc['available_zones'])}")
#         bad = [p for p in (precincts or []) if p not in {x["precinct_id"] for x in loc["available_precincts"]}]
#         if bad:
#             raise ValueError(f"Unknown precinct(s) for this council: {bad}")
#         loc["zoning"]["zone_id"], loc["zoning"]["manual"] = zone_id, True
#         loc["zoning"]["precincts"] = precincts or []
#     facts = build_facts(loc, structure, inputs)
#     site = {"lg": loc["council"]["lg_id"], "zone": loc["zoning"]["zone_id"], "precincts": loc["zoning"]["precincts"],
#             "local_plans": loc["zoning"]["local_plans"], "local_plan_precincts": loc["zoning"]["local_plan_precincts"],
#             "overlays": sorted({i for o in loc["overlays"] for i in o["overlay_ids"]})}
#     scenario = {"assessment_date": date, "site": site, "facts": {k: v["value"] for k, v in facts.items()},
#                 "structures": [{"label": STRUCTURES[structure], "structure_type": structure, "facts": {}, "boundaries": boundaries(facts)}]}
#     results = evaluate.resolve(db, scenario)
#     live = [r for r in results if r["state"] != "DISPLACED"]
#     live.sort(key=lambda r: (r["regime"], str(r["boundary"] or ""), r["topic"]))
#     return {
#         "assessment_date": date,
#         "structure": {"type": structure, "label": STRUCTURES[structure]},
#         "location": {k: loc[k] for k in ("geocode", "lon", "lat", "council", "parcel", "parcel_geometry", "pda", "zoning", "overlays", "sources", "site_constraints") if k in loc},
#         "scheme_viewer": zoning.load_config().get(loc["council"]["lg_id"], {}).get("scheme_viewer"),
#         "warnings": loc["warnings"] + ([f"Inside Priority Development Area '{loc['pda']['pda_name']}': the PDA land use plan applies; QDC/QHC siting parts do not."] if loc.get("pda") else [])
#                     + ([] if loc["zoning"]["zone_id"] else ["Zone unknown: only council-wide and State rules are shown."]),
#         "applicable_instruments": applicable_instruments(db, loc["council"]["lg_id"], date),
#         "facts": facts,
#         "rules": live,
#         "displaced": [r for r in results if r["state"] == "DISPLACED"],
#         "missing_inputs": missing_inputs(db, live, scenario["facts"]),
#         "council_rules": council_explanation(db, scenario, results),
#         "available_zones": loc["available_zones"],
#         "available_precincts": loc["available_precincts"],
#     }
