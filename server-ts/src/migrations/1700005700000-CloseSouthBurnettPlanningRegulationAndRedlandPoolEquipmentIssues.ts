import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Closes 2 open_issues (#154 South Burnett, #172 Redland).
 *
 * #154: fetched Planning Regulation 2017 Schedule 6 Part 2 section 2 directly (legislation.qld.gov.au,
 * current in-force consolidation) to check the open question's own premise. Section 2(2) limits when a
 * local categorising instrument CAN make a dwelling house material-change-of-use assessable, but its
 * own paragraph (a) condition reads (verbatim): "the material change of use is for a residential purpose
 * in a residential zone other than a medium density residential zone or high density residential zone".
 * South Burnett's Table 5.5.2 (the lot<400m2 / secondary-dwelling trigger this issue asked about) sits in
 * the Medium density residential zone code -- a zone section 2(2)(a) explicitly excludes by name. So
 * section 2's protection does not reach this zone at all; Sch 6 Pt 2 s2 places no constraint on Table
 * 5.5.2's triggers, which are fully effective as drafted.
 *
 * #172: re-read AO9.1's own verbatim text (already held): "Development (including domestic outbuildings
 * and other roofed structures, but excluding in-ground swimming pools) is setback a minimum of 9m...".
 * The operative term is "Development" (the broad, catch-all word) -- "including ... other roofed
 * structures" is a non-exhaustive clarifying example, not an exhaustive limitation, and the clause states
 * exactly one express carve-out ("excluding in-ground swimming pools"). Free-standing pool equipment
 * (pumps/filters/heaters) is "development" (at minimum operational/building work) and is not the
 * excluded item (the in-ground pool itself) -- so it is caught by the 9m setback the same as an
 * above-ground pool, deck, or outbuilding, by ordinary construction of an "including X but excluding Y"
 * clause (the same drafting-convention device already used this session for open_issues #64/#77/#82).
 */
export class CloseSouthBurnettPlanningRegulationAndRedlandPoolEquipmentIssues1700005700000 implements MigrationInterface {
  name = "CloseSouthBurnettPlanningRegulationAndRedlandPoolEquipmentIssues1700005700000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: fetched Planning Regulation 2017 Schedule 6 Part 2 section 2 directly from legislation.qld.gov.au (current in-force consolidation, 2026-09-11) to check this issue''s own premise. Section 2(2) limits when a local categorising instrument CAN make a dwelling house material-change-of-use assessable (rather than accepted development) -- but its paragraph (a) condition reads, verbatim: "the material change of use is for a residential purpose in a residential zone other than a medium density residential zone or high density residential zone [...]". South Burnett''s Table 5.5.2 (the lot < 400 m2 / secondary-dwelling trigger this issue asked about) sits in the Medium density residential zone code -- a zone section 2(2)(a) explicitly excludes by name (and section 2(4)(a) confirms a zone reference by name means the zone of that name in the Regulation''s own schedule 2, the standard QPP zone South Burnett''s own zone naming matches). So section 2''s "cannot be made assessable" protection does not reach the Medium density residential zone at all -- Sch 6 Pt 2 s2 places no constraint on Table 5.5.2''s lot-size/secondary-dwelling triggers, which are fully effective as drafted. Resolved; no fix needed.'
WHERE issue_id = 154 AND instrument_id = 'SBRC_PLANNING_SCHEME_2017';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: re-read AO9.1''s own already-held verbatim text: "Development (including domestic outbuildings and other roofed structures, but excluding in-ground swimming pools) is setback a minimum of 9m from the property boundary adjoining a canal or lake." The operative, catch-all term is "Development" -- "including ... domestic outbuildings and other roofed structures" is a non-exhaustive clarifying example of what counts (it does not narrow "Development" down to only roofed things), and the clause states exactly one express carve-out: "excluding in-ground swimming pools". Free-standing pool equipment (pumps/filters/heaters) is "development" in its own right (at minimum operational/building work installing fixed plant) and is not the one excluded item (the in-ground pool itself) -- so by ordinary construction of this "including X but excluding Y" clause, it IS caught by the 9m canal/lake setback, the same as an above-ground pool, deck, or domestic outbuilding would be. Resolved by the clause''s own drafting convention (the same device already used this session for open_issues #64/#77/#82) -- not a gap requiring external confirmation.'
WHERE issue_id = 172 AND instrument_id = 'RCC_CITY_PLAN_2018';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
