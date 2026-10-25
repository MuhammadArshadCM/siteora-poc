-- =============================================================================
-- Curated council rules, batch 2 (9 Oct 2026): main residential and
-- rural-residential siting rules for Class 10a. Same conventions as 031.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('boundary_faces_south_or_west','BOOLEAN',NULL,NULL,'GEOMETRY_DERIVED','The boundary being tested is the southern or western boundary of the lot', 'Boundary bearing'),
 ('btb_max_single_part_length_m','NUMBER','m',NULL,'GEOMETRY_DERIVED','Longest single part of the built-to-boundary wall along the boundary', NULL),
 ('is_non_habitable','BOOLEAN',NULL,NULL,'DESIGN_INPUT','The building/space is non-habitable (e.g. Class 10a)', NULL),
 ('secondary_frontage_opposite_primary','BOOLEAN',NULL,NULL,'GEOMETRY_DERIVED','The secondary street frontage is opposite the primary street frontage (through lot)', NULL),
 ('secondary_road_reserve_width_m','NUMBER','m',NULL,'PROPERTY_DATA','Road reserve width of the secondary street frontage', NULL),
 ('secondary_road_is_minor','BOOLEAN',NULL,NULL,'PLANNING_DATA','The secondary street is a minor road (scheme road hierarchy)', NULL),
 ('adjoins_revetment_wall','BOOLEAN',NULL,NULL,'PROPERTY_DATA','A lot boundary adjoins a revetment wall', NULL),
 ('wall_is_built_to_boundary','BOOLEAN',NULL,NULL,'DESIGN_INPUT','The wall is a built-to-boundary or dividing wall', NULL),
 ('distance_to_adjoining_window_or_wall_m','NUMBER','m',NULL,'PROPERTY_DATA','Distance from the proposed wall to any window or wall on the adjoining lot (existing or approved)', NULL);

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, boundary_selector, vertical_projection, evaluate_per_part, notes) VALUES
 ('SEPARATION_TO_ADJOINING_OPENING','MIN_HORIZONTAL_DISTANCE','BUILT_TO_BOUNDARY_WALL','ADJOINING_WINDOW_OR_WALL',NULL,true,false,'Ipswich RO2.3 / AO2.2.2.');


-- ================================================================== LOGAN
SELECT define_rule($r${
 "rule_id": "LCC.C.SITE_COVER_LDR_SMALL_ACREAGE", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SITE_COVER", "title": "LDR Small acreage precinct: site cover <= 35%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 35, "unit": "%",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}, {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/SMALL_ACREAGE"}],
 "subjects": ["ANY"], "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}]],
 "sources": [{"key": "dh_ao3_site_cover_ldr_small_acreage", "role": "PRIMARY", "quote": "b. 35 percent in the Low density residential zone - Small acreage precinct"}],
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.SITE_COVER_LDR_SMALL_ACREAGE@2025-07-01', 'LCC.dh_ao3_site_cover_ldr_small_acreage');
SELECT alt_overrides('LCC.C.SITE_COVER_LDR_SMALL_ACREAGE@2025-07-01', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.6.1: PO3/AO3 alternative site cover.');

SELECT define_rule($r${
 "rule_id": "LCC.C.SITE_COVER_LDR_ACREAGE", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SITE_COVER", "title": "LDR Acreage precinct: site cover <= 20%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 20, "unit": "%",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}, {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/ACREAGE"}],
 "subjects": ["ANY"], "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}]],
 "sources": [{"key": "dh_ao3_site_cover_ldr_acreage", "role": "PRIMARY", "quote": "c. 20 percent in the Low density residential zone - Acreage precinct"}],
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.SITE_COVER_LDR_ACREAGE@2025-07-01', 'LCC.dh_ao3_site_cover_ldr_acreage');
SELECT alt_overrides('LCC.C.SITE_COVER_LDR_ACREAGE@2025-07-01', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.6.1: PO3/AO3 alternative site cover.');

SELECT define_rule($r${
 "rule_id": "LCC.C.ROAD_CLEARANCE_4M_LMDR", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.FRONTAGE", "title": "Low-medium density residential: road boundary clearance >= 4 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 4.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}, {"level": "ZONE", "zone": "LCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "dh_ao4b_road_clearance_lmdr_4m", "role": "PRIMARY", "quote": "b. has a minimum road boundary clearance of 4 metres in the Low-medium density residential zone"}],
 "interpretation_notes": "'road boundary clearance' applies to every road frontage. Carport concession AO4(a) relaxes it.",
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.ROAD_CLEARANCE_4M_LMDR@2025-07-01', 'LCC.dh_ao4b_road_clearance_lmdr_4m');
SELECT alt_overrides('LCC.C.ROAD_CLEARANCE_4M_LMDR@2025-07-01', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.SIDE_TO_CORNER_STREET'], 'Table 1.6.1: PO4/AO4 alternative boundary clearance.');

SELECT define_rule($r${
 "rule_id": "LCC.C.ROAD_CLEARANCE_10M", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.FRONTAGE", "title": "Emerging community, LDR Acreage/Small acreage, listed Rural residential precincts: road boundary clearance >= 10 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"},
            {"level": "ZONE", "zone": "LCC:EMERGING_COMMUNITY"},
            {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/ACREAGE"},
            {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/SMALL_ACREAGE"},
            {"level": "PRECINCT", "precinct": "LCC:RURAL_RESIDENTIAL/CARBROOK"},
            {"level": "PRECINCT", "precinct": "LCC:RURAL_RESIDENTIAL/COTTAGE_RURAL"},
            {"level": "PRECINCT", "precinct": "LCC:RURAL_RESIDENTIAL/PARK_LIVING"},
            {"level": "PRECINCT", "precinct": "LCC:RURAL_RESIDENTIAL/PARK_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "dh_ao4c_road_clearance_10m", "role": "PRIMARY"}],
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.ROAD_CLEARANCE_10M@2025-07-01', 'LCC.dh_ao4c_road_clearance_10m');
SELECT alt_overrides('LCC.C.ROAD_CLEARANCE_10M@2025-07-01', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.SIDE_TO_CORNER_STREET'], 'Table 1.6.1: PO4/AO4 alternative boundary clearance.');

SELECT define_rule($r${
 "rule_id": "LCC.C.SIDE_REAR_10M_RURAL", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.SIDE_REAR", "title": "Environmental management & conservation / Rural zone: side and rear 10 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}, {"level": "ZONE", "zone": "LCC:ENVIRONMENTAL_MANAGEMENT_AND_CONSERVATION"}, {"level": "ZONE", "zone": "LCC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "dh_ao5b_side_rear_10m", "role": "PRIMARY", "quote": "b. 10 metres in the: i. Environmental management and conservation zone ii. Rural zone. Note - AO5 does not apply to a domestic outbuilding, being a shed or detached garage, that complies with Link AO7.1(b)."},
             {"key": "dh_ao5a_side_rear_3m", "role": "SUPPLEMENTARY", "quote": "AO5 A Dual occupancy or Dwelling house has the following minimum side and rear boundary clearances:"}],
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.SIDE_REAR_10M_RURAL@2025-07-01', 'LCC.dh_ao5b_side_rear_10m');
SELECT alt_overrides('LCC.C.SIDE_REAR_10M_RURAL@2025-07-01', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1: PO5/AO5 alternative boundary clearance.');

-- Large outbuildings (> 150 m2): AO7.1(b) path
SELECT define_rule($r${
 "rule_id": "LCC.C.LARGE_OUTBUILDING_MAX_300", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "OUTBUILDING.SIZE", "title": "Domestic outbuildings over 150 m2 (rural-type zones in Table 9.3.2.3.2): cumulative floor area <= 300 m2",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "value": 300, "unit": "m2",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"},
            {"level": "ZONE", "zone": "LCC:EMERGING_COMMUNITY"}, {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/ACREAGE"},
            {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/SMALL_ACREAGE"}, {"level": "ZONE", "zone": "LCC:RURAL_RESIDENTIAL"},
            {"level": "ZONE", "zone": "LCC:ENVIRONMENTAL_MANAGEMENT_AND_CONSERVATION"}, {"level": "ZONE", "zone": "LCC:RURAL"}],
 "subjects": ["SHED", "GARAGE"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "is_attached_to_dwelling", "op": "IS_FALSE"},
                 {"fact": "total_outbuilding_floor_area_m2", "op": ">", "value": 150}]],
 "sources": [{"key": "dh_ao7_1b_large_outbuilding_max_300m2", "role": "PRIMARY", "quote": "iii. has a total maximum floor area of 300m2. Editor's note - The total maximum floor area is a cumulative total that applies across all domestic outbuildings on a premises."}],
 "interpretation_notes": "Only scoped to zones that Table 9.3.2.3.2 gives a clearance for. In urban zones the >150 m2 path has no clearance value (open issue), so the 150 m2 cap stays in force there.",
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.LARGE_OUTBUILDING_MAX_300@2025-07-01', 'LCC.dh_ao7_1b_large_outbuilding_max_300m2');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_version_id, type, basis_provision_id, verification, notes)
VALUES ('LCC.C.LARGE_OUTBUILDING_MAX_300@2025-07-01', 'LCC.C.OUTBUILDING_FLOOR_AREA_150@2025-07-01', 'RELAXES',
        pk('LCC_PLANNING_SCHEME_2015@2025-07-01', 'dh_ao7_1b_large_outbuilding_max_300m2'), 'VERIFIED_VERBATIM', 'AO7.1 (a) or (b).');

SELECT define_rule($r${
 "rule_id": "LCC.C.LARGE_OUTBUILDING_HEIGHT_5_5", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "HEIGHT.CLASS_10A", "title": "Domestic outbuildings where total floor area exceeds 150 m2: height <= 5.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 5.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}],
 "subjects": ["SHED", "GARAGE"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "is_attached_to_dwelling", "op": "IS_FALSE"},
                 {"fact": "total_outbuilding_floor_area_m2", "op": ">", "value": 150}]],
 "sources": [{"key": "dh_ao7_1b_large_outbuilding_height_5_5m", "role": "PRIMARY", "quote": "ii. has a maximum building height of 5.5 metres"}],
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.LARGE_OUTBUILDING_HEIGHT_5_5@2025-07-01', 'LCC.dh_ao7_1b_large_outbuilding_height_5_5m');

SELECT define_rule($r${
 "rule_id": "LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.SIDE_REAR", "title": "Large domestic outbuildings (> 150 m2): side and rear 6 m (EC, LDR Acreage/Small acreage, Rural residential)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"},
            {"level": "ZONE", "zone": "LCC:EMERGING_COMMUNITY"}, {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/ACREAGE"},
            {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/SMALL_ACREAGE"}, {"level": "ZONE", "zone": "LCC:RURAL_RESIDENTIAL"}],
 "subjects": ["SHED", "GARAGE"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "is_attached_to_dwelling", "op": "IS_FALSE"},
                 {"fact": "total_outbuilding_floor_area_m2", "op": ">", "value": 150}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "dh_t93232_large_outbuilding_clearance_6m", "role": "PRIMARY"}],
 "interpretation_notes": "Rural residential zone rows in the research are recorded zone-wide (no precinct split in Table 9.3.2.3.2).",
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M@2025-07-01', 'LCC.dh_t93232_large_outbuilding_clearance_6m');
SELECT relate('LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M@2025-07-01', 'LCC.C.SIDE_REAR_3M_ACREAGE@2025-07-01', 'OVERRIDES', NULL, NULL, 'VERIFIED_VERBATIM', 'AO5 note: AO5 does not apply to a domestic outbuilding complying with AO7.1(b).');

SELECT define_rule($r${
 "rule_id": "LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.SIDE_REAR", "title": "Large domestic outbuildings (> 150 m2): side and rear 20 m (EMC, Rural zone)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 20.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}, {"level": "ZONE", "zone": "LCC:ENVIRONMENTAL_MANAGEMENT_AND_CONSERVATION"}, {"level": "ZONE", "zone": "LCC:RURAL"}],
 "subjects": ["SHED", "GARAGE"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "is_attached_to_dwelling", "op": "IS_FALSE"},
                 {"fact": "total_outbuilding_floor_area_m2", "op": ">", "value": 150}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "dh_t93232_large_outbuilding_clearance_20m", "role": "PRIMARY"},
             {"key": "dh_t93232_large_outbuilding_clearance_6m", "role": "SUPPLEMENTARY", "quote": "Table 9.3.2.3.2 - Minimum side and rear boundary clearances for large domestic outbuildings"}],
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M@2025-07-01', 'LCC.dh_t93232_large_outbuilding_clearance_20m');
SELECT relate('LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M@2025-07-01', 'LCC.C.SIDE_REAR_10M_RURAL@2025-07-01', 'OVERRIDES', NULL, NULL, 'VERIFIED_VERBATIM', 'AO5 note: AO5 does not apply to a domestic outbuilding complying with AO7.1(b).');

-- Carport concession also relaxes the new road clearances
SELECT relate('LCC.C.CARPORT_TO_FRONT_BOUNDARY@2025-07-01', 'LCC.C.ROAD_CLEARANCE_4M_LMDR@2025-07-01', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM', 'AO4(b) exception: carport complying with AO4(a).');
SELECT relate('LCC.C.CARPORT_TO_FRONT_BOUNDARY@2025-07-01', 'LCC.C.ROAD_CLEARANCE_10M@2025-07-01', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM', 'AO4(c) exception: carport complying with AO4(a).');

-- ============================================================== GOLD COAST
SELECT define_rule($r${
 "rule_id": "CGC.C.RR_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Rural residential: front setback 6 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:RURAL_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_rr_front_setback", "role": "PRIMARY", "quote": "Front | - if roadside stall: 0m - otherwise: 6m | Side and rear | 3m"}],
 "interpretation_notes": "Roadside stall 0 m not relevant to Class 10a/pools. Buildings only (Table 1.5-1).",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.RR_FRONT_SETBACK@2026-09-29', 'CGC.gc_rr_front_setback');
SELECT alt_overrides('CGC.C.RR_FRONT_SETBACK@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code is the QDC alternative for buildings.');

SELECT define_rule($r${
 "rule_id": "CGC.C.RR_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural residential: side and rear setback 3 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:RURAL_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_rr_side_rear_setback", "role": "PRIMARY", "quote": "Side and rear | 3m"}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.RR_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_rr_side_rear_setback');
SELECT alt_overrides('CGC.C.RR_SIDE_REAR_SETBACK@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1: zone code is the QDC alternative for buildings.');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
SELECT 'CGC.C.RR_SIDE_REAR_SETBACK@2026-09-29', t, 'UNRESOLVED', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM',
       'Same question as Low density residential: whether QDC A2(d) Class 10a built-to-boundary survives a zone table that is silent on it.'
FROM unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;

SELECT define_rule($r${
 "rule_id": "CGC.C.RR_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "Rural residential (outside landscape and environment precinct): site cover <= 25%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 25, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:RURAL_RESIDENTIAL"},
            {"level": "PRECINCT", "precinct": "CGC:RURAL_RESIDENTIAL/LANDSCAPE_ENVIRONMENT", "exclude": true}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_rr_site_cover", "role": "PRIMARY", "quote": "Site cover does not exceed 25%."}],
 "effective_from": "2026-09-29"}$r$);
SELECT define_rule($r${
 "rule_id": "CGC.C.RR_LANDSCAPE_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "Rural residential landscape and environment precinct: site cover <= 15% (previously cleared areas only)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 15, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "PRECINCT", "precinct": "CGC:RURAL_RESIDENTIAL/LANDSCAPE_ENVIRONMENT"}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_rr_site_cover", "role": "PRIMARY", "quote": "Within the Rural residential landscape and environment precinct development is confined only to previously cleared areas and site cover does not exceed 15%."}],
 "interpretation_notes": "'Confined only to previously cleared areas' is a separate spatial test (vegetation data) — not encoded.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.RR_SITE_COVER@2026-09-29', 'CGC.gc_rr_site_cover');
SELECT alt_overrides(rv, ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.5-1: zone code is the QDC site cover alternative.')
FROM unnest(ARRAY['CGC.C.RR_SITE_COVER@2026-09-29','CGC.C.RR_LANDSCAPE_SITE_COVER@2026-09-29']) rv;

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_SMALL_LOT_FRONT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Low density residential small lot (< 400 m2): front 4.5 m to wall and balcony",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 4.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A_OTHER", "SHED", "DETACHED_LAUNDRY"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_ldr_small_lot_front_setback", "role": "PRIMARY", "quote": "Setbacks for Dwelling houses on small lots: ... Front | 4.5m to wall and balcony"}],
 "interpretation_notes": "Covered car parking has its own row (6 m from the frontage where vehicles access). Measured to wall/balcony, not OMP.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_SMALL_LOT_FRONT@2026-09-29', 'CGC.gc_ldr_small_lot_front_setback');
SELECT alt_overrides('CGC.C.LDR_SMALL_LOT_FRONT@2026-09-29', ARRAY['QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_SMALL_LOT_COVERED_PARKING", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "GARAGE.FRONTAGE", "title": "Low density residential small lot: covered car parking 6 m from the frontage where vehicles access the lot",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "gc_ldr_small_lot_covered_parking_setback", "role": "PRIMARY", "quote": "Covered car parking (not applicable to the rear lane access) | 1m behind front wall or balcony; and 6m from the frontage where vehicles access the lot."}],
 "interpretation_notes": "The '1m behind front wall or balcony' limb is relative to the house and is not encoded. Applies to the frontage that provides vehicle access only — engine must pick that boundary. Not applicable to rear-lane access.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_SMALL_LOT_COVERED_PARKING@2026-09-29', 'CGC.gc_ldr_small_lot_covered_parking_setback');
SELECT alt_overrides('CGC.C.LDR_SMALL_LOT_COVERED_PARKING@2026-09-29', ARRAY['QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_SMALL_LOT_SECONDARY", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Low density residential small lot: secondary frontage of corner lot 4 m (projections up to 2 m excluded)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 4.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "gc_ldr_small_lot_secondary_frontage", "role": "PRIMARY", "quote": "Secondary frontage of corner lot | 4m (not including projections up to 2m)"}],
 "interpretation_notes": "'not including projections up to 2m' read as: projections (eaves, balconies) may extend up to 2 m into the 4 m setback. Measure to the wall.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_SMALL_LOT_SECONDARY@2026-09-29', 'CGC.gc_ldr_small_lot_secondary_frontage');
SELECT alt_overrides('CGC.C.LDR_SMALL_LOT_SECONDARY@2026-09-29', ARRAY['QDC11.A1a.SIDE_TO_CORNER_STREET'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_SMALL_LOT_SIDE_REAR", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Low density residential small lot: side and rear to wall 1 / 1.5 / 2 m by height",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.0},
                                  {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 1.5}], "else": 2.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_ldr_small_lot_side_rear_setback", "role": "PRIMARY",
              "quote": "up to 4.5m | 1m to wall and balcony | 0.5m to outermost projection ... for the part between 4.5m - 7.5m | 1.5m to wall and balcony 1m to outermost projection | for that part exceeding 7.5m | 2m to wall and balcony 1.5m to outermost projection"}],
 "interpretation_notes": "Encodes the 'to wall and balcony' column. The OMP column (0.5 / 1 / 1.5 m) is a second test on eaves — not encoded as a separate rule yet.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_SMALL_LOT_SIDE_REAR@2026-09-29', 'CGC.gc_ldr_small_lot_side_rear_setback');
SELECT alt_overrides('CGC.C.LDR_SMALL_LOT_SIDE_REAR@2026-09-29', ARRAY['QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.5-1: the small-lot table sets its own Class 10 BTB terms, displacing A2(d).');

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_SMALL_LOT_CLASS10_BTB", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Low density residential small lot: Class 10 at 0 m on a southern or western boundary (<= 12 m, no part > 6 m, >= 1 m from neighbour's habitable window)",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]},
                 {"fact": "part_height_m", "op": "<=", "value": 4.5}, {"fact": "boundary_faces_south_or_west", "op": "IS_TRUE"},
                 {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 12}, {"fact": "btb_max_single_part_length_m", "op": "<=", "value": 6},
                 {"fact": "distance_to_adjoining_habitable_window_m", "op": ">=", "value": 1.0}]],
 "sources": [{"key": "gc_ldr_small_lot_class10_built_to_boundary", "role": "PRIMARY",
              "quote": "0m to class 10 buildings and/or non-habitable room where: - located along either a southern or western boundary; - a maximum length of 12m where no single part exceeds 6m in length - at least 1m separation from a habitable window of a neighbouring dwelling."}],
 "interpretation_notes": "'southern or western boundary' needs a bearing convention (e.g. boundary outward normal within 45° of S or W) — decide and document in the geometry layer.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_SMALL_LOT_CLASS10_BTB@2026-09-29', 'CGC.gc_ldr_small_lot_class10_built_to_boundary');
SELECT relate('CGC.C.LDR_SMALL_LOT_CLASS10_BTB@2026-09-29', 'CGC.C.LDR_SMALL_LOT_SIDE_REAR@2026-09-29', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM');

SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_COVERED_PARKING_FRONT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "GARAGE.FRONTAGE", "title": "Medium density residential: front setback for covered car parking 6 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_mdr_front_setback_covered_parking", "role": "PRIMARY", "quote": "Front for covered car parking (excluding a basement) | all | 6m"}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.MDR_COVERED_PARKING_FRONT@2026-09-29', 'CGC.gc_mdr_front_setback_covered_parking');
SELECT alt_overrides('CGC.C.MDR_COVERED_PARKING_FRONT@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK'], 'Table 1.5-1: zone code alternative (buildings).');

SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_GARAGE_CARPORT_HEIGHT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.CLASS_10A", "title": "Medium density residential: freestanding garages and carports <= 3.5 m high",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 3.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}, {"fact": "planning_assessment_required", "op": "IS_TRUE"}]],
 "sources": [{"key": "gc_mdr_garage_carport_height", "role": "PRIMARY", "quote": "RO4 Freestanding garages and carports do not exceed a height of 3.5m."}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.MDR_GARAGE_CARPORT_HEIGHT@2026-09-29', 'CGC.gc_mdr_garage_carport_height');

SELECT define_rule($r${
 "rule_id": "CGC.C.RIDGES_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "Ridges and significant hills protection overlay: site cover <= 40% (or the zone figure if lower)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 40, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "OVERLAY", "overlay": "CGC:OV:RIDGES_AND_SIGNIFICANT_HILLS_PROTECTION_OVERLAY"},
            {"level": "OVERLAY", "overlay": "CGC:OV:RIDGES_AND_SIGNIFICANT_HILLS_PROTECTION_OVERLAY_RIDGES_AND_SIGNIFICANT_HILLS_AREA"}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_ridges_site_cover", "role": "PRIMARY", "quote": "Site cover does not exceed 40% or that identified in the relevant zone, whichever is the lesser."}],
 "interpretation_notes": "'whichever is the lesser' is satisfied by SUPPLEMENTS: the zone site-cover rule still applies, so both limits are reported and the lower governs. Neighbourhood centre 60% branch not relevant to houses.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.RIDGES_SITE_COVER@2026-09-29', 'CGC.gc_ridges_site_cover');
SELECT alt_overrides('CGC.C.RIDGES_SITE_COVER@2026-09-29', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.5-1: Ridges and significant hills protection overlay code is a site cover alternative.');
SELECT relate('CGC.C.RIDGES_SITE_COVER@2026-09-29', 'CGC.C.LDR_SITE_COVER@2026-09-29', 'SUPPLEMENTS', NULL, NULL, 'VERIFIED_VERBATIM', 'Lesser of the two applies.');

-- =========================================================== SUNSHINE COAST
SELECT define_rule($r${
 "rule_id": "SCC.C.GARAGE_DOOR_WIDTH_6", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "GARAGE.OPENING_WIDTH", "title": "Residential zones: garage door width facing a street <= 6 m within any one plane",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "GARAGE_OPENING_WIDTH_FACING_STREET", "operator": "<=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"},
            {"level": "ZONE", "zone": "SCC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "SCC:HIGH_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:TOURIST_ACCOMMODATION"}],
 "subjects": ["GARAGE"],
 "sources": [{"key": "dh_garage_door_width_res", "role": "PRIMARY",
              "quote": "AO2.2 ... the total width of a garage door facing a street (and that is visible from the road frontage) does not exceed 6 metres within any one plane, with any additional garage door being set back a further 1 metre from the street frontage"}],
 "interpretation_notes": "Measure per facade plane; the 1 m step-back for additional doors is a geometric check not encoded separately.",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.GARAGE_DOOR_WIDTH_6@2024-01-23', 'SCC.dh_garage_door_width_res');

SELECT define_rule($r${
 "rule_id": "SCC.C.RR_LDLR_ROAD_10", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.FRONTAGE", "title": "Rural residential / Limited development (landscape residential): house incl. garage, carport, shed >= 10 m from any road frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}, {"level": "ZONE", "zone": "SCC:RURAL_RESIDENTIAL"},
            {"level": "ZONE", "zone": "SCC:LIMITED_DEVELOPMENT_LANDSCAPE_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "dh_rural_small_rr_ldlr_road_setback", "role": "PRIMARY",
              "quote": "the dwelling house (including any associated garage, carport or shed) is set back at least:- (a) 10 metres from any road frontage; ... Note--AO4.1 and AO4.2 alternative provisions to QDC."}],
 "interpretation_notes": "Limb (b) (small extensions within an existing house) is not relevant to detached Class 10a.",
 "effective_from": "2024-01-23"}$r$);
SELECT define_rule($r${
 "rule_id": "SCC.C.RURAL_SMALL_LOT_ROAD_10", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone, lot <= 2 ha: house incl. garage, carport, shed >= 10 m from any road frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}, {"level": "ZONE", "zone": "SCC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<=", "value": 20000}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "dh_rural_small_rr_ldlr_road_setback", "role": "PRIMARY"}],
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.RR_LDLR_ROAD_10@2024-01-23', 'SCC.dh_rural_small_rr_ldlr_road_setback');
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1b.CORNER_NOMINATED_FRONTAGE','QDC12.A1c.OPEN_CARPORT','QDC11.A1a.FRONTAGE_SETBACK'], 'Note--AO4.1 and AO4.2 alternative provisions to QDC.')
FROM unnest(ARRAY['SCC.C.RR_LDLR_ROAD_10@2024-01-23','SCC.C.RURAL_SMALL_LOT_ROAD_10@2024-01-23']) rv;

-- ================================================================== REDLAND
SELECT define_rule($r${
 "rule_id": "RCC.C.LDR3_SITE_COVER_30", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "SITE_COVER", "title": "LDR3 Point Lookout: site cover <= 30%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 30, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR3"}],
 "subjects": ["ANY"],
 "sources": [{"key": "ldr3_site_cover_30pct", "role": "PRIMARY", "quote": "AO11.1 Site cover does not exceed 30% of site area. Editor's note - This acceptable outcome is an alternative provision for the purposes of the Queensland Development Code."}],
 "effective_from": "2025-11-10"}$r$);
SELECT supersede_draft('RCC.C.LDR3_SITE_COVER_30@2025-11-10', 'RCC.ldr3_site_cover_30pct');
SELECT alt_overrides('RCC.C.LDR3_SITE_COVER_30@2025-11-10', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Editor''s note: alternative provision for the purposes of the QDC.');

SELECT define_rule($r${
 "rule_id": "RCC.C.LDR3_HEIGHT_8_5", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "HEIGHT.BUILDING", "title": "LDR3 Point Lookout (slope <= 15%): building height 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 8.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR3"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_slope_pct", "op": "<=", "value": 15}]],
 "sources": [{"key": "ldr3_building_height_8_5m", "role": "PRIMARY",
              "quote": "AO13.1 For slopes up to 15%, building height is 8.5m, except for roofs or pergolas covering decks. These may extend to 10m above ground level, providing: (1) they cover an area of no more than 10m2; (2) there is only one such covered areas on each detached building component on the site; and (3) the covered area is not enclosed by walls."}],
 "interpretation_notes": "The 10 m deck-roof exception is not encoded (needs per-component facts) — such roofs go to manual review. Slopes > 15%: QDC A4 applies (editor's note).",
 "effective_from": "2025-11-10"}$r$);
SELECT supersede_draft('RCC.C.LDR3_HEIGHT_8_5@2025-11-10', 'RCC.ldr3_building_height_8_5m');
SELECT alt_overrides('RCC.C.LDR3_HEIGHT_8_5@2025-11-10', ARRAY['QDC12.A4.BUILDING_HEIGHT','QDC11.A4.BUILDING_HEIGHT'], 'Editor''s note: alternative solution to the QDC for buildings on slopes < 15%.');

SELECT define_rule($r${
 "rule_id": "RCC.C.LDR5_REVETMENT_9M", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "SETBACK.WATERWAY", "title": "LDR5: development set back 9 m from a boundary adjoining a revetment wall (planning matter)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_WATERWAY", "operator": ">=", "value": 9.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR5"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "adjoins_revetment_wall", "op": "IS_TRUE"}]],
 "sources": [{"key": "ldr5_revetment_wall_setback_9m", "role": "PRIMARY",
              "quote": "AO7.1 Development is set back 9m from the property boundary adjoining a revetment wall. Editor's note - This acceptable outcome is not an alternative provision for the purposes of the Queensland Development Code. Where building work for a dwelling house/dual occupancy does not meet the acceptable solution, a code assessable Building Works Assessable Against the Planning Scheme application will be triggered."}],
 "interpretation_notes": "'Development' includes pools and unroofed structures (no exclusion stated, unlike AO9.1).",
 "effective_from": "2025-11-10"}$r$);
SELECT supersede_draft('RCC.C.LDR5_REVETMENT_9M@2025-11-10', 'RCC.ldr5_revetment_wall_setback_9m');

-- ================================================================== IPSWICH
SELECT define_rule($r${
 "rule_id": "ICC.C.NEW_SUBURBAN_GARAGE_DOOR_5_5", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "GARAGE.FRONTAGE", "title": "New Suburban precinct: garage door at least 5.5 m from the front boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "QHC_GARAGE_DOOR_TO_ACCESS_BOUNDARY", "operator": ">=", "value": 5.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "PRECINCT", "precinct": "ICC:LOW_DENSITY_RESIDENTIAL/NEW_SUBURBAN"}],
 "subjects": ["GARAGE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "dh_ro2_1_garage_door_setback_new_suburban", "role": "PRIMARY", "quote": "in the New Suburban precinct, where front boundary setbacks are a minimum of 3m and 5.5m to the garage door"}],
 "effective_from": "2026-07-01"}$r$);
SELECT supersede_draft('ICC.C.NEW_SUBURBAN_GARAGE_DOOR_5_5@2026-07-01', 'ICC.dh_ro2_1_garage_door_setback_new_suburban');
SELECT define_rule($r${
 "rule_id": "ICC.C.NEW_SUBURBAN_FRONT_3", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "SETBACK.FRONTAGE", "title": "New Suburban precinct: front boundary setback at least 3 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "PRECINCT", "precinct": "ICC:LOW_DENSITY_RESIDENTIAL/NEW_SUBURBAN"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "dh_ro2_1_front_setback_new_suburban", "role": "PRIMARY", "quote": "in the New Suburban precinct, where front boundary setbacks are a minimum of 3m and 5.5m to the garage door"}],
 "interpretation_notes": "Applies to Class 10a only through the SC1.1 dwelling house definition (includes domestic outbuildings).",
 "effective_from": "2026-07-01"}$r$);
SELECT supersede_draft('ICC.C.NEW_SUBURBAN_FRONT_3@2026-07-01', 'ICC.dh_ro2_1_front_setback_new_suburban');
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5.1: Dwelling House and Dual Occupancy Code is the QDC boundary clearance alternative.')
FROM unnest(ARRAY['ICC.C.NEW_SUBURBAN_GARAGE_DOOR_5_5@2026-07-01','ICC.C.NEW_SUBURBAN_FRONT_3@2026-07-01']) rv;

SELECT define_rule($r${
 "rule_id": "ICC.C.NEW_SUBURBAN_GARAGE_BTB", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "New Suburban precinct: garage may be built to boundary on one side, up to 9 m long",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "PRECINCT", "precinct": "ICC:LOW_DENSITY_RESIDENTIAL/NEW_SUBURBAN"}],
 "subjects": ["GARAGE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SIDE"}, {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 9}]],
 "sources": [{"key": "dh_ro2_2_garage_built_to_boundary_new_suburban", "role": "PRIMARY",
              "quote": "in the New Suburban precinct, where side boundaries are as per MP1.1, MP1.2 and MP1.3 with a built to boundary setback for a garage on one side, up to a length of 9m"}],
 "interpretation_notes": "'on one side' — only one side boundary per lot; the engine must check no other side already uses it. QDC side clearances otherwise continue to apply.",
 "effective_from": "2026-07-01"}$r$);
SELECT supersede_draft('ICC.C.NEW_SUBURBAN_GARAGE_BTB@2026-07-01', 'ICC.dh_ro2_2_garage_built_to_boundary_new_suburban');
SELECT relate('ICC.C.NEW_SUBURBAN_GARAGE_BTB@2026-07-01', 'QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM');
SELECT relate('ICC.C.NEW_SUBURBAN_GARAGE_BTB@2026-07-01', 'QDC11.A2a.SIDE_REAR_CLEARANCE@2010-03-26', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM');

SELECT define_rule($r${
 "rule_id": "ICC.C.BTB_WALL_SEPARATION", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "SEPARATION.WINDOW", "title": "Built-to-boundary or dividing wall: >= 0.9 m from a window or wall, >= 1.5 m from a habitable-room window",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SEPARATION_TO_ADJOINING_OPENING", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<", "args": [{"var": "distance_to_adjoining_habitable_window_m"}, 1.5]}, "then": 1.5}], "else": 0.9},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"},
            {"level": "ZONE", "zone": "ICC:LOW_DENSITY_RESIDENTIAL"}, {"level": "PRECINCT", "precinct": "ICC:LOW_DENSITY_RESIDENTIAL/NEW_SUBURBAN"},
            {"level": "ZONE", "zone": "ICC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "ICC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "ICC:HIGH_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "ICC:CHARACTER_RESIDENTIAL"},
            {"level": "ZONE", "zone": "ICC:TOWNSHIP"}, {"level": "ZONE", "zone": "ICC:EMERGING_COMMUNITY"}, {"level": "ZONE", "zone": "ICC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "wall_is_built_to_boundary", "op": "IS_TRUE"}]],
 "sources": [{"key": "dh_ro2_3_built_to_boundary_wall_separation", "role": "PRIMARY",
              "quote": "A built to boundary or dividing wall is not: within 900mm of a window or wall, or within 1500mm of a window to a habitable room*. * Windows or walls that are already constructed, or that are part of an existing approval."}],
 "interpretation_notes": "Two tests; encoded as one distance requirement that becomes 1.5 m when the nearest neighbouring opening is a habitable-room window. Needs neighbour building data => not automatable.",
 "effective_from": "2026-07-01"}$r$);
SELECT supersede_draft('ICC.C.BTB_WALL_SEPARATION@2026-07-01', 'ICC.dh_ro2_3_built_to_boundary_wall_separation');

-- ================================================================= BRISBANE
SELECT define_rule($r${
 "rule_id": "BCC.C.SL_SECONDARY_FRONTAGE_1_5", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Small lot (180-450 m2): secondary street frontage setback 1.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:RURAL_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:EMERGING_COMMUNITY"}, {"level": "ZONE", "zone": "BCC:TOWNSHIP"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "sl_secondary_frontage_setback", "role": "PRIMARY", "quote": "on a secondary street frontage: - 1.5m; or - 0m for non-habitable spaces up to 3m building height where ..."}],
 "interpretation_notes": "Garages additionally need 5.5 m (BCC.C.SL_GARAGE_STREET_5_5). Small-lot status for rear lots < 600 m2 must be derived separately.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SL_SECONDARY_FRONTAGE_1_5@2026-09-18', 'BCC.sl_secondary_frontage_setback');
SELECT alt_overrides('BCC.C.SL_SECONDARY_FRONTAGE_1_5@2026-09-18', ARRAY['QDC11.A1a.SIDE_TO_CORNER_STREET'], 'Table 1.6.1 item 10: alternative to QDC P1.');

SELECT define_rule($r${
 "rule_id": "BCC.C.SL_SECONDARY_FRONTAGE_0M_NONHABITABLE", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Small lot: 0 m to a narrow minor secondary street opposite the primary frontage, for non-habitable spaces up to 3 m high",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}, {"fact": "structure_height_m", "op": "<=", "value": 3.0},
                 {"fact": "secondary_frontage_opposite_primary", "op": "IS_TRUE"}, {"fact": "secondary_road_reserve_width_m", "op": "<=", "value": 8},
                 {"fact": "secondary_road_is_minor", "op": "IS_TRUE"}]],
 "sources": [{"key": "sl_secondary_frontage_setback", "role": "PRIMARY",
              "quote": "0m for non-habitable spaces up to 3m building height where the secondary street frontage is opposite to the primary street frontage and the road reserve of the secondary street frontage is 8m or less wide and a minor road"}],
 "interpretation_notes": "Class 10a is non-habitable by definition. Garages still need 5.5 m under AO5(c) ('in addition to ... a minimum of 5.5m street frontage setback for garages') — garage rule is not relaxed.",
 "effective_from": "2026-09-18"}$r$);
SELECT relate('BCC.C.SL_SECONDARY_FRONTAGE_0M_NONHABITABLE@2026-09-18', 'BCC.C.SL_SECONDARY_FRONTAGE_1_5@2026-09-18', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM');

SELECT define_rule($r${
 "rule_id": "BCC.C.SLB_SITE_COVER_55", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SITE_COVER", "title": "Lot under 180 m2: site cover <= 55% (or approved development footprint plan)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 55, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 180}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}]],
 "sources": [{"key": "slb_site_cover", "role": "PRIMARY", "quote": "AO19 Development has a maximum site cover: - of 55%; or - that is in accordance with an approved development footprint plan for the site."}],
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SLB_SITE_COVER_55@2026-09-18', 'BCC.slb_site_cover');
SELECT alt_overrides('BCC.C.SLB_SITE_COVER_55@2026-09-18', ARRAY['QDC11.A3.SITE_COVER'], 'Table 1.6.1 item 12: alternative to QDC P3 site cover.');

-- ============================================================= MORETON BAY
SELECT define_rule($r${
 "rule_id": "CMB.C.SUBURBAN_OUTBUILDING_FRONTAGES", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Suburban neighbourhood precinct: covered car parking and domestic outbuildings 5.4 m from primary and secondary street frontages",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.4, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"}],
 "subjects": ["GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "wall_height_m", "op": "<", "value": 4.5}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "mb_dh_t93114_suburban_front", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 4.5m || Min 3m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 0.5 || Refer to standard as in QDC || Refer to standard as in QDC || Min 4.5m"}],
 "interpretation_notes": "Column 'To covered car parking space and domestic outbuildings' = 5.4 m (primary and secondary street). For walls 4.5 m or higher that column is 'N/A' — tall outbuildings exceed RAD26 (4 m) anyway. Domestic outbuildings must also sit behind the main building line (RAD26(c), draft). Side/rear cells 'Refer to standard as in QDC' => QDC applies, no override.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.SUBURBAN_OUTBUILDING_FRONTAGES@2026-09-11', 'CMB.mb_dh_t93114_suburban_front');
SELECT alt_overrides('CMB.C.SUBURBAN_OUTBUILDING_FRONTAGES@2026-09-11', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.SIDE_TO_CORNER_STREET'], 'Table 1.6.1: Dwelling house code setbacks are QDC alternatives.');

SELECT define_rule($r${
 "rule_id": "CMB.C.SUBURBAN_LANE_0_5", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Suburban neighbourhood precinct: secondary frontage to a lane 0.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 0.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_LANE_PARKWAY"}]],
 "sources": [{"key": "mb_dh_t93114_suburban_secondary", "role": "PRIMARY", "quote": "Frontage Secondary to lane ... Min 0.5"}],
 "effective_from": "2026-09-11"}$r$);

SELECT define_rule($r${
 "rule_id": "CMB.C.SUBURBAN_COASTAL_NO_BTB_WALL", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Coastal communities / Suburban neighbourhood / Redcliffe Interim residential: built-to-boundary walls (within 200 mm) not permitted",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">", "value": 0.2, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/COASTAL_COMMUNITIES"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:REDCLIFFE_KIPPA_RING/INTERIM_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_dh_t93117_btb_coastal_suburban", "role": "PRIMARY",
              "quote": "Not permitted* ... *Note - Built to boundary walls are not permitted, however, reduced side and rear boundary clearances may be permitted as prescribed (e.g QDC)."},
             {"key": "mb_dh_rad4_btb_general", "role": "SUPPLEMENTARY",
              "quote": "setback from the side boundary: - if a plan of development provides for only one built to boundary wall on the one boundary, not more than 200mm"}],
 "interpretation_notes": "A built-to-boundary wall is one within 200 mm of the boundary (RAD4). The footnote keeps QDC reduced clearances (e.g. MP 1.2 A2(d)) available, so this SUPPLEMENTS A2(d): Class 10a may be closer than 1.5 m, but not within 200 mm. Operator '>' 0.2 m.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.SUBURBAN_COASTAL_NO_BTB_WALL@2026-09-11', 'CMB.mb_dh_t93117_btb_coastal_suburban');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, verification, notes)
SELECT 'CMB.C.SUBURBAN_COASTAL_NO_BTB_WALL@2026-09-11', t, 'SUPPLEMENTS', 'VERIFIED_VERBATIM',
       'Both apply: QDC reduced clearance permitted (footnote), but not within 200 mm (BTB wall).'
FROM unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;

SELECT define_rule($r${
 "rule_id": "CMB.C.OUTBUILDING_HEIGHT", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "HEIGHT.CLASS_10A", "title": "Domestic outbuildings: max height 4 m (mean 3.5 m); carport in front of main building line 3.3 m (mean 2.7 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "in_front_of_main_building_line"}]}, "then": 3.3}], "else": 4.0},
 "on_noncompliance": "MANUAL_REVIEW", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/COASTAL_COMMUNITIES"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/NEXT_GENERATION_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/URBAN_NEIGHBOURHOOD"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:REDCLIFFE_KIPPA_RING/INTERIM_RESIDENTIAL"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_dh_rad26_outbuilding_height", "role": "PRIMARY",
              "quote": "where in front of the main building line for a carport - have a maximum building height of 3.3m and a mean height not exceeding 2.7m; or - for all other instances - have a maximum building height of 4m and a mean height not exceeding 3.5m"}],
 "interpretation_notes": "Mean height limits (2.7 / 3.5 m) not encoded as a separate rule. Only carports may be in front of the main building line (RAD26(c)). Amenity and aesthetics matter => MANUAL_REVIEW on failure.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.OUTBUILDING_HEIGHT@2026-09-11', 'CMB.mb_dh_rad26_outbuilding_height');
