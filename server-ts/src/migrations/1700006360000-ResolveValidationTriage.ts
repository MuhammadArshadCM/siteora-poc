import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Fixes the 2 real bugs found while triaging the 18 validate-setbacks errors surfaced on 2026-11-19 (the other 16
 * were validator/tooling gaps, fixed in server-ts/src/tools/validate-setbacks.ts and verify-load.ts, not here).
 *
 * 1. CMB.C.EC_OUTBUILDING_MAIN_BUILDING_LINE_POSITION (Moreton Bay, Emerging community zone code -- Dwelling
 *    house, Domestic outbuildings, RAD48/50; created by MoretonBayEmergingCommunityOutbuildings1700004980000)
 *    had NO conditions at all. The engine evaluates a rule with no boundary_type condition as a candidate on
 *    every boundary (front, side, rear, secondary) -- but "is this outbuilding behind the main building line"
 *    is a frontage-only test (same bug class as the Logan carport fix, change_log.csv C017). Adds the missing
 *    boundary_type = PRIMARY_FRONTAGE condition.
 *
 * 2. provisions.provision_id 1132 ("Table 1.6.1 (Designation of bushfire prone area)", Moreton Bay V9, the
 *    PRIMARY source for the real ACTIVE rule CMB.C.BUSHFIRE_PRONE_AREA_DESIGNATION) was miscategorised with
 *    kind='DEFINITION' -- it is a table, not a glossary definition -- which made verify-load count it as a
 *    20th "definition" against the research file's correct 19 and report a false MISMATCH. Corrects kind to
 *    'TABLE'. Metadata-only: `kind` is not read by the rules engine, so this does not change any live rule's
 *    behaviour.
 *
 * Idempotent (guarded INSERT, unconditional-but-harmless UPDATE): this was first applied directly to live
 * `siteora` via psql (change_log.csv C025/C026, 2026-11-19) before being ported here to replay correctly on a
 * fresh database -- running it again on the already-fixed live database is a safe no-op.
 */
export class ResolveValidationTriage1700006360000 implements MigrationInterface {
  name = "ResolveValidationTriage1700006360000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

INSERT INTO rule_conditions (rule_version_id, group_no, fact_id, operator, value)
SELECT 'CMB.C.EC_OUTBUILDING_MAIN_BUILDING_LINE_POSITION@2026-09-11', 1, 'boundary_type', '=', '"PRIMARY_FRONTAGE"'
WHERE NOT EXISTS (
  SELECT 1 FROM rule_conditions
   WHERE rule_version_id = 'CMB.C.EC_OUTBUILDING_MAIN_BUILDING_LINE_POSITION@2026-09-11' AND fact_id = 'boundary_type'
);

UPDATE provisions SET kind = 'TABLE' WHERE provision_id = 1132;
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
