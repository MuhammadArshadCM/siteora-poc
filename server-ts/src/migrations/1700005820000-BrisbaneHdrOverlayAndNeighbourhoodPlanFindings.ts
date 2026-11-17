import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Closes open_issues #19 and narrows #21 for Brisbane, following up on the user's request to try the
 * Brisbane Neighbourhood Plan (NP) documents.
 *
 * #19: resolved purely by re-reading text already held (no fetch needed) -- Table 5.5.4's own note is
 * unconditional: "All dwelling houses in the High density residential zone may become assessable
 * development as the Dwelling house character overlay applies to all land within this zone." The scheme
 * asserts universal overlay coverage of the HDR zone itself, in its own words -- a lot-by-lot Schedule 2
 * map check would only matter if the scheme's own text were silent or conditional, which it is not.
 *
 * #21 (narrowed, not closed): fetched and read 2016/2020-era snapshots of the West End-Woolloongabba,
 * Fortitude Valley, and Spring Hill neighbourhood plan codes from Brisbane's public docs.brisbane.qld.gov.au
 * file mirror (the live current eplan at cityplan.brisbane.qld.gov.au returns HTTP 403 to automated
 * fetches). Findings, with an important caveat discovered along the way:
 * - West End-Woolloongabba's PO6/AO6.1-AO6.2 (2016 snapshot) was a dwelling-house front-elevation/ceiling
 *   height provision scoped only to the West End estate precinct (NPP-001) -- a pre-1946 heritage/character
 *   area requiring "1 dwelling house ... on each lot" (AO4.2) -- not the Mater Hill precinct (where any
 *   higher-density land in this NP would sit). On its face this is a non-HDR character-precinct provision.
 * - Fortitude Valley's PO1/AO1.2 (2016 snapshot) was a generic plan-area-wide height/storeys table intended
 *   for towers/mixed-use buildings; the plan's own overall outcomes describe an entirely commercial/
 *   entertainment/multi-unit character with no mention of standard detached dwelling houses as an
 *   anticipated use anywhere in its precincts.
 * - Spring Hill's CURRENT Table 1.6.1 citation (PO1/AO1, PO7/AO7.2) does not match the 2020 snapshot's own
 *   PO7/AO7 ("landscape buffer ... No acceptable outcome is prescribed") -- proving the plan has been
 *   renumbered at least once since 2020. This means the 2016 West End-Woolloongabba/Fortitude Valley
 *   snapshots could likewise be stale relative to the current (v37.00/2026) numbering, and their content
 *   cannot be treated as confirmed-current on this evidence alone.
 * Genuinely still open: the exact CURRENT text of all three NP codes' cited provisions needs either a
 * current-version document (the same way the user has supplied current documents for other councils this
 * session) or a working live-fetch path into cityplan.brisbane.qld.gov.au, neither of which was available
 * this pass.
 */
export class BrisbaneHdrOverlayAndNeighbourhoodPlanFindings1700005820000 implements MigrationInterface {
  name = "BrisbaneHdrOverlayAndNeighbourhoodPlanFindings1700005820000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held verbatim text of Table 5.5.4''s own note (no fetch needed): "All dwelling houses in the High density residential zone may become assessable development as the Dwelling house character overlay applies to all land within this zone." This is the scheme''s own unconditional, explicit assertion of universal overlay coverage within the HDR zone -- not a derived or inferred claim needing independent lot-by-lot verification against the Schedule 2 overlay map. A lot-by-lot GIS check would only be necessary if the scheme''s own text were silent, qualified, or ambiguous about coverage, which it is not: the scheme states "all land within this zone" without exception. If a lot were ever found to sit outside the mapped overlay despite this statement, that would be the scheme''s own internal drafting inconsistency, not a gap in this project''s extraction -- and this project''s working convention throughout (established for other councils'' overlay-to-fact mappings this session) is to trust a scheme''s own stated provisions text as authoritative. No fix needed.'
WHERE issue_id = 19 AND instrument_id = 'BCC_CITY_PLAN_2014';

UPDATE open_issues SET description =
  'NARROWED 2026-11-17: fetched and read 2016/2020-era snapshots of the West End-Woolloongabba, Fortitude Valley, and Spring Hill neighbourhood plan codes from Brisbane''s public docs.brisbane.qld.gov.au file mirror (the live current eplan at cityplan.brisbane.qld.gov.au returns HTTP 403 to automated fetches). Findings, with an important caveat: West End-Woolloongabba''s PO6/AO6.1-AO6.2 (2016 snapshot) was a dwelling-house front-elevation/ceiling-height provision scoped only to the West End estate precinct (NPP-001) -- a pre-1946 heritage/character area requiring "1 dwelling house ... on each lot" (AO4.2) -- not the Mater Hill precinct where any higher-density land in this NP would sit; on its face a non-HDR character-precinct provision. Fortitude Valley''s PO1/AO1.2 (2016 snapshot) was a generic plan-area-wide height/storeys table intended for towers/mixed-use buildings, in a plan area whose own overall outcomes describe an entirely commercial/entertainment/multi-unit character with no mention of standard detached dwelling houses as an anticipated use anywhere in its precincts. However: Spring Hill''s CURRENT Table 1.6.1 citation (PO1/AO1, PO7/AO7.2) does not match the 2020 snapshot''s own PO7/AO7 ("landscape buffer ... No acceptable outcome is prescribed") -- proving this plan has been renumbered at least once since 2020. That means the 2016 West End-Woolloongabba/Fortitude Valley snapshots could likewise be stale relative to the current (v37.00/2026) numbering cited in Table 1.6.1, so their content is informative but not confirmed-current. Genuinely still open: the exact current text of all three NP codes'' cited provisions needs either a current-version document (as the user has supplied for other councils this session) or a working live-fetch path into cityplan.brisbane.qld.gov.au -- neither was available this pass.'
WHERE issue_id = 21 AND instrument_id = 'BCC_CITY_PLAN_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
