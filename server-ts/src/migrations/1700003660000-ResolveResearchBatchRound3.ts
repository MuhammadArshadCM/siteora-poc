import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "066_resolve_research_batch_round3.sql");

/**
 * Replays db/066_resolve_research_batch_round3.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class ResolveResearchBatchRound31700003660000 implements MigrationInterface {
  name = "ResolveResearchBatchRound31700003660000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: ResolveResearchBatchRound31700003660000 ports a historical content/schema migration (db/066_resolve_research_batch_round3.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
