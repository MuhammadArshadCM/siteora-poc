import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/050_council_south_burnett_street_hierarchy_research_note.sql verbatim (ported from the project's hand-applied SQL history, originally db/050_council_south_burnett_street_hierarchy_research_note.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilSouthBurnettStreetHierarchyResearchNote1700002700000 implements MigrationInterface {
  name = "CouncilSouthBurnettStreetHierarchyResearchNote1700002700000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- South Burnett: follow-up on issue #155 (Rural AO1.1 depends on road
-- hierarchy "collector or higher order road", not defined in SC1).
--
-- This is the same QDC MP 1.1 Table A1 street-hierarchy gap researched and
-- fixed for 9 other councils (Moreton Bay, Rockhampton, Mount Isa, Brisbane,
-- Sunshine Coast, Gold Coast, Toowoomba, Townsville, Logan) via each
-- council's own public road-classification GIS layer (see
-- server-ts/src/core/geo.ts STREET_HIERARCHY_SOURCES). South Burnett has no
-- such layer: confirmed via dedicated research that no council-published or
-- state/national source exists that reliably classifies South Burnett roads
-- as Access vs Collector (the same is true for Ipswich, Redland,
-- Livingstone, Burke and Central Highlands). OpenStreetMap was evaluated and
-- found technically capable, but its public Overpass API's own acceptable-
-- use policy explicitly excludes "automated or high-volume use" in favour of
-- a self-hosted instance, so it was not wired into this project's live,
-- per-request lookup path.
--
-- Not resolving this issue: the gap it describes (no automatic road-
-- hierarchy source for South Burnett) is still true. What has changed is
-- that a manual resolution mechanism now exists project-wide: a
-- \`--street-type access|collector\` CLI flag / \`street_type\` API input
-- (server-ts/src/tools/cli.ts, core/engine.ts) lets the result be supplied
-- directly for any lot where no automatic source resolves it, including
-- every South Burnett Rural AO1.1 case. Noted on the issue so a future pass
-- does not repeat this research.
-- =============================================================================
SET search_path = regs, public;

UPDATE open_issues
SET description = description || $q$ RESEARCHED 2026-11-04: confirmed no council-published or state/national road-hierarchy source exists for South Burnett that distinguishes Access from Collector roads (same conclusion as Ipswich, Redland, Livingstone, Burke and Central Highlands). OpenStreetMap/Overpass was evaluated but excluded -- its public API's acceptable-use policy prohibits automated/production use. A manual \`--street-type access|collector\` CLI flag / \`street_type\` API input is now available project-wide (server-ts/src/tools/cli.ts, core/engine.ts) as the practical way to resolve Rural AO1.1 here until a proper source is found; left open since no automatic source exists.$q$
WHERE issue_id = 155 AND lg_id = 'SOUTH_BURNETT' AND resolved_at IS NULL;
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilSouthBurnettStreetHierarchyResearchNote1700002700000 ports a historical content/schema migration (db/050_council_south_burnett_street_hierarchy_research_note.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
