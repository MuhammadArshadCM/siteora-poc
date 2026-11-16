-- =============================================================================
-- Gold Coast: resolve open issues that were overtaken by later curated work
-- (db/035, db/036) but never swept, after re-verifying live on 3 Nov 2026 in
-- response to a direct question about V13/V14, HDR/EC/Rural Class 10a
-- coverage, and the Building height overlay defaulting to '9m'.
--
-- Verified live (CLI, City Plan Version 14 instrument text, Version 13 GIS
-- geometry, mapped_max_height_m fact):
--   - 136 Marine Parade, Coolangatta (CGC:HIGH_DENSITY_RESIDENTIAL, lot
--     00000SP139287): Building height overlay returns the genuine per-polygon
--     value (38 m), not a default -- CGC.C.HDR_HEIGHT_MAPPED (db/036) reads
--     mapped_max_height_m from the dedicated Building height overlay
--     FeatureServer (layer 33, field HEIGHT_IN_METRES), a different source
--     to the zone layer's own defaulted 'Building_height' field that issue
--     #47 correctly flagged as unreliable. CGC.gc_hdr_building_height (the
--     old fixed-9m draft) is already SUPERSEDED.
--   - Same address: HDR front setback 4 m, side/rear 1.5 m, site cover 50%
--     all return DETERMINED from CGC.C.HDR_FRONT_SETBACK / HDR_SIDE_REAR_
--     SETBACK / HDR_SITE_COVER (db/036) -- confirms issue #49's own proposed
--     reading (Table 1.5-1 'Buildings: Relevant zone code') is exactly what
--     is now encoded.
--   - 26 Observatory Drive, Reedy Creek (CGC:EMERGING_COMMUNITY): zone-level
--     height/site-cover/front/side-rear setbacks all now return (MANUAL_
--     REVIEW pending lot_from_residential_subdivision, as expected) from
--     CGC.C.EC_* (db/035).
--   - 912 Tomewin Mountain Road, Currumbin Valley (CGC:RURAL): zone-level
--     height/front/side-rear setbacks return from CGC.C.RURAL_* (db/035);
--     Rural site cover genuinely still falls through to QDC's 50% default --
--     confirmed the Rural zone code itself has no site-cover provision
--     (issue #34, left open, still accurate).
--
-- Not resolved: Mixed use zone dwelling house provisions are still not
-- extracted at all (no CGC Mixed use rule exists) -- split out of #31 below
-- as its own narrower issue. Issue #34 (Rural site cover), #36 (no Class
-- 10a-specific allowance in Rural/EC zone codes), #48 (HDR has no
-- freestanding garage/carport height limit) remain open: re-confirmed live
-- as genuine silences in the scheme itself, not gaps in this project's
-- research.
-- =============================================================================
SET search_path = regs, public;

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03: superseded by db/036 -- CGC.C.HDR_HEIGHT_MAPPED now reads the genuine per-polygon value from the dedicated Building height overlay layer (not the zone layer's defaulted field); verified live at 136 Marine Parade, Coolangatta (returns 38 m, not 9 m).$q$
WHERE issue_id = 47 AND resolved_at IS NULL;

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03: this reading is now encoded and ACTIVE (CGC.C.HDR_FRONT_SETBACK, CGC.C.HDR_SIDE_REAR_SETBACK, CGC.C.HDR_COVERED_PARKING_FRONT, db/036); verified live at 136 Marine Parade, Coolangatta (front 4 m, side/rear 1.5 m all DETERMINED).$q$
WHERE issue_id = 49 AND resolved_at IS NULL;

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03 for HDR and Emerging community: both now have zone-level dwelling house provisions extracted and ACTIVE (CGC.C.HDR_* / CGC.C.EC_*, db/035-036); verified live at 136 Marine Parade, Coolangatta and 26 Observatory Drive, Reedy Creek. Mixed use remains unextracted -- split out as issue below.$q$
WHERE issue_id = 31 AND resolved_at IS NULL;

INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES
  ($q$GOLD_COAST$q$, $q$CGC_CITY_PLAN$q$, 'MEDIUM',
   $q$Mixed use zone dwelling house provisions not extracted (split out from issue #31, 3 Nov 2026 -- Residential/Emerging community now done, Mixed use still outstanding).$q$);
