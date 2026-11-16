import type { MigrationInterface, QueryRunner } from "typeorm";

/** Further narrows open_issues #1 now that the gate latch height is encoded (MP34.A1b.GATE_LATCH_HEIGHT,
 *  PoolBarrierFullMp34Extraction). Only hinge tamper-resistance specs remain genuinely missing. */
export class PoolBarrierIssue1FurtherNarrowed1700004200000 implements MigrationInterface {
  name = "PoolBarrierIssue1FurtherNarrowed1700004200000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE regs.open_issues SET description =
        'FURTHER NARROWED 2026-11-16 (previously: "...exact latch height above ground and hinge tamper-resistance specifications... genuinely still missing"): gate latch height is now encoded (MP34.A1b.GATE_LATCH_HEIGHT -- underside of latch release >= 1500mm above ground AND >= 1400mm above the highest lower rail, or shielded), sourced from the s258 Building Act guideline that MP 3.4''s own A1(b) incorporates by reference for exactly this kind of tolerance-limit figure -- VERIFIED_VERBATIM, not a secondary source. A full re-extraction of the user''s own local copy of QDC MP 3.4 (39 pages; the complete Schedule 1 is items 1-30, all on pages 1-6 -- pages 7-39 are figures only) also added items 16, 17, 19-20 and 26 as new rules (retaining-wall/water-body-as-barrier, balcony NCZ, indoor child-resistant doorset) and confirmed AS 1926.2:2007 (location of barriers) is mostly DISAPPLIED by MP 3.4 itself, so there is no further hidden content there. Genuinely still missing, not found in MP 3.4, the s258 guideline, or any other free source checked: gate/door HINGE tamper-resistance specifications. Obtain a licensed copy of AS 1926.1-2007 to fill that one remaining gap, or confirm via a Queensland pool safety certifier.'
      WHERE issue_id = 1 AND instrument_id = 'AS_1926_1_2007';
    `);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
