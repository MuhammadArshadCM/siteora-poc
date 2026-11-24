import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/065_resolve_research_batch_round2.sql verbatim (ported from the project's hand-applied SQL history, originally db/065_resolve_research_batch_round2.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class ResolveResearchBatchRound21700003600000 implements MigrationInterface {
  name = "ResolveResearchBatchRound21700003600000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Second-pass batch resolution of open_issues via more research, continuing
-- the same pattern as db/064. This round surfaced one genuine coverage bug
-- (Gold Coast #35) and several issues that turned out to be ALREADY
-- correctly resolved by earlier work in this project -- confirmed by
-- reading rule_conditions/interpretation_notes directly, not just the
-- issue text (an initial fork survey claimed Burke #127/#128/#129 were
-- still-active bugs; direct inspection of rule_conditions showed they are
-- already gated by \`burke_zone_code_applies IS_TRUE\`, evidently fixed by
-- the prior "fix: burke shire council fixes" commit -- the open_issues
-- rows were simply never closed afterward).
--
-- Covers:
--   1. #35  GOLD_COAST -- ACTUAL FIX: Rural/EC front-setback rules only
--      matched boundary_type = PRIMARY_FRONTAGE, leaving a corner lot's
--      second road frontage (SECONDARY_FRONTAGE_ROAD) with no front-setback
--      rule in either the front or side/rear condition sets.
--   2. #10, #11, #18 BRISBANE -- doc-only closes, already correctly
--      implemented.
--   3. #132 CENTRAL_HIGHLANDS -- doc-only close, already correctly
--      implemented.
--   4. #126, #127, #128, #129 BURKE -- doc-only closes, already correctly
--      implemented (gated on burke_zone_code_applies).
-- =============================================================================
SET search_path = regs, public;

-- -----------------------------------------------------------------------
-- 1. Gold Coast #35 -- Sch 1 "Frontage" = "the boundary between a site and
-- a road," with no primacy qualifier -- every road boundary is a Front.
-- The Rural and Emerging community zone codes give only a flat "Front"
-- figure (10 m Rural; 10 m/6 m EC) and "Side and rear," with no secondary-
-- frontage carve-out of their own (unlike the residential zones' small-lot
-- codes, which do distinguish a secondary frontage with its own value).
-- Confirmed live: CGC.C.RURAL_FRONT_SETBACK / EC_FRONT_SETBACK /
-- EC_SUBDIV_FRONT_SETBACK all condition on boundary_type = 'PRIMARY_
-- FRONTAGE' only (not IN [...]), and the side/rear counterparts condition
-- on boundary_type IN ['SIDE','REAR'] only -- so a corner lot's second road
-- boundary (SECONDARY_FRONTAGE_ROAD) currently matches neither set and
-- gets no Gold Coast Rural/EC front-setback rule at all. Fix: extend the
-- three front rules' boundary_type condition to also match
-- SECONDARY_FRONTAGE_ROAD (an actual road boundary, per Sch 1's own
-- wording) -- not SECONDARY_FRONTAGE_LANE_PARKWAY or _OTHER, which are not
-- roads under that definition and are unaffected.
-- -----------------------------------------------------------------------
UPDATE rule_conditions SET value = '["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]'::jsonb, operator = 'IN'
WHERE condition_id IN (447, 450, 454);

UPDATE rule_versions SET interpretation_notes = COALESCE(interpretation_notes || E'\\n', '') ||
  'RESOLVED 2026-11-13 (closes open_issues #35): Sch 1 ''Frontage'' = ''the boundary between a site and a road'', with no primacy qualifier, so every road boundary on a corner lot is a Front -- the Rural/EC zone codes give only one flat Front figure with no secondary-frontage carve-out of their own. Condition extended from boundary_type = PRIMARY_FRONTAGE to IN (PRIMARY_FRONTAGE, SECONDARY_FRONTAGE_ROAD) so a corner lot''s second road boundary now gets this same front-setback figure (previously uncovered by any rule). SECONDARY_FRONTAGE_LANE_PARKWAY/_OTHER are not roads under Sch 1''s definition and are intentionally excluded.'
WHERE rule_version_id IN ('CGC.C.RURAL_FRONT_SETBACK@2026-09-29', 'CGC.C.EC_FRONT_SETBACK@2026-09-29', 'CGC.C.EC_SUBDIV_FRONT_SETBACK@2026-09-29');

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 35;

-- -----------------------------------------------------------------------
-- 2. Brisbane #10, #11, #18 -- all three confirmed already-correct on
-- direct DB inspection, no changes needed:
--
-- #10: "Average depth" is genuinely undefined in SC1.2 (only "average
-- width" is) -- but BCC.C.SL_REAR is already automatable=true with its own
-- note that average depth is estimated from the parcel outline (the
-- structural analogue of SC1.2's "average width" method, applied to the
-- perpendicular axis). Already handled.
--
-- #11: BCC.C.SL_REAR / BCC.C.SLB_REAR are already scoped subjects=ANY
-- ("applies to all buildings and structures" / confirmed via
-- BCC.slb_rear_setback_ref_table_c), matching the issue's own premise that
-- small-lot rear setbacks should carry no Class 10a carve-out. The
-- remaining "concurrence referral" question is a process/enforcement fact
-- that doesn't change the computed setback number.
--
-- #18: BCC.pad_dhc_small_lot_minor_structures already implements Table
-- 5.3.4.1 row 4589's prescribed-accepted shed/carport/pool for small HDR
-- lots. For non-small HDR lots, the absence of any Table 5.10.9/5.7.1
-- listing already defaults correctly to accepted development (QDC/QHC
-- governs), which is the engine's standing default behaviour.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (10, 11, 18);

-- -----------------------------------------------------------------------
-- 3. Central Highlands #132 -- CHRC.C.RURAL_ROAD_SETBACK and
-- CHRC.C.RURAL_SIDE_REAR_SETBACK are already ACTIVE, automatable=true,
-- titled "dwelling house incl. domestic outbuildings," and scoped to both
-- CLASS_1 and CLASS_10A -- exactly matching the issue's own premise that
-- AO1/AO3 bind as building assessment provisions via Table 1.6.1 even
-- though Rural-zone Class 10a building work is otherwise accepted
-- development with no planning requirements. Already correctly
-- implemented; nothing to change.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 132;

-- -----------------------------------------------------------------------
-- 4. Burke #126, #127, #128, #129 -- all four confirmed already-correct on
-- direct DB inspection of rule_conditions (an initial survey pass wrongly
-- flagged these as still-unresolved bugs; checking rule_conditions
-- directly, not just interpretation_notes prose, showed they already are):
--
-- #126: Research's own dwelling-house-use definition explicitly includes
-- "domestic outbuildings and works normally associated with a dwelling,"
-- so Table 7.2.1.4's exclusion of dwelling houses (via AO5) necessarily
-- excludes their outbuildings too -- confirmed no active BSC rule applies
-- Table 7.2.1.4 to a dwelling house or Class 10a outbuilding.
--
-- #127, #128, #129: BSC.C.RR_FRONT_SETBACK / RR_SIDE_REAR_SETBACK /
-- RURAL_FRONT_SETBACK / RURAL_SIDE_REAR_SETBACK / TOWNSHIP_COMMERCIAL_RES_
-- BOUNDARY_2M are each already gated by a rule_conditions row
-- \`burke_zone_code_applies IS_TRUE\` (confirmed live) -- i.e. each one
-- already applies ONLY when Table 5.8 makes the Class 10 building work
-- code assessable (heritage places / airport operational airspace), and
-- is accepted development (QDC governs) otherwise. This already resolves:
-- #127's Rural AO1 (6m) vs Table 7.2.1.4 (10m) conflict (AO5 defers to the
-- zone code, and the zone-code rule itself only fires when actually
-- code-assessable); #128's Township Commercial AO12.1 reaching a
-- code-assessable dwelling in that precinct (the same Table 5.8 gate
-- applies, and TOWNSHIP_COMMERCIAL_RES_BOUNDARY_2M is additionally kept
-- automatable=false pending a separate, already-flagged scope question);
-- #129's "no provision is an alternative provision" question (every one
-- of these rule_versions' interpretation_notes already states "Not a QDC
-- alternative provision... planning benchmark only, the QDC still applies
-- alongside" -- i.e. the council's position, per this research, is that
-- none of Burke's provisions are s33 alternative provisions, and the QDC
-- applies in full regardless of the planning-benchmark outcome).
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (126, 127, 128, 129);
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: ResolveResearchBatchRound21700003600000 ports a historical content/schema migration (db/065_resolve_research_batch_round2.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
