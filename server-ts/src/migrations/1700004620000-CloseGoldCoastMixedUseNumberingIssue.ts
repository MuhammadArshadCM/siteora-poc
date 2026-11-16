import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #168 (Gold Coast Mixed use zone code numbering conflict): user supplied the current,
 * clean (non-draft) PDF of section 6.2.19 "Mixed use zone code" directly from the council's eplan, City Plan
 * v14 (08-Sep-2026 export). Confirms:
 *
 *   1. The current in-force section number IS 6.2.19 -- there is no real conflict with the Rural zone code's
 *      6.2.20 (already held, sourced from the live eplan). The earlier "Our City Our Plan" tracked-changes
 *      amendment PDF (marked "FOR MINISTERIAL APPROVAL") that appeared to clash was simply an unreliable,
 *      not-yet-adopted draft source -- correctly left unused.
 *   2. The Mixed use zone code has NO dwelling-house or Class 10a-specific content at all. Its Required
 *      Outcomes (RO1-RO8) set generic multi-storey BUILDING setbacks/site cover/height (frontage/side/rear by
 *      storeys, tower site cover, podium heights) for the zone's intended apartment-over-retail / mixed-use
 *      built form -- there is no "dwelling house" or "outbuilding" mentioned anywhere in the 13-page code.
 *      This is the SAME scope question already tracked by open_issues #36 (Gold Coast Rural/Emerging
 *      Community: "if sheds/garages/carports are 'buildings' under Table 1.5-1, do the zone's general building
 *      setbacks displace the QDC MP1.2 Class 10a boundary allowances?"), now also true of Mixed use -- not a
 *      new, separate ambiguity to track twice, and not something to invent Class 10a rules for where the
 *      source text has none. No rule built: there is nothing Class-10a-specific in this zone code to encode.
 */
export class CloseGoldCoastMixedUseNumberingIssue1700004620000 implements MigrationInterface {
  name = "CloseGoldCoastMixedUseNumberingIssue1700004620000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: user supplied the current, clean (non-draft) section 6.2.19 "Mixed use zone code" PDF directly from the council''s eplan (City Plan v14, 08-Sep-2026 export). Confirms the current in-force section number IS 6.2.19 -- there was never a real conflict with the Rural zone code''s 6.2.20 (already correctly held); the earlier "Our City Our Plan" tracked-changes PDF that appeared to clash was simply an unreliable, not-yet-adopted draft source. More importantly: the Mixed use zone code has NO dwelling-house or Class 10a-specific content at all -- its Required Outcomes (RO1-RO8) set only generic multi-storey BUILDING setbacks/site cover/height (frontage/side/rear by storeys, tower site cover, podium heights) for the zone''s apartment-over-retail built form; "dwelling house" and "outbuilding" are not mentioned anywhere in the 13-page code. This is the same scope question already tracked by open_issues #36 for Rural/Emerging Community (whether sheds/garages/carports count as "buildings" under Table 1.5-1, displacing QDC MP1.2 Class 10a allowances), now also true of Mixed use -- not a new ambiguity to track separately, and no rule was invented here since the source text has nothing Class-10a-specific to encode.'
WHERE issue_id = 168 AND instrument_id = 'CGC_CITY_PLAN';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
