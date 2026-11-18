import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Closes open_issues #21, using a current document the user supplied directly from Brisbane's eplan tool
 * (PC100_SpringHill_115_03-Nov-2026.pdf, an 11-page export of section 7.2.19.5 "Spring Hill neighbourhood
 * plan code" shown with the pending "Fortitude Valley Sustainable Growth Precinct Plan" amendment overlay).
 *
 * The document shows old/struck-through vs new/underlined pairs only for the two precinct/special-boundary
 * MAPS (Figures a and b) -- every other section (the Application, Purpose, all of Table 7.2.19.5.3.A's PO1
 * through PO9, Table 7.2.19.5.3.B Maximum building height, Table 7.2.19.5.3.C Urban context report, and
 * Table 7.2.19.5.3.D Boundary setback requirements) appears only once, confirming that content is current
 * and NOT touched by the pending amendment (which only redraws precinct boundaries).
 *
 * Findings:
 * - Table 7.2.19.5.3.D "Boundary setback requirements" (the specific table this issue was chasing) sets
 *   figures for "Street building" (0m front, 0m side/rear, 3m on a special boundary) and "Tower" (3m-to-
 *   balcony/6m-to-wall front, 6m side/rear, 9m on a special boundary) -- multi-storey commercial/mixed-use
 *   building typologies, not Class 10a-relevant at all.
 * - Critically, ALL of Spring Hill's own assessment criteria (PO1 through PO9, and therefore every table
 *   they reference including Table D) are explicitly scoped by their own header to apply only "If in the
 *   Principal centre zone, District centre zone, Mixed use zone, or Community facilities zone" -- never the
 *   Low-medium density residential or Character residential zones, which is where an actual dwelling
 *   house/Class 10a structure within Spring Hill's boundary would sit. Those residential zones are
 *   mentioned only in the plan's general "overall outcomes" narrative (section 7.2.19.5.2), never given
 *   their own PO/AO benchmark anywhere in this code.
 * - PO1/AO1 (the item Table 1.6.1 cites for Class 10 building height) is, as already suspected from
 *   Fortitude Valley's equivalent, a generic storeys/height-table reference (Table 7.2.19.5.3.B, up to 30
 *   storeys depending on precinct/site size) -- trivially satisfied by any real Class 10a structure's
 *   height and so never practically constraining.
 * - Noted but not material: Table 1.6.1's own citation ("PO7 and AO7.2") does not exactly match this
 *   document's PO7 (which has only "AO7: No acceptable outcome is prescribed", no AO7.2) -- a minor
 *   citation-drift artifact, not examined further since PO7 sits within the same commercial-zone-only scope
 *   either way and does not change the conclusion.
 *
 * Combined with the already-closed Fortitude Valley finding and the already well-corroborated West
 * End-Woolloongabba finding (both from earlier this session), all three neighbourhood plans named in this
 * issue are now resolved: none sets Class 10a-relevant siting content for land where a dwelling house
 * would actually be Class 10a-relevant.
 */
export class CloseBrisbaneNeighbourhoodPlanIssueSpringHillDocument1700006300000 implements MigrationInterface {
  name = "CloseBrisbaneNeighbourhoodPlanIssueSpringHillDocument1700006300000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-18', description =
  'RESOLVED 2026-11-18: user supplied a current document from Brisbane''s eplan tool (section 7.2.19.5 Spring Hill neighbourhood plan code, shown with the pending Fortitude Valley Sustainable Growth Precinct Plan amendment overlay -- old/struck-through vs new/underlined pairs appear only for the two precinct/special-boundary maps; every other section, including all of Table 7.2.19.5.3.A''s PO1-PO9 and Tables B/C/D, appears once, confirming that content is current and untouched by the pending amendment). Table 7.2.19.5.3.D "Boundary setback requirements" (the specific table this issue was chasing) sets figures for "Street building" (0m front, 0m side/rear, 3m on a special boundary) and "Tower" (3m-to-balcony/6m-to-wall front, 6m side/rear, 9m on a special boundary) -- multi-storey commercial/mixed-use building typologies, not Class 10a-relevant. Critically, ALL of Spring Hill''s own assessment criteria (PO1-PO9, and every table they reference) are explicitly scoped to apply only "If in the Principal centre zone, District centre zone, Mixed use zone, or Community facilities zone" -- never the Low-medium density residential or Character residential zones, which is where an actual dwelling house/Class 10a structure within Spring Hill''s boundary would sit (those zones appear only in the plan''s general "overall outcomes" narrative, never given their own PO/AO benchmark). PO1/AO1 (cited by Table 1.6.1 for Class 10 building height) is a generic storeys/height-table reference (up to 30 storeys depending on precinct/site size), trivially satisfied by any real Class 10a structure and so never practically constraining -- the same pattern already confirmed for Fortitude Valley. Combined with the already-resolved Fortitude Valley finding and the already well-corroborated West End-Woolloongabba finding (both from earlier this session), all three neighbourhood plans named in this issue are now resolved: none sets Class 10a-relevant siting content for land where a dwelling house would actually be Class 10a-relevant. (Noted, not material: Table 1.6.1''s own citation "PO7 and AO7.2" does not exactly match this document''s PO7, which has only "AO7: No acceptable outcome is prescribed" -- a minor citation-drift artifact that does not change the conclusion, since PO7 sits within the same commercial-zone-only scope either way.)'
WHERE issue_id = 21 AND instrument_id = 'BCC_CITY_PLAN_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
