-- =============================================================================
-- Curated council rules: hand-encoded from the verbatim provisions loaded by
-- db/030_council_*.sql, reviewed against the quoted text, with proper scopes,
-- subjects, conditions and expressions. Each curated rule REPLACES its
-- auto-imported draft (which is marked SUPERSEDED).
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('planning_assessment_required','BOOLEAN',NULL,NULL,'ENGINE_DERIVED','The development is accepted-subject-to-requirements or assessable under the planning scheme for this lot (so zone/use code benchmarks apply as planning requirements)', 'From the scheme tables of assessment (levels_of_assessment provisions)'),
 ('dwelling_house_code_applies','BOOLEAN',NULL,NULL,'PLANNING_DATA','The council dwelling house code is the nominated requirement for this lot (e.g. Logan: land in a "residential area" on the Residential overlay)', NULL),
 ('total_outbuilding_floor_area_m2','NUMBER','m2',NULL,'GEOMETRY_DERIVED','Cumulative floor area of all domestic outbuildings (sheds/detached garages) on the premises, existing + proposed', NULL),
 ('total_outbuilding_roofed_area_m2','NUMBER','m2',NULL,'GEOMETRY_DERIVED','Combined roofed area of all domestic outbuildings, existing + proposed', NULL),
 ('in_front_of_main_building_line','BOOLEAN',NULL,NULL,'GEOMETRY_DERIVED','Structure is forward of the main building line', NULL),
 ('is_garage_under_main_roof','BOOLEAN',NULL,NULL,'DESIGN_INPUT','Garage is under the main roof of the dwelling house', NULL),
 ('adjoins_canal_or_lake','BOOLEAN',NULL,NULL,'PROPERTY_DATA','A lot boundary adjoins a canal, lake or artificial waterway/waterbody', NULL),
 ('pool_fence_transparency_pct','NUMBER','%',NULL,'DESIGN_INPUT','Visual transparency of pool fencing', NULL),
 ('development_footprint_exists','BOOLEAN',NULL,NULL,'PLANNING_DATA','A development footprint is identified for the lot (approval/plan of development)', NULL),
 ('carport_is_unenclosed','BOOLEAN',NULL,NULL,'DESIGN_INPUT','Carport is entirely unenclosed except where the rear attaches to a structure', NULL);

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, boundary_selector, vertical_projection, evaluate_per_part, notes) VALUES
 ('SCHEME_SETBACK_WATERWAY','MIN_HORIZONTAL_DISTANCE','PER_SCHEME_DEFINITION','BOUNDARY_ADJOINING_CANAL_OR_LAKE',NULL,true,false,NULL);


-- ============================================================== GOLD COAST
SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Low density residential: front setback 6 m (buildings; lots >= 400 m2)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_ldr_front_setback", "role": "PRIMARY", "quote": "Setback | Minimum distances measured in metres (m) | Front | 6m"},
             {"ref": "def Setback", "role": "DEFINITION"}],
 "interpretation_notes": "Alternative provision for BUILDINGS only (Table 1.5-1); structures (pools, unroofed decks) keep QDC setbacks. Applies whenever building work is assessed (dwelling house use on >= 400 m2 lots is Accepted with no requirements, but s33 alternative provisions bind building assessment regardless). Rear lots (3 m all boundaries) and small-lot table excluded. Secondary frontage on corner lots: standard table has only 'Front' — whether 6 m applies to both road frontages needs council confirmation.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_FRONT_SETBACK@2026-09-29', 'CGC.gc_ldr_front_setback');
SELECT alt_overrides('CGC.C.LDR_FRONT_SETBACK@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'City Plan Table 1.5-1: relevant zone code is the alternative to QDC boundary clearance for buildings.');

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Low density residential: side and rear setback by height (1.5 / 2 / +0.5 per 3 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.5},
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "part_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 400}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_ldr_side_rear_setback_height_tiered", "role": "PRIMARY",
              "quote": "Side and rear | Height | Setback | up to 4.5m | 1.5m | between 4.5m – 7.5m | 2m | exceeding 7.5m | an extra 0.5m is added for every 3m in height or part thereof over 7.5m"}],
 "interpretation_notes": "Unlike QDC MP 1.2 A2(d) and QHC Table 3, the standard table has NO built-to-boundary concession for Class 10a on lots >= 400 m2. Because s33(4) makes the QDC apply only to the extent the alternative provision does not, a shed on the side boundary appears to need a referral. Researcher flagged this for council/certifier confirmation; 'height' read as height of the part (QDC convention) — the table does not say.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_ldr_side_rear_setback_height_tiered');
SELECT alt_overrides('CGC.C.LDR_SIDE_REAR_SETBACK@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1 alternative boundary clearance (buildings).');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
SELECT 'CGC.C.LDR_SIDE_REAR_SETBACK@2026-09-29', t, 'UNRESOLVED', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM',
       'Does QDC A2(d) (Class 10a built to boundary) survive? s33(4): QDC applies only to the extent the alternative provision does not apply. The zone table sets side/rear setbacks for all buildings without a Class 10a concession, so A2(d) is arguably displaced; but A2(d) is a relaxation the table does not address. Confirm with City of Gold Coast.'
FROM unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "Low density residential: site cover <= 50%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 50, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_ldr_site_cover", "role": "PRIMARY", "quote": "AO2 Site cover does not exceed 50%."}, {"ref": "def Site cover", "role": "DEFINITION"}],
 "interpretation_notes": "Measured per the City Plan 'site cover' definition, not the QDC/QHC one.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_SITE_COVER@2026-09-29', 'CGC.gc_ldr_site_cover');
SELECT alt_overrides('CGC.C.LDR_SITE_COVER@2026-09-29', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.5-1 alternative site cover.');

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_HEIGHT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "Low density residential: building height 2 storeys and 9 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 9.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "sources": [{"key": "gc_ldr_building_height", "role": "PRIMARY"}],
 "interpretation_notes": "Storey limit (2, or partial third within 9 m) not encoded as a separate rule. Exceeding the Dwelling house overlay height makes the use impact assessable (planning track).",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_HEIGHT@2026-09-29', 'CGC.gc_ldr_building_height');
SELECT alt_overrides('CGC.C.LDR_HEIGHT@2026-09-29', ARRAY['QDC12.A4.BUILDING_HEIGHT','QDC11.A4.BUILDING_HEIGHT'], 'Table 1.5-1: alternative to QDC building height (P4).');

SELECT define_rule($r${
 "rule_id": "CGC.C.LDR_GARAGE_CARPORT_HEIGHT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.CLASS_10A", "title": "Low density residential: freestanding garages and carports <= 3.5 m high",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 3.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}, {"fact": "planning_assessment_required", "op": "IS_TRUE"}]],
 "sources": [{"key": "gc_ldr_garage_carport_height", "role": "PRIMARY", "quote": "RO4 Freestanding garages and carports do not exceed a height of 3.5m."}],
 "interpretation_notes": "Only a requirement where the zone code applies to the use (accepted subject to requirements: lots < 400 m2 or with a secondary dwelling; or assessable). Not listed as a QDC alternative for structures. Sheds are not mentioned.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.LDR_GARAGE_CARPORT_HEIGHT@2026-09-29', 'CGC.gc_ldr_garage_carport_height');

-- ================================================================== LOGAN
SELECT define_rule($r${
 "rule_id": "LCC.C.OUTBUILDING_FLOOR_AREA_150", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "OUTBUILDING.SIZE", "title": "Domestic outbuildings (sheds/detached garages): cumulative floor area <= 150 m2",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "value": 150, "unit": "m2",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}],
 "subjects": ["SHED", "GARAGE"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}]],
 "sources": [{"key": "dh_ao7_1a_outbuilding_total_floor_area_150", "role": "PRIMARY",
              "quote": "AO7.1 A single domestic outbuilding, being a shed or detached garage, or multiple domestic outbuildings, being sheds or detached garages: a. has a total maximum floor area of 150m2 ... Editor's note - The total maximum floor area is a cumulative total that applies across all domestic outbuildings on a premises."}],
 "interpretation_notes": "Measured value = total_outbuilding_floor_area_m2 (existing + proposed). Above 150 m2 the AO7.1(b) path (<= 300 m2, <= 5.5 m high, 6 m / 20 m clearances in rural-type zones) is a separate draft rule. Listed in Table 1.6.1 as an alternative provision; non-compliance makes the dwelling-house building work code assessable (accepted subject to requirements).",
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.OUTBUILDING_FLOOR_AREA_150@2025-07-01', 'LCC.dh_ao7_1a_outbuilding_total_floor_area_150');

SELECT define_rule($r${
 "rule_id": "LCC.C.CARPORT_TO_FRONT_BOUNDARY", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.FRONTAGE", "title": "Carport (<= 6 m x 6 m, <= 3.5 m high, unenclosed) may be built to the front boundary",
 "role": "RELAXATION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}, {"fact": "longest_side_m", "op": "<=", "value": 6},
                 {"fact": "structure_height_m", "op": "<=", "value": 3.5}, {"fact": "carport_is_unenclosed", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "dh_ao4a_carport_to_front_boundary", "role": "PRIMARY"}],
 "interpretation_notes": "'6 metres by 6 metres' encoded as longest side <= 6 m. Fixed 23 Oct 2026 (user report): the rule had no boundary_type condition, so it was a candidate on every boundary pass (side, rear, secondary), not only the front boundary AO4(a) actually names. 'Front boundary' is PRIMARY_FRONTAGE only — AO4(a) is narrower than the 'road boundary clearance' wording in AO4(b)-(d), which does cover PRIMARY_FRONTAGE + SECONDARY_FRONTAGE_ROAD (see LCC.C.ROAD_CLEARANCE_4M_LMDR etc.).",
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.CARPORT_TO_FRONT_BOUNDARY@2025-07-01', 'LCC.dh_ao4a_carport_to_front_boundary');
SELECT alt_overrides('LCC.C.CARPORT_TO_FRONT_BOUNDARY@2025-07-01', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.6.1: PO4/AO4 alternative boundary clearance.');

SELECT define_rule($r${
 "rule_id": "LCC.C.SITE_COVER_LDR_SMALL_LOT", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SITE_COVER", "title": "Low density residential - Small lot precinct: site cover <= 60%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 60, "unit": "%",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"}, {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/SMALL_LOT"}],
 "subjects": ["ANY"],
 "sources": [{"key": "dh_ao3_site_cover_ldr_small_lot", "role": "PRIMARY"}],
 "interpretation_notes": "Other precincts (Suburban etc.) have no AO3 value => QDC MP1.1/1.2 site cover applies via AO1.",
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.SITE_COVER_LDR_SMALL_LOT@2025-07-01', 'LCC.dh_ao3_site_cover_ldr_small_lot');
SELECT alt_overrides('LCC.C.SITE_COVER_LDR_SMALL_LOT@2025-07-01', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.6.1: PO3/AO3 alternative site cover.');

SELECT define_rule($r${
 "rule_id": "LCC.C.SIDE_REAR_3M_ACREAGE", "instrument_version": "LCC_PLANNING_SCHEME_2015@2025-07-01",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural residential / Emerging community / LDR Acreage & Small acreage: side and rear 3 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LOGAN"},
            {"level": "ZONE", "zone": "LCC:RURAL_RESIDENTIAL"}, {"level": "ZONE", "zone": "LCC:EMERGING_COMMUNITY"},
            {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/ACREAGE"}, {"level": "PRECINCT", "precinct": "LCC:LOW_DENSITY_RESIDENTIAL/SMALL_ACREAGE"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}, {"fact": "dwelling_house_code_applies", "op": "IS_TRUE"}]],
 "sources": [{"key": "dh_ao5a_side_rear_3m", "role": "PRIMARY"}],
 "interpretation_notes": "Note to AO5: does not apply to a shed/detached garage complying with AO7.1(b) (large outbuilding path with its own clearances).",
 "effective_from": "2025-07-01"}$r$);
SELECT supersede_draft('LCC.C.SIDE_REAR_3M_ACREAGE@2025-07-01', 'LCC.dh_ao5a_side_rear_3m');
SELECT alt_overrides('LCC.C.SIDE_REAR_3M_ACREAGE@2025-07-01', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1: PO5/AO5 alternative boundary clearance.');

-- ============================================================= MORETON BAY
SELECT define_rule($r${
 "rule_id": "CMB.C.RR_ROAD_SETBACK", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Rural residential: road boundary setback 6 m (incl. domestic outbuildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:RURAL_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_rr_rad48_road_setback", "role": "PRIMARY",
              "quote": "RAD48 Setbacks (including domestic outbuildings) comply with the following: - Road boundary - 6m ... Note - For building work associated with a dwelling house, this is an alternative provision to the QDC, part MP1.2, A1 (a), (b) and (c), A2 (a), (b) and (d) and is a concurrence agency issue. Note - This provision does not apply where a development footprint exists for a lot."}],
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.RR_ROAD_SETBACK@2026-09-11', 'CMB.mb_rr_rad48_road_setback');
SELECT alt_overrides('CMB.C.RR_ROAD_SETBACK@2026-09-11', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1b.CORNER_NOMINATED_FRONTAGE','QDC12.A1c.OPEN_CARPORT'], 'RAD48 note: alternative provision to QDC MP1.2 A1(a), (b) and (c).');

SELECT define_rule($r${
 "rule_id": "CMB.C.RR_SIDE_REAR_SETBACK", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural residential: side and rear setback by wall height (1.5 / 2 / 4 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "wall_height_m"}, 3.0]}, "then": 1.5},
                                  {"if": {"op": "<=", "args": [{"var": "wall_height_m"}, 4.5]}, "then": 2.0}], "else": 4.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:RURAL_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_rr_rad48_side_rear_setback", "role": "PRIMARY",
              "quote": "Side and rear boundary: Height of wall || Minimum setback from side or rear boundary ; 3m or less || 1.5m ; Greater than 3m to 4.5m || 2m ; Greater than 4.5m || 4m."}],
 "interpretation_notes": "Replaces QDC A2(d), so there is NO built-to-boundary concession for sheds in this zone. 'Wall height' is not defined in the scheme — QHC external-wall height used.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.RR_SIDE_REAR_SETBACK@2026-09-11', 'CMB.mb_rr_rad48_side_rear_setback');
SELECT alt_overrides('CMB.C.RR_SIDE_REAR_SETBACK@2026-09-11', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2b.NARROW_LOT_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE'], 'RAD48 note: alternative provision to QDC MP1.2 A2(a), (b) and (d).');

SELECT define_rule($r${
 "rule_id": "CMB.C.RR_OUTBUILDING_HEIGHT", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "HEIGHT.CLASS_10A", "title": "Rural residential: domestic outbuildings and free-standing carports/garages <= 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 4.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:RURAL_RESIDENTIAL"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_rr_rad47_height_dwelling_outbuilding", "role": "PRIMARY"}],
 "interpretation_notes": "Researcher records RAD47 as an express alternative provision.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.RR_OUTBUILDING_HEIGHT@2026-09-11', 'CMB.mb_rr_rad47_height_dwelling_outbuilding');

SELECT define_rule($r${
 "rule_id": "CMB.C.GR_SITE_COVER_50", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SITE_COVER", "title": "General residential (Coastal communities / Suburban neighbourhood) and Redcliffe Interim residential: site cover <= 50%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 50, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/COASTAL_COMMUNITIES"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:REDCLIFFE_KIPPA_RING/INTERIM_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "sources": [{"key": "mb_dh_rad5_site_cover_50", "role": "PRIMARY",
              "quote": "RAD5 Site cover (excluding eaves, sun shading devices, patios, balconies and other unenclosed structures) does not exceed: ... Coastal communities precinct – 50% - Suburban neighbourhood precinct – 50% ... Interim residential precinct - 50%"}],
 "interpretation_notes": "RAD5 excludes 'other unenclosed structures' (so open carports/patios excluded) although the scheme's site cover definition includes carports — conflict flagged by researcher; RAD5 wording followed.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.GR_SITE_COVER_50@2026-09-11', 'CMB.mb_dh_rad5_site_cover_50');
SELECT alt_overrides('CMB.C.GR_SITE_COVER_50@2026-09-11', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.6.1: Dwelling house code holds alternative site cover provisions.');

SELECT define_rule($r${
 "rule_id": "CMB.C.OUTBUILDING_ROOFED_AREA", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "OUTBUILDING.SIZE", "title": "Domestic outbuildings: total combined roofed area by lot size (50 / 70 / 80 / 150 m2)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "unit": "m2",
 "value": {"op": "case", "when": [{"if": {"op": "<", "args": [{"var": "lot_area_m2"}, 600]}, "then": 50},
                                  {"if": {"op": "<=", "args": [{"var": "lot_area_m2"}, 1000]}, "then": 70},
                                  {"if": {"op": "<=", "args": [{"var": "lot_area_m2"}, 2000]}, "then": 80}], "else": 150},
 "on_noncompliance": "MANUAL_REVIEW", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/COASTAL_COMMUNITIES"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/NEXT_GENERATION_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/URBAN_NEIGHBOURHOOD"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:REDCLIFFE_KIPPA_RING/INTERIM_RESIDENTIAL"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_dh_rad26_outbuilding_roofed_area", "role": "PRIMARY",
              "quote": "Size of lot || Maximum roofed area ; Less than 600m2 || 50m2 ; 600m2 - 1000m2 || 70m2 ; >1000m2 – 2000m2 || 80m2 ; Greater than 2000m2 || 150m2"}],
 "interpretation_notes": "Measured value = total_outbuilding_roofed_area_m2. Declared an amenity-and-aesthetics matter, not an alternative provision; the referral consequence for amenity/aesthetics was not verified => MANUAL_REVIEW on failure.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.OUTBUILDING_ROOFED_AREA@2026-09-11', 'CMB.mb_dh_rad26_outbuilding_roofed_area');

-- =========================================================== SUNSHINE COAST
SELECT define_rule($r${
 "rule_id": "SCC.C.CLASS10A_ROAD_SETBACK_6M", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.FRONTAGE", "title": "Residential zones: garage, carport or shed >= 6 m from any road frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"},
            {"level": "ZONE", "zone": "SCC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "SCC:HIGH_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:TOURIST_ACCOMMODATION"}],
 "subjects": ["GARAGE", "CARPORT", "SHED"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "dh_garage_carport_shed_road_setback_res", "role": "PRIMARY",
              "quote": "AO2.1 Where located on a lot in a residential zone, a garage, carport or shed:- (a) is setback at least 6 metres from any road frontage; ... Note--AO2.1(a) alternative provision to QDC."}],
 "interpretation_notes": "'any road frontage' => applies to both frontages of a corner lot (no secondary-frontage concession). Also applies to a garage under the main roof. Whether 'Tourist accommodation zone' counts as a 'residential zone' follows the researcher's reading.",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.CLASS10A_ROAD_SETBACK_6M@2024-01-23', 'SCC.dh_garage_carport_shed_road_setback_res');
SELECT alt_overrides('SCC.C.CLASS10A_ROAD_SETBACK_6M@2024-01-23', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1b.CORNER_NOMINATED_FRONTAGE','QDC12.A1c.OPEN_CARPORT','QDC11.A1a.FRONTAGE_SETBACK'], 'Note--AO2.1(a) alternative provision to QDC.');

SELECT define_rule($r${
 "rule_id": "SCC.C.OUTBUILDING_HEIGHT_3_6", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "HEIGHT.CLASS_10A", "title": "Residential zones: garage, carport or shed <= 3.6 m high (not a garage under the main roof)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 3.6, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"},
            {"level": "ZONE", "zone": "SCC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "SCC:HIGH_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:TOURIST_ACCOMMODATION"}],
 "subjects": ["GARAGE", "CARPORT", "SHED"],
 "conditions": [[{"fact": "is_garage_under_main_roof", "op": "IS_FALSE"}]],
 "sources": [{"key": "dh_outbuilding_max_height_res", "role": "PRIMARY"}],
 "interpretation_notes": "Not an alternative provision; failing it makes the work code assessable for that matter only (s5.3.3(2)).",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.OUTBUILDING_HEIGHT_3_6@2024-01-23', 'SCC.dh_outbuilding_max_height_res');

SELECT define_rule($r${
 "rule_id": "SCC.C.OUTBUILDING_FLOOR_AREA_56", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "OUTBUILDING.SIZE", "title": "Residential zones: garage, carport or shed total floor area <= 56 m2",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "value": 56, "unit": "m2",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"},
            {"level": "ZONE", "zone": "SCC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "SCC:HIGH_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:TOURIST_ACCOMMODATION"}],
 "subjects": ["GARAGE", "CARPORT", "SHED"],
 "conditions": [[{"fact": "is_garage_under_main_roof", "op": "IS_FALSE"}]],
 "sources": [{"key": "dh_outbuilding_max_floor_area_res", "role": "PRIMARY"}],
 "interpretation_notes": "Not automatable: 'a garage, carport or shed ... has a total floor area' — per building or combined across all outbuildings is unresolved. Engine should test both and report.",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.OUTBUILDING_FLOOR_AREA_56@2024-01-23', 'SCC.dh_outbuilding_max_floor_area_res');

SELECT define_rule($r${
 "rule_id": "SCC.C.CANAL_SETBACK_4_5", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.WATERWAY", "title": "Buildings and structures > 1 m high (incl. pools, decks; not >= 75% transparent pool fencing) >= 4.5 m from canal/artificial waterway boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_WATERWAY", "operator": ">=", "value": 4.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "adjoins_canal_or_lake", "op": "IS_TRUE"}, {"fact": "structure_height_above_ground_m", "op": ">", "value": 1.0}]],
 "sources": [{"key": "dh_canal_setback", "role": "PRIMARY",
              "quote": "AO6 Buildings and structures exceeding 1 metre in height above ground level (other than pool fencing which is at least 75% transparent) are setback a minimum of 4.5 metres from the property boundary adjoining the canal or artificial waterway/waterbody. Note--AO6 alternative provision to QDC."}],
 "interpretation_notes": "In-ground pools with coping <= 1 m above ground are outside AO6. Transparent pool fencing exception handled by the exemption below.",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.CANAL_SETBACK_4_5@2024-01-23', 'SCC.dh_canal_setback');

SELECT define_rule($r${
 "rule_id": "SCC.C.CANAL_SETBACK_POOL_FENCE_EXEMPT", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.WATERWAY", "title": "Pool fencing at least 75% transparent exempt from canal setback",
 "role": "EXEMPTION", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}],
 "subjects": ["POOL_FENCE"],
 "conditions": [[{"fact": "pool_fence_transparency_pct", "op": ">=", "value": 75}]],
 "sources": [{"key": "dh_canal_setback", "role": "PRIMARY", "quote": "(other than pool fencing which is at least 75% transparent)"}],
 "effective_from": "2024-01-23"}$r$);
SELECT relate('SCC.C.CANAL_SETBACK_POOL_FENCE_EXEMPT@2024-01-23', 'SCC.C.CANAL_SETBACK_4_5@2024-01-23', 'EXEMPTS', NULL, NULL, 'VERIFIED_VERBATIM');

SELECT define_rule($r${
 "rule_id": "SCC.C.RR_SIDE_REAR_3M", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural residential / Limited development (landscape residential): house incl. garage, carport, shed >= 3 m from side or rear boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}, {"level": "ZONE", "zone": "SCC:RURAL_RESIDENTIAL"},
            {"level": "ZONE", "zone": "SCC:LIMITED_DEVELOPMENT_LANDSCAPE_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "dh_rr_ldlr_side_rear_setback", "role": "PRIMARY"}],
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.RR_SIDE_REAR_3M@2024-01-23', 'SCC.dh_rr_ldlr_side_rear_setback');
SELECT alt_overrides('SCC.C.RR_SIDE_REAR_3M@2024-01-23', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Note--AO5.1 and AO5.2 alternative provisions to QDC.');

-- ================================================================== IPSWICH
SELECT define_rule($r${
 "rule_id": "ICC.C.SITE_COVER_60", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "SITE_COVER", "title": "Dwelling houses: site cover <= 60% (residential, township, emerging community, rural zones)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 60, "unit": "%",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"},
            {"level": "ZONE", "zone": "ICC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "ICC:LOW_MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "ICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "ICC:HIGH_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "ICC:CHARACTER_RESIDENTIAL"}, {"level": "ZONE", "zone": "ICC:TOWNSHIP"},
            {"level": "ZONE", "zone": "ICC:EMERGING_COMMUNITY"}, {"level": "ZONE", "zone": "ICC:RURAL"}],
 "subjects": ["ANY"],
 "sources": [{"key": "dh_ro3_1_1_site_cover_60", "role": "PRIMARY",
              "quote": "RO3.1.1 Dwelling houses and Dual occupancies have a maximum site cover of 60%;"}],
 "interpretation_notes": "Terrace-style 75% alternative (RO3.1.2) is a separate draft rule. Table 1.5.1 names the Dwelling House and Dual Occupancy Code as the alternative to QDC site cover. Failing an ADSR requirement makes the work code assessable (planning permit before building approval).",
 "effective_from": "2026-07-01"}$r$);
SELECT supersede_draft('ICC.C.SITE_COVER_60@2026-07-01', 'ICC.dh_ro3_1_1_site_cover_60');
SELECT alt_overrides('ICC.C.SITE_COVER_60@2026-07-01', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.5.1 QDC Alternative Provisions: site cover.');

SELECT define_rule($r${
 "rule_id": "ICC.C.HEIGHT_9_5", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "HEIGHT.BUILDING", "title": "Dwelling houses: maximum building height 9.5 m to the roof peak",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 9.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"},
            {"level": "ZONE", "zone": "ICC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "ICC:LOW_MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "ICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "ICC:HIGH_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "ICC:CHARACTER_RESIDENTIAL"}, {"level": "ZONE", "zone": "ICC:TOWNSHIP"},
            {"level": "ZONE", "zone": "ICC:EMERGING_COMMUNITY"}, {"level": "ZONE", "zone": "ICC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "sources": [{"key": "dh_ro3_2_1_building_height_9_5", "role": "PRIMARY",
              "quote": "RO3.2.1 Maximum building height is 9.5m to the peak of the roof."}],
 "interpretation_notes": "Recorded as PLANNING: Table 1.5.1 names the Building Height and Density Overlay (OV6), not this code, as the QDC height alternative. Building track therefore keeps QDC A4 (8.5 m / 10 m) unless OV6 provides otherwise — both limits must be met.",
 "effective_from": "2026-07-01"}$r$);
SELECT supersede_draft('ICC.C.HEIGHT_9_5@2026-07-01', 'ICC.dh_ro3_2_1_building_height_9_5');

SELECT define_rule($r${
 "rule_id": "ICC.C.RURAL_FRONT_10", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone: front boundary setback >= 10 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "ZONE", "zone": "ICC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "dh_ro2_1_front_setback_rural", "role": "PRIMARY"}],
 "interpretation_notes": "Application to Class 10a is inferred from the SC1.1 dwelling house definition (includes domestic outbuildings), not stated in the RO => not automatable until confirmed.",
 "effective_from": "2026-07-01"}$r$);
SELECT supersede_draft('ICC.C.RURAL_FRONT_10@2026-07-01', 'ICC.dh_ro2_1_front_setback_rural');

SELECT define_rule($r${
 "rule_id": "ICC.C.RURAL_SIDE_20", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "SETBACK.SIDE", "title": "Rural zone: side boundary setback >= 20 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 20.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "ZONE", "zone": "ICC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "dh_ro2_2_side_setback_rural", "role": "PRIMARY"}],
 "interpretation_notes": "Text addresses side boundaries only; rear setback in the Rural zone is not regulated by the code => QDC A2 applies to rear. Class 10a coverage inferred (see front rule).",
 "effective_from": "2026-07-01"}$r$);
SELECT supersede_draft('ICC.C.RURAL_SIDE_20@2026-07-01', 'ICC.dh_ro2_2_side_setback_rural');

-- ================================================================== REDLAND
SELECT define_rule($r${
 "rule_id": "RCC.C.LDR2_ROAD_SETBACK_10", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "SETBACK.FRONTAGE", "title": "LDR2 Park residential: dwelling houses (incl. outbuildings) 10 m from a road frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR2"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "ldr2_road_setback_10m", "role": "PRIMARY",
              "quote": "AO4.1 In precinct LDR2 park residential, dwelling houses (including outbuildings) are set back 10m from a road frontage and 10m from a side or rear boundary."}],
 "effective_from": "2025-11-10"}$r$);
SELECT supersede_draft('RCC.C.LDR2_ROAD_SETBACK_10@2025-11-10', 'RCC.ldr2_road_setback_10m');
SELECT alt_overrides('RCC.C.LDR2_ROAD_SETBACK_10@2025-11-10', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Editor''s note: the following acceptable outcomes are alternative provisions for the purposes of the QDC.');

SELECT define_rule($r${
 "rule_id": "RCC.C.LDR2_SIDE_REAR_10", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "SETBACK.SIDE_REAR", "title": "LDR2 Park residential: dwelling houses (incl. outbuildings) 10 m from side or rear boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR2"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "ldr2_side_rear_setback_10m", "role": "PRIMARY"}],
 "interpretation_notes": "No Class 10a built-to-boundary concession in LDR2 (displaces QDC A2(d)).",
 "effective_from": "2025-11-10"}$r$);
SELECT supersede_draft('RCC.C.LDR2_SIDE_REAR_10@2025-11-10', 'RCC.ldr2_side_rear_setback_10m');
SELECT alt_overrides('RCC.C.LDR2_SIDE_REAR_10@2025-11-10', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Editor''s note: alternative provisions for the purposes of the QDC.');

SELECT define_rule($r${
 "rule_id": "RCC.C.LDR1_LDR2_SITE_COVER_30", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "SITE_COVER", "title": "LDR1 Large lot / LDR2 Park residential: site cover <= 30%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 30, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR1"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR2"}],
 "subjects": ["ANY"],
 "sources": [{"key": "ldr1_ldr2_site_cover_30pct", "role": "PRIMARY", "quote": "AO6.1 Site cover does not exceed 30% of site area."}],
 "interpretation_notes": "Heading note says 'A number of the following acceptable outcomes are alternative provisions'; AO6.1 is the only AO under it.",
 "effective_from": "2025-11-10"}$r$);
SELECT supersede_draft('RCC.C.LDR1_LDR2_SITE_COVER_30@2025-11-10', 'RCC.ldr1_ldr2_site_cover_30pct');
SELECT alt_overrides('RCC.C.LDR1_LDR2_SITE_COVER_30@2025-11-10', ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Alternative site cover provision.');

SELECT define_rule($r${
 "rule_id": "RCC.C.LDR5_CANAL_LAKE_9M", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "SETBACK.WATERWAY", "title": "LDR5: development incl. outbuildings and roofed structures (not in-ground pools) >= 9 m from canal/lake boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_WATERWAY", "operator": ">=", "value": 9.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR5"}],
 "subjects": ["CLASS_1", "CLASS_10A", "POOL_ABOVEGROUND", {"id": "POOL_INGROUND", "exclude": true}],
 "conditions": [[{"fact": "adjoins_canal_or_lake", "op": "IS_TRUE"}]],
 "sources": [{"key": "ldr5_canal_lake_setback_9m", "role": "PRIMARY",
              "quote": "AO9.1 Development (including domestic outbuildings and other roofed structures, but excluding in-ground swimming pools) is setback a minimum of 9m from the property boundary adjoining a canal or lake. Editor's note - This acceptable outcome is an alternative provision for the purposes of the Queensland Development Code."}],
 "interpretation_notes": "Roofed patios/pergolas/decks are 'other roofed structures' => covered; unroofed decks unresolved (OUTDOOR_STRUCTURE not listed — engine routes to manual review). Above-ground pools included by the express exclusion of only in-ground pools.",
 "effective_from": "2025-11-10"}$r$);
SELECT supersede_draft('RCC.C.LDR5_CANAL_LAKE_9M@2025-11-10', 'RCC.ldr5_canal_lake_setback_9m');

-- ================================================================= BRISBANE

SELECT define_rule($r${
 "rule_id": "BCC.C.DH_HEIGHT_9_5", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "HEIGHT.BUILDING", "title": "Dwelling house (standard lot): maximum building height 9.5 m and 2 storeys",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 9.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"},
            {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:RURAL_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}]],
 "sources": [{"key": "dh_max_height_low_density", "role": "PRIMARY",
              "quote": "AO2 Development in the Low density residential zone, Character residential zone, ... results in a maximum building height of 9.5m and: - 2 storeys; or - 1 storey if ..."}],
 "interpretation_notes": "Table 1.6.1 item 6: a s32(b) quantifiable standard for QDC MP1.1/1.2 performance criteria 4 (height) — replaces QDC A4 (8.5 m) for building assessment. Small-lot definition also covers rear lots < 600 m2 excl. access way — engine must derive that, not just lot area. Applies to domestic outbuildings only through the dwelling house definition; Brisbane has no separate outbuilding height cap here, so the QHC/QDC 4.5 m Class 10a limit is not applicable while MP 1.2 applies (MP 1.2 has none).",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.DH_HEIGHT_9_5@2026-09-18', 'BCC.dh_max_height_low_density');
SELECT alt_overrides('BCC.C.DH_HEIGHT_9_5@2026-09-18', ARRAY['QDC12.A4.BUILDING_HEIGHT'], 'City Plan Table 1.6.1 item 6 (s32(b) Building Act; former s6 Building Regulation): quantifiable standard for QDC P4.');

SELECT define_rule($r${
 "rule_id": "BCC.C.SL_GARAGE_STREET_5_5", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "GARAGE.FRONTAGE", "title": "Small lot (180-450 m2): garage street setback at least 5.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "ZONE", "zone": "BCC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "BCC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "BCC:CHARACTER_RESIDENTIAL"}],
 "subjects": ["GARAGE"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "sl_garage_street_setback", "role": "PRIMARY"}],
 "interpretation_notes": "Text says 'garages' only — carports not expressly caught (researcher flag). Table 1.6.1 item 10 alternative provision.",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.SL_GARAGE_STREET_5_5@2026-09-18', 'BCC.sl_garage_street_setback');
SELECT alt_overrides('BCC.C.SL_GARAGE_STREET_5_5@2026-09-18', ARRAY['QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.6.1 item 10: alternative to QDC P1.');

SELECT define_rule($r${
 "rule_id": "BCC.C.NP_NEW_FARM_REAR_6", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.REAR", "title": "New Farm & Teneriffe Hill NP, Low density living precinct: rear setback 6 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "BCC:NP_NEW_FARM_TENERIFFE/NPP-001"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "np_newfarm_ldr_rear_setback", "role": "PRIMARY", "quote": "AO3 Development is set back a minimum of 6m from the rear boundary."}],
 "interpretation_notes": "'Development' — whether it reaches Class 10a and pools needs council confirmation (alternative provisions only operate for QDC siting matters). Example of a neighbourhood plan overriding the QDC rear clearance (Table 1.6.1 item 11).",
 "effective_from": "2026-09-18"}$r$);
SELECT supersede_draft('BCC.C.NP_NEW_FARM_REAR_6@2026-09-18', 'BCC.np_newfarm_ldr_rear_setback');
SELECT alt_overrides('BCC.C.NP_NEW_FARM_REAR_6@2026-09-18', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1 item 11: alternative to QDC P2.');

