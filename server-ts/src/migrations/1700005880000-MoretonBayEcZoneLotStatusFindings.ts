import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Follows up on open_issues #62 (Moreton Bay Emerging community zone's remaining setback/BTB/site-cover
 * tables, per precinct) using the already-held current Version 9 full-plan PDF (research/sources/
 * MORETON_BAY/moreton_bay_planning_scheme_v9.pdf).
 *
 * Fetched/read in full: Table 6.2.3.1.1 (Interim precinct), 6.2.3.2.1.1 (Transition, developable lot),
 * 6.2.3.2.2.1 + 6.2.3.2.2.3/.4 (Transition, developed lot: Setbacks + Built to boundary walls), and
 * 6.2.3.3.1-3.6 (Morayfield South precinct, both developable and developed lot, including its Next
 * generation neighbourhood and Urban neighbourhood sub-precincts).
 *
 * Found, with high confidence (clean, repeated, cross-checked text):
 * - A single zone-wide "general" setback (RAD3/RAD4 depending on table: road frontage 6m minimum, side and
 *   rear 4.5m minimum, "unless specified elsewhere in the zone code") is IDENTICAL, word for word, across
 *   the Interim precinct, the Transition precinct's developABLE-lot table, and the Morayfield South
 *   precinct's developABLE-lot table.
 * - A different, height-tiered Setbacks (Residential uses) table applies on a developED lot: Side 1.5m
 *   (wall <4.5m) / 2m (4.5m-8.5m) / graduated above 8.5m; Rear 1.5m / 2m / 5m. This table is numerically
 *   IDENTICAL between the Transition precinct's developed-lot table (6.2.3.2.2.3) and Morayfield South's
 *   Next generation neighbourhood sub-precinct (6.2.3.3.3). Morayfield South's Urban neighbourhood
 *   sub-precinct (6.2.3.3.4) has its own, different (denser) figures, but the PDF's complex merged-header
 *   table layout could not be extracted with confidence this pass -- genuinely still open.
 * - Both developed-lot BTB provisions state, verbatim: "Buildings (excluding class 10 buildings and
 *   structures) ensure that built to boundary walls are: ..." -- Class 10 buildings/structures are
 *   explicitly excluded from the built-to-boundary wall option in every developed-lot precinct checked.
 *
 * Critical finding (a real correctness issue in an already-live rule, not just new research): the
 * existing CMB.C.EC_OUTBUILDING_SIZE rule's interpretation_notes claimed the lot-size-banded roofed-area
 * table (50/70/80/150 m2) was "confirmed identical in every precinct/lot-type checked", explicitly
 * including "Transition developed". Re-reading Transition precinct's developed-lot table (6.2.3.2.2.1)
 * directly: that table has NO such roofed-area-by-lot-size clause at all (RAD45 is literally marked
 * "N/A - This RAD has been deleted", and "Use specific requirements" goes straight to "Home based
 * business"). A whole-document search for the table's own header text ("Size of lot" / "Max. Roofed
 * Area") confirms it appears only in the Interim precinct, the Transition precinct's developABLE-lot
 * table, and the Morayfield South precinct's developABLE-lot table -- never in either precinct's
 * developED-lot table, where "Site cover (Residential uses)" (a percentage, a different mechanism
 * entirely) governs overall building coverage instead. This project has no fact or precinct boundary
 * distinguishing a "developable" from a "developed" lot within the Transition/Morayfield South precincts
 * of the Emerging community zone (confirmed: only 2 precinct_ids exist under CMB:EMERGING_COMMUNITY,
 * both from the unrelated Dwelling house code's building-height-overlay precinct split, not from the
 * 6.2.3 zone code's own precinct structure) -- so CMB.C.EC_OUTBUILDING_SIZE, scoped to the whole zone,
 * may currently misapply the developable-lot roofed-area bands on a developed lot, where the (as yet
 * unencoded) site-cover percentage standard should govern instead. Correcting the rule's own
 * interpretation_notes to state this accurately rather than leave the false "confirmed identical" claim
 * in place; the rule's scope is left as-is (zone-wide) since narrowing it would also incorrectly drop the
 * correct, much more common Interim-precinct case, and no distinguishing fact/precinct currently exists
 * to split the two.
 */
export class MoretonBayEcZoneLotStatusFindings1700005880000 implements MigrationInterface {
  name = "MoretonBayEcZoneLotStatusFindings1700005880000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE rule_versions SET interpretation_notes =
  'RAD48(a) in the Interim precinct (and its PO57 assessable-development mirror); the same lot-size-banded roofed-area table also appears verbatim in the Transition precinct''s DEVELOPABLE-lot table and the Morayfield South precinct''s DEVELOPABLE-lot table (both as their own RAD48(a)/PO60-equivalent). CORRECTED 2026-11-17 (was: "Confirmed identical in every precinct/lot-type checked"): this roofed-area-by-lot-size standard does NOT appear in either the Transition or Morayfield South precincts'' DEVELOPED-lot tables -- a whole-document check confirms the table''s own header text ("Size of lot" / "Max. Roofed Area") is absent from both; those tables instead use a "Site cover (Residential uses)" PERCENTAGE standard, a different mechanism, not yet encoded. This project has no fact or precinct boundary distinguishing a "developable" from a "developed" lot within the Transition/Morayfield South precincts of this zone, so this rule (scoped zone-wide) may currently misapply these roofed-area bands on a developed lot, where the site-cover percentage standard should govern instead. See open_issues #62 for full detail.'
WHERE rule_version_id = 'CMB.C.EC_OUTBUILDING_SIZE@2026-09-11';

UPDATE open_issues SET description =
  'NARROWED 2026-11-17: fetched and read in full Table 6.2.3.1.1 (Interim precinct), 6.2.3.2.1.1 (Transition developable lot), 6.2.3.2.2.1 + .3/.4 (Transition developed lot: Setbacks + Built to boundary walls), and 6.2.3.3.1-3.6 (Morayfield South precinct, both lot types, both sub-precincts) from the current Version 9 PDF. Confirmed: (1) a single zone-wide general setback (road frontage 6m minimum, side/rear 4.5m minimum, "unless specified elsewhere in the zone code") is identical across the Interim precinct and both precincts'' DEVELOPABLE-lot tables; (2) a height-tiered Setbacks (Residential uses) table applies on a DEVELOPED lot (Side 1.5m under 4.5m wall height / 2m from 4.5-8.5m / graduated above; Rear 1.5m / 2m / 5m), numerically identical between the Transition precinct''s developed-lot table and Morayfield South''s Next generation neighbourhood sub-precinct -- but the Urban neighbourhood sub-precinct''s own (denser) figures could not be extracted with confidence from the PDF''s complex merged-header table layout, and remain genuinely unconfirmed; (3) both developed-lot precincts'' built-to-boundary wall provisions explicitly exclude "class 10 buildings and structures" from the BTB wall option, verbatim -- the same open legal question already flagged for the Township zone (open_issues #75, re the QDC MP1.2 A2(d) built-to-boundary concession) applies here too, now with stronger textual support that Moreton Bay deliberately excludes Class 10 from local BTB provisions where it addresses the topic at all. CRITICALLY: also discovered and corrected a real citation/overclaim error in the already-live CMB.C.EC_OUTBUILDING_SIZE rule''s interpretation_notes (see its own updated notes) -- the lot-size-banded roofed-area table it encodes does NOT exist in either precinct''s developed-lot table (Site cover % governs there instead), and this project has no fact/precinct distinguishing developable from developed lots in Transition/Morayfield South to correctly split this. Genuinely still open: Morayfield South Urban neighbourhood sub-precinct''s own setback figures; the developed-lot Site cover % tables (found but not yet encoded); and -- the deeper architectural gap -- no way for this engine to determine whether a Transition/Morayfield South EC-zone lot is currently "developable" or "developed", which is the actual precondition for choosing between the general 4.5m setback and the tiered 1.5m/2m setback, or between the roofed-area bands and the site-cover percentage.'
WHERE issue_id = 62 AND instrument_id = 'MBRC_PLANNING_SCHEME_2016';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
