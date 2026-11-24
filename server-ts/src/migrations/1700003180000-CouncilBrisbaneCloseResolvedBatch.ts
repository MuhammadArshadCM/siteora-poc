import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/058_council_brisbane_close_resolved_batch.sql verbatim (ported from the project's hand-applied SQL history, originally db/058_council_brisbane_close_resolved_batch.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilBrisbaneCloseResolvedBatch1700003180000 implements MigrationInterface {
  name = "CouncilBrisbaneCloseResolvedBatch1700003180000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Close Brisbane open_issues already confirmed resolved in earlier passes
-- this session but never formally closed. No code changes -- all of these
-- already match the current, correct implementation.
-- =============================================================================
SET search_path = regs, public;

-- #6, #20 (QHC transition): resolved by the Building Regulation 2021 s106 text,
-- already confirmed verbatim in this database (QLD_BUILDING_REG_2021@2026-08-14):
-- a scheme's former QDC-based alternative provisions continue unchanged until
-- the scheme is amended for the QHC or 1 Sept 2029. No chapter-mapping needed;
-- current behaviour (apply the existing provisions as-is) is already correct.
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (6, 20);

-- #9: BCC.C.SL_GARAGE_STREET_5_5 already has subjects: ["GARAGE"] only (db/031)
-- -- carports correctly excluded, matching the deliberate AO5(c)/AO22.2 ("covered
-- car parking") contrast. Already correct.
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 9;

-- #14: Dwelling house character overlay is already wired to a live ArcGIS layer
-- (poc/zoning_layers.json: Dwelling_house_character_overlay), queried per-lot
-- this session (e.g. "11 Glencarron Street, Kenmore" returned it live). Already
-- resolved.
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 14;

-- #15: confirmed neither the Dwelling house code nor small-lot code Section A
-- names HDR for height. The correct consequence -- QDC/QHC height governs HDR
-- unmodified -- is already implemented: BCC.C.SL_HEIGHT's scopes (db/033)
-- already exclude High density residential. No scheme height AO exists for
-- HDR, so there is nothing to encode; this is a correctly-left gap, not a bug.
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 15;

-- #17: standard (non-small) HDR lots correctly fall to QDC/QHC for setback/
-- site cover -- matches existing, correct fallback behaviour. Not a bug.
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 17;
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilBrisbaneCloseResolvedBatch1700003180000 ports a historical content/schema migration (db/058_council_brisbane_close_resolved_batch.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
