import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #125 (Burke): user supplied the scheme's own "Citation and commencement" clause
 * verbatim -- "This planning scheme may be cited as Burke Shire Planning Scheme 2020 ... Government Gazette
 * No.20 on 31 January 2020 ... commencement date ... was 7 February 2020." It names only a citation and a
 * single commencement date, no amendment history or version number of any kind. This confirms the original
 * premise directly from the document's own front matter: Burke Shire genuinely does not publish a
 * version/amendment register in this scheme, consistent with "no version/amendment number is published."
 * (This confirms the document's own silence on amendments, not an independent check of the council's website
 * for any separately-gazetted administrative amendment since 2020 -- a much lower-likelihood residual risk
 * for a small-shire scheme with no visible amendment-tracking apparatus at all.)
 */
export class CloseBurkeVersionIssue1700005220000 implements MigrationInterface {
  name = "CloseBurkeVersionIssue1700005220000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-17',
  description = 'RESOLVED 2026-11-17: user supplied the scheme''s own "Citation and commencement" clause verbatim -- it names only the citation, the Government Gazette notice (No.20, 31 January 2020) and the commencement date (7 February 2020), with no amendment history or version number anywhere in it. Confirms directly from the document''s own front matter that Burke Shire genuinely does not publish a version/amendment register in this scheme. No content change needed.'
WHERE issue_id = 125 AND instrument_id = 'BSC_PLANNING_SCHEME_2020';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
