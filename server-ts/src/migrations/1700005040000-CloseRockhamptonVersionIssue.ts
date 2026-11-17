import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #150 (Rockhampton): user checked the council's current ePlan and confirmed the
 * planning scheme is still on Version 5 -- the 2026 LGIP/major amendment that was out for consultation
 * (Jan-Feb 2026) has not commenced. No version bump, no content change; closing with this confirmation.
 */
export class CloseRockhamptonVersionIssue1700005040000 implements MigrationInterface {
  name = "CloseRockhamptonVersionIssue1700005040000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-17',
  description = 'RESOLVED 2026-11-17: user checked the council''s current ePlan and confirmed the scheme is still on Version 5 -- the 2026 LGIP/major amendment that was out for consultation (Jan-Feb 2026) has not commenced. No version bump, no content change needed.'
WHERE issue_id = 150 AND instrument_id = 'RRC_PLANNING_SCHEME_2015';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
