import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "045_council_moreton_bay_height_overlay_and_issue_cleanup.sql");

/**
 * Replays db/045_council_moreton_bay_height_overlay_and_issue_cleanup.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilMoretonBayHeightOverlayAndIssueCleanup1700002400000 implements MigrationInterface {
  name = "CouncilMoretonBayHeightOverlayAndIssueCleanup1700002400000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilMoretonBayHeightOverlayAndIssueCleanup1700002400000 ports a historical content/schema migration (db/045_council_moreton_bay_height_overlay_and_issue_cleanup.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
