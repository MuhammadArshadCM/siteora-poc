import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "040_council_curated_brisbane_dhc_carport.sql");

/**
 * Replays db/040_council_curated_brisbane_dhc_carport.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilCuratedBrisbaneDhcCarport1700002100000 implements MigrationInterface {
  name = "CouncilCuratedBrisbaneDhcCarport1700002100000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilCuratedBrisbaneDhcCarport1700002100000 ports a historical content/schema migration (db/040_council_curated_brisbane_dhc_carport.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
