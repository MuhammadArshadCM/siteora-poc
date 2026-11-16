-- =============================================================================
-- Moreton Bay: research findings on the "Building heights overlay sourced
-- from 2022 open data, not the Version 8 legal map" gap (3 Nov 2026), plus
-- narrowing #62 to reflect zone-code encoding already completed since it was
-- raised.
--
-- Building heights overlay (issues #60, #71): checked both candidate GIS
-- layers on the council's ArcGIS Online org (152ojN3Ts9H3cdtl) directly via
-- their own service metadata (not the catalogue listing, which is
-- misleading):
--   - OM_Building_Heights_WebMercator_OpenData (currently wired, polygons):
--     true dataLastEditDate = 2022-03-08 (the catalogue page's "Updated
--     21/01/2025" is a re-harvest timestamp, not a data refresh).
--   - MBRC_PlanningScheme_OM_BuildingHeights_Exceptions (newer-looking name,
--     checked as a candidate replacement): also dataLastEditDate =
--     2022-03-08, and it is point geometry representing only exception
--     sites, not a general height layer -- not an improvement.
--   - A narrowly-scoped "Morayfield_Story_Map" service
--     (gis.moretonbay.qld.gov.au) shows existing/proposed height categories
--     for a draft Morayfield precinct amendment only -- not a general,
--     current, LGA-wide height source.
-- No fresher authoritative source exists on any council GIS platform found.
-- This is a genuine external blocker (the council has not yet republished a
-- Version-8-current spatial height layer), not a gap in this project's
-- research -- same category as Gold Coast's missing V14 zone geometry
-- (db/042). Left open with this finding recorded so a future pass does not
-- re-check the same two layers.
-- =============================================================================
SET search_path = regs, public;

UPDATE open_issues
SET description = description || $q$ RESEARCHED 2026-11-03, NOT RESOLVABLE FROM OUR SIDE: checked both this layer's own edit-date metadata (2022-03-08, not the catalogue's misleading 2025 re-harvest date) and the only other candidate on the council's GIS platform (MBRC_PlanningScheme_OM_BuildingHeights_Exceptions, same 2022-03-08 edit date, point geometry, exceptions only) -- no fresher Version 8 source exists anywhere published. Confirmed external blocker, not a project gap.$q$
WHERE issue_id = 60 AND resolved_at IS NULL;

UPDATE open_issues
SET description = description || $q$ RESEARCHED 2026-11-03, NOT RESOLVABLE FROM OUR SIDE: same finding as issue #60 -- no fresher source exists on the council's GIS platform. The "some Rural parcels had no polygon" sub-issue remains a genuine per-lot spot-check item (inherent to a sparse exception-style layer), not something a source-level fix resolves.$q$
WHERE issue_id = 71 AND resolved_at IS NULL;

UPDATE open_issues
SET description = description || $q$ UPDATED 2026-11-03: Rural (6.2.10) and Township (6.2.12) zone codes have since been substantially fetched and encoded (db/034-040) -- Rural has ACTIVE height (CMB.C.RURAL_HEIGHT_MAPPED); Township has ACTIVE front/secondary frontage/side/site-cover/height/outbuilding-height/outbuilding-roofed-area rules (CMB.C.TW_*). Genuinely still unfetched: Emerging community zone code (6.2.3) -- no CMB rule exists for it at all; Woodfordia local plan; Planning scheme policy - Residential design. Rural front/side/rear setbacks and Township rear setback remain DRAFT (not activated) pending the cross-reference questions in issues #65 and #67.$q$
WHERE issue_id = 62 AND resolved_at IS NULL;
