import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves 3 Sunshine Coast open_issues (#85, #89, #93). #85 via a direct live fetch of the Dwelling house
 * code PDF (publicdocs.scc.qld.gov.au record 22407391, pages 9-27/9-28); #89 and #93 via re-reading text
 * this project already held in db/030_council_sunshine_coast.sql.
 */
export class CloseSunshineCoastWordingIssuesBatch1700005400000 implements MigrationInterface {
  name = "CloseSunshineCoastWordingIssuesBatch1700005400000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: fetched the Dwelling house code PDF directly (publicdocs.scc.qld.gov.au record 22407391, pages 9-27/9-28) and read the actual table layout. The heading "Caloundra Local Plan Area (Precinct CAL LPP-2 (Moffat Beach/Shelly Beach/Dicky Beach) on Local Plan Map LPM45" appears once, immediately above PO18/AO18. PO19/AO19 continue in the very next table rows, separated from AO18 only by a page break (the routine "Performance Outcomes | Acceptable Outcomes" column-header reprint at the top of page 9-28) -- no new area/precinct heading intervenes. Confirmed: AO19.1/AO19.2 (secondary dwelling, 45m2 / 4m) apply to the same area as AO18 -- Caloundra Local Plan Area, Precinct CAL LPP-2.'
WHERE issue_id = 85 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held research (SCC.dh_site_cover_none''s own notes: "Checked the Dwelling house code and the LDR, MDR, RR and LDLR zone codes. The zone codes contain only purpose and overall outcomes, with no acceptable outcomes for dwelling houses."). This is confirmed as a deliberate scheme structure, not a gap: per Table 1.6.1, all of this scheme''s actual numeric dwelling-house/Class 10a siting standards (setbacks, height, site cover, canal setback, Blackall Range figures etc.) live in the SEPARATE "Dwelling house code" (9.3.6), not in the individual zone codes -- the zone codes themselves are purpose/character statements only, by the scheme''s own design. This project has already extracted the Dwelling house code in depth (AO1 through AO19+). Critically, that code''s own rules already explicitly list SCC:HIGH_DENSITY_RESIDENTIAL and SCC:TOURIST_ACCOMMODATION among their scopes (e.g. SCC.dh_caloundra_lpp2_front_setback, SCC.dh_secondary_dwelling_lpp2, SCC.dh_site_cover_none, SCC.dh_canal_setback) -- so those two zones are already covered via the Dwelling house code''s own multi-zone scope, the same way LDR/MDR are. "Not checked in depth" referred to the zone codes'' own text specifically, which -- consistent with LDR/MDR -- was never going to contain the real standards anyway.'
WHERE issue_id = 89 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held research for both sub-questions. (1) Blackall Range: AO16.1/AO16.2 (SCC.dh_blackall_range_storeys, SCC.dh_blackall_range_footprint) are scoped by LOCAL_PLAN (SCC:BLACKALL_RANGE), not by zone -- the engine already matches on local-plan-boundary overlap independently of zone, so if any Emerging Community land does fall within the Blackall Range local plan area, these rules already fire correctly for it; no zone-specific carve-out is needed regardless of the answer to "does EC land overlap". (2) Canal/waterbody: AO6 (SCC.dh_canal_setback, the 4.5m canal/artificial waterway setback) already explicitly lists SCC:EMERGING_COMMUNITY in its own scopes -- EC land adjacent to a canal/waterbody was already anticipated and covered when this rule was drafted. Both sub-questions resolved by the existing architecture; no fix needed (SCC.dh_canal_setback remains DRAFT/uncurated, a separate curation-backlog matter, not a scope gap).'
WHERE issue_id = 93 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
