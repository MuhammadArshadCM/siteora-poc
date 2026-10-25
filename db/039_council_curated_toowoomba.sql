-- =============================================================================
-- Curated council rules: Toowoomba Regional Council (TRC_PLANNING_SCHEME_2012, version 29 with TLPI 01/2026).
-- Class 10 front / side / rear setbacks, hand-encoded from research/councils/toowoomba.json (loaded as drafts by
-- db/030_council_toowoomba.sql). Each curated rule REPLACES its draft.
--   * Only the Small Lot Housing Design Code (9.3.10, lots < 450 m2) AO3.1 and AO4.1 are QDC alternative provisions
--     (Part 1 Table 1.6.1 items 6 and 7): regime BUILDING. AO7.1 (car parking, item 9) is an s32 standard.
--   * Zone / local plan tables 6.2.1:3, 6.2.2:3, 6.6.9:2, 6.6.1:2 and 7.2.3:1 are benchmarks for assessable
--     development only: regime PLANNING with planning_assessment_required. Under TLPI 01/2026 Class 10 building work
--     not associated with an MCU is accepted subject to requirements against "the applicable zone code", but these
--     tables do not apply to accepted development, so those rules are not automatable.
--   * Community Facilities Table 6.6.1:1 and the Heritage / Neighbourhood character overlay AO1.1 are accepted
--     development requirements (dwelling house / Class 10a under TLPI 01/2026).
-- Drafts deliberately not curated: scratchpad decisions/toowoomba.json. Absence drafts stay as drafts.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('toowoomba_avg_front_setback_100m_m','NUMBER','m',NULL,'PROPERTY_DATA','Average front setback of existing residential buildings within 100 m of the site (Toowoomba Small Lot Housing Design Code AO3.1(a); Low-medium density residential zone AO9.1(a))', 'Building footprints and cadastre within 100 m of the site'),
 ('toowoomba_primary_building_front_setback_m','NUMBER','m',NULL,'DESIGN_INPUT','Setback from the front boundary of the main face / front building line of the dwelling (primary building) on the site: its closest non-garage/carport element to the front boundary (Toowoomba 9.3.10 AO7.1(d) footnote 40; Heritage and Neighbourhood character overlay AO1.1(a))', 'Site plan of the dwelling'),
 ('toowoomba_boundary_adjoins_residential_premises','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The boundary being tested adjoins a residential premises (Toowoomba Community Facilities zone AO2.1)', 'Land use of the adjoining lot'),
 ('toowoomba_boundary_adjoins_residential_zone','BOOLEAN',NULL,NULL,'PLANNING_DATA','The boundary being tested adjoins land in a residential or rural residential zone (Toowoomba Community Facilities zone AO6.1)', 'Zoning of the adjoining lot'),
 ('toowoomba_part_within_10m_of_front_boundary','BOOLEAN',NULL,NULL,'GEOMETRY_DERIVED','The part of the building being tested is within 10 m of the front boundary (Toowoomba Hospital Support Precinct AO33.2)', 'Distance from the front boundary to the building part'),
 ('toowoomba_boundary_adjoins_rural_land_outside_cwea','BOOLEAN',NULL,NULL,'PLANNING_DATA','The boundary being tested adjoins land outside the Charlton Wellcamp Enterprise Area local plan area that is used for rural purposes (Toowoomba 7.2.3 AO14.1(a))', 'Local plan boundary and land use of the adjoining lot');

-- =========================================================== SMALL LOT HOUSING DESIGN CODE (9.3.10), lots < 450 m2
-- AO3.1(a): adjoining buildings exist -> within 10% of the average of residential buildings within 100 m
SELECT define_rule($r${
 "rule_id": "TRC.C.SLH_FRONT_PREVAILING", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Small lot (< 450 m2, LDR / LMDR): buildings within 10% of the average front setback of residential buildings within 100 m (minimum encoded: 90%)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "*", "args": [0.9, {"var": "toowoomba_avg_front_setback_100m_m"}]},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "development_footprint_exists", "op": "IS_FALSE"},
                 {"fact": "has_adjoining_dwelling", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_slh_ao3_1_front_prevailing", "role": "PRIMARY",
              "quote": "AO3.1 Buildings are setback from the road frontage: (a) within 10% of the average front setback of existing residential buildings within 100m of the site;"}],
 "interpretation_notes": "'Within 10%' is a band (0.9x to 1.1x the average); the 0.9x minimum is encoded, the 1.1x maximum is for the geometry layer. Limb (b) (Table 4) applies where there are no adjoining buildings, so this limb is used where an adjoining dwelling exists (has_adjoining_dwelling approximates 'adjoining buildings'). Needs neighbour setback data => not automatable. Schedule 7 plan of development read as development_footprint_exists. Part 1 Table 1.6.1 item 6: alternative to QDC MP1.1 P1.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.SLH_FRONT_PREVAILING@2026-07-21', 'TRC.trc_slh_ao3_1_front_prevailing');
SELECT alt_overrides('TRC.C.SLH_FRONT_PREVAILING@2026-07-21', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1a.ROAD_SETBACK_NEIGHBOURS','QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.FRONTAGE_NEIGHBOURS'], 'Part 1 Table 1.6.1 item 6: Small Lot Housing Design Code AO3.1 is an alternative provision to QDC MP1.1 P1.');

-- AO3.1(b) / Table 4: no adjoining buildings
SELECT define_rule($r${
 "rule_id": "TRC.C.SLH_FRONT_WALL_4M", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Small lot (< 450 m2, LDR / LMDR), no adjoining buildings: solid building wall (other than a garage) 4.0 m from the front",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 4.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "development_footprint_exists", "op": "IS_FALSE"},
                 {"fact": "has_adjoining_dwelling", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_slh_ao3_1_table4_front", "role": "PRIMARY", "quote": "Solid building wall (other than a garage) | 4.0m"},
             {"key": "trc_slh_ao3_1_front_prevailing", "role": "SUPPLEMENTARY", "quote": "(b) where there is no adjoining buildings the front setback is provided in accordance with Table 4."}],
 "interpretation_notes": "Enclosed Class 10a buildings other than garages (sheds, laundries) take the solid-wall row; garages and carports have their own rows (TRC.C.SLH_GARAGE_FRONT_5_5, TRC.C.SLH_CARPORT_FRONT_3_5). Eaves and window hoods may encroach up to 600 mm (not encoded).",
 "effective_from": "2026-07-21"}$r$);
SELECT define_rule($r${
 "rule_id": "TRC.C.SLH_GARAGE_FRONT_5_5", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "GARAGE.FRONTAGE", "title": "Small lot (< 450 m2, LDR / LMDR), no adjoining buildings: garage wall 5.5 m from the front",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "development_footprint_exists", "op": "IS_FALSE"},
                 {"fact": "has_adjoining_dwelling", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_slh_ao3_1_table4_front", "role": "PRIMARY", "quote": "Solid building wall (where for a garage) | 5.5m"},
             {"key": "trc_slh_ao3_1_front_prevailing", "role": "SUPPLEMENTARY", "quote": "(b) where there is no adjoining buildings the front setback is provided in accordance with Table 4."}],
 "interpretation_notes": "The garage must also be 1 m behind the dwelling's main face (TRC.C.SLH_GARAGE_BEHIND_MAIN_FACE); both minimums apply (cumulative, not alternatives).",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.SLH_GARAGE_FRONT_5_5@2026-07-21', 'TRC.trc_slh_ao3_1_table4_front');
SELECT define_rule($r${
 "rule_id": "TRC.C.SLH_CARPORT_FRONT_3_5", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "GARAGE.FRONTAGE", "title": "Small lot (< 450 m2, LDR / LMDR), no adjoining buildings: carport (non-enclosed) 3.5 m from the front, 3 m from a secondary road frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "=", "args": [{"var": "boundary_type"}, "SECONDARY_FRONTAGE_ROAD"]}, "then": 3.0}], "else": 3.5},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "development_footprint_exists", "op": "IS_FALSE"},
                 {"fact": "has_adjoining_dwelling", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "trc_slh_ao3_1_table4_front", "role": "PRIMARY", "quote": "Permeable or non-enclosed elements (e.g. porch, verandah, balcony or carport) | 3.5m (or 3m where secondary road frontage)"},
             {"key": "trc_slh_ao3_1_front_prevailing", "role": "SUPPLEMENTARY", "quote": "(b) where there is no adjoining buildings the front setback is provided in accordance with Table 4."}],
 "interpretation_notes": "Table 4 states the 3 m secondary-road figure only for permeable / non-enclosed elements, so only this row is extended to the secondary road frontage. The carport must also be 1 m behind the dwelling's main face (TRC.C.SLH_GARAGE_BEHIND_MAIN_FACE).",
 "effective_from": "2026-07-21"}$r$);
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Part 1 Table 1.6.1 item 6: Small Lot Housing Design Code AO3.1 is an alternative provision to QDC MP1.1 P1.')
FROM unnest(ARRAY['TRC.C.SLH_FRONT_WALL_4M@2026-07-21','TRC.C.SLH_GARAGE_FRONT_5_5@2026-07-21','TRC.C.SLH_CARPORT_FRONT_3_5@2026-07-21']) rv;

-- AO7.1(d): garage / carport 1 m behind the main face of the dwelling (s32 standard for QDC MP1.1 P8, Table 1.6.1 item 9)
SELECT define_rule($r${
 "rule_id": "TRC.C.SLH_GARAGE_BEHIND_MAIN_FACE", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "GARAGE.FRONTAGE", "title": "Small lot (< 450 m2, LDR / LMDR) without rear lane access: garage or carport at least 1 m behind the main face of the dwelling",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "+", "args": [{"var": "toowoomba_primary_building_front_setback_m"}, 1.0]},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "development_footprint_exists", "op": "IS_FALSE"},
                 {"fact": "vehicle_access_from_rear_lane", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_slh_ao7_1d_garage_behind_main_face", "role": "PRIMARY",
              "quote": "(d) the garage or carport is setback a minimum of one (1) metre behind the main face40 of the dwelling."}],
 "interpretation_notes": "Relative setback expressed as (front setback of the dwelling's main face) + 1 m. Footnote 40 defines the main face as the closest non-garage/carport dwelling element to the front boundary. 'Lots without rear lane access' read as vehicle_access_from_rear_lane = false. AO7.1 is an s32 standard for QDC MP1.1 P8 (car parking), not a boundary clearance alternative, so no QDC boundary rule is overridden. Cumulative with the Table 4 garage / carport minimums.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.SLH_GARAGE_BEHIND_MAIN_FACE@2026-07-21', 'TRC.trc_slh_ao7_1d_garage_behind_main_face');

-- AO4.1 / Table 9.3.10:2 (side and rear)
SELECT define_rule($r${
 "rule_id": "TRC.C.SLH_SIDE", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.SIDE", "title": "Small lot (< 450 m2, LDR / LMDR): side setback 1.2 m (building height <= 8.5 m); 2 m + 0.5 m per 3 m over 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "building_height_m"}, 8.5]},
           "then": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "building_height_m"}, 8.5]}, 3]}]}]}]}}],
           "else": 1.2},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "trc_slh_t2_side", "role": "PRIMARY",
              "quote": "Side | Where the building height is greater than 8.5 metres. | Any | 2 metres plus 0.5 metres for every 3 metres or part thereof exceeding 8.5 metres. || Where the building height is 8.5 metres or less. | ≤ 12.5 metres | 1.2m unless external walls built to boundary (zero lot alignment with no gap to boundary) || > 12 metres | 1.2 metre"}],
 "interpretation_notes": "Scheme drafting error: AO4.1 cites 'Table 9.3.10:3' (the built-to-boundary wall length table) but the setback table is Table 9.3.10:2; lot-width bands overlap as printed ('≤ 12.5' / '> 12'). The zero-lot-alignment option for lots <= 12.5 m wide is not encoded because its wall-length limits (Table 9.3.10:3) are not in the research. 'Building height' read as building_height_m of the building being sited. Not automatable until the table reference is confirmed with council. Part 1 Table 1.6.1 item 7: alternative to QDC MP1.1 P2; the text does not name Class 10, so QDC A2(d) is not displaced. Where the dwelling house is also code assessable, the zone code side setbacks apply as separate planning benchmarks.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.SLH_SIDE@2026-07-21', 'TRC.trc_slh_t2_side');

SELECT define_rule($r${
 "rule_id": "TRC.C.SLH_REAR", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.REAR", "title": "Small lot (< 450 m2, LDR / LMDR): rear setback 1.2 m (0 m with rear laneway access; building > 8.5 m: 0 m, 3 m for elements above 8.5 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": ">", "args": [{"var": "building_height_m"}, 8.5]},
     "then": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "part_height_m"}, 8.5]}, "then": 3.0}], "else": 0}},
    {"if": {"op": "is_true", "args": [{"var": "vehicle_access_from_rear_lane"}]}, "then": 0}],
   "else": 1.2},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 450}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "trc_slh_t2_rear", "role": "PRIMARY",
              "quote": "Rear | Where the building height is greater than 8.5 metres and not associated with a rear lane. | Any | 0 metres (built to boundary) up to 8.5 metres in height; 3 metres for any building element exceeding 8.5 metres in height. || Where: (a) The building height is 8.5 metres or less and (b) The site has rear laneway access. | Any | 0 metres || Where: (a) The building height is 8.5 metres or less and (b) The side does not have rear laneway access. | ≤ 12.5 metres | 1.2 metres || > 12 metres | 1.2 metre"}],
 "interpretation_notes": "Same AO4.1 table-number error as TRC.C.SLH_SIDE ('Table 9.3.10:3' for 9.3.10:2). 'The side does not have rear laneway access' printed for 'site'. A building over 8.5 m on a lot with a rear lane is not covered by the table (encoded as the > 8.5 m row). Rear laneway access read as vehicle_access_from_rear_lane. Not automatable until confirmed with council. Part 1 Table 1.6.1 item 7: alternative to QDC MP1.1 P2.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.SLH_REAR@2026-07-21', 'TRC.trc_slh_t2_rear');
SELECT alt_overrides(rv, ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC12.A2b.NARROW_LOT_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE'], 'Part 1 Table 1.6.1 item 7: Small Lot Housing Design Code AO4.1 is an alternative provision to QDC MP1.1 P2.')
FROM unnest(ARRAY['TRC.C.SLH_SIDE@2026-07-21','TRC.C.SLH_REAR@2026-07-21']) rv;

-- ============================================================ LOW DENSITY RESIDENTIAL ZONE (Table 6.2.1:3, assessable only)
SELECT define_rule($r${
 "rule_id": "TRC.C.LDR_FRONT", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Low density residential (assessable): front setback to a collector or local road within 20% of the adjoining buildings' average (minimum encoded: 80%), or 4 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "has_adjoining_dwelling"}]},
           "then": {"op": "*", "args": [0.8, {"op": "avg_of", "args": [{"var": "adjoining_road_setbacks_m"}]}]}}], "else": 4.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "street_type", "op": "IN", "value": ["ACCESS_PLACE", "ACCESS_STREET", "COLLECTOR"]},
                 {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_ldr_ao9_1_front", "role": "PRIMARY",
              "quote": "AO9.1 Where the site has frontage to a collector or local road, buildings are set back from that frontage: (a) within 20% of the average front setback of adjoining buildings; or (b) where there are no adjoining buildings, 4m."}],
 "interpretation_notes": "Table 6.2.1:3 is for assessable development only; a Class 10 under TLPI 01/2026 is accepted subject to requirements against the zone code, whose Table 6.2.1:1 has no setback AO, so whether this reaches stand-alone Class 10 work is doubtful => not automatable. 'Collector or local road' mapped to street_type ACCESS_PLACE / ACCESS_STREET / COLLECTOR (lot-level street hierarchy, so the primary frontage only). 'Within 20%' band: 0.8x minimum encoded. Other roads: AO9.2 defers to the QDC.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LDR_FRONT@2026-07-21', 'TRC.trc_ldr_ao9_1_front');

SELECT define_rule($r${
 "rule_id": "TRC.C.LDR_SIDE", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.SIDE", "title": "Low density residential (assessable): side setback 1.5 m (up to 3.5 m high), 2 m (up to 7.5 m), 3 m above 7.5 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 3.5]}, "then": 1.5},
                                  {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0}], "else": 3.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "trc_ldr_ao10_1_side", "role": "PRIMARY",
              "quote": "AO10.1 Buildings are set back from a side boundary: (a) Ground Floor (up to 3.5m high) – 1.5m; and (b) First floor (up to 7.5m high) – 2m; (c) Above 7.5m – 3m;"}],
 "interpretation_notes": "Limb (d) (the height of a side-boundary retaining wall, or retaining wall plus fence, 'whichever is greater') is not encoded. Assessable-only table; TLPI 01/2026 doubt as TRC.C.LDR_FRONT => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LDR_SIDE@2026-07-21', 'TRC.trc_ldr_ao10_1_side');

SELECT define_rule($r${
 "rule_id": "TRC.C.LDR_REAR_3M", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.REAR", "title": "Low density residential (assessable): rear setback 3 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "trc_ldr_ao10_2_rear", "role": "PRIMARY", "quote": "AO10.2 Buildings are set back: (a) a minimum of 3m from a rear boundary;"}],
 "interpretation_notes": "Alternative (b) (cumulative height of the rear retaining wall and fence) not encoded. Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LDR_REAR_3M@2026-07-21', 'TRC.trc_ldr_ao10_2_rear');

-- ===================================================== LOW-MEDIUM DENSITY RESIDENTIAL ZONE (Table 6.2.2:3, assessable only)
SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_FRONT_PREVAILING", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Low-medium density residential (assessable): buildings within 10% of the average front setback of residential buildings within 100 m (minimum encoded: 90%)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "*", "args": [0.9, {"var": "toowoomba_avg_front_setback_100m_m"}]},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "has_adjoining_dwelling", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_lmdr_ao9_1_front", "role": "PRIMARY",
              "quote": "AO9.1 Buildings are set back from the road frontage: (a) within 10% of the average front setback of existing residential buildings within 100m of the site;"}],
 "interpretation_notes": "As TRC.C.SLH_FRONT_PREVAILING but as a planning benchmark (assessable only; TLPI 01/2026 doubt). Needs neighbour setback data => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_FRONT_WALL_4M", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Low-medium density residential (assessable), no adjoining buildings: solid building wall (other than a garage) 4.0 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 4.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "has_adjoining_dwelling", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_lmdr_ao9_1_front", "role": "PRIMARY",
              "quote": "(b) where there are no adjoining buildings the front setback is provided in accordance with Table 1. || Table 1 | Building element | Minimum setback || Solid building wall (other than a garage) | 4.0m"}],
 "interpretation_notes": "Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_GARAGE_FRONT_5_5", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "GARAGE.FRONTAGE", "title": "Low-medium density residential (assessable), no adjoining buildings: garage wall 5.5 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["GARAGE"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "has_adjoining_dwelling", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_lmdr_ao9_1_front", "role": "PRIMARY",
              "quote": "(b) where there are no adjoining buildings the front setback is provided in accordance with Table 1. ... Solid building wall (where for a garage) | 5.5m"}],
 "interpretation_notes": "Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LMDR_GARAGE_FRONT_5_5@2026-07-21', 'TRC.trc_lmdr_ao9_1_front');
SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_CARPORT_FRONT_3_5", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "GARAGE.FRONTAGE", "title": "Low-medium density residential (assessable), no adjoining buildings: carport 3.5 m, 3 m from a secondary road frontage",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "=", "args": [{"var": "boundary_type"}, "SECONDARY_FRONTAGE_ROAD"]}, "then": 3.0}], "else": 3.5},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "has_adjoining_dwelling", "op": "IS_FALSE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "trc_lmdr_ao9_1_front", "role": "PRIMARY",
              "quote": "Permeable or non-enclosed elements (e.g. porch, verandah, balcony or carport) | 3.5m (or 3m where secondary road frontage)"}],
 "interpretation_notes": "Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);

SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_SIDE", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.SIDE", "title": "Low-medium density residential (assessable): side setback by frontage width and height (Table 6.2.2:4, 0.9 to 2 m)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": ">", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0},
    {"if": {"op": "<", "args": [{"var": "road_frontage_m"}, 12.5]}, "then": 0.9},
    {"if": {"op": "<", "args": [{"var": "road_frontage_m"}, 15.0]}, "then": 1.0},
    {"if": {"op": "<", "args": [{"var": "road_frontage_m"}, 20.0]},
     "then": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 3.5]}, "then": 1.0}], "else": 1.5}}],
   "else": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 3.5]}, "then": 1.2}], "else": 2.0}},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "road_frontage_m", "op": ">=", "value": 10}, {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "trc_lmdr_ao16_2_side", "role": "PRIMARY",
              "quote": "AO16.2 Buildings are set back from a side boundary in accordance with table 6.2.2:4 ... Table 6.2.2:4 – Side Boundary Setbacks | Width of lot frontage || 10.0m - 12.4m | Ground floor (up to 3.5m high) 0.9m | First floor (up to 7.5m high) 0.9m || 12.5m – 14.9m | Ground floor (up to 3.5m high) 1m | First floor (up to 7.5m high) 1m || 15.0m -19.9m | Ground floor (up to 3.5m high) 1m | First floor (up to 7.5m high) 1.5m || 20m + | Ground floor (up to 3.5m high) 1.2m | First floor (up to 7.5m high) 2m || All lots | Second floor (above 7.5m) 2m"}],
 "interpretation_notes": "Table columns flattened in the research; 'width of lot frontage' read as road_frontage_m. No figure for frontages under 10 m (rule limited to >= 10 m). The retaining-wall alternative ('whichever is greater') is not encoded. Built-to-boundary option AO16.1: TRC.C.LMDR_SIDE_BTB. Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LMDR_SIDE@2026-07-21', 'TRC.trc_lmdr_ao16_2_side');
SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_SIDE_BTB", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.SIDE_REAR.BTB", "title": "Low-medium density residential (assessable): buildings built to a side boundary (max 3 m high, max 9 m long)",
 "role": "RELAXATION", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 0, "unit": "m", "permits_btb": true,
 "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "SIDE"},
                 {"fact": "structure_height_m", "op": "<=", "value": 3.0}, {"fact": "btb_length_on_boundary_m", "op": "<=", "value": 9}]],
 "sources": [{"key": "trc_lmdr_ao16_2_side", "role": "PRIMARY",
              "quote": "AO16.1 Buildings built to side boundaries have: (a) a maximum height of 3m; and (b) a maximum length of 9m. Note: Built to boundary walls require a 0.00m lot alignment."}],
 "interpretation_notes": "AO16.1 is the alternative ('OR') to AO16.2. Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT relate('TRC.C.LMDR_SIDE_BTB@2026-07-21', 'TRC.C.LMDR_SIDE@2026-07-21', 'RELAXES', NULL, NULL, 'VERIFIED_VERBATIM');

SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_REAR_1M", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.REAR", "title": "Low-medium density residential (assessable): rear setback 1 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 1.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "trc_lmdr_ao16_3_rear", "role": "PRIMARY", "quote": "AO16.3 Buildings are set back a minimum of 1m from a rear boundary"}],
 "interpretation_notes": "Retaining wall / fence height alternative not encoded. Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LMDR_REAR_1M@2026-07-21', 'TRC.trc_lmdr_ao16_3_rear');

-- Hospital Support Precinct (prevails over the zone-wide rows)
SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_HS_FRONT_6M", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Low-medium density residential, Hospital Support Precinct (assessable): front setback 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "PRECINCT", "precinct": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL/HOSPITAL_SUPPORT"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_lmdr_hs_ao33_1_front", "role": "PRIMARY", "quote": "AO33.1 Buildings are setback at least 6m from the front boundary."}],
 "interpretation_notes": "Assessable-only table; TLPI 01/2026 doubt => not automatable. Prevails over the zone-wide front rows (OVERRIDES).",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LMDR_HS_FRONT_6M@2026-07-21', 'TRC.trc_lmdr_hs_ao33_1_front');
SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_HS_SIDE_4M", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.SIDE", "title": "Low-medium density residential, Hospital Support Precinct (assessable): side setback 4 m for building parts within 10 m of the front boundary",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 4.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "PRECINCT", "precinct": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL/HOSPITAL_SUPPORT"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "toowoomba_part_within_10m_of_front_boundary", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "trc_lmdr_hs_ao33_2_side", "role": "PRIMARY", "quote": "AO33.2 Buildings are setback a minimum of 4m from side boundaries for the extent of the building(s) within 10m of the front boundary."}],
 "interpretation_notes": "Behind the first 10 m the zone-wide side table applies. Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LMDR_HS_SIDE_4M@2026-07-21', 'TRC.trc_lmdr_hs_ao33_2_side');
SELECT define_rule($r${
 "rule_id": "TRC.C.LMDR_HS_REAR_6M", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.REAR", "title": "Low-medium density residential, Hospital Support Precinct (assessable): rear setback 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "PRECINCT", "precinct": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL/HOSPITAL_SUPPORT"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "trc_lmdr_hs_ao33_3_rear", "role": "PRIMARY", "quote": "AO33.3 Buildings are setback at least 6m from the rear boundary."}],
 "interpretation_notes": "Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.LMDR_HS_REAR_6M@2026-07-21', 'TRC.trc_lmdr_hs_ao33_3_rear');
SELECT relate(f, t, 'OVERRIDES', NULL, NULL, 'VERIFIED_VERBATIM', 'Hospital Support Precinct AO33 is the precinct-specific setback and prevails over the zone-wide rows.')
FROM (VALUES ('TRC.C.LMDR_HS_FRONT_6M@2026-07-21', 'TRC.C.LMDR_FRONT_PREVAILING@2026-07-21'),
             ('TRC.C.LMDR_HS_FRONT_6M@2026-07-21', 'TRC.C.LMDR_FRONT_WALL_4M@2026-07-21'),
             ('TRC.C.LMDR_HS_FRONT_6M@2026-07-21', 'TRC.C.LMDR_GARAGE_FRONT_5_5@2026-07-21'),
             ('TRC.C.LMDR_HS_FRONT_6M@2026-07-21', 'TRC.C.LMDR_CARPORT_FRONT_3_5@2026-07-21'),
             ('TRC.C.LMDR_HS_SIDE_4M@2026-07-21', 'TRC.C.LMDR_SIDE@2026-07-21'),
             ('TRC.C.LMDR_HS_SIDE_4M@2026-07-21', 'TRC.C.LMDR_SIDE_BTB@2026-07-21'),
             ('TRC.C.LMDR_HS_REAR_6M@2026-07-21', 'TRC.C.LMDR_REAR_1M@2026-07-21')) v(f, t);

-- ============================================== TOWNSHIP ZONE, Flood Management Precinct (Table 6.6.9:2, assessable only)
SELECT define_rule($r${
 "rule_id": "TRC.C.TWN_FMP_FRONT", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Township zone, Flood Management Precinct (assessable): front setback to a collector or local road within 20% of the adjoining buildings' average (minimum encoded: 80%), or 4 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "has_adjoining_dwelling"}]},
           "then": {"op": "*", "args": [0.8, {"op": "avg_of", "args": [{"var": "adjoining_road_setbacks_m"}]}]}}], "else": 4.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "PRECINCT", "precinct": "TRC:TOWNSHIP/FLOOD_MANAGEMENT"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "street_type", "op": "IN", "value": ["ACCESS_PLACE", "ACCESS_STREET", "COLLECTOR"]},
                 {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_twn_ao6_1_front", "role": "PRIMARY",
              "quote": "AO6.1 Where the site has frontage to a collector or local road, buildings are set back from that frontage: (a) within 20% of the average front setback of adjoining buildings; or (b) where there are no adjoining buildings, 4m."}],
 "interpretation_notes": "As TRC.C.LDR_FRONT. A dwelling house in the Flood Management Precinct is code assessable against the Township zone code (Table 5.5:17); assessable-only table, TLPI 01/2026 doubt for stand-alone Class 10 => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.TWN_FMP_FRONT@2026-07-21', 'TRC.trc_twn_ao6_1_front');

-- ========================================================================== COMMUNITY FACILITIES ZONE (6.6.1)
SELECT define_rule($r${
 "rule_id": "TRC.C.CF_SIDE_REAR_RES_PREMISES", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.SIDE_REAR", "title": "Community facilities zone: buildings 3 m or half the building height (greater) from a boundary adjoining residential premises",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "max", "args": [3.0, {"op": "/", "args": [{"var": "building_height_m"}, 2]}]},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:COMMUNITY_FACILITIES"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "toowoomba_boundary_adjoins_residential_premises", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "trc_cf_ao2_1_side_rear_res", "role": "PRIMARY",
              "quote": "AO2.1 Buildings are set back from any boundary adjoining a residential premises a minimum of 3m or half the height of the building, whichever is the greater."}],
 "interpretation_notes": "Table 6.6.1:1 requirement for accepted development: a dwelling house in the zone is accepted subject to requirements against this code (Table 5.5:14) and Class 10 building work is accepted subject to requirements against the zone code (TLPI 01/2026), so no planning_assessment_required condition. 'Residential premises' is undefined in the research and 'any boundary' is read as side / rear => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.CF_SIDE_REAR_RES_PREMISES@2026-07-21', 'TRC.trc_cf_ao2_1_side_rear_res');
SELECT define_rule($r${
 "rule_id": "TRC.C.CF_SIDE_REAR_RES_ZONE", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.SIDE_REAR", "title": "Community facilities zone (assessable): buildings 3 m or half the building height (greater) from a boundary adjoining a residential or rural residential zone",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "max", "args": [3.0, {"op": "/", "args": [{"var": "building_height_m"}, 2]}]},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:COMMUNITY_FACILITIES"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "toowoomba_boundary_adjoins_residential_zone", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "trc_cf_ao6_1_side_rear_reszone", "role": "PRIMARY",
              "quote": "AO6.1 Buildings are set back from any boundary adjoining land in a residential or rural residential zone a minimum of 3m or half the height of the building, whichever is the greater."}],
 "interpretation_notes": "Table 6.6.1:2 is for assessable development only; TLPI 01/2026 doubt => not automatable. Same value as TRC.C.CF_SIDE_REAR_RES_PREMISES, so no conflict.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.CF_SIDE_REAR_RES_ZONE@2026-07-21', 'TRC.trc_cf_ao6_1_side_rear_reszone');
SELECT define_rule($r${
 "rule_id": "TRC.C.CF_FRONT_LOCAL_ROAD", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Community facilities zone (assessable): front setback to a collector or local road within 20% of the adjoining buildings' average (minimum encoded: 80%), or 4 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "has_adjoining_dwelling"}]},
           "then": {"op": "*", "args": [0.8, {"op": "avg_of", "args": [{"var": "adjoining_road_setbacks_m"}]}]}}], "else": 4.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:COMMUNITY_FACILITIES"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "street_type", "op": "IN", "value": ["ACCESS_PLACE", "ACCESS_STREET", "COLLECTOR"]},
                 {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_cf_ao7_1_front", "role": "PRIMARY",
              "quote": "AO7.1 Where the site has frontage to a collector or local road, buildings are set back from that frontage: (a) within 20% of the average front setback of adjoining buildings; or (b) where there are no adjoining buildings, 4m."}],
 "interpretation_notes": "As TRC.C.LDR_FRONT. Assessable-only table; TLPI 01/2026 doubt => not automatable. Other roads: TRC.C.CF_FRONT_OTHER_ROAD_6M.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.CF_FRONT_LOCAL_ROAD@2026-07-21', 'TRC.trc_cf_ao7_1_front');
SELECT define_rule($r${
 "rule_id": "TRC.C.CF_FRONT_OTHER_ROAD_6M", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Community facilities zone (assessable): front setback 6 m to a road other than a collector or local road",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:COMMUNITY_FACILITIES"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "street_type", "op": "=", "value": "OTHER"},
                 {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_cf_ao7_1_front", "role": "PRIMARY",
              "quote": "AO7.1 Where the site has frontage to a road other than a collector or local road, buildings are set back from that frontage by 6m."}],
 "interpretation_notes": "Second AO numbered 7.1 as printed. 'Road other than a collector or local road' mapped to street_type OTHER. Assessable-only table; TLPI 01/2026 doubt => not automatable.",
 "effective_from": "2026-07-21"}$r$);

-- ==================================================== CHARLTON WELLCAMP ENTERPRISE AREA LOCAL PLAN (Table 7.2.3:1)
SELECT define_rule($r${
 "rule_id": "TRC.C.CWEA_SIDE_REAR", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.SIDE_REAR", "title": "Charlton Wellcamp Enterprise Area local plan (assessable): 40 m from a boundary adjoining rural land outside the plan area, otherwise 5 m from side and rear boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "toowoomba_boundary_adjoins_rural_land_outside_cwea"}]}, "then": 40.0}], "else": 5.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "LOCAL_PLAN", "local_plan": "TRC:CHARLTON_WELLCAMP"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "trc_cwea_ao14_1_side_rear", "role": "PRIMARY",
              "quote": "AO14.1 Buildings are setback: (a) not less than 40m from any boundary adjoining land outside the Charlton Wellcamp Enterprise Area Local Plan area used for rural purposes; ... or otherwise, where not for (a) or (b): (c) a minimum of 5m from any side or rear boundary."}],
 "interpretation_notes": "Limb (b) (70 m from Dry Creek, Westbrook Creek or Spring Creek) is a waterway buffer and is not encoded. Benchmark for code-assessable dwelling houses in the local plan area; TLPI 01/2026 doubt for stand-alone Class 10 => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.CWEA_SIDE_REAR@2026-07-21', 'TRC.trc_cwea_ao14_1_side_rear');

-- ================================================================ HERITAGE / NEIGHBOURHOOD CHARACTER OVERLAYS (AO1.1(a))
SELECT define_rule($r${
 "rule_id": "TRC.C.NC_OVERLAY_OUTBUILDING_FRONT", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Neighbourhood character overlay: new garages, carports and outbuildings equal to or behind the front building line of the primary building",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"var": "toowoomba_primary_building_front_setback_m"},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "OVERLAY", "overlay": "TRC:OV:NEIGHBOURHOOD_CHARACTER_OVERLAY"}],
 "subjects": ["GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_nc_overlay_ao1_1_garage_front", "role": "PRIMARY",
              "quote": "AO1.1 New garages, carports or outbuildings are: (a) set back equal to or behind the front building line30 of the primary building on the site;"}],
 "interpretation_notes": "Class 10a on the site of a Neighbourhood character place is accepted subject to requirements against this code (TLPI 01/2026). 'Front building line' is not defined (footnote 30 is an amendment note), read as the dwelling's main face => not automatable. Not a QDC alternative provision (Table 1.6.2 amenity and aesthetics referral).",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.NC_OVERLAY_OUTBUILDING_FRONT@2026-07-21', 'TRC.trc_nc_overlay_ao1_1_garage_front');
SELECT define_rule($r${
 "rule_id": "TRC.C.HERITAGE_OVERLAY_OUTBUILDING_FRONT", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "SETBACK.FRONTAGE", "title": "Heritage overlay: new garages, carports and outbuildings equal to or behind the alignment of the primary building",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"var": "toowoomba_primary_building_front_setback_m"},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "OVERLAY", "overlay": "TRC:OV:HERITAGE_OVERLAY"}],
 "subjects": ["GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "trc_heritage_overlay_ao1_1_garage_front", "role": "PRIMARY",
              "quote": "AO1.1 New garages, carports or outbuildings are: (a) set back equal to or behind the alignment of the primary building on the site;"}],
 "interpretation_notes": "Class 10a on the site of a Heritage place is accepted subject to requirements against this code (TLPI 01/2026). 'Alignment of the primary building' is undefined, read as the dwelling's front building line => not automatable.",
 "effective_from": "2026-07-21"}$r$);
SELECT supersede_draft('TRC.C.HERITAGE_OVERLAY_OUTBUILDING_FRONT@2026-07-21', 'TRC.trc_heritage_overlay_ao1_1_garage_front');
