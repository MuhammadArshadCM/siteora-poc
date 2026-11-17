import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Narrows (does not close) open_issues #122 (Redland): user checked the council's current City Plan
 * document and confirmed it is still Version 14 -- Major Amendment 02/25 (Residential), which council
 * resolved on 15 July 2026 to send for Ministerial approval, has NOT yet been adopted/commenced. Left open
 * since adoption is still pending and this issue's own text ("re-check after adoption") means it needs
 * checking again once a new version actually commences -- same open-ended-but-confirmed-current-state
 * treatment as open_issues #4 (QHC).
 */
export class NarrowRedlandMajorAmendment0225Issue1700005100000 implements MigrationInterface {
  name = "NarrowRedlandMajorAmendment0225Issue1700005100000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  description = 'CONFIRMED STILL PENDING 2026-11-17: user checked the council''s current City Plan document (Version 14, updated 23 Sep 2026) -- Major Amendment 02/25 (Residential), sent for Ministerial approval per council''s 15 July 2026 resolution, has NOT yet been adopted. No version bump; the changes described below (character residential zone road setback alternative, LDR5 pool/excavation triggers, LDR3 AO16.1 domestic outbuildings, LDR corner-lot/dual occupancy rules) are not yet in force. Left open -- re-check again once a new version actually commences.'
WHERE issue_id = 122 AND instrument_id = 'RCC_CITY_PLAN_2018';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
