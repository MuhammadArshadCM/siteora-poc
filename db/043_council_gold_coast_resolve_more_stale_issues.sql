-- =============================================================================
-- Gold Coast: three more open issues overtaken by db/035-036 curated work,
-- found while triaging "what's still pending" for this council (3 Nov 2026).
--
-- Verified live:
--   - 10 Marina Parade, Jacobs Well (CGC:LOW_DENSITY_RESIDENTIAL, lot
--     4SP176520): side/rear setback returns 1.5 m DETERMINED from
--     CGC.C.LDR_SIDE_REAR_SETBACK (db/036) -- confirms issue #24's own
--     proposed reading (zone 1.5m applies to Class 10a via Table 1.5-1) is
--     now encoded; CGC.C.LDR_SMALL_LOT_CLASS10_BTB / MDR equivalent (db/036)
--     also ACTIVE for the small-lot case.
--   - CGC.C.EC_HEIGHT_MAPPED (db/035) is ACTIVE and reads mapped_max_height_m
--     the same way CGC.C.HDR_HEIGHT_MAPPED does (already verified in db/042)
--     -- issue #39's GIS lookup now exists.
--   - Issue #53 describes work ("added as gc_hdr_small_lot_* here") that was
--     completed in the same migration that raised it (db/036):
--     CGC.C.HDR_SMALL_LOT_FRONT / _COVERED_PARKING / _SECONDARY / _SIDE_REAR
--     / _CLASS10_BTB are all ACTIVE.
-- =============================================================================
SET search_path = regs, public;

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03: encoded and ACTIVE (CGC.C.LDR_SIDE_REAR_SETBACK, CGC.C.MDR_SIDE_REAR_SETBACK, CGC.C.LDR_SMALL_LOT_CLASS10_BTB, CGC.C.MDR_SMALL_LOT_CLASS10_BTB, db/036); verified live at 10 Marina Parade, Jacobs Well (side/rear 1.5 m DETERMINED).$q$
WHERE issue_id = 24 AND resolved_at IS NULL;

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03: CGC.C.EC_HEIGHT_MAPPED (db/035) is ACTIVE and reads mapped_max_height_m from the Building height overlay layer, the same mechanism verified for HDR in db/042.$q$
WHERE issue_id = 39 AND resolved_at IS NULL;

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03: this was a note describing work done in the same migration that raised it -- CGC.C.HDR_SMALL_LOT_FRONT/_COVERED_PARKING/_SECONDARY/_SIDE_REAR/_CLASS10_BTB (db/036) are all ACTIVE.$q$
WHERE issue_id = 53 AND resolved_at IS NULL;
