-- =============================================================================
-- Curated council rules, batch 4 (15 Oct 2026): maximum height taken from a council height overlay map.
-- The mapped value arrives as the fact mapped_max_height_m (read from the council's overlay layer by the
-- property lookup; see docs/13-map-services.md). Each rule is scoped to the overlay, so it only appears where
-- the lot is on the height map. Same conventions as 031-033.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('mapped_max_height_m', 'NUMBER', 'm', NULL, 'PLANNING_DATA',
  'Maximum building height shown for the site on the council''s height overlay map',
  'Council height overlay layer (Moreton Bay OM Building heights; Sunshine Coast Height of buildings and structures; Gold Coast Building height). Lowest value where polygons overlap.');

-- ------------------------------------------------ Moreton Bay: Dwelling house code RAD1
SELECT define_rule($r${
 "rule_id": "CMB.C.DH_HEIGHT_MAPPED", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "HEIGHT.BUILDING", "title": "Dwelling house: height not more than mapped on Overlay map - Building heights (not domestic outbuildings)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m", "value": {"var": "mapped_max_height_m"},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/COASTAL_COMMUNITIES"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/SUBURBAN_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/NEXT_GENERATION_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/URBAN_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT_MORAYFIELD_SOUTH"},
            {"level": "OVERLAY", "overlay": "CMB:OV:BUILDING_HEIGHTS"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "sources": [{"key": "mb_dh_rad1_building_height_overlay", "role": "PRIMARY",
              "quote": "RAD1 Building height does not exceed that mapped on Overlay map – Building heights. ... Note - The above does not apply to domestic outbuildings."}],
 "interpretation_notes": "Applies to the dwelling house and attached or unattached outdoor structures (patios, decks, pergolas); sheds, garages and carports are domestic outbuildings and use CMB.C.OUTBUILDING_HEIGHT instead. Minimums mapped on the overlay do not apply to dwelling houses. Value from the open-data layer OVL2_DESC ('Max 8.5m'). Non-compliance: council concurrence agency (Planning Reg sch 9 pt 3 div 2).",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.DH_HEIGHT_MAPPED@2026-09-11', 'CMB.mb_dh_rad1_building_height_overlay');

-- ------------------------------------------------ Sunshine Coast: Dwelling house code AO1
SELECT define_rule($r${
 "rule_id": "SCC.C.DH_HEIGHT_MAPPED", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "HEIGHT.BUILDING", "title": "Dwelling house: height not more than specified on the Height of Buildings and Structures Overlay Map",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m", "value": {"var": "mapped_max_height_m"},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"},
            {"level": "ZONE", "zone": "SCC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "SCC:HIGH_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:TOURIST_ACCOMMODATION"},
            {"level": "ZONE", "zone": "SCC:RURAL"}, {"level": "ZONE", "zone": "SCC:RURAL_RESIDENTIAL"},
            {"level": "ZONE", "zone": "SCC:LIMITED_DEVELOPMENT_LANDSCAPE_RESIDENTIAL"}, {"level": "ZONE", "zone": "SCC:EMERGING_COMMUNITY"},
            {"level": "OVERLAY", "overlay": "SCC:OV:HEIGHT_OF_BUILDINGS_AND_STRUCTURES_OVERLAY"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "sources": [{"key": "dh_building_height_overlay", "role": "PRIMARY",
              "quote": "AO1 The height of the dwelling house does not exceed the height specified for the site on the applicable Height of Buildings and Structures Overlay Map."}],
 "interpretation_notes": "Accepted development requirement of the Dwelling house code: over the mapped height, the dwelling house needs a planning approval. Sheds have the lower 3.6 m outbuilding limit (SCC.C.OUTBUILDING_HEIGHT_3_6). In a flooding and inundation area the overlay code allows MH = OMH + flood hazard allowance (max 1 m for a dwelling house in Low density residential) — not encoded (needs the defined flood level).",
 "effective_from": "2024-01-23"}$r$);
SELECT supersede_draft('SCC.C.DH_HEIGHT_MAPPED@2024-01-23', 'SCC.dh_building_height_overlay');

-- ------------------------------------------------ Gold Coast: Medium density residential zone RO3
SELECT define_rule($r${
 "rule_id": "CGC.C.MDR_HEIGHT_MAPPED", "instrument_version": "CGC_CITY_PLAN@2026-09-29",
 "topic": "HEIGHT.BUILDING", "title": "Medium density residential: buildings and structures not higher than shown on the Building height overlay map",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "unit": "m", "value": {"var": "mapped_max_height_m"},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "GOLD_COAST"}, {"level": "ZONE", "zone": "CGC:MEDIUM_DENSITY_RESIDENTIAL"},
            {"level": "OVERLAY", "overlay": "CGC:OV:DWELLING_HOUSE_OVERLAY_BUILDING_HEIGHT_OVERLAY_MAP"}],
 "subjects": ["ANY"],
 "sources": [{"key": "gc_mdr_building_height", "role": "PRIMARY",
              "quote": "RO3 Building height does not exceed 2 storeys and a maximum of 9m or that shown on the Building height overlay map. AND Structures do not exceed a height of 9m or that shown on the Building height overlay map."}],
 "interpretation_notes": "Where the lot is on the Building height overlay map, the mapped metres govern ('2(9m)' = 9 m). Map labels without metres ('HX', 'Please refer to Southport PDA', The Spit areas) give no value and fall to manual review. Off the map, RO3 gives 2 storeys / 9 m — not encoded separately. The storey limit is not checked.",
 "effective_from": "2026-09-29"}$r$);
SELECT supersede_draft('CGC.C.MDR_HEIGHT_MAPPED@2026-09-29', 'CGC.gc_mdr_building_height');
