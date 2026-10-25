-- =============================================================================
-- Curated council rules: Burke Shire Council (Burke Shire Planning Scheme 2020, commenced 7 Feb 2020).
-- Class 10 front / side / rear setbacks. Hand-encoded from research/councils/burke.json (loaded as drafts by
-- db/030_council_burke.sql). Each curated rule REPLACES its draft.
--
-- Key finding (research): no provision is a declared QDC alternative provision (s1.6(3) / Table 5.8 only regulate
-- building work at local heritage places and in airport operational airspace). The General development code
-- setback AO5 / Table 7.2.1.4 applies only to assessable development for uses OTHER than Dwelling houses, Dual
-- occupancies and Multiple dwellings, so it never reaches a dwelling house's domestic outbuildings (left as drafts,
-- decision OUT_OF_SCOPE). An accepted dwelling house (and later Class 10 building work without an MCU) gets no
-- council setback: the QDC applies (absence drafts kept). The zone code setbacks below are planning benchmarks that
-- apply only when the dwelling house MCU is code assessable (Tables 5.5.1 / 5.5.3 / 5.5.4 "Otherwise").
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('burke_zone_code_applies','BOOLEAN',NULL,NULL,'PLANNING_DATA','Burke: the development (dwelling house MCU incl. its domestic outbuildings) is code assessable against the zone code (Tables 5.5.1 / 5.5.3 / 5.5.4 "Otherwise" row). False for accepted development subject to requirements (General development code only) and for Class 10 building work without an MCU (Table 5.8 accepted).', 'Township: not in the Residential precinct. Rural residential: not accepted subject to requirements. Rural: more than two dwellings, or bushfire prone (SPP mapping), or an identified abandoned mine area.'),
 ('burke_boundary_road_is_state_controlled','BOOLEAN',NULL,NULL,'PROPERTY_DATA','Burke: the boundary being tested adjoins a State-controlled road (Rural residential / Rural zone code AO1)', 'State-controlled road network mapping'),
 ('burke_boundary_adjoins_residential_precinct','BOOLEAN',NULL,NULL,'PLANNING_DATA','Burke: the boundary being tested is shared with land in the Township zone Residential precinct (Township zone code AO12.1)', 'Zone / precinct mapping of the adjoining lot');

-- ============================================================================ RURAL RESIDENTIAL ZONE
SELECT define_rule($r${
 "rule_id": "BSC.C.RR_FRONT_SETBACK", "instrument_version": "BSC_PLANNING_SCHEME_2020@2020-02-07",
 "topic": "SETBACK.FRONTAGE", "title": "Rural residential zone (code assessable): buildings and structures 20 m from a State-controlled road, otherwise 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "burke_boundary_road_is_state_controlled"}]}, "then": 20.0}], "else": 6.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BURKE"}, {"level": "ZONE", "zone": "BSC:RURAL_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"key": "bsc_rr_ao1_front_setback", "role": "PRIMARY",
              "quote": "AO1 Buildings and structures are setback 20m from a State-controlled road otherwise 6m from all boundaries."}],
 "interpretation_notes": "Zone code (Table 6.2.3.2 AO1) applies only when the dwelling house is code assessable (Table 5.5.3 'Otherwise'); an accepted dwelling house and later Class 10 building work (Table 5.8 accepted) get no council setback, so the QDC applies. Not a QDC alternative provision (s1.6(3), Table 5.8): planning benchmark only, the QDC still applies alongside. '6m from all boundaries' covers every frontage type. Table 7.2.1.4 (GDC AO5) excludes Dwelling houses and is not encoded.",
 "effective_from": "2020-02-07"}$r$);
SELECT supersede_draft('BSC.C.RR_FRONT_SETBACK@2020-02-07', 'BSC.bsc_rr_ao1_front_setback');

SELECT define_rule($r${
 "rule_id": "BSC.C.RR_SIDE_REAR_SETBACK", "instrument_version": "BSC_PLANNING_SCHEME_2020@2020-02-07",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural residential zone (code assessable): buildings and structures 6 m from side and rear boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BURKE"}, {"level": "ZONE", "zone": "BSC:RURAL_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "bsc_rr_ao1_side_rear_setback", "role": "PRIMARY",
              "quote": "AO1 Buildings and structures are setback 20m from a State-controlled road otherwise 6m from all boundaries."}],
 "interpretation_notes": "As BSC.C.RR_FRONT_SETBACK: applies only to a code assessable dwelling house (Table 5.5.3 'Otherwise'); planning benchmark, not a QDC alternative provision. Side/rear boundaries are not road boundaries, so the 6 m limb applies. No built-to-boundary allowance for Class 10 is stated.",
 "effective_from": "2020-02-07"}$r$);
SELECT supersede_draft('BSC.C.RR_SIDE_REAR_SETBACK@2020-02-07', 'BSC.bsc_rr_ao1_side_rear_setback');

-- ======================================================================================== RURAL ZONE
SELECT define_rule($r${
 "rule_id": "BSC.C.RURAL_FRONT_SETBACK", "instrument_version": "BSC_PLANNING_SCHEME_2020@2020-02-07",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone (code assessable): buildings and structures 20 m from a State-controlled road, otherwise 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "burke_boundary_road_is_state_controlled"}]}, "then": 20.0}], "else": 6.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BURKE"}, {"level": "ZONE", "zone": "BSC:RURAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"key": "bsc_rural_ao1_front_setback", "role": "PRIMARY",
              "quote": "AO1 Buildings and structures are setback 20m from a State-controlled road otherwise 6m from all boundaries."}],
 "interpretation_notes": "Zone code (Table 6.2.4.2 AO1) applies only when the dwelling house is code assessable (Table 5.5.4: more than two dwellings, bushfire prone, or abandoned mine area); otherwise accepted subject to requirements against the GDC only, and Class 10 building work without an MCU is accepted (Table 5.8): QDC applies. Not a QDC alternative provision: planning benchmark only. Table 7.2.1.4's 10 m Rural front setback excludes Dwelling houses and defers to the zone code (AO5), so it is not encoded.",
 "effective_from": "2020-02-07"}$r$);
SELECT supersede_draft('BSC.C.RURAL_FRONT_SETBACK@2020-02-07', 'BSC.bsc_rural_ao1_front_setback');

SELECT define_rule($r${
 "rule_id": "BSC.C.RURAL_SIDE_REAR_SETBACK", "instrument_version": "BSC_PLANNING_SCHEME_2020@2020-02-07",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural zone (code assessable): buildings and structures 6 m from side and rear boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BURKE"}, {"level": "ZONE", "zone": "BSC:RURAL"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "bsc_rural_ao1_side_rear_setback", "role": "PRIMARY",
              "quote": "AO1 Buildings and structures are setback 20m from a State-controlled road otherwise 6m from all boundaries."}],
 "interpretation_notes": "As BSC.C.RURAL_FRONT_SETBACK: applies only to a code assessable dwelling house; planning benchmark, not a QDC alternative provision. Side/rear boundaries are not road boundaries, so the 6 m limb applies.",
 "effective_from": "2020-02-07"}$r$);
SELECT supersede_draft('BSC.C.RURAL_SIDE_REAR_SETBACK@2020-02-07', 'BSC.bsc_rural_ao1_side_rear_setback');

-- ======================================================================== TOWNSHIP COMMERCIAL PRECINCT
SELECT define_rule($r${
 "rule_id": "BSC.C.TOWNSHIP_COMMERCIAL_RES_BOUNDARY_2M", "instrument_version": "BSC_PLANNING_SCHEME_2020@2020-02-07",
 "topic": "SETBACK.SIDE_REAR", "title": "Township zone Commercial precinct: buildings 2 m from a boundary shared with a residential precinct",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 2.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BURKE"}, {"level": "PRECINCT", "precinct": "BSC:TOWNSHIP/COMMERCIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]},
                 {"fact": "burke_boundary_adjoins_residential_precinct", "op": "IS_TRUE"}]],
 "sources": [{"key": "bsc_township_commercial_ao12_1_side_rear_setback", "role": "PRIMARY",
              "quote": "AO12.1 Buildings are set back 2m from any boundary shared with a residential precinct."}],
 "interpretation_notes": "A dwelling house in the Commercial precinct is code assessable against the Township zone code (Table 5.5.1 'Otherwise'), so AO12.1 reaches its buildings incl. Class 10a outbuildings; later Class 10 building work without an MCU is accepted (Table 5.8). Not automatable: the research left open whether this commercial-amenity AO (PO12 refers to land 'in a residential zone') is meant to apply to dwelling house outbuildings; reviewer to confirm. Planning benchmark only, not a QDC alternative provision.",
 "effective_from": "2020-02-07"}$r$);
SELECT supersede_draft('BSC.C.TOWNSHIP_COMMERCIAL_RES_BOUNDARY_2M@2020-02-07', 'BSC.bsc_township_commercial_ao12_1_side_rear_setback');
