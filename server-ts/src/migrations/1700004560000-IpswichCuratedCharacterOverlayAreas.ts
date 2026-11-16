import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Activates 4 Ipswich Character Places and Areas Overlay (OV3) carport/outbuilding placement rules
 * (RO1.1-RO1.4, db/030_council_ipswich.sql) that have sat in DRAFT since the research was first captured --
 * never curated because the researcher's own note said "Areas A-D are shown on Figure 8.2.3.3.20.1 (image
 * not extracted)", so what each area physically meant was unconfirmed (open_issues #112).
 *
 * User supplied a screenshot of the actual figure (2026-11-16), confirming:
 *   Area A = rear of the main building; Area B = side of the main building; Area C = front, only where
 *   existing side setbacks are < 3m and side/rear access isn't possible; Area D = secondary frontage of a
 *   corner lot.
 *
 * Area D (is_corner_lot) is the only one of the four with a clean existing engine fact to gate on -- added as
 * a real condition. Areas A/B/C have no corresponding fact (rear/side-of-dwelling position, or an existing
 * dwelling's own side-setback distance) and stay automatable=false/MANUAL_REVIEW with the precondition spelled
 * out in interpretation_notes, same convention as every other geometry-outside-this-tool's-model rule in this
 * project.
 *
 * Also corrects two drafting mistakes found while curating, both directly supported by the verbatim text
 * already held in db/030 (not new research):
 *   - Area D's draft used measurement SCHEME_SETBACK_SECONDARY_FRONTAGE with a flat value of 6 -- but the
 *     source text is a carport SIZE limit (max 6m wide AND 6m long), not a setback distance. Corrected to
 *     SCHEME_GARAGE_CARPORT (the composite size/setback measurement already used by Areas B and C), with the
 *     same width+length structure Area C already uses.
 *   - Area B's draft subjects included CLASS_1 (dwelling) and Area D's included "ANY" -- neither matches their
 *     own quoted text ("Open Class 10 buildings...including car accommodation" for B; "a single or double
 *     width carport" for D). Area C's draft also included CLASS_1 despite its text saying "a single carport".
 *     Corrected: B -> ANY (matches Area A's equally broad Class 10 scope, not car-accommodation-only);
 *     C, D -> CARPORT (both texts name only carports, not sheds/other Class 10).
 */
export class IpswichCuratedCharacterOverlayAreas1700004560000 implements MigrationInterface {
  name = "IpswichCuratedCharacterOverlayAreas1700004560000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

SELECT define_rule($r\${
 "rule_id": "ICC.C.CHAR_OV3_AREA_A_CLASS10_REAR", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "OUTBUILDING.SIZE", "title": "Character Places and Areas Overlay: Class 10 buildings/structures to the rear of the dwelling (Area A) — max 50% of dwelling GFA",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "value": 50, "unit": "% of existing main building GFA",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "OVERLAY", "overlay": "ICC:OV:OV3_CHARACTER_PLACES_AND_AREAS_OVERLAY"}],
 "subjects": ["ANY"],
 "sources": [{"key": "char_ro1_1_class10_rear_area_a", "role": "PRIMARY"}],
 "interpretation_notes": "CURATED 2026-11-16 (was DRAFT, open_issues #112): Area A = rear of the main building, confirmed by Figure 8.2.3.3.20.1 (user-supplied screenshot). RO1.1: Class 10 buildings/structures (open or enclosed, incl. car accommodation, sheds, pools) may be located here, detached from the main building, with a GFA no greater than 50% of the existing main building's GFA. Only applies within the OV3 Character Places and Areas Overlay footprint. automatable=false: which part of a lot is \\\"the rear of the main building\\\" is not a fact this engine currently derives.",
 "effective_from": "2026-07-01"}$r\$);
SELECT supersede_draft('ICC.C.CHAR_OV3_AREA_A_CLASS10_REAR@2026-07-01', 'ICC.char_ro1_1_class10_rear_area_a');

SELECT define_rule($r\${
 "rule_id": "ICC.C.CHAR_OV3_AREA_B_CLASS10_SIDE", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "GARAGE.FRONTAGE", "title": "Character Places and Areas Overlay: open Class 10 buildings/structures beside the dwelling (Area B) — design form requirements, max 6 m wide",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_GARAGE_CARPORT", "operator": "<=", "value": 6, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "OVERLAY", "overlay": "ICC:OV:OV3_CHARACTER_PLACES_AND_AREAS_OVERLAY"}],
 "subjects": ["ANY"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "SIDE"}]],
 "sources": [{"key": "char_ro1_2_class10_side_area_b", "role": "PRIMARY"}],
 "interpretation_notes": "CURATED 2026-11-16 (was DRAFT, open_issues #112): Area B = side of the main building, confirmed by Figure 8.2.3.3.20.1. RO1.2: open (or partially enclosed) Class 10 buildings/structures, including but not limited to car accommodation -- subject corrected from the draft's [CLASS_10A, CLASS_1] to ANY, matching Area A's equally broad scope (the text is not car-accommodation-only). Gated on boundary_type=SIDE (added during curation -- the draft had no boundary condition at all, which would have repeated this rule once per boundary context instead of only the side). Detached, open/battened facing the street, aligned with or set back behind the internal verandah wall line, max 6m wide; where roofed: pitch >=15deg, gable/hip form, overhangs >=300mm, matching roofing/guttering, 100x100mm posts; where enclosed: battens/doors facing the street >=30% transparent, enclosed parts at the rear. automatable=false (design/material facts this engine does not collect).",
 "effective_from": "2026-07-01"}$r\$);
SELECT supersede_draft('ICC.C.CHAR_OV3_AREA_B_CLASS10_SIDE@2026-07-01', 'ICC.char_ro1_2_class10_side_area_b');

SELECT define_rule($r\${
 "rule_id": "ICC.C.CHAR_OV3_AREA_C_CARPORT_FRONT_NARROW_SETBACK", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "GARAGE.FRONTAGE", "title": "Character Places and Areas Overlay: single carport forward of the dwelling where side setbacks are narrow (Area C) — max 3.6 m x 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_GARAGE_CARPORT", "operator": "<=",
 "value": {"op": "unencoded", "text": "width<=3.6m AND length<=6m", "extracted_value": null, "extracted_operator": "<="},
 "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "OVERLAY", "overlay": "ICC:OV:OV3_CHARACTER_PLACES_AND_AREAS_OVERLAY"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"key": "char_ro1_3_carport_front_area_c", "role": "PRIMARY"}],
 "interpretation_notes": "CURATED 2026-11-16 (was DRAFT, open_issues #112): Area C = forward of the dwelling, only available where the existing dwelling's side setbacks are < 3m AND side/rear access is not possible, confirmed by Figure 8.2.3.3.20.1. Subject corrected from the draft's [CLASS_10A, CLASS_1] to CARPORT (the text names only 'a single carport'). Gated on boundary_type=PRIMARY_FRONTAGE (added during curation, same reasoning as Area B) -- the < 3m existing-side-setback precondition itself is a fact about the EXISTING dwelling, not modelled by this engine, so it stays a manual precondition rather than a coded condition. Max 3.6m wide x 6m long, detached, roof pitch matching the main building, overhangs >=300mm, gable/hip form, matching roofing/guttering, 100x100mm posts; may be enclosed with >=30% transparent battens/doors facing the street. automatable=false.",
 "effective_from": "2026-07-01"}$r\$);
SELECT supersede_draft('ICC.C.CHAR_OV3_AREA_C_CARPORT_FRONT_NARROW_SETBACK@2026-07-01', 'ICC.char_ro1_3_carport_front_area_c');

SELECT define_rule($r\${
 "rule_id": "ICC.C.CHAR_OV3_AREA_D_CARPORT_SECONDARY_FRONTAGE_CORNER", "instrument_version": "ICC_CITY_PLAN_2025@2026-07-01",
 "topic": "GARAGE.FRONTAGE", "title": "Character Places and Areas Overlay: carport on the secondary frontage of a corner lot (Area D) — max 6 m x 6 m",
 "role": "REQUIREMENT", "regime": "PLANNING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_GARAGE_CARPORT", "operator": "<=",
 "value": {"op": "unencoded", "text": "width<=6m AND length<=6m", "extracted_value": null, "extracted_operator": "<="},
 "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "IPSWICH"}, {"level": "OVERLAY", "overlay": "ICC:OV:OV3_CHARACTER_PLACES_AND_AREAS_OVERLAY"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"key": "char_ro1_4_carport_secondary_frontage_area_d", "role": "PRIMARY"}],
 "interpretation_notes": "CURATED 2026-11-16 (was DRAFT, open_issues #112): Area D = secondary frontage of a corner lot, confirmed by Figure 8.2.3.3.20.1. Corrections from the draft: (1) subject ANY -> CARPORT (text names only 'a single or double width carport'); (2) measurement SCHEME_SETBACK_SECONDARY_FRONTAGE with a flat value of 6 -> SCHEME_GARAGE_CARPORT with a width+length pair, matching Area C's structure -- the source text is a SIZE limit (max 6m wide and 6m long), not a setback distance; (3) added boundary_type=SECONDARY_FRONTAGE_ROAD alongside is_corner_lot (both in the same AND group) -- is_corner_lot alone would still repeat this rule once per boundary context on a corner lot, not just the secondary frontage. Single carport: single gable roof; double carport: paired gabled/hipped roofs of equal width facing the secondary frontage; roof pitch matching the main building, overhangs >=300mm, matching roofing/guttering, 100x100mm posts. automatable=false (design-form facts this engine does not collect).",
 "effective_from": "2026-07-01"}$r\$);
SELECT supersede_draft('ICC.C.CHAR_OV3_AREA_D_CARPORT_SECONDARY_FRONTAGE_CORNER@2026-07-01', 'ICC.char_ro1_4_carport_secondary_frontage_area_d');

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: user supplied screenshots confirming (1) the precinct for a test address (52 Suncrest Mews, Redbank Plains) is correctly determinable as New Suburban via the ePlan Zones and Precincts panel; (2) the OV6 Building Height Density overlay carries per-lot Storeys/Min Lot Size/Density Code attributes (map-only, confirmed, not yet GIS-wired -- separate from this fix); (3) Figure 8.2.3.3.20.1 (\"Placement of Class 10 Buildings and Structures\") confirms Areas A-D = rear / side / narrow-setback front / corner-lot secondary frontage respectively. That confirmation was enough to curate and activate 4 previously-DRAFT rules this project already held verbatim text for (ICC.C.CHAR_OV3_AREA_A/B/C/D..., superseding ICC.char_ro1_1 through _4) -- these had sat inactive specifically because the figure was unconfirmed. OV6''s numeric mapped height remains map-only/not GIS-wired (would need the same value_fact mechanism already used for Sunshine Coast/Gold Coast/Moreton Bay height overlays) -- left as a separate, smaller follow-up, not blocking this closure.'
WHERE issue_id = 112 AND instrument_id = 'ICC_CITY_PLAN_2025';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
