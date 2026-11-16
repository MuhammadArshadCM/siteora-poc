import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Closes stale bookkeeping: open_issues #175 asked for a bushfire-prone-area-designation rule to be built
 * for Moreton Bay's V9 zones, "pending the zone list and overlay trigger values confirmed against the live
 * overlay map." That rule (CMB.C.BUSHFIRE_PRONE_AREA_DESIGNATION) was already built and is ACTIVE, scoped to
 * CMB:GENERAL_RESIDENTIAL and CMB:TOWNSHIP, gated on the CMB:OV:BUSHFIRE_HAZARD overlay layer -- exactly what
 * the issue asked for. The issue row itself was simply never closed out when the rule was built. No new
 * research needed; this is a pure data-hygiene fix found while triaging open_issues.
 */
export class CloseMoretonBayBushfireDesignationIssue1700004380000 implements MigrationInterface {
  name = "CloseMoretonBayBushfireDesignationIssue1700004380000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16 (stale bookkeeping found during open_issues triage): CMB.C.BUSHFIRE_PRONE_AREA_DESIGNATION was already built and activated (2026-11-02) to address exactly this -- scoped to CMB:GENERAL_RESIDENTIAL and CMB:TOWNSHIP, gated on the CMB:OV:BUSHFIRE_HAZARD overlay layer (poc/site_layers.json), surfaced for manual review (AS 3959 BAL rating is not something this tool calculates). Centre and Industry zones are deliberately out of scope (no dwelling-house Class 10a scenario is curated for either), per the rule''s own interpretation_notes -- not an oversight. This issue row was simply never closed when the rule was built; no new research was needed to close it.'
WHERE issue_id = 175 AND instrument_id = 'MBRC_PLANNING_SCHEME_2016';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
