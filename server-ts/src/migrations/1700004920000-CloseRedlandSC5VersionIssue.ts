import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #123 (Redland): user supplied the "Version 14, updated 23 September 2026, with changes
 * to SC5" PDF (full 523-page consolidated City Plan, freshly fetched from the live eplan).
 *
 * Confirmed directly from the primary document:
 *   - The version stays 14 -- every page header in this fresh download reads "Redland City Plan 2018 -
 *     Version 14", matching the filename. No version bump for this update.
 *   - Schedule 5 (SC5) is "Designation of premises for development" -- Table SC5.1, a register of specific
 *     real-property lots designated for STATE/LOCAL GOVERNMENT INFRASTRUCTURE (fire stations, law courts,
 *     emergency services facilities) under s42 of the Planning Act 2016, maintained per the Act's own
 *     requirement that Council update it whenever notified of a new/changed designation. Purely an
 *     administrative infrastructure-designation register -- no zone code, dwelling house or Class 10a content
 *     whatsoever.
 *   - Appendix 2's Table of Amendments (the main amendment history) does not list a separate "23 September
 *     2026" entry at all -- consistent with this being a routine administrative update to the s42 register
 *     (adding/editing a specific designated premises entry) rather than a formal planning scheme amendment,
 *     which is why it did not get its own version number or amendment-table row.
 *
 * No content in SC5 is reachable by, or relevant to, this tool's Class 10a siting scope. Closing with this
 * confirmation; no new content needed.
 */
export class CloseRedlandSC5VersionIssue1700004920000 implements MigrationInterface {
  name = "CloseRedlandSC5VersionIssue1700004920000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: user supplied the "Version 14, updated 23 September 2026, with changes to SC5" PDF (full consolidated City Plan, freshly fetched from the live eplan). Confirmed directly: the version stays 14 (every page header reads "Redland City Plan 2018 - Version 14", matching the filename -- no bump). Schedule 5 ("Designation of premises for development", Table SC5.1) is purely a register of specific lots designated for government infrastructure (fire stations, law courts, emergency services facilities) under s42 of the Planning Act 2016, maintained per the Act''s own requirement -- zero zone code, dwelling house or Class 10a content. Appendix 2''s Table of Amendments does not list a separate entry for this date, consistent with it being a routine administrative register update rather than a formal scheme amendment. No content in SC5 is reachable by this tool''s Class 10a scope; no new content needed.'
WHERE issue_id = 123 AND instrument_id = 'RCC_CITY_PLAN_2018';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
