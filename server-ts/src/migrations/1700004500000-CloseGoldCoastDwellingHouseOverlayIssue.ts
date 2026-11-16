import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves the last open portion of open_issues #30 (Gold Coast): the user located Table 5.10.5 "Dwelling
 * house overlay" directly in the City Plan (screenshot, 2026-11-16) -- it is a real, separately-named table,
 * not a legacy/renamed artifact as previously suspected.
 *
 * Confirmed purpose: it is a CATEGORY-OF-ASSESSMENT trigger (Code vs Impact assessment) for a Material change
 * of use of a Dwelling house involving building work with a Partial third storey, gated on whether the land is
 * identified on the Dwelling house overlay map AND on the (separate) Building height overlay map. It is NOT a
 * numeric siting/height standard, and it does not apply to Class 10a structures at all -- this project's own
 * raw research capture (db/030_council_gold_coast.sql) already holds the scheme's own note verbatim: "For
 * class 10 buildings and structures, no height restriction is provided in this table of assessment" (repeated
 * for both the Rural and Emerging community zone codes' MCU impact-assessment tables, the same tables this
 * overlay feeds into). Out of scope for this tool by the scheme's own text, not an oversight -- no new rule
 * needed. Closes #30 in full (the Building height overlay and Residential density overlay portions were
 * already resolved 2026-11-03).
 *
 * Separately flagged, NOT fixed here (needs its own investigation): while confirming this, found that
 * CGC.C.RURAL_HEIGHT (db/030, value 9m) is currently scoped to CLASS_10A as well as CLASS_1, with an
 * interpretation_notes comment that itself says "'For structures, no requirements for accepted development
 * are provided' -- structures keep the QDC" -- i.e. the rule's own notes and its own subject scoping disagree
 * about whether it should apply to Class 10a sheds/garages/carports in the Rural zone. Left for separate
 * review; not touched by this migration.
 */
export class CloseGoldCoastDwellingHouseOverlayIssue1700004500000 implements MigrationInterface {
  name = "CloseGoldCoastDwellingHouseOverlayIssue1700004500000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: user located Table 5.10.5 "Dwelling house overlay" directly in the City Plan (screenshot provided). It is a real table, not legacy/renamed. Purpose: a category-of-assessment trigger (Code vs Impact) for a dwelling house material-change-of-use involving a Partial third storey, gated on the Dwelling house overlay map AND the separate Building height overlay map -- not a numeric siting standard. Confirmed OUT OF SCOPE for Class 10a structures by the scheme''s own text, already held verbatim in this project''s raw research capture (db/030): "For class 10 buildings and structures, no height restriction is provided in this table of assessment" (appears for both the Rural and Emerging community zone MCU impact-assessment tables). No new rule needed. The Building height overlay and Residential density overlay portions of this issue were already resolved 2026-11-03 (db/042). Separately flagged during this check, NOT fixed here: CGC.C.RURAL_HEIGHT is scoped to CLASS_10A despite its own interpretation_notes saying structures keep the QDC instead -- needs its own review.'
WHERE issue_id = 30 AND instrument_id = 'CGC_CITY_PLAN';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
