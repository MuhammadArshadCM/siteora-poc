import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #102 (Logan): user checked the council's current ePlan and confirmed the currently
 * selected version is "Version 9.2 (with TLPI No. 1/2024)", effective 01 Jul 2025. This project's own Logan
 * instrument_version is already labelled "Version 9.2 (printed with TLPI No. 1/2024 - flood)" with the same
 * effective_from date (2025-07-01) -- i.e. TLPI No. 1/2024 has not expired away, it has been folded into the
 * consolidated current version, and this project's 9.3.2 flood provisions are already sourced from that
 * current, TLPI-inclusive text. No drift, no content change needed.
 */
export class CloseLoganTLPIIssue1700005160000 implements MigrationInterface {
  name = "CloseLoganTLPIIssue1700005160000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-17',
  description = 'RESOLVED 2026-11-17: user checked the council''s current ePlan and confirmed the currently-selected version is "Version 9.2 (with TLPI No. 1/2024)", effective 01 Jul 2025. This project''s own Logan instrument_version (LCC_PLANNING_SCHEME_2015@2025-07-01) is already labelled "Version 9.2 (printed with TLPI No. 1/2024 - flood)" with the same effective date -- TLPI No. 1/2024 has not expired away, it has been folded into the consolidated current version, and this project''s 9.3.2 flood provisions are already sourced from that current, TLPI-inclusive text. No drift, no content change needed.'
WHERE issue_id = 102 AND instrument_id = 'LCC_PLANNING_SCHEME_2015';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
