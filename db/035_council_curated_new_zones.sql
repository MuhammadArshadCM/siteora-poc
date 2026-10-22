-- =============================================================================
-- Curated council rules, batch 5 (21 Oct 2026): zones that had no council rules.
--   Gold Coast  Rural zone (6.2.20) and Emerging community zone (6.2.15) — City Plan Version 14
--   Moreton Bay Rural zone (6.2.10, Hamlet precinct) and Township zone, Township residential precinct (6.2.12.3)
--   Sunshine Coast Emerging community zone: no zone numbers; the Dwelling house code mapped-height AO1 is widened
--                  to it in 034 (the canal setback AO6 is already council-wide).
-- Verbatim text: research/councils/<slug>.json (rule keys gc_rural_*, gc_ec_*, mb_rural_*, mb_tw_*), fetched from
-- the councils' ePlan JSON on 21 Oct 2026. Clauses with real doubt stay as DRAFT rules (they are listed to the user
-- as "council clauses not yet encoded"):
--   mb_rural_rad3_* (6 / 4.5 / 4.5 m for 'buildings and structures other than a dwelling house' — the scheme's
--     dwelling house definition includes its domestic outbuildings, so whether sheds are covered is unclear),
--   mb_tw_rad3_rear ('Refer to standards in QDC'; assessable E4 says 6.0 m), lake / waterway / bushfire separations,
--   Gold Coast structure heights and pool notes. Same conventions as 031-034.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('lot_from_residential_subdivision', 'BOOLEAN', NULL, NULL, 'USER_DECLARATION',
  'The lot was created through a residential subdivision approval (Gold Coast Emerging community zone)',
  'Not in public map data: from the lot''s subdivision approval / plan of development. Asked of the user.');

-- ============================================================== GOLD COAST: Rural zone
SELECT define_rule($r${
 "rule_id": "CGC.C.RURAL_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Rural: front setback 10 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_rural_front_setback", "role": "PRIMARY", "quote": "Front | - if roadside stall: 0m - otherwise: 10m | Side and rear | 6m"}],
 "interpretation_notes": "Roadside stall 0 m not relevant to Class 10a/pools. Alternative provision for BUILDINGS only (Table 1.5-1); structures (pools, unroofed decks) keep QDC setbacks. The code has no secondary-frontage row; whether 10 m applies to every road frontage of a corner lot needs council confirmation.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.RURAL_FRONT_SETBACK@2026-09-29', 'CGC.gc_rural_front_setback');
SELECT alt_overrides('CGC.C.RURAL_FRONT_SETBACK@2026-09-29', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code is the QDC alternative for buildings.');

SELECT define_rule($r${
 "rule_id": "CGC.C.RURAL_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural: side and rear setback 6 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_rural_side_setback", "role": "PRIMARY", "quote": "Side and rear | 6m"}],
 "interpretation_notes": "Flat 6 m with no height steps and no Class 10a built-to-boundary concession in the table.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.RURAL_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_rural_side_setback');
SELECT supersede_draft('CGC.C.RURAL_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_rural_rear_setback');
SELECT alt_overrides('CGC.C.RURAL_SIDE_REAR_SETBACK@2026-09-29', ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1: zone code is the QDC alternative for buildings.');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
SELECT 'CGC.C.RURAL_SIDE_REAR_SETBACK@2026-09-29', t, 'UNRESOLVED', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM',
       'Same question as Low density and Rural residential: whether QDC A2(d) Class 10a built-to-boundary survives a zone table that is silent on it.'
FROM unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;

SELECT define_rule($r${
 "rule_id": "CGC.C.RURAL_HEIGHT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "Rural: building height 2 storeys and 9 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 9.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:RURAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "sources": [{"key": "gc_rural_building_height", "role": "PRIMARY", "quote": "RO2 Building height does not exceed 2 storeys with a maximum height of 9m."}],
 "interpretation_notes": "Storey limit not encoded separately. 'For structures, no requirements for accepted development are provided' — structures keep the QDC. The Rural code has no site cover provision, so QDC/QHC site cover applies (certifier to confirm).",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.RURAL_HEIGHT@2026-09-29', 'CGC.gc_rural_building_height');
SELECT alt_overrides('CGC.C.RURAL_HEIGHT@2026-09-29', ARRAY['QDC12.A4.BUILDING_HEIGHT','QDC11.A4.BUILDING_HEIGHT'], 'Table 1.5-1: alternative to QDC building height (P4).');

-- ============================================================== GOLD COAST: Emerging community zone
-- Two sets of numbers: the general (interim) case, and 'a Dwelling house on a lot created through a residential
-- subdivision approval ... unless the earlier approval specifies otherwise'. The user says which (fact
-- lot_from_residential_subdivision); unanswered, both sets go to manual review with a 'needs input' prompt.
SELECT define_rule($r${
 "rule_id": "CGC.C.EC_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Emerging community (lot not from a residential subdivision): front setback 10 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 10.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_from_residential_subdivision", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_ec_front_setback", "role": "PRIMARY", "quote": "RO1 Setbacks are as follows: | Setback | Minimum distances measured in metres (m) | Front | 10m | Side and rear | 6m"}],
 "interpretation_notes": "Alternative provision for BUILDINGS only (Table 1.5-1).",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.EC_FRONT_SETBACK@2026-09-29', 'CGC.gc_ec_front_setback');

SELECT define_rule($r${
 "rule_id": "CGC.C.EC_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Emerging community (lot not from a residential subdivision): side and rear setback 6 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_from_residential_subdivision", "op": "IS_FALSE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_ec_side_setback", "role": "PRIMARY", "quote": "Side and rear | 6m"}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.EC_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_ec_side_setback');
SELECT supersede_draft('CGC.C.EC_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_ec_rear_setback');

SELECT define_rule($r${
 "rule_id": "CGC.C.EC_SUBDIV_FRONT_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.FRONTAGE", "title": "Emerging community (lot from a residential subdivision): front setback 6 m (buildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_from_residential_subdivision", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "gc_ec_subdiv_lot_front_setback", "role": "PRIMARY",
              "quote": "For a Dwelling house on a lot created through a residential subdivision approval, the setbacks are as follows, unless the earlier approval specifies otherwise: | Setback | Minimum distances measured in metres (m) | Front | 6m"}],
 "interpretation_notes": "'Unless the earlier approval specifies otherwise': an approved plan of development for the estate overrides these numbers — check it.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.EC_SUBDIV_FRONT_SETBACK@2026-09-29', 'CGC.gc_ec_subdiv_lot_front_setback');

SELECT define_rule($r${
 "rule_id": "CGC.C.EC_SUBDIV_SIDE_REAR_SETBACK", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SETBACK.SIDE_REAR", "title": "Emerging community (lot from a residential subdivision): side and rear setback by height (1.5 / 2 / +0.5 per 3 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.5},
    {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5, {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "part_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "lot_from_residential_subdivision", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]}]],
 "sources": [{"key": "gc_ec_subdiv_lot_side_setback_height_tiered", "role": "PRIMARY",
              "quote": "Side and rear | Height | Setback | up to 4.5m | 1.5m | between 4.5m – 7.5m | 2m"}],
 "interpretation_notes": "Same table as Low density residential; 'height' read as height of the part (QDC convention). No Class 10a built-to-boundary concession in the table. 'Unless the earlier approval specifies otherwise' — check the plan of development.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.EC_SUBDIV_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_ec_subdiv_lot_side_setback_height_tiered');
SELECT supersede_draft('CGC.C.EC_SUBDIV_SIDE_REAR_SETBACK@2026-09-29', 'CGC.gc_ec_subdiv_lot_rear_setback_height_tiered');

-- Both cases replace the QDC road and side/rear clearances for buildings (Table 1.5-1)
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Table 1.5-1: zone code is the QDC alternative for buildings.')
FROM unnest(ARRAY['CGC.C.EC_FRONT_SETBACK@2026-09-29','CGC.C.EC_SUBDIV_FRONT_SETBACK@2026-09-29']) rv;
SELECT alt_overrides(rv, ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC11.A2a.SIDE_REAR_CLEARANCE'], 'Table 1.5-1: zone code is the QDC alternative for buildings.')
FROM unnest(ARRAY['CGC.C.EC_SIDE_REAR_SETBACK@2026-09-29','CGC.C.EC_SUBDIV_SIDE_REAR_SETBACK@2026-09-29']) rv;
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
SELECT rv, t, 'UNRESOLVED', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM',
       'Same question as Low density residential: whether QDC A2(d) Class 10a built-to-boundary survives a zone table that is silent on it.'
FROM unnest(ARRAY['CGC.C.EC_SIDE_REAR_SETBACK@2026-09-29','CGC.C.EC_SUBDIV_SIDE_REAR_SETBACK@2026-09-29']) rv,
     unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;

SELECT define_rule($r${
 "rule_id": "CGC.C.EC_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "Emerging community (lot not from a residential subdivision): site cover <= 5%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 5, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:EMERGING_COMMUNITY"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_from_residential_subdivision", "op": "IS_FALSE"}]],
 "sources": [{"key": "gc_ec_site_cover", "role": "PRIMARY", "quote": "RO2 Site cover does not exceed 5%."}],
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.EC_SITE_COVER@2026-09-29', 'CGC.gc_ec_site_cover');

SELECT define_rule($r${
 "rule_id": "CGC.C.EC_SUBDIV_SITE_COVER", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "SITE_COVER", "title": "Emerging community (lot from a residential subdivision): site cover <= 50%",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 50, "unit": "%",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:EMERGING_COMMUNITY"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "lot_from_residential_subdivision", "op": "IS_TRUE"}]],
 "sources": [{"key": "gc_ec_subdiv_lot_site_cover", "role": "PRIMARY",
              "quote": "For a Dwelling house on a lot created through a residential subdivision approval, the site cover does not exceed 50%, unless the earlier approval specifies otherwise."}],
 "interpretation_notes": "'Unless the earlier approval specifies otherwise' — check the plan of development.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.EC_SUBDIV_SITE_COVER@2026-09-29', 'CGC.gc_ec_subdiv_lot_site_cover');
SELECT alt_overrides(rv, ARRAY['QDC12.A3.SITE_COVER','QDC11.A3.SITE_COVER'], 'Table 1.5-1: zone code is the QDC site cover alternative.')
FROM unnest(ARRAY['CGC.C.EC_SITE_COVER@2026-09-29','CGC.C.EC_SUBDIV_SITE_COVER@2026-09-29']) rv;

SELECT define_rule($r${
 "rule_id": "CGC.C.EC_HEIGHT", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "Emerging community (off the Building height overlay map): buildings 2 storeys and 9 m, structures 9 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 9.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:EMERGING_COMMUNITY"},
            {"level": "OVERLAY", "overlay": "CGC:OV:DWELLING_HOUSE_OVERLAY_BUILDING_HEIGHT_OVERLAY_MAP", "exclude": true}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_ec_building_height", "role": "PRIMARY",
              "quote": "RO3 Building height does not exceed 2 storeys and a maximum of 9m or that shown on the Building height overlay map."}],
 "interpretation_notes": "Where the lot is on the Building height overlay map, CGC.C.EC_HEIGHT_MAPPED applies instead. Storey limit not encoded separately.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.EC_HEIGHT@2026-09-29', 'CGC.gc_ec_building_height');

SELECT define_rule($r${
 "rule_id": "CGC.C.EC_HEIGHT_MAPPED", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "Emerging community: buildings and structures not higher than shown on the Building height overlay map",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m", "value": {"var": "mapped_max_height_m"},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:EMERGING_COMMUNITY"},
            {"level": "OVERLAY", "overlay": "CGC:OV:DWELLING_HOUSE_OVERLAY_BUILDING_HEIGHT_OVERLAY_MAP"}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_ec_structure_height", "role": "PRIMARY",
              "quote": "Structures do not exceed a height of 9m or that shown on the Building height overlay map."}],
 "interpretation_notes": "Same reading as CGC.C.MDR_HEIGHT_MAPPED: map labels without metres give no value and fall to manual review.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.EC_HEIGHT_MAPPED@2026-09-29', 'CGC.gc_ec_structure_height');
SELECT alt_overrides(rv, ARRAY['QDC12.A4.BUILDING_HEIGHT','QDC11.A4.BUILDING_HEIGHT'], 'Table 1.5-1: alternative to QDC building height (P4).')
FROM unnest(ARRAY['CGC.C.EC_HEIGHT@2026-09-29','CGC.C.EC_HEIGHT_MAPPED@2026-09-29']) rv;

-- ============================================================== MORETON BAY: Rural zone
-- 6.2.10.1: 'Development associated with a dwelling house is subject to the relevant provisions in this code and not
-- the dwelling house code.' Outside the Hamlet precinct the code sets no setback, site cover or roofed-area limit
-- for the dwelling house, so the QDC/QHC applies to those.
SELECT define_rule($r${
 "rule_id": "CMB.C.RURAL_HEIGHT_MAPPED", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "HEIGHT.BUILDING", "title": "Rural: buildings and structures not higher than mapped on Overlay map - Building heights",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m", "value": {"var": "mapped_max_height_m"},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:RURAL"},
            {"level": "OVERLAY", "overlay": "CMB:OV:BUILDING_HEIGHTS"}],
 "subjects": ["ANY"],
 "sources": [{"key": "mb_rural_rad2_height_dwelling", "role": "PRIMARY",
              "quote": "Unless otherwise specified elsewhere in this code, building height and all structures do not exceed the height identified on Overlay map - Building heights"}],
 "interpretation_notes": "RAD2 is listed in the zone's concurrence table as an alternative provision to the QDC, so non-compliance goes to council as concurrence agency. Value from the open-data layer OVL2_DESC ('Max 8.5m'; the open data is 2022, check the lot on the Version 8 map).",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.RURAL_HEIGHT_MAPPED@2026-09-11', 'CMB.mb_rural_rad2_height_dwelling');
SELECT alt_overrides('CMB.C.RURAL_HEIGHT_MAPPED@2026-09-11', ARRAY['QDC12.A4.BUILDING_HEIGHT','QDC11.A4.BUILDING_HEIGHT'], '6.2.10 concurrence table: RAD2 is an alternative provision to the QDC.');

SELECT define_rule($r${
 "rule_id": "CMB.C.HAMLET_OUTBUILDING_HEIGHT", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "HEIGHT.CLASS_10A", "title": "Rural zone Hamlet precinct: outbuildings and free-standing carports/garages <= 3.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 3.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:RURAL/HAMLET"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_rural_rad2_hamlet_outbuilding_height", "role": "PRIMARY",
              "quote": "except in the Hamlet precinct, where outbuildings, free standing car ports or garages do not exceed 3.5m."}],
 "interpretation_notes": "RAD2 is a listed alternative provision (concurrence agency issue).",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.HAMLET_OUTBUILDING_HEIGHT@2026-09-11', 'CMB.mb_rural_rad2_hamlet_outbuilding_height');

SELECT define_rule($r${
 "rule_id": "CMB.C.HAMLET_ROAD_SETBACK", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Rural zone Hamlet precinct: road boundary setback 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:RURAL/HAMLET"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_rural_rad4_hamlet_road_setback", "role": "PRIMARY", "quote": "For lots located in the Hamlet precinct, the minimum setback from a boundary are as follows: - road boundary - 6m"}],
 "interpretation_notes": "RAD4 is not in the concurrence table: not meeting it makes the building work assessable (limited code assessment, s5.3.3.1.a.ii). The QDC setbacks still apply alongside it.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.HAMLET_ROAD_SETBACK@2026-09-11', 'CMB.mb_rural_rad4_hamlet_road_setback');

SELECT define_rule($r${
 "rule_id": "CMB.C.HAMLET_SIDE_SETBACK", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SIDE", "title": "Rural zone Hamlet precinct: side boundary setback 1.5 m (lots <= 1000 m2) or 3 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "lot_area_m2"}, 1000]}, "then": 1.5}], "else": 3.0},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:RURAL/HAMLET"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SIDE"}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_rural_rad4_hamlet_side_setback_le1000", "role": "PRIMARY", "quote": "side boundary - 1.5m for lots having 1000m2 or less; 3m for lots greater than 1000m2"}],
 "interpretation_notes": "Not a concurrence matter: non-compliance makes the work assessable. The QDC still applies alongside it (incl. the Class 10a built-to-boundary allowance, which this RAD does not displace because it is not an alternative provision).",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.HAMLET_SIDE_SETBACK@2026-09-11', 'CMB.mb_rural_rad4_hamlet_side_setback_le1000');
SELECT supersede_draft('CMB.C.HAMLET_SIDE_SETBACK@2026-09-11', 'CMB.mb_rural_rad4_hamlet_side_setback_gt1000');

SELECT define_rule($r${
 "rule_id": "CMB.C.HAMLET_REAR_SETBACK", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.REAR", "title": "Rural zone Hamlet precinct: rear boundary setback 4 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_REAR", "operator": ">=", "value": 4.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:RURAL/HAMLET"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "REAR"}, {"fact": "development_footprint_exists", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_rural_rad4_hamlet_rear_setback", "role": "PRIMARY", "quote": "rear boundary - 4m."}],
 "interpretation_notes": "Not a concurrence matter: non-compliance makes the work assessable.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.HAMLET_REAR_SETBACK@2026-09-11', 'CMB.mb_rural_rad4_hamlet_rear_setback');

-- ============================================================== MORETON BAY: Township residential precinct
SELECT define_rule($r${
 "rule_id": "CMB.C.TW_PRIMARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Township residential: primary frontage 6.0 m to wall (house and other buildings, not car parking / outbuildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 6.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:TOWNSHIP/TOWNSHIP_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "mb_tw_rad3_primary_frontage", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 6.0m || Min 4.5m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 1.5m || Refer to standards in QDC"}],
 "interpretation_notes": "Min 4.5 m to the outermost projection not encoded separately. RAD3 carries 'Note - This is an alternative provision to the QDC for building work associated with a Dwelling house, and is a concurrence agency issue.' (Table 1.6.1 does not list 6.2.12 — researcher flagged.)",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.TW_PRIMARY_FRONTAGE@2026-09-11', 'CMB.mb_tw_rad3_primary_frontage');

SELECT define_rule($r${
 "rule_id": "CMB.C.TW_SECONDARY_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Township residential: secondary frontage 3 m to wall (house and other buildings, not car parking / outbuildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SECONDARY_FRONTAGE", "operator": ">=", "value": 3.0, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:TOWNSHIP/TOWNSHIP_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "mb_tw_rad3_secondary_frontage", "role": "PRIMARY",
              "quote": "Less than 4.5m || Min 6.0m || Min 4.5m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 1.5m || Refer to standards in QDC"}],
 "interpretation_notes": "Min 2 m to the outermost projection not encoded separately.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.TW_SECONDARY_FRONTAGE@2026-09-11', 'CMB.mb_tw_rad3_secondary_frontage');

SELECT define_rule($r${
 "rule_id": "CMB.C.TW_OUTBUILDING_FRONTAGE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "GARAGE.FRONTAGE", "title": "Township residential: car parking spaces, carports and domestic outbuildings >= 5.4 m from the primary or secondary frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 5.4, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:TOWNSHIP/TOWNSHIP_RESIDENTIAL"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "DETACHED_LAUNDRY", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]}]],
 "sources": [{"key": "mb_tw_rad3_carport_frontage", "role": "PRIMARY",
              "quote": "in all other instances: a minimum setback of 5.4m from the primary or secondary frontage."},
             {"key": "mb_tw_rad3_primary_frontage", "role": "SUPPLEMENTARY",
              "quote": "Less than 4.5m || Min 6.0m || Min 4.5m || Min 5.4 || Min 3m || Min 2m || Min 5.4 || Min 1.5m || Refer to standards in QDC"}],
 "interpretation_notes": "Open carports of a house built before 2005 may instead match a lawful neighbouring carport/garage (min 0.5 m) — not encoded. RAD59(c) also requires domestic outbuildings (other than a complying carport) to be behind the main building line.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.TW_OUTBUILDING_FRONTAGE@2026-09-11', 'CMB.mb_tw_rad3_carport_frontage');
SELECT alt_overrides(rv, ARRAY['QDC12.A1a.ROAD_SETBACK','QDC12.A1b.CORNER_NOMINATED_FRONTAGE','QDC12.A1c.OPEN_CARPORT','QDC11.A1a.FRONTAGE_SETBACK'],
       'RAD3 note: alternative provision to the QDC for building work associated with a Dwelling house.')
FROM unnest(ARRAY['CMB.C.TW_PRIMARY_FRONTAGE@2026-09-11','CMB.C.TW_SECONDARY_FRONTAGE@2026-09-11','CMB.C.TW_OUTBUILDING_FRONTAGE@2026-09-11']) rv;

SELECT define_rule($r${
 "rule_id": "CMB.C.TW_SIDE_SETBACK", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SIDE", "title": "Township residential: side setback 1.5 m (wall under 4.5 m) or 2 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<", "args": [{"var": "wall_height_m"}, 4.5]}, "then": 1.5}], "else": 2.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:TOWNSHIP/TOWNSHIP_RESIDENTIAL"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "mb_tw_rad3_side", "role": "PRIMARY",
              "quote": "4.5m or more || Min 6.0m || Min 4.5m || N/A || Min 3m || Min 2m || N/A || Min 2m || Refer to standards in QDC"}],
 "interpretation_notes": "Rear boundary: 'Refer to standards in QDC', so the QDC/QHC rear clearance applies (no rule here). Same values as QDC MP1.2 A2(a) for low walls; the QDC is not marked overridden, because whether the Class 10a built-to-boundary allowance survives is unresolved.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.TW_SIDE_SETBACK@2026-09-11', 'CMB.mb_tw_rad3_side');
INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
SELECT 'CMB.C.TW_SIDE_SETBACK@2026-09-11', t, 'UNRESOLVED', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM',
       'RAD3 is noted as an alternative provision but has no built-to-boundary row: does QDC A2(d) (Class 10a within the clearance) survive? Confirm with Moreton Bay.'
FROM unnest(ARRAY['QDC12.A2d.CLASS10A_WITHIN_CLEARANCE','QDC11.A2d.CLASS10A_WITHIN_CLEARANCE']) t;

SELECT define_rule($r${
 "rule_id": "CMB.C.TW_SITE_COVER", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SITE_COVER", "title": "Township residential: site cover <= 50%",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SITE_COVER", "operator": "<=", "value": 50, "unit": "%",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:TOWNSHIP/TOWNSHIP_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "sources": [{"key": "mb_tw_rad4_site_cover", "role": "PRIMARY",
              "quote": "Site cover does not exceed 50% (excluding eaves, sun shading devices, patios, balconies and other unenclosed structures)."}],
 "interpretation_notes": "No alternative-provision note on RAD4: exceeding it makes the work assessable (limited code assessment); the QDC site cover still applies too.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.TW_SITE_COVER@2026-09-11', 'CMB.mb_tw_rad4_site_cover');

SELECT define_rule($r${
 "rule_id": "CMB.C.TW_OUTBUILDING_ROOFED_AREA", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "OUTBUILDING.SIZE", "title": "Township residential: domestic outbuildings total roofed area by lot size (50 / 70 / 80 / 150 m2)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "unit": "m2",
 "value": {"op": "case", "when": [{"if": {"op": "<", "args": [{"var": "lot_area_m2"}, 600]}, "then": 50},
                                  {"if": {"op": "<=", "args": [{"var": "lot_area_m2"}, 1000]}, "then": 70},
                                  {"if": {"op": "<=", "args": [{"var": "lot_area_m2"}, 2000]}, "then": 80}], "else": 150},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:TOWNSHIP/TOWNSHIP_RESIDENTIAL"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_tw_rad59_outbuilding_roofed_area", "role": "PRIMARY",
              "quote": "Size of lot || Maximum roofed area ; Less than 600m2 || 50m2 ; 600m2 - 1000m2 || 70m2 ; >1000m2 – 2000m2 || 80m2 ; Greater than 2000m2 || 150m2"}],
 "interpretation_notes": "Measured value = total_outbuilding_roofed_area_m2. RAD59(a) is expressly not an alternative provision, so exceeding it makes the work assessable.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.TW_OUTBUILDING_ROOFED_AREA@2026-09-11', 'CMB.mb_tw_rad59_outbuilding_roofed_area');

SELECT define_rule($r${
 "rule_id": "CMB.C.TW_OUTBUILDING_HEIGHT", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "HEIGHT.CLASS_10A", "title": "Township residential: domestic outbuildings max height 4 m (mean 3.5 m); carport in front of main building line 3.3 m (mean 2.7 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "is_true", "args": [{"var": "in_front_of_main_building_line"}]}, "then": 3.3}], "else": 4.0},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:TOWNSHIP/TOWNSHIP_RESIDENTIAL"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "conditions": [[{"fact": "is_attached_to_dwelling", "op": "IS_FALSE"}]],
 "sources": [{"key": "mb_tw_rad59_outbuilding_height", "role": "PRIMARY",
              "quote": "where in front of the main building line for a carport - have a maximum building height of 3.3m and a mean height not exceeding 2.7m; or - for all other instances - have a maximum building height of 4m and a mean height not exceeding 3.5m"}],
 "interpretation_notes": "Same wording as the Dwelling house code RAD26 (CMB.C.OUTBUILDING_HEIGHT). Mean height limits not encoded separately. RAD59(b) is an alternative provision (concurrence agency issue).",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.TW_OUTBUILDING_HEIGHT@2026-09-11', 'CMB.mb_tw_rad59_outbuilding_height');

SELECT define_rule($r${
 "rule_id": "CMB.C.TW_HEIGHT_MAPPED", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "HEIGHT.BUILDING", "title": "Township residential: building height not more than mapped on Overlay map - Building heights (not domestic outbuildings)",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m", "value": {"var": "mapped_max_height_m"},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "PRECINCT", "precinct": "CMB:TOWNSHIP/TOWNSHIP_RESIDENTIAL"},
            {"level": "OVERLAY", "overlay": "CMB:OV:BUILDING_HEIGHTS"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "sources": [{"key": "mb_tw_rad1_height_dwelling", "role": "PRIMARY",
              "quote": "Building height does not exceed that mapped on Overlay map - Building heights. Note - The above does not apply to domestic outbuildings."}],
 "interpretation_notes": "No alternative-provision note on RAD1: exceeding it makes the work assessable. Sheds, garages and carports use CMB.C.TW_OUTBUILDING_HEIGHT. Value from the 2022 open-data layer — check the lot on the Version 8 map.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.TW_HEIGHT_MAPPED@2026-09-11', 'CMB.mb_tw_rad1_height_dwelling');
