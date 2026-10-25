-- =============================================================================
-- Curated council rules: Townsville City Plan 2014 — front / side / rear setbacks reaching Class 10 structures.
-- Hand-encoded from research/councils/townsville.json (loaded as drafts by db/030_council_townsville.sql).
-- Part 1 Table 1.6.1 names only the Character residential zone code as QDC alternative provisions (s33 Building Act).
-- Not curated (see decisions): tcc_cr_class10a_carport_garage_front (AO9(a), a relative "as far back as the main
-- building" rule). Absence drafts (tcc_*_absent) stay as the record that the QDC applies.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('townsville_contributing_neighbour_avg_front_setback_m','NUMBER','m',NULL,'PROPERTY_DATA','Average front setback of the adjoining contributing character buildings (Townsville Character residential zone code AO14.1)', 'Needs the scheme''s contributing character building identification for the adjoining lots and their street setbacks');

-- ================================================================ CHARACTER RESIDENTIAL ZONE (Table 6.2.5.3)
SELECT define_rule($r${
 "rule_id": "TCC.C.CR_FRONT_SETBACK_AVERAGE", "instrument_version": "TCC_CITY_PLAN_2014@2025-12-08",
 "topic": "SETBACK.FRONTAGE", "title": "Character residential: buildings set back within 10% of the average front setback of adjoining contributing character buildings (minimum encoded: 90%)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "*", "args": [0.9, {"var": "townsville_contributing_neighbour_avg_front_setback_m"}]},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOWNSVILLE"}, {"level": "ZONE", "zone": "TCC:CHARACTER_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}, {"fact": "planning_assessment_required", "op": "IS_TRUE"}]],
 "sources": [{"key": "tcc_cr_buildings_front_setback_average", "role": "PRIMARY",
              "quote": "Buildings and extensions are setback from street frontages within 10% of the average front setback of adjoining contributing character buildings."}],
 "interpretation_notes": "AO14.1 applies to assessable development only (Table 5.7.1). 'Street frontages' => primary and secondary road frontages. 'Within 10%' also implies a 110% maximum (noted for the geometry layer, not encoded). Carports and garages are governed by the more specific AO9(a) (not curated, manual review) and are excluded here. Not automatable: whether 'buildings' reaches stand-alone Class 10a outbuildings is unclear (research flagged it), and identifying adjoining contributing character buildings needs data not held.",
 "effective_from": "2025-12-08"}$r$);
SELECT supersede_draft('TCC.C.CR_FRONT_SETBACK_AVERAGE@2025-12-08', 'TCC.tcc_cr_buildings_front_setback_average');
SELECT alt_overrides('TCC.C.CR_FRONT_SETBACK_AVERAGE@2025-12-08', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Part 1 Table 1.6.1; Table 6.2.5.3 editor''s note: Character residential zone code is the s33 alternative provision for dwelling houses.');

-- ================================================================ RURAL ZONE, CUNGULLA PRECINCT (Table 6.6.1.3 AO3.2)
SELECT define_rule($r${
 "rule_id": "TCC.C.RURAL_CUNGULLA_FRONT_6M", "instrument_version": "TCC_CITY_PLAN_2014@2025-12-08",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone, Cungulla precinct: dwellings and ancillary structures 6 m from front boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOWNSVILLE"}, {"level": "PRECINCT", "precinct": "TCC:RURAL/CUNGULLA"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "tcc_rural_cungulla_front", "role": "PRIMARY",
              "quote": "other than in the Cungulla precinct where dwellings and ancillary structures are set back a minimum of 6m from front boundaries"}],
 "interpretation_notes": "Planning benchmark (accepted development subject to requirements / assessable, Table 5.5.21), not a QDC alternative (Table 1.6.1). 'Ancillary structures' read as Class 10a buildings; Class 10b (pools, fences) not encoded. Not automatable: whether AO3.2 binds a later stand-alone Class 10a building (building work with no material change of use) is unclear.",
 "effective_from": "2025-12-08"}$r$);
SELECT supersede_draft('TCC.C.RURAL_CUNGULLA_FRONT_6M@2025-12-08', 'TCC.tcc_rural_cungulla_front');

SELECT define_rule($r${
 "rule_id": "TCC.C.RURAL_CUNGULLA_SIDE_ROAD_3M", "instrument_version": "TCC_CITY_PLAN_2014@2025-12-08",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Rural zone, Cungulla precinct: dwellings and ancillary structures 3 m from a side boundary adjoining a road",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOWNSVILLE"}, {"level": "PRECINCT", "precinct": "TCC:RURAL/CUNGULLA"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "tcc_rural_cungulla_side_rear", "role": "PRIMARY",
              "quote": "dwellings and ancillary structures are set back a minimum of 6m from front boundaries, 3m from side boundaries where adjoining a road"}],
 "interpretation_notes": "A side boundary adjoining a road is classified SECONDARY_FRONTAGE_ROAD. Same doubt as TCC.C.RURAL_CUNGULLA_FRONT_6M (stand-alone Class 10a building work) => not automatable.",
 "effective_from": "2025-12-08"}$r$);

SELECT define_rule($r${
 "rule_id": "TCC.C.RURAL_CUNGULLA_SIDE_REAR_1_5M", "instrument_version": "TCC_CITY_PLAN_2014@2025-12-08",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural zone, Cungulla precinct: dwellings and ancillary structures 1.5 m from other side and rear boundaries",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOWNSVILLE"}, {"level": "PRECINCT", "precinct": "TCC:RURAL/CUNGULLA"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "tcc_rural_cungulla_side_rear", "role": "PRIMARY",
              "quote": "dwellings and ancillary structures are set back a minimum of 6m from front boundaries, 3m from side boundaries where adjoining a road or 1.5m otherwise for side and rear boundaries."}],
 "interpretation_notes": "Road-adjoining side boundaries: TCC.C.RURAL_CUNGULLA_SIDE_ROAD_3M. No built-to-boundary concession for Class 10a. Same doubt as TCC.C.RURAL_CUNGULLA_FRONT_6M => not automatable.",
 "effective_from": "2025-12-08"}$r$);
SELECT supersede_draft('TCC.C.RURAL_CUNGULLA_SIDE_REAR_1_5M@2025-12-08', 'TCC.tcc_rural_cungulla_side_rear');
