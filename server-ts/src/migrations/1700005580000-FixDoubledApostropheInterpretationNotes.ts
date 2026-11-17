import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Data-quality fix, found while building LivingstoneToowoombaPlanOfDevelopmentFlags (migration
 * 1700005520000): inside a define_rule() call, the JSON blob is itself wrapped in a dollar-quoted
 * string ($r$...$r$), so a single quote inside it needs no SQL escaping -- writing '' (the correct
 * escaping for a regular '...'-quoted SQL string, e.g. inside define_provision() or an UPDATE
 * statement) instead inserts a literal, doubled apostrophe into the stored text. Confirmed live via
 * CLI output (e.g. "Schedule 10''s own setback tables...") before being caught and fixed in that new
 * migration's own source; this migration repairs the same mistake already applied to 5 existing rules'
 * interpretation_notes across 3 earlier migrations (1700004140000 PoolBarrierFullMp34Extraction,
 * 1700004740000 LivingstoneSchedule10FiguresAndSecondRow, 1700004980000
 * MoretonBayEmergingCommunityOutbuildings). No rule content/meaning changes -- cosmetic text repair only.
 */
export class FixDoubledApostropheInterpretationNotes1700005580000 implements MigrationInterface {
  name = "FixDoubledApostropheInterpretationNotes1700005580000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE rule_versions
SET interpretation_notes = replace(interpretation_notes, $q$''$q$, $q$'$q$)
WHERE rule_version_id IN (
  'MP34.S1_16.RETAINING_WALL_BARRIER_NO_FOOTHOLD@2012-07-27',
  'MP34.S1_17.WATER_BODY_AS_BARRIER@2012-07-27',
  'MP34.S1_19_20.BALCONY_NCZ@2012-07-27',
  'LSC.C.RUR_EC_SMALL_SECONDARY_FIG6_SETBACK@2025-05-02',
  'CMB.C.EC_OUTBUILDING_MAIN_BUILDING_LINE_POSITION@2026-09-11'
)
AND interpretation_notes LIKE $q$%''%$q$;
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
