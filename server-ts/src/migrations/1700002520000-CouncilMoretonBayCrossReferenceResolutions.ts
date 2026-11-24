import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/047_council_moreton_bay_cross_reference_resolutions.sql verbatim (ported from the project's hand-applied SQL history, originally db/047_council_moreton_bay_cross_reference_resolutions.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilMoretonBayCrossReferenceResolutions1700002520000 implements MigrationInterface {
  name = "CouncilMoretonBayCrossReferenceResolutions1700002520000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Moreton Bay: definitive resolutions for 5 open issues (#57, #58, #65, #67,
-- #68) after the user supplied docs/fullplan.pdf, the full current Version 8
-- planning scheme (the eplan itself blocks automated access, so this PDF is
-- the first time these provisions could be read directly). All text below is
-- read verbatim from that PDF, with page numbers noted for traceability.
-- =============================================================================
SET search_path = regs, public;

-- ---------------------------------------------------------------------------
-- Issue #65: Rural zone RAD3 vs domestic outbuildings.
-- Schedule 1 (docs/fullplan.pdf p.3522): "Dwelling house means a residential
-- use of premises involving - a. 1 dwelling and any domestic outbuildings
-- associated with the dwelling; or b. 2 dwellings, 1 of which is a secondary
-- dwelling, and any domestic outbuildings associated with either dwelling."
-- Rural zone code RAD3 (p.1620): "the minimum setbacks from a lot boundary
-- for buildings and structures OTHER THAN A DWELLING HOUSE, are as follows:
-- a. road boundary - 6m b. side boundary - 4.5m c. rear boundary - 4.5m."
-- RESOLVED: "a dwelling house" is a defined term that already bundles in any
-- domestic outbuildings associated with it, so RAD3's exclusion of "a
-- dwelling house" excludes domestic outbuildings too -- RAD3 only ever
-- applies to a standalone non-dwelling rural building/structure (e.g. a
-- shed for a rural industry use), never to a shed/carport/pool associated
-- with a dwelling. Outside the Hamlet precinct, the Rural zone code has NO
-- boundary-setback RAD at all for a dwelling house or its domestic
-- outbuildings -- QDC/QHC governs Class 10a boundary clearance entirely.
-- (Inside the Hamlet precinct, RAD4 (p.1620) does NOT carry the "other than
-- a dwelling house" exclusion, so its 6m/1.5-3m/4m setbacks DO apply there.)
-- These 3 DRAFT rules explored the opposite (wrong) reading -- superseding.
-- ---------------------------------------------------------------------------
UPDATE rule_versions SET status = 'SUPERSEDED', interpretation_notes = interpretation_notes ||
  E'\\n\\nRESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8, p.3522 Schedule 1 + p.1620 RAD3/RAD4): "a dwelling house" is a defined term in Schedule 1 that already includes "any domestic outbuildings associated with the dwelling" -- so RAD3''s exclusion of "a dwelling house" excludes domestic outbuildings too. RAD3 only applies to standalone non-dwelling rural buildings/structures. Outside the Hamlet precinct, the Rural zone code sets NO boundary setback for a dwelling house or its domestic outbuildings at all -- QDC/QHC governs Class 10a boundary clearance entirely (confirming the project''s existing QDC/QHC baseline is correct and complete here, nothing further to encode). Inside the Hamlet precinct, RAD4 (no dwelling-house exclusion) does apply: 6m road / 1.5m side (lots <=1000m2) or 3m (>1000m2) / 4m rear.'
WHERE rule_id IN ('CMB.mb_rural_rad3_road_setback_non_dwelling', 'CMB.mb_rural_rad3_side_setback_non_dwelling', 'CMB.mb_rural_rad3_rear_setback_non_dwelling')
  AND status = 'DRAFT';

-- ---------------------------------------------------------------------------
-- Issue #67: Township residential rear -- RAD3 "Refer to standards in QDC"
-- vs Part F E4 "6.0m" (docs/fullplan.pdf p.1860 RAD3, p.1873 E4).
-- RESOLVED: not a real conflict -- RAD3 (Part E, accepted development) and
-- E4 (Part F, assessable-development acceptable outcome for PO4) answer two
-- different questions. RAD3 legitimately defers the rear figure to QDC/QHC
-- for the accepted-development pathway this tool targets; E4 only matters
-- once a proposal is ALREADY assessable for some other reason and is being
-- checked against PO4 during code assessment (a merit-assessment scenario
-- outside this tool's scope). For determining the accepted-development
-- threshold, QDC/QHC governs Township residential rear -- same conclusion
-- as the Rural zone (issue #65) and consistent with how "Refer to standards
-- in QDC" cells are already treated elsewhere in this project.
-- ---------------------------------------------------------------------------
UPDATE rule_versions SET interpretation_notes = interpretation_notes ||
  E'\\n\\nRESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8, p.1860 RAD3 + p.1873 E4): not a real conflict -- RAD3 (Part E, accepted development) and E4 (Part F, assessable-development benchmark for PO4) answer different questions for different pathways. RAD3 legitimately defers Township residential rear setback to QDC/QHC for accepted development (the pathway this tool targets); E4''s 6.0m only matters once a proposal is already assessable for an unrelated reason and is being assessed against PO4 in code assessment. No Township-specific SETBACK.REAR rule for accepted development -- QDC/QHC governs, same conclusion as Rural (issue #65).'
WHERE rule_id = 'CMB.mb_tw_rad3_rear' AND status = 'DRAFT';

UPDATE rule_versions SET status = 'SUPERSEDED', interpretation_notes = interpretation_notes ||
  E'\\n\\nRESOLVED 2026-11-03: E4 is the assessable-development acceptable-outcome benchmark for PO4, not an accepted-development requirement -- it only applies once a proposal is already assessable for some other reason (a merit-assessment scenario outside this tool''s accepted-development scope). Superseding rather than encoding as an active SETBACK.REAR rule; see CMB.mb_tw_rad3_rear for the accepted-development conclusion (QDC/QHC governs).'
WHERE rule_id = 'CMB.mb_tw_e4_rear_assessable' AND status = 'DRAFT';

-- ---------------------------------------------------------------------------
-- Issue #68: Township zone code (6.2.12) Building Act s33 / concurrence
-- status. Table 1.6.1 (p.6-7) lists only 6.2.10, 6.2.11 and 9.3.1 as s33
-- "alternative provisions to the QDC" codes -- 6.2.12 Township is NOT among
-- them. Separately, Part 1 s1.6(6) (p.7) DOES list 6.2.3, 6.2.10, 6.2.11,
-- 6.2.12 and 9.3.1 together as codes containing "concurrence agency issues".
-- RESOLVED: Township's own internal "alternative provision to the QDC"
-- notes on RAD3(b)/RAD59 are not backed by Table 1.6.1 (the scheme's actual
-- s33 declaration), so that specific label is not legally effective for
-- Township. This does not change the practical outcome for this tool,
-- though: Township's concurrence-agency role IS independently and validly
-- established (s1.6(6) does list 6.2.12), so non-compliance with RAD3/RAD59
-- still only triggers Council's concurrence assessment rather than full
-- code-assessable development, regardless of the s33 labelling technicality.
-- ---------------------------------------------------------------------------
UPDATE rule_versions SET interpretation_notes = interpretation_notes ||
  E'\\n\\nRESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8, p.6-7 Table 1.6.1 + s1.6(6)): confirmed Table 1.6.1 does not list 6.2.12 Township as an s33 "alternative provision to the QDC" code -- that specific label on this RAD is not backed by the scheme''s own s33 declaration. Does not change the practical outcome: s1.6(6) separately and validly lists 6.2.12 among the "concurrence agency issues" codes, so non-compliance still only triggers Council''s concurrence role, not full code-assessable development.'
WHERE rule_id IN ('CMB.mb_tw_rad59_outbuilding_height', 'CMB.mb_tw_rad59_outbuilding_location', 'CMB.mb_tw_rad59_outbuilding_roofed_area')
  AND rule_id IN (SELECT rule_id FROM rules WHERE rule_id IN ('CMB.mb_tw_rad59_outbuilding_height', 'CMB.mb_tw_rad59_outbuilding_location', 'CMB.mb_tw_rad59_outbuilding_roofed_area'));

-- ---------------------------------------------------------------------------
-- Issue #57: Redcliffe Kippa-Ring local plan, Interim residential precinct.
-- Dwelling house code (9.3.1) RAD3(d)(i) (docs/fullplan.pdf p.1619-1620)
-- routes this precinct to Table 9.3.1.3; the local plan's OWN code (7.2.1.6)
-- RAD3 (p.2180) instead routes it to Table 7.2.1.6.3. Full Table 7.2.1.6.3
-- read (p.2216): side 1.5m(<4.5m wall)/2m(4.5-8.5m)/2m+0.5m-per-3m(>8.5m);
-- rear identical to side; primary frontage 6m wall/4.5m OMP/5.4m carpark
-- (<4.5m wall) else N/A for carpark; secondary frontage 3m wall/2m OMP;
-- secondary-to-lane 0.5m.
-- RESOLVED: Part 1 s1.5(1)(d) (p.5): "local plan codes prevail over zone
-- codes, use codes and other development codes to the extent of the
-- inconsistency" -- 9.3.1 (Dwelling house code) is a "use code", so the
-- local plan's Table 7.2.1.6.3 governs over 9.3.1's Table 9.3.1.3 for
-- Redcliffe Kippa-Ring's Interim residential precinct. (Separately, Table
-- 1.6.1 does not list 7.2.1.6 as an s33 Building Act alternative-provision
-- code -- that is a different, narrower question about which figure a
-- building certifier must apply absent a separate town-planning approval;
-- it does not change which number is the correct planning-scheme
-- requirement under s1.5.)
-- ---------------------------------------------------------------------------
UPDATE rule_versions SET interpretation_notes = interpretation_notes ||
  E'\\n\\nRESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8, p.5 s1.5(1)(d), p.1619-1620 RAD3(d)(i), p.2180 local plan RAD3, p.2216 Table 7.2.1.6.3): Table 7.2.1.6.3 (the local plan''s own table) governs over Dwelling house code Table 9.3.1.3, per the scheme''s explicit hierarchy clause s1.5(1)(d) -- "local plan codes prevail over zone codes, use codes and other development codes to the extent of the inconsistency" (9.3.1 is a use code). Full table read: side 1.5m(wall<4.5m)/2m(4.5-8.5m)/2m+0.5m per 3m over(>8.5m); rear identical to side; primary frontage 6m to wall/4.5m to OMP/5.4m to car parking space (wall<4.5m only, else N/A); secondary frontage 3m to wall/2m to OMP; secondary-to-lane 0.5m. (Table 1.6.1 not listing 7.2.1.6 as an s33 alternative-provision code is a separate, narrower Building Act question that does not change which number is the correct planning-scheme requirement.) Ready for an automatable rule split by wall-height band in a future pass.'
WHERE rule_id = 'CMB.mb_rkr_interim_setbacks_table_72163' AND status = 'DRAFT';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilMoretonBayCrossReferenceResolutions1700002520000 ports a historical content/schema migration (db/047_council_moreton_bay_cross_reference_resolutions.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
