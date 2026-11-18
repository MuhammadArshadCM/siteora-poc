import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Further narrows open_issues #21 using current (v37.00/2026) Brisbane documents, found after the live
 * eplan (cityplan.brisbane.qld.gov.au) kept returning HTTP 403 and the public docs.brisbane.qld.gov.au
 * mirror turned out to stop at v13 (2018/2019) -- confirmed via the council's own "adopted city plan
 * amendments" page, which lists docs.brisbane.qld.gov.au links only up to v13 and otherwise points to the
 * blocked eplan for anything current.
 *
 * Found two usable current documents on brisbane.qld.gov.au (not the blocked subdomains):
 * - "schedule-of-amendments-citywide-amendment-more-homes-sooner-lm-density-residential-design-v37-2026.pdf"
 *   -- part of the adopted v37.00/2026 package (effective 18 September 2026). Its own copy of Table 1.6.1
 *   item 6 confirms the citations this project already holds are current and UNCHANGED by this amendment:
 *   Fortitude Valley Neighbourhood Plan Code "PO1 and AO1.2"; Spring Hill Neighbourhood Plan Code "PO1 and
 *   AO1" / "PO7 and AO7.2"; West End-Woolloongabba district neighbourhood plan code "PO1 and AO1" / "PO6,
 *   AO6.1 and AO6.2". (Only the Dwelling house/Dwelling house (small lot) code citations in that table
 *   changed, cascading from the LMR package's own renumbering -- the three NP codes' own citations did not.)
 * - "schedule-of-amendments-text-draft-fortitude-valley-neighbourhood-plan.pdf" (the draft Fortitude Valley
 *   Sustainable Growth Precinct Plan, public notice 13 Nov - 18 Dec 2026, not yet adopted) -- shows Fortitude
 *   Valley's current PO1/AO1.2 content directly, via tracked-changes redline. The provision being renumbered
 *   (old AO1.2, soon AO2.2 or similar) is content-UNCHANGED: "Development complies with the number of
 *   storeys and building height in Table 7.2.6.4.3.B" -- confirming the already-held 2016-snapshot reading
 *   (a generic, plan-area-wide height/storeys table, not Class 10a-specific) is still accurate today.
 *
 * For Spring Hill and West End-Woolloongabba, no current full-text source could be reached (their own NP
 * code sections were not touched by either document above, so neither shows their body text) -- but since
 * neither NP's own Table 1.6.1 citation number has changed across any current document checked this pass
 * (while Spring Hill's citation WAS confirmably renumbered at some earlier point, between the already-held
 * 2020 snapshot and today), the citations now in force are the SAME ones already held, raising confidence
 * (not proof) that the 2016-snapshot content already read for West End-Woolloongabba (PO6/AO6.1-AO6.2,
 * scoped to the non-HDR West End estate heritage precinct) remains representative. Spring Hill's own
 * Table 7.2.19.5.3.D "Boundary setback requirements" (confirmed by title to exist and be setback-relevant)
 * could not be retrieved in full from any reachable current source -- genuinely still open.
 */
export class NarrowBrisbaneNeighbourhoodPlanIssueWithCurrentDocs1700006180000 implements MigrationInterface {
  name = "NarrowBrisbaneNeighbourhoodPlanIssueWithCurrentDocs1700006180000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET description =
  'NARROWED 2026-11-18: found two usable current Brisbane documents on brisbane.qld.gov.au (the live eplan at cityplan.brisbane.qld.gov.au still 403s automated fetches; the public docs.brisbane.qld.gov.au mirror, confirmed via the council''s own "adopted city plan amendments" page, stops at v13/2018-2019 and was never updated further). (1) The adopted v37.00/2026 "More Homes, Sooner - Low-medium density residential design" amendment schedule (effective 18 September 2026) includes its own copy of Table 1.6.1 item 6, confirming the citations already held are CURRENT and UNCHANGED by this amendment: Fortitude Valley "PO1 and AO1.2"; Spring Hill "PO1 and AO1" / "PO7 and AO7.2"; West End-Woolloongabba "PO1 and AO1" / "PO6, AO6.1 and AO6.2" (only the Dwelling house/Dwelling house (small lot) code citations in that table changed). (2) The draft Fortitude Valley Sustainable Growth Precinct Plan schedule of amendments (public notice 13 Nov - 18 Dec 2026, not yet adopted) shows Fortitude Valley''s current PO1/AO1.2 content directly via tracked-changes redline: the provision being renumbered is content-UNCHANGED -- "Development complies with the number of storeys and building height in Table 7.2.6.4.3.B" -- confirming the already-held 2016-snapshot reading (a generic, plan-area-wide height/storeys table, not Class 10a-specific) remains accurate today. RESOLVED for Fortitude Valley: no Class 10a-specific siting content, confirmed current. Genuinely still open: Spring Hill''s own Table 7.2.19.5.3.D "Boundary setback requirements" (confirmed by title to exist and likely be setback-relevant) and West End-Woolloongabba''s PO6/AO6.1-AO6.2 full current text could not be retrieved from any reachable current source this pass (neither NP''s own body-text section was touched by either document found) -- though since neither citation NUMBER has changed in any current document checked (while Spring Hill''s own citation WAS confirmably renumbered at some earlier point, between the already-held 2020 snapshot and today), this raises confidence that the already-read 2016-snapshot content for West End-Woolloongabba (scoped to the non-HDR West End estate heritage precinct) remains representative, without proving it. Needs either a current-version document (as the user has supplied for other councils this session) or a working live-fetch path into cityplan.brisbane.qld.gov.au.'
WHERE issue_id = 21 AND instrument_id = 'BCC_CITY_PLAN_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
