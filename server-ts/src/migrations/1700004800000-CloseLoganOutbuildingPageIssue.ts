import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #105 (Logan): user supplied the council's "Domestic outbuildings (sheds, carports)"
 * page content (live URL section 4 of
 * www.logan.qld.gov.au/planning-and-building/planning-and-development/development-in-logan/residential-projects,
 * fetched 2026-11-16, since the originally-tried URL 404'd).
 *
 * The page's content (150m2 single-outbuilding cap; up to 300m2 combined with 5.5m height and 6m/20m side-rear
 * clearances depending on zone; no separate garage height treatment) matches EXACTLY what this project already
 * holds and has ACTIVE (LCC.C.OUTBUILDING_FLOOR_AREA_150, LCC.C.LARGE_OUTBUILDING_MAX_300,
 * LCC.C.LARGE_OUTBUILDING_HEIGHT_5_5, LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M, LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M)
 * -- sourced directly from the Dual Occupancy and Dwelling House Code (9.3.2, Table 9.3.2.3.1 AO7.1/Table
 * 9.3.2.3.2), the authoritative planning scheme text, not the web page. The web page was only ever a
 * secondary restatement of this same figure (the original researcher's own note on the draft rule already
 * said as much: "Council web page summary (search snippet) repeats this 150m2 rule"). No new content needed;
 * closing with this confirmation.
 */
export class CloseLoganOutbuildingPageIssue1700004800000 implements MigrationInterface {
  name = "CloseLoganOutbuildingPageIssue1700004800000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: original URL had moved; user found and fetched the live page (section 4, "Domestic outbuildings (sheds, carports)", www.logan.qld.gov.au/planning-and-building/planning-and-development/development-in-logan/residential-projects). Its content (150m2 single cap; up to 300m2 combined with 5.5m height and 6m/20m side-rear clearances by zone; garages get no separate treatment, only named as an example) matches exactly what this project already has ACTIVE (LCC.C.OUTBUILDING_FLOOR_AREA_150, LCC.C.LARGE_OUTBUILDING_MAX_300, LCC.C.LARGE_OUTBUILDING_HEIGHT_5_5, LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M, LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M), sourced directly from the Dual Occupancy and Dwelling House Code (the authoritative text, not the web page) -- confirming the web page was only ever a restatement, never a source of anything new. No new content needed.'
WHERE issue_id = 105 AND instrument_id = 'LCC_PLANNING_SCHEME_2015';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
