import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/055_council_sunshine_coast_outbuilding_floor_area_resolved.sql verbatim (ported from the project's hand-applied SQL history, originally db/055_council_sunshine_coast_outbuilding_floor_area_resolved.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilSunshineCoastOutbuildingFloorAreaResolved1700003000000 implements MigrationInterface {
  name = "CouncilSunshineCoastOutbuildingFloorAreaResolved1700003000000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Sunshine Coast: resolve the open question on SCC.C.OUTBUILDING_FLOOR_AREA_56
-- (9.3.6.3 Table 9.3.6.3.1 AO2.1(c)) -- whether the 56 m2 "total floor area"
-- cap applies per structure or combined across every garage/carport/shed on
-- the lot.
--
-- Researched 2026-11-12 against the verbatim clause (research/councils/
-- sunshine_coast.json): "AO2.1 Where located on a lot in a residential zone,
-- a garage, carport or shed:- (a) is setback at least 6 metres from any road
-- frontage; (b) does not exceed a height of 3.6 metres; and (c) has a total
-- floor area that does not exceed 56m2. Note--AO2.1(b) and (c) do not apply
-- to a garage under the main roof of a dwelling house." "Total floor area"
-- is NOT a defined term in Schedule 1 (confirmed already in the original
-- research notes).
--
-- Resolved as PER STRUCTURE, not a lot-wide combined total:
--   1. Grammar: (a), (b) and (c) are three parallel tests on one singular
--      subject ("a garage, carport or shed"). (a) (setback) and (b) (height)
--      are unambiguously per-structure -- nothing in the drafting marks (c)
--      as switching to a lot-wide aggregate.
--   2. This dataset already shows what explicit aggregation language looks
--      like when a scheme actually means it: QDC MP1.1/1.2 A2(d)(ii) says
--      "the total length of all buildings or parts, of any class..."; Logan's
--      LCC.C.LARGE_OUTBUILDING_MAX_300 (db/032) is titled "cumulative floor
--      area <= 300 m2" and Moreton Bay's outbuilding cap is explicitly
--      "combined roofed area", scaled by lot size (50/70/80/150 m2). AO2.1(c)
--      has none of that: no "all", no "combined"/"cumulative", and a flat,
--      unscaled figure -- consistent with a per-building size cap, not a
--      property-wide budget.
--   3. The exemption note ("do not apply to a garage under the main roof")
--      excludes that one structure from the test -- a reading that only
--      makes sense if the test is applied structure-by-structure.
--
-- Consequence: the required figure (56 m2) does not change either way -- all
-- that was blocking automation was knowing which structure's own floor area
-- to show it against. Flipping automatable to true now that this is settled;
-- title/notes updated so the comparison is unambiguous to the reader (compare
-- against *this* structure's own floor area, not a running lot total).
-- =============================================================================
SET search_path = regs, public;

UPDATE rules
SET title = 'Residential zones: garage, carport or shed -- EACH structure''s own total floor area <= 56 m2 (not combined across the lot)'
WHERE rule_id = 'SCC.C.OUTBUILDING_FLOOR_AREA_56';

UPDATE rule_versions
SET automatable = true,
    interpretation_notes = $q$RESOLVED 2026-11-12 (per structure, not combined across the lot): AO2.1(c) is one of three parallel tests ((a) setback, (b) height, (c) floor area) on the singular subject "a garage, carport or shed" -- (a) and (b) are unambiguously per-structure, and nothing in the drafting marks (c) as switching to a lot-wide aggregate. Contrast with schemes in this dataset that DO aggregate explicitly when they mean to (QDC A2(d)(ii) "total length of all buildings... of any class"; Logan's cumulative 300 m2 cap; Moreton Bay's lot-size-scaled "combined roofed area"): AO2.1(c) has no such language and is a flat, unscaled figure. The "does not apply to a garage under the main roof" exemption also only makes sense applied structure-by-structure. Compare against this structure's own floor area (plan_area_m2 in the engine), not a running total of existing + new outbuildings.$q$
WHERE rule_version_id = 'SCC.C.OUTBUILDING_FLOOR_AREA_56@2024-01-23';

UPDATE open_issues
SET resolved_at = CURRENT_DATE
WHERE lg_id = 'SUNSHINE_COAST'
  AND description = $q$Whether the AO2.1(c) 56 m2 'total floor area' applies per structure or to all garages, carports and sheds on the lot combined.$q$;
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilSunshineCoastOutbuildingFloorAreaResolved1700003000000 ports a historical content/schema migration (db/055_council_sunshine_coast_outbuilding_floor_area_resolved.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
