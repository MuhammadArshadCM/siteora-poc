import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #8 (Brisbane): user supplied both the current Bushfire overlay code (8.2.5) and Part 1
 * (About the planning scheme) PDFs, both freshly fetched from the live eplan (03-Nov-2026 print date), City
 * Plan v37 (effective 18/09/2026).
 *
 * Confirmed directly from the primary text, not inferred:
 *   - Table 1.6.1 item 9 (Part 1, page 18 of 23) still literally reads "Bushfire overlay code PO21 and
 *     AO21.2" -- a genuine, STILL-UNCORRECTED drafting error in Brisbane's own current, in-force document,
 *     not something that has since been fixed.
 *   - The Bushfire overlay code (8.2.5) itself genuinely has no PO21 or AO21 at all -- its highest items are
 *     PO20/AO20.1/AO20.2 (Section D, "accepted development subject to compliance with identified
 *     requirements ... or assessable development where in Potential impact sub-category").
 *   - AO20.2 specifically determines bushfire attack level "where in Potential impact sub-category" -- the
 *     exact designation concept Table 1.6.1 item 9 is about (Building Act s32(b) / Building Regulation s7
 *     designation of a bushfire prone area for a single detached Class 1a building in the Potential impact
 *     sub-category). This is a strong subject-matter match, confirming the correct reading is PO20/AO20.2,
 *     not the erroneous PO21/AO21.2 in the table.
 *
 * No active rule in this project currently depends on the erroneous reference (the only other PO21/AO21.2 in
 * this dataset is an unrelated small-lot-code building-length provision, BCC.slb_building_length_and_break --
 * same item numbers, different code, pure coincidence). Separately noted, not built here: Brisbane has no
 * equivalent to Moreton Bay's CMB.C.BUSHFIRE_PRONE_AREA_DESIGNATION (a Building Regulation s7/AS 3959
 * informational trigger) -- a worthwhile future addition, out of scope for this narrow cross-reference fix.
 */
export class CloseBrisbaneBushfireStaleCrossReference1700004860000 implements MigrationInterface {
  name = "CloseBrisbaneBushfireStaleCrossReference1700004860000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: user supplied both the current Bushfire overlay code (8.2.5) and Part 1 PDFs, freshly fetched from the live eplan (City Plan v37, effective 18/09/2026, printed 03-Nov-2026). Confirmed directly: Table 1.6.1 item 9 genuinely still says "PO21 and AO21.2" -- a real, still-uncorrected drafting error in the council''s own current document, not fixed since this issue was first raised. The Bushfire overlay code genuinely has no PO21/AO21 -- its highest items are PO20/AO20.1/AO20.2. AO20.2 determines bushfire attack level "where in Potential impact sub-category" -- the exact designation concept item 9 is about -- so the correct reading is PO20/AO20.2. No active rule in this project depends on the erroneous reference (the dataset''s only other PO21/AO21.2 is an unrelated small-lot building-length provision, same item numbers in a different code, coincidental). Separately noted: Brisbane has no equivalent to Moreton Bay''s CMB.C.BUSHFIRE_PRONE_AREA_DESIGNATION trigger rule -- a worthwhile future addition, out of scope here.'
WHERE issue_id = 8 AND instrument_id = 'BCC_CITY_PLAN_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
