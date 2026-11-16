import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Corrects open_issues #4's premise. It was framed as "a department register exists but returns HTTP
 * 403" — re-checked 2026-11-14 and that framing is wrong on two counts:
 *
 * 1. There is no central, browsable "register" of QHC-adopting councils at all (checked
 *    planning.statedevelopment.qld.gov.au, statedevelopment.qld.gov.au, legislation.qld.gov.au and general
 *    search — nothing found, not a 403, just nothing there).
 * 2. The actual legal mechanism (Building Regulation 2021 s106, inserted by Building and Other
 *    Legislation Amendment Regulation 2026, SL 2026 No. 115) does NOT create a register at all --
 *    adoption happens per council, via that council amending its OWN planning scheme to state how the
 *    QHC applies. The regulation's own note says only: "If paragraph (a) applies to a local government's
 *    planning scheme, the department will publish the effective day on the department's website" -- i.e.
 *    a per-council notice if and when that council adopts, not a pre-existing list. As of this check, no
 *    Queensland council has adopted the QHC at all (confirmed independently for all 15 councils in this
 *    project via their own current scheme text, which already each state "no QHC adoption found" / "no
 *    reference to the Queensland Housing Code" -- see db/030_council_*.sql's instrument notes), so there
 *    is nothing yet for the department to have published anywhere.
 *
 * Practical consequence: the "automated monthly recheck" this issue called for was aimed at the wrong
 * target (a register that doesn't exist). The actually-correct recheck is per-council: does THAT
 * council's current planning scheme text now say how the QHC applies? This project already does that
 * check manually whenever a council's research is refreshed (exactly what caught Moreton Bay's V8->V9
 * drift this session) -- there is no cheaper or more authoritative alternative, since the law itself
 * routes adoption through each council's own scheme, not a central source. Left open, re-scoped to this
 * correct target rather than closed, since the practical gap (no automated recheck of any kind) still
 * exists.
 */
export class QhcRegisterFindingCorrected1700004080000 implements MigrationInterface {
  name = "QhcRegisterFindingCorrected1700004080000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      UPDATE regs.open_issues SET description =
        'CORRECTED 2026-11-14 (was: "Department register of QHC adoption effective days not reachable (HTTP 403)"): there is no central register to reach -- checked directly, nothing found at any Queensland Government planning/building department URL, and Building Regulation 2021 s106 (inserted by SL 2026 No. 115) does not create one. Adoption is per-council: each council amends its OWN planning scheme to state how the QHC applies, at which point "the department will publish the effective day on the department''s website" for THAT council -- there is nothing to publish statewide until a council actually adopts, and none had as of this check (confirmed independently for all 15 councils in this project via their own current scheme text). The right recheck target is each council''s own live scheme text (same check already done whenever a council''s research is refreshed -- this is what caught Moreton Bay''s V8-to-V9 drift this session), not a nonexistent central list. Left open: no automated recheck of any kind exists yet for any council; a periodic per-council keyword check ("Housing Code" / "QHC") against each council''s known live ePlan endpoint would be the correct, buildable next step.'
      WHERE issue_id = 4 AND instrument_id = 'QHC';
    `);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
