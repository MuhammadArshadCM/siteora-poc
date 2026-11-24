import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/041_council_brisbane_heritage_flood_pre1911_overlays.sql verbatim (ported from the project's hand-applied SQL history, originally db/041_council_brisbane_heritage_flood_pre1911_overlays.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilBrisbaneHeritageFloodPre1911Overlays1700002160000 implements MigrationInterface {
  name = "CouncilBrisbaneHeritageFloodPre1911Overlays1700002160000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Brisbane: resolve the open issue "Heritage, Pre-1911 building, flood and
-- other overlays can still raise the level of assessment in HDR (section
-- 5.10); not extracted here." (db/030, raised with the initial Brisbane load).
--
-- Researched 3 Nov 2026 against City Plan 2014's own code text (DB provisions
-- for the Flood overlay code (8.2.11) already extracted; Heritage overlay
-- code (8.2.12) read directly from Brisbane City Council's published text;
-- Pre-1911 building overlay already covered by BCC.pad_tbc_outbuildings_
-- carports_pools, db/030/033). Conclusion for all three, consistent with the
-- same "overlay raises assessment category but sets no numeric Class 10
-- siting standard" pattern already recorded for Logan (heritage/PSP4),
-- Mount Isa and Townsville:
--   - Pre-1911 building overlay: only changes accepted-development /
--     assessment category for outbuildings, carports and pools (Table
--     5.3.4.1); QDC/QHC siting still governs the actual setback. No new
--     SETBACK rule.
--   - Flood overlay: sets minimum floor levels / freeboard for habitable
--     rooms and attached garages (8.2.11 PO2/AO2.1, RO3), not a horizontal
--     setback for freestanding Class 10 structures. No new SETBACK rule.
--   - Heritage overlay (Local heritage place / State heritage place / Area
--     adjoining a heritage place): PO1-PO5 (and PO16-PO24 for "area
--     adjoining") are qualitative merit criteria with "No acceptable outcome
--     is prescribed" -- there is no numeric siting standard for a new shed,
--     carport, garage or pool. Being on a Local/State heritage place does
--     remove the development from the accepted-development pathway (Table
--     5.3.4.1 already encodes that exclusion), pushing it to a Heritage
--     Impact Assessment / Council discretion instead of a deemed-to-comply
--     number -- so there is nothing further to encode as a SETBACK rule.
--
-- Net effect: all three are wired below as informational overlay hits only
-- (site_layers.json/zoning_layers.json surfaces presence to the report), with
-- no new rule_versions, since none of the three source codes sets a numeric
-- or automatable siting standard for Class 10 structures beyond QDC/QHC.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ($q$BCC:OV:HERITAGE_OVERLAY_LOCAL_HERITAGE_AREA$q$, $q$BCC_CITY_PLAN_2014$q$, $q$Heritage overlay (Local heritage place)$q$);
INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ($q$BCC:OV:HERITAGE_OVERLAY_STATE_HERITAGE_AREA$q$, $q$BCC_CITY_PLAN_2014$q$, $q$Heritage overlay (State heritage place)$q$);
INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ($q$BCC:OV:HERITAGE_OVERLAY_AREA_ADJOINING$q$, $q$BCC_CITY_PLAN_2014$q$, $q$Heritage overlay (Area adjoining a heritage place)$q$);

UPDATE open_issues
SET resolved_at = DATE '2026-11-03',
    description = description || $q$ RESOLVED 2026-11-03: researched City Plan 2014's own Heritage overlay code (8.2.12), Flood overlay code (8.2.11) and the Pre-1911 building overlay's Table 5.3.4.1 treatment -- none sets a numeric or automatable Class 10 siting/setback standard (Heritage overlay PO1-PO5/PO16-PO24 explicitly carry "No acceptable outcome is prescribed"; Flood overlay only sets floor-level freeboard; Pre-1911 only changes accepted-development category). All three only raise the assessment category, same as the already-recorded pattern for Logan/Mount Isa/Townsville. Wired as informational overlay hits (zoning_layers.json) instead of new SETBACK rules.$q$
WHERE lg_id = $q$BRISBANE$q$
  AND description = $q$Heritage, Pre-1911 building, flood and other overlays can still raise the level of assessment in HDR (section 5.10); not extracted here.$q$
  AND resolved_at IS NULL;
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilBrisbaneHeritageFloodPre1911Overlays1700002160000 ports a historical content/schema migration (db/041_council_brisbane_heritage_flood_pre1911_overlays.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
