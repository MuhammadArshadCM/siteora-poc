import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Partially resolves open_issues #62 (Moreton Bay): Emerging community zone code (6.2.3) was never fetched at
 * all ("no CMB rule exists for it") -- user supplied the current Version 9 full-plan PDF (effective 2 Nov
 * 2026, confirmed "Status: Current" throughout, after two earlier downloads turned out to be the superseded
 * Version 8 export).
 *
 * The zone has three precincts (Interim; Transition, with developable/developed-lot sub-cases; Morayfield
 * South, with developable/developed-lot and Next generation/Urban neighbourhood sub-precincts) -- fetching
 * and curating every precinct's full setback/BTB/site-cover table is a much larger task than this migration
 * attempts. What IS encoded here: the "Dwelling house - Domestic outbuildings" clause (RAD48/50/PO57+E57/
 * PO60+E60 depending on precinct), confirmed VERBATIM-IDENTICAL across every precinct and lot-type checked
 * (Interim, Transition developable, Transition developed, Morayfield South developable) -- a genuine zone-wide
 * standard, not needing per-precinct duplication:
 *   "Domestic outbuildings: (a) have a total combined maximum roofed area [by lot-size band]; (b) have a
 *   maximum building height of 4m and a mean height not exceeding 3.5m; (c) are located behind the main
 *   building line and not within primary or secondary frontage or trafficable water body setbacks."
 * Mean height (b) is not encoded as a separate rule, matching this project's own existing precedent
 * (CMB.C.OUTBUILDING_HEIGHT's interpretation_notes: "Mean height limits ... not encoded as a separate rule").
 *
 * Also resolves, by confirming no content is missing (not by building anything):
 *   - Woodfordia local plan code (7.2.2): fetched and reviewed in full -- zero dwelling-house/Class 10a
 *     content. It is a tourism/events/rural-use precinct code (festival valley, event, eastern precincts)
 *     governed by landslide/overland-flow/infrastructure-buffer hazard overlays; its one passing mention of
 *     domestic outbuildings (RAD52) only exempts them from a landslide-area construction-method requirement
 *     (split-level/pier construction), not a siting figure.
 *   - Planning scheme policy - Residential design: confirmed advisory/methodological only (guidance on how to
 *     prepare a visual impact assessment for a qualitative performance outcome), not a source of mandatory
 *     numeric benchmarks, and not bundled as a standalone section in this full-plan export.
 *
 * Genuinely still open after this (left in open_issues #62, not closed): the rest of the Emerging community
 * zone code's own setback/BTB/site-cover tables, per precinct, remain unfetched/uncurated.
 */
export class MoretonBayEmergingCommunityOutbuildings1700004980000 implements MigrationInterface {
  name = "MoretonBayEmergingCommunityOutbuildings1700004980000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE instrument_versions SET
  version_label = 'Version 9 (Major Amendment No.4, eff. 2 Nov 2026)',
  notes = 'This project does not model a separate instrument_version row per scheme version, only per content-effective-date -- content originally captured under this row when it was Version 8 (LGIP Amendment No. 2) has had Version 9 content (incl. db/069, this migration) layered in without creating a new row. version_label updated 2026-11-17 to reflect that Version 9 is now current (confirmed via a fresh full-plan export, Status: Current).'
WHERE instrument_version_id = 'MBRC_PLANNING_SCHEME_2016@2026-09-11';

SELECT define_provision('MBRC_PLANNING_SCHEME_2016@2026-09-11', '6.2.3 Emerging community zone code -- Dwelling house, Domestic outbuildings', 'ACCEPTED_DEVELOPMENT_REQUIREMENT',
  $q$Dwelling house - Domestic outbuildings. RAD48/50 (confirmed identical wording in the Interim, Transition developable, Transition developed and Morayfield South developable precincts): Domestic outbuildings: a. have a total combined maximum roofed area as outlined in the table below: Size of lot / Max. Roofed Area -- Less than 600m2: 50m2; 600m2-1000m2: 70m2; Greater than 1000m2-2000m2: 80m2; Greater than 2000m2: 150m2. b. have a maximum building height of 4m and a mean height not exceeding 3.5m. c. are located behind the main building line and not within primary or secondary frontage or trafficable water body setbacks.$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL,
  'https://eplan.moretonbay.qld.gov.au/',
  'Confirmed verbatim-identical across every precinct/lot-type checked in Version 9 (effective 2 Nov 2026) -- encoded zone-wide rather than per-precinct.');

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, vertical_projection, evaluate_per_part, notes) VALUES
  ('CMB_EC_OUTBUILDING_MAIN_BUILDING_LINE_POSITION', 'PRESENCE', 'CLASS_10A_POSITION', NULL, false, false,
   'Whether a domestic outbuilding in the Emerging community zone sits behind the main building line and outside the primary/secondary frontage and trafficable water body setbacks.');

SELECT define_rule($r\${
 "rule_id": "CMB.C.EC_OUTBUILDING_SIZE", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "OUTBUILDING.SIZE", "title": "Emerging community zone: domestic outbuilding max combined roofed area by lot size",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "unit": "m2",
 "value": {"op": "lookup_range", "x": {"var": "lot_area_m2"}, "rows": [
    {"max": 599.999, "value": 50}, {"min": 600, "max": 1000, "value": 70},
    {"min": 1000.001, "max": 2000, "value": 80}, {"min": 2000.001, "value": 150}]},
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:EMERGING_COMMUNITY"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "sources": [{"ref": "6.2.3 Emerging community zone code -- Dwelling house, Domestic outbuildings", "role": "PRIMARY"}],
 "interpretation_notes": "RAD48/50(a) (and its PO57/PO60 assessable-development mirrors). Combined total across all domestic outbuildings on the lot. Confirmed identical in every precinct/lot-type checked.",
 "effective_from": "2026-09-11"}$r\$);

SELECT define_rule($r\${
 "rule_id": "CMB.C.EC_OUTBUILDING_HEIGHT", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "OUTBUILDING.HEIGHT", "title": "Emerging community zone: domestic outbuilding max height 4 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 4, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:EMERGING_COMMUNITY"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "sources": [{"ref": "6.2.3 Emerging community zone code -- Dwelling house, Domestic outbuildings", "role": "PRIMARY"}],
 "interpretation_notes": "RAD48/50(b). Unlike the General Residential zone's RAD26 (CMB.C.OUTBUILDING_HEIGHT), the Emerging community clause has no reduced 3.3m carport-in-front-of-building-line carve-out -- item (c) instead bars ANY domestic outbuilding from being in front of the main building line at all (see CMB.C.EC_OUTBUILDING_MAIN_BUILDING_LINE_POSITION). Mean height (3.5m) not encoded as a separate rule, matching CMB.C.OUTBUILDING_HEIGHT's own precedent.",
 "effective_from": "2026-09-11"}$r\$);
SELECT alt_overrides('CMB.C.EC_OUTBUILDING_HEIGHT@2026-09-11', ARRAY['QDC12.A4.BUILDING_HEIGHT','QDC11.A4.BUILDING_HEIGHT'], 'Same basis as CMB.C.OUTBUILDING_HEIGHT: Table 1.6.1, zone codes hold alternative provisions to QDC, and this is a more restrictive Class-10a-specific height limit than the QDC''s general 8.5-10m building height.');

SELECT define_rule($r\${
 "rule_id": "CMB.C.EC_OUTBUILDING_MAIN_BUILDING_LINE_POSITION", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.FRONTAGE", "title": "Emerging community zone: domestic outbuilding must be behind the main building line, outside frontage and trafficable water body setbacks",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
 "measurement": "CMB_EC_OUTBUILDING_MAIN_BUILDING_LINE_POSITION", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:EMERGING_COMMUNITY"}],
 "subjects": ["SHED", "GARAGE", "CARPORT", "CLASS_10A_OTHER"],
 "sources": [{"ref": "6.2.3 Emerging community zone code -- Dwelling house, Domestic outbuildings", "role": "PRIMARY"}],
 "interpretation_notes": "RAD48/50(c). A trafficable water body boundary is treated the same as a secondary frontage for determining the main building line (the zone code''s own note). automatable=false: position relative to the dwelling''s own main building line is not geometry this engine derives (same limitation as Ipswich''s Character Overlay Area A/B rules built earlier this session).",
 "effective_from": "2026-09-11"}$r\$);

UPDATE open_issues SET
  description = 'PARTIALLY RESOLVED 2026-11-17: user supplied the current Version 9 full-plan PDF (effective 2 Nov 2026, confirmed Current/not superseded -- two earlier downloads had been the superseded Version 8 export). Emerging community zone code (6.2.3): fetched; its one zone-wide, precinct-identical Class 10a standard (domestic outbuilding roofed area by lot-size band, 4m height, behind-main-building-line position -- RAD48/50) is now encoded (CMB.C.EC_OUTBUILDING_SIZE/_HEIGHT/_MAIN_BUILDING_LINE_POSITION). Genuinely still open: the rest of the zone''s own setback/BTB/site-cover tables, which differ across its three precincts (Interim; Transition developable/developed; Morayfield South developable/developed with Next generation/Urban neighbourhood sub-precincts) and were not attempted in this pass. Woodfordia local plan: fetched and reviewed in full -- confirmed ZERO dwelling-house/Class 10a content (a tourism/events/rural-use precinct code under landslide/overland-flow hazard overlays); no rule needed, this part is closed. Planning scheme policy - Residential design: confirmed advisory/methodological only (visual impact assessment guidance for a qualitative performance outcome, not a numeric benchmark, and not bundled separately in this export); no rule needed, this part is closed.'
WHERE issue_id = 62 AND instrument_id = 'MBRC_PLANNING_SCHEME_2016';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
