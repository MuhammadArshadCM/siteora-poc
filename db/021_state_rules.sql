-- =============================================================================
-- State rules. Each SELECT define_rule(...) is one rule version as a JSON doc.
-- Expression language: docs/03-schema.md#expression-language
-- Boundary-dependent values use {"op":"switch","on":{"var":"boundary_type"},...};
-- "BTB permitted" is encoded as a minimum of 0 with permits_btb = true.
-- =============================================================================
SET search_path = regs, public;

-- -----------------------------------------------------------------------------
-- Shared legacy rules: identical text in QDC MP 1.1 and MP 1.2 (2010).
-- Defined once and instantiated for each part (lot < 450 m2 / >= 450 m2).
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  part record;
  tmpl text;
  docs text[] := ARRAY[
$d${
 "rule_id": "{P}.A2a.SIDE_REAR_CLEARANCE", "topic": "SETBACK.SIDE_REAR", "title": "Side and rear boundary clearance by height of part",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_SIDE_REAR_CLEARANCE_OMP", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.5},
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "part_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE", "CLASS_10B", {"id": "POOL", "exclude": true}],
 "conditions": [[{LOT}, {"fact": "road_frontage_m", "op": ">", "value": 15}],
                [{LOT}, {"fact": "lot_is_rectangular_or_near", "op": "IS_FALSE"}]],
 "sources": [{"ref": "A2(a)", "role": "PRIMARY", "quote": "(i) where the height of that part is 4.5m or less - 1.5m; and (ii) where the height of that part is greater than 4.5m but not more than 7.5m - 2m; and (iii) where the height is greater that 7.5m - 2m plus 0.5m for every 3m or part exceeding 7.5m."},
             {"ref": "def outermost projection", "role": "DEFINITION", "iv": "QDC_MP_1_2@2010-03-26"}],
 "interpretation_notes": "Evaluated per part: each part of the OMP is tested against the clearance computed from that part's own height (definition of height). 'every 3m or part' => ceil. Narrow-lot alternative (A2(b)) excluded by condition.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A2b.NARROW_LOT_CLEARANCE", "topic": "SETBACK.SIDE_REAR", "title": "Side and rear clearance for narrow lots (frontage 15 m or less) — Table A2",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_SIDE_REAR_CLEARANCE_OMP", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]},
     "then": {"op": "lookup_range", "x": {"var": "road_frontage_m"}, "rows": [
        {"max": 10.5, "value": 0.750}, {"min": 10.501, "max": 11.0, "value": 0.825}, {"min": 11.001, "max": 11.5, "value": 0.900},
        {"min": 11.501, "max": 12.0, "value": 0.975}, {"min": 12.001, "max": 12.5, "value": 1.050}, {"min": 12.501, "max": 13.0, "value": 1.125},
        {"min": 13.001, "max": 13.5, "value": 1.200}, {"min": 13.501, "max": 14.0, "value": 1.275}, {"min": 14.001, "max": 14.5, "value": 1.350},
        {"min": 14.501, "max": 15.0, "value": 1.425}]}},
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]},
     "then": {"op": "lookup_range", "x": {"var": "road_frontage_m"}, "rows": [
        {"max": 10.5, "value": 1.000}, {"min": 10.501, "max": 11.0, "value": 1.100}, {"min": 11.001, "max": 11.5, "value": 1.200},
        {"min": 11.501, "max": 12.0, "value": 1.300}, {"min": 12.001, "max": 12.5, "value": 1.400}, {"min": 12.501, "max": 13.0, "value": 1.500},
        {"min": 13.001, "max": 13.5, "value": 1.600}, {"min": 13.501, "max": 14.0, "value": 1.700}, {"min": 14.001, "max": 14.5, "value": 1.800},
        {"min": 14.501, "max": 15.0, "value": 1.900}]}}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "part_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE", "CLASS_10B", {"id": "POOL", "exclude": true}],
 "conditions": [[{LOT}, {"fact": "road_frontage_m", "op": "<=", "value": 15}, {"fact": "lot_is_rectangular_or_near", "op": "IS_TRUE"}]],
 "sources": [{"ref": "A2(b) Table A2", "role": "PRIMARY"}],
 "interpretation_notes": "Table A2 cell for 11.001-11.500 is printed '09.00'/'0900'; read as 0.900. Bands have gaps between 3-decimal limits (e.g. 10.5005) — round frontage to 3 dp before lookup. 'rectangular or near rectangular' is a judgement => not automatable.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A2a.POOL_SIDE_REAR", "topic": "POOL.SETBACK.SIDE_REAR", "title": "Swimming pool side and rear boundary clearance (from water's edge)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_POOL_WATER_TO_SIDE_REAR", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "<=", "args": [{"var": "pool_coping_height_m"}, 4.5]}, "then": 1.5},
    {"if": {"op": "<=", "args": [{"var": "pool_coping_height_m"}, 7.5]}, "then": 2.0}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "pool_coping_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{LOT}]],
 "sources": [{"ref": "A2(a)", "role": "PRIMARY"}, {"ref": "def setback", "role": "DEFINITION", "iv": "QDC_MP_1_2@2010-03-26",
              "quote": "for a swimming pool, the shortest distance measured horizontally from the water's edge to the vertical projection of a boundary of the lot."}],
 "interpretation_notes": "A2(a) applies to 'a part of the building or structure'; a pool is a structure and the side and rear boundary clearance for a pool is measured from the water's edge. Height of the pool part taken as coping height above natural ground. Full 3-tier A2(a) formula applied by height (<=4.5m / <=7.5m / taller), matching A2a.SIDE_REAR_CLEARANCE - the previous version only encoded the first tier and returned null (manual review) above 4.5 m, which was an incomplete encoding, not a real legal distinction (the quoted clause is the same one applied to any part of any structure).",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A2c.EXEMPT_FENCES_WALLS", "topic": "SETBACK.SIDE_REAR", "title": "Screens, fences, retaining walls up to 2 m exempt from side/rear clearance",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "EXEMPTION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["FENCE", "RETAINING_WALL", "POOL_FENCE"],
 "conditions": [[{LOT}, {"fact": "structure_height_m", "op": "<=", "value": 2.0}]],
 "sources": [{"ref": "A2(c)", "role": "PRIMARY", "quote": "(iii) a screen, fence or retaining wall or a combination of screens, fences or retaining walls is not more than 2m in height"}],
 "interpretation_notes": "A pool fence is a fence; a pool barrier over 2 m loses this exemption.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A2c.EXEMPT_RAINWATER_TANK", "topic": "SETBACK.SIDE_REAR", "title": "Rainwater tank up to 2.4 m exempt from side/rear clearance",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "EXEMPTION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["RAINWATER_TANK"],
 "conditions": [[{LOT}, {"fact": "structure_height_m", "op": "<=", "value": 2.4}]],
 "sources": [{"ref": "A2(c)", "role": "PRIMARY", "quote": "(iv) a rainwater tank, including any supporting structure such as a stand, is not more than 2.4m high."}],
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A2c.EXEMPT_ORNAMENTAL_PERGOLA", "topic": "SETBACK.SIDE_REAR", "title": "Unroofed, unenclosed ornamental pergola up to 2.4 m at boundary exempt",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "EXEMPTION",
 "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["PERGOLA", "OUTDOOR_STRUCTURE"],
 "conditions": [[{LOT}, {"fact": "is_roofed", "op": "IS_FALSE"}, {"fact": "is_enclosed", "op": "IS_FALSE"},
                 {"fact": "part_height_m", "op": "<=", "value": 2.4, "notes": "height at the boundary"},
                 {"fact": "primarily_ornamental_or_horticultural", "op": "IS_TRUE"},
                 {"fact": "used_for_entertainment_or_recreation", "op": "IS_FALSE"}]],
 "sources": [{"ref": "A2(c)", "role": "PRIMARY", "quote": "(v) subject to (ii), it is a pergola or other structure which is- (A) not enclosed by walls or roofed; and (B) not more than 2.4m in height at the boundary; and (C) primarily ornamental or for horticultural purposes."}],
 "interpretation_notes": "Use (entertainment) and 'primarily ornamental' are declarations, not geometry => not automatable. Decks, patios and verandahs are expressly NOT exempt under A2(c)(i).",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A2d.CLASS10A_WITHIN_CLEARANCE", "topic": "SETBACK.SIDE_REAR.BTB", "title": "Class 10a within side/rear clearance (up to built to boundary)",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_SIDE_REAR_CLEARANCE_OMP", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_10A"],
 "conditions": [[{LOT}, {"fact": "part_height_m", "op": "<=", "value": 4.5}, {"fact": "mean_height_m", "op": "<=", "value": 3.5},
                 {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 9.0},
                 {"fact": "distance_to_adjoining_habitable_window_m", "op": ">=", "value": 1.5}]],
 "sources": [{"ref": "A2(d)", "role": "PRIMARY"}],
 "interpretation_notes": "btb_length_on_boundary_m includes ALL buildings or parts of any class (incl. existing house parts) inside the clearance on that boundary. If the adjoining window distance is unknown the engine must return MANUAL_REVIEW, not PASS. Whether a roofed patio/deck that is Class 10a may use A2(d) given 'Subject to A2(c)' is contested — treat OUTDOOR_STRUCTURE as excluded unless certified Class 10a.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A2e.POOL_WITHIN_CLEARANCE", "topic": "POOL.SETBACK.SIDE_REAR", "title": "Pool within side/rear clearance behind a 1.8 m solid wall",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_POOL_WATER_TO_SIDE_REAR", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{LOT}, {"fact": "solid_wall_between_pool_and_boundary_height_m", "op": ">=", "value": 1.8},
                 {"fact": "solid_wall_top_above_coping_m", "op": ">=", "value": 1.0}]],
 "sources": [{"ref": "A2(e)", "role": "PRIMARY"}],
 "interpretation_notes": "Wall must also be 'constructed to prevent water entry onto adjoining lots' — a design declaration.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A3.SITE_COVER", "topic": "SITE_COVER", "title": "Maximum site cover 50% (roofed with impervious materials)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_SITE_COVER", "operator": "<=", "value": 50, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"],
 "conditions": [[{LOT}]],
 "sources": [{"ref": "A3", "role": "PRIMARY", "quote": "The maximum area covered by all buildings and structures roofed with impervious materials, does not exceed 50% of the lot area."}],
 "interpretation_notes": "Lot-level rule: evaluate with the proposed structure plus all existing roofed buildings/structures. Pools and unroofed decks are not 'roofed' and are excluded.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A4.BUILDING_HEIGHT", "topic": "HEIGHT.BUILDING", "title": "Maximum building height by lot slope",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_BUILDING_HEIGHT", "operator": "<=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<", "args": [{"var": "lot_slope_pct"}, 15]}, "then": 8.5}], "else": 10.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{LOT}]],
 "sources": [{"ref": "A4", "role": "PRIMARY"}],
 "interpretation_notes": "Text says '(a) up to 15%' and '(b) of 15% or more'; exactly 15% resolved to 10 m because (b) states it expressly. MP 1.x has NO separate Class 10a height limit (contrast QHC 4.5 m).",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A6.WALL_MAINTENANCE", "topic": "SETBACK.SIDE_REAR.MAINTENANCE", "title": "Wall within 750 mm of side/rear boundary must be maintenance free",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "value": 0.75, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{LOT}, {"fact": "wall_is_maintenance_free", "op": "IS_FALSE"}]],
 "sources": [{"ref": "A6", "role": "PRIMARY"}],
 "interpretation_notes": "Measured to the wall (not OMP). Rule only bites when the wall is not maintenance free.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A7.CORNER_SIGHTLINE", "topic": "CORNER.SIGHTLINE", "title": "Max 1 m high within 6 m-radius 3-chord truncation at road corner",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_SIGHTLINE_TRUNCATION_6M_RADIUS", "operator": "<=", "value": 1.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"],
 "conditions": [[{LOT}, {"fact": "is_corner_lot", "op": "IS_TRUE"}]],
 "sources": [{"ref": "A7", "role": "PRIMARY"}],
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A1d.POOL_ROAD_SETBACK", "topic": "POOL.SETBACK.ROAD", "title": "Pool water's edge to road frontage 1.5 m (coping <= 1.2 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_POOL_WATER_TO_ROAD", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{LOT}, {"fact": "pool_coping_height_m", "op": "<=", "value": 1.2}]],
 "sources": [{"ref": "A1(d)", "role": "PRIMARY", "quote": "(i) swimming pools, where the minimum distance from the water to the road frontage is – (A) where the vertical distance to the coping above the finished ground level is not more than 1.2m – 1.5m"}],
 "interpretation_notes": "Coping above 1.2 m: A1(d) falls back to the A1(a)-(c) road setback for the dwelling (FALLS_BACK_TO relationship).",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A1d.POOL_ROAD_WALL_EXEMPT", "topic": "POOL.SETBACK.ROAD", "title": "No pool road setback behind 1.8 m solid wall/fence 1.0 m above coping",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{LOT}, {"fact": "solid_wall_between_pool_and_boundary_height_m", "op": ">=", "value": 1.8},
                 {"fact": "solid_wall_top_above_coping_m", "op": ">=", "value": 1.0}]],
 "sources": [{"ref": "A1(d)", "role": "PRIMARY", "quote": "(B) where a solid wall or fence at least 1.8m high above finished ground level is constructed between the water and the road frontage and the top of the wall or fence is at least 1.0m above the top of the coping of the pool – no requirement"}],
 "interpretation_notes": "A front fence above 2 m (if needed to be 1.0 m above a raised coping) itself fails the 2 m fence exemption — check both.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A1d.EXEMPT_FENCES_ROAD", "topic": "SETBACK.ROAD", "title": "Screens, fences, retaining walls up to 2 m exempt from road setback",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["FENCE", "RETAINING_WALL", "POOL_FENCE"],
 "conditions": [[{LOT}, {"fact": "structure_height_m", "op": "<=", "value": 2.0}]],
 "sources": [{"ref": "A1(d)", "role": "PRIMARY", "quote": "(ii) screens, fences, retaining walls or a combination of screens, fences or retaining walls not more than 2m in height"}],
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.A1d.EXEMPT_GATEHOUSE_ROAD", "topic": "SETBACK.ROAD", "title": "Roofed gatehouse/arch (<= 4 m2, <= 2 m wide to street, <= 3 m high) exempt from road setback",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["GATEHOUSE"],
 "conditions": [[{LOT}, {"fact": "roof_area_m2", "op": "<=", "value": 4}, {"fact": "gatehouse_street_elevation_width_m", "op": "<=", "value": 2},
                 {"fact": "structure_height_m", "op": "<=", "value": 3}]],
 "sources": [{"ref": "A1(d)", "role": "PRIMARY", "quote": "(iii) roofed gatehouses and arches having – (A) a maximum area of 4m2 ; and (B) not more than 2m wide elevation to street; and (C) not more than 3m in height."}],
 "interpretation_notes": "'maximum area of 4m2' read as roof/plan area.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$,
$d${
 "rule_id": "{P}.APP.LOW_STRUCTURE", "topic": "APPLICATION", "title": "Part does not apply to structures less than 1 m above natural ground (except pools)",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "MANDATORY", "provision_kind": "APPLICATION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["OUTDOOR_STRUCTURE", "CLASS_10B", {"id": "POOL", "exclude": true}],
 "conditions": [[{LOT}, {"fact": "structure_height_above_ground_m", "op": "<", "value": 1.0}]],
 "sources": [{"ref": "Application", "role": "PRIMARY", "quote": "b) Except for swimming pools, structures less than 1m above natural ground"}],
 "interpretation_notes": "Typical case: a low unroofed deck. Exempts every rule of this part for that structure (EXEMPTS relationship to the whole instrument). Does not exempt it from planning-scheme rules.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$d$
  ];
BEGIN
  FOR part IN SELECT * FROM (VALUES
      ('QDC11', 'QDC_MP_1_1@2010-03-26', '{"fact": "lot_area_m2", "op": "<", "value": 450, "unit": "m2"}'),
      ('QDC12', 'QDC_MP_1_2@2010-03-26', '{"fact": "lot_area_m2", "op": ">=", "value": 450, "unit": "m2"}'))
    AS t(prefix, iv, lotcond)
  LOOP
    FOREACH tmpl IN ARRAY docs LOOP
      PERFORM define_rule(
        jsonb_set(replace(replace(tmpl, '{P}', part.prefix), '{LOT}', part.lotcond)::jsonb,
                  '{instrument_version}', to_jsonb(part.iv)));
    END LOOP;
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- MP 1.2 only (lots >= 450 m2): road setbacks
-- -----------------------------------------------------------------------------
SELECT define_rule($r${
 "rule_id": "QDC12.A1a.ROAD_SETBACK", "instrument_version": "QDC_MP_1_2@2010-03-26",
 "topic": "SETBACK.ROAD", "title": "Minimum road setback 6 m (dwelling, garage, carport; structures via A1(d))",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_ROAD_SETBACK_OMP", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE", "CLASS_10B", {"id": "POOL", "exclude": true}],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "A1(a)", "role": "PRIMARY", "quote": "(a) For a detached dwelling, garage or a carport the minimum road setback is – (i) 6m"},
             {"ref": "A1(d)", "role": "SUPPLEMENTARY", "quote": "(d) For structures the minimum road setbacks are as for A1(a),(b), and (c) except for –"}],
 "interpretation_notes": "Applies to every road frontage (MP 1.2 has no primary/secondary distinction outside the corner-lot provision). Sheds, patios, decks >= 1 m are reached through A1(d) 'structures'.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

SELECT define_rule($r${
 "rule_id": "QDC12.A1a.ROAD_SETBACK_NEIGHBOURS", "instrument_version": "QDC_MP_1_2@2010-03-26",
 "topic": "SETBACK.ROAD", "title": "Reduced road setback aligned with adjoining dwellings",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_ROAD_SETBACK_OMP", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"op": "-", "args": [{"op": "max_of", "args": [{"var": "adjoining_road_setbacks_m"}]}, {"op": "min_of", "args": [{"var": "adjoining_road_setbacks_m"}]}]}, 2]},
                                   "then": {"op": "min_of", "args": [{"var": "adjoining_road_setbacks_m"}]}}],
           "else": {"op": "avg_of", "args": [{"var": "adjoining_road_setbacks_m"}]}},
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "adjoining_dwellings_both_sides", "op": "IS_TRUE"},
                 {"fact": "any_adjoining_setback_3_to_6m", "op": "IS_TRUE"}]],
 "sources": [{"ref": "A1(a)", "role": "PRIMARY"}],
 "interpretation_notes": "'(A) a distance between the two buildings' read as: any setback not less than the smaller neighbour setback. Automatable once the page's optional adjoining-setback inputs are supplied (adjoining_road_setbacks_m, adjoining_dwellings_both_sides, any_adjoining_setback_3_to_6m); otherwise the conditions are unknown and the engine still routes to manual review. Added 23 Oct 2026 (user asked for this rule to be resolvable from optional neighbour-frontage inputs); previously always automatable=false with this precondition only noted in prose.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

SELECT define_rule($r${
 "rule_id": "QDC12.A1b.CORNER_NOMINATED_FRONTAGE", "instrument_version": "QDC_MP_1_2@2010-03-26",
 "topic": "SETBACK.CORNER", "title": "Corner lot (average depth <= 24 m): nominated road frontage per Table A1 graph",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_ROAD_SETBACK_OMP", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]},
            "then": {"op": "interpolate", "x": {"var": "lot_width_m"}, "points": [[10, 1.5], [24, 6.0]], "extrapolate": "NONE"}}],
           "else": {"op": "interpolate", "x": {"var": "lot_width_m"}, "points": [[10, 2.0], [22, 6.0]], "extrapolate": "NONE"}},
 "verification": "VERIFIED_FROM_FIGURE", "automatable": false,
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "is_corner_lot", "op": "IS_TRUE"},
                 {"fact": "average_lot_depth_m", "op": "<=", "value": 24}, {"fact": "is_nominated_road_frontage", "op": "IS_TRUE"}]],
 "sources": [{"ref": "A1(b)", "role": "PRIMARY"}, {"ref": "Table A1", "role": "FIGURE"}],
 "interpretation_notes": "Graph only (no formula). Axis is 'WIDTH OF SITE' — taken as lot width. Lines digitised to the same end points as the QHC Table A1 formulas. Outside 10-24 m width the graph gives no value => null => manual review. Requires the other frontage to use 6 m and the 9x9 truncation rule.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

SELECT define_rule($r${
 "rule_id": "QDC12.A1b.CORNER_TRUNCATION_9X9", "instrument_version": "QDC_MP_1_2@2010-03-26",
 "topic": "CORNER.TRUNCATION", "title": "No building or structure over 2 m within 9 m x 9 m corner truncation",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_CORNER_TRUNCATION_9X9", "operator": "<=", "value": 2.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "average_lot_depth_m", "op": "<=", "value": 24}]],
 "sources": [{"ref": "A1(b)", "role": "PRIMARY", "quote": "(C) no building or structure over 2m high is built within a 9m by 9m truncation at the corner of the 2 road frontages (Figure 3)."}],
 "interpretation_notes": "Only a condition of the A1(b)(ii) corner concession; if the 6 m setback is achieved on both frontages the truncation rule is not engaged (CONDITIONAL_ON relationship).",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

SELECT define_rule($r${
 "rule_id": "QDC12.A1c.OPEN_CARPORT", "instrument_version": "QDC_MP_1_2@2010-03-26",
 "topic": "SETBACK.ROAD", "title": "Open carport may be within road setback (no stated minimum)",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_ROAD_SETBACK_OMP", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["OPEN_CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "carport_obstruction_pct", "op": "<=", "value": 15},
                 {"fact": "alternative_carport_site_available", "op": "IS_FALSE"}]],
 "sources": [{"ref": "A1(c)", "role": "PRIMARY"}, {"ref": "def open carport", "role": "DEFINITION"}],
 "interpretation_notes": "Text: 'may be less than required' — no floor stated; 0 recorded. Absence of an alternative site (2.5 m access, max 1 in 5) is a judgement => manual review.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

-- -----------------------------------------------------------------------------
-- MP 1.1 only (lots < 450 m2): road setbacks by street type, garage openings
-- -----------------------------------------------------------------------------
SELECT define_rule($r${
 "rule_id": "QDC11.A1a.FRONTAGE_SETBACK", "instrument_version": "QDC_MP_1_1@2010-03-26",
 "topic": "SETBACK.FRONT", "title": "Minimum frontage setback by street type (Table A1)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_ROAD_SETBACK_OMP", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "street_type"}, "cases": {"ACCESS_PLACE": 3.0, "ACCESS_STREET": 3.0, "COLLECTOR": 4.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE", "CLASS_10B", {"id": "POOL", "exclude": true}],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"ref": "A1(a) Table A1", "role": "PRIMARY", "quote": "Access place and Access street 3.0 1.0 Collector street 4.0 2.0"},
             {"ref": "A1(b)", "role": "SUPPLEMENTARY", "quote": "(b) For a garage/carport the minimum road setback is- (i) as for A1(a)"},
             {"ref": "A1(d)", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "Street types other than access place/access street/collector are not covered by the table => null => manual review. Street hierarchy must come from council road-hierarchy data.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

SELECT define_rule($r${
 "rule_id": "QDC11.A1a.SIDE_TO_CORNER_STREET", "instrument_version": "QDC_MP_1_1@2010-03-26",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Minimum side-to-corner-street setback by street type (Table A1)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_ROAD_SETBACK_OMP", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "street_type"}, "cases": {"ACCESS_PLACE": 1.0, "ACCESS_STREET": 1.0, "COLLECTOR": 2.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE", "CLASS_10B", {"id": "POOL", "exclude": true}],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"ref": "A1(a) Table A1", "role": "PRIMARY"}, {"ref": "A1(c)", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "A1(c) corner-lot text interacts with the p9 graph also labelled 'Table A1'; which applies to the secondary street on a lot with average depth <= 24 m is ambiguous. Manual review.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

SELECT define_rule($r${
 "rule_id": "QDC11.A1a.FRONTAGE_NEIGHBOURS", "instrument_version": "QDC_MP_1_1@2010-03-26",
 "topic": "SETBACK.FRONT", "title": "Frontage setback aligned with adjoining dwellings",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_ROAD_SETBACK_OMP", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
     {"if": {"op": "<=", "args": [{"op": "max_of", "args": [{"var": "adjoining_road_setbacks_m"}]}, 3]}, "then": 0},
     {"if": {"op": "<=", "args": [{"op": "-", "args": [{"op": "max_of", "args": [{"var": "adjoining_road_setbacks_m"}]}, {"op": "min_of", "args": [{"var": "adjoining_road_setbacks_m"}]}]}, 2]},
      "then": {"op": "min_of", "args": [{"var": "adjoining_road_setbacks_m"}]}}],
   "else": {"op": "avg_of", "args": [{"var": "adjoining_road_setbacks_m"}]}},
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "adjoining_dwellings_both_sides", "op": "IS_TRUE"},
                 {"fact": "any_adjoining_setback_3_to_6m", "op": "IS_TRUE"}],
                [{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "adjoining_dwellings_both_sides", "op": "IS_TRUE"},
                 {"fact": "both_adjoining_setbacks_le_3m", "op": "IS_TRUE"}]],
 "sources": [{"ref": "A1(a) Table A1", "role": "PRIMARY"}],
 "interpretation_notes": "(iii) 'where adjacent buildings have road setbacks of 3m or less – any distance between the setbacks': encoded as minimum 0 when both neighbours <= 3 m; strictly the text allows any distance between the two setbacks (a range), which the engine should report rather than reduce to 0. Two OR-ed condition groups separate limb (ii) (at least one neighbour in 3-6 m) from limb (iii) (both neighbours <= 3 m) so a pair like (2 m, 7 m) — neither limb's precondition — correctly does NOT become a candidate (previously the value formula's 'else: avg_of' branch could fire for such a pair with no gating condition at all). Automatable once the page's optional adjoining-setback inputs are supplied; otherwise still manual review. Added 23 Oct 2026 (user asked for this rule to be resolvable from optional neighbour-frontage inputs).",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

SELECT define_rule($r${
 "rule_id": "QDC11.A1b.GARAGE_OPENING_WIDTH", "instrument_version": "QDC_MP_1_1@2010-03-26",
 "topic": "GARAGE.OPENING_WIDTH", "title": "Garage/carport openings facing street: lesser of 6 m and 50% of frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "GARAGE_OPENING_WIDTH_FACING_STREET", "operator": "<=", "unit": "m",
 "value": {"op": "min", "args": [6.0, {"op": "*", "args": [0.5, {"var": "road_frontage_m"}]}]},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "lot_is_rectangular_or_near", "op": "IS_TRUE"}]],
 "sources": [{"ref": "A1(b)", "role": "PRIMARY"}],
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

SELECT define_rule($r${
 "rule_id": "QDC11.A1c.CORNER_TRUNCATION_9X9", "instrument_version": "QDC_MP_1_1@2010-03-26",
 "topic": "CORNER.TRUNCATION", "title": "No building or structure over 2 m within 9 m x 9 m corner truncation",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_CORNER_TRUNCATION_9X9", "operator": "<=", "value": 2.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "average_lot_depth_m", "op": "<=", "value": 24}]],
 "sources": [{"ref": "A1(c)", "role": "PRIMARY"}],
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"}$r$);

-- -----------------------------------------------------------------------------
-- QHC (from 1 Sept 2026 in adopting LGs; everywhere from 1 Sept 2029)
-- Chapter 1 (lot < 450 m2) and Chapter 2 (lot >= 450 m2)
-- -----------------------------------------------------------------------------
SELECT define_rule($r${
 "rule_id": "QHC.APP.EXCLUSIONS", "instrument_version": "QHC@2026-09-01",
 "topic": "APPLICATION", "title": "QHC does not apply to low structures (<1 m, except pools), indoor pools, PDAs",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "MANDATORY", "provision_kind": "APPLICATION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"],
 "conditions": [[{"fact": "structure_height_above_ground_m", "op": "<", "value": 1.0}, {"fact": "pool_is_indoor", "op": "IS_NULL", "notes": "i.e. subject is not a pool"}],
                [{"fact": "pool_is_indoor", "op": "IS_TRUE"}],
                [{"fact": "in_priority_development_area", "op": "IS_TRUE"}]],
 "sources": [{"ref": "s 4", "role": "PRIMARY"}],
 "interpretation_notes": "Also excludes tourist parks and electric-line equipment (not modelled). Applies only to dwelling-permitted zones (s4(2)) — engine checks zone_permits_dwelling_house before selecting QHC at all.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.A1_1.HEIGHT_CLASS1", "instrument_version": "QHC@2026-09-01",
 "topic": "HEIGHT.BUILDING", "title": "Class 1/2 maximum height 8.5 m (+1.5 m where slope > 15%)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_HEIGHT", "operator": "<=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "lot_slope_pct"}, 15]}, "then": 10.0}], "else": 8.5},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A1.1", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.A1_1.HEIGHT_CLASS10A", "instrument_version": "QHC@2026-09-01",
 "topic": "HEIGHT.CLASS_10A", "title": "Class 10a maximum height 4.5 m (+1.5 m where slope > 15%)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_HEIGHT", "operator": "<=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "lot_slope_pct"}, 15]}, "then": 6.0}], "else": 4.5},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_10A"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A1.1", "role": "PRIMARY", "quote": "2. Class 10a buildings have a maximum height of 4.5m. 3. Where the slope of a lot exceeds 15%, the heights in A1.1(1)-(2) are increased by 1.5m."}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.A1_1.HEIGHT_FENCES", "instrument_version": "QHC@2026-09-01",
 "topic": "HEIGHT.FENCE", "title": "Fence, privacy screen, retaining or free-standing wall (or combination) maximum 2 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_HEIGHT", "operator": "<=", "value": 2.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["FENCE", "RETAINING_WALL", "POOL_FENCE"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A1.1", "role": "PRIMARY"}, {"ref": "Ch1 A10", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "A1.1(6) disapplies A1.1(4) to swimming pools, not to pool fences. A pool fence > 2 m (e.g. 2.4 m chosen to avoid an NCZ under MP 3.4) therefore needs a performance solution/referral under the QHC.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T1.FRONT_CLASS1", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — Class 1 external walls (and Class 10a not otherwise listed)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {
     "PRIMARY_FRONTAGE": {"op": "case", "when": [
        {"if": {"op": "is_true", "args": [{"var": "primary_frontage_is_lane_or_parkway"}]}, "then": 2.0},
        {"if": {"op": "is_true", "args": [{"var": "adjoining_premises_setback_less_than_table"}]}, "then": 2.0}], "else": 3.0},
     "SECONDARY_FRONTAGE_ROAD": 1.5, "SECONDARY_FRONTAGE_LANE_PARKWAY": 1.0, "SECONDARY_FRONTAGE_OTHER": 2.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A_OTHER"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A2.1 Table 1", "role": "PRIMARY"}, {"ref": "def QHC setback", "role": "DEFINITION"}],
 "interpretation_notes": "Supp. prov. 1 (lane/parkway primary => 2 m) and 2 (adjoining premises closer => reduce by 1 m) apply to Class 1/2 only; for CLASS_10A_OTHER the engine must use 3.0 (supp. 3 applies the Class 1 row, not the Class 1 reductions — contestable; flag).",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T1.FRONT_GARAGE", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — garage (and garage door)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 5.0, "SECONDARY_FRONTAGE_ROAD": 5.0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 1.0, "SECONDARY_FRONTAGE_OTHER": 2.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["GARAGE"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A2.1 Table 1", "role": "PRIMARY", "quote": "Building work including: a garage; or a carport. Building work including: a garage door: 5m | 5m | 1m | 2m"}],
 "interpretation_notes": "The same values apply to the garage door, measured door-to-access-boundary (QHC setback (b)); engine evaluates both measurements.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T1.FRONT_CARPORT", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — carport over 4.5 m high or mean height over 3.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_STRUCTURE_OMP_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 5.0, "SECONDARY_FRONTAGE_ROAD": 5.0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 1.0, "SECONDARY_FRONTAGE_OTHER": 2.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": ">", "value": 4.5}],
                [{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "mean_height_m", "op": ">", "value": 3.5}]],
 "sources": [{"ref": "Ch1 A2.1 Table 1", "role": "PRIMARY"}],
 "interpretation_notes": "QHC setback definition has no limb for a carport (a building without external walls). Measuring point (posts vs roof edge) needs a certifier view; the carport roof edge is separately a 'weather control element for a carport'.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T1.FRONT_SHED_LAUNDRY", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — detached shed or laundry",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 5.4, "SECONDARY_FRONTAGE_ROAD": 5.4, "SECONDARY_FRONTAGE_LANE_PARKWAY": 1.0, "SECONDARY_FRONTAGE_OTHER": 2.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["SHED", "DETACHED_LAUNDRY"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A2.1 Table 1", "role": "PRIMARY", "quote": "Building work including a detached: laundry; or shed: 5.4m | 5.4m | 1m | 2m"}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T1.FRONT_SMALL_CARPORT", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — carport <= 4.5 m high, mean height <= 3.5 m (BTB except 'other' frontage)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_STRUCTURE_OMP_TO_BOUNDARY", "operator": ">=", "unit": "m", "permits_btb": true,
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 0, "SECONDARY_FRONTAGE_ROAD": 0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0, "SECONDARY_FRONTAGE_OTHER": 1.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}, {"fact": "mean_height_m", "op": "<=", "value": 3.5}]],
 "sources": [{"ref": "Ch1 A2.1 Table 1", "role": "PRIMARY"}, {"ref": "def mean height", "role": "DEFINITION"}],
 "interpretation_notes": "Garage door in such a carport must not swing beyond the boundary (supp. 4). Planning schemes commonly restrict front carports — check the planning track.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T1.FRONT_SMALL_GATEHOUSE", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — gatehouse <= 3 m high, roof <= 4 m2",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_STRUCTURE_OMP_TO_BOUNDARY", "operator": ">=", "unit": "m", "permits_btb": true,
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 0, "SECONDARY_FRONTAGE_ROAD": 0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0, "SECONDARY_FRONTAGE_OTHER": 1.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["GATEHOUSE"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 3.0}, {"fact": "roof_area_m2", "op": "<=", "value": 4}]],
 "sources": [{"ref": "Ch1 A2.1 Table 1", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T2.FRONT_POOL", "instrument_version": "QHC@2026-09-01",
 "topic": "POOL.SETBACK.FRONTAGE", "title": "Frontage setback — swimming pool <= 1.2 m high: 1.5 m from water's edge",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_POOL_WATER_TO_BOUNDARY", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 1.2},
                 {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"ref": "Ch1 A2.1 Table 2", "role": "PRIMARY", "quote": "If 1.2m or less in height and involving building work that is: a swimming pool. 1.5m 1.5m 1.5m 1.5m"}],
 "interpretation_notes": "Pool 'height' is the structure height (ground level to highest point, e.g. coping/wall). Over 1.2 m => Table 1 Class 1 row (supp. 1).",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T2.FRONT_COVERED_OUTDOOR_ROOM", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setback — covered outdoor room / balcony / stairs <= 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 1.5, "SECONDARY_FRONTAGE_ROAD": 0.5, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0.5, "SECONDARY_FRONTAGE_OTHER": 1.5}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["PATIO", "PERGOLA", "DECK", "VERANDAH"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}, {"fact": "is_roofed", "op": "IS_TRUE"}]],
 "sources": [{"ref": "Ch1 A2.1 Table 2", "role": "PRIMARY"}, {"ref": "def covered outdoor room", "role": "DEFINITION"}],
 "interpretation_notes": "Unroofed decks/pergolas >= 1 m are not a 'covered outdoor room' and are not otherwise listed => Table 1 Class 1 row (supp. 1). Supp. 2: if attached and the building's setback is less, the building's applies.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T2.FRONT_WEATHER_CONTROL_CARPORT", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE.EAVES", "title": "Frontage setback — weather control element for a carport <= 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m", "permits_btb": true,
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 0, "SECONDARY_FRONTAGE_ROAD": 0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0.5, "SECONDARY_FRONTAGE_OTHER": 1.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}]],
 "sources": [{"ref": "Ch1 A2.1 Table 2", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T2.FRONT_WEATHER_CONTROL", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE.EAVES", "title": "Frontage setback — weather control element (eaves, awning) or privacy screen <= 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 1.5, "SECONDARY_FRONTAGE_ROAD": 0.5, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0.5, "SECONDARY_FRONTAGE_OTHER": 1.5}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A", {"id": "CARPORT", "exclude": true}],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A2.1 Table 2", "role": "PRIMARY"}],
 "interpretation_notes": "Applies to the eaves/awnings of Class 1 and Class 10a buildings; carport roofs use the carport-specific row.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T3.COMMON_CLASS1", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR", "title": "Common boundary setbacks — Class 1 external walls (and Class 10a fallback)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {
     "SIDE": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "wall_height_m"}, 8.5]}, "then": 1.0},
                                     {"if": {"op": "<=", "args": [{"var": "lot_width_m"}, 12.5]}, "then": 2.0}], "else": 2.5},
     "REAR": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "wall_height_m"}, 4.5]}, "then": 3.0}], "else": 2.5}}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A_OTHER"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A3.1 Table 3", "role": "PRIMARY"}],
 "interpretation_notes": "Per part: wall height at the relevant point (or storey, supp. 4). Class 10a reach this row only via supp. 3 (exceeding the BTB row limits or not listed).",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T3.COMMON_CLASS10A_BTB", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Garage, carport, laundry or shed <= 4.5 m: BTB permitted up to 9 m combined length per common boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5},
                 {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 9.0, "notes": "combined length of garage/carport/laundry/shed along that common boundary"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch1 A3.1 Table 3", "role": "PRIMARY", "quote": "If 4.5m or less in height and involving building work that is: a garage, carport, laundry, or shed up to 9m total combined length along each common boundary. BTB permitted BTB permitted"}],
 "interpretation_notes": "Unlike MP 1.x A2(d), there is no mean-height test, no adjoining-window test, and the 9 m counts only these Class 10a types (not the house). Walls within 750 mm must be maintenance free (A6.1).",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T4.COMMON_POOL", "instrument_version": "QHC@2026-09-01",
 "topic": "POOL.SETBACK.SIDE_REAR", "title": "Common boundary setback — swimming pool <= 4.5 m: 1.5 m side and rear",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_POOL_WATER_TO_BOUNDARY", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch1 A3.1 Table 4", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T4.COMMON_COVERED_OUTDOOR_ROOM", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR", "title": "Common boundary setback — covered outdoor room / balcony <= 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"SIDE": 0.5, "REAR": 1.5}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["PATIO", "PERGOLA", "DECK", "VERANDAH"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}, {"fact": "is_roofed", "op": "IS_TRUE"}]],
 "sources": [{"ref": "Ch1 A3.1 Table 4", "role": "PRIMARY"}],
 "interpretation_notes": "Ch1 Table 4 lists 'covered outdoor room; or a balcony' (no stairs/ramps, unlike Ch2).",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T4.COMMON_WEATHER_CONTROL", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR.EAVES", "title": "Common boundary setback — weather control element or privacy screen <= 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"SIDE": 0.5, "REAR": 1.5}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A3.1 Table 4", "role": "PRIMARY"}],
 "interpretation_notes": "Supp. 1: where attached to a BTB part of a building => BTB; carport weather control elements <= 4.5 m => BTB (separate row). Encoded via RELAXES relationship from the Class 10a BTB rule.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.T24.POOL_SOLID_FENCE_BTB", "instrument_version": "QHC@2026-09-01",
 "topic": "POOL.SETBACK", "title": "Pool may be BTB where solid fence extends >= 1 m above pool deck between water and boundary",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "SUPPLEMENTARY_PROVISION",
 "measurement": "QHC_POOL_WATER_TO_BOUNDARY", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "solid_fence_above_pool_deck_m", "op": ">=", "value": 1.0}]],
 "sources": [{"ref": "Ch1 A2.1 Table 2", "role": "PRIMARY", "quote": "3. Where a solid fence extends at least 1m above the level of the swimming pool deck (between the water and the frontage), the minimum setback for a swimming pool is BTB."},
             {"ref": "Ch1 A3.1 Table 4", "role": "PRIMARY", "quote": "4. Where a solid fence extends at least 1m above the level of the swimming pool (between the water and the adjoining premises), the minimum setback for a swimming pool is BTB."}],
 "interpretation_notes": "Ch1 Table 4 wording says 'above the level of the swimming pool' (Ch2 says 'swimming pool deck'). Treated the same. Note no 1.8 m minimum fence height (contrast MP 1.x), but the fence itself is capped at 2 m by A1.1(4).",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.A4_1.SITE_COVER", "instrument_version": "QHC@2026-09-01",
 "topic": "SITE_COVER", "title": "Maximum site cover: 65% (lot <= 250 m2) / 60% (lot > 250 m2)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_SITE_COVER", "operator": "<=", "unit": "%",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "lot_area_m2"}, 250]}, "then": 65}], "else": 60},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"], "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"ref": "Ch1 A4.1", "role": "PRIMARY"}, {"ref": "def QHC site cover", "role": "DEFINITION"}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH1.A5.DECK_PRIVACY_SCREEN", "instrument_version": "QHC@2026-09-01",
 "topic": "PRIVACY", "title": "Deck/pergola/verandah/balcony > 1 m high within 2 m of common boundary: 1.5 m privacy screen",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "PRIVACY_SCREEN_HEIGHT_ABOVE_FLOOR", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["DECK", "PERGOLA", "VERANDAH", "PATIO"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "floor_height_above_ground_m", "op": ">", "value": 1.0},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch1 A5", "role": "PRIMARY"}],
 "interpretation_notes": "Triggered only where the deck is setback 2 m or less from that common boundary; the engine evaluates the trigger geometrically. Exempt where the adjoining premises is not residential in use.",
 "effective_from": "2026-09-01"}$r$);

-- --------------------------------------------------------------- QHC Chapter 2
SELECT define_rule($r${
 "rule_id": "QHC.CH2.A1_1.HEIGHT_CLASS1", "instrument_version": "QHC@2026-09-01",
 "topic": "HEIGHT.BUILDING", "title": "Class 1/2 maximum height 8.5 m (+1.5 m where slope > 15%)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_HEIGHT", "operator": "<=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "lot_slope_pct"}, 15]}, "then": 10.0}], "else": 8.5},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A1.1", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.A1_1.HEIGHT_CLASS10A", "instrument_version": "QHC@2026-09-01",
 "topic": "HEIGHT.CLASS_10A", "title": "Class 10a maximum height 4.5 m (+1.5 m where slope > 15%)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_HEIGHT", "operator": "<=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "lot_slope_pct"}, 15]}, "then": 6.0}], "else": 4.5},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_10A"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A1.1", "role": "PRIMARY", "quote": "2. Class 10a buildings have a maximum height of 4.5m. 3. Where the slope of a lot exceeds 15%, the heights in A1.1(1)-(2) are increased by 1.5m."}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.A1_1.HEIGHT_FENCES", "instrument_version": "QHC@2026-09-01",
 "topic": "HEIGHT.FENCE", "title": "Fence, privacy screen, retaining or free-standing wall (or combination) maximum 2 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_HEIGHT", "operator": "<=", "value": 2.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["FENCE", "RETAINING_WALL", "POOL_FENCE"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A1.1", "role": "PRIMARY"}, {"ref": "Ch2 A10", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "See QHC.CH1.A1_1.HEIGHT_FENCES regarding pool fences over 2 m.", "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T1.FRONT_CLASS1", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — Class 1 external walls (and Class 10a not otherwise listed); secondary road per Table A1",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {
     "PRIMARY_FRONTAGE": {"op": "case", "when": [
        {"if": {"op": "is_true", "args": [{"var": "primary_frontage_is_lane_or_parkway"}]}, "then": 2.0},
        {"if": {"op": "is_true", "args": [{"var": "adjoining_premises_setback_less_than_table"}]}, "then": 4.0}], "else": 5.0},
     "SECONDARY_FRONTAGE_ROAD": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "building_height_m"}, 4.5]},
            "then": {"op": "/", "args": [{"op": "-", "args": [{"var": "lot_width_m"}, 5.34]}, 3.11]}}],
           "else": {"op": "/", "args": [{"op": "-", "args": [{"var": "lot_width_m"}, 4]}, 3]}},
     "SECONDARY_FRONTAGE_LANE_PARKWAY": 1.0, "SECONDARY_FRONTAGE_OTHER": 3.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_FROM_FIGURE", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A_OTHER"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A2.1 Table 1", "role": "PRIMARY"}, {"ref": "Ch2 Table A1", "role": "FIGURE"}, {"ref": "def lot width", "role": "DEFINITION"}],
 "interpretation_notes": "Table A1 formulas are unbounded; the graph is drawn only for lot widths 10-24 m (setback 1.5-6.0 m). No clamp is applied; results outside 1.5-6.0 m are flagged by the engine for review. 'buildings <= 4.5m high' uses building height.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T1.FRONT_GARAGE", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — garage (and garage door)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 5.6, "SECONDARY_FRONTAGE_ROAD": 5.6, "SECONDARY_FRONTAGE_LANE_PARKWAY": 1.0, "SECONDARY_FRONTAGE_OTHER": 3.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["GARAGE"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A2.1 Table 1", "role": "PRIMARY", "quote": "Building work including: a garage; or a carport. Building work including: a garage door. 5.6m 5.6m 1m 3m"}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T1.FRONT_CARPORT", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — carport over 4.5 m high or mean height over 3.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_STRUCTURE_OMP_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 5.6, "SECONDARY_FRONTAGE_ROAD": 5.6, "SECONDARY_FRONTAGE_LANE_PARKWAY": 1.0, "SECONDARY_FRONTAGE_OTHER": 3.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": ">", "value": 4.5}],
                [{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "mean_height_m", "op": ">", "value": 3.5}]],
 "sources": [{"ref": "Ch2 A2.1 Table 1", "role": "PRIMARY"}],
 "interpretation_notes": "See QHC.CH1.T1.FRONT_CARPORT on carport measuring point.", "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T1.FRONT_SHED_LAUNDRY", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — detached shed or laundry",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 6.0, "SECONDARY_FRONTAGE_ROAD": 6.0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 1.0, "SECONDARY_FRONTAGE_OTHER": 3.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["SHED", "DETACHED_LAUNDRY"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A2.1 Table 1", "role": "PRIMARY", "quote": "Building work including a detached: laundry; or shed. 6m 6m 1m 3m"}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T1.FRONT_SMALL_CARPORT", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — carport <= 4.5 m high, mean height <= 3.5 m (BTB except 'other' frontage)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_STRUCTURE_OMP_TO_BOUNDARY", "operator": ">=", "unit": "m", "permits_btb": true,
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 0, "SECONDARY_FRONTAGE_ROAD": 0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0, "SECONDARY_FRONTAGE_OTHER": 1.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}, {"fact": "mean_height_m", "op": "<=", "value": 3.5}]],
 "sources": [{"ref": "Ch2 A2.1 Table 1", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T1.FRONT_SMALL_GATEHOUSE", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setbacks — gatehouse <= 3 m high, roof <= 4 m2",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_STRUCTURE_OMP_TO_BOUNDARY", "operator": ">=", "unit": "m", "permits_btb": true,
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 0, "SECONDARY_FRONTAGE_ROAD": 0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0, "SECONDARY_FRONTAGE_OTHER": 1.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["GATEHOUSE"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 3.0}, {"fact": "roof_area_m2", "op": "<=", "value": 4}]],
 "sources": [{"ref": "Ch2 A2.1 Table 1", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T2.FRONT_POOL", "instrument_version": "QHC@2026-09-01",
 "topic": "POOL.SETBACK.FRONTAGE", "title": "Frontage setback — swimming pool <= 1.2 m high: 1.5 m from water's edge",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_POOL_WATER_TO_BOUNDARY", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 1.2},
                 {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"ref": "Ch2 A2.1 Table 2", "role": "PRIMARY", "quote": "If 1.2m or less in height and involving building work that is: a swimming pool. 1.5m 1.5m 1.5m 1.5m"}],
 "interpretation_notes": "Over 1.2 m => Table 1 Class 1 row (supp. 1), i.e. 5 m primary frontage.", "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T2.FRONT_COVERED_OUTDOOR_ROOM", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE", "title": "Frontage setback — covered outdoor room / balcony / stairs <= 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 3.0, "SECONDARY_FRONTAGE_ROAD": 2.5, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0.5, "SECONDARY_FRONTAGE_OTHER": 1.5}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["PATIO", "PERGOLA", "DECK", "VERANDAH"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}, {"fact": "is_roofed", "op": "IS_TRUE"}]],
 "sources": [{"ref": "Ch2 A2.1 Table 2", "role": "PRIMARY"}, {"ref": "def covered outdoor room", "role": "DEFINITION"}],
 "interpretation_notes": "Unroofed decks/pergolas >= 1 m fall to the Class 1 row (supp. 1).", "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T2.FRONT_WEATHER_CONTROL_CARPORT", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE.EAVES", "title": "Frontage setback — weather control element for a carport <= 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m", "permits_btb": true,
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"PRIMARY_FRONTAGE": 0, "SECONDARY_FRONTAGE_ROAD": 0, "SECONDARY_FRONTAGE_LANE_PARKWAY": 0.5, "SECONDARY_FRONTAGE_OTHER": 1.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}]],
 "sources": [{"ref": "Ch2 A2.1 Table 2", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T2.FRONT_WEATHER_CONTROL", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FRONTAGE.EAVES", "title": "Frontage setback — weather control element or privacy screen <= 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {
     "PRIMARY_FRONTAGE": 3.0,
     "SECONDARY_FRONTAGE_ROAD": {"op": "-", "args": [{"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "building_height_m"}, 4.5]},
            "then": {"op": "/", "args": [{"op": "-", "args": [{"var": "lot_width_m"}, 5.34]}, 3.11]}}],
           "else": {"op": "/", "args": [{"op": "-", "args": [{"var": "lot_width_m"}, 4]}, 3]}}, 0.5]},
     "SECONDARY_FRONTAGE_LANE_PARKWAY": 0.5, "SECONDARY_FRONTAGE_OTHER": 1.5}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_FROM_FIGURE", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A", {"id": "CARPORT", "exclude": true}],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A2.1 Table 2", "role": "PRIMARY", "quote": "If 8.5m or less in height and involving building work that is: a weather control element; or a privacy screen. 3m | 0.5m less than the setback for an external wall under Table A1 | 0.5m | 1.5m"}, {"ref": "Ch2 Table A1", "role": "FIGURE"}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T3.COMMON_CLASS1", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR", "title": "Common boundary setbacks — Class 1 external walls (and Class 10a fallback)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {
     "SIDE": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "wall_height_m"}, 8.5]}, "then": 1.5}], "else": 2.5},
     "REAR": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "wall_height_m"}, 4.5]}, "then": 4.0}], "else": 3.0}}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A_OTHER"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A3.1 Table 3", "role": "PRIMARY"}],
 "interpretation_notes": "Per part. Upper storey may cantilever 1 m over a 4 m rear setback (supp. 1).", "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T3.COMMON_CLASS10A_BTB", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Garage, carport, laundry or shed <= 4.5 m: BTB permitted up to 9 m combined length per common boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5},
                 {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 9.0}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch2 A3.1 Table 3", "role": "PRIMARY", "quote": "If 4.5m or less in height and involving building work that is: a garage, carport, laundry, or shed up to 9m total combined length along each common boundary. BTB permitted BTB permitted"}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T4.COMMON_POOL", "instrument_version": "QHC@2026-09-01",
 "topic": "POOL.SETBACK.SIDE_REAR", "title": "Common boundary setback — swimming pool <= 4.5 m: 1.5 m side and rear",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_POOL_WATER_TO_BOUNDARY", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch2 A3.1 Table 4", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T4.COMMON_COVERED_OUTDOOR_ROOM", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR", "title": "Common boundary setback — covered outdoor room / balcony / stairs <= 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"SIDE": 1.0, "REAR": 2.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["PATIO", "PERGOLA", "DECK", "VERANDAH"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "structure_height_m", "op": "<=", "value": 4.5}, {"fact": "is_roofed", "op": "IS_TRUE"}]],
 "sources": [{"ref": "Ch2 A3.1 Table 4", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T4.COMMON_WEATHER_CONTROL", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR.EAVES", "title": "Common boundary setback — weather control element or privacy screen <= 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE_ROW",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "unit": "m",
 "value": {"op": "switch", "on": {"var": "boundary_type"}, "cases": {"SIDE": 0.5, "REAR": 2.0}, "default": null},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A3.1 Table 4", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T24.POOL_SOLID_FENCE_BTB", "instrument_version": "QHC@2026-09-01",
 "topic": "POOL.SETBACK", "title": "Pool may be BTB where solid fence extends >= 1 m above pool deck between water and boundary",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "SUPPLEMENTARY_PROVISION",
 "measurement": "QHC_POOL_WATER_TO_BOUNDARY", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "solid_fence_above_pool_deck_m", "op": ">=", "value": 1.0}]],
 "sources": [{"ref": "Ch2 A2.1 Table 2", "role": "PRIMARY"}, {"ref": "Ch2 A3.1 Table 4", "role": "PRIMARY"}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.A4_1.SITE_COVER", "instrument_version": "QHC@2026-09-01",
 "topic": "SITE_COVER", "title": "Maximum site cover 50%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_SITE_COVER", "operator": "<=", "value": 50, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"], "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"ref": "Ch2 A4.1", "role": "PRIMARY"}, {"ref": "def QHC site cover", "role": "DEFINITION"}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.A5.DECK_PRIVACY_SCREEN", "instrument_version": "QHC@2026-09-01",
 "topic": "PRIVACY", "title": "Deck/pergola/verandah/balcony > 1 m high within 2 m of common boundary: 1.5 m privacy screen",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "PRIVACY_SCREEN_HEIGHT_ABOVE_FLOOR", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["DECK", "PERGOLA", "VERANDAH", "PATIO"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "floor_height_above_ground_m", "op": ">", "value": 1.0},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch2 A5.1", "role": "PRIMARY"}], "effective_from": "2026-09-01"}$r$);


SELECT define_rule($r${
 "rule_id": "QHC.A10.FENCE_BTB", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.FENCE", "title": "Fence, privacy fence/screen, retaining or free-standing wall <= 2 m may be built to boundary (frontage and common boundaries)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_STRUCTURE_OMP_TO_BOUNDARY", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["FENCE", "RETAINING_WALL", "POOL_FENCE"],
 "conditions": [[{"fact": "structure_height_m", "op": "<=", "value": 2.0}]],
 "sources": [{"ref": "Ch1 A10", "role": "PRIMARY"}, {"ref": "Ch2 A10", "role": "PRIMARY"}],
 "interpretation_notes": "Over 2 m: fails A1.1(4) height and falls to the Class 1 setback rows (Table 2/4 supp. prov.). Pool barrier rules (MP 3.4) apply in addition.",
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.A6_1.WALL_MAINTENANCE", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR.MAINTENANCE", "title": "Walls within 750 mm of a common boundary must be maintenance free",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "QHC_WALL_TO_BOUNDARY", "operator": ">=", "value": 0.75, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "wall_is_maintenance_free", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch1 A6.1", "role": "PRIMARY"}, {"ref": "Ch2 A6.1", "role": "PRIMARY"}],
 "effective_from": "2026-09-01"}$r$);

-- -----------------------------------------------------------------------------
-- Pool safety (Building Act ch 8; QDC MP 3.4 = pool safety standard)
-- -----------------------------------------------------------------------------
SELECT define_rule($r${
 "rule_id": "BA.S231B.REGULATED_POOL", "instrument_version": "QLD_BUILDING_ACT_1975@2026-02-01",
 "topic": "POOL.APPLICABILITY", "title": "A swimming pool on regulated land is a regulated pool (barrier rules apply)",
 "role": "DEFINITION_RULE", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "DEFINITION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "conditions": [[{"fact": "land_is_regulated_land", "op": "IS_TRUE"}, {"fact": "pool_capable_depth_m", "op": ">=", "value": 0.3}]],
 "sources": [{"ref": "s 231B", "role": "PRIMARY"}, {"ref": "sch 2 regulated land", "role": "DEFINITION"}],
 "interpretation_notes": "Depth >= 300 mm comes from the 'swimming pool' definition (Building Act sch 2). Includes spas and portable pools capable of >= 300 mm; excludes portable wading pools.",
 "effective_from": "2026-02-01"}$r$);

SELECT define_rule($r${
 "rule_id": "MP34.P1.BARRIER_REQUIRED", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL.BARRIER.PRESENCE", "title": "Regulated pool must have a continuous barrier restricting young children's access",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "PERFORMANCE_CRITERIA",
 "measurement": "POOL_BARRIER_CONTINUITY", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL"],
 "sources": [{"ref": "P1", "role": "PRIMARY"}, {"ref": "s 232(1)", "role": "LEGAL_BASIS", "iv": "QLD_BUILDING_ACT_1975@2026-02-01"}],
 "interpretation_notes": "Continuity from plan geometry can be screened (closed ring around pool area) but final compliance needs a pool safety certificate (Building Act s234).",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r${
 "rule_id": "MP34.FIG1.BARRIER_MIN_HEIGHT", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL.BARRIER.HEIGHT", "title": "Pool fence minimum height 1200 mm, measured on the NCZ side",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "FIGURE",
 "measurement": "POOL_BARRIER_HEIGHT", "operator": ">=", "value": 1200, "unit": "mm",
 "on_noncompliance": "FAIL", "verification": "VERIFIED_FROM_FIGURE", "automatable": true,
 "subjects": ["POOL_FENCE", "POOL_GATE"],
 "sources": [{"ref": "Figure 1", "role": "PRIMARY", "quote": "1200mm min fence height measured on side with NCZ"},
             {"ref": "Sch 1 item 1", "role": "SUPPLEMENTARY"}, {"ref": "Sch 1 items 6-7", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "The 1200 mm minimum originates in AS 1926.1-2007 (not held); MP 3.4 states it in Figures 1-2 and sch 1 item 7.",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r${
 "rule_id": "MP34.S1_6.NCZ_INSIDE_NEEDS_1800", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL.BARRIER.HEIGHT", "title": "If the NCZ is on the inside (pool side), the fence must be at least 1800 mm",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "measurement": "POOL_BARRIER_HEIGHT", "operator": ">=", "value": 1800, "unit": "mm",
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL_FENCE"],
 "conditions": [[{"fact": "ncz_side", "op": "=", "value": "INSIDE"}, {"fact": "ncz_required", "op": "IS_TRUE"}]],
 "sources": [{"ref": "Sch 1 items 6-7", "role": "PRIMARY"}],
 "interpretation_notes": "Applies equally to boundary fences forming part of the barrier (item 7: boundary fence 1200-1800 mm only with NCZ outside, i.e. on the neighbour's side — usually requires the neighbour's side to be kept clear).",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r${
 "rule_id": "MP34.S1_12.NO_NCZ_TALL_FENCE", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL.BARRIER.NCZ", "title": "NCZ and clear areas not required for fence >= 2400 mm (or >= 1800 mm with cranked top)",
 "role": "EXEMPTION", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL_FENCE"],
 "conditions": [[{"fact": "barrier_height_mm", "op": ">=", "value": 2400}],
                [{"fact": "barrier_height_mm", "op": ">=", "value": 1800}, {"fact": "barrier_has_cranked_top", "op": "IS_TRUE"}]],
 "sources": [{"ref": "Sch 1 item 12", "role": "PRIMARY"}],
 "interpretation_notes": "Also requires compliance with AS 1926.1 cl 2.3.2 (not held). A 2.4 m fence exceeds the 2 m QHC / MP 1.x fence limits — building track consequence.",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r${
 "rule_id": "MP34.S1_15.GATE_OPENS_AWAY", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL.GATE", "title": "Pool gates must not open towards the pool area",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "measurement": "POOL_GATE_OPENS_AWAY", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_GATE"],
 "sources": [{"ref": "Sch 1 item 15", "role": "PRIMARY"}], "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r${
 "rule_id": "MP34.P1d.GATE_SELF_CLOSING", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL.GATE", "title": "Gates self-closing and self-latching, latch not readily operated by young children",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "PERFORMANCE_CRITERIA",
 "measurement": "POOL_GATE_SELF_CLOSING_LATCHING", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_GATE"],
 "sources": [{"ref": "P1", "role": "PRIMARY", "quote": "(d) has any gates fitted with latching devices not readily operated by young children, and constructed to automatically close and latch"}],
 "interpretation_notes": "Numeric latch height/shielding requirements are in AS 1926.1-2007 (not held) — see open_issues.",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r${
 "rule_id": "MP34.P1e.NO_BUILDING_DOORS", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL.BARRIER.LOCATION", "title": "Outdoor pool barrier must not incorporate doors to or from a building",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "PERFORMANCE_CRITERIA",
 "measurement": "POOL_BARRIER_HAS_BUILDING_DOOR", "operator": "IS_FALSE", "value": false,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_BARRIER"],
 "conditions": [[{"fact": "pool_is_indoor", "op": "IS_FALSE"}]],
 "sources": [{"ref": "P1", "role": "PRIMARY"}, {"ref": "Sch 1 items 28-30", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "Item 28 permits direct access from a patio/deck/verandah with at least one permanently open side.",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r${
 "rule_id": "BA.S234.CERTIFICATE_BEFORE_FILLING", "instrument_version": "QLD_BUILDING_ACT_1975@2026-02-01",
 "topic": "POOL.PROCESS", "title": "Certifier's certificate (complying pool) before filling to 300 mm",
 "role": "TRIGGER", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SECTION",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["POOL"],
 "sources": [{"ref": "s 234(2)", "role": "PRIMARY"}], "effective_from": "2026-02-01"}$r$);

-- -----------------------------------------------------------------------------
-- Building Regulation triggers (approval pathway, not siting values)
-- -----------------------------------------------------------------------------
SELECT define_rule($r${
 "rule_id": "BR.SCH1_S13.SMALL_CLASS10_ACCEPTED", "instrument_version": "QLD_BUILDING_REG_2021@2026-08-14",
 "topic": "PATHWAY.ACCEPTED_BUILDING_WORK", "title": "Small Class 10 (<= 10 m2, <= 2.4 m high, mean <= 2.1 m, sides <= 5 m) is accepted building work — but must still comply with siting provisions",
 "role": "TRIGGER", "regime": "BUILDING", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_10A", "CLASS_10B", "OUTDOOR_STRUCTURE", {"id": "POOL", "exclude": true}, {"id": "POOL_BARRIER", "exclude": true}],
 "conditions": [[{"fact": "plan_area_m2", "op": "<=", "value": 10}, {"fact": "structure_height_m", "op": "<=", "value": 2.4},
                 {"fact": "mean_height_m", "op": "<=", "value": 2.1}, {"fact": "longest_side_m", "op": "<=", "value": 5},
                 {"fact": "in_wind_region_c", "op": "IS_FALSE"}]],
 "sources": [{"ref": "sch 1 s 13", "role": "PRIMARY"}, {"ref": "s 4", "role": "LEGAL_BASIS",
              "quote": "(2) The building work mentioned in schedule 1 must comply with the relevant provisions within the meaning of section 21(5) of the Act."},
             {"ref": "s 21(5)", "role": "LEGAL_BASIS", "iv": "QLD_BUILDING_ACT_1975@2026-02-01"}],
 "interpretation_notes": "Excludes decks that are roofed or > 1 m high, rainwater tanks for new buildings, regulated pools and their fences. Accepted = no building approval, NOT exempt from QDC/QHC or alternative-provision siting. The engine still runs the building track.",
 "effective_from": "2026-08-14"}$r$);

SELECT define_rule($r${
 "rule_id": "PR.SCH9_T3.SITING_REFERRAL", "instrument_version": "QLD_PLANNING_REG_2017@2026-09-11",
 "topic": "PATHWAY.REFERRAL", "title": "Non-compliance with a QDC 1.1/1.2 acceptable solution (or an alternative provision's quantifiable standard) => referral to local government",
 "role": "TRIGGER", "regime": "BUILDING", "enforceability": "MANDATORY", "provision_kind": "TABLE",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"],
 "sources": [{"ref": "sch 9 pt 3 div 2 table 3", "role": "PRIMARY"}], "effective_from": "2026-09-11"}$r$);

-- -----------------------------------------------------------------------------
-- QDC MP 1.4 — building near relevant infrastructure
-- -----------------------------------------------------------------------------
SELECT define_rule($r${
 "rule_id": "MP14.S4_4.OUT_OF_SCOPE_3M", "instrument_version": "QDC_MP_1_4@2014-12-15",
 "topic": "INFRASTRUCTURE.APPLICATION", "title": "MP 1.4 does not apply to Class 1/10 work >= 3 m from the infrastructure centreline (with zone-of-influence test)",
 "role": "EXEMPTION", "regime": "INFRASTRUCTURE", "enforceability": "MANDATORY", "provision_kind": "APPLICATION",
 "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["CLASS_1", "CLASS_10A", "CLASS_10B", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "distance_to_infrastructure_centreline_m", "op": ">=", "value": 3.0}]],
 "sources": [{"ref": "s 4(4)", "role": "PRIMARY"}],
 "interpretation_notes": "Also requires invert >= 300 mm above the zone-of-influence intersection (geotechnical — certifier) and pile/anchor distances. Distance test alone is a screen, not a determination.",
 "effective_from": "2014-12-15"}$r$);

SELECT define_rule($r${
 "rule_id": "MP14.A2_1.FOOTING_1_2M", "instrument_version": "QDC_MP_1_4@2014-12-15",
 "topic": "INFRASTRUCTURE.SEPARATION", "title": "Wall/footing/pile/pier/floor at least 1.2 m from infrastructure centreline (not light-weight Class 10)",
 "role": "REQUIREMENT", "regime": "INFRASTRUCTURE", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "INFRA_FOOTING_DISTANCE", "operator": ">=", "value": 1.2, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_SERVICE_PROVIDER", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A", "CLASS_10B", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "infrastructure_on_lot", "op": "IS_TRUE"}, {"fact": "is_light_weight_class_10", "op": "IS_FALSE"}, {"fact": "infrastructure_dn_mm", "op": "<=", "value": 225}]],
 "sources": [{"ref": "A2.1(2)", "role": "PRIMARY"}, {"ref": "Referral", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "A2.1 applies to sewer/combined sanitary drain/water main DN <= 225 or stormwater DN <= 375 (stormwater threshold not encoded in this condition — engine must branch on infrastructure type). Larger mains: no acceptable solution => referral.",
 "effective_from": "2014-12-15"}$r$);

SELECT define_rule($r${
 "rule_id": "MP14.A2_1.COVER_CLEAR_ZONE", "instrument_version": "QDC_MP_1_4@2014-12-15",
 "topic": "INFRASTRUCTURE.SEPARATION", "title": "Nothing (incl. overhangs) within 1.5 m radius of a maintenance cover",
 "role": "REQUIREMENT", "regime": "INFRASTRUCTURE", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "INFRA_MAINTENANCE_COVER_DISTANCE", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_SERVICE_PROVIDER", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["ANY"],
 "conditions": [[{"fact": "infrastructure_on_lot", "op": "IS_TRUE"}]],
 "sources": [{"ref": "A2.1(2)", "role": "PRIMARY"}, {"ref": "A2.2", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "Applies to light-weight Class 10 too (A2.2(2)(b) requires compliance with A2.1(2)(c)). Pools: a pool shell is a structure; most service providers treat pools as not light-weight. Cover must also not be covered by fill or subject to ponding.",
 "effective_from": "2014-12-15"}$r$);

SELECT define_rule($r${
 "rule_id": "MP14.A2_2.LIGHTWEIGHT_MAX_10M_OVER", "instrument_version": "QDC_MP_1_4@2014-12-15",
 "topic": "INFRASTRUCTURE.SEPARATION", "title": "Light-weight Class 10 may extend over the infrastructure for not more than 10 m",
 "role": "REQUIREMENT", "regime": "INFRASTRUCTURE", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "INFRA_LENGTH_OVER_CENTRELINE", "operator": "<=", "value": 10, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_SERVICE_PROVIDER", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_10A", "OUTDOOR_STRUCTURE", "CLASS_10B"],
 "conditions": [[{"fact": "infrastructure_on_lot", "op": "IS_TRUE"}, {"fact": "is_light_weight_class_10", "op": "IS_TRUE"}, {"fact": "infrastructure_dn_mm", "op": "<=", "value": 225}]],
 "sources": [{"ref": "A2.2", "role": "PRIMARY"}],
 "interpretation_notes": "Water mains are not covered by A2.2 (sewer/combined sanitary drain DN<=225 or stormwater DN<=375 only).",
 "effective_from": "2014-12-15"}$r$);


SELECT define_rule($r${
 "rule_id": "QHC.CH1.T4.WCE_ATTACHED_TO_BTB", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR.EAVES", "title": "Weather control element attached to a BTB part of a building: BTB",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "SUPPLEMENTARY_PROVISION",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "weather_control_attached_to_btb_part", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch1 A3.1 Table 4", "role": "PRIMARY", "quote": "1. Where a weather control element is attached to a part of a building that is BTB, the minimum setback is BTB."}],
 "effective_from": "2026-09-01"}$r$);

SELECT define_rule($r${
 "rule_id": "QHC.CH2.T4.WCE_ATTACHED_TO_BTB", "instrument_version": "QHC@2026-09-01",
 "topic": "SETBACK.SIDE_REAR.EAVES", "title": "Weather control element attached to a BTB part of a building: BTB",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "SUPPLEMENTARY_PROVISION",
 "measurement": "QHC_BUILDING_PART_TO_BOUNDARY", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "weather_control_attached_to_btb_part", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"ref": "Ch2 A3.1 Table 4", "role": "PRIMARY", "quote": "1. Where a weather control element is attached to a part of a building that is BTB, the minimum setback is BTB."}],
 "effective_from": "2026-09-01"}$r$);

-- -----------------------------------------------------------------------------
-- Boundary applicability of legacy QDC clauses ("road setback" vs "side and rear")
-- -----------------------------------------------------------------------------
DO $$
DECLARE p text; r text;
  road text[] := ARRAY['PRIMARY_FRONTAGE','SECONDARY_FRONTAGE_ROAD'];
  sr   text[] := ARRAY['SIDE','REAR'];
BEGIN
  FOREACH p IN ARRAY ARRAY['QDC11','QDC12'] LOOP
    FOREACH r IN ARRAY ARRAY['A2a.SIDE_REAR_CLEARANCE','A2b.NARROW_LOT_CLEARANCE','A2a.POOL_SIDE_REAR',
                             'A2d.CLASS10A_WITHIN_CLEARANCE','A2e.POOL_WITHIN_CLEARANCE','A6.WALL_MAINTENANCE'] LOOP
      PERFORM restrict_boundary(p||'.'||r||'@2010-03-26', sr);
    END LOOP;
    PERFORM restrict_boundary(p||'.A1d.POOL_ROAD_SETBACK@2010-03-26', road);
  END LOOP;
  FOREACH r IN ARRAY ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1a.ROAD_SETBACK_NEIGHBOURS','QDC12.A1c.OPEN_CARPORT',
                           'QDC11.A1a.FRONTAGE_NEIGHBOURS','QDC11.A1b.GARAGE_OPENING_WIDTH'] LOOP
    PERFORM restrict_boundary(r||'@2010-03-26', road);
  END LOOP;
  PERFORM restrict_boundary('QDC12.A1b.CORNER_NOMINATED_FRONTAGE@2010-03-26', road);
END $$;

-- Rows whose value is a switch on boundary_type apply only to the boundaries they list.
DO $$
DECLARE r record;
BEGIN
  FOR r IN SELECT rv.rule_version_id, array_agg(k ORDER BY k) AS types
             FROM rule_versions rv, jsonb_object_keys(rv.value_expr->'cases') k
            WHERE rv.value_expr->>'op' = 'switch' AND rv.value_expr->'on'->>'var' = 'boundary_type'
              AND NOT EXISTS (SELECT 1 FROM rule_conditions c WHERE c.rule_version_id = rv.rule_version_id AND c.fact_id = 'boundary_type')
            GROUP BY rv.rule_version_id
  LOOP
    PERFORM restrict_boundary(r.rule_version_id, r.types);
  END LOOP;
END $$;

-- -----------------------------------------------------------------------------
-- Relationships between state rules
-- -----------------------------------------------------------------------------
DO $$
DECLARE p text;
BEGIN
  FOREACH p IN ARRAY ARRAY['QDC11','QDC12'] LOOP
    PERFORM relate(p||'.A2c.EXEMPT_FENCES_WALLS@2010-03-26', p||'.A2a.SIDE_REAR_CLEARANCE@2010-03-26', 'EXEMPTS',
                   CASE p WHEN 'QDC11' THEN 'QDC_MP_1_1@2010-03-26' ELSE 'QDC_MP_1_2@2010-03-26' END, 'A2(c)', 'VERIFIED_VERBATIM');
    PERFORM relate(p||'.A2c.EXEMPT_RAINWATER_TANK@2010-03-26', p||'.A2a.SIDE_REAR_CLEARANCE@2010-03-26', 'EXEMPTS',
                   CASE p WHEN 'QDC11' THEN 'QDC_MP_1_1@2010-03-26' ELSE 'QDC_MP_1_2@2010-03-26' END, 'A2(c)', 'VERIFIED_VERBATIM');
    PERFORM relate(p||'.A2c.EXEMPT_ORNAMENTAL_PERGOLA@2010-03-26', p||'.A2a.SIDE_REAR_CLEARANCE@2010-03-26', 'EXEMPTS',
                   CASE p WHEN 'QDC11' THEN 'QDC_MP_1_1@2010-03-26' ELSE 'QDC_MP_1_2@2010-03-26' END, 'A2(c)', 'VERIFIED_VERBATIM');
    PERFORM relate(p||'.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26', p||'.A2a.SIDE_REAR_CLEARANCE@2010-03-26', 'RELAXES',
                   CASE p WHEN 'QDC11' THEN 'QDC_MP_1_1@2010-03-26' ELSE 'QDC_MP_1_2@2010-03-26' END, 'A2(d)', 'VERIFIED_VERBATIM');
    PERFORM relate(p||'.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26', p||'.A2b.NARROW_LOT_CLEARANCE@2010-03-26', 'RELAXES',
                   CASE p WHEN 'QDC11' THEN 'QDC_MP_1_1@2010-03-26' ELSE 'QDC_MP_1_2@2010-03-26' END, 'A2(d)', 'VERIFIED_VERBATIM');
    PERFORM relate(p||'.A2e.POOL_WITHIN_CLEARANCE@2010-03-26', p||'.A2a.POOL_SIDE_REAR@2010-03-26', 'RELAXES',
                   CASE p WHEN 'QDC11' THEN 'QDC_MP_1_1@2010-03-26' ELSE 'QDC_MP_1_2@2010-03-26' END, 'A2(e)', 'VERIFIED_VERBATIM');
    PERFORM relate(p||'.A1d.POOL_ROAD_WALL_EXEMPT@2010-03-26', p||'.A1d.POOL_ROAD_SETBACK@2010-03-26', 'EXEMPTS',
                   CASE p WHEN 'QDC11' THEN 'QDC_MP_1_1@2010-03-26' ELSE 'QDC_MP_1_2@2010-03-26' END, 'A1(d)', 'VERIFIED_VERBATIM');
  END LOOP;

  PERFORM relate('QDC12.A1d.EXEMPT_FENCES_ROAD@2010-03-26', 'QDC12.A1a.ROAD_SETBACK@2010-03-26', 'EXEMPTS', 'QDC_MP_1_2@2010-03-26', 'A1(d)', 'VERIFIED_VERBATIM');
  PERFORM relate('QDC12.A1d.EXEMPT_GATEHOUSE_ROAD@2010-03-26', 'QDC12.A1a.ROAD_SETBACK@2010-03-26', 'EXEMPTS', 'QDC_MP_1_2@2010-03-26', 'A1(d)', 'VERIFIED_VERBATIM');
  PERFORM relate('QDC12.A1a.ROAD_SETBACK_NEIGHBOURS@2010-03-26', 'QDC12.A1a.ROAD_SETBACK@2010-03-26', 'ALTERNATIVE_TO', 'QDC_MP_1_2@2010-03-26', 'A1(a)', 'VERIFIED_VERBATIM', 'A1(a)(i) "or" (ii)');
  PERFORM relate('QDC12.A1b.CORNER_NOMINATED_FRONTAGE@2010-03-26', 'QDC12.A1a.ROAD_SETBACK@2010-03-26', 'ALTERNATIVE_TO', 'QDC_MP_1_2@2010-03-26', 'A1(b)', 'VERIFIED_VERBATIM', 'Only for the nominated frontage; other frontage keeps 6 m.');
  PERFORM relate('QDC12.A1b.CORNER_TRUNCATION_9X9@2010-03-26', 'QDC12.A1b.CORNER_NOMINATED_FRONTAGE@2010-03-26', 'CONDITIONAL_ON', 'QDC_MP_1_2@2010-03-26', 'A1(b)', 'VERIFIED_VERBATIM', 'Truncation applies only if the Table A1 concession is used.');
  PERFORM relate('QDC12.A1c.OPEN_CARPORT@2010-03-26', 'QDC12.A1a.ROAD_SETBACK@2010-03-26', 'RELAXES', 'QDC_MP_1_2@2010-03-26', 'A1(c)', 'VERIFIED_VERBATIM');
  PERFORM relate('QDC12.A1d.POOL_ROAD_SETBACK@2010-03-26', 'QDC12.A1a.ROAD_SETBACK@2010-03-26', 'FALLS_BACK_TO', 'QDC_MP_1_2@2010-03-26', 'A1(d)', 'VERIFIED_VERBATIM', 'Pool with coping > 1.2 m falls back to A1(a).');

  PERFORM relate('QDC11.A1d.EXEMPT_FENCES_ROAD@2010-03-26', 'QDC11.A1a.FRONTAGE_SETBACK@2010-03-26', 'EXEMPTS', 'QDC_MP_1_1@2010-03-26', 'A1(d)', 'VERIFIED_VERBATIM');
  PERFORM relate('QDC11.A1d.EXEMPT_GATEHOUSE_ROAD@2010-03-26', 'QDC11.A1a.FRONTAGE_SETBACK@2010-03-26', 'EXEMPTS', 'QDC_MP_1_1@2010-03-26', 'A1(d)', 'VERIFIED_VERBATIM');
  PERFORM relate('QDC11.A1a.FRONTAGE_NEIGHBOURS@2010-03-26', 'QDC11.A1a.FRONTAGE_SETBACK@2010-03-26', 'ALTERNATIVE_TO', 'QDC_MP_1_1@2010-03-26', 'A1(a) Table A1', 'VERIFIED_VERBATIM');
  PERFORM relate('QDC11.A1d.POOL_ROAD_SETBACK@2010-03-26', 'QDC11.A1a.FRONTAGE_SETBACK@2010-03-26', 'FALLS_BACK_TO', 'QDC_MP_1_1@2010-03-26', 'A1(d)', 'VERIFIED_VERBATIM');

  -- QHC: listed rows fall back to the Class 1 rows when limits are exceeded / not listed
  FOREACH p IN ARRAY ARRAY['CH1','CH2'] LOOP
    PERFORM relate('QHC.'||p||'.T1.FRONT_SMALL_CARPORT@2026-09-01', 'QHC.'||p||'.T1.FRONT_CARPORT@2026-09-01', 'FALLS_BACK_TO', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A2.1 Table 1', 'VERIFIED_VERBATIM');
    PERFORM relate('QHC.'||p||'.T1.FRONT_SMALL_GATEHOUSE@2026-09-01', 'QHC.'||p||'.T1.FRONT_CLASS1@2026-09-01', 'FALLS_BACK_TO', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A2.1 Table 1', 'VERIFIED_VERBATIM', 'Supp. prov. 3');
    PERFORM relate('QHC.'||p||'.T2.FRONT_POOL@2026-09-01', 'QHC.'||p||'.T1.FRONT_CLASS1@2026-09-01', 'FALLS_BACK_TO', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A2.1 Table 2', 'VERIFIED_VERBATIM', 'Table 2 supp. prov. 1');
    PERFORM relate('QHC.'||p||'.T2.FRONT_COVERED_OUTDOOR_ROOM@2026-09-01', 'QHC.'||p||'.T1.FRONT_CLASS1@2026-09-01', 'FALLS_BACK_TO', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A2.1 Table 2', 'VERIFIED_VERBATIM', 'Table 2 supp. prov. 1');
    PERFORM relate('QHC.'||p||'.T3.COMMON_CLASS10A_BTB@2026-09-01', 'QHC.'||p||'.T3.COMMON_CLASS1@2026-09-01', 'FALLS_BACK_TO', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A3.1 Table 3', 'VERIFIED_VERBATIM', 'Table 3 supp. prov. 3');
    PERFORM relate('QHC.'||p||'.T4.COMMON_POOL@2026-09-01', 'QHC.'||p||'.T3.COMMON_CLASS1@2026-09-01', 'FALLS_BACK_TO', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A3.1 Table 4', 'VERIFIED_VERBATIM', 'Table 4 supp. prov. 2');
    PERFORM relate('QHC.'||p||'.T4.COMMON_COVERED_OUTDOOR_ROOM@2026-09-01', 'QHC.'||p||'.T3.COMMON_CLASS1@2026-09-01', 'FALLS_BACK_TO', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A3.1 Table 4', 'VERIFIED_VERBATIM', 'Table 4 supp. prov. 2');
    PERFORM relate('QHC.'||p||'.T24.POOL_SOLID_FENCE_BTB@2026-09-01', 'QHC.'||p||'.T4.COMMON_POOL@2026-09-01', 'RELAXES', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A3.1 Table 4', 'VERIFIED_VERBATIM');
    PERFORM relate('QHC.'||p||'.T24.POOL_SOLID_FENCE_BTB@2026-09-01', 'QHC.'||p||'.T2.FRONT_POOL@2026-09-01', 'RELAXES', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A2.1 Table 2', 'VERIFIED_VERBATIM');
    PERFORM relate('QHC.'||p||'.T4.WCE_ATTACHED_TO_BTB@2026-09-01', 'QHC.'||p||'.T4.COMMON_WEATHER_CONTROL@2026-09-01', 'RELAXES', 'QHC@2026-09-01', replace(p,'CH','Ch')||' A3.1 Table 4', 'VERIFIED_VERBATIM', 'Table 4 supp. prov. 1');
  END LOOP;

  -- QHC replaces MP 1.1/1.2 (per-LG timing is in instrument_applicability)
  PERFORM relate('QHC.CH2.T3.COMMON_CLASS10A_BTB@2026-09-01', 'QDC12.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26', 'REPLACES', 'QHC@2026-09-01', 's 3', 'VERIFIED_VERBATIM');
  PERFORM relate('QHC.CH2.A4_1.SITE_COVER@2026-09-01', 'QDC12.A3.SITE_COVER@2010-03-26', 'REPLACES', 'QHC@2026-09-01', 's 3', 'VERIFIED_VERBATIM');
  PERFORM relate('QHC.CH1.A4_1.SITE_COVER@2026-09-01', 'QDC11.A3.SITE_COVER@2010-03-26', 'REPLACES', 'QHC@2026-09-01', 's 3', 'VERIFIED_VERBATIM');
  PERFORM relate('QHC.CH2.T4.COMMON_POOL@2026-09-01', 'QDC12.A2a.POOL_SIDE_REAR@2010-03-26', 'REPLACES', 'QHC@2026-09-01', 's 3', 'VERIFIED_VERBATIM');
  PERFORM relate('QHC.CH2.T2.FRONT_POOL@2026-09-01', 'QDC12.A1d.POOL_ROAD_SETBACK@2010-03-26', 'REPLACES', 'QHC@2026-09-01', 's 3', 'VERIFIED_VERBATIM');

  -- Pool safety
  PERFORM relate('MP34.S1_12.NO_NCZ_TALL_FENCE@2012-07-27', 'MP34.S1_6.NCZ_INSIDE_NEEDS_1800@2012-07-27', 'EXEMPTS', 'QDC_MP_3_4@2012-07-27', 'Sch 1 item 12', 'VERIFIED_VERBATIM');
  PERFORM relate('MP34.P1.BARRIER_REQUIRED@2012-07-27', 'BA.S231B.REGULATED_POOL@2026-02-01', 'CONDITIONAL_ON', 'QLD_BUILDING_ACT_1975@2026-02-01', 's 231D(1)', 'VERIFIED_VERBATIM', 'MP 3.4 applies to regulated pools.');
END $$;

-- -----------------------------------------------------------------------------
-- Instrument applicability (state-wide)
-- -----------------------------------------------------------------------------
INSERT INTO instrument_applicability (instrument_version_id, lg_id, regime, effective_from, effective_to, end_condition, basis_provision_id, confidence, notes) VALUES
 ('QDC_MP_3_4@2012-07-27', NULL, 'POOL_SAFETY', '2012-07-27', NULL, NULL, p('QLD_BUILDING_ACT_1975@2026-02-01','s 231D(1)'), 'VERIFIED_VERBATIM', 'Pool safety standard, all regulated pools statewide.'),
 ('QDC_MP_1_4@2014-12-15', NULL, 'INFRASTRUCTURE', '2014-12-15', NULL, NULL, p('QLD_BUILDING_REG_2021@2026-08-14','sch 7'), 'VERIFIED_VERBATIM', NULL),
 ('QDC_MP_1_1@2010-03-26', NULL, 'BUILDING', '2010-03-26', '2026-08-31', NULL, p('QLD_BUILDING_REG_2021@2026-08-14','s 106'), 'VERIFIED_VERBATIM', 'Statewide until QHC commencement.'),
 ('QDC_MP_1_2@2010-03-26', NULL, 'BUILDING', '2010-03-26', '2026-08-31', NULL, p('QLD_BUILDING_REG_2021@2026-08-14','s 106'), 'VERIFIED_VERBATIM', 'Statewide until QHC commencement.');

-- Per-LG rows for the 7 councils: legacy MP 1.1/1.2 continue from 1 Sept 2026
-- until the earlier of QHC adoption or 1 Sept 2029; QHC applies from the
-- long-stop date. Adoption dates (none found as at 2026-10-08) go in db/030.
INSERT INTO instrument_applicability (instrument_version_id, lg_id, regime, effective_from, effective_to, end_condition, basis_provision_id, confidence, notes)
SELECT iv, lg_id, 'BUILDING', '2026-09-01', '2029-08-31',
       'Ends on the day before the effective day of a scheme amendment stating how the QHC applies, if earlier',
       p('QLD_BUILDING_REG_2021@2026-08-14','s 106'), 'VERIFIED_VERBATIM',
       'No adopting amendment found for this LG as at 2026-10-08 (see council research notes).'
FROM local_governments, unnest(ARRAY['QDC_MP_1_1@2010-03-26','QDC_MP_1_2@2010-03-26']) AS iv;

INSERT INTO instrument_applicability (instrument_version_id, lg_id, regime, effective_from, effective_to, end_condition, basis_provision_id, confidence, notes)
SELECT 'QHC@2026-09-01', lg_id, 'BUILDING', '2029-09-01', NULL, NULL,
       p('QLD_BUILDING_REG_2021@2026-08-14','s 106'), 'VERIFIED_VERBATIM', 'Long-stop. Move effective_from earlier when an adopting amendment takes effect.'
FROM local_governments;

INSERT INTO open_issues (instrument_id, severity, description) VALUES
 ('AS_1926_1_2007', 'HIGH', 'Barrier gap limits, ground clearance, horizontal climbable member spacing, gate latch height and hinge requirements live in AS 1926.1-2007 (as modified by MP 3.4). Not held; no numeric values recorded. Obtain a licensed copy before automating barrier detail checks.'),
 ('QLD_BUILDING_REG_2021', 'MEDIUM', 'Former s6 of the Building Regulation 2021 (continued by s106 for non-adopting schemes) not held. Brisbane City Plan Table 1.6.1 cites it (with Building Act s32(b)) as the basis for scheme standards on QDC P4 height, P5 privacy and P8 parking — confirm against the pre-2026 reprint.'),
 ('QDC_MP_1_4', 'MEDIUM', 'MP 1.4 still cites Sustainable Planning Regulation 2009 sch 7 item 27A; confirm the current Planning Regulation 2017 referral item for service-provider concurrence.'),
 ('QHC', 'HIGH', 'Department register of QHC adoption effective days not reachable (HTTP 403). Re-check monthly; each adoption changes instrument_applicability for that LG.'),
 ('NCC', 'MEDIUM', 'NCC Housing Provisions fire separation for Class 10a within 900 mm of a boundary or 1.8 m of a Class 1 building not captured (text not held). Construction requirement, not a siting fail.');
