import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/056_council_brisbane_small_lot_hdr_scope_resolved.sql verbatim (ported from the project's hand-applied SQL history, originally db/056_council_brisbane_small_lot_hdr_scope_resolved.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilBrisbaneSmallLotHdrScopeResolved1700003060000 implements MigrationInterface {
  name = "CouncilBrisbaneSmallLotHdrScopeResolved1700003060000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Brisbane: resolve open_issues #16 (HDR omitted from the zone arrays of
-- BCC.C.SL_*/dh_parking_spaces/dh_secondary_dwelling_size/
-- dh_building_envelope_plan/slb_* rules -- the issue's own text recommended
-- just adding "High density residential zone" to those arrays).
--
-- Investigated 2026-11-12, NOT applying that recommendation: the only
-- verbatim evidence found for extending the Dwelling house (small lot) code
-- into HDR is Table 5.10.9 (research/councils/brisbane.json) -- but that
-- table is the Dwelling House Character OVERLAY's planning *assessment
-- category* table (does the work need approval at all), not the Building
-- Act s33 "alternative provision" designation that actually produces these
-- rules' enforceable setback/site-cover NUMBERS. That designation (Table
-- 1.6.1 items 10-12) names code clauses (PO2/AO2 etc.), not zones -- the
-- small-lot code's own zone list lives in that code's "Application" section,
-- which was never captured in this project's research and which Brisbane's
-- ePlan blocks from automated access (403, confirmed again today via both
-- curl and WebFetch -- same block already documented for the HIGH-severity
-- Moreton Bay/QHC-register issues).
--
-- Supporting reasons to NOT assume HDR inclusion absent that text:
--   1. A NEW dwelling house MCU in HDR (or Tourist accommodation) requires
--      IMPACT assessment -- the most discretionary category -- meaning
--      these zones aren't really designed to host a standalone dwelling
--      house; an existing one is a legacy/non-conforming situation, not
--      the zone's intended building type.
--   2. The existing rules' own interpretation_notes already flagged
--      uncertainty even for Character Residential ("the researcher's zone
--      list named LDR/LMR/MDR -- confirm CR") -- this scope was already a
--      best-effort guess, not a verified list, so extending it further on
--      the same unverified basis would compound the guess, not resolve it.
--   3. For a STANDARD (non-small) HDR lot, this project already correctly
--      determined (open_issues #17, NOT A BUG) that no scheme setback
--      exists and QDC/QHC governs directly. It is entirely plausible small
--      HDR lots work the same way -- the small-lot code simply not
--      reaching them -- which is exactly the CURRENT (unchanged) behaviour.
--
-- Resolution: no rule change. Absent the Application-section text, HDR (and
-- Tourist accommodation, raised by the same question) are correctly left
-- out of these zone arrays, so a small lot in either zone falls straight
-- through to bare QDC/QHC -- the conservative default, and already the
-- current behaviour of every BCC.C.SL_*/dh_*/slb_* rule in this dataset.
-- Re-open and re-verify against the small-lot code's own Application
-- section if Brisbane's ePlan ever becomes reachable (same caveat as the
-- HIGH-severity ePlan-access issues).
-- =============================================================================
SET search_path = regs, public;

UPDATE open_issues
SET resolved_at = CURRENT_DATE
WHERE issue_id = 16;

INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES
  ($q$BRISBANE$q$, $q$BCC_CITY_PLAN_2014$q$, 'LOW',
   $q$RESOLVED (closes #16): BCC.C.SL_*/dh_parking_spaces/dh_secondary_dwelling_size/dh_building_envelope_plan/slb_* rules deliberately omit High density residential and Tourist accommodation zones. The only evidence found for HDR/Tourist inclusion (Table 5.10.9) answers a different question (DHC overlay assessment category, not the Building Act s33 alternative-provision zone scope that produces these setback numbers) -- the small-lot code's own Application section, which would settle this, is blocked behind Brisbane's ePlan 403 and was never captured in research. Until that text is available, small lots in HDR/Tourist accommodation correctly fall straight to QDC/QHC (the conservative default, already the current behaviour) -- consistent with standard (non-small) HDR lots per #17. Re-verify if ePlan access is ever restored.$q$);
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilBrisbaneSmallLotHdrScopeResolved1700003060000 ports a historical content/schema migration (db/056_council_brisbane_small_lot_hdr_scope_resolved.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
