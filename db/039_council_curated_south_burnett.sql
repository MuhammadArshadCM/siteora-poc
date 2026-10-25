-- =============================================================================
-- Curated council rules: South Burnett Regional Council (SBRC Planning Scheme 2017, v2.0 effective 28 Oct 2024).
-- Front / side / rear setbacks that reach Class 10 structures. Hand-encoded from the verbatim provisions loaded by
-- db/030_council_south_burnett.sql. Each curated rule REPLACES its draft.
--
-- QDC relationship: s1.6(4) / Table 1.6.1 lists only the bushfire prone area designation as a building assessment
-- provision. No zone-code setback is a s33 Building Act alternative provision, so every rule here is a PLANNING
-- benchmark (no alt_overrides): the QDC MP1.1/MP1.2 boundary clearances continue to apply alongside these rules.
-- Absence drafts (verbatim text starting with "(") stay as drafts recording that the QDC applies.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('south_burnett_road_is_collector_or_higher','BOOLEAN',NULL,NULL,'PLANNING_DATA','The road boundary being tested is a collector or higher order road (South Burnett Rural zone code AO1.1); the scheme does not define the road hierarchy', 'Council / State road hierarchy mapping (not defined in SC1)');

-- ============================================================ Low density residential zone, AO2.5 ("Buildings")
SELECT define_rule($r${
 "rule_id": "SBRC.C.LDR_FRONT_PRIMARY_6M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.FRONTAGE", "title": "Low density residential: buildings 6 m from the primary street frontage (code assessment)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "sbrc_ldr_buildings_front", "role": "PRIMARY", "quote": "AO2.5 Buildings are set back at least: (a) 6m from the primary street frontage;"}],
 "interpretation_notes": "Table 5.5.1: a dwelling house is accepted development (no requirements) outside the Bunya Mountains Precinct, and ADSR there against Section 4 only (no setbacks). AO2.5 reaches a dwelling house and its outbuildings only through code assessment, which s5.3.3(4)(b) may limit to the failed Section 4 matters, so automatable is false. Not a QDC alternative (Table 1.6.1): the QDC also applies.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.LDR_FRONT_PRIMARY_6M@2024-10-28', 'SBRC.sbrc_ldr_buildings_front');

SELECT define_rule($r${
 "rule_id": "SBRC.C.LDR_FRONT_SECONDARY_4_5M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Low density residential: buildings 4.5 m from any secondary street frontage (code assessment)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 4.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "sbrc_ldr_buildings_front", "role": "PRIMARY", "quote": "(b) 4.5m from any secondary street frontage;"}],
 "interpretation_notes": "Limb (b) of the same AO2.5 as SBRC.C.LDR_FRONT_PRIMARY_6M (the draft is superseded once, by that rule). Same code-assessment reach doubt (Table 5.5.1, s5.3.3(4)(b)).",
 "effective_from": "2024-10-28"}$r$);

SELECT define_rule($r${
 "rule_id": "SBRC.C.LDR_SIDE_1_5M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.SIDE", "title": "Low density residential: buildings 1.5 m from side boundaries (code assessment)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "sbrc_ldr_buildings_side", "role": "PRIMARY", "quote": "(c) 1.5m from side boundaries;"}],
 "interpretation_notes": "Same code-assessment reach doubt as SBRC.C.LDR_FRONT_PRIMARY_6M. No Class 10a built-to-boundary concession in AO2.5; the QDC A2(d) concession is not displaced because AO2.5 is not an alternative provision.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.LDR_SIDE_1_5M@2024-10-28', 'SBRC.sbrc_ldr_buildings_side');

SELECT define_rule($r${
 "rule_id": "SBRC.C.LDR_REAR_6M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.REAR", "title": "Low density residential: buildings 6 m from rear boundaries (code assessment)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "sbrc_ldr_buildings_rear", "role": "PRIMARY", "quote": "and (d) 6m from rear boundaries."}],
 "interpretation_notes": "Same code-assessment reach doubt as SBRC.C.LDR_FRONT_PRIMARY_6M.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.LDR_REAR_6M@2024-10-28', 'SBRC.sbrc_ldr_buildings_rear');

-- ============================================================ Low density residential zone, Section 5 small lot dwelling houses (< 400 m2)
SELECT define_rule($r${
 "rule_id": "SBRC.C.LDR_SMALL_LOT_FRONT", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.FRONTAGE", "title": "Low density residential small lot (< 400 m2): front 6 m, or the setback of an adjoining dwelling house if less",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "=", "args": [{"var": "has_adjoining_dwelling"}, false]}, "then": 6.0}],
           "else": {"op": "min", "args": [6.0, {"op": "min_of", "args": [{"var": "adjoining_road_setbacks_m"}]}]}},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "lot_area_m2", "op": "<", "value": 400},
                 {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "sbrc_ldr_small_lot_front", "role": "PRIMARY",
              "quote": "For houses on lots less than 400m2 ... AO12.1 The minimum front setback is 6m or, if any adjoining dwelling house is set back less than 6m, that setback."}],
 "interpretation_notes": "Unlike Medium density residential, Table 5.5.1 makes a LDR dwelling house accepted development (no requirements) regardless of lot size outside the Bunya Mountains Precinct, and the Bunya ADSR nominates Section 4 only, so Section 5 reaches a dwelling house only through code assessment: hence planning_assessment_required. 'Houses' read with the Dwelling house definition (SC1.1: includes any domestic outbuildings), so domestic outbuildings are listed as subjects, but whether a detached Class 10a is caught is a doubt: automatable false. 'That setback' read as the least adjoining dwelling setback (adjoining_road_setbacks_m); 'front' read as the primary street frontage.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.LDR_SMALL_LOT_FRONT@2024-10-28', 'SBRC.sbrc_ldr_small_lot_front');

SELECT define_rule($r${
 "rule_id": "SBRC.C.LDR_SMALL_LOT_SIDE_1M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.SIDE", "title": "Low density residential small lot (< 400 m2): side boundaries 1 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "lot_area_m2", "op": "<", "value": 400},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "sbrc_ldr_small_lot_side", "role": "PRIMARY", "quote": "For houses on lots less than 400m2 ... AO12.2 The minimum setback from side boundaries is 1m."}],
 "interpretation_notes": "As SBRC.C.LDR_SMALL_LOT_FRONT: reaches a dwelling house only via code assessment (Table 5.5.1), and the outbuilding reach of 'houses' is a doubt.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.LDR_SMALL_LOT_SIDE_1M@2024-10-28', 'SBRC.sbrc_ldr_small_lot_side');

SELECT define_rule($r${
 "rule_id": "SBRC.C.LDR_SMALL_LOT_REAR_6M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.REAR", "title": "Low density residential small lot (< 400 m2): rear boundary 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:LOW_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "lot_area_m2", "op": "<", "value": 400},
                 {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "sbrc_ldr_small_lot_rear", "role": "PRIMARY", "quote": "For houses on lots less than 400m2 ... AO12.3 The minimum setback from the rear boundary is 6m"}],
 "interpretation_notes": "As SBRC.C.LDR_SMALL_LOT_FRONT. Same value as AO2.5(d) (SBRC.C.LDR_REAR_6M), so no conflict.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.LDR_SMALL_LOT_REAR_6M@2024-10-28', 'SBRC.sbrc_ldr_small_lot_rear');

-- On a code-assessable small lot both AO2.5 and Section 5 can apply with different front / side values.
SELECT relate('SBRC.C.LDR_SMALL_LOT_FRONT@2024-10-28', 'SBRC.C.LDR_FRONT_PRIMARY_6M@2024-10-28', 'OVERRIDES', NULL, NULL, 'VERIFIED_VERBATIM', 'Section 5 "For houses on lots less than 400m2" is the specific provision for small-lot dwelling houses; it prevails over the general AO2.5 "Buildings" setback.');
SELECT relate('SBRC.C.LDR_SMALL_LOT_SIDE_1M@2024-10-28', 'SBRC.C.LDR_SIDE_1_5M@2024-10-28', 'OVERRIDES', NULL, NULL, 'VERIFIED_VERBATIM', 'Section 5 "For houses on lots less than 400m2" is the specific provision for small-lot dwelling houses; it prevails over the general AO2.5 "Buildings" setback.');

-- ============================================================ Medium density residential zone, Section 5 small lot dwelling houses (< 400 m2)
-- Table 5.5.2: a dwelling house on a lot < 400 m2 is not accepted development, so it is ADSR against Sections 5 & 6.
SELECT define_rule($r${
 "rule_id": "SBRC.C.MDR_SMALL_LOT_FRONT", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.FRONTAGE", "title": "Medium density residential small lot (< 400 m2): front 6 m, or the setback of an adjoining dwelling house if less",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "=", "args": [{"var": "has_adjoining_dwelling"}, false]}, "then": 6.0}],
           "else": {"op": "min", "args": [6.0, {"op": "min_of", "args": [{"var": "adjoining_road_setbacks_m"}]}]}},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "sbrc_mdr_small_lot_front", "role": "PRIMARY",
              "quote": "For houses on lots less than 400m2 ... AO20.1 The minimum front setback is 6m or, if any adjoining dwelling house is set back less than 6m, that setback."}],
 "interpretation_notes": "Table 5.5.2: a dwelling house on a lot under 400 m2 is ADSR against Sections 5 & 6 AOs, so this applies without planning_assessment_required. 'Houses' read with the Dwelling house definition (SC1.1: includes any domestic outbuildings), so domestic outbuildings are listed as subjects, but whether a detached Class 10a is caught is a doubt: automatable false. 'That setback' read as the least adjoining dwelling setback. Open question: Planning Regulation Sch 6 Pt 2 s2 may limit the lot-size trigger.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.MDR_SMALL_LOT_FRONT@2024-10-28', 'SBRC.sbrc_mdr_small_lot_front');

SELECT define_rule($r${
 "rule_id": "SBRC.C.MDR_SMALL_LOT_SIDE_1M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.SIDE", "title": "Medium density residential small lot (< 400 m2): side boundaries 1 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "sbrc_mdr_small_lot_side", "role": "PRIMARY", "quote": "For houses on lots less than 400m2 ... AO20.2 The minimum setback from side boundaries is 1m."}],
 "interpretation_notes": "As SBRC.C.MDR_SMALL_LOT_FRONT (outbuilding reach of 'houses' is a doubt). Not a QDC alternative: the QDC Class 10a built-to-boundary concession is not displaced.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.MDR_SMALL_LOT_SIDE_1M@2024-10-28', 'SBRC.sbrc_mdr_small_lot_side');

SELECT define_rule($r${
 "rule_id": "SBRC.C.MDR_SMALL_LOT_REAR_6M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.REAR", "title": "Medium density residential small lot (< 400 m2): rear boundary 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 400}, {"fact": "boundary_type", "op": "=", "value": "REAR"}]],
 "sources": [{"key": "sbrc_mdr_small_lot_rear", "role": "PRIMARY", "quote": "For houses on lots less than 400m2 ... AO20.3 The minimum setback from the rear boundary is 6m"}],
 "interpretation_notes": "As SBRC.C.MDR_SMALL_LOT_FRONT (outbuilding reach of 'houses' is a doubt).",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.MDR_SMALL_LOT_REAR_6M@2024-10-28', 'SBRC.sbrc_mdr_small_lot_rear');

-- ============================================================ Rural zone, AO1.1
SELECT define_rule($r${
 "rule_id": "SBRC.C.RURAL_ROAD_SETBACK", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone: buildings 20 m from a collector or higher order road, 10 m from any other road frontage",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "south_burnett_road_is_collector_or_higher"}]}, "then": 20.0}], "else": 10.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "sbrc_rural_buildings_road", "role": "PRIMARY", "quote": "AO1.1 Buildings are set back 20m from any collector or higher order road and 10m from any other road frontage."}],
 "interpretation_notes": "Applies to every road frontage. Table 5.5.13: a dwelling house is accepted development with no requirements unless it includes a secondary dwelling (then ADSR against Section 1, which includes AO1.1) or is otherwise assessable: hence planning_assessment_required. 'Collector or higher order road' is not defined in SC1 and needs road hierarchy mapping (fact south_burnett_road_is_collector_or_higher), so automatable false.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.RURAL_ROAD_SETBACK@2024-10-28', 'SBRC.sbrc_rural_buildings_road');

-- ============================================================ Rural residential zone, AO1.3
SELECT define_rule($r${
 "rule_id": "SBRC.C.RR_ROAD_10M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.FRONTAGE", "title": "Rural residential: buildings 10 m to the road frontage (code assessment)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:RURAL_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "sbrc_rr_buildings_road", "role": "PRIMARY", "quote": "AO1.3 Buildings have a minimum set back of: (a) 10m to the road frontage;"}],
 "interpretation_notes": "Table 5.5.14: a dwelling house is accepted development unless it includes a secondary dwelling (ADSR against Section 4 only, no setbacks). AO1.3 reaches a dwelling house and its outbuildings only through code assessment, which s5.3.3(4)(b) may limit to the failed Section 4 matters: automatable false. 'The road frontage' (singular) encoded for the primary frontage only; whether it also covers a secondary road frontage on a corner lot needs review.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.RR_ROAD_10M@2024-10-28', 'SBRC.sbrc_rr_buildings_road');

SELECT define_rule($r${
 "rule_id": "SBRC.C.RR_SIDE_REAR_6M", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural residential: buildings 6 m to a side or rear boundary (code assessment)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:RURAL_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "sbrc_rr_buildings_side_rear", "role": "PRIMARY", "quote": "(b) 6m to a side or rear boundary."}],
 "interpretation_notes": "Same code-assessment reach doubt as SBRC.C.RR_ROAD_10M (Table 5.5.14, s5.3.3(4)(b)).",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.RR_SIDE_REAR_6M@2024-10-28', 'SBRC.sbrc_rr_buildings_side_rear');

-- ============================================================ Township zone, AO2.2 / AO2.3
SELECT define_rule($r${
 "rule_id": "SBRC.C.TOWNSHIP_ROAD_SETBACK", "instrument_version": "SBRC_PLANNING_SCHEME_2017@2024-10-28",
 "topic": "SETBACK.FRONTAGE", "title": "Township zone: buildings at the average road setback of the 2 adjoining buildings, else at least 3 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "=", "args": [{"var": "adjoining_dwellings_both_sides"}, false]}, "then": 3.0},
    {"if": {"op": ">", "args": [{"op": "avg_of", "args": [{"var": "adjoining_road_setbacks_m"}]}, 6]}, "then": 3.0}],
   "else": {"op": "avg_of", "args": [{"var": "adjoining_road_setbacks_m"}]}},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SOUTH_BURNETT"}, {"level": "ZONE", "zone": "SBRC:TOWNSHIP"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "planning_assessment_required", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "sbrc_township_buildings_road", "role": "PRIMARY",
              "quote": "AO2.2 Buildings are built the same distance from the road alignment as the average of the 2 adjoining buildings. || AO2.3 If no adjoining buildings, or if the average setback of adjoining buildings from road alignments exceeds 6m, buildings are at least 3m from road alignments."}],
 "interpretation_notes": "Table 5.5.16: a dwelling house is accepted development unless it includes a secondary dwelling (then ADSR against Sections 1, 2, 3 & 7, including AO2.2/AO2.3): hence planning_assessment_required. AO2.2 sets an equal (averaging) setback, encoded as a minimum. 'Adjoining buildings' approximated by adjoining dwellings (adjoining_dwellings_both_sides, adjoining_road_setbacks_m); the case of only one adjoining building is not addressed by the text and is treated as AO2.3 (3 m). Applies to every road alignment. Automatable false for these approximations.",
 "effective_from": "2024-10-28"}$r$);
SELECT supersede_draft('SBRC.C.TOWNSHIP_ROAD_SETBACK@2024-10-28', 'SBRC.sbrc_township_buildings_road');
