import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "037_council_curated_mb_general_residential.sql");

/**
 * Replays db/037_council_curated_mb_general_residential.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilCuratedMbGeneralResidential1700001560000 implements MigrationInterface {
  name = "CouncilCuratedMbGeneralResidential1700001560000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilCuratedMbGeneralResidential1700001560000 ports a historical content/schema migration (db/037_council_curated_mb_general_residential.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
