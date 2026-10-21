-- =============================================================================
-- Curated council rules, batch 3 (12 Oct 2026): Brisbane small-lot code,
-- Traditional building character overlay, Dwelling house character overlay,
-- neighbourhood plans. Same conventions as 031/032.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('has_adjoining_dwelling','BOOLEAN',NULL,NULL,'PROPERTY_DATA','At least one adjoining lot has a dwelling house', NULL),
 ('adjoining_lot_area_m2','NUMBER','m2',NULL,'PROPERTY_DATA','Area of the adjoining lot on the boundary being tested', 'Cadastre'),
 ('adjoining_btb_wall_matched','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The proposed wall matches the extent of an existing built-to-boundary wall on the adjoining lot', NULL),
 ('adjoining_owner_does_not_object','BOOLEAN',NULL,NULL,'USER_DECLARATION','The registered owner of the adjoining premises does not object to the reduced setback', NULL),
 ('pre1946_neighbour_avg_front_setback_m','NUMBER','m',NULL,'PROPERTY_DATA','Average front setback of the nearest residential buildings built in 1946 or earlier fronting the same street', 'Needs building age data'),
 ('roofed_area_m2','NUMBER','m2',NULL,'DESIGN_INPUT','Roofed area of the structure', NULL);

-- ------------------------------------------------ Small lot code, section A (180 m2 to under 450 m2)
SELECT define_rule($r${
 "rule_id": "BCC.C.SL_FRONT_PRIMARY", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.FRONTAGE", "title": "Small lot: primary street setback 6 m / least adjoining setback (min 3 m) / 3 m if no adjoining house",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "=", "args": [{"var": "has_adjoining_dwelling"}, false]}, "then": 3.0},
    {"if": {"op": ">=", "args": [{"op": "min_of", "args": [{"var": "adjoining_road_setbacks_m"}]}, 6]}, "then": 6.0}],
   "else": {"op": "max", "args": [3.0, {"op": "min_of", "args": [{"var": "adjoining_road_setbacks_m"}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "sl_front_setback_primary", "role": "PRIMARY",
              "quote": "on the primary street frontage: - 6m where all adjoining dwelling houses have a setback of 6m or more; or - the same as the least setback, but not less than 3m, of an adjoining dwelling house where that dwelling house has a setback less than 6m; or - 3m where there is no adjoining dwelling house"}],
 "interpretation_notes": "Needs neighbour data (adjoining setbacks) — MANUAL_REVIEW until supplied. Garages additionally need 5.5 m (BCC.C.SL_GARAGE_STREET_5_5). 'Small lot' also includes a rear lot under 600 m2 excluding the access way — not derived by the POC. Character residential included because AO5 sits in the small-lot code that applies to the residential zones; the researcher's zone list named LDR/LMR/MDR — confirm CR.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SL_FRONT_PRIMARY@2026-09-18', 'BCC.sl_front_setback_primary');
SELECT alt_overrides('BCC.C.SL_FRONT_PRIMARY@2026-09-18', ARRAY['QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.FRONTAGE_NEIGHBOURS'], 'Table 1.6.1 item 10: alternative to QDC P1.');

SELECT define_rule($r${
 "rule_id": "BCC.C.SL_SIDE_HABITABLE", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SIDE", "title": "Small lot: side setback 1 m (habitable spaces; also the default for non-habitable spaces outside the 0.5 m allowance)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "sl_side_setback", "role": "PRIMARY", "quote": "Development results in a minimum side boundary setback that is: - 1m for habitable spaces; or - 0.5m and a maximum height of 3.5m for non-habitable spaces only for a maximum length of: ..."}],
 "interpretation_notes": "AO6 lists alternatives; for a non-habitable structure that does not meet the 0.5 m or 0 m limbs, the 1 m limb is treated as the governing default (conservative reading).",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SL_SIDE_HABITABLE@2026-09-18', 'BCC.sl_side_setback');
SELECT alt_overrides('BCC.C.SL_SIDE_HABITABLE@2026-09-18', ARRAY['QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1 item 11: alternative to QDC P2.');

SELECT define_rule($r${
 "rule_id": "BCC.C.SL_SIDE_NONHABITABLE_LDR_CR", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SIDE", "title": "Small lot (LDR, CR): non-habitable spaces 0.5 m from side boundary, max 3.5 m high, max 9 m long",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0.5, "unit": "m",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}, {"fact": "structure_height_m", "op": "<=", "value": 3.5},
                 {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 9}]],
 "sources": [{"key": "sl_side_setback", "role": "PRIMARY", "quote": "0.5m and a maximum height of 3.5m for non-habitable spaces only for a maximum length of: ... 9m, where in the Low density residential zone or the Character residential zone"}],
 "interpretation_notes": "'maximum length' read as the length of the non-habitable structure along that side boundary.",
 "effective_from": "2026-09-18"}$r$);
SELECT define_rule($r${
 "rule_id": "BCC.C.SL_SIDE_NONHABITABLE_LMR_MDR", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SIDE", "title": "Small lot (LMR, MDR): non-habitable spaces 0.5 m from side boundary, max 3.5 m high, max 15 m long",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0.5, "unit": "m",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}, {"fact": "structure_height_m", "op": "<=", "value": 3.5},
                 {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 15}]],
 "sources": [{"key": "sl_side_setback", "role": "PRIMARY", "quote": "0.5m and a maximum height of 3.5m for non-habitable spaces only for a maximum length of: - 15m, where located in the Low-medium density residential zone, Medium density residential zone or High density residential zone"}],
 "effective_from": "2026-09-18"}$r$);
SELECT relate(rv, 'BCC.C.SL_SIDE_HABITABLE@2026-09-18', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM')
FROM unnest(ARRAY['BCC.C.SL_SIDE_NONHABITABLE_LDR_CR@2026-09-18','BCC.C.SL_SIDE_NONHABITABLE_LMR_MDR@2026-09-18']) rv;

SELECT define_rule($r${
 "rule_id": "BCC.C.SL_SIDE_ZERO", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Small lot: 0 m side setback where matching an adjoining built-to-boundary wall, or the adjoining lot is 300 m2 or less (not Character precinct)",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}, {"fact": "adjoining_btb_wall_matched", "op": "IS_TRUE"}],
                [{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}, {"fact": "adjoining_lot_area_m2", "op": "<=", "value": 300}]],
 "sources": [{"key": "sl_side_zero_setback", "role": "PRIMARY", "quote": "0m where: - matching the extent of an existing built to boundary wall on the adjoining property; or - the adjoining property is 300m2 or less and in the Residential zone category other than in the Character zone precinct of the Character residential zone"}],
 "interpretation_notes": "The 'adjoining property is 300m2 or less' limb excludes the Character zone precinct of the Character residential zone — check that for the adjoining lot. Two further limbs (narrow lots <= 7.5 m wide; owner consent in LDR) are in BCC.C.SL_SIDE_ZERO_CONSENT / not encoded.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SL_SIDE_ZERO@2026-09-18', 'BCC.sl_side_zero_setback');
SELECT define_rule($r${
 "rule_id": "BCC.C.SL_SIDE_ZERO_CONSENT", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Small lot in LDR (average width > 7.5 m): 0 m for non-habitable spaces up to 3 m high and 9 m long if the neighbour does not object",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}, {"fact": "lot_width_m", "op": ">", "value": 7.5},
                 {"fact": "structure_height_m", "op": "<=", "value": 3.0}, {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 9},
                 {"fact": "adjoining_owner_does_not_object", "op": "IS_TRUE"}]],
 "sources": [{"key": "sl_side_zero_setback", "role": "PRIMARY", "quote": "on a lot with an average width of more than 7.5m in the Low density residential zone or the Infill housing zone precinct of the Character residential zone where the registered owner of the adjoining premises does not object to a setback less than AO6(b) but only for non-habitable spaces, a maximum height of 3m and a maximum length of 9m"}],
 "interpretation_notes": "Uses estimated lot width for 'average width'. Infill housing zone precinct of the Character residential zone also qualifies — precinct not in the dataset yet.",
 "effective_from": "2026-09-18"}$r$);
SELECT relate(rv, 'BCC.C.SL_SIDE_HABITABLE@2026-09-18', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM')
FROM unnest(ARRAY['BCC.C.SL_SIDE_ZERO@2026-09-18','BCC.C.SL_SIDE_ZERO_CONSENT@2026-09-18']) rv;

SELECT define_rule($r${
 "rule_id": "BCC.C.SL_REAR", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.REAR", "title": "Small lot: rear setback 6 m (lot deeper than 25 m) or 3 m / 4.5 m by height (lot 25 m deep or less) — applies to all buildings and structures",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "average_lot_depth_m"}, 25]}, "then": 6.0},
                                  {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 3.0}], "else": 4.5},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "sl_rear_setback", "role": "PRIMARY", "quote": "Development results in a minimum rear boundary setback that is: - 6m, where on a lot with an average depth of more than 25m; or - on a lot with an average depth of 25m or less: - 3m, for a part of a building or structure up to 4.5m high; - 4.5m, for a part of a building or structure over 4.5m high."}],
 "interpretation_notes": "No built-to-boundary concession for Class 10a at the rear on small lots (stricter than QDC A2(d)). Average depth is estimated from the parcel outline.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SL_REAR@2026-09-18', 'BCC.sl_rear_setback');
SELECT alt_overrides('BCC.C.SL_REAR@2026-09-18', ARRAY['QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2a.POOL_SIDE_REAR','QDC11.A2e.POOL_WITHIN_CLEARANCE'], 'Table 1.6.1 item 11: alternative to QDC P2 (rear).');

SELECT define_rule($r${
 "rule_id": "BCC.C.SL_SITE_COVER", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SITE_COVER", "title": "Small lot: site cover 50% (400 m2+), 60% (300-400), 70% (200-300), 80% (under 200)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "unit": "%",
 "value": {"op": "case", "when": [{"if": {"op": ">=", "args": [{"var": "lot_area_m2"}, 400]}, "then": 50},
                                  {"if": {"op": ">=", "args": [{"var": "lot_area_m2"}, 300]}, "then": 60},
                                  {"if": {"op": ">=", "args": [{"var": "lot_area_m2"}, 200]}, "then": 70}], "else": 80},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"key": "sl_site_cover", "role": "PRIMARY", "quote": "Development results in a maximum site cover of: - 50% where the lot is 400m2 or more; or - 60% where the lot is 300m2 or more and less than 400m2; or - 70% where the lot is 200m2 or more and less than 300m2; or - 80% where the lot is less than 200m2."}],
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SL_SITE_COVER@2026-09-18', 'BCC.sl_site_cover');
SELECT alt_overrides('BCC.C.SL_SITE_COVER@2026-09-18', ARRAY['QDC11.A3.SITE_COVER'], 'Table 1.6.1 item 12: alternative to QDC P3.');

SELECT define_rule($r${
 "rule_id": "BCC.C.SL_HEIGHT", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "HEIGHT.BUILDING", "title": "Small lot (LDR, CR, LMR 2-storey mix): height 7.5 m at side/rear walls rising at no more than 30 degrees to 9.5 m, 2 storeys",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 9.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}, {"level": "PRECINCT", "precinct": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL/2_STOREY_MIX"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"key": "sl_max_height_low_density", "role": "PRIMARY", "quote": "results in a maximum building height of 7.5m above ground level at side and rear walls, increasing at no more than 30 degrees to a maximum building height of 9.5m above ground level and: - 2 storeys"}],
 "interpretation_notes": "Only the 9.5 m maximum is encoded; the 7.5 m-at-the-wall / 30 degree envelope is a 3-D test for the geometry layer. Class 10a under 7.5 m always satisfies it.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SL_HEIGHT@2026-09-18', 'BCC.sl_max_height_low_density');
SELECT alt_overrides('BCC.C.SL_HEIGHT@2026-09-18', ARRAY['QDC11.A4.BUILDING_HEIGHT'], 'Table 1.6.1 item 6: s32(b) standard for QDC P4.');

-- ------------------------------------------------ Traditional building character (design) overlay
SELECT define_rule($r${
 "rule_id": "BCC.C.TBC_FRONT_SETBACK_AVERAGE", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.FRONTAGE", "title": "Character overlay (LMR, CR zones): front setback within 20% of the average of nearby pre-1946 houses (excl. eaves, stairs, garage)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "*", "args": [0.8, {"var": "pre1946_neighbour_avg_front_setback_m"}]},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"},
            {"level": "OVERLAY", "overlay": "BCC:OV:TRADITIONAL_BUILDING_CHARACTER_OVERLAY_NOT_LOCAL_CHARACTER_SIGNIFICANCE_SUB_CATEGORY"}],
 "subjects": ["CLASS_1", "CLASS_10A", {"id": "GARAGE", "exclude": true}],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "tbc_front_setback_average", "role": "PRIMARY", "quote": "Development for a building which is not on a rear lot is set back from any road alignment, excluding eaves, awnings, stairs and garage, within 20% of the average front setback of the nearest residential buildings constructed in 1946 or earlier fronting the same street."}],
 "interpretation_notes": "'Within 20%' is a band: setback must be between 0.8x and 1.2x the average. The minimum (0.8x) is encoded; the 1.2x maximum is noted for the geometry layer. Identifying pre-1946 houses needs building-age data => not automatable. Not a rear lot.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.TBC_FRONT_SETBACK_AVERAGE@2026-09-18', 'BCC.tbc_front_setback_average');
SELECT alt_overrides('BCC.C.TBC_FRONT_SETBACK_AVERAGE@2026-09-18', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1a.ROAD_SETBACK_NEIGHBOURS','QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.FRONTAGE_NEIGHBOURS'], 'Table 1.6.1 item 10: TBC overlay AO1.2 is an alternative provision to QDC P1.');

SELECT define_rule($r${
 "rule_id": "BCC.C.TBC_GARAGE_POSITION", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "GARAGE.FRONTAGE", "title": "Character overlay (LMR, CR zones): garage set back in a position similar to garages of nearby pre-1946 houses",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_GARAGE_CARPORT", "operator": ">=", "unit": "m",
 "value": {"op": "unencoded", "text": "in a position similar to garages located on sites of dwelling houses constructed in 1946 or earlier located nearby in the street"},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"},
            {"level": "OVERLAY", "overlay": "BCC:OV:TRADITIONAL_BUILDING_CHARACTER_OVERLAY_NOT_LOCAL_CHARACTER_SIGNIFICANCE_SUB_CATEGORY"}],
 "subjects": ["GARAGE"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "tbc_garage_setback", "role": "PRIMARY"}],
 "interpretation_notes": "Qualitative — always manual review. It is an alternative provision (Table 1.6.1 item 10), so the QDC garage setback is displaced.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.TBC_GARAGE_POSITION@2026-09-18', 'BCC.tbc_garage_setback');
SELECT alt_overrides('BCC.C.TBC_GARAGE_POSITION@2026-09-18', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.6.1 item 10.');

SELECT define_rule($r${
 "rule_id": "BCC.C.TBC_CARPORT_FORWARD_ACCEPTED", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "GARAGE.OPENING_WIDTH", "title": "Character overlay: carport between the house and the front boundary needs no planning approval only if total width <= lesser of 6 m and 50% of average lot width",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "GARAGE_OPENING_WIDTH_FACING_STREET", "operator": "<=", "unit": "m",
 "value": {"op": "min", "args": [6.0, {"op": "*", "args": [0.5, {"var": "lot_width_m"}]}]},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "OVERLAY", "overlay": "BCC:OV:TRADITIONAL_BUILDING_CHARACTER_OVERLAY_NOT_LOCAL_CHARACTER_SIGNIFICANCE_SUB_CATEGORY"},
            {"level": "LOCAL_PLAN", "local_plan": "BCC:NP_SHERWOOD_GRACEVILLE", "exclude": true}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "in_front_of_main_building_line", "op": "IS_TRUE"}]],
 "sources": [{"key": "pad_tbc_outbuildings_carports_pools", "role": "PRIMARY", "quote": "a carport: - if located: ... between the building and front boundary, where a maximum total width of 6m or 50% of the average width of the lot, excluding eaves, whichever is the lesser; - if not in the Sherwood-Graceville district neighbourhood plan area or the Local character significance sub-category of the Traditional building character overlay"}],
 "interpretation_notes": "Planning category (Table 5.3.4.1), not a building rule: within the limit the carport needs no planning approval; over it, planning approval (code assessment) is needed. Uses estimated lot width. A carport, garage or shed at the rear of the house is also prescribed accepted development.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.TBC_CARPORT_FORWARD_ACCEPTED@2026-09-18', 'BCC.pad_tbc_outbuildings_carports_pools');

SELECT define_rule($r${
 "rule_id": "BCC.C.TBC_LOCAL_CHARACTER_CARPORT", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "GARAGE.OPENING_WIDTH", "title": "Character overlay, Local character significance: car parking forward of the house only as an open carport max 3.5 m wide",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "GARAGE_OPENING_WIDTH_FACING_STREET", "operator": "<=", "value": 3.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "OVERLAY", "overlay": "BCC:OV:TRADITIONAL_BUILDING_CHARACTER_OVERLAY_LOCAL_CHARACTER_SIGNIFICANCE_SUB_CATEGORY"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "in_front_of_main_building_line", "op": "IS_TRUE"}]],
 "sources": [{"key": "tbc_local_character_carport", "role": "PRIMARY", "quote": "Development for a garage where located forward of the front facade of a dwelling house consists of a carport with a maximum width of 3.5m and: - is open on all sides; - has no gates or roller doors; ... - has a maximum driveway crossover width of 3.5m."}],
 "interpretation_notes": "Also requires open on all sides, no gates/roller doors and a sympathetic roof line (not encoded). Assessment benchmark for assessable development (overlay makes house building work code assessable).",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.TBC_LOCAL_CHARACTER_CARPORT@2026-09-18', 'BCC.tbc_local_character_carport');

-- ------------------------------------------------ Dwelling house character overlay (small lots)
SELECT define_rule($r${
 "rule_id": "BCC.C.DHC_SMALL_LOT_SHED", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "OUTBUILDING.SIZE", "title": "Dwelling house character overlay, small lot: one shed outside the building envelope needs no planning approval only if roofed area <= 10 m2 and height <= 3 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "value": 10, "unit": "m2",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "OVERLAY", "overlay": "BCC:OV:DWELLING_HOUSE_CHARACTER_OVERLAY"}],
 "subjects": ["SHED"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}]],
 "sources": [{"key": "pad_dhc_small_lot_minor_structures", "role": "PRIMARY", "quote": "1 shed (maximum roofed area 10m2 and maximum height 3m)"}],
 "interpretation_notes": "Applies only to building work OUTSIDE the small-lot code building envelope — whether the shed is outside the envelope depends on the design => manual. Limits: patio/gazebo 16 m2 x 3 m; shade structure over a pool 10 m2 x 3 m; gatehouse 3 m2 x 3 m; single carport 6 x 3 m; double carport 6 x 6 m (lot 180 m2+), 2 m from front, 1.5 m from side.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.DHC_SMALL_LOT_SHED@2026-09-18', 'BCC.pad_dhc_small_lot_minor_structures');

-- ------------------------------------------------ Neighbourhood plans
SELECT define_rule($r${
 "rule_id": "BCC.C.NP_SHERWOOD_WESTSIDE_REAR", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.REAR", "title": "Sherwood-Graceville NP, Westside character precinct: rear setback the lesser of 10 m and 25% of lot depth",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "unit": "m",
 "value": {"op": "min", "args": [10.0, {"op": "*", "args": [0.25, {"var": "average_lot_depth_m"}]}]},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "BCC:NP_SHERWOOD_GRACEVILLE/NPP-001"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "np_sherwood_westside_rear_setback", "role": "PRIMARY", "quote": "Development has a minimum rear boundary setback of 10m or 25% of the depth of the lot, whichever is less, in accordance with Figure d."}],
 "interpretation_notes": "'Development' — whether this reaches Class 10a outbuildings needs council confirmation (Figure d not held) => manual.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.NP_SHERWOOD_WESTSIDE_REAR@2026-09-18', 'BCC.np_sherwood_westside_rear_setback');
SELECT alt_overrides('BCC.C.NP_SHERWOOD_WESTSIDE_REAR@2026-09-18', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1 item 11.');

SELECT define_rule($r${
 "rule_id": "BCC.C.NP_NEW_FARM_LMR_REAR_6", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.REAR", "title": "New Farm & Teneriffe Hill NP, Low-medium density living precinct: rear setback 6 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "BCC:NP_NEW_FARM_TENERIFFE/NPP-002"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "np_newfarm_lmr_rear_setback", "role": "PRIMARY", "quote": "Development has a minimum setback of 6m from the rear boundary."}],
 "interpretation_notes": "As for the NPP-001 rule: 'development' reaching Class 10a needs confirmation.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.NP_NEW_FARM_LMR_REAR_6@2026-09-18', 'BCC.np_newfarm_lmr_rear_setback');
SELECT alt_overrides('BCC.C.NP_NEW_FARM_LMR_REAR_6@2026-09-18', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1 item 11.');

-- Garage/carport width rules carry no boundary condition: test them on the road frontage only
SELECT restrict_boundary(rv, ARRAY['PRIMARY_FRONTAGE','SECONDARY_FRONTAGE_ROAD'])
FROM unnest(ARRAY['BCC.C.TBC_CARPORT_FORWARD_ACCEPTED@2026-09-18','BCC.C.TBC_LOCAL_CHARACTER_CARPORT@2026-09-18']) rv;
