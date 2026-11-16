import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "042_council_gold_coast_resolve_stale_issues.sql");

/**
 * Replays db/042_council_gold_coast_resolve_stale_issues.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilGoldCoastResolveStaleIssues1700002220000 implements MigrationInterface {
  name = "CouncilGoldCoastResolveStaleIssues1700002220000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilGoldCoastResolveStaleIssues1700002220000 ports a historical content/schema migration (db/042_council_gold_coast_resolve_stale_issues.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
