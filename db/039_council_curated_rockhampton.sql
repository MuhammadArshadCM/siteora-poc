-- =============================================================================
-- Curated council rules: Rockhampton Regional Council (RRC Planning Scheme 2015) front / side / rear setbacks that
-- reach Class 10 structures. Hand-encoded from the verbatim provisions loaded by db/030_council_rockhampton.sql.
-- Part 1 Table 1.6.1 names only the Low density residential zone code, Low-medium density residential zone code and
-- Character overlay code as QDC MP1.1/MP1.2 alternatives. A dwelling house is Accepted with benchmarks 'Not applicable'
-- in the LDR / LMDR / HDR / Township / Rural residential zones and s5.6 building work is 'Not applicable', so the
-- residential zone setbacks (dual occupancy and assessable development) do not reach a house lot's Class 10 and are
-- decided, not curated. The rules below are planning benchmarks (Rural zone, Emerging community zone, Flood hazard
-- overlay, Filling and excavation code): not QDC alternatives, so no alt_overrides; the QDC applies alongside them.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('rockhampton_road_is_state_controlled','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The road boundary being tested is a State-controlled road (Rockhampton Emerging community zone code Table 6.7.2.3.2 AO12.2)', 'State-controlled road network mapping');

-- =================================================================================== RURAL ZONE (Table 6.7.4.3.1)
SELECT define_rule($r${
 "rule_id": "RRC.C.RURAL_FRONT_20M", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone: dwelling house development set back 20 m from all site boundaries (road boundaries)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 20.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}, {"level": "ZONE", "zone": "RRC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"key": "rrc_rural_dh_front_20m", "role": "PRIMARY", "quote": "AO3.1 ... Development: ... is set back a minimum of twenty (20) metres from all site boundaries"}],
 "interpretation_notes": "Rural zone code is not in Table 1.6.1, so this is a planning benchmark for a dwelling house that is accepted subject to requirements (Table 5.4.6.4); non-compliance makes it assessable. 'All site boundaries' covers every frontage, so all frontage types are encoded. Not automatable: AO3.1 says 'Development' under the heading 'Dwelling house or dwelling unit'; it reaches domestic outbuildings built with the house through the SC1.1 dwelling house definition, but whether it reaches a later stand-alone shed/garage (building work, which s5.6 makes 'Not applicable') is doubtful. Class 10b structures are not encoded. Alton Downs precinct front: RRC.C.ALTON_DOWNS_FRONT_6M overrides.",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.RURAL_FRONT_20M@2025-03-28', 'RRC.rrc_rural_dh_front_20m');

SELECT define_rule($r${
 "rule_id": "RRC.C.RURAL_SIDE_REAR_20M", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural zone: dwelling house development set back 20 m from all site boundaries (side and rear)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 20.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}, {"level": "ZONE", "zone": "RRC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "rrc_rural_dh_side_rear_20m", "role": "PRIMARY", "quote": "AO3.1 ... Development: ... is set back a minimum of twenty (20) metres from all site boundaries"}],
 "interpretation_notes": "Same provision and the same Class 10a reach doubt as RRC.C.RURAL_FRONT_20M, so not automatable. Planning benchmark only: the QDC side/rear clearances (incl. the A2(d) Class 10a concession) still apply alongside it. In the Alton Downs precinct, AO13.1's note 'There is no specific setback to any other boundary' may displace this 20 m (precinct outcomes take precedence where they vary): recorded as UNRESOLVED against RRC.C.ALTON_DOWNS_FRONT_6M; the rule is kept in scope there pending council confirmation.",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.RURAL_SIDE_REAR_20M@2025-03-28', 'RRC.rrc_rural_dh_side_rear_20m');

-- Rural zone, Alton Downs precinct (AO13.1): precinct outcomes take precedence
SELECT define_rule($r${
 "rule_id": "RRC.C.ALTON_DOWNS_FRONT_6M", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone Alton Downs precinct: dwelling house 6 m from front boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}, {"level": "PRECINCT", "precinct": "RRC:RURAL/ALTON_DOWNS"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "rrc_rural_alton_downs_dh_front_6m", "role": "PRIMARY", "quote": "AO13.1 ... A dwelling house is setback a minimum of six (6) metres from front boundaries."},
             {"key": "rrc_rural_alton_downs_dh_front_6m", "role": "SUPPLEMENTARY", "quote": "Where acceptable outcomes in this section vary from this code, the precinct based acceptable outcomes take precedence."}],
 "interpretation_notes": "Overrides the Rural zone 20 m front (precinct outcomes take precedence). 'Front boundaries' (plural) is not defined; only the primary frontage is encoded, secondary road frontages fall back to the zone's 20 m - council to confirm. Not automatable: 'A dwelling house' reaches domestic outbuildings only through the SC1.1 definition, and a later stand-alone shed is doubtful (as RRC.C.RURAL_FRONT_20M). Side/rear interaction with AO3.1 is UNRESOLVED.",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.ALTON_DOWNS_FRONT_6M@2025-03-28', 'RRC.rrc_rural_alton_downs_dh_front_6m');
SELECT relate('RRC.C.ALTON_DOWNS_FRONT_6M@2025-03-28', 'RRC.C.RURAL_FRONT_20M@2025-03-28', 'OVERRIDES', NULL, NULL, 'VERIFIED_VERBATIM',
              'Alton Downs precinct note: where acceptable outcomes in this section vary from this code, the precinct based acceptable outcomes take precedence.');
SELECT relate('RRC.C.ALTON_DOWNS_FRONT_6M@2025-03-28', 'RRC.C.RURAL_SIDE_REAR_20M@2025-03-28', 'UNRESOLVED', NULL, NULL, 'VERIFIED_VERBATIM',
              'AO13.1 note "There is no specific setback to any other boundary" plus the precinct-precedence note may remove the AO3.1 20 m side/rear setback in Alton Downs, or may only mean AO13.1 itself sets none. Council confirmation needed.');

-- =================================================================================== EMERGING COMMUNITY ZONE
-- Table 6.7.2.3.1 AO2.1 (dwelling house accepted subject to requirements, Table 5.4.6.2)
SELECT define_rule($r${
 "rule_id": "RRC.C.EC_SIDE_REAR_6M", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.SIDE_REAR", "title": "Emerging community zone: dwelling house development 6 m from side and rear lot boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}, {"level": "ZONE", "zone": "RRC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "rrc_ec_dh_side_rear_6m", "role": "PRIMARY", "quote": "AO2.1 ... Development: ... is set back a minimum of six (6) metres from side and rear lot boundaries"}],
 "interpretation_notes": "Emerging community zone code is not in Table 1.6.1: planning benchmark only, the QDC applies alongside it. Not automatable: AO2.1 says 'Development' under the heading 'Dwelling house or dwelling unit'; reach to a later stand-alone shed/garage is doubtful (as RRC.C.RURAL_FRONT_20M). No front setback in this table.",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.EC_SIDE_REAR_6M@2025-03-28', 'RRC.rrc_ec_dh_side_rear_6m');

-- Table 6.7.2.3.2 AO12.2 (assessable development only)
SELECT define_rule($r${
 "rule_id": "RRC.C.EC_ASSESSABLE_ROAD_SETBACK", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.FRONTAGE", "title": "Emerging community zone, assessable development: 50 m from State-controlled roads, 20 m from all other roads",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "rockhampton_road_is_state_controlled"}]}, "then": 50.0}], "else": 20.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}, {"level": "ZONE", "zone": "RRC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "rrc_ec_assessable_front_20m", "role": "PRIMARY", "quote": "AO12.2 ... Development is set back: ... - fifty (50) metres from state controlled roads; ... - twenty (20) metres from all other roads; and"}],
 "interpretation_notes": "Table 6.7.2.3.2 applies to assessable development only; a dwelling house is accepted subject to requirements, so this reaches it (and its outbuildings) only once it becomes code assessable. Not automatable: whether a dwelling house that fails AO2.1 is assessed against this table (vs only the corresponding performance outcomes), and whether 'Development' reaches a later shed, needs council confirmation. 'Roads' covers every road frontage.",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.EC_ASSESSABLE_ROAD_SETBACK@2025-03-28', 'RRC.rrc_ec_assessable_front_20m');

SELECT define_rule($r${
 "rule_id": "RRC.C.EC_ASSESSABLE_SIDE_REAR_6M", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.SIDE_REAR", "title": "Emerging community zone, assessable development: 6 m from any other (non-road) boundary",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}, {"level": "ZONE", "zone": "RRC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "rrc_ec_assessable_side_rear_6m", "role": "PRIMARY", "quote": "AO12.2 ... Development is set back: ... - six (6) metres from any other boundary."}],
 "interpretation_notes": "Same value as the accepted-development AO2.1 (RRC.C.EC_SIDE_REAR_6M), so no conflict. Not automatable for the same reasons as RRC.C.EC_ASSESSABLE_ROAD_SETBACK.",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.EC_ASSESSABLE_SIDE_REAR_6M@2025-03-28', 'RRC.rrc_ec_assessable_side_rear_6m');

-- =================================================================================== FLOOD HAZARD OVERLAY (Table 8.2.8.3.1 AO4.1.4)
SELECT define_rule($r${
 "rule_id": "RRC.C.FLOOD_RURAL_CLASS10A_FRONT_20M", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.FRONTAGE", "title": "Flood hazard overlay (high/extreme hazard, local catchment PA1), Rural zone: Class 10a buildings and structures 20 m from all site boundaries (road boundaries)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 20.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}, {"level": "ZONE", "zone": "RRC:RURAL"},
            {"level": "OVERLAY", "overlay": "RRC:OV:FLOOD_HAZARD_OVERLAY_FITZROY_RIVER_FLOOD_AREA_H3_H4_HIGH_OR_H5_H6_EXTREME_OR_LOCAL_CATCHMENT_FLOOD_P"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"key": "rrc_flood_rural_class10a_front_20m", "role": "PRIMARY", "quote": "Where located in the rural zone, the total floor area of class 10a buildings and structures on the site do not exceed a total of fifty (50) square metres, and are set back a minimum of twenty (20) metres from all site boundaries."}],
 "interpretation_notes": "Table 5.9.8 makes dwelling house MCU and building work in these flood areas accepted subject to requirements against this code, so it reaches a later shed/garage directly; the text names class 10a expressly. Flood overlay code is not in Table 1.6.1: planning benchmark, QDC applies alongside. The 50 m2 total class 10a floor area cap is out of scope. 'All site boundaries' covers every frontage. In the Alton Downs precinct this 20 m is stricter than AO13.1's 6 m front and prevails for Class 10a (relationship recorded).",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.FLOOD_RURAL_CLASS10A_FRONT_20M@2025-03-28', 'RRC.rrc_flood_rural_class10a_front_20m');
SELECT relate('RRC.C.FLOOD_RURAL_CLASS10A_FRONT_20M@2025-03-28', 'RRC.C.ALTON_DOWNS_FRONT_6M@2025-03-28', 'OVERRIDES', NULL, NULL, 'UNVERIFIED',
              'Both apply to Class 10a in the Alton Downs precinct within the mapped flood area; the overlay AO4.1.4 20 m is cumulative with and stricter than the precinct 6 m front, and overlays prevail over zone codes under the scheme hierarchy (s1.5 hierarchy not re-read; reviewer to confirm).');

SELECT define_rule($r${
 "rule_id": "RRC.C.FLOOD_RURAL_CLASS10A_SIDE_REAR_20M", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.SIDE_REAR", "title": "Flood hazard overlay (high/extreme hazard, local catchment PA1), Rural zone: Class 10a buildings and structures 20 m from all site boundaries (side and rear)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 20.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}, {"level": "ZONE", "zone": "RRC:RURAL"},
            {"level": "OVERLAY", "overlay": "RRC:OV:FLOOD_HAZARD_OVERLAY_FITZROY_RIVER_FLOOD_AREA_H3_H4_HIGH_OR_H5_H6_EXTREME_OR_LOCAL_CATCHMENT_FLOOD_P"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "rrc_flood_rural_class10a_side_rear_20m", "role": "PRIMARY", "quote": "Where located in the rural zone, the total floor area of class 10a buildings and structures on the site do not exceed a total of fifty (50) square metres, and are set back a minimum of twenty (20) metres from all site boundaries."}],
 "interpretation_notes": "As RRC.C.FLOOD_RURAL_CLASS10A_FRONT_20M. Applies to Class 10a regardless of the Alton Downs side/rear question, because the overlay names class 10a and all site boundaries expressly.",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.FLOOD_RURAL_CLASS10A_SIDE_REAR_20M@2025-03-28', 'RRC.rrc_flood_rural_class10a_side_rear_20m');

-- =================================================================================== FILLING AND EXCAVATION CODE (Table 9.3.3.3.1 AO1.1)
SELECT define_rule($r${
 "rule_id": "RRC.C.RETAINING_WALL_SIDE_REAR_HALF_HEIGHT", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.SIDE_REAR", "title": "Filling and excavation (assessable): retaining walls set back at least half the wall height from side and rear boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "*", "args": [0.5, {"var": "wall_height_m"}]},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}],
 "subjects": ["RETAINING_WALL"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "rrc_retaining_wall_half_height", "role": "PRIMARY", "quote": "Retaining walls are set back at least half the height of the wall from any boundary of the site."}],
 "interpretation_notes": "'Half the height' encoded as 0.5 x wall height. Applies only where filling/excavation is code assessable operational work (Table 5.7.1), hence planning_assessment_required. Not a QDC alternative. The same provision's road-boundary leg is RRC.C.RETAINING_WALL_FRONT_HALF_HEIGHT (the draft is superseded once, here).",
 "effective_from": "2025-03-28"}$r$);
SELECT supersede_draft('RRC.C.RETAINING_WALL_SIDE_REAR_HALF_HEIGHT@2025-03-28', 'RRC.rrc_retaining_wall_half_height');

SELECT define_rule($r${
 "rule_id": "RRC.C.RETAINING_WALL_FRONT_HALF_HEIGHT", "instrument_version": "RRC_PLANNING_SCHEME_2015@2025-03-28",
 "topic": "SETBACK.FRONTAGE", "title": "Filling and excavation (assessable): retaining walls set back at least half the wall height from road boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "*", "args": [0.5, {"var": "wall_height_m"}]},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "ROCKHAMPTON"}],
 "subjects": ["RETAINING_WALL"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"key": "rrc_retaining_wall_half_height", "role": "PRIMARY", "quote": "Retaining walls are set back at least half the height of the wall from any boundary of the site."}],
 "interpretation_notes": "As RRC.C.RETAINING_WALL_SIDE_REAR_HALF_HEIGHT; 'any boundary of the site' includes every frontage.",
 "effective_from": "2025-03-28"}$r$);
