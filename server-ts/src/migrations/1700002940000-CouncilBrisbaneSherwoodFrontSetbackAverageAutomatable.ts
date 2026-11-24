import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/054_council_brisbane_sherwood_front_setback_average_automatable.sql verbatim (ported from the project's hand-applied SQL history, originally db/054_council_brisbane_sherwood_front_setback_average_automatable.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilBrisbaneSherwoodFrontSetbackAverageAutomatable1700002940000 implements MigrationInterface {
  name = "CouncilBrisbaneSherwoodFrontSetbackAverageAutomatable1700002940000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Brisbane: BCC.C.NP_SHERWOOD_WESTSIDE_FRONT_AVG (City Plan 2014 7.2.19.3.3
-- Table 7.2.19.3.3.A, PO3/AO3.3 -- Sherwood-Graceville district neighbourhood
-- plan, Westside character precinct) was still automatable=false.
--
-- Client Q&A (2026-11-06) on this exact clause: asked whether, instead of
-- the user computing a "20% average front setback" themselves, the app
-- could just take the average front setback figure directly. It already
-- does -- the rule's value is {op:"*", args:[0.8, {var:
-- pre1946_neighbour_avg_front_setback_m}]}}, so the 80%-of-average minimum
-- is computed by the engine; the user only ever supplies one number (the
-- average front setback of the nearest pre-1946 houses on the same street),
-- never a percentage. That input path (pre1946_setback_m CLI flag / API
-- input / poc/static/index.html field) was added for the city-wide
-- BCC.C.TBC_FRONT_SETBACK_AVERAGE rule in db/051, and this rule shares the
-- exact same fact -- but db/051 only flipped that one rule_version, missing
-- this neighbourhood-plan duplicate of the same clause (confirmed: both
-- quote near-identical AO wording and use pre1946_neighbour_avg_front_
-- setback_m). Flipping this one too, same reasoning as db/051: resolveWith()
-- still falls back to MANUAL_REVIEW whenever the fact is left blank (the
-- computed value is then UNKNOWN), so this is not forcing an answer, only
-- removing the permanent-override that kept it at MANUAL_REVIEW even once
-- supplied.
--
-- Note on the client's "if nearest building is post-46, not relevant" point:
-- already correctly handled -- the PRIMARY_FRONTAGE/SECONDARY_FRONTAGE_ROAD
-- condition plus this rule's own LOCAL_PLAN_PRECINCT scope (NPP-001, the
-- Westside character precinct) mean it only becomes a candidate, and the
-- UI only asks for the figure, when the lot is actually in that precinct;
-- nothing here assumes a pre-1946 building exists where there isn't one.
-- =============================================================================
SET search_path = regs, public;

UPDATE rule_versions
SET automatable = true,
    interpretation_notes = interpretation_notes || $q$ Automatable once pre1946_neighbour_avg_front_setback_m is supplied (same fact/input path as BCC.C.TBC_FRONT_SETBACK_AVERAGE, see db/051); otherwise still manual review.$q$
WHERE rule_version_id = 'BCC.C.NP_SHERWOOD_WESTSIDE_FRONT_AVG@2026-09-18';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilBrisbaneSherwoodFrontSetbackAverageAutomatable1700002940000 ports a historical content/schema migration (db/054_council_brisbane_sherwood_front_setback_average_automatable.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
