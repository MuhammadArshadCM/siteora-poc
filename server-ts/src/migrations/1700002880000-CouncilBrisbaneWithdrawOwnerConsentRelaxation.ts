import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "053_council_brisbane_withdraw_owner_consent_relaxation.sql");

/**
 * Replays db/053_council_brisbane_withdraw_owner_consent_relaxation.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilBrisbaneWithdrawOwnerConsentRelaxation1700002880000 implements MigrationInterface {
  name = "CouncilBrisbaneWithdrawOwnerConsentRelaxation1700002880000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilBrisbaneWithdrawOwnerConsentRelaxation1700002880000 ports a historical content/schema migration (db/053_council_brisbane_withdraw_owner_consent_relaxation.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
