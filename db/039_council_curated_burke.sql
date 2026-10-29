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
 ('burke_zone_code_applies','BOOLEAN',NULL,NULL,'PLANNING_DATA','Burke: the Class 10 building work (no MCU) is code assessable under Table 5.8 (General development code) - not the dwelling house MCU tables 5.5.1/5.5.3/5.5.4, which do not reach building work on an existing dwelling house lot. Table 5.8 accepted development is unconditional except for two triggers: within 50m of a Schedule 5 local heritage place, or within the Burketown Airport operational airspace (Schedule 2 maps BTN AF1/BTN AF2).', 'TRUE if burke_near_local_heritage_place. FALSE if not near heritage AND burke_near_burketown_airport is false (>5km from the airport). Otherwise left unresolved: the airport''s obstacle limitation surface is not published as GIS and is not safely reconstructable from the scheme''s static map without the exact runway geometry - see poc/site_layers.json BURKE notes.'),
 ('burke_near_local_heritage_place','BOOLEAN',NULL,NULL,'PROPERTY_DATA','Burke: the lot is within 50m of a Schedule 5 local heritage register parcel (Table 5.8)', 'State cadastre (lot/plan match against Table SC6.1), partial: see poc/site_layers.json BURKE notes for which of the 9 listed places still resolve'),
 ('burke_near_burketown_airport','BOOLEAN',NULL,NULL,'PROPERTY_DATA','Burke: the lot is within 5km of the Burketown Airport reference point - a deliberately generous outer bound on its operational airspace, not the mapped boundary (Table 5.8)', 'State/council airport point layer, distance only'),
 ('burke_boundary_road_is_state_controlled','BOOLEAN',NULL,NULL,'PROPERTY_DATA','Burke: the boundary being tested adjoins a State-controlled road (Rural residential / Rural zone code AO1)', 'State-controlled road network mapping'),
 ('burke_boundary_adjoins_residential_precinct','BOOLEAN',NULL,NULL,'PLANNING_DATA','Burke: the boundary being tested is shared with land in the Township zone Residential precinct (Township zone code AO12.1)', 'State cadastre: parcels that share a boundary with this lot (Touches, not a distance buffer), each checked against the Burke Precincts map. TRUE if any neighbour is in the Residential precinct, FALSE only once every neighbour found has been checked and none is; left unresolved if the lookup fails or finds no neighbour at all (a true neighbour can be missed by a tiny digitising gap, so that case is not read as "isolated lot = false").');

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
 "conditions": [[{"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"key": "bsc_rr_ao1_front_setback", "role": "PRIMARY",
              "quote": "AO1 Buildings and structures are setback 20m from a State-controlled road otherwise 6m from all boundaries."}],
 "interpretation_notes": "Zone code (Table 6.2.3.2 AO1) applies only when the Class 10 building work is code assessable under Table 5.8 (burke_zone_code_applies); otherwise it is accepted development and the QDC applies. Not gated on the generic 'planning_assessment_required' fact (that fact is a blanket ASSUMED-false default used by other councils' MCU-based rules; Burke's actual trigger for building work is Table 5.8, which burke_zone_code_applies already captures in full - see its fact description). Not a QDC alternative provision (s1.6(3), Table 5.8): planning benchmark only, the QDC still applies alongside. '6m from all boundaries' covers every frontage type. Table 7.2.1.4 (GDC AO5) excludes Dwelling houses and is not encoded.",
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
 "conditions": [[{"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "bsc_rr_ao1_side_rear_setback", "role": "PRIMARY",
              "quote": "AO1 Buildings and structures are setback 20m from a State-controlled road otherwise 6m from all boundaries."}],
 "interpretation_notes": "As BSC.C.RR_FRONT_SETBACK: applies only when the Class 10 building work is code assessable under Table 5.8 (burke_zone_code_applies), not the generic 'planning_assessment_required' default; planning benchmark, not a QDC alternative provision. Side/rear boundaries are not road boundaries, so the 6 m limb applies. No built-to-boundary allowance for Class 10 is stated.",
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
 "conditions": [[{"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD", "SECONDARY_FRONTAGE_LANE_PARKWAY", "SECONDARY_FRONTAGE_OTHER"]}]],
 "sources": [{"key": "bsc_rural_ao1_front_setback", "role": "PRIMARY",
              "quote": "AO1 Buildings and structures are setback 20m from a State-controlled road otherwise 6m from all boundaries."}],
 "interpretation_notes": "Zone code (Table 6.2.4.2 AO1) applies only when the Class 10 building work is code assessable under Table 5.8 (burke_zone_code_applies: the Rural zone's own dwelling-house-MCU trigger in Table 5.5.4 - more than two dwellings, bushfire prone, abandoned mine area - does not reach building work on an existing lot); otherwise accepted development and the QDC applies. Not gated on the generic 'planning_assessment_required' fact (see BSC.C.RR_FRONT_SETBACK). Not a QDC alternative provision: planning benchmark only. Table 7.2.1.4's 10 m Rural front setback excludes Dwelling houses and defers to the zone code (AO5), so it is not encoded.",
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
 "conditions": [[{"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "bsc_rural_ao1_side_rear_setback", "role": "PRIMARY",
              "quote": "AO1 Buildings and structures are setback 20m from a State-controlled road otherwise 6m from all boundaries."}],
 "interpretation_notes": "As BSC.C.RURAL_FRONT_SETBACK: applies only when the Class 10 building work is code assessable under Table 5.8 (burke_zone_code_applies), not the generic 'planning_assessment_required' default; planning benchmark, not a QDC alternative provision. Side/rear boundaries are not road boundaries, so the 6 m limb applies.",
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
 "conditions": [[{"fact": "burke_zone_code_applies", "op": "IS_TRUE"},
                 {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]},
                 {"fact": "burke_boundary_adjoins_residential_precinct", "op": "IS_TRUE"}]],
 "sources": [{"key": "bsc_township_commercial_ao12_1_side_rear_setback", "role": "PRIMARY",
              "quote": "AO12.1 Buildings are set back 2m from any boundary shared with a residential precinct."}],
 "interpretation_notes": "Class 10 building work on an existing dwelling house lot is governed by Table 5.8 (burke_zone_code_applies), the same as every other zone/precinct - a new dwelling house MCU in the Commercial precinct is separately always code assessable (Table 5.5.1 'Otherwise', no accepted pathway), but that MCU table does not reach later building work. Not gated on the generic 'planning_assessment_required' fact (see BSC.C.RR_FRONT_SETBACK): that bug previously made this rule silently vanish rather than surface for review. Not automatable: the research left open whether this commercial-amenity AO (PO12 refers to land 'in a residential zone') is meant to apply to dwelling house outbuildings at all; reviewer to confirm. Planning benchmark only, not a QDC alternative provision.",
 "effective_from": "2020-02-07"}$r$);
SELECT supersede_draft('BSC.C.TOWNSHIP_COMMERCIAL_RES_BOUNDARY_2M@2020-02-07', 'BSC.bsc_township_commercial_ao12_1_side_rear_setback');
