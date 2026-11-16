import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "062_ncc_fire_separation_class10a.sql");

/**
 * Replays db/062_ncc_fire_separation_class10a.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class NccFireSeparationClass10a1700003420000 implements MigrationInterface {
  name = "NccFireSeparationClass10a1700003420000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: NccFireSeparationClass10a1700003420000 ports a historical content/schema migration (db/062_ncc_fire_separation_class10a.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
