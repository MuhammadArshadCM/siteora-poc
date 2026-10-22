-- =============================================================================
-- Curated council rules, batch 6 (21 Oct 2026): the last residential-type zones without council rules.
--   Gold Coast  High density residential (6.2.3) and Limited development (constrained land) (6.2.18) — City Plan V14
--   Moreton Bay Limited development (6.2.8): flood / storm-tide land; every kind of building work is impact assessable
--   Brisbane    High density residential: a NEW dwelling house is impact assessable (Table 5.5.4, Table 5.10.9), but
--               building work for an EXTENSION to a dwelling house (incl. Class 10a) is accepted subject to the
--               Dwelling house (small lot) code on a small lot, because the Dwelling house character overlay covers
--               all HDR land. The small-lot rules of 033 are widened to the zone below; lots of 450 m2 or more get
--               no scheme siting numbers (QDC/QHC only, as in the other zones).
-- Verbatim text: research/councils/<slug>.json (gc_hdr_*, gc_ld_*, mb_ld_*, bcc_hdr_*), fetched 21 Oct 2026.
-- Same conventions as 031-035.
-- =============================================================================
SET search_path = regs, public;

-- The Gold Coast Limited development zone uses the same 'lot created by a residential subdivision' question
UPDATE facts SET description = 'The lot was created through a residential subdivision / reconfiguration of a lot approval (Gold Coast Emerging community and Limited development zones)'
WHERE fact_id = 'lot_from_residential_subdivision';

-- ============================================================== GOLD COAST: High density residential
-- Standard table (lots >= 400 m2)
SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "High density residential: front setback 4 m (part up to 23 m high; buildings other than covered car parking)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 4.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A_OTHER", "SHED", "DETACHED_LAUNDRY"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_hdr_front_setback", "role": "PRIMARY", "quote": "Front (excluding covered car parking) | up to 23m | 4m | for that part exceeding 23m | 6m"}],
 "interpretation_notes": "A dwelling house is capped at 9 m, so the 6 m row for parts over 23 m never applies. Buildings only (Table 1.5-1).",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_FRONT_SETBACK@2026-09-29', 'CGC.gc_hdr_front_setback');

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_COVERED_PARKING_FRONT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "GARAGE.FRONTAGE", "title": "High density residential: front setback for covered car parking 6 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_hdr_front_setback_covered_parking", "role": "PRIMARY", "quote": "Front for covered car parking (excluding a basement) | all | 6m"}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_COVERED_PARKING_FRONT@2026-09-29', 'CGC.gc_hdr_front_setback_covered_parking');
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code is the QDC alternative for buildings.')
FROM unnest(ARRAY['CGC.C.HDR_FRONT_SETBACK@2026-09-29','CGC.C.HDR_COVERED_PARKING_FRONT@2026-09-29']) rv;

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "High density residential: side and rear setback by height (1.5 / 2 / +0.5 per 3 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.5},
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "part_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_hdr_side_rear_setback_height_tiered", "role": "PRIMARY", "quote": "Side and rear | up to 4.5m | 1.5m | for that part between 4.5m – 7.5m"}],
 "interpretation_notes": "Same table as Low density residential; 'height' read as height of the part. No Class 10a built-to-boundary concession in the standard table.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_hdr_side_rear_setback_height_tiered');
SELECT supersede_draft('CGC.C.HDR_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_hdr_rear_setback_height_tiered');
SELECT alt_overrides('CGC.C.HDR_SIDE_REAR_SETBACK@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1 alternative boundary clearance (buildings).');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
SELECT 'CGC.C.HDR_SIDE_REAR_SETBACK@2026-09-29', t, 'UNRESOLVED', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM',
       'Same question as Low density residential: whether QDC A2(d) Class 10a built-to-boundary survives a zone table that is silent on it.'
FROM unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;

-- Small lot table (lots < 400 m2) — same wording and encoding as the Low density residential small-lot rules in 032
SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_SMALL_LOT_FRONT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "High density residential small lot (< 400 m2): front 4.5 m to wall and balcony",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 4.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A_OTHER", "SHED", "DETACHED_LAUNDRY"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_hdr_small_lot_front_setback", "role": "PRIMARY", "quote": "Front | 4.5m to wall and balcony"}],
 "interpretation_notes": "Covered car parking has its own row. Measured to wall/balcony, not OMP.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_SMALL_LOT_FRONT@2026-09-29', 'CGC.gc_hdr_small_lot_front_setback');
SELECT alt_overrides('CGC.C.HDR_SMALL_LOT_FRONT@2026-09-29', ARRAY['QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_SMALL_LOT_COVERED_PARKING", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "GARAGE.FRONTAGE", "title": "High density residential small lot: covered car parking 6 m from the frontage where vehicles access the lot",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "gc_hdr_small_lot_covered_parking_setback", "role": "PRIMARY", "quote": "6m from the frontage where vehicles access the lot"}],
 "interpretation_notes": "The '1m behind front wall or balcony' limb (Part A also has '2m behind front building line') is relative to the house and not encoded. Not applicable to rear-lane access.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_SMALL_LOT_COVERED_PARKING@2026-09-29', 'CGC.gc_hdr_small_lot_covered_parking_setback');
SELECT alt_overrides('CGC.C.HDR_SMALL_LOT_COVERED_PARKING@2026-09-29', ARRAY['QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_SMALL_LOT_SECONDARY", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "High density residential small lot: secondary frontage of corner lot 4 m to front wall",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 4.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "gc_hdr_small_lot_secondary_frontage", "role": "PRIMARY", "quote": "Secondary frontage of corner lot | Front wall: 4m (not including projections up to 2m)"}],
 "interpretation_notes": "Part A RO1 (used here) says 4 m with projections up to 2 m not counted; Part B AO1 says 3 m with projections up to 1 m — researcher flagged the inconsistency.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_SMALL_LOT_SECONDARY@2026-09-29', 'CGC.gc_hdr_small_lot_secondary_frontage');
SELECT alt_overrides('CGC.C.HDR_SMALL_LOT_SECONDARY@2026-09-29', ARRAY['QDC11.A1a.SIDE_TO_CORNER_STREET'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_SMALL_LOT_SIDE_REAR", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "High density residential small lot: side and rear to wall 1 / 1.5 / 2 m by height",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.0},
                                  {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 1.5}], "else": 2.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_hdr_small_lot_side_setback", "role": "PRIMARY", "quote": "up to 4.5m | 1m to wall and balcony"}],
 "interpretation_notes": "Encodes the 'to wall and balcony' column (1 / 1.5 / 2 m); the outermost-projection column (0.5 / 1 / 1.5 m) is not encoded separately.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_SMALL_LOT_SIDE_REAR@2026-09-29', 'CGC.gc_hdr_small_lot_side_setback');
SELECT supersede_draft('CGC.C.HDR_SMALL_LOT_SIDE_REAR@2026-09-29', 'CGC.gc_hdr_small_lot_rear_setback');
SELECT alt_overrides('CGC.C.HDR_SMALL_LOT_SIDE_REAR@2026-09-29', ARRAY['QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.5-1: the small-lot table sets its own Class 10 BTB terms, displacing A2(d).');

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_SMALL_LOT_CLASS10_BTB", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "High density residential small lot: Class 10 at 0 m on a southern or western boundary (<= 12 m, no part > 6 m, >= 1 m from neighbour's habitable window)",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]},
                 {"fact": "part_height_m", "op": "<=", "value": 4.5}, {"fact": "boundary_faces_south_or_west", "op": "IS_TRUE"},
                 {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 12}, {"fact": "btb_max_single_part_length_m", "op": "<=", "value": 6},
                 {"fact": "distance_to_adjoining_habitable_window_m", "op": ">=", "value": 1.0}]],
 "sources": [{"key": "gc_hdr_small_lot_class10_built_to_boundary", "role": "PRIMARY",
              "quote": "0m to class 10 building and/or non-habitable room where: - located along a southern or western boundary; - a maximum length of 12m where no single part exceeds 6m in length; and - at least 1m separation from a habitable window of a neighbouring dwelling."}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_SMALL_LOT_CLASS10_BTB@2026-09-29', 'CGC.gc_hdr_small_lot_class10_built_to_boundary');
SELECT relate('CGC.C.HDR_SMALL_LOT_CLASS10_BTB@2026-09-29', 'CGC.C.HDR_SMALL_LOT_SIDE_REAR@2026-09-29', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM');

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "High density residential: dwelling house site cover <= 50% (lot >= 400 m2) or 70% (lot < 400 m2)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "unit": "%",
 "value": {"op": "case", "when": [{"if": {"op": "<", "args": [{"var": "lot_area_m2"}, 400]}, "then": 70}], "else": 50},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_hdr_site_cover", "role": "PRIMARY",
              "quote": "RO2 Site cover does not exceed 50% for Dwelling houses on lots with areas equal to or greater than 400m2 and Dual occupancies. OR Site cover does not exceed 70% for Dwelling houses on lots less than 400m2."}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_SITE_COVER@2026-09-29', 'CGC.gc_hdr_site_cover');
SELECT alt_overrides('CGC.C.HDR_SITE_COVER@2026-09-29', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.5-1 alternative site cover.');

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_HEIGHT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "High density residential (off the Building height overlay map): buildings 2 storeys and 9 m, structures 9 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 9.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"},
            {"level": "OVERLAY", "overlay": "CGC:OV:DWELLING_HOUSE_OVERLAY_BUILDING_HEIGHT_OVERLAY_MAP", "exclude": true}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_hdr_building_height", "role": "PRIMARY",
              "quote": "RO3 Building height does not exceed 2 storeys and a maximum of 9m or that shown on the Building height overlay map. AND Structures do not exceed a height of 9m or that shown on the Building height overlay map."}],
 "interpretation_notes": "Where the lot is on the Building height overlay map, CGC.C.HDR_HEIGHT_MAPPED applies instead. Storey limit not encoded separately.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_HEIGHT@2026-09-29', 'CGC.gc_hdr_building_height');

SELECT define_rule($r${
 "rule_id": "CGC.C.HDR_HEIGHT_MAPPED", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "High density residential: buildings and structures not higher than shown on the Building height overlay map",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m", "value": {"var": "mapped_max_height_m"},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:HIGH_DENSITY_RESIDENTIAL"},
            {"level": "OVERLAY", "overlay": "CGC:OV:DWELLING_HOUSE_OVERLAY_BUILDING_HEIGHT_OVERLAY_MAP"}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_hdr_structure_height", "role": "PRIMARY",
              "quote": "Structures do not exceed a height of 9m or that shown on the Building height overlay map."}],
 "interpretation_notes": "Same reading as CGC.C.MDR_HEIGHT_MAPPED: map labels without metres fall to manual review.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.HDR_HEIGHT_MAPPED@2026-09-29', 'CGC.gc_hdr_structure_height');
SELECT alt_overrides(rv, ARRAY['QDC12.A4.BUILDING_HEIGHT','QDC11.A4.BUILDING_HEIGHT'], 'Table 1.5-1: alternative to QDC building height (P4).')
FROM unnest(ARRAY['CGC.C.HDR_HEIGHT@2026-09-29','CGC.C.HDR_HEIGHT_MAPPED@2026-09-29']) rv;

-- ============================================================== GOLD COAST: Limited development (constrained land)
SELECT define_rule($r${
 "rule_id": "CGC.C.LD_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Limited development (constrained land): front setback 10 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LIMITED_DEVELOPMENT_CONSTRAINED_LAND"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_ld_front_setback", "role": "PRIMARY", "quote": "Front | - if roadside stall: 0m - otherwise: 10m | Side and rear | 3m"}],
 "interpretation_notes": "A dwelling house is accepted subject to requirements (Table 5.5.18), so this zone code binds it as a planning requirement as well as the QDC alternative for buildings.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LD_FRONT_SETBACK@2026-09-29', 'CGC.gc_ld_front_setback');
SELECT alt_overrides('CGC.C.LD_FRONT_SETBACK@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code is the QDC alternative for buildings.');

SELECT define_rule($r${
 "rule_id": "CGC.C.LD_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Limited development (constrained land): side and rear setback 3 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LIMITED_DEVELOPMENT_CONSTRAINED_LAND"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_ld_side_setback", "role": "PRIMARY", "quote": "Side and rear | 3m"}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LD_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_ld_side_setback');
SELECT supersede_draft('CGC.C.LD_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_ld_rear_setback');
SELECT alt_overrides('CGC.C.LD_SIDE_REAR_SETBACK@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1: zone code is the QDC alternative for buildings.');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
SELECT 'CGC.C.LD_SIDE_REAR_SETBACK@2026-09-29', t, 'UNRESOLVED', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM',
       'Same question as Low density residential: whether QDC A2(d) Class 10a built-to-boundary survives a zone table that is silent on it.'
FROM unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;

SELECT define_rule($r${
 "rule_id": "CGC.C.LD_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "Limited development (constrained land): site cover <= 10% (lot not from a residential subdivision)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 10, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LIMITED_DEVELOPMENT_CONSTRAINED_LAND"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_from_residential_subdivision", "op": "IS_FALSE"}]],
 "sources": [{"key": "gc_ld_site_cover", "role": "PRIMARY", "quote": "OR Site cover does not exceed 10%."}],
 "effective_from": "2026-09-29"}$r$);
SELECT define_rule($r${
 "rule_id": "CGC.C.LD_SUBDIV_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "Limited development (constrained land): dwelling house on a lot from a residential reconfiguration approval — site cover <= 50%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 50, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LIMITED_DEVELOPMENT_CONSTRAINED_LAND"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_from_residential_subdivision", "op": "IS_TRUE"}]],
 "sources": [{"key": "gc_ld_site_cover", "role": "PRIMARY",
              "quote": "RO2 Site cover for dwelling houses, on lots created by a residential reconfiguration of a lot approval, does not exceed 50%."}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LD_SITE_COVER@2026-09-29', 'CGC.gc_ld_site_cover');
SELECT alt_overrides(rv, ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.5-1: zone code is the QDC site cover alternative.')
FROM unnest(ARRAY['CGC.C.LD_SITE_COVER@2026-09-29','CGC.C.LD_SUBDIV_SITE_COVER@2026-09-29']) rv;

SELECT define_rule($r${
 "rule_id": "CGC.C.LD_HEIGHT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "Limited development (constrained land), off the Building height overlay map: buildings 2 storeys and 9 m, structures 9 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 9.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LIMITED_DEVELOPMENT_CONSTRAINED_LAND"},
            {"level": "OVERLAY", "overlay": "CGC:OV:DWELLING_HOUSE_OVERLAY_BUILDING_HEIGHT_OVERLAY_MAP", "exclude": true}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_ld_building_height", "role": "PRIMARY",
              "quote": "RO3 Building height does not exceed 2 storeys and a maximum of 9m or that shown on the Building height overlay map."}],
 "interpretation_notes": "RO3 joins the building and structure limits with 'OR'; read as both applying (structures 9 m too).",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LD_HEIGHT@2026-09-29', 'CGC.gc_ld_building_height');

SELECT define_rule($r${
 "rule_id": "CGC.C.LD_HEIGHT_MAPPED", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "Limited development (constrained land): buildings and structures not higher than shown on the Building height overlay map",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m", "value": {"var": "mapped_max_height_m"},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LIMITED_DEVELOPMENT_CONSTRAINED_LAND"},
            {"level": "OVERLAY", "overlay": "CGC:OV:DWELLING_HOUSE_OVERLAY_BUILDING_HEIGHT_OVERLAY_MAP"}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_ld_structure_height", "role": "PRIMARY",
              "quote": "Structures do not exceed a height of 9m or that shown on the Building height overlay map."}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LD_HEIGHT_MAPPED@2026-09-29', 'CGC.gc_ld_structure_height');
SELECT alt_overrides(rv, ARRAY['QDC12.A4.BUILDING_HEIGHT','QDC11.A4.BUILDING_HEIGHT'], 'Table 1.5-1: alternative to QDC building height (P4).')
FROM unnest(ARRAY['CGC.C.LD_HEIGHT@2026-09-29','CGC.C.LD_HEIGHT_MAPPED@2026-09-29']) rv;

-- ============================================================== MORETON BAY: Limited development zone
SELECT define_rule($r${
 "rule_id": "CMB.C.LD_IMPACT_ASSESSMENT", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "PATHWAY.PLANNING_APPROVAL", "title": "Limited development zone: any building work (incl. sheds, garages, carports, pools) is impact assessable — no accepted siting envelope",
 "role": "TRIGGER", "regime": "PLANNING", "enforceability": "MANDATORY", "provision_kind": "PERFORMANCE_OUTCOME",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:LIMITED_DEVELOPMENT"}],
 "subjects": ["ANY"],
 "sources": [{"key": "mb_ld_po1_no_new_buildings_minor_building_work", "role": "PRIMARY",
              "quote": "PO1 New buildings are not located in the Limited development zone and any other building work is only minor building work."}],
 "interpretation_notes": "Table 5.7.1 (rule 4428): 'Building work, not associated with a material change of use, in the Limited development zone || Assessable development - Impact assessment In all instances.' The Table 1.7.7.1 accepted-development circumstances exclude the zone, the zone has no RADs and no QDC alternative provisions, and the Dwelling house code does not apply. A development application is needed; the QDC/QHC siting shown is the building track only.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.LD_IMPACT_ASSESSMENT@2026-09-11', 'CMB.mb_ld_po1_no_new_buildings_minor_building_work');

-- ============================================================== BRISBANE: High density residential
-- Dwelling house (small lot) code rules of 033 also apply here (extension to a dwelling house, Table 5.10.9 row 13136;
-- the Dwelling house character overlay covers all HDR land, Table 5.5.4 note). AO6 names the zone for the 15 m limb.
INSERT INTO rule_scopes (rule_version_id, level, zone_id, exclude)
SELECT rv, 'ZONE', 'BCC:HIGH_DENSITY_RESIDENTIAL', false
FROM unnest(ARRAY['BCC.C.SL_FRONT_PRIMARY@2026-09-18', 'BCC.C.SL_SIDE_HABITABLE@2026-09-18', 'BCC.C.SL_SIDE_NONHABITABLE_LMR_MDR@2026-09-18',
                  'BCC.C.SL_SIDE_ZERO@2026-09-18', 'BCC.C.SL_REAR@2026-09-18', 'BCC.C.SL_SITE_COVER@2026-09-18',
                  'BCC.C.SL_SECONDARY_FRONTAGE_1_5@2026-09-18']) rv;
