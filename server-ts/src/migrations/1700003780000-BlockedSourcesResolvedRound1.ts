import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "068_blocked_sources_resolved_round1.sql");

/**
 * Replays db/068_blocked_sources_resolved_round1.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class BlockedSourcesResolvedRound11700003780000 implements MigrationInterface {
  name = "BlockedSourcesResolvedRound11700003780000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: BlockedSourcesResolvedRound11700003780000 ports a historical content/schema migration (db/068_blocked_sources_resolved_round1.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
