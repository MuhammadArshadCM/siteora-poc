import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "039_council_curated_burke.sql");

/**
 * Replays db/039_council_curated_burke.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilCuratedBurke1700001680000 implements MigrationInterface {
  name = "CouncilCuratedBurke1700001680000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilCuratedBurke1700001680000 ports a historical content/schema migration (db/039_council_curated_burke.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
