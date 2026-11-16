-- =============================================================================
-- Gold Coast: follow-up to db/042-043, fixing open issues that genuinely
-- could be resolved by more research (3 Nov 2026), after thorough reading of
-- the actual City Plan code text for four items:
--
--   1. Bushfire hazard overlay code (8.2.3) -- full read (not just a keyword
--      search), confirms NO numeric Class 10a setback/separation exists.
--      RO1 fully exempts the ordinary case ("a dwelling house on a lot
--      smaller than 1,000 sqm serviced by reticulated water" needs no
--      assessment at all); where not exempt, RO2 only requires "bushfire
--      radiation zones are located entirely within the boundaries of the
--      private property" -- a qualitative containment test, not a metre
--      figure, and not automatable from zoning data alone. The code does
--      NOT differentiate by the High/Medium/Very High Potential Bushfire
--      Intensity or Potential Impact Buffer sub-categories used in the GIS
--      layer -- it treats "in the overlay" as one undifferentiated trigger.
--      Source: Part 8.2.3 Bushfire hazard overlay code.
--      Net effect: same "raises assessment category, no numeric siting
--      standard" pattern as Brisbane's Heritage/Flood/Pre-1911 overlays
--      (db/041) -- wired below as an informational overlay hit only.
--
--   2. Water resource catchment overlay code (8.2.19/8.2.16), Table 8.2.19-2:
--      confirmed NOT Class 10a relevant. The table's separation distances
--      (e.g. 50m from an intermittent watercourse, 100m permanent
--      watercourse, 30m water supply well/bore/dam) are scoped by the
--      code's own Application clause (8.2.19.1) to "material change of use,
--      reconfiguring a lot or operational work" -- they govern on-site
--      sewage/effluent/chemical/waste infrastructure for NEW uses or
--      subdivisions, not boundary setbacks for a shed/carport/pool added to
--      an existing dwelling. Nothing to encode; no GIS wiring needed either
--      (this overlay does not change the assessment pathway for ordinary
--      Class 10a building work the way Bushfire/Heritage/Flood do).
--
--   3. Residential density overlay (RD1-RD8, LDR1/LDR2 codes, GIS layer
--      "Residential density", FeatureServer 115): confirmed to be a
--      subdivision/minimum-lot-size trigger only (e.g. Low density
--      residential zone code: lots down to 400 sqm only where the
--      Residential density overlay map shows RD1 or greater) -- unrelated
--      to Class 10a structure siting. No GIS wiring needed for the same
--      reason as #2.
--
--   4. Dwelling house overlay (GIS layer "Dwelling house overlay area",
--      FeatureServer 43, single category): INCONCLUSIVE. No current City
--      Plan text referencing a "Dwelling house overlay" by that name could
--      be found in the time available -- possibly a legacy/renamed layer.
--      Left open below, not resolved -- do not build logic on the
--      unconfirmed "gatekeeper" hypothesis.
--
--   Mixed use zone code (issue #168, ex-#31): a candidate source was found
--      (an "Our City Our Plan" tracked-changes amendment PDF, explicitly
--      marked "FOR MINISTERIAL APPROVAL" -- adoption status unconfirmed),
--      but its section numbering (Part 6.2.19/6.2.20) conflicts with the
--      section number this project already uses for the Rural zone code
--      (6.2.20, db/035/036, sourced from the live eplan's own ruleId
--      references) -- the two zones cannot both be 6.2.20 in the same
--      in-force document, so this source cannot be relied on without
--      resolving that conflict against the live eplan (which blocks
--      automated fetching, HTTP 403). NOT encoded; issue left open with
--      this finding recorded so a future pass does not repeat the dead end.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ($q$CGC:OV:BUSHFIRE_HAZARD_OVERLAY$q$, $q$CGC_CITY_PLAN$q$, $q$Bushfire hazard overlay$q$);
INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ($q$CGC:OV:BUSHFIRE_HAZARD_OVERLAY_HIGH_POTENTIAL_BUSHFIRE_INTENSITY$q$, $q$CGC_CITY_PLAN$q$, $q$Bushfire hazard overlay (High Potential Bushfire Intensity)$q$);
INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ($q$CGC:OV:BUSHFIRE_HAZARD_OVERLAY_MEDIUM_POTENTIAL_BUSHFIRE_INTENSITY$q$, $q$CGC_CITY_PLAN$q$, $q$Bushfire hazard overlay (Medium Potential Bushfire Intensity)$q$);
INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ($q$CGC:OV:BUSHFIRE_HAZARD_OVERLAY_VERY_HIGH_POTENTIAL_BUSHFIRE_INTENSITY$q$, $q$CGC_CITY_PLAN$q$, $q$Bushfire hazard overlay (Very High Potential Bushfire Intensity)$q$);
INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ($q$CGC:OV:BUSHFIRE_HAZARD_OVERLAY_POTENTIAL_IMPACT_BUFFER$q$, $q$CGC_CITY_PLAN$q$, $q$Bushfire hazard overlay (Potential Impact Buffer)$q$);

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03: full read of Part 8.2.3 Bushfire hazard overlay code (not just a keyword search) confirms no numeric setback/separation exists for Class 10a structures -- RO1 exempts the ordinary dwelling-house case outright, RO2 (where not exempt) is a qualitative "radiation zones within the property boundary" containment test, not a metre figure, and not automatable from zoning data. No differentiation by hazard-intensity sub-category. Wired as an informational overlay hit only (zoning_layers.json), same treatment as Brisbane's Heritage/Flood/Pre-1911 overlays (db/041) -- raises assessment category but sets no siting number.$q$
WHERE issue_id = 33 AND resolved_at IS NULL;

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03: Table 8.2.19-2's separation distances are scoped by the code's own Application clause (8.2.19.1) to material change of use / reconfiguring a lot / operational work -- they govern on-site effluent/infrastructure siting for new uses or subdivisions relative to watercourses, not boundary setbacks for a shed/carport/pool added to an existing dwelling. Confirmed not Class 10a setback-relevant; nothing to encode, no GIS wiring needed (does not change the assessment pathway for ordinary Class 10a building work).$q$
WHERE issue_id = 32 AND resolved_at IS NULL;

UPDATE open_issues
SET description = description || $q$ PARTIALLY ADDRESSED 2026-11-03: Building height overlay portion resolved (db/042, mapped_max_height_m). Residential density overlay (RD1-RD8/LDR1/LDR2) confirmed to be a subdivision/minimum-lot-size trigger only, unrelated to Class 10a siting -- no GIS wiring needed for it. Dwelling house overlay map remains genuinely open: no current City Plan text referencing it by that name could be found (possibly legacy/renamed); its purpose (which code applies vs a numeric standard) is unconfirmed -- left open.$q$
WHERE issue_id = 30 AND resolved_at IS NULL;

UPDATE open_issues
SET description = description || $q$ RESEARCHED 2026-11-03, NOT RESOLVED: a candidate current-looking source was found (an "Our City Our Plan" tracked-changes amendment PDF, marked "FOR MINISTERIAL APPROVAL" -- adoption status unconfirmed) giving Mixed use zone setback/site-cover/height figures, but its section numbering (6.2.19/6.2.20) conflicts with the section this project already uses for the Rural zone code (6.2.20, sourced from the live eplan) -- the two zones cannot both occupy 6.2.20 in the same in-force document, so this source cannot be relied on without reconciling against the live eplan, which blocks automated fetching (HTTP 403 on direct request). Left open pending a manual eplan lookup or a verified non-draft PDF.$q$
WHERE issue_id = 168 AND resolved_at IS NULL;
