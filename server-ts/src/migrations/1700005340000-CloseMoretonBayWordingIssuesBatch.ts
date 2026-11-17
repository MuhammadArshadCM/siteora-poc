import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves/narrows 4 Moreton Bay open_issues (#64, #75, #77, #82), all by re-reading text already held in
 * db/030_council_moreton_bay.sql (no new document needed).
 */
export class CloseMoretonBayWordingIssuesBatch1700005340000 implements MigrationInterface {
  name = "CloseMoretonBayWordingIssuesBatch1700005340000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held verbatim text (Table 6.2.11.1 RAD3 and RAD48, Rural residential zone code). RAD3''s own opening clause is "Unless otherwise specified elsewhere in this code, the minimum setbacks from a property boundary are as follows..." -- an explicit residual/fallback rule. RAD48''s own heading is "Setbacks (including domestic outbuildings) comply with the following..." -- a complete, self-contained setback schedule (road 6m; side/rear 1.5/2/4m by wall height) that explicitly covers dwelling houses AND their domestic outbuildings. RAD48 is exactly the "otherwise specified elsewhere" RAD3 defers to for that structure scope -- confirmed RAD3 does NOT also apply to dwelling houses or domestic outbuildings; RAD48 is the complete, displacing standard for them, and RAD3 applies only to other buildings/structures outside RAD48''s scope.'
WHERE issue_id = 64 AND instrument_id = 'MBRC_PLANNING_SCHEME_2016';

UPDATE open_issues SET description =
  'NARROWED 2026-11-17: re-read the already-held verbatim text (Table 6.2.12.3.1 RAD3, Township zone code). Confirmed exactly as stated: the table''s "Side" column is headed "To OMP and wall" with a single figure (Min 1.5m below 4.5m wall height, Min 2m at or above) applying equally to both the wall face and the outermost projection -- there is no separate, smaller OMP-only figure the way some other councils'' tables split "to wall" vs "to OMP". The table genuinely has no built-to-boundary (0m) row for Class 10a at all for either Side or Rear. What remains genuinely open (not resolved by text alone, and already correctly flagged this way in the existing curated rule CMB.C.TW_SIDE_SETBACK''s own interpretation_notes): whether QDC MP1.2''s own A2(d) built-to-boundary concession for Class 10a survives alongside this comprehensive local alternative provision, or is displaced by it since RAD3 comprehensively covers "side setback" as a topic without carving out a BTB exception. This is a genuine legal-interpretation question for a certifier/council, not a textual ambiguity -- left open.'
WHERE issue_id = 75 AND instrument_id = 'MBRC_PLANNING_SCHEME_2016';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held verbatim text (Table 6.2.10.1 RAD3, Rural zone code). RAD3''s own note, immediately following its "not located in a bushfire prone area" trigger, reads: "Note - Where located in a bushfire hazard area (see Overlay map - Bushfire hazard) a greater setback may be required." The scheme itself bridges the two terms by naming the specific overlay map to check ("Bushfire hazard") right where the "bushfire prone area" trigger is stated -- this is the scheme''s own explicit mapping, not a gap needing external research. This project already has the corresponding overlay configured (CMB:OV:BUSHFIRE_HAZARD, used by CMB.C.BUSHFIRE_PRONE_AREA_DESIGNATION built earlier this session) -- no fix needed, just confirmation that the carve-out maps to that overlay.'
WHERE issue_id = 77 AND instrument_id = 'MBRC_PLANNING_SCHEME_2016';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-confirmed this is a benign, inert field -- LDZ_DoesNotApply is always 0 across every record in the open-data layer, meaning it never actually triggers any different behaviour for any lot currently in the dataset. Whatever the council''s internal purpose for this undocumented field is, it has zero practical effect on zone determination as the data currently stands. No fix needed.'
WHERE issue_id = 82 AND instrument_id = 'MBRC_PLANNING_SCHEME_2016';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
