// One-time generator: wraps every historical db/*.sql file in a TypeORM migration class that replays
// it verbatim via queryRunner.query(fs.readFileSync(...)). Run once to populate src/migrations/ from the
// db/ directory's existing history; NEW migrations from here on should be written directly as TypeORM
// migration files (see README), not as new db/*.sql files.
//
// Usage: node scripts/generate-migrations.mjs
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SERVER_TS_ROOT = path.join(HERE, "..");
const OUT_DIR = path.join(SERVER_TS_ROOT, "src", "migrations");

// Exact historical order: the first 39 follow db/load_all.sql's own \i order (council files were loaded
// in research-completion order, not filename order); 041-069 each have a unique numeric prefix so natural
// order is unambiguous.
const FILES_IN_ORDER = [
  "001_schema.sql", "002_loader.sql", "010_reference_data.sql", "020_state_provisions.sql", "021_state_rules.sql",
  "030_council_brisbane.sql", "030_council_gold_coast.sql", "030_council_moreton_bay.sql", "030_council_sunshine_coast.sql",
  "030_council_logan.sql", "030_council_ipswich.sql", "030_council_redland.sql", "030_council_burke.sql",
  "030_council_central_highlands.sql", "030_council_livingstone.sql", "030_council_mount_isa.sql", "030_council_rockhampton.sql",
  "030_council_south_burnett.sql", "030_council_toowoomba.sql", "030_council_townsville.sql",
  "031_council_curated.sql", "032_council_curated_batch2.sql", "033_council_curated_brisbane.sql", "034_council_mapped_heights.sql",
  "035_council_curated_new_zones.sql", "036_council_curated_remaining_zones.sql", "037_council_curated_mb_general_residential.sql",
  "038_council_curated_class10_setbacks.sql",
  "039_council_curated_burke.sql", "039_council_curated_central_highlands.sql", "039_council_curated_livingstone.sql",
  "039_council_curated_rockhampton.sql", "039_council_curated_south_burnett.sql", "039_council_curated_toowoomba.sql",
  "039_council_curated_townsville.sql",
  "040_council_curated_brisbane_dhc_carport.sql",
  "041_council_brisbane_heritage_flood_pre1911_overlays.sql", "042_council_gold_coast_resolve_stale_issues.sql",
  "043_council_gold_coast_resolve_more_stale_issues.sql", "044_council_gold_coast_bushfire_overlay_and_issue_cleanup.sql",
  "045_council_moreton_bay_height_overlay_and_issue_cleanup.sql", "046_council_moreton_bay_version9_and_access_blocker.sql",
  "047_council_moreton_bay_cross_reference_resolutions.sql", "048_council_moreton_bay_resolve_cross_reference_issues.sql",
  "049_council_moreton_bay_morayfield_south_side_rear_waterbody.sql", "050_council_south_burnett_street_hierarchy_research_note.sql",
  "051_council_brisbane_tbc_front_setback_automatable.sql", "052_council_logan_centre_zone_and_local_plan.sql",
  "053_council_brisbane_withdraw_owner_consent_relaxation.sql", "054_council_brisbane_sherwood_front_setback_average_automatable.sql",
  "055_council_sunshine_coast_outbuilding_floor_area_resolved.sql", "056_council_brisbane_small_lot_hdr_scope_resolved.sql",
  "057_resolve_similar_ambiguities_batch.sql", "058_council_brisbane_close_resolved_batch.sql",
  "059_council_rockhampton_alton_downs_side_rear_resolved.sql", "060_close_verified_stale_batch.sql",
  "061_resolve_general_legislation_citations.sql", "062_ncc_fire_separation_class10a.sql",
  "063_council_mount_isa_curated.sql", "064_resolve_research_batch_nov13.sql", "065_resolve_research_batch_round2.sql",
  "066_resolve_research_batch_round3.sql", "067_blocked_sources.sql", "068_blocked_sources_resolved_round1.sql",
  "069_moreton_bay_v9_morayfield_and_bushfire.sql",
];

const DB_DIR = path.join(SERVER_TS_ROOT, "..", "db");
for (const f of FILES_IN_ORDER) {
  if (!fs.existsSync(path.join(DB_DIR, f))) throw new Error(`Missing db/${f} — check FILES_IN_ORDER`);
}

fs.mkdirSync(OUT_DIR, { recursive: true });
for (const old of fs.readdirSync(OUT_DIR)) fs.unlinkSync(path.join(OUT_DIR, old));   // regenerate clean each run

const BASE_TS = 1700000000000;   // 2023-11-14 — arbitrary, just needs to be in the past and strictly increasing

function pascalCase(stem) {
  // "042_council_gold_coast_resolve_stale_issues" -> "CouncilGoldCoastResolveStaleIssues"
  return stem.replace(/^\d+_/, "").split(/[_\-]+/).map((w) => w.charAt(0).toUpperCase() + w.slice(1)).join("");
}

const manifest = [];
FILES_IN_ORDER.forEach((file, i) => {
  const ts = BASE_TS + i * 60000;
  const stem = file.replace(/\.sql$/, "");
  const className = `${pascalCase(stem)}${ts}`;
  const outFile = `${ts}-${pascalCase(stem)}.ts`;
  const body = `import type { MigrationInterface, QueryRunner } from "typeorm";
import fs from "node:fs";
import path from "node:path";
import { ROOT } from "../core/env.js";

const SQL_FILE = path.join(ROOT, "db", ${JSON.stringify(file)});

/**
 * Replays db/${file} verbatim (ported from the project's hand-applied SQL history —
 * see that file for the full rationale/comments). Forward-only: see down().
 */
export class ${className} implements MigrationInterface {
  name = ${JSON.stringify(className)};

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(fs.readFileSync(SQL_FILE, "utf-8"));
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: ${className} ports a historical content/schema migration (db/${file}) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
`;
  fs.writeFileSync(path.join(OUT_DIR, outFile), body);
  manifest.push({ file, outFile, className, ts });
});

// Final migration, not sourced from a db/ file: replays load_all.sql's own trailing step.
{
  const ts = BASE_TS + FILES_IN_ORDER.length * 60000;
  const className = `SetDefaultSearchPath${ts}`;
  const outFile = `${ts}-SetDefaultSearchPath.ts`;
  const body = `import type { MigrationInterface, QueryRunner } from "typeorm";

/** Ports db/load_all.sql's trailing step: make the regs schema visible without a prefix on new connections. */
export class ${className} implements MigrationInterface {
  name = ${JSON.stringify(className)};

  public async up(queryRunner: QueryRunner): Promise<void> {
    const db = await queryRunner.query("SELECT current_database() AS db");
    await queryRunner.query(\`ALTER DATABASE "\${db[0].db}" SET search_path = regs, public\`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const db = await queryRunner.query("SELECT current_database() AS db");
    await queryRunner.query(\`ALTER DATABASE "\${db[0].db}" SET search_path = public\`);
  }
}
`;
  fs.writeFileSync(path.join(OUT_DIR, outFile), body);
  manifest.push({ file: null, outFile, className, ts });
}

console.log(`Generated ${manifest.length} migrations in ${path.relative(SERVER_TS_ROOT, OUT_DIR)}`);
