import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Further narrows open_issues #21's remaining West End-Woolloongabba item with stronger corroborating
 * evidence, found after another attempt at a current Brisbane document (the live eplan and the
 * docs.brisbane.qld.gov.au historical mirror both remain dead ends, per migration 1700006180000).
 *
 * Found "Major amendment package L" schedule of amendments (brisbane.qld.gov.au, printed 28/10/2025 --
 * roughly a year newer than the already-held 2016 snapshot, and itself amending the Traditional building
 * character overlay code's small-lot prescribed-accepted-development table). That table's own redline
 * text includes, UNCHANGED by this amendment: "iii. if associated with a dwelling house in the West End
 * estate precinct of the West End--Woolloongabba district neighbourhood plan, where also complying with
 * the requirements in AO13.2, AO13.3 and AO13.4 in that neighbourhood plan code" -- the exact same
 * AO13.2/13.3/13.4 cross-reference already held from the 2016 snapshot, now independently confirmed
 * current as of October 2025 via a DIFFERENT part of the scheme (a different overlay code) that cites it.
 * The same document's own copy of Table 1.6.1 item 6 also still shows "West End--Woolloongabba district
 * neighbourhood plan code | PO1 and AO1 | PO6, AO6.1 and AO6.2" -- the identical citation already held.
 *
 * This is stronger corroboration than a merely-unchanged citation number (which is all the previous pass
 * had): an entirely separate code, amended as recently as October 2025, still relies on an unchanged
 * numbered cross-reference INTO this NP code's own body text, which would be a drafting error if that body
 * text had since been renumbered. Raises confidence from "plausible" to "well-corroborated, though not
 * verbatim-proven" that the already-held 2016-snapshot content for West End-Woolloongabba (PO6/AO6.1-AO6.2
 * scoped to the non-HDR West End estate heritage precinct) remains representative of its current wording.
 *
 * No equivalent corroboration was found for Spring Hill's Table 7.2.19.5.3.D "Boundary setback
 * requirements" -- genuinely still unconfirmed, and the harder of the two remaining items.
 */
export class FurtherNarrowBrisbaneWestEndWoolloongabbaEvidence1700006240000 implements MigrationInterface {
  name = "FurtherNarrowBrisbaneWestEndWoolloongabbaEvidence1700006240000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET description =
  'NARROWED 2026-11-18 (further): found "Major amendment package L" schedule of amendments (brisbane.qld.gov.au, printed 28/10/2025) -- roughly a year newer than the already-held 2016 snapshot, itself amending the Traditional building character overlay code''s small-lot prescribed-accepted-development table. That table''s own redline text includes, UNCHANGED by this amendment: "iii. if associated with a dwelling house in the West End estate precinct of the West End--Woolloongabba district neighbourhood plan, where also complying with the requirements in AO13.2, AO13.3 and AO13.4 in that neighbourhood plan code" -- the exact same AO13.2/13.3/13.4 cross-reference already held from the 2016 snapshot, now independently confirmed current as of October 2025 via a DIFFERENT, separately-amended part of the scheme that relies on it. The same document''s own copy of Table 1.6.1 item 6 also still shows the identical citation already held ("PO1 and AO1 | PO6, AO6.1 and AO6.2"). This is stronger evidence than a merely-unchanged citation number: a different code, amended as recently as October 2025, still relies on an unrenumbered cross-reference into this NP code''s own body text -- which would itself be a drafting error if that body text had since been renumbered. Raises confidence from "plausible" to "well-corroborated, though not verbatim-proven" that the already-held 2016-snapshot content for West End-Woolloongabba (PO6/AO6.1-AO6.2, scoped to the non-HDR West End estate heritage precinct, not HDR land) remains representative of its current wording. No equivalent corroboration found for Spring Hill''s Table 7.2.19.5.3.D "Boundary setback requirements" -- genuinely still unconfirmed, and the harder of the two remaining items; still needs either a current-version document or a working live-fetch path into cityplan.brisbane.qld.gov.au.'
WHERE issue_id = 21 AND instrument_id = 'BCC_CITY_PLAN_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
