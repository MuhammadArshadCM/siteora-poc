-- =============================================================================
-- Resolves the two Moreton Bay V9 follow-ups logged in db/068 (#174, #175),
-- read directly from the user-supplied V9 PDF (research/sources/MORETON_BAY/
-- moreton_bay_planning_scheme_v9.pdf).
-- =============================================================================
SET search_path = regs, public;

-- -----------------------------------------------------------------------
-- #174 Morayfield South Structure Plan / zone-code formalisation --
-- CONFIRMED NO CHANGE NEEDED, doc-only close.
--
-- V9's new 6.2.3.3 "Morayfield South precinct" zone-code section is all
-- Purpose/Overall-outcomes text (qualitative, no setback figures) plus a
-- reference to the Morayfield South Structure Plan map -- it governs the
-- MCU/use-assessment category, not Class 10a siting numbers. The actual
-- numeric table this project already encoded (db/049) is Table 9.3.1.6 in
-- the Dwelling house code (Part 9), and its heading in V9 reads, verbatim:
-- "General residential zone - Urban neighbourhood precinct, and Emerging
-- community zone - Transition precinct (developed lot) and Morayfield
-- South precinct (developed lot) - Urban neighbourhood sub-precinct" --
-- i.e. Morayfield South is now explicitly named as its own item (reflecting
-- the new formal precinct structure) alongside the same General
-- residential/Transition combination db/049 already covers, but the
-- figures in every column are IDENTICAL to what is already encoded: Side
-- and Rear both still read "Refer to standard as in QDC" (no scheme
-- number, same as before), Trafficable water body is still "Min 4.5m"
-- (matches CMB.C.URBAN_WATERBODY_SETBACK exactly). Nothing changed in
-- substance.
--
-- Separately: the live zoning open-data layer (poc/zoning_layers.json)
-- already notes its ZONE_PREC value for this area is just "Transition"
-- with no Morayfield South sub-split, and that layer's last edit date
-- (Oct 2024) predates V9 -- so the existing manual --zone/--precinct
-- override requirement for this sub-area is unchanged either way; V9's
-- new formal precinct structure has not (yet) propagated to the public GIS
-- layer this tool queries.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 174;

-- -----------------------------------------------------------------------
-- #175 Bushfire-prone-area designation widened to General residential,
-- Centre, Industry and Township zones -- ACTUAL NEW RULE.
--
-- V9's Table 1.6.1 designation row (verbatim, quoted below) no longer
-- carries any zone exclusion -- confirmed by comparing to this project's
-- own prior research note on CMB.mb_tw_rad77_bushfire_separation ("Table
-- 1.6.1 rule 241 says Township zone land is NOT a designated bushfire
-- prone area for the Building Regulation, but this planning RAD still
-- applies where the Bushfire hazard overlay is mapped") -- that Township
-- exclusion, and the equivalent for General residential, Centre and
-- Industry, is exactly what Major Amendment No.4 removed.
--
-- This is a Building Regulation s7 DESIGNATION, not a scheme-level setback
-- or RAD -- it sits one level up from, and in addition to, the existing
-- scheme-level bushfire RADs (RAD77 Township, RAD92 Rural, RAD100 Rural
-- residential, all already encoded as draft/automatable=false). Once land
-- is designated bushfire prone for the Building Regulation, AS 3959-2018
-- construction requirements (BAL rating) can apply to the building itself
-- -- a CONSTRUCTION standard, not a siting rule, same category as
-- NCC.PT9_2.CLASS10A_FIRE_SEPARATION (db/062). Encoded the same way: a
-- state-... no, council-specific (this designation mechanism is Moreton
-- Bay's own Table 1.6.1, not a state-wide NCC clause) informational
-- REQUIREMENT, automatable=false, "must hold" style.
--
-- Only General residential and Township exist as zones in this project's
-- Moreton Bay dataset (Centre and Industry were never built out here --
-- they are not zones where a dwelling-house Class 10a scenario arises, so
-- out of this tool's scope by design, not an oversight).
-- -----------------------------------------------------------------------
SELECT define_provision('MBRC_PLANNING_SCHEME_2016@2026-09-11', 'Table 1.6.1 (Designation of bushfire prone area)', 'DEFINITION',
  $q$Designation of bushfire prone area for the BCA or QDC. (Building Act 1975 section 32(a) and Building Regulation 2021 section 7). The areas shown on Overlay map - Bushfire hazard as Very high potential bushfire intensity, High potential bushfire intensity, Medium potential bushfire intensity, and Potential impact buffer, are designated bushfire prone areas for section 7 of the Building Regulation 2021.$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL,
  'research/sources/MORETON_BAY/moreton_bay_planning_scheme_v9.pdf');

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, vertical_projection, evaluate_per_part, notes) VALUES
  ('CMB_BUSHFIRE_PRONE_DESIGNATION', 'PRESENCE', 'CLASS_1_AND_10_BUILDING', NULL, false, false,
   'Presence of a Building Regulation 2021 s7 bushfire-prone-area designation (triggers AS 3959-2018 construction requirements) under Moreton Bay''s own Table 1.6.1 mechanism. Not a setback -- reference_geometry deliberately NULL, same pattern as NCC_FIRE_SEPARATION_WALL (db/062).');

SELECT define_rule($r${
 "rule_id": "CMB.C.BUSHFIRE_PRONE_AREA_DESIGNATION", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "CONSTRUCTION.BUSHFIRE", "title": "General residential / Township zone, Bushfire hazard overlay: land is a designated bushfire prone area (Building Regulation s7) -- AS 3959 construction requirements may apply",
 "role": "REQUIREMENT", "regime": "FIRE_SAFETY", "enforceability": "MANDATORY", "provision_kind": "DEFINITION",
 "measurement": "CMB_BUSHFIRE_PRONE_DESIGNATION", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:GENERAL_RESIDENTIAL"},
            {"level": "ZONE", "zone": "CMB:TOWNSHIP"}, {"level": "OVERLAY", "overlay": "CMB:OV:BUSHFIRE_HAZARD"}],
 "subjects": ["ANY"],
 "sources": [{"ref": "Table 1.6.1 (Designation of bushfire prone area)", "role": "PRIMARY"}],
 "interpretation_notes": "Version 9 (Major Amendment No.4, eff. 2 Nov 2026) removed the prior Table 1.6.1 exemption for General residential, Centre, Industry and Township zones from this Building Regulation s7 designation -- confirmed by comparing V9''s designation row (no zone carve-out at all) against this project''s own prior note on CMB.mb_tw_rad77_bushfire_separation, which recorded the pre-V9 Township exclusion verbatim. This sits ABOVE, and in addition to, the scheme''s own planning-level bushfire RADs (RAD77 Township, RAD92 Rural, RAD100 Rural residential) -- it is a Building Act/Building Regulation construction-standard trigger (AS 3959 BAL rating), not a siting/setback rule, same category as NCC.PT9_2.CLASS10A_FIRE_SEPARATION. Always surfaced for manual review when the Bushfire hazard overlay is mapped on a General residential or Township lot, since this tool does not itself calculate a BAL rating. Centre and Industry zones are not built out in this dataset (no dwelling-house Class 10a scenario arises there) -- out of scope by design, not an oversight; re-add this rule''s scope if either zone is ever curated.",
 "effective_from": "2026-11-02"}$r$);
