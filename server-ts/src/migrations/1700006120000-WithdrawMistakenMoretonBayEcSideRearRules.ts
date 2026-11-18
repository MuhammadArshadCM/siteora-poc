import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Withdraws CMB.C.EC_DEVELOPED_LOT_SIDE_SETBACK and CMB.C.EC_DEVELOPED_LOT_REAR_SETBACK, which were live
 * on this database by accident and are wrong (see migration 1700006060000's own explanation of why the EC
 * zone code's Table 6.2.3.x is not the operative Class 10a standard for a developed lot -- the Dwelling
 * house code, already correctly encoded via open_issues #58, is).
 *
 * How they got live: that migration's TypeScript source file was deleted after being tested ONLY against a
 * scratch database (the mistake was caught before an intentional "apply to live" step), but `tsc`'s
 * incremental build does not delete an output file when its source is removed -- the already-compiled
 * dist/src/migrations/1700006000000-MoretonBayEcDevelopedLotSideRearSetbacks.js (and its .map) survived on
 * disk. The very next migration (1700006060000, the correction) was then applied for real with
 * `typeorm migration:run`, which runs every *.js file in dist/src/migrations not yet recorded in this
 * database's own schema_migrations -- so the stale, deleted-in-source migration ran too, silently
 * re-introducing the two wrong rules into this live database. Caught via an unexpected parity failure
 * (moreton-bay-kippa-ring-patio's other_places_count changed from 30 to 32, exactly the 2 rules) right
 * after applying 1700006060000. The stale dist/*.js files have now been deleted from disk.
 *
 * WITHDRAWN rather than deleted, per this project's established convention (e.g. BCC.C.SL_SIDE_ZERO_CONSENT)
 * -- kept in the dataset for provenance/audit, excluded from candidacy.
 */
export class WithdrawMistakenMoretonBayEcSideRearRules1700006120000 implements MigrationInterface {
  name = "WithdrawMistakenMoretonBayEcSideRearRules1700006120000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE rule_versions
SET status = 'WITHDRAWN'
WHERE rule_version_id IN (
  'CMB.C.EC_DEVELOPED_LOT_SIDE_SETBACK@2026-09-11',
  'CMB.C.EC_DEVELOPED_LOT_REAR_SETBACK@2026-09-11'
);
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
