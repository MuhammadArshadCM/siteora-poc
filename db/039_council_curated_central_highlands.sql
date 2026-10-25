-- =============================================================================
-- Curated council rules: Central Highlands Regional Council (CHRC Planning Scheme 2016) front / side / rear setbacks
-- that reach Class 10 structures. Hand-encoded from the verbatim provisions loaded by db/030_council_central_highlands.sql.
-- Dwelling house code Table 8.3.5.3.1 AO1-AO3 are QDC MP1.2 alternative provisions (Table 1.6.1). The scheme's
-- Dwelling house definition includes associated domestic outbuildings and the code note applies it to associated
-- Class 10 domestic outbuildings, so the rules are encoded for CLASS_1 and CLASS_10A. Every other CHRC setback draft
-- is an absence record (the QDC applies) and stays a draft.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('central_highlands_road_is_state_controlled','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The road boundary being tested is a State-controlled road (Central Highlands Dwelling house code Table 8.3.5.3.1 AO1)', 'State-controlled road network mapping');

-- Rural zone excluding the Gemfields precincts: road frontage setback (AO1)
SELECT define_rule($r${
 "rule_id": "CHRC.C.RURAL_ROAD_SETBACK", "instrument_version": "CHRC_PLANNING_SCHEME_2016@2024-06-07",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone (excluding Gemfields precincts): dwelling house incl. domestic outbuildings 100 m from a State-controlled road, 20 m from any other road frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "central_highlands_road_is_state_controlled"}]}, "then": 100.0}], "else": 20.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "CENTRAL_HIGHLANDS"}, {"level": "ZONE", "zone": "CHRC:RURAL"},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_CORE", "exclude": true},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_FRAME", "exclude": true},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_BALANCE", "exclude": true}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "chrc_dh_ao1_rural_front", "role": "PRIMARY",
              "quote": "AO1 In the Rural zone (excluding the Gemfields precincts) the dwelling house is set back at least:- 100m from a State controlled road frontage; and 20m from any other road frontage."}],
 "interpretation_notes": "AO1 says 'the dwelling house'; the row heading is 'Frontage setbacks for buildings and structures', the scheme's Dwelling house definition includes associated domestic outbuildings and the code note applies it to Class 10 domestic outbuildings, so it is encoded for Class 1 and Class 10a. Class 10b structures keep the QDC. 'Any other road frontage' covers every road boundary. State-controlled road status uses a dedicated fact (the Sunshine Coast fact road_is_state_controlled_or_extractive_route also captures extractive routes, which AO1 does not). Gemfields precincts: CHRC.C.GEMFIELDS_FRONT_SETBACK.",
 "effective_from": "2024-06-07"}$r$);
SELECT supersede_draft('CHRC.C.RURAL_ROAD_SETBACK@2024-06-07', 'CHRC.chrc_dh_ao1_rural_front');
SELECT alt_overrides('CHRC.C.RURAL_ROAD_SETBACK@2024-06-07', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.6.1: Dwelling house code PO1 and AO1 are alternative provisions to QDC MP1.2 road boundary setbacks.');

-- Rural zone, Gemfields Core / Frame / Balance precincts: frontage setback (AO2)
SELECT define_rule($r${
 "rule_id": "CHRC.C.GEMFIELDS_FRONT_SETBACK", "instrument_version": "CHRC_PLANNING_SCHEME_2016@2024-06-07",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone Gemfields precincts: dwelling house incl. domestic outbuildings 10 m from the frontage (lot over 1,000 m2), 6 m (1,000 m2 or less)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "lot_area_m2"}, 1000]}, "then": 10.0}], "else": 6.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "CENTRAL_HIGHLANDS"},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_CORE"},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_FRAME"},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_BALANCE"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "chrc_dh_ao2_gemfields_front", "role": "PRIMARY",
              "quote": "AO2 In the Rural zone in a Gemfields precinct the dwelling house is set back:- 10m from the frontage where on a lot greater than 1,000m2; or 6m from the frontage where on a lot 1,000m2 or less."}],
 "interpretation_notes": "AO2 says 'is set back' without 'at least'; read as a minimum because it replaces QDC A1 (a minimum) and PO2 asks that the house be 'sufficiently set back'. AO2 says 'the frontage' (singular), so only the primary frontage is encoded; secondary road frontages keep the QDC. Same Class 10a scope reading as CHRC.C.RURAL_ROAD_SETBACK.",
 "effective_from": "2024-06-07"}$r$);
SELECT supersede_draft('CHRC.C.GEMFIELDS_FRONT_SETBACK@2024-06-07', 'CHRC.chrc_dh_ao2_gemfields_front');
SELECT alt_overrides('CHRC.C.GEMFIELDS_FRONT_SETBACK@2024-06-07', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.6.1: Dwelling house code PO2 and AO2 are alternative provisions to QDC MP1.2 road boundary setbacks.');

-- Rural zone excluding the Gemfields precincts: side and rear (AO3)
SELECT define_rule($r${
 "rule_id": "CHRC.C.RURAL_SIDE_REAR_SETBACK", "instrument_version": "CHRC_PLANNING_SCHEME_2016@2024-06-07",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural zone (excluding Gemfields precincts): dwelling house incl. domestic outbuildings 10 m from side and rear boundaries (lot over 1 ha), 3 m (1 ha or less)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "lot_area_m2"}, 10000]}, "then": 10.0}], "else": 3.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "CENTRAL_HIGHLANDS"}, {"level": "ZONE", "zone": "CHRC:RURAL"},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_CORE", "exclude": true},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_FRAME", "exclude": true},
            {"level": "PRECINCT", "precinct": "CHRC:RURAL/GEMFIELDS_BALANCE", "exclude": true}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "chrc_dh_ao3_rural_side_rear", "role": "PRIMARY",
              "quote": "AO3 In the Rural zone (excluding the Gemfields precincts) the dwelling house is set back from any side or rear boundary a minimum of:- 10m on a lot of more than 1 hectare; or 3m on a lot of 1 hectare or less."}],
 "interpretation_notes": "1 hectare = 10,000 m2. No height banding and no built-to-boundary concession; as AO3 replaces the whole of QDC A2 and the dwelling house includes its domestic outbuildings, the QDC A2(d) Class 10a concession is displaced. Same Class 10a scope reading as CHRC.C.RURAL_ROAD_SETBACK. Gemfields precincts have no side/rear provision (QDC applies; draft CHRC.chrc_gemfields_side_rear_absent).",
 "effective_from": "2024-06-07"}$r$);
SELECT supersede_draft('CHRC.C.RURAL_SIDE_REAR_SETBACK@2024-06-07', 'CHRC.chrc_dh_ao3_rural_side_rear');
SELECT alt_overrides('CHRC.C.RURAL_SIDE_REAR_SETBACK@2024-06-07', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC12.A2b.NARROW_LOT_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE'], 'Table 1.6.1: Dwelling house code PO3 and AO3 are alternative provisions to QDC MP1.2 side and rear boundary clearances.');
