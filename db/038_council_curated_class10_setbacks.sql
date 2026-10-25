-- =============================================================================
-- Curated council rules: remaining front / side / rear setbacks that reach Class 10 structures, for the loaded
-- councils (Class 10 scope set by the user on 22 Oct 2026). Hand-encoded from the verbatim provisions loaded by
-- db/030_council_*.sql. Each curated rule REPLACES its draft. Drafts reviewed and deliberately not curated are
-- listed with reasons in validation/councils.json ("curation_decisions").
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('boundary_road_is_mount_cotton_or_beenleigh_redland_bay','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The road boundary being tested is Mount Cotton Road or Beenleigh-Redland Bay Road (Logan 9.3.2 AO4(d)(ii))', 'Road name of the road reserve adjoining the boundary'),
 ('boundary_adjoins_milner_place_lot','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The boundary being tested is shared with an existing lot that has a frontage to, or gains access from, Milner Place (Redland LDR4 AO5.1)', 'Cadastre: adjoining lot and its access'),
 ('road_is_state_controlled_or_extractive_route','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The road boundary being tested is a State-controlled road or an extractive industry transport route (Sunshine Coast 9.3.6 AO4.1)', 'State-controlled road network / scheme extractive transport route mapping'),
 ('boundary_is_gloucester_road','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The road boundary being tested is Gloucester Road, Buderim (Sunshine Coast 9.3.6 AO17; Buderim local plan precinct BUD LPP-1)', 'Road name of the road reserve adjoining the boundary'),
 ('vehicle_access_from_rear_lane','BOOLEAN',NULL,NULL,'PROPERTY_DATA','Vehicle access to the lot is from a rear lane (Brisbane 9.3.8 AO22.2 does not apply then)', 'Driveway location');

-- =================================================================================== GOLD COAST
-- Township zone (Table 6.2.23-1)
SELECT define_rule($r${
 "rule_id": "CGC.C.TOWNSHIP_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Township zone: front setback 6 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:TOWNSHIP"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_township_setbacks", "role": "PRIMARY", "quote": "Front | - if roadside stall: 0m - otherwise: 6m"}],
 "interpretation_notes": "Roadside stall (0 m) is not a Class 1/10 building and is not encoded. Table 1.5-1: the zone code is the QDC alternative for buildings only; structures (pools etc.) keep the QDC.",
 "effective_from": "2026-09-29"}$r$);
SELECT alt_overrides('CGC.C.TOWNSHIP_FRONT_SETBACK@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.TOWNSHIP_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Township zone: side and rear setback by height (1.5 / 2 / +0.5 per 3 m over 7.5 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.5},
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "part_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:TOWNSHIP"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_township_setbacks", "role": "PRIMARY",
              "quote": "Side and rear | Height | Setback | up to 4.5m | 1.5m | for that part between 4.5m – 7.5m | 2m | for that part exceeding 7.5m | an extra 0.5m is added for every 3m in height or part thereof over 7.5m"}],
 "interpretation_notes": "Same structure as the Low density residential table (CGC.C.LDR_SIDE_REAR_SETBACK): no built-to-boundary concession for Class 10a in the table.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.TOWNSHIP_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_township_setbacks');
SELECT alt_overrides('CGC.C.TOWNSHIP_SIDE_REAR_SETBACK@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1: zone code alternative (buildings).');

-- Medium density residential, standard lots >= 400 m2 (Table 6.2.2-1); covered car parking: CGC.C.MDR_COVERED_PARKING_FRONT (db/032)
SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Medium density residential (lots >= 400 m2): front setback 4 m (6 m for the part above 23 m), excluding covered car parking",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "part_height_m"}, 23]}, "then": 6.0}], "else": 4.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A_OTHER", "SHED", "DETACHED_LAUNDRY"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_mdr_front_setback", "role": "PRIMARY", "quote": "Front (excluding covered car parking) | up to 23m | 4m | for that part exceeding 23m | 6m"}],
 "interpretation_notes": "Garages and carports (covered car parking) have their own 6 m row: CGC.C.MDR_COVERED_PARKING_FRONT. Lots under 400 m2 use the small-lot table (CGC.C.MDR_SMALL_LOT_*), as for Low density residential.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.MDR_FRONT_SETBACK@2026-09-29', 'CGC.gc_mdr_front_setback');
SELECT alt_overrides('CGC.C.MDR_FRONT_SETBACK@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Medium density residential (lots >= 400 m2): side and rear setback by height (1.5 / 2 / +0.5 per 3 m over 7.5 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.5},
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "part_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_mdr_side_rear_setback_height_tiered", "role": "PRIMARY",
              "quote": "Side and rear | up to 4.5m | 1.5m | for that part between 4.5m – 7.5m | 2m | for that part exceeding 7.5m | an extra 0.5m is added for every 3m in height or part thereof over 7.5m."}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.MDR_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_mdr_side_rear_setback_height_tiered');
SELECT alt_overrides('CGC.C.MDR_SIDE_REAR_SETBACK@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1: zone code alternative (buildings).');

-- Medium density residential, small lots < 400 m2 (same table as Low density residential small lots)
SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_SMALL_LOT_FRONT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Medium density residential small lot (< 400 m2): front 4.5 m to wall and balcony",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 4.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A_OTHER", "SHED", "DETACHED_LAUNDRY"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_mdr_small_lot_setbacks", "role": "PRIMARY", "quote": "Setbacks for Dwelling houses on small lots: | Setback | Minimum distances measured in metres (m) | Front | 4.5m to wall and balcony"}],
 "interpretation_notes": "Mirrors CGC.C.LDR_SMALL_LOT_FRONT. Covered car parking: CGC.C.MDR_SMALL_LOT_COVERED_PARKING.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.MDR_SMALL_LOT_FRONT@2026-09-29', 'CGC.gc_mdr_small_lot_setbacks');
SELECT alt_overrides('CGC.C.MDR_SMALL_LOT_FRONT@2026-09-29', ARRAY['QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_SMALL_LOT_COVERED_PARKING", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "GARAGE.FRONTAGE", "title": "Medium density residential small lot: covered car parking 6 m from the frontage where vehicles access the lot",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "gc_mdr_small_lot_setbacks", "role": "PRIMARY", "quote": "Covered car parking (not applicable to the rear lane access) | 1m behind front wall or balcony; and 6m from the frontage where vehicles access the lot."}],
 "interpretation_notes": "Mirrors CGC.C.LDR_SMALL_LOT_COVERED_PARKING: '1m behind front wall or balcony' not encoded; applies to the frontage giving vehicle access only.",
 "effective_from": "2026-09-29"}$r$);
SELECT alt_overrides('CGC.C.MDR_SMALL_LOT_COVERED_PARKING@2026-09-29', ARRAY['QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_SMALL_LOT_SIDE_REAR", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Medium density residential small lot: side and rear to wall 1 / 1.5 / 2 m by height",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.0},
                                  {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 1.5}], "else": 2.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_mdr_small_lot_setbacks", "role": "PRIMARY",
              "quote": "Side and rear (not applicable to the secondary frontage of corner lots) | Height | Setback | up to 4.5m | 1m to wall and balcony 0.5m to outermost projection ... for that part between 4.5m – 7.5m | 1.5m to wall and balcony 1m to outermost projection | for that part exceeding 7.5m | 2m to wall and balcony 1.5m to outermost projection"}],
 "interpretation_notes": "Mirrors CGC.C.LDR_SMALL_LOT_SIDE_REAR ('to wall and balcony' column).",
 "effective_from": "2026-09-29"}$r$);
SELECT alt_overrides('CGC.C.MDR_SMALL_LOT_SIDE_REAR@2026-09-29', ARRAY['QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.5-1: the small-lot table sets its own Class 10 BTB terms, displacing A2(d).');

SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_SMALL_LOT_CLASS10_BTB", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Medium density residential small lot: Class 10 at 0 m on a southern or western boundary (<= 12 m, no part > 6 m, >= 1 m from neighbour's habitable window)",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]},
                 {"fact": "part_height_m", "op": "<=", "value": 4.5}, {"fact": "boundary_faces_south_or_west", "op": "IS_TRUE"},
                 {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 12}, {"fact": "btb_max_single_part_length_m", "op": "<=", "value": 6},
                 {"fact": "distance_to_adjoining_habitable_window_m", "op": ">=", "value": 1.0}]],
 "sources": [{"key": "gc_mdr_small_lot_class10_built_to_boundary", "role": "PRIMARY",
              "quote": "0m to class 10 building and/or non-habitable room where: - located along a southern or western boundary; - a maximum length of 12m where no single part exceeds 6m in length; and - at least 1m separation from a habitable window of a neighbouring dwelling."}],
 "interpretation_notes": "Mirrors CGC.C.LDR_SMALL_LOT_CLASS10_BTB.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.MDR_SMALL_LOT_CLASS10_BTB@2026-09-29', 'CGC.gc_mdr_small_lot_class10_built_to_boundary');
SELECT relate('CGC.C.MDR_SMALL_LOT_CLASS10_BTB@2026-09-29', 'CGC.C.MDR_SMALL_LOT_SIDE_REAR@2026-09-29', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM');

-- Rear lots in Low and Medium density residential: "OR For development on rear lots the setback is 3m from all boundaries."
SELECT define_rule($r${
 "rule_id": "CGC.C.REAR_LOT_FRONT_3M", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Low / Medium density residential rear lot: 3 m from the frontage boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "is_battle_axe_lot", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_ldr_rear_lot_setback", "role": "PRIMARY", "quote": "OR For development on rear lots the setback is 3m from all boundaries."},
             {"key": "gc_mdr_small_lot_setbacks", "role": "SUPPLEMENTARY", "quote": "OR For development on rear lots the setback is 3m from all boundaries."}],
 "interpretation_notes": "'Rear lot' read as a battle-axe lot (fact is_battle_axe_lot). On a rear lot this 3 m replaces the zone's front / side / rear / covered-parking rows (OVERRIDES relationships).",
 "effective_from": "2026-09-29"}$r$);
SELECT define_rule($r${
 "rule_id": "CGC.C.REAR_LOT_SIDE_REAR_3M", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Low / Medium density residential rear lot: 3 m from side and rear boundaries",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "is_battle_axe_lot", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_ldr_rear_lot_setback", "role": "PRIMARY", "quote": "OR For development on rear lots the setback is 3m from all boundaries."},
             {"key": "gc_mdr_small_lot_setbacks", "role": "SUPPLEMENTARY", "quote": "OR For development on rear lots the setback is 3m from all boundaries."}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.REAR_LOT_SIDE_REAR_3M@2026-09-29', 'CGC.gc_ldr_rear_lot_setback');
SELECT alt_overrides('CGC.C.REAR_LOT_FRONT_3M@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');
SELECT alt_overrides('CGC.C.REAR_LOT_SIDE_REAR_3M@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE'], 'Table 1.5-1: zone code alternative (buildings).');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, verification, notes)
SELECT f, t, 'OVERRIDES', 'VERIFIED_VERBATIM', 'Zone table: "OR For development on rear lots the setback is 3m from all boundaries."'
FROM unnest(ARRAY['CGC.C.REAR_LOT_FRONT_3M@2026-09-29','CGC.C.REAR_LOT_SIDE_REAR_3M@2026-09-29']) f,
     unnest(ARRAY['CGC.C.LDR_FRONT_SETBACK','CGC.C.LDR_SIDE_REAR_SETBACK','CGC.C.LDR_SMALL_LOT_FRONT','CGC.C.LDR_SMALL_LOT_COVERED_PARKING','CGC.C.LDR_SMALL_LOT_SIDE_REAR',
                  'CGC.C.MDR_COVERED_PARKING_FRONT','CGC.C.MDR_FRONT_SETBACK','CGC.C.MDR_SIDE_REAR_SETBACK','CGC.C.MDR_SMALL_LOT_FRONT','CGC.C.MDR_SMALL_LOT_COVERED_PARKING','CGC.C.MDR_SMALL_LOT_SIDE_REAR']) t;

-- Low density residential rear draft: same provision as the curated side-and-rear rule (db/031)
SELECT supersede_draft('CGC.C.LDR_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_ldr_rear_setback_height_tiered');

-- Mudgeeraba Village character overlay (Table 8.2.13): prevails over the zone code
SELECT define_rule($r${
 "rule_id": "CGC.C.MUDGEERABA_FRONT_3M", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Mudgeeraba Village character area: residential buildings front setback 3 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "OVERLAY", "overlay": "CGC:OV:MUDGEERABA_VILLAGE_CHARACTER_OVERLAY_MUDGEERABA_VILLAGE_CHARACTER_AREA"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_mudgeeraba_residential_setbacks", "role": "PRIMARY", "quote": "Residential buildings and structures | Front | 3m | Side and rear | 1.5m"}],
 "interpretation_notes": "Table 1.5-1 lists this overlay code as the QDC alternative for buildings in the Mudgeeraba Village character area, and the overlay prevails over the zone code, so it OVERRIDES the zone setback rules there. Structures that are not buildings (pools) keep the QDC.",
 "effective_from": "2026-09-29"}$r$);
SELECT define_rule($r${
 "rule_id": "CGC.C.MUDGEERABA_SIDE_REAR_1_5M", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Mudgeeraba Village character area: residential buildings side and rear setback 1.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "OVERLAY", "overlay": "CGC:OV:MUDGEERABA_VILLAGE_CHARACTER_OVERLAY_MUDGEERABA_VILLAGE_CHARACTER_AREA"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_mudgeeraba_residential_setbacks", "role": "PRIMARY", "quote": "Residential buildings and structures | Front | 3m | Side and rear | 1.5m"}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.MUDGEERABA_FRONT_3M@2026-09-29', 'CGC.gc_mudgeeraba_residential_setbacks');
SELECT alt_overrides('CGC.C.MUDGEERABA_FRONT_3M@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: Mudgeeraba Village character overlay code alternative (buildings).');
SELECT alt_overrides('CGC.C.MUDGEERABA_SIDE_REAR_1_5M@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1: Mudgeeraba Village character overlay code alternative (buildings).');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, verification, notes)
SELECT f, r.rule_id, 'OVERRIDES', 'VERIFIED_VERBATIM', 'Overlay code prevails over the zone code (s1.5 / Table 1.5-1) within the Mudgeeraba Village character area.'
FROM unnest(ARRAY['CGC.C.MUDGEERABA_FRONT_3M@2026-09-29','CGC.C.MUDGEERABA_SIDE_REAR_1_5M@2026-09-29']) f
JOIN rules r ON r.rule_id LIKE 'CGC.C.%' AND r.rule_id NOT LIKE 'CGC.C.MUDGEERABA%'
 AND r.topic IN ('SETBACK.FRONTAGE','SETBACK.SIDE','SETBACK.REAR','SETBACK.SIDE_REAR','GARAGE.FRONTAGE');

-- ======================================================================================= LOGAN
SELECT define_rule($r${
 "rule_id": "LCC.C.ROAD_CLEARANCE_20M", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.FRONTAGE", "title": "Environmental management and conservation / Rural zone: road boundary clearance 20 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 20.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}, {"level": "ZONE", "zone": "LCC:ENVIRONMENTAL_MANAGEMENT_AND_CONSERVATION"}, {"level": "ZONE", "zone": "LCC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "dh_ao4d_road_clearance_20m", "role": "PRIMARY",
              "quote": "d. has a minimum road boundary clearance of 20 metres in the: i. Environmental management and conservation zone ii. Rural residential zone - Carbrook precinct with a road frontage to Mount Cotton Road or Beenleigh-Redland Bay Road iii. Rural zone."}],
 "interpretation_notes": "As LCC.C.ROAD_CLEARANCE_10M: 'road boundary' covers every road frontage. The Carbrook limb is LCC.C.ROAD_CLEARANCE_20M_CARBROOK.",
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.ROAD_CLEARANCE_20M@2025-07-01', 'LCC.dh_ao4d_road_clearance_20m');
SELECT define_rule($r${
 "rule_id": "LCC.C.ROAD_CLEARANCE_20M_CARBROOK", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.FRONTAGE", "title": "Rural residential Carbrook precinct: road boundary clearance 20 m to Mount Cotton Road / Beenleigh-Redland Bay Road",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 20.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}, {"level": "PRECINCT", "precinct": "LCC:RURAL_RESIDENTIAL/CARBROOK"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]},
                 {"fact": "boundary_road_is_mount_cotton_or_beenleigh_redland_bay", "op": "IS_TRUE"}]],
 "sources": [{"key": "dh_ao4d_road_clearance_20m", "role": "PRIMARY",
              "quote": "ii. Rural residential zone - Carbrook precinct with a road frontage to Mount Cotton Road or Beenleigh-Redland Bay Road"}],
 "interpretation_notes": "Read as applying to the boundary that fronts one of the two named roads; other Carbrook road frontages keep 10 m (LCC.C.ROAD_CLEARANCE_10M), which this rule overrides where it applies.",
 "effective_from": "2025-07-01"}$r$);
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.SIDE_TO_CORNER_STREET'], 'Table 1.6.1: Dual occupancy and Dwelling house code PO4/AO4 is an alternative to the QDC boundary clearances.')
FROM unnest(ARRAY['LCC.C.ROAD_CLEARANCE_20M@2025-07-01','LCC.C.ROAD_CLEARANCE_20M_CARBROOK@2025-07-01']) rv;
SELECT relate('LCC.C.ROAD_CLEARANCE_20M_CARBROOK@2025-07-01', 'LCC.C.ROAD_CLEARANCE_10M@2025-07-01', 'OVERRIDES', NULL, NULL, 'VERIFIED_VERBATIM', 'AO4(d)(ii) is the more specific limb for Carbrook frontages to the two named roads.');

-- ===================================================================================== REDLAND
SELECT define_rule($r${
 "rule_id": "RCC.C.LDR4_MILNER_PLACE_5M", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "SETBACK.SIDE_REAR", "title": "LDR4 Kinross Road precinct: dwelling houses (including outbuildings) 5 m from boundaries shared with existing Milner Place lots",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 5.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR4"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}, {"fact": "boundary_adjoins_milner_place_lot", "op": "IS_TRUE"}]],
 "sources": [{"key": "ldr4_milner_place_setback_5m", "role": "PRIMARY",
              "quote": "AO5.1 In precinct LDR4 Kinross Road, dwelling houses (including outbuildings) are set back 5m from lot boundaries shared with existing lots accessed from Milner Place."}],
 "interpretation_notes": "Not automatable: which neighbouring lots are 'accessed from Milner Place' needs cadastral review. Outbuildings are expressly included, so the QDC Class 10a concession does not apply on these boundaries.",
 "effective_from": "2025-11-10"}$r$);
SELECT supersede_draft('RCC.C.LDR4_MILNER_PLACE_5M@2025-11-10', 'RCC.ldr4_milner_place_setback_5m');
SELECT alt_overrides('RCC.C.LDR4_MILNER_PLACE_5M@2025-11-10', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'],
       'Editor''s note: the LDR zone code acceptable outcomes are alternative provisions for the QDC.');

-- ============================================================================== SUNSHINE COAST
SELECT define_rule($r${
 "rule_id": "SCC.C.RURAL_LARGE_LOT_ROAD_SETBACK", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone, lot over 2 ha: dwelling house incl. garage/carport/shed 40 m from a State-controlled road or extractive transport route, 20 m from any other road",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "road_is_state_controlled_or_extractive_route"}]}, "then": 40.0}], "else": 20.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}, {"level": "ZONE", "zone": "SCC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">", "value": 20000}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "dh_rural_large_road_setback", "role": "PRIMARY",
              "quote": "AO4.1 Where located on a lot in the Rural zone, and the lot has an area of more than 2 hectares, the dwelling house (including any associated garage, carport or shed) is set back at least:- (a) 40 metres from a State controlled road or an extractive industry transport route; (b) 20 metres from any other road"}],
 "interpretation_notes": "Limb (c) (extensions up to 50 m2 within/under an existing house) is not Class 10 and is not encoded. Lots of 2 ha or less: SCC.C.RURAL_SMALL_LOT_ROAD_10.",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.RURAL_LARGE_LOT_ROAD_SETBACK@2024-01-23', 'SCC.dh_rural_large_road_setback');
SELECT alt_overrides('SCC.C.RURAL_LARGE_LOT_ROAD_SETBACK@2024-01-23', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK','QDC12.A1b.CORNER_NOMINATED_FRONTAGE','QDC12.A1c.OPEN_CARPORT'], 'Note--AO4.1 and AO4.2 alternative provisions to QDC.');

SELECT define_rule($r${
 "rule_id": "SCC.C.RURAL_SIDE_REAR", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural zone: dwelling house incl. garage/carport/shed 3 m from side and rear boundaries (lot 2 ha or less), 10 m (over 2 ha)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "lot_area_m2"}, 20000]}, "then": 3.0}], "else": 10.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}, {"level": "ZONE", "zone": "SCC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "dh_rural_side_rear_setback", "role": "PRIMARY",
              "quote": "AO5.1 Where located on a lot in the Rural zone, the dwelling house (including any associated garage, carport or shed) is set back from any side or rear boundary at least:- (a) 3 metres where the lot has an area of 2 hectares or less; or (b) 10 metres where the lot has an area of more than 2 hectares."}],
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.RURAL_SIDE_REAR@2024-01-23', 'SCC.dh_rural_side_rear_setback');
SELECT alt_overrides('SCC.C.RURAL_SIDE_REAR@2024-01-23', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Note--AO5.1 and AO5.2 alternative provisions to QDC.');

SELECT define_rule($r${
 "rule_id": "SCC.C.BUDERIM_GLOUCESTER_RD_10M", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.FRONTAGE", "title": "Buderim local plan BUD LPP-1: dwelling house incl. garage/carport/shed 10 m from Gloucester Road",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}, {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "SCC:BUDERIM/BUD_LPP_1"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}, {"fact": "boundary_is_gloucester_road", "op": "IS_TRUE"}]],
 "sources": [{"key": "dh_buderim_gloucester_rd_setback", "role": "PRIMARY",
              "quote": "AO17 The dwelling house (including any garage, carport or shed) is setback at least 10 metres from Gloucester Road. Note--AO17 alternative provision to QDC."}],
 "interpretation_notes": "Applies in Buderim local plan precinct BUD LPP-1 (Gloucester Road South, Local Plan Map LPM32), to the boundary with Gloucester Road. Research lists the Low density residential zone.",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.BUDERIM_GLOUCESTER_RD_10M@2024-01-23', 'SCC.dh_buderim_gloucester_rd_setback');

SELECT define_rule($r${
 "rule_id": "SCC.C.CALOUNDRA_LPP2_FRONT_6M", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.FRONTAGE", "title": "Caloundra local plan CAL LPP-2: dwelling house incl. garage/carport/shed 6 m from the primary street frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}, {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "SCC:CALOUNDRA/CAL_LPP_2"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "dh_caloundra_lpp2_front_setback", "role": "PRIMARY",
              "quote": "AO18 The dwelling house (including any garage, carport or shed) is setback a minimum of 6 metres from the primary street frontage. Note--AO18.1 alternative provision to QDC."}],
 "interpretation_notes": "Precinct CAL LPP-2 (Moffat Beach / Shelly Beach / Dicky Beach, LPM45); research lists the Low, Medium and High density residential and Tourist accommodation zones. 'Primary street frontage' is undefined in the scheme; read as PRIMARY_FRONTAGE.",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.CALOUNDRA_LPP2_FRONT_6M@2024-01-23', 'SCC.dh_caloundra_lpp2_front_setback');
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Note--AO17 / AO18 alternative provisions to QDC.')
FROM unnest(ARRAY['SCC.C.BUDERIM_GLOUCESTER_RD_10M@2024-01-23','SCC.C.CALOUNDRA_LPP2_FRONT_6M@2024-01-23']) rv;

-- ==================================================================================== BRISBANE
-- Small lot code section B: lots under 180 m2 (Table 9.3.8.3.C, AO22–AO25)
SELECT define_rule($r${
 "rule_id": "BCC.C.SLB_FRONT", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.FRONTAGE", "title": "Small lot under 180 m2: front setback to wall 3 / 4 / 6 m by lot depth; 2.5 m on a corner lot",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "is_corner_lot"}]}, "then": 2.5},
                                  {"if": {"op": ">", "args": [{"var": "average_lot_depth_m"}, 25]}, "then": 6.0},
                                  {"if": {"op": ">", "args": [{"var": "average_lot_depth_m"}, 18]}, "then": 4.0}], "else": 3.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 180}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "slb_front_setback_ref_table_c", "role": "PRIMARY", "quote": "Development results in a front boundary setback in accordance with: - the requirements set out in Table 9.3.8.3.C; or - an approved development footprint plan for the site."},
             {"key": "slb_table_c_setbacks_lt15", "role": "SUPPLEMENTARY", "quote": "Lot depth less than 15m | 3 | 3(2) | 3 | 4 | 1"},
             {"key": "slb_table_c_setbacks_15_18", "role": "SUPPLEMENTARY", "quote": "Lot depth between 15m and 18m | 3 | 3(2) | 4 | 1"},
             {"key": "slb_table_c_setbacks_18_25", "role": "SUPPLEMENTARY", "quote": "Lot depth greater than 18m and up to 25m | 3 | 4(2) | 4 | 6 | 1"},
             {"key": "slb_table_c_setbacks_gt25", "role": "SUPPLEMENTARY", "quote": "Lot depth greater than 25m | 4 | 6(2) | 4 | 6 | 1"},
             {"key": "slb_table_c_setbacks_corner", "role": "SUPPLEMENTARY", "quote": "Where located on a corner lot | 2.5(2); or 1.5 to a secondary street frontage | – | 1"}],
 "interpretation_notes": "Front 'To wall' column: < 15 m deep 3 m; 15–18 m 3 m; > 18–25 m 4 m; > 25 m 6 m; corner lot 2.5 m. 'To balcony' column (3 / 3 / 3 / 4 m) not encoded separately. Covered car parking needs 5.5 m (note (2), BCC.C.SLB_COVERED_PARKING_5_5). Zones as for the 180–450 m2 section (BCC.C.SL_*).",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SLB_FRONT@2026-09-18', d) FROM unnest(ARRAY['BCC.slb_front_setback_ref_table_c','BCC.slb_table_c_setbacks_lt15','BCC.slb_table_c_setbacks_15_18','BCC.slb_table_c_setbacks_18_25','BCC.slb_table_c_setbacks_gt25','BCC.slb_table_c_setbacks_corner']) d;
SELECT alt_overrides('BCC.C.SLB_FRONT@2026-09-18', ARRAY['QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.FRONTAGE_NEIGHBOURS'], 'Table 1.6.1: small lot code alternative to QDC P1.');

SELECT define_rule($r${
 "rule_id": "BCC.C.SLB_REAR", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.REAR", "title": "Small lot under 180 m2: rear setback to wall 4 m (lot 18 m deep or less) or 6 m (deeper)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "average_lot_depth_m"}, 18]}, "then": 6.0}], "else": 4.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 180}, {"fact": "development_footprint_exists", "op": "IS_FALSE"},
                 {"fact": "is_corner_lot", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "slb_rear_setback_ref_table_c", "role": "PRIMARY", "quote": "Development results in a rear boundary setback in accordance with: - the requirements set out in Table 9.3.8.3.C; or - an approved development footprint plan for the site."},
             {"key": "slb_table_c_setbacks_lt15", "role": "SUPPLEMENTARY", "quote": "Lot depth less than 15m | 3 | 3(2) | 3 | 4 | 1"},
             {"key": "slb_table_c_setbacks_18_25", "role": "SUPPLEMENTARY", "quote": "Lot depth greater than 18m and up to 25m | 3 | 4(2) | 4 | 6 | 1"}],
 "interpretation_notes": "Rear 'To wall' column: 4 / 4 / 6 / 6 m by depth band. Corner lots: rear '–' (no rear setback stated) — rule excluded on corner lots. Rear-lane frontage reduced setbacks (note (1): 0.5 m non-habitable, 1 m habitable) apply to the lane frontage and are not encoded.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SLB_REAR@2026-09-18', 'BCC.slb_rear_setback_ref_table_c');
SELECT alt_overrides('BCC.C.SLB_REAR@2026-09-18', ARRAY['QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1: small lot code alternative to QDC P2 (rear).');

SELECT define_rule($r${
 "rule_id": "BCC.C.SLB_SIDE_1M", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SIDE", "title": "Small lot under 180 m2: side setback 1 m (built-to-boundary walls: BCC.C.SLB_BTB)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 180}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "slb_side_setback_ref_table_c", "role": "PRIMARY", "quote": "Development results in side boundary setbacks in accordance with: - the requirements set out in Table 9.3.8.3.C; or - an approved development footprint plan for the site."},
             {"key": "slb_table_c_setbacks_gt25", "role": "SUPPLEMENTARY", "quote": "Lot depth greater than 25m | 4 | 6(2) | 4 | 6 | 1"}],
 "interpretation_notes": "Side column is 1 m in every row, including corner lots. Subjects as BCC.C.SL_SIDE_HABITABLE.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SLB_SIDE_1M@2026-09-18', 'BCC.slb_side_setback_ref_table_c');
SELECT alt_overrides('BCC.C.SLB_SIDE_1M@2026-09-18', ARRAY['QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1: small lot code alternative to QDC P2.');

SELECT define_rule($r${
 "rule_id": "BCC.C.SLB_BTB", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Small lot under 180 m2: built-to-boundary wall for non-habitable spaces (adjoining lot > 300 m2, >= 1 m from neighbour's habitable window, <= 3 m high, <= 15 m long)",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 180}, {"fact": "boundary_type", "op": "=", "value": "SIDE"},
                 {"fact": "adjoining_lot_area_m2", "op": ">", "value": 300}, {"fact": "distance_to_adjoining_habitable_window_m", "op": ">=", "value": 1.0},
                 {"fact": "structure_height_m", "op": "<=", "value": 3.0}, {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 15}]],
 "sources": [{"key": "slb_built_to_boundary_conditions", "role": "PRIMARY",
              "quote": "AO25.1 Development ensures that a built to boundary wall is: - only for non-habitable rooms or spaces where the adjoining lot is more than 300m2; - not located within 1m of a window of a habitable room in an adjoining dwelling house; - not located within the front (including secondary frontages) or rear boundary setbacks;"},
             {"key": "slb_built_to_boundary_length", "role": "SUPPLEMENTARY", "quote": "AO25.2 Development ensures a built to boundary wall: - has a maximum length of 15m; or - is in accordance with an approved development footprint plan for the site."}],
 "interpretation_notes": "'a maximum wall height of 3m' encoded on structure_height_m. 'Not within the front or rear setbacks' and 'located towards the front ... on a corner lot' are geometric limits for the geometry layer. Low-maintenance materials not encoded. A built-to-boundary wall is less than 900 mm from the boundary (note).",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SLB_BTB@2026-09-18', d) FROM unnest(ARRAY['BCC.slb_built_to_boundary_conditions','BCC.slb_built_to_boundary_length']) d;
SELECT relate('BCC.C.SLB_BTB@2026-09-18', 'BCC.C.SLB_SIDE_1M@2026-09-18', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM');

SELECT define_rule($r${
 "rule_id": "BCC.C.SLB_COVERED_PARKING_5_5", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "GARAGE.FRONTAGE", "title": "Small lot under 180 m2: covered car parking 5.5 m from the front boundary (not where accessed by a rear lane)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:HIGH_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 180}, {"fact": "development_footprint_exists", "op": "IS_FALSE"},
                 {"fact": "vehicle_access_from_rear_lane", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "slb_covered_parking_front_setback", "role": "PRIMARY",
              "quote": "AO22.2 Development, except where accessed by a rear lane, results in a front boundary setback to areas for covered car parking that: - is a minimum of 5.5m; or - is in accordance with an approved development footprint plan for the site."}],
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SLB_COVERED_PARKING_5_5@2026-09-18', 'BCC.slb_covered_parking_front_setback');
SELECT alt_overrides('BCC.C.SLB_COVERED_PARKING_5_5@2026-09-18', ARRAY['QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.6.1: small lot code alternative to QDC P1.');

-- Sherwood–Graceville neighbourhood plan area, outside the Westside character precinct (traditional building character overlay)
SELECT define_rule($r${
 "rule_id": "BCC.C.TBC_SHERWOOD_REAR_6", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.REAR", "title": "Traditional building character, Sherwood–Graceville NP area (not Westside precinct): rear setback 6 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "LOCAL_PLAN", "local_plan": "BCC:NP_SHERWOOD_GRACEVILLE"},
            {"level": "OVERLAY", "overlay": "BCC:OV:TRADITIONAL_BUILDING_CHARACTER_OVERLAY"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "BCC:NP_SHERWOOD_GRACEVILLE/NPP-001", "exclude": true}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "tbc_sherwood_rear_setback", "role": "PRIMARY",
              "quote": "Additional performance outcomes and acceptable outcomes if in the Sherwood—Graceville district neighbourhood plan area where not in the Westside character precinct | AO12.2 Development has a minimum rear boundary setback of 6m."}],
 "interpretation_notes": "As BCC.C.NP_NEW_FARM_REAR_6: whether 'development' reaches Class 10a outbuildings needs council confirmation => not automatable (manual review).",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.TBC_SHERWOOD_REAR_6@2026-09-18', 'BCC.tbc_sherwood_rear_setback');

SELECT define_rule($r${
 "rule_id": "BCC.C.NP_SHERWOOD_WESTSIDE_FRONT_AVG", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.FRONTAGE", "title": "Sherwood–Graceville Westside character precinct: front setback within 20% of the average of the nearest pre-1947 buildings (minimum encoded: 80%)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "*", "args": [0.8, {"var": "pre1946_neighbour_avg_front_setback_m"}]},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "BCC:NP_SHERWOOD_GRACEVILLE/NPP-001"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "np_sherwood_westside_front_setback", "role": "PRIMARY",
              "quote": "AO3.3 Development is set back from any road alignment to a distance within 20% of the average front setback of the nearest buildings built in 1946 or before that front the same street, in accordance with Figure d."}],
 "interpretation_notes": "As BCC.C.TBC_FRONT_SETBACK_AVERAGE: the 1.2x maximum is noted for the geometry layer; identifying pre-1947 buildings needs building-age data; whether 'development' reaches Class 10a needs confirmation => not automatable.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.NP_SHERWOOD_WESTSIDE_FRONT_AVG@2026-09-18', 'BCC.np_sherwood_westside_front_setback');

-- ================================================================================ MORETON BAY
-- RAD3 routing / carport exception: already encoded by the db/037 outbuilding-frontage rules (cited as SUPPLEMENTARY)
SELECT supersede_draft('CMB.C.COASTAL_OUTBUILDING_FRONTAGES@2026-09-11', 'CMB.mb_dh_rad3_setback_table_routing_and_carport');
