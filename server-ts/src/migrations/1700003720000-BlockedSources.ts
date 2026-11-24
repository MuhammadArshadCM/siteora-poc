import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/067_blocked_sources.sql verbatim (ported from the project's hand-applied SQL history, originally db/067_blocked_sources.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class BlockedSources1700003720000 implements MigrationInterface {
  name = "BlockedSources1700003720000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Tracks external council/department sources that return HTTP 403 (or
-- equivalent) to automated fetching, so an admin can see them in one place,
-- upload a replacement document fetched manually in a browser, or mark the
-- underlying open_issue moot because the council has since adopted the
-- Queensland Housing Code (which changes instrument_applicability for that
-- LG and can make the blocked source irrelevant).
-- =============================================================================
SET search_path = regs, public;

CREATE TABLE IF NOT EXISTS blocked_sources (
  blocked_source_id BIGSERIAL PRIMARY KEY,
  issue_id BIGINT REFERENCES open_issues(issue_id),
  lg_id TEXT,
  label TEXT NOT NULL,
  url TEXT,
  status TEXT NOT NULL DEFAULT 'BLOCKED' CHECK (status IN ('BLOCKED', 'DOCUMENT_UPLOADED', 'QHC_OPTED_UNBLOCKED')),
  uploaded_file_path TEXT,
  uploaded_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO blocked_sources (issue_id, lg_id, label, url, notes) VALUES
  (144, 'MOUNT_ISA', 'Mount Isa Planning Scheme 2020 (no maps) PDF',
   'https://www.mountisa.qld.gov.au/files/assets/public/v/1/development/documents/city_of_mount_isa_planning_scheme__no_maps_.pdf',
   'Akamai hard-blocks every URL on this host regardless of client/headers (curl, PowerShell, WebFetch all 403). Currently reading an Internet Archive byte-copy (SHA-256 ca488ad3...069b) as a stand-in. Best candidate for a manual browser download + upload here.'),
  (124, 'BURKE', 'Burke Shire Planning Scheme 2020 (council planning page)',
   'https://www.burke.qld.gov.au/Our-council/Planning-and-development/Planning',
   'The scheme PDF itself is reachable from a pre-production mirror (burkeshire.prelive.opencities.com); this upload slot is for confirming the production page/URL is the authoritative one, not for the PDF text itself.'),
  (156, 'SOUTH_BURNETT', 'South Burnett Regional Council Planning Scheme v2.0 (currency check)',
   'https://www.southburnett.qld.gov.au/files/assets/public/v/1/business/documents/planning-scheme/south_burnett_regional_council_planning_scheme_v20__1_.pdf',
   'The PDF text was already captured from an earlier successful fetch; this 403 only blocks re-confirming v2.0 (eff. 28 Oct 2024) is still current.'),
  (169, 'MORETON_BAY', 'Moreton Bay ePlan (Version 9, commenced 2 Nov 2026)',
   'https://eplan.moretonbay.qld.gov.au/planningscheme',
   'HIGH severity: every CMB.* rule in this project is encoded against Version 8; the actual V8-to-V9 changes have not been checked.'),
  (168, 'GOLD_COAST', 'Gold Coast City Plan — Mixed Use zone (6.2.19/6.2.20)',
   'https://cityplan.goldcoast.qld.gov.au/eplan',
   'Only the Mixed Use zone dwelling-house figures are blocked (most of this host is otherwise fetchable). A draft "Our City Our Plan" amendment PDF exists but its section numbering conflicts with the live scheme.'),
  (105, 'LOGAN', 'Logan "Domestic outbuildings (garages and sheds)" web page',
   'https://logan.qld.gov.au/residential-projects/domestic-outbuildings-garages-sheds',
   'Secondary explainer page, not the primary scheme text (already held) -- low value.'),
  (4, NULL, 'Queensland Dept register of QHC adoption effective days',
   NULL,
   'No specific department URL was ever captured for this one in prior research -- re-check monthly; each adoption changes instrument_applicability for that LG. This row is also not a single-document upload candidate the way the others are (it is a recurring state-wide register check, not one council''s scheme text), but is tracked here so it is visible on the same admin page.');
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: BlockedSources1700003720000 ports a historical content/schema migration (db/067_blocked_sources.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
