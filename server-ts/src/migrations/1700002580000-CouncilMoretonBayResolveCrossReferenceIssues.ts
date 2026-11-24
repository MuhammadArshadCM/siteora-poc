import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/048_council_moreton_bay_resolve_cross_reference_issues.sql verbatim (ported from the project's hand-applied SQL history, originally db/048_council_moreton_bay_resolve_cross_reference_issues.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilMoretonBayResolveCrossReferenceIssues1700002580000 implements MigrationInterface {
  name = "CouncilMoretonBayResolveCrossReferenceIssues1700002580000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Moreton Bay: resolve open issues #57, #58, #65, #67, #68 using the full
-- Version 8 scheme text the user supplied (docs/fullplan.pdf), per the
-- findings recorded against the matching rule_versions in db/047.
-- =============================================================================
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = DATE '2026-11-03',
  description = description || $q$ RESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8) p.5 s1.5(1)(d), p.1619-1620, p.2180, p.2216: Section 1.5(1)(d) states "local plan codes prevail over zone codes, use codes and other development codes to the extent of the inconsistency". The Dwelling house code (9.3.1) is a use code, so the Redcliffe Kippa-Ring local plan's own Table 7.2.1.6.3 governs over 9.3.1's Table 9.3.1.3. Full table: side 1.5m(wall<4.5m)/2m(4.5-8.5m)/2m+0.5m per 3m(>8.5m); rear identical to side; primary frontage 6m wall/4.5m OMP/5.4m car parking (wall<4.5m only); secondary frontage 3m wall/2m OMP; secondary-to-lane 0.5m. Recorded against CMB.mb_rkr_interim_setbacks_table_72163 (db/047); ready for an automatable split by wall-height band.$q$
WHERE issue_id = 57 AND lg_id = 'MORETON_BAY' AND resolved_at IS NULL;

UPDATE open_issues SET resolved_at = DATE '2026-11-03',
  description = description || $q$ RESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8) p.3103 Table 9.3.1.6: the table's own title explicitly reads "...and Emerging community zone - Transition precinct (developed lot) and identified in the Morayfield South urban area on Figure 9.3.1.1" -- confirming Table 9.3.1.6 (not 9.3.1.5) is the one meant for Morayfield South, consistent with E3.1 (assessable-development pathway). RAD3's own routing to 9.3.1.5 for Morayfield South is the drafting slip (every other line in RAD3's list matches E3.1 exactly; only the Morayfield South line differs). Checked against the live rule set: this is ALREADY correctly encoded -- CMB.C.URBAN_PRIMARY_FRONTAGE / URBAN_SECONDARY_FRONTAGE / URBAN_OUTBUILDING_FRONTAGES (Table 9.3.1.6) are scoped to precinct CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT_MORAYFIELD_SOUTH, and the NEXTGEN_* (Table 9.3.1.5) equivalents are scoped to CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT (the "other than Morayfield South" precinct) -- matching this resolution exactly; a prior pass already got this right, it was just never closed. Note: side/rear for the Morayfield South (Table 9.3.1.6) precinct remain DRAFT (CMB.mb_dh_t93116_urban_side/_rear) -- only front/secondary/outbuilding-frontage are active; left as a separate, smaller follow-up.$q$
WHERE issue_id = 58 AND lg_id = 'MORETON_BAY' AND resolved_at IS NULL;

UPDATE open_issues SET resolved_at = DATE '2026-11-03',
  description = description || $q$ RESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8) p.3522 Schedule 1 + p.1620 RAD3/RAD4: "Dwelling house" is a defined term in Schedule 1 that already includes "any domestic outbuildings associated with the dwelling" -- RAD3's exclusion of "a dwelling house" therefore excludes domestic outbuildings too; RAD3 (6m/4.5m/4.5m) only ever applies to a standalone non-dwelling rural building/structure. Outside the Hamlet precinct, the Rural zone code sets NO boundary setback at all for a dwelling house or its domestic outbuildings -- QDC/QHC governs Class 10a boundary clearance entirely (the project's existing baseline is correct and complete; nothing new to encode). Inside the Hamlet precinct, RAD4 (no dwelling-house exclusion) applies: 6m road / 1.5m side (lots <=1000m2) or 3m (>1000m2) / 4m rear. The 3 DRAFT rules exploring the opposite reading have been superseded (db/047).$q$
WHERE issue_id = 65 AND lg_id = 'MORETON_BAY' AND resolved_at IS NULL;

UPDATE open_issues SET resolved_at = DATE '2026-11-03',
  description = description || $q$ RESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8) p.1860 RAD3 + p.1873 E4: not a real conflict -- RAD3 (Part E, accepted development) and E4 (Part F, assessable-development benchmark for PO4) answer different questions for different assessment pathways. RAD3 legitimately defers Township residential rear setback to QDC/QHC for the accepted-development pathway; E4's 6.0m is only the acceptable-outcome example once a proposal is ALREADY assessable for some unrelated reason and is being merit-assessed against PO4 (outside this tool's accepted-development scope). For determining the accepted-development threshold, QDC/QHC governs Township residential rear, same conclusion as Rural (issue #65). Recorded against CMB.mb_tw_rad3_rear (kept, clarified) and CMB.mb_tw_e4_rear_assessable (superseded) in db/047.$q$
WHERE issue_id = 67 AND lg_id = 'MORETON_BAY' AND resolved_at IS NULL;

UPDATE open_issues SET resolved_at = DATE '2026-11-03',
  description = description || $q$ RESOLVED 2026-11-03 from docs/fullplan.pdf (Version 8) p.6-7 Table 1.6.1 + s1.6(6): confirmed Table 1.6.1 does NOT list 6.2.12 Township as an s33 "alternative provision to the QDC" code -- so that specific label on RAD3(b)/RAD59's own notes is not backed by the scheme's actual s33 declaration, and is likely an internal drafting inconsistency in the zone code's own text. This does not change the practical outcome for this tool: s1.6(6) separately and validly lists 6.2.12 among the codes with "concurrence agency issues", so non-compliance with RAD3/RAD59 still only triggers Council's concurrence role rather than full code-assessable development, regardless of the s33 labelling technicality.$q$
WHERE issue_id = 68 AND lg_id = 'MORETON_BAY' AND resolved_at IS NULL;
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilMoretonBayResolveCrossReferenceIssues1700002580000 ports a historical content/schema migration (db/048_council_moreton_bay_resolve_cross_reference_issues.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
