-- =============================================================================
-- Curated council rules: Moreton Bay Dwelling house code setback tables 9.3.1.3–9.3.1.6 (via Table 9.3.1.1 RAD3 /
-- E3.1), hand-encoded from the verbatim provisions loaded by db/030_council_moreton_bay.sql. Each curated rule
-- REPLACES its draft. Found by the 22 Oct 2026 setback validation (validation/validation_report.md §6).
--
-- Table columns per wall-height row: Frontage Primary [to wall | to OMP | to covered car parking and domestic
-- outbuildings] || Frontage Secondary to street [same] || Secondary to lane || Side || Rear || Trafficable water body.
-- Encoded: primary and secondary street frontage "to wall", covered car parking / outbuildings, and the Next
-- generation side/rear cells. Not encoded (as in db/032 and db/035): "to OMP" minimums, lane (0.5 m) and
-- trafficable water body (4.5 m) columns.
--
-- Side and rear in Tables 9.3.1.3, 9.3.1.4 and 9.3.1.6 read "Refer to standard as in QDC": the scheme states no
-- value, so the QDC side/rear clearance applies and no council rule is created (those drafts stay DRAFT as the
-- record of the deferral).
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('primary_frontage_length_m','NUMBER','m',NULL,'GEOMETRY_DERIVED','Length of the lot''s primary frontage boundary (Moreton Bay Table 9.3.1.5 "primary frontage ≤12m / ≤9.5m")', 'Length of the boundary with boundary_type PRIMARY_FRONTAGE'),
 ('longest_side_boundary_m','NUMBER','m',NULL,'GEOMETRY_DERIVED','Length of the lot''s longest side boundary (Moreton Bay Table 9.3.1.5 "longest side boundary is ≤25m")', 'Max length over boundaries with boundary_type SIDE'),
 ('adjoins_or_opposite_park','BOOLEAN',NULL,NULL,'PROPERTY_DATA','The lot adjoins a park, or is directly opposite a park fronting the same street (Moreton Bay Table 9.3.1.5)', 'Open space zone / park land adjoining the lot or across the primary street');

-- ============================================== Coastal communities precinct + Redcliffe Kippa-Ring Interim residential (Table 9.3.1.3)
SELECT define_rule($r${
 "rule_id": "CMB.C.COASTAL_PRIMARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Coastal communities / Redcliffe Interim residential: primary frontage 6 m to wall (house and other buildings, not car parking / outbuildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/COASTAL_COMMUNITIES"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:REDCLIFFE_KIPPA_RING/INTERIM_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "mb_dh_t93113_coastal_front", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 6m || Min 4.5m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 0.5 ... Greater than 8.5m || Min 6m || Min 4.5m || N/A"},
             {"key": "mb_rkr_interim_setbacks_table_72163", "role": "SUPPLEMENTARY",
              "quote": "Less than 4.5m || Min 6m || Min 4.5m || Min 5.4m || Min 3m || Min 2m || Min 5.4m || Min 0.5m"}],
 "interpretation_notes": "6 m to wall in every wall-height row; Min 4.5 m to the outermost projection not encoded separately. Redcliffe Interim residential: 9.3.1 RAD3 routes it to Table 9.3.1.3 and the local plan Part K to Table 7.2.1.6.3 (open issue); both tables give 6 m primary / 3 m secondary / 5.4 m car parking, so the frontage rules are scoped to it. Side/rear differ between the two tables and are not encoded.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.COASTAL_PRIMARY_FRONTAGE@2026-09-11', 'CMB.mb_dh_t93113_coastal_front');

SELECT define_rule($r${
 "rule_id": "CMB.C.COASTAL_SECONDARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Coastal communities / Redcliffe Interim residential: secondary street frontage 3 m to wall",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/COASTAL_COMMUNITIES"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:REDCLIFFE_KIPPA_RING/INTERIM_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "mb_dh_t93113_coastal_secondary", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 6m || Min 4.5m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 0.5"}],
 "interpretation_notes": "3 m to wall in every wall-height row; Min 2 m to the outermost projection not encoded separately.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.COASTAL_SECONDARY_FRONTAGE@2026-09-11', 'CMB.mb_dh_t93113_coastal_secondary');

SELECT define_rule($r${
 "rule_id": "CMB.C.COASTAL_OUTBUILDING_FRONTAGES", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Coastal communities / Redcliffe Interim residential: covered car parking and domestic outbuildings 5.4 m from primary and secondary street frontages",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.4, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/COASTAL_COMMUNITIES"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:REDCLIFFE_KIPPA_RING/INTERIM_RESIDENTIAL"}],
 "subjects": ["GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "wall_height_m", "op": "<", "value": 4.5}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "mb_dh_t93113_coastal_front", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 6m || Min 4.5m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 0.5"},
             {"key": "mb_dh_rad3_setback_table_routing_and_carport", "role": "SUPPLEMENTARY",
              "quote": "Except for carports in the primary and secondary frontage where they: - are setback a minimum of: - 5.4m"}],
 "interpretation_notes": "As CMB.C.SUBURBAN_OUTBUILDING_FRONTAGES: the 'To covered car parking space and domestic outbuildings' column is 5.4 m (primary and secondary street) for walls under 4.5 m and 'N/A' above (RAD26 caps outbuildings at 4 m). Open carports of a house built before 2005 may instead match a lawful neighbouring carport/garage (min 0.5 m) under RAD3 — not encoded.",
 "effective_from": "2026-09-11"}$r$);

-- ======================================================================== Suburban neighbourhood precinct (Table 9.3.1.4)
SELECT define_rule($r${
 "rule_id": "CMB.C.SUBURBAN_PRIMARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Suburban neighbourhood: primary frontage 4.5 m to wall (house and other buildings, not car parking / outbuildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 4.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "mb_dh_t93114_suburban_front", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 4.5m || Min 3m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 0.5"}],
 "interpretation_notes": "4.5 m to wall in every wall-height row; Min 3 m to the outermost projection not encoded separately. Car parking / outbuildings: CMB.C.SUBURBAN_OUTBUILDING_FRONTAGES (db/032), which already replaced the draft of this provision. The table heading also names Township zone - Residential precinct, but Table 5.7.1 sends Township dwelling houses to the Township zone code (db/035).",
 "effective_from": "2026-09-11"}$r$);

SELECT define_rule($r${
 "rule_id": "CMB.C.SUBURBAN_SECONDARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Suburban neighbourhood: secondary street frontage 3 m to wall",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "mb_dh_t93114_suburban_secondary", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 4.5m || Min 3m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 0.5"}],
 "interpretation_notes": "3 m to wall in every wall-height row; Min 2 m to the outermost projection not encoded separately.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.SUBURBAN_SECONDARY_FRONTAGE@2026-09-11', 'CMB.mb_dh_t93114_suburban_secondary');

-- ============================== Next generation neighbourhood + EC Transition (developed lot) + Caboolture West Next generation (Table 9.3.1.5)
SELECT define_rule($r${
 "rule_id": "CMB.C.NEXTGEN_PRIMARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Next generation neighbourhood (and equivalents): primary frontage 3 m to wall, 6 m where the wall is over 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "wall_height_m"}, 8.5]}, "then": 6.0}], "else": 3.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/NEXT_GENERATION_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:CABOOLTURE_WEST/URBAN_LIVING_NEXT_GENERATION"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "mb_dh_t93115_nextgen_front", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 3m || Min 2m || Min 5.4m* ... 4.5m to 8.5m || Min 3m || Min 2m || N/A ... Greater than 8.5m || Min 6m || Min 5m || N/A"}],
 "interpretation_notes": "Rows 'Less than 4.5m' and '4.5m to 8.5m' = 3 m; 'Greater than 8.5m' = 6 m (a wall of exactly 8.5 m is in the 4.5–8.5 m row). To the outermost projection (2 m / 5 m) not encoded separately. Morayfield South is scoped to Table 9.3.1.6 per E3.1 and that table's heading; RAD3 says 9.3.1.5 (open issue).",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.NEXTGEN_PRIMARY_FRONTAGE@2026-09-11', 'CMB.mb_dh_t93115_nextgen_front');

SELECT define_rule($r${
 "rule_id": "CMB.C.NEXTGEN_SECONDARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Next generation neighbourhood (and equivalents): secondary street frontage 2 m to wall, 3 m where the wall is over 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "wall_height_m"}, 8.5]}, "then": 3.0}], "else": 2.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/NEXT_GENERATION_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:CABOOLTURE_WEST/URBAN_LIVING_NEXT_GENERATION"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "mb_dh_t93115_nextgen_secondary", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 3m || Min 2m || Min 5.4m* || Min 2m || Min 1m || Min 5.4m* ... Greater than 8.5m || Min 6m || Min 5m || N/A || Min 3m || Min 2m || N/A"}],
 "interpretation_notes": "Secondary to street, to wall: 2 m (walls up to 8.5 m), 3 m above. To the outermost projection (1 m / 2 m) not encoded separately.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.NEXTGEN_SECONDARY_FRONTAGE@2026-09-11', 'CMB.mb_dh_t93115_nextgen_secondary');

SELECT define_rule($r${
 "rule_id": "CMB.C.NEXTGEN_OUTBUILDING_FRONTAGES", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Next generation neighbourhood (and equivalents): covered car parking and domestic outbuildings 5.4 m from primary and secondary street frontages (4.5 m in some cases)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.4, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/NEXT_GENERATION_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:CABOOLTURE_WEST/URBAN_LIVING_NEXT_GENERATION"}],
 "subjects": ["GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "wall_height_m", "op": "<", "value": 4.5}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "mb_dh_t93115_nextgen_front", "role": "PRIMARY",
              "quote": "*Note - The minimum setback to covered car parking spaces may be reduced to 4.5m where: - the primary or secondary frontage of the lot adjoins a road reserve with a minimum rear verge width of 1m or greater and includes a footpath with a width of 2m or greater; - The lot has a primary frontage greater than 7.5m and no greater than 10m (Lot type B)."},
             {"key": "mb_dh_rad3_setback_table_routing_and_carport", "role": "SUPPLEMENTARY",
              "quote": "Except for carports in the primary and secondary frontage where they: - are setback a minimum of: - 5.4m"}],
 "interpretation_notes": "5.4 m ('Min 5.4m*') for walls under 4.5 m, 'N/A' above. Not automatable: the * note lets covered car parking reduce to 4.5 m on verge/footpath and Lot type B conditions, and it is unclear whether those two bullets are cumulative; road reserve verge and footpath widths are not available inputs. Caboolture West Next generation: garden sheds of at most 10 m2 roofed area and 2.5 m height are exempt from the setback tables (RAD3 note) — not encoded.",
 "effective_from": "2026-09-11"}$r$);

SELECT define_rule($r${
 "rule_id": "CMB.C.NEXTGEN_SIDE_NARROW_LOT", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SIDE", "title": "Next generation neighbourhood (and equivalents): side setback 1 m to wall where wall is under 4.5 m and primary frontage is 12 m or less",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/NEXT_GENERATION_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:CABOOLTURE_WEST/URBAN_LIVING_NEXT_GENERATION"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SIDE"}, {"fact": "wall_height_m", "op": "<", "value": 4.5},
                 {"fact": "primary_frontage_length_m", "op": "<=", "value": 12}]],
 "sources": [{"key": "mb_dh_t93115_nextgen_side", "role": "PRIMARY",
              "quote": "For lots with a primary frontage ≤12m, Min 1m OR For lots with a primary frontage >12m, refer to standard as in QDC but measured to wall"}],
 "interpretation_notes": "Only the 'Less than 4.5m' row gives a number. Every other case reads 'refer to standard as in QDC but measured to wall', so the QDC side clearance applies there (this rule is then not a candidate and does not override it); 'measured to wall' instead of to the outermost projection is not encoded. Side to OMP = standard to wall minus 0.5 m (extra column) not encoded. Built-to-boundary walls: RAD4 / Table 9.3.1.7.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.NEXTGEN_SIDE_NARROW_LOT@2026-09-11', 'CMB.mb_dh_t93115_nextgen_side');

SELECT define_rule($r${
 "rule_id": "CMB.C.NEXTGEN_REAR", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.REAR", "title": "Next generation neighbourhood (and equivalents): rear setback 5 m to wall; 3 m on short or narrow lots",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "longest_side_boundary_m"}, 25]}, "then": 3.0},
                                   {"if": {"op": "<=", "args": [{"var": "primary_frontage_length_m"}, 9.5]}, "then": 3.0}], "else": 5.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/NEXT_GENERATION_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT"},
            {"level": "LOCAL_PLAN_PRECINCT", "local_plan_precinct": "CMB:CABOOLTURE_WEST/URBAN_LIVING_NEXT_GENERATION"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "REAR"}, {"fact": "primary_frontage_length_m", "op": ">", "value": 9.5}],
                [{"fact": "boundary_type", "op": "=", "value": "REAR"}, {"fact": "adjoins_or_opposite_park", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_dh_t93115_nextgen_rear", "role": "PRIMARY",
              "quote": "Min 5m OR Where the longest side boundary is ≤25m or where the primary frontage is ≤9.5m - Min 3m OR Where the primary frontage is ≤9.5m and the lot is adjoining a park or directly opposite a park fronting the same street - refer to standard as in QDC but measured to wall"}],
 "interpretation_notes": "Same in every wall-height row. The rule does not apply (QDC rear clearance 'measured to wall' instead) when the primary frontage is <= 9.5 m AND the lot adjoins or is directly opposite a park fronting the same street: hence the two OR-ed condition groups. Not automatable: 'directly opposite a park fronting the same street' needs judgement and park data. Rear to OMP = rear standard to wall minus 0.5 m (extra column) not encoded.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.NEXTGEN_REAR@2026-09-11', 'CMB.mb_dh_t93115_nextgen_rear');

-- ============================== Urban neighbourhood precinct + EC Transition (developed lot) Morayfield South (Table 9.3.1.6)
SELECT define_rule($r${
 "rule_id": "CMB.C.URBAN_PRIMARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Urban neighbourhood / Morayfield South: primary frontage 1 m to wall, 5 m where the wall is over 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "wall_height_m"}, 8.5]}, "then": 5.0}], "else": 1.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/URBAN_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT_MORAYFIELD_SOUTH"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "mb_dh_t93116_urban_front", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 1m || Min 1m || Min 5.4m ... 4.5 to 8.5m || Min 1m || Min 1m || N/A ... Greater than 8.5m || Min 5m || Min 3m || N/A"}],
 "interpretation_notes": "Walls up to 8.5 m: 1 m; above 8.5 m: 5 m (3 m to the outermost projection, not encoded separately). Morayfield South scoped here per E3.1 and the table heading; RAD3 routes it to 9.3.1.5 (open issue).",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.URBAN_PRIMARY_FRONTAGE@2026-09-11', 'CMB.mb_dh_t93116_urban_front');

SELECT define_rule($r${
 "rule_id": "CMB.C.URBAN_SECONDARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Urban neighbourhood / Morayfield South: secondary street frontage 1 m to wall, 2 m where the wall is over 8.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": ">", "args": [{"var": "wall_height_m"}, 8.5]}, "then": 2.0}], "else": 1.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/URBAN_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT_MORAYFIELD_SOUTH"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "mb_dh_t93116_urban_secondary", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 1m || Min 1m || Min 5.4m || Min 1m || Min 1m || Min 5.4m ... Greater than 8.5m || Min 5m || Min 3m || N/A || Min 2m || Min 1m || N/A"}],
 "interpretation_notes": "Secondary to street, to wall: 1 m (walls up to 8.5 m), 2 m above. To the outermost projection (1 m) not encoded separately.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.URBAN_SECONDARY_FRONTAGE@2026-09-11', 'CMB.mb_dh_t93116_urban_secondary');

SELECT define_rule($r${
 "rule_id": "CMB.C.URBAN_OUTBUILDING_FRONTAGES", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Urban neighbourhood / Morayfield South: covered car parking and domestic outbuildings 5.4 m from primary and secondary street frontages",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.4, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/URBAN_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT_MORAYFIELD_SOUTH"}],
 "subjects": ["GARAGE", "CARPORT", "SHED", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "wall_height_m", "op": "<", "value": 4.5}, {"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "mb_dh_t93116_urban_front", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 1m || Min 1m || Min 5.4m || Min 1m || Min 1m || Min 5.4m || Min 0.5"},
             {"key": "mb_dh_rad3_setback_table_routing_and_carport", "role": "SUPPLEMENTARY",
              "quote": "Except for carports in the primary and secondary frontage where they: - are setback a minimum of: - 5.4m"}],
 "interpretation_notes": "As CMB.C.SUBURBAN_OUTBUILDING_FRONTAGES: 5.4 m for walls under 4.5 m, 'N/A' above. RAD3 pre-2005 carport alternative not encoded.",
 "effective_from": "2026-09-11"}$r$);

-- ============================================================== Displaced QDC rules (Building Act s33(4))
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1b.CORNER_NOMINATED_FRONTAGE','QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.SIDE_TO_CORNER_STREET'],
       'Table 1.6.1: 9.3.1 RADs noted as a planning scheme matter are the alternative provisions to QDC boundary clearances.')
FROM unnest(ARRAY['CMB.C.COASTAL_PRIMARY_FRONTAGE@2026-09-11','CMB.C.COASTAL_SECONDARY_FRONTAGE@2026-09-11',
                  'CMB.C.SUBURBAN_PRIMARY_FRONTAGE@2026-09-11','CMB.C.SUBURBAN_SECONDARY_FRONTAGE@2026-09-11',
                  'CMB.C.NEXTGEN_PRIMARY_FRONTAGE@2026-09-11','CMB.C.NEXTGEN_SECONDARY_FRONTAGE@2026-09-11',
                  'CMB.C.URBAN_PRIMARY_FRONTAGE@2026-09-11','CMB.C.URBAN_SECONDARY_FRONTAGE@2026-09-11']) rv;
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1b.CORNER_NOMINATED_FRONTAGE','QDC12.A1c.OPEN_CARPORT','QDC11.A1a.FRONTAGE_SETBACK','QDC11.A1a.SIDE_TO_CORNER_STREET'],
       'Table 1.6.1: 9.3.1 RADs noted as a planning scheme matter are the alternative provisions to QDC boundary clearances.')
FROM unnest(ARRAY['CMB.C.COASTAL_OUTBUILDING_FRONTAGES@2026-09-11','CMB.C.NEXTGEN_OUTBUILDING_FRONTAGES@2026-09-11',
                  'CMB.C.URBAN_OUTBUILDING_FRONTAGES@2026-09-11']) rv;
SELECT alt_overrides(rv, ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE','QDC12.A2b.NARROW_LOT_CLEARANCE','QDC11.A2b.NARROW_LOT_CLEARANCE'],
       'Table 1.6.1: Table 9.3.1.5 side/rear cells that state a value are alternative provisions; cells reading "refer to standard as in QDC" leave the QDC in force (rule conditions exclude them).')
FROM unnest(ARRAY['CMB.C.NEXTGEN_SIDE_NARROW_LOT@2026-09-11','CMB.C.NEXTGEN_REAR@2026-09-11']) rv;
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
SELECT rv, t, 'UNRESOLVED', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM',
       'Table 9.3.1.5 gives a side/rear value but no Class 10a concession; built-to-boundary walls are dealt with by RAD4 / Table 9.3.1.7. Does QDC A2(d) (Class 10a within the clearance) survive? Confirm with Moreton Bay.'
FROM unnest(ARRAY['CMB.C.NEXTGEN_SIDE_NARROW_LOT@2026-09-11','CMB.C.NEXTGEN_REAR@2026-09-11']) rv,
     unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;
