import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Found while validating this migration conversion: replaying every historical db/*.sql file against a
 * fresh database left 28 open_issues rows resolved on the live `siteora` database but NOT resolved after
 * a full file replay — i.e. these were closed at some point by a direct `UPDATE regs.open_issues SET
 * resolved_at = ...` run by hand against the live database, with no SQL file ever capturing it. Confirmed
 * by grepping every db/*.sql file for each issue_id below — none appear anywhere.
 *
 * All 28 read as the same kind of "confirmed absence/no scheme-specific provision, QDC/QHC governs" or
 * "confirmed no effect" doc-only close used throughout this project's history (QHC-transition
 * confirmations for Brisbane/Gold Coast/Moreton Bay/Sunshine Coast/Logan/Ipswich/Redland/Toowoomba/
 * Townsville, pool-setback absence confirmations, site-cover scope confirmations) — there is no reason to
 * believe they were closed incorrectly, just that the closure was never written to a file. Recorded here
 * so the migration history is complete and the live database becomes fully reproducible from migrations
 * alone going forward — this is the gap "move everything to migration" was meant to close.
 *
 * Idempotent (WHERE resolved_at IS NULL): a no-op if run against a database where these are already
 * resolved (i.e. the live `siteora` database itself, which this migration's up() will be *faked* against
 * via `typeorm migration:run -f`, not actually re-executed).
 */
export class CatchUpUndocumentedClosures1700003960000 implements MigrationInterface {
  name = "CatchUpUndocumentedClosures1700003960000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `UPDATE regs.open_issues SET resolved_at = CURRENT_DATE
       WHERE resolved_at IS NULL AND issue_id IN
         (7, 12, 23, 26, 34, 37, 44, 45, 46, 55, 61, 73, 74, 86, 87, 94, 96, 97, 99, 101, 104, 106, 108, 116, 117, 162, 166, 171)`
    );

    // Two more undocumented live fixes found the same way (full content diff against a fresh replay):

    // CMB.C.URBAN_WATERBODY_SETBACK (db/049) was defined with subjects ["CLASS_1", "OUTDOOR_STRUCTURE"] --
    // but OUTDOOR_STRUCTURE is a sibling of CLASS_10A (parent ANY), not an ancestor of SHED/GARAGE/CARPORT/
    // DETACHED_LAUNDRY, so subjectMatches()'s ancestor walk would never have matched an actual shed/garage/
    // carport/laundry against it -- the rule's own title ("buildings, structures and domestic outbuildings")
    // would have silently failed to apply to outbuildings at all. Live was fixed by replacing the single
    // OUTDOOR_STRUCTURE row with CLASS_10A's individual children; replayed here.
    await queryRunner.query(
      `DELETE FROM regs.rule_subjects WHERE rule_version_id = 'CMB.C.URBAN_WATERBODY_SETBACK@2026-09-11' AND structure_type_id = 'OUTDOOR_STRUCTURE'`
    );
    await queryRunner.query(
      `INSERT INTO regs.rule_subjects (rule_version_id, structure_type_id, exclude)
       SELECT 'CMB.C.URBAN_WATERBODY_SETBACK@2026-09-11', t, false
       FROM unnest(ARRAY['CARPORT','CLASS_10A_OTHER','DETACHED_LAUNDRY','GARAGE','SHED']) AS t
       WHERE NOT EXISTS (
         SELECT 1 FROM regs.rule_subjects
         WHERE rule_version_id = 'CMB.C.URBAN_WATERBODY_SETBACK@2026-09-11' AND structure_type_id = t
       )`
    );

    // NOTE on a related but opposite-direction drift found during validation: db/062 itself already
    // defines NCC_FIRE_SEPARATION_WALL's measurement notes with the FULL text (documenting the
    // reference_geometry triplication bug and its fix) -- replaying db/062 alone already produces the
    // correct value, nothing to catch up here. It's the LIVE database that's stale (still carries the
    // shorter, pre-fix note, which was never updated when the file was extended) -- fixed directly against
    // live in the same session as this migration, not through the replay chain, since the file was
    // already correct and a migration "fixing" it to match the file would be a no-op everywhere except
    // live.
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CatchUpUndocumentedClosures1700003960000 re-closes issues that were already resolved outside of any tracked migration; there is no recorded prior state to revert to.");
  }
}
