import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Narrows open_issues #1 (AS 1926.1-2007 pool-barrier detail figures paywalled, "no numeric values
 * recorded"). Two different fixes, kept clearly distinguished by verification tier:
 *
 * 1. QDC MP 3.4 itself already restates several AS 1926.1 figures directly in its own schedule/figures
 *    -- this project already captured that text VERIFIED_VERBATIM / VERIFIED_FROM_FIGURE in db/020 (Sch 1
 *    item 13, Sch 1 item 21, Figure 1's labels) but never promoted it into active rules. No new source
 *    needed for these three -- just finishing work already on hand:
 *      - MP34.S1_13.NCZ_HORIZONTAL_MEMBER_GAP_900: the non-climbable zone's own 900mm figure (MP 3.4's
 *        schedule substitutes 900mm for AS 1926.1's default 1000mm).
 *      - MP34.FIG1.CLEAR_AREA_FOOTHOLD_300: Figure 1's "Clear area (300mm)" foothold-clearance label.
 *      - MP34.S1_21.DESIGNATED_ACCESS_POINT: a designated, barrier-enclosed pool access point is required.
 *
 * 2. The maximum-gap and ground-clearance figures genuinely are NOT restated anywhere in MP 3.4 itself --
 *    they live only in AS 1926.1-2007's own body text, which remains paywalled and unheld. Sourced instead
 *    from the Queensland Building and Construction Commission's own public consumer guidance (QBCC is the
 *    state's building regulator, not a random secondary source, but this is still its own plain-English
 *    restatement of the Standard, not the Standard's primary text) -- tagged COUNCIL_FACTSHEET, the
 *    verification tier this project already uses for "official but not primary-legislative-text"
 *    government guidance, deliberately NOT VERIFIED_VERBATIM:
 *      - MP34.AS1926.BARRIER_MAX_GAP_100: no gap greater than 100mm anywhere in the barrier.
 *      - MP34.AS1926.BARRIER_GROUND_GAP_100: max 100mm gap from ground level to the bottom of the barrier.
 *
 * Still genuinely missing after this (left open, not invented): exact latch height above ground and
 * hinge-tamper-resistance specifications -- not stated on any free government source found, only on
 * unverified commercial pool-builder pages. docs/06-pool-rules.md is updated separately to reflect the
 * narrowed gap.
 */
export class PoolBarrierAdditionalFigures1700004020000 implements MigrationInterface {
  name = "PoolBarrierAdditionalFigures1700004020000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, vertical_projection, evaluate_per_part, notes) VALUES
  ('POOL_BARRIER_NCZ_GAP', 'EXCLUSION_ZONE', 'POOL_BARRIER_NON_CLIMBABLE_ZONE', NULL, false, false,
   'The non-climbable zone''s own clear-gap dimension (MP 3.4 Sch 1 item 13 substitutes 900mm for AS 1926.1''s default 1000mm, measured top-surface to top-surface of horizontal members).'),
  ('POOL_BARRIER_FOOTHOLD_CLEARANCE', 'EXCLUSION_ZONE', 'POOL_BARRIER_CLEAR_AREA', NULL, false, false,
   'Clear area free of footholds/climbable objects, per Figure 1''s "Clear area (300mm)" label and Sch 1 items 8-10 (extends 900mm beyond fence ends/intersections where the NCZ is on the outside).'),
  ('POOL_ACCESS_POINT_ENCLOSED', 'PRESENCE', 'POOL_ACCESS_POINT', NULL, false, false,
   'A designated swimming pool access point, enclosed by a barrier (incl. a compliant gate), per Sch 1 item 21.'),
  ('POOL_BARRIER_MAX_GAP', 'WIDTH', 'POOL_BARRIER_OPENING', NULL, false, false,
   'Maximum gap/hole anywhere in the barrier. NOT restated in MP 3.4 itself -- sourced from QBCC consumer guidance restating AS 1926.1-2007, which remains unheld/paywalled; see this rule''s interpretation_notes.'),
  ('POOL_BARRIER_GROUND_GAP', 'WIDTH', 'POOL_BARRIER_BOTTOM_EDGE', NULL, false, false,
   'Maximum gap from finished ground level to the bottom of the barrier. NOT restated in MP 3.4 itself -- sourced from QBCC consumer guidance restating AS 1926.1-2007, which remains unheld/paywalled; see this rule''s interpretation_notes.');

SELECT define_rule($r\${
 "rule_id": "MP34.S1_13.NCZ_HORIZONTAL_MEMBER_GAP_900", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_NCZ", "title": "Non-climbable zone: clear gap between horizontal members >= 900 mm",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "measurement": "POOL_BARRIER_NCZ_GAP", "operator": ">=", "value": 900, "unit": "mm",
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_FENCE"],
 "sources": [{"ref": "Sch 1 item 13", "role": "PRIMARY"}, {"ref": "Figure 1", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "The 900mm figure IS held verbatim in this project (db/020, Sch 1 item 13: 'The dimension of 900 millimetres applies instead of 1000 millimetres...'), confirmed by Figure 1's own '900mm NCZ' label -- this rule was simply never promoted from provision to active rule before now. automatable=false, matching the rest of this rule family: whether a given fence's actual member spacing meets this is a design/as-built fact this tool cannot verify from plan geometry alone.",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r\${
 "rule_id": "MP34.FIG1.CLEAR_AREA_FOOTHOLD_300", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_NCZ", "title": "Non-climbable zone: clear area free of footholds/climbable objects >= 300 mm",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "FIGURE",
 "measurement": "POOL_BARRIER_FOOTHOLD_CLEARANCE", "operator": ">=", "value": 300, "unit": "mm",
 "on_noncompliance": "FAIL", "verification": "VERIFIED_FROM_FIGURE", "automatable": false,
 "subjects": ["POOL_FENCE"],
 "sources": [{"ref": "Figure 1", "role": "PRIMARY"}, {"ref": "Sch 1 items 8-10", "role": "SUPPLEMENTARY"}],
 "interpretation_notes": "Figure 1's label: 'Clear area (300mm) No nearby horizontal surfaces which could be used as holds for climbing in this area if fence uprights more than 10mm apart' -- the 10mm upright-spacing detail is a condition on WHEN this clearance matters (gated on an as-built fact this tool cannot see), not a separate general gap rule, so it is noted here rather than encoded as its own check. Where the NCZ sits outside the fence, Sch 1 items 9-10 extend this clear area 900mm beyond the fence's ends and past any intersection with another barrier/object. automatable=false, same reasoning as MP34.S1_13.",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r\${
 "rule_id": "MP34.S1_21.DESIGNATED_ACCESS_POINT", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_ACCESS", "title": "A designated pool access point, enclosed by a compliant barrier and gate, must be provided",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "measurement": "POOL_ACCESS_POINT_ENCLOSED", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_BARRIER"],
 "sources": [{"ref": "Sch 1 item 21", "role": "PRIMARY"}],
 "interpretation_notes": "'In addition to the requirements of clause 2.10, a designated swimming pool access point must be provided, regardless of whether or not a permanent access ladder is installed. The access point must be enclosed by a barrier, including a gate that complies with this part.' automatable=false: existence/placement of a designated access point is a design fact, not derivable from siting geometry.",
 "effective_from": "2012-07-27"}$r$);

SELECT define_provision('QDC_MP_3_4@2012-07-27', 'QBCC pool fences guidance', 'OTHER',
  $q$it has no holes or gaps greater than 100mm in any direction. Where outside rails are at least 900mm apart, vertical elements can be up to 100mm apart.$q$,
  'COUNCIL_FACTSHEET', NULL, NULL, NULL, NULL, 'https://www.qbcc.qld.gov.au/pools/pool-fences',
  $q$Secondary government restatement of AS 1926.1-2007 (which remains unheld/paywalled, open_issues #1), not QDC MP 3.4's own text. QBCC is the Queensland building regulator; use as a practical figure, not as primary-source-verified for a dispute.$q$);

SELECT define_rule($r\${
 "rule_id": "MP34.AS1926.BARRIER_MAX_GAP_100", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_CONSTRUCTION", "title": "No gap or hole greater than 100 mm anywhere in the pool barrier",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "OTHER",
 "measurement": "POOL_BARRIER_MAX_GAP", "operator": "<=", "value": 100, "unit": "mm",
 "on_noncompliance": "FAIL", "verification": "COUNCIL_FACTSHEET", "automatable": false,
 "subjects": ["POOL_FENCE"],
 "sources": [{"ref": "QBCC pool fences guidance", "role": "PRIMARY", "quote": "it has no holes or gaps greater than 100mm in any direction. Where outside rails are at least 900mm apart, vertical elements can be up to 100mm apart.", "url": "https://www.qbcc.qld.gov.au/pools/pool-fences"}],
 "interpretation_notes": "NOT restated in QDC MP 3.4's own held text (db/020) -- this figure lives only in AS 1926.1-2007 itself, which remains paywalled/unheld (open_issues #1). Sourced instead from QBCC (Queensland's own building regulator)'s public consumer guidance, which restates AS 1926.1's requirement for consumers -- tagged COUNCIL_FACTSHEET (not VERIFIED_VERBATIM) to be explicit this is a secondary government restatement, not the primary Standard text. Treat as a reliable practical figure, but confirm against a purchased copy of AS 1926.1-2007 before treating it as legally dispositive in a dispute. automatable=false, same reasoning as the rest of this family.",
 "effective_from": "2012-07-27"}$r$);

SELECT define_rule($r\${
 "rule_id": "MP34.AS1926.BARRIER_GROUND_GAP_100", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_CONSTRUCTION", "title": "Maximum 100 mm gap from finished ground level to the bottom of the pool barrier",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "OTHER",
 "measurement": "POOL_BARRIER_GROUND_GAP", "operator": "<=", "value": 100, "unit": "mm",
 "on_noncompliance": "FAIL", "verification": "COUNCIL_FACTSHEET", "automatable": false,
 "subjects": ["POOL_FENCE"],
 "sources": [{"ref": "QBCC pool fences guidance", "role": "PRIMARY", "quote": "maximum gap of 100mm from finished ground level to bottom of barrier", "url": "https://www.qbcc.qld.gov.au/pools/pool-fences"}],
 "interpretation_notes": "NOT restated in QDC MP 3.4's own held text (db/020) -- this figure lives only in AS 1926.1-2007 itself, which remains paywalled/unheld (open_issues #1). Sourced instead from QBCC (Queensland's own building regulator)'s public consumer guidance -- tagged COUNCIL_FACTSHEET (not VERIFIED_VERBATIM), same caveat as MP34.AS1926.BARRIER_MAX_GAP_100. automatable=false.",
 "effective_from": "2012-07-27"}$r$);

UPDATE open_issues SET description =
  $q$NARROWED 2026-11-14 (was: "no numeric values recorded"): QDC MP 3.4's own held text (db/020) already restated, and this project has now activated, the NCZ 900mm gap (MP34.S1_13), the 300mm foothold clear-area (MP34.FIG1), and the designated-access-point requirement (MP34.S1_21). The maximum-gap-in-barrier and ground-clearance figures (both 100mm) are now also encoded, sourced from QBCC's public consumer guidance (COUNCIL_FACTSHEET tier, not VERIFIED_VERBATIM, since AS 1926.1-2007 itself remains paywalled). Genuinely still missing, not found on any free government source: exact gate latch height above ground, and hinge tamper-resistance specifications. Obtain a licensed copy of AS 1926.1-2007 to verify the two 100mm COUNCIL_FACTSHEET figures against the primary Standard and to fill the latch-height/hinge gap, or confirm via a Queensland pool safety certifier.$q$
WHERE issue_id = 1 AND instrument_id = 'AS_1926_1_2007';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
