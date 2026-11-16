import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Closes stale bookkeeping on open_issues #83 and #90 (Sunshine Coast): both were raised 2026-10-29 over the
 * "8.5 m commonly cited, UNVERIFIED (maps are JavaScript/image only)" building height figure -- for low/medium/
 * high density residential (#83) and Emerging Community land (#90) respectively.
 *
 * SCC.C.DH_HEIGHT_MAPPED (db/034, built 2026-11-0x, after these issues were raised) already replaced the
 * guessed constant entirely: it reads the real per-lot value live from the council's own
 * SCC:OV:HEIGHT_OF_BUILDINGS_AND_STRUCTURES_OVERLAY GIS layer (poc/zoning_layers.json "value_fact":
 * "mapped_max_height_m", field LABEL on geoimage.scc.qld.gov.au), not a hardcoded 8.5m. Scope already covers
 * every zone named in both issues (Low/Medium/High Density Residential, Tourist Accommodation, Rural, Rural
 * Residential, Limited Development Landscape Residential, AND Emerging Community).
 *
 * Verified live today (2026-11-16) against a real Sunshine Coast coordinate (153.084668, -26.644206):
 * `npm run cli -- --lon 153.084668 --lat -26.644206 --structure SHED ...` returns
 * "Overlays: Height of buildings and structures overlay (25 metres)" and the rule resolves
 * "<= 25 m [DETERMINED]" -- an actual mapped value pulled live from the council's GIS, not the old 8.5m guess,
 * end to end. Both issues' core concern (an unverified guessed figure) no longer exists.
 */
export class CloseSunshineCoastHeightOverlayIssues1700004440000 implements MigrationInterface {
  name = "CloseSunshineCoastHeightOverlayIssues1700004440000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16 (stale bookkeeping found during open_issues triage): SCC.C.DH_HEIGHT_MAPPED (db/034) already replaced the guessed 8.5m constant with a live read of the council''s own Height of Buildings and Structures Overlay GIS layer (value_fact mapped_max_height_m, field LABEL, geoimage.scc.qld.gov.au) -- scoped to Low/Medium/High Density Residential, Tourist Accommodation, Rural, Rural Residential and Limited Development Landscape Residential. Verified live 2026-11-16 against a real coordinate (153.084668, -26.644206): the engine returns "Height of buildings and structures overlay (25 metres)" and resolves <= 25 m [DETERMINED] -- an actual per-lot mapped value, not a guess. This issue row was simply never closed when the rule was built.'
WHERE issue_id = 83 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16 (stale bookkeeping found during open_issues triage): SCC.C.DH_HEIGHT_MAPPED (db/034) already covers the Emerging Community zone (rule_scopes includes SCC:EMERGING_COMMUNITY) with the same live GIS-mapped value mechanism described in issue #83''s resolution -- no separate EC-specific figure was ever needed; the mapped value applies per lot regardless of zone. Verified by the same live test as #83.'
WHERE issue_id = 90 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
