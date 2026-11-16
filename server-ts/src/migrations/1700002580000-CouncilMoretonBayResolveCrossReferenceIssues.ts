import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "048_council_moreton_bay_resolve_cross_reference_issues.sql");

/**
 * Replays db/048_council_moreton_bay_resolve_cross_reference_issues.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilMoretonBayResolveCrossReferenceIssues1700002580000 implements MigrationInterface {
  name = "CouncilMoretonBayResolveCrossReferenceIssues1700002580000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilMoretonBayResolveCrossReferenceIssues1700002580000 ports a historical content/schema migration (db/048_council_moreton_bay_resolve_cross_reference_issues.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
