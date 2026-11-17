import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Closes open_issues #92 and narrows #88 for Sunshine Coast, following up directly on the Palmview/Kawana
 * item the user asked to pursue.
 *
 * #92: fetched and fully read the Palmview Structure Plan PDF (publicdocs.scc.qld.gov.au record 22407421,
 * all precincts, not just a text search). Confirmed: Mixed Density Residential (Table 10.2.3.3B) and
 * Medium Density Residential (Table 10.2.3.3C) are the only two precincts where Dwelling house is a named
 * Consistent use, Accepted development (already encoded). Every one of the other 8 precincts -- District
 * Activity Centre (10.2.3.3D), Local Activity Centre (10.2.3.3E), Local Employment Area (10.2.3.3F),
 * Community Purpose (10.2.3.3G), Urban Open Space Recreation Park (10.2.3.3H(i)), Urban Open Space Sports
 * Park (10.2.3.3H(ii)), Non-urban Open Space Environmental Protection (10.2.3.3I(i)), and Non-urban Open
 * Space Landscape Protection (10.2.3.3I(ii)) -- carries the identical "All other/All defined uses in the
 * residential activity group (Inconsistent use)" catch-all row, uniformly triggering Impact assessment.
 * Dwelling house is a defined use within the "residential activity group" class under the scheme's own use
 * taxonomy, so it is caught by this catch-all in every one of those 8 precincts, with zero exceptions
 * found. This fully answers the issue's own question.
 *
 * #88 (narrowed, not fully closed): the Palmview portion is now comprehensively addressed (via #92's full
 * review plus the already-built SCC.C.EC_CHECK_APPROVED_PLAN_OF_DEVELOPMENT trigger for #91); the State
 * PDA (Caloundra South etc.) portion was already resolved via #95 (PDA land out-of-scope by design,
 * generically flagged via in_priority_development_area). Kawana DCP 1: fetched the council's live DCP 1
 * page directly and confirmed its operation is CURRENTLY SUSPENDED by Temporary Local Planning Instrument
 * (Kawana Waters Town Centre) No. 4 of 2025, in effect 13 April 2026 - 12 April 2028, and that TLPI itself
 * does not target dwelling house siting (per already-held research) -- so no DCP 1 siting content is
 * currently in force for dwelling houses in the Kawana Waters area. This is a time-bound finding (expires
 * with the suspension) and DCP 1's own historic siting content was never read, so narrowing rather than
 * closing -- left open only for a recheck once the suspension lifts or is extended/replaced.
 */
export class SunshineCoastPalmviewKawanaFindings1700005760000 implements MigrationInterface {
  name = "SunshineCoastPalmviewKawanaFindings1700005760000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: fetched and fully read the Palmview Structure Plan PDF directly (publicdocs.scc.qld.gov.au record 22407421, all 10 precinct tables, not just a text search). Confirmed: Mixed Density Residential (Table 10.2.3.3B) and Medium Density Residential (Table 10.2.3.3C) remain the only two precincts where Dwelling house is a named Consistent use, Accepted development (already encoded in CMB-style SCC rules). Every one of the other 8 precincts -- District Activity Centre (10.2.3.3D), Local Activity Centre (10.2.3.3E), Local Employment Area (10.2.3.3F), Community Purpose (10.2.3.3G), Urban Open Space Recreation Park (10.2.3.3H(i)), Urban Open Space Sports Park (10.2.3.3H(ii)), Non-urban Open Space Environmental Protection (10.2.3.3I(i)), and Non-urban Open Space Landscape Protection (10.2.3.3I(ii)) -- carries an identical "All other/All defined uses in the residential activity group (Inconsistent use)" catch-all row, uniformly triggering Impact assessment. Dwelling house is a defined use within the scheme''s own "residential activity group" use class, so it is caught by this catch-all in every one of those 8 precincts, with zero exceptions found across any of them. This fully answers the issue''s own question: yes, Palmview precincts beyond Mixed/Medium Density Residential do address dwelling house (via the residential-activity-group catch-all), consistently as an Inconsistent use requiring Impact assessment rather than Accepted/Code pathway. No granular Palmview sub-precinct boundary data exists in this project to scope a precinct-specific rule, and the existing SCC.C.EC_CHECK_APPROVED_PLAN_OF_DEVELOPMENT trigger (open_issues #91) already generically flags "check the Structure Plan" for the whole Emerging community zone, which covers this nuance in spirit. No further rule needed.'
WHERE issue_id = 92 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';

UPDATE open_issues SET description =
  'NARROWED 2026-11-17: the Palmview portion is now comprehensively addressed (full precinct-table review under open_issues #92, plus the SCC.C.EC_CHECK_APPROVED_PLAN_OF_DEVELOPMENT trigger built for #91). The State PDA (Caloundra South/Aura etc.) portion was already resolved via #95 (PDA land is jurisdictionally outside the City Plan by design, generically flagged project-wide via the in_priority_development_area fact). Kawana DCP 1: fetched the council''s live "Development Control Plan 1 - Kawana Waters" page directly and confirmed, verbatim: "The operation of [Development] Control Plan 1 - Kawana Waters is currently suspended and affected by [the] Temporary Local Planning Instrument (Kawana Waters Town Centre) No. 4 of 2025", with "The Temporary Local Planning Instrument has effect from 13 April 2026 until 12 April 2028." Already-held research on that TLPI confirms it does not target dwelling house siting. So as of this check (within the suspension window), no DCP 1 siting content is currently in force for dwelling houses in the Kawana Waters area -- not a present coverage gap. Genuinely still open: this is a time-bound confirmation only (expires with the suspension, 12 April 2028, or sooner if repealed/replaced), and DCP 1''s own historic siting text was never read (unnecessary while suspended, but would be needed once it lifts or TLPI No. 4/2025 is superseded) -- left open for that future recheck.'
WHERE issue_id = 88 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
