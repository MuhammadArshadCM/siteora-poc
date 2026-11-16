import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "041_council_brisbane_heritage_flood_pre1911_overlays.sql");

/**
 * Replays db/041_council_brisbane_heritage_flood_pre1911_overlays.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilBrisbaneHeritageFloodPre1911Overlays1700002160000 implements MigrationInterface {
  name = "CouncilBrisbaneHeritageFloodPre1911Overlays1700002160000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilBrisbaneHeritageFloodPre1911Overlays1700002160000 ports a historical content/schema migration (db/041_council_brisbane_heritage_flood_pre1911_overlays.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
