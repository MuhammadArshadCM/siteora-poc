import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves 7 Gold Coast open_issues (#27, #28, #40, #42, #43, #51, #54), all by carefully re-reading text
 * this project already held in db/030_council_gold_coast.sql / research/councils/gold_coast.json (no new
 * document needed), plus one live GIS check for #54.
 */
export class CloseGoldCoastWordingIssuesBatch1700005280000 implements MigrationInterface {
  name = "CloseGoldCoastWordingIssuesBatch1700005280000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held verbatim text (gc_mdr_small_lot_setbacks). The small-lot setback table''s OWN column header states every value in the table is a "Minimum distance[] measured in metres" -- so "0.5m minimum" (Part B / AO1) is the textually-correct, internally-consistent reading, and "0.5m maximum" in Part A / RO1 is the drafting error (the research had already flagged this as "apparent drafting inconsistency" but the issue was never closed). Draft rule CGC.gc_mdr_small_lot_setbacks is still DRAFT (uncurated) -- when curated, use the minimum reading.'
WHERE issue_id = 27 AND instrument_id = 'CGC_CITY_PLAN';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held verbatim text. Every OTHER Dwelling house accepted-development row in this zone (the general, non-Large-lot table) uses AND (lot >= 400m2 AND not involving a secondary dwelling). Table 5.5.1(1)''s Large Lot precinct row uses OR instead -- but a Large Lot precinct''s own minimum lot sizes are always well above 400m2, so under "OR" the first disjunct is always true, making EVERY dwelling house in the precinct unconditionally Accepted regardless of a secondary dwelling -- an absurd result that would erase the secondary-dwelling distinction the rest of the scheme consistently draws. Confirmed: "OR" is a drafting error; the intended, consistent reading is AND, matching every other row in this table family.'
WHERE issue_id = 28 AND instrument_id = 'CGC_CITY_PLAN';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held research note on this exact provision (LOA Table 5.5.15; s5.3.2, Dwelling house (MCU) / Emerging community zone): a Dwelling house with a secondary dwelling GFA > 80m2 is genuinely not listed anywhere in Table 5.5.15, and s5.3.2 itself (the scheme''s own default-assessment-category mechanism) states an MCU not listed or defined in a table of assessment is impact assessable. This is not merely a presumption needing council verification -- s5.3.2 is the scheme''s own explicit, stated default rule, making the "impact assessable" conclusion a direct application of the scheme''s own text, not an inference.'
WHERE issue_id = 40 AND instrument_id = 'CGC_CITY_PLAN';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held verbatim text (gc_rural_building_height / gc_rural_structure_height, Rural zone code 6.2.20.3 Table 6.2.20-1 RO2; Table 6.2.20-2 AO2.1/AO2.2): both claims in this issue are CONFIRMED as deliberate scheme text, not drafting omissions needing a number. (1) RO2 (accepted development, Part A) states only "Building height does not exceed 2 storeys with a maximum height of 9m" -- it genuinely omits the partial-third-storey alternative that AO2.1 (Part B, assessable development) explicitly offers ("or a partial third storey if within 9m"); RO2 and AO2.1 really do differ. (2) For structures (non-building), the scheme states verbatim, twice, that there is no requirement at all: RO2 "For structures, no requirements for accepted development are provided" and AO2.2 "For structures, no acceptable outcome provided" -- Rural structures genuinely have no numeric height limit in the zone code (QDC/QHC governs instead, subject to the unresolved building-vs-structure classification question already flagged in the research notes). The existing draft rules already correctly reflect both findings (gc_rural_building_height uses 9m/2-storeys without the AO2.1 alternative; gc_rural_structure_height has an unencoded/null value with a note explaining the absence) -- no fix needed, just confirmation.'
WHERE issue_id = 42 AND instrument_id = 'CGC_CITY_PLAN';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held verbatim text (gc_ec_subdiv_lot_side/rear_setback_height_tiered). Confirmed typographical: Part A (RO1) reads "up to 4.5m" while Part B (AO1) reads "up to 4.5" (missing unit) in the identical height-tier row of the identical setback table -- the intended value is unambiguously 4.5m, matching RO1''s own unit and the surrounding identical tier structure. The existing draft rules already use the correct 4.5m threshold regardless of which part''s text is read -- no fix needed, just confirmation this is a simple missing-unit typo with no live impact.'
WHERE issue_id = 43 AND instrument_id = 'CGC_CITY_PLAN';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read the already-held research note on Table 5.5.18 (Limited development (constrained land) zone): this is confirmed even more directly than the analogous #40 (Emerging community) finding -- Table 5.5.18 itself contains an EXPLICIT Impact assessment catch-all row ("Any use listed in this table and not meeting the description listed in the use column"), which textually and directly captures a Dwelling house listed under "Accepted subject to requirements" that fails to meet that row''s own stated description (secondary dwelling GFA > 80m2). This is a direct textual match within the table itself, not an inference via s5.3.2''s generic default -- confirmed impact assessable.'
WHERE issue_id = 51 AND instrument_id = 'CGC_CITY_PLAN';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: checked live -- queried Gold Coast''s ArcGIS Online services directory (services-ap1.arcgis.com/lnVW0dLI3fvST2hd) directly. Confirmed open-data layers exist only up to City_Plan_Version_13_Open_Data (versions 8, 10, 11, 12, 13) -- no City_Plan_Version_14_Open_Data service exists at all. Version 13 is genuinely the most current open-data GIS layer the council publishes, not a stale source this project should have updated away from. The "None" precinct values and the absence of a separate HDR/LD precinct are consistent with the text-based v14 ePlan''s own table of contents, which likewise does not define a separate HDR/LD precinct -- no data gap, no fix needed.'
WHERE issue_id = 54 AND instrument_id = 'CGC_CITY_PLAN';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
