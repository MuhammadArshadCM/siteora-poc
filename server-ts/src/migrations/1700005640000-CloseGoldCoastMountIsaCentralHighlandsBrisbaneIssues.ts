import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Closes 4 open_issues (#36 Gold Coast, #133 Central Highlands, #143 Mount Isa, #170 Brisbane), all
 * resolved by re-reading text/research already held in this project -- no new document needed.
 *
 * #36: the project's own already-held researcher notes on CGC.gc_rural_* / CGC.gc_ec_* (currently DRAFT)
 * already answer the issue's own question: Table 1.5-1 (s1.5, ruleId 2203) designates the "Relevant zone
 * code" as the alternative to QDC's boundary clearance provisions for Buildings, with QDC applying only
 * "to any building or structure where an alternative setback is not provided in the above codes." The
 * Rural/EC zone codes DO provide their own general building setbacks, so those displace QDC MP1.2's
 * Class 10a-specific allowances entirely for sheds/garages/carports -- confirmed by the scheme's own
 * text, not merely certifier practice.
 *
 * #133: Blackwater/Blackwater East PDAs (Economic Development Act 2012) are the same category of
 * jurisdictional carve-out as Sunshine Coast's state PDAs (open_issues #95) -- already generically
 * handled statewide by the existing in_priority_development_area fact (engine.ts, sourced from the
 * statewide PDA GIS layer, used in db/021_state_rules.sql), not a Central-Highlands-specific gap.
 *
 * #143: re-extracted Mount Isa's Part 5 tables (5.5.3 Local centre, 5.5.4 Principal centre, 5.5.12 Mixed
 * use) directly from the held source PDF. The grouping convention is consistent and unambiguous across
 * every block in all three tables: [bulleted use list] -> [one shared "If..." condition], repeated with
 * no exceptions. The 50m2-expansion condition does attach to Dwelling house in all three zones.
 *
 * #170: documents an already-settled, deliberate client-directed decision (see
 * db/053_council_brisbane_withdraw_owner_consent_relaxation.sql) -- not a pending question. Re-confirmed
 * current status (BCC.C.SL_SIDE_ZERO_CONSENT@2026-09-18 remains WITHDRAWN) matches what was decided.
 */
export class CloseGoldCoastMountIsaCentralHighlandsBrisbaneIssues1700005640000 implements MigrationInterface {
  name = "CloseGoldCoastMountIsaCentralHighlandsBrisbaneIssues1700005640000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the project''s own already-held researcher notes on CGC.gc_rural_front_setback/side_setback/rear_setback/height/structure_height/pool_setback and CGC.gc_ec_front_setback/side_setback/rear_setback/height/structure_height/site_cover/pool_setback (all currently DRAFT, auto-imported). Each already states, in its own interpretation_notes written at extraction time: "Alternative provision to QDC/QHC: YES ... Table 1.5-1 (s1.5, ruleId 2203) ... lists ''Alternatives to QDC boundary clearance provisions'' -> ''Buildings: Relevant zone code ...''". Table 1.5-1''s own note reads: "QDC setbacks will apply to any building or structure where an alternative setback is not provided in the above codes." Since the Rural and Emerging Community zone codes DO provide their own general building setbacks (10m front/6m side-rear for Rural; 10m front/6m side-rear, or tiered height-based 6m/1.5m+ for subdivided EC lots), those scheme setbacks ARE "an alternative setback provided" under the scheme''s own Table 1.5-1 test -- so they displace QDC MP1.2''s Class 10a-specific boundary allowances (built-to-boundary, outbuilding floor-area tier, garage/carport height) entirely for sheds/garages/carports in these two zones. This is confirmed by the scheme''s own explicit text, not a matter requiring separate certifier-practice confirmation. These Rural/EC setback rules remain DRAFT pending full curation (site cover and corner-lot frontage definition questions are separate, already-flagged open items) -- but the interpretive question this issue asked is resolved.'
WHERE issue_id = 36 AND instrument_id = 'CGC_CITY_PLAN';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: confirmed the Blackwater and Blackwater East Priority Development Areas (Economic Development Act 2012) are the same category of jurisdictional carve-out as Sunshine Coast''s state PDAs (already resolved this session via open_issues #95) -- land inside a PDA is administered under its own PDA Development Scheme, outside the local planning scheme entirely, until revoked. This project already generically flags ANY PDA lot statewide via the existing in_priority_development_area fact (engine.ts, sourced from the statewide Priority Development Areas GIS layer, not council-specific), used in db/021_state_rules.sql to exclude QHC/QDC siting parts for a PDA lot. Not a Central-Highlands-specific coverage gap -- the mechanism already works correctly for Blackwater the same way it does for every other council''s PDA land. No fix needed.'
WHERE issue_id = 133 AND instrument_id = 'CHRC_PLANNING_SCHEME_2016';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-extracted the actual Part 5 table layout directly from the held source PDF (research/sources/MOUNT_ISA/city_of_mount_isa_planning_scheme__no_maps_.pdf, pdftotext -layout) for Table 5.5.3 (Local centre zone), Table 5.5.4 (Principal centre zone), and Table 5.5.12 (Mixed use zone). Confirmed the grouping is NOT actually ambiguous: every use-group block in every one of these tables follows the identical, consistent convention of [a bulleted use list] -> [one shared "If expanding the total use area of the existing use by less than 50m2 requiring: (a) no building work; or (b) minor building work." condition] -> [the next bulleted use list] -> [its own shared condition], with zero exceptions found across all three tables (contrast Table 5.5.1''s Low density residential zone, where Dwelling house is instead bulleted ALONE and so gets its own dedicated "If no secondary dwelling is proposed" condition -- a different grouping, consistently applied). So yes: the 50m2 expansion condition does attach to Dwelling house (grouped with Dual occupancy/Dwelling unit/Multiple dwelling/Residential care facility/Retirement facility/Rooming accommodation) in the Local centre, Principal centre, and Mixed use zones, confirming the open issue''s own stated default reading. Not an ambiguity in the PDF layout -- a standard, unexcepted drafting convention once compared across the table''s own other groups.'
WHERE issue_id = 143 AND instrument_id = 'MICC_PLANNING_SCHEME_2020';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: this entry documents an already-settled, deliberate client-directed decision (2026-11-06 Q&A, see db/053_council_brisbane_withdraw_owner_consent_relaxation.sql) -- not a pending question. BCC.C.SL_SIDE_ZERO_CONSENT was deliberately withdrawn from automated-evaluation candidacy because the underlying adjoining_owner_does_not_object fact (a neighbour-consent/building-certifier matter evidenced by a statutory declaration) was never wired into engine.ts/cli.ts/index.html by design, and was never going to be something this tool could ask the user about. Re-confirmed the rule''s current status (BCC.C.SL_SIDE_ZERO_CONSENT@2026-09-18 = WITHDRAWN) still matches that documented decision. No action needed -- closing as a provenance record only.'
WHERE issue_id = 170 AND instrument_id = 'BCC_CITY_PLAN_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
