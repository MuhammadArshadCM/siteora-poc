-- =============================================================================
-- Brisbane: double carport minimum boundary setbacks for "prescribed accepted
-- development" status (Table 5.3.4.1, rule 4589). These figures previously
-- existed only as free text inside BCC.C.DHC_SMALL_LOT_SHED's interpretation_notes
-- (db/033) -- split out here as their own queryable SETBACK rules, since they
-- are genuine front/side boundary distances for a Class 10a structure (user
-- request, 25 Oct 2026, reviewing Table 5.3.4.1 against the live scheme PDF).
-- =============================================================================
SET search_path = regs, public;

SELECT define_rule($r${
 "rule_id": "BCC.C.DHC_SMALL_LOT_DOUBLE_CARPORT_FRONT", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.FRONTAGE", "title": "Dwelling house character overlay, small lot: double carport outside the building envelope needs no planning approval only if set back >= 2 m from the front boundary",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_FRONT", "operator": ">=", "value": 2.0, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "OVERLAY", "overlay": "BCC:OV:DWELLING_HOUSE_CHARACTER_OVERLAY"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "width_m", "op": ">", "value": 3}, {"fact": "width_m", "op": "<=", "value": 6},
                 {"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "pad_dhc_small_lot_minor_structures", "role": "PRIMARY",
              "quote": "1 double carport on a lot 180m2 or greater only, where: - maximum depth 6m, excluding eaves; - maximum width 6m, excluding eaves; - minimum side boundary setback 1.5m; - minimum front boundary setback 2m; - maximum crossover width 4.5m; - on a lot with a street frontage width of 15m or greater, and the total building footprint of the dwelling and carport does not exceed 50%."}],
 "interpretation_notes": "Split out from BCC.C.DHC_SMALL_LOT_SHED (db/033), where this figure previously sat only in free text. NOT an alternative provision to QDC/QHC (researcher-confirmed, alternative_provision_to_qdc_qhc=NO): the table's own Note keeps 'the siting provisions of the Building Regulation 2021' (QDC/QHC) applying regardless, so this 2 m is an ADDITIONAL eligibility threshold for 'prescribed accepted development' status (no development application needed) -- not a replacement of the governing QDC/QHC setback. A double carport meeting this AND the QDC/QHC setback is prescribed accepted; one that meets QDC/QHC but not this 2 m still needs a development application even though lawfully sited. automatable=false because eligibility also requires the carport be 'outside the building envelope' of the small-lot code (ss A/B), a site-specific design fact not derivable here. width_m > 3 and <= 6 distinguishes this (double carport) item from the single-carport item in the same source row (max width 3 m), which has no stated setback.",
 "effective_from": "2026-09-18"}$r$);

SELECT define_rule($r${
 "rule_id": "BCC.C.DHC_SMALL_LOT_DOUBLE_CARPORT_SIDE", "instrument_version": "BCC_CITY_PLAN_2014@2026-09-18",
 "topic": "SETBACK.SIDE", "title": "Dwelling house character overlay, small lot: double carport outside the building envelope needs no planning approval only if set back >= 1.5 m from the side boundary",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "value": 1.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "BRISBANE"}, {"level": "OVERLAY", "overlay": "BCC:OV:DWELLING_HOUSE_CHARACTER_OVERLAY"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 180}, {"fact": "lot_area_m2", "op": "<", "value": 450},
                 {"fact": "width_m", "op": ">", "value": 3}, {"fact": "width_m", "op": "<=", "value": 6},
                 {"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "pad_dhc_small_lot_minor_structures", "role": "PRIMARY",
              "quote": "1 double carport on a lot 180m2 or greater only, where: - maximum depth 6m, excluding eaves; - maximum width 6m, excluding eaves; - minimum side boundary setback 1.5m; - minimum front boundary setback 2m; - maximum crossover width 4.5m; - on a lot with a street frontage width of 15m or greater, and the total building footprint of the dwelling and carport does not exceed 50%."}],
 "interpretation_notes": "Split out from BCC.C.DHC_SMALL_LOT_SHED (db/033), where this figure previously sat only in free text. NOT an alternative provision to QDC/QHC (researcher-confirmed, alternative_provision_to_qdc_qhc=NO): the table's own Note keeps 'the siting provisions of the Building Regulation 2021' (QDC/QHC) applying regardless, so this 1.5 m is an ADDITIONAL eligibility threshold for 'prescribed accepted development' status (no development application needed) -- not a replacement of the governing QDC/QHC setback. automatable=false for the same 'outside the building envelope' reason as the front-setback counterpart. width_m > 3 and <= 6 distinguishes this (double carport) item from the single-carport item in the same source row (max width 3 m), which has no stated setback.",
 "effective_from": "2026-09-18"}$r$);
