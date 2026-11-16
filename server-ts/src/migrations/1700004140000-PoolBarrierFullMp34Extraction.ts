import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Full re-extraction of QDC MP 3.4 against the user's own local copy (39 pages; pages 7-39 are figures only,
 * no extractable text — the complete Schedule 1 is items 1-30, all on pages 1-6). db/020/062 had already
 * captured items 1, 6-10, 12, 13, 15, 21 and the P1/A1 performance criteria -- this migration adds everything
 * else in Schedule 1 that is a real, independent requirement (not a bare terminology/definition substitution,
 * which is interpretive plumbing, not something this engine evaluates):
 *
 *   - Gate latch height/clearance -- NOT a Schedule 1 item at all: A1(b) itself says the Acceptable Solution
 *     is "subject to ... (b) tolerance limits specified in a guideline for swimming pool barriers made under
 *     section 258 of the Building Act 1975" -- i.e. MP 3.4 EXPLICITLY INCORPORATES that guideline BY
 *     REFERENCE for exactly this kind of figure, which makes it as authoritative as MP 3.4 itself for this
 *     purpose, not just a helpful secondary source. The guideline (housing.qld.gov.au, "Guideline for pool
 *     owners and property agents", effective 10 June 2024) states the actual figure. Upgrades
 *     MP34.AS1926.BARRIER_MAX_GAP_100 / GROUND_GAP_100 (db/069-equivalent TypeORM migration
 *     PoolBarrierAdditionalFigures) to cite this stronger source too, alongside QBCC -- VERIFIED_VERBATIM now,
 *     not COUNCIL_FACTSHEET, since A1(b) itself designates this document as part of the Acceptable Solution.
 *   - Item 16: a retaining wall used as a barrier needs overhang/return fencing with no foothold/handhold.
 *   - Item 17: a canal/lake/river/creek/stream/pond/ocean/dam may form part of the barrier itself, under
 *     detailed conditions (depth, width, no under/over access, overhang or return at the water's edge). This
 *     is a BARRIER-COMPLIANCE question (can the water body stand in for a physical fence on that side) --
 *     genuinely new, and distinct from this project's existing canal SITING setbacks (SCC.C.CANAL_SETBACK_4_5,
 *     RCC.C.LDR5_CANAL_LAKE_9M), which answer "how far from the canal can the pool go," not "can the canal
 *     itself be the safety barrier."
 *   - Items 19-20: an additional NCZ (Figure 23) is needed for balcony pools unless the balcony itself has a
 *     compliant barrier.
 *   - Item 26: indoor-pool access must be via a child-resistant doorset (or another compliant barrier) --
 *     supplements the existing MP34.P1e.NO_BUILDING_DOORS indoor-pool exception.
 *
 * NOT encoded (reviewed, correctly out of scope -- interpretive terminology substitutions, not independent
 * requirements this engine evaluates): items 2-5 (definitions, temporary-fence approval process -- process,
 * not a design figure), 9-10/8/12/13/15/21 already encoded, 14 (figure-only substitution), 18 (clause 2.8
 * exclusion, no remaining content), 22 (900mm-for-1000mm substitution restated for Appendix D -- same figure
 * already covered by item 13), 23-24 (AS 1926.2:2007 "location of barriers" is mostly DISAPPLIED by MP 3.4
 * itself -- item 23 switches off AS1926.2 clauses 3.3/3.6/3.7/4.3/4.4.2/Appendix A entirely, item 24 is just a
 * definition substitution -- so there is no hidden trove of AS1926.2 siting rules being missed), 25/27
 * (terminology substitutions), 28-30 (already reflected in MP34.P1e.NO_BUILDING_DOORS's interpretation_notes).
 */
export class PoolBarrierFullMp34Extraction1700004140000 implements MigrationInterface {
  name = "PoolBarrierFullMp34Extraction1700004140000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, vertical_projection, evaluate_per_part, notes) VALUES
  ('POOL_GATE_LATCH_HEIGHT', 'MAX_VERTICAL_HEIGHT', 'POOL_GATE_LATCH_UNDERSIDE', NULL, true, false,
   'Height of the underside of a gate latch release above ground, and above the highest lower rail -- MP 3.4 A1(b) incorporates the s258 BA guideline''s tolerance limits by reference for this figure.'),
  ('POOL_RETAINING_WALL_BARRIER_NO_FOOTHOLD', 'PRESENCE', 'POOL_RETAINING_WALL_OVERHANG_RETURN_FENCING', NULL, false, false,
   'Presence of a no-foothold/no-handhold surface on overhang or return fencing atop a retaining wall used as part of a pool barrier (Sch 1 item 16).'),
  ('POOL_WATER_BODY_AS_BARRIER', 'PRESENCE', 'POOL_ADJOINING_WATER_BODY', NULL, false, false,
   'Presence of the conditions under which a canal/lake/river/creek/stream/pond/ocean/dam may form part of a pool barrier (Sch 1 item 17) -- a barrier-COMPLIANCE question, not a siting setback.'),
  ('POOL_BALCONY_NCZ', 'PRESENCE', 'POOL_BALCONY_NON_CLIMBABLE_ZONE', NULL, false, false,
   'Presence of the additional non-climbable zone (Figure 23) required for a balcony pool, unless the balcony itself has a compliant barrier (Sch 1 items 19-20).'),
  ('POOL_INDOOR_CHILD_RESISTANT_DOORSET', 'PRESENCE', 'POOL_INDOOR_ACCESS_DOORSET', NULL, false, false,
   'Presence of a compliant child-resistant doorset (or another compliant barrier) for access to an indoor swimming pool (Sch 1 item 26) -- supplements MP34.P1e.NO_BUILDING_DOORS.');

SELECT define_provision('QDC_MP_3_4@2012-07-27', 'A1(b) + Guideline for pool owners and property agents (s258 BA), Fencing gates and latches', 'ACCEPTABLE_SOLUTION',
  $q$A1(b): the acceptable solution is subject to tolerance limits specified in a guideline for swimming pool barriers made under section 258 of the Building Act 1975. Guideline text (effective 10 June 2024): "Gates must self-close and self-latch when released from all open positions and not open towards the pool area. The underside of gate latch releases must be located at least 1500mm above the ground and at least 1400mm above the highest lower rail on the pool barrier or shielded in compliance with the standard."$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL,
  'https://www.housing.qld.gov.au/__data/assets/pdf_file/0034/58984/guideline-owner-agent-swimming-pool-safety.pdf',
  'MP 3.4''s own A1(b) incorporates this guideline by reference for tolerance-limit figures -- VERIFIED_VERBATIM, not a mere secondary source, because the Acceptable Solution itself designates it.');

SELECT define_provision('QDC_MP_3_4@2012-07-27', 'Sch 1 item 16', 'SCHEDULE_ITEM',
  $q$16. The overhang or return fencing must have a surface that does not provide any projection or indentation forming a handhold or foothold and must be located at the outer edge of the retaining wall or other such barrier so as not to provide a handhold or foothold (see figure 2.7(c) in the Standard).$q$,
  'VERIFIED_VERBATIM', 'Page 5', 5, NULL, NULL, NULL, NULL);

SELECT define_provision('QDC_MP_3_4@2012-07-27', 'Sch 1 item 17', 'SCHEDULE_ITEM',
  $q$17. A canal, lake, river, creek, stream, pond, ocean or dam may form part of a barrier where: (a) the depth of water is continuously more than 300 millimetres at any point of the area of body of water adjacent to the barrier specified in 17(b); and (b) the width of the body of water immediately adjacent to the edge of the pool area being protected is equal to or exceeds 1800 millimetres at any point of the body of water; and (c) access is not available to the pool over or under the body of water (see figure 20, 21a and 21b); and (d) required barriers intersecting the body of water, either (i) extend to the edge of the water and either overhangs the water by 900 millimetres; or (ii) return 900 millimetres along the edge of the water in at least one direction (see figure 19); and (e) the overhang or return fencing required by 17(d) must have a surface that does not provide any projection or indentation forming a handhold or foothold that would aid climbing (see figure 19).$q$,
  'VERIFIED_VERBATIM', 'Page 5-6', 5, NULL, NULL, NULL, NULL);

SELECT define_provision('QDC_MP_3_4@2012-07-27', 'Sch 1 items 19-20', 'SCHEDULE_ITEM',
  $q$19. In addition to the requirements of clause 2.9, a non-climbable zone complying with figure 23 must be provided unless a barrier complying with this part is provided to the balcony. 20. Figure 22 applies in addition to figure 2.9 of the Standard.$q$,
  'VERIFIED_VERBATIM', 'Page 6', 6, NULL, NULL, NULL, NULL);

SELECT define_provision('QDC_MP_3_4@2012-07-27', 'Sch 1 item 26', 'SCHEDULE_ITEM',
  $q$26. Access to an indoor swimming pool must be via a child-resistant doorset that complies with this part or via another barrier that complies with this part. Where windows are present in the barrier, they must be child-resistant in accordance with this part.$q$,
  'VERIFIED_VERBATIM', 'Page 7', 7, NULL, NULL, NULL, NULL);

SELECT define_rule($r\${
 "rule_id": "MP34.A1b.GATE_LATCH_HEIGHT", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_ACCESS", "title": "Gate latch release underside >= 1500 mm above ground and >= 1400 mm above the highest lower rail (or shielded)",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "POOL_GATE_LATCH_HEIGHT", "operator": ">=", "value": 1500, "unit": "mm",
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_GATE"],
 "sources": [{"ref": "A1(b) + Guideline for pool owners and property agents (s258 BA), Fencing gates and latches", "role": "PRIMARY"}],
 "interpretation_notes": "Two cumulative height floors (1500mm above ground AND 1400mm above the highest lower rail), OR the latch may instead be shielded in compliance with the standard -- an (A AND B) OR C structure, encoded as the dominant case (the two heights) since shielding is a design alternative this tool cannot verify from geometry. Closes the gate-latch-height portion of open_issues #1. Hinge tamper-resistance specifications are still not found in any free source (neither this guideline nor MP 3.4 itself mentions hinges) -- that part of #1 remains open.",
 "effective_from": "2012-07-27"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MP34.S1_16.RETAINING_WALL_BARRIER_NO_FOOTHOLD", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_CONSTRUCTION", "title": "Overhang/return fencing atop a retaining wall used as a barrier must have no foothold/handhold surface",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "measurement": "POOL_RETAINING_WALL_BARRIER_NO_FOOTHOLD", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_BARRIER"],
 "sources": [{"ref": "Sch 1 item 16", "role": "PRIMARY"}],
 "interpretation_notes": "Only relevant where a retaining wall is used as (part of) the pool barrier. Paired with item 17(e)''s near-identical wording for the water-body-as-barrier case -- same no-foothold standard, different scenario (retaining wall here, water body in MP34.S1_17).",
 "effective_from": "2012-07-27"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MP34.S1_17.WATER_BODY_AS_BARRIER", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_CONSTRUCTION", "title": "A canal/lake/river/creek/stream/pond/ocean/dam may form part of the pool barrier, subject to depth/width/access/overhang-or-return conditions",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "measurement": "POOL_WATER_BODY_AS_BARRIER", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_BARRIER"],
 "sources": [{"ref": "Sch 1 item 17", "role": "PRIMARY"}],
 "interpretation_notes": "Conditions, all required: (a) water continuously >300mm deep adjacent to the relevant barrier section; (b) the water body is >=1800mm wide at that point; (c) no access to the pool over or under the water; (d) the barrier intersecting the water either extends to the water''s edge and overhangs the water by 900mm, or returns 900mm along the water''s edge in at least one direction; (e) that overhang/return fencing has no foothold/handhold surface (same standard as MP34.S1_16). This is a BARRIER-COMPLIANCE question -- whether the water body itself can stand in for a physical fence on that side -- distinct from this project''s existing canal SITING setbacks (SCC.C.CANAL_SETBACK_4_5, RCC.C.LDR5_CANAL_LAKE_9M), which answer a different question (how far back from the canal the pool/structure must sit), not this one.",
 "effective_from": "2012-07-27"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MP34.S1_19_20.BALCONY_NCZ", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_NCZ", "title": "Balcony pools: an additional non-climbable zone (Figure 23) is required unless the balcony itself has a compliant barrier",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "measurement": "POOL_BALCONY_NCZ", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_BARRIER"],
 "sources": [{"ref": "Sch 1 items 19-20", "role": "PRIMARY"}],
 "interpretation_notes": "Only relevant for a pool on/accessible from a balcony. Narrow applicability for this tool''s typical Class 10a/10b ground-level shed/pool scope, but encoded for completeness.",
 "effective_from": "2012-07-27"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MP34.S1_26.INDOOR_CHILD_RESISTANT_DOORSET", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_ACCESS", "title": "Indoor pool access must be via a compliant child-resistant doorset (or another compliant barrier)",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SCHEDULE_ITEM",
 "measurement": "POOL_INDOOR_CHILD_RESISTANT_DOORSET", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_BARRIER"],
 "sources": [{"ref": "Sch 1 item 26", "role": "PRIMARY"}],
 "interpretation_notes": "Supplements MP34.P1e.NO_BUILDING_DOORS's indoor-pool exception: for an indoor pool, the otherwise-prohibited building door is replaced by this specific requirement (a child-resistant doorset, or another fully-compliant barrier) rather than being unconditionally allowed. Windows in the barrier must also be child-resistant.",
 "effective_from": "2012-07-27"}$r\$);
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
