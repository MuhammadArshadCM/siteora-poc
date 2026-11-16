import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", "052_council_logan_centre_zone_and_local_plan.sql");

/**
 * Replays db/052_council_logan_centre_zone_and_local_plan.sql verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class CouncilLoganCentreZoneAndLocalPlan1700002820000 implements MigrationInterface {
  name = "CouncilLoganCentreZoneAndLocalPlan1700002820000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilLoganCentreZoneAndLocalPlan1700002820000 ports a historical content/schema migration (db/052_council_logan_centre_zone_and_local_plan.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
