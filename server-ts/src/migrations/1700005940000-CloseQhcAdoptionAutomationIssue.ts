import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Closes open_issues #4. The issue's own text already named the correct, buildable next step: "a periodic
 * per-council keyword check ('Housing Code' / 'QHC') against each council's known live ePlan endpoint".
 * Built exactly that: server-ts/src/tools/check-qhc-adoption.ts (npm run check-qhc), which fetches each
 * council's ACTIVE planning-scheme instrument_versions.source_url and searches its text for "Housing Code"
 * or "QHC", following the exact style/pattern of the existing check-services.ts health-check tool.
 *
 * Tested live: 10 of 15 councils' pages fetched cleanly (all CLEAR -- no mention), 1 (South Burnett) is a
 * direct PDF link and reports SKIP (not text-searchable by this lightweight tool), and 5 (Brisbane, Central
 * Highlands, Gold Coast, Ipswich, Rockhampton) return HTTP 403 to automated fetches -- the same councils
 * already known this session to block scripted access on their main pages. This is a lightweight landing-
 * page signal, not a full-document audit, and is documented as such in the tool's own header comment; it
 * does not replace manually re-reading a council's scheme text, but gives a cheap, runnable first pass that
 * did not exist before. How often to run it (manual, CI, cron) is an operational choice left to the user.
 */
export class CloseQhcAdoptionAutomationIssue1700005940000 implements MigrationInterface {
  name = "CloseQhcAdoptionAutomationIssue1700005940000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: built the buildable next step this issue itself named -- server-ts/src/tools/check-qhc-adoption.ts (npm run check-qhc), a per-council keyword check ("Housing Code" / "QHC") against each council''s known live planning-scheme URL (instrument_versions.source_url), following the same pattern as the existing check-services.ts health-check tool. Tested live: 10 of 15 councils'' pages fetched cleanly with no mention found; 1 (South Burnett) is a direct PDF link, reported as not text-searchable by this lightweight tool; 5 (Brisbane, Central Highlands, Gold Coast, Ipswich, Rockhampton) return HTTP 403 to automated fetches, the same councils already known to block scripted access elsewhere this session. This is a lightweight landing-page signal, not a full-document audit -- documented as such in the tool''s own header -- but it is the concrete, runnable automated recheck this issue asked for, where none existed before. Scheduling it to run periodically (cron, CI, or manual) is an operational choice left to the user.'
WHERE issue_id = 4 AND instrument_id = 'QHC';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
