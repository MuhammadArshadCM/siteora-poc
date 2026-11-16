import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "030_council_burke.sql");

/**
 * Replays db/030_council_burke.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilBurke1700000720000 implements MigrationInterface {
  name = "CouncilBurke1700000720000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilBurke1700000720000 ports a historical content/schema migration (db/030_council_burke.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
