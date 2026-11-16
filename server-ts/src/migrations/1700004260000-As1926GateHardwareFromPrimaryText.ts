import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * User sourced a licensed copy of AS 1926.1-2007 (+ Amdt 1) -- previously unheld/paywalled (open_issues #1).
 * NOT stored in this repository (copyright) -- only the specific clause text needed to resolve #1 is
 * transcribed below, same as every other instrument in this dataset.
 *
 * Findings:
 *   1. "Hinge tamper-resistance specifications" -- the premise behind half of open_issues #1 -- does NOT
 *      exist in AS 1926.1-2007. The word "hinge" appears exactly once in the whole standard, in Sec 2.3.4
 *      (Horizontal climbable members): gate hinges are listed only as an example of a foothold/climbing aid
 *      if mounted outside the fence below 1800mm -- a concern already covered by this project's existing
 *      non-climbable-zone rules (MP34.S1_13, MP34.FIG1.CLEAR_AREA_FOOTHOLD_300). There is no separate
 *      hardware-tamper-resistance clause for hinges. This closes that part of #1 by confirming absence, not
 *      by finding a source -- the original assumption that a figure existed and was merely paywalled was
 *      incorrect.
 *   2. Secs 2.3.7 (vertical member gap <=100mm) and 2.4 (ground clearance <=100mm) are the actual primary
 *      text behind the two figures this project already held only via QBCC's consumer-guidance restatement
 *      (COUNCIL_FACTSHEET tier, db/-equivalent PoolBarrierAdditionalFigures migration). Now upgraded to
 *      VERIFIED_VERBATIM with AS 1926.1 itself as PRIMARY source; QBCC demoted to SUPPLEMENTARY corroboration.
 *      Sec 2.5.2 restates the same ground-clearance figure specifically for gates -- not a new figure, so not
 *      encoded as a separate rule, just cited as further corroboration on the ground-gap rule.
 *   3. Sec 2.5.4.1 (latching device integrity) and 2.5.4.3 (latch shielding, the alternative compliance path
 *      to the already-encoded MP34.A1b.GATE_LATCH_HEIGHT) ARE genuinely new, independent requirements not
 *      restated anywhere else in this dataset -- encoded as two new rules below.
 *
 * Resolves open_issues #1 in full.
 */
export class As1926GateHardwareFromPrimaryText1700004260000 implements MigrationInterface {
  name = "As1926GateHardwareFromPrimaryText1700004260000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE instrument_versions SET
  notes = 'A licensed copy (incl. Amendment No. 1, published 12 July 2007 / amended 5 May 2008) was sourced and reviewed 2026-11-16 to resolve open_issues #1. Primary text itself is NOT stored in this repository (copyright) -- only the specific clause text needed for the rules below is transcribed, consistent with every other instrument in this dataset.',
  verified_at = '2026-11-16',
  verified_by = 'user-provided licensed copy, reviewed by Claude Code (not stored in repo)'
WHERE instrument_version_id = 'AS_1926_1_2007@2007';

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, vertical_projection, evaluate_per_part, notes) VALUES
  ('POOL_GATE_LATCH_TAMPER_RESISTANT', 'PRESENCE', 'POOL_GATE_LATCH_MECHANISM', NULL, false, false,
   'Whether the gate latching device meets AS 1926.1-2007 Sec 2.5.4.1''s tamper-resistance conditions (not inadvertently adjustable, not lockable open, not tool-free adjustable, not releasable via the 10mm gap).'),
  ('POOL_GATE_LATCH_SHIELD_GEOMETRY', 'PRESENCE', 'POOL_GATE_LATCH_SHIELD', NULL, false, false,
   'Whether a gate latch sitting below the MP34.A1b.GATE_LATCH_HEIGHT thresholds is shielded per AS 1926.1-2007 Sec 2.5.4.3 (450mm radius, <=10mm opening, hand-hole/rounding conditions) -- the alternative compliance path to the height requirement.');

SELECT define_provision('AS_1926_1_2007@2007', '2.3.7', 'SECTION',
  $q$2.3.7 Vertical members. The clear space between any adjacent vertical members (see Figure 2.2), such as palings, rods or wires, shall not exceed 100 mm at any point.$q$,
  'VERIFIED_VERBATIM', 'Page 13', 13, NULL, NULL, NULL, NULL);

SELECT define_provision('AS_1926_1_2007@2007', '2.4', 'SECTION',
  $q$2.4 GROUND CLEARANCE. The height of any opening between the bottom of the barrier and the finished ground level shall not exceed 100 mm.$q$,
  'VERIFIED_VERBATIM', 'Page 13', 13, NULL, NULL, NULL, NULL);

SELECT define_provision('AS_1926_1_2007@2007', '2.5.2', 'SECTION',
  $q$2.5.2 Operation of gate. The gate shall have sufficient clearance to enable it to swing freely through its arc of operation. [Amdt 1] The maximum gap under the gate shall not exceed 100 mm at any point when in a closed position.$q$,
  'VERIFIED_VERBATIM', 'Page 14', 14, NULL, NULL, NULL, NULL);

SELECT define_provision('AS_1926_1_2007@2007', '2.5.4.1', 'SECTION',
  $q$2.5.4.1 General. Gates shall be fitted with a latching device that will automatically operate on the closing of the gate and will prevent the gate from being re-opened without being manually released. The latching device shall not be able to be -- (a) inadvertently adjusted during operation; (b) able to be locked in the 'open' position; and (c) able to be adjusted without the use of tools. When in the closed position, the latching mechanism shall not be able to be released by the insertion of any implement in the 10 mm gap shown in Figure 2.6(a).$q$,
  'VERIFIED_VERBATIM', 'Page 14', 14, NULL, NULL, NULL, NULL);

SELECT define_provision('AS_1926_1_2007@2007', '2.5.4.3', 'SECTION',
  $q$2.5.4.3 Shielding of latching device (see Figure 2.6). Where the release to either the latching device or the latch is located at a height less than [Amdt 1] 1500 mm above the finished ground level and 1400 mm above the highest lower horizontal member and is capable of being released at the mechanism, the latch and its release shall be so shielded that no opening greater than 10 mm occurs within an area bounded by -- (a) an effective radius of 450 mm from the operating parts of the latch; and (b) the top of the fence, if this intersects the area described in Item (a). Where it is necessary to have a hand-hole in a gate, the bottom of the opening shall be not less than 1200 mm above the finished ground level and 1000 mm above the highest lower horizontal member, and the shielding shall be extended up to a horizontal line through the top of the hand-hole, or 150 mm above the top of the latch, whichever is the higher. The shield shall be free of sharp edges and the edges of the adjacent parts of the shield on the gate and the fence shall be rounded or chamfered to prevent a hazard when the gate closes.$q$,
  'VERIFIED_VERBATIM', 'Page 15', 15, NULL, NULL, NULL, NULL);

-- Upgrade the two gap figures from COUNCIL_FACTSHEET (QBCC restatement) to VERIFIED_VERBATIM
-- (AS 1926.1-2007's own primary text), now that the Standard itself is held.
UPDATE rule_versions SET
  verification = 'VERIFIED_VERBATIM',
  interpretation_notes = 'UPGRADED 2026-11-16: AS 1926.1-2007 Sec 2.3.7 (now held, open_issues #1 resolved) states this verbatim -- "The clear space between any adjacent vertical members ... shall not exceed 100 mm at any point." Previously sourced only via QBCC''s consumer-guidance restatement (COUNCIL_FACTSHEET), now demoted to corroborating/SUPPLEMENTARY. automatable=false, unchanged.'
WHERE rule_version_id = 'MP34.AS1926.BARRIER_MAX_GAP_100@2012-07-27';

UPDATE rule_versions SET
  verification = 'VERIFIED_VERBATIM',
  interpretation_notes = 'UPGRADED 2026-11-16: AS 1926.1-2007 Sec 2.4 (now held, open_issues #1 resolved) states this verbatim -- "The height of any opening between the bottom of the barrier and the finished ground level shall not exceed 100 mm." Sec 2.5.2 separately restates the identical 100mm figure specifically for gates, corroborating rather than adding a new figure. Previously sourced only via QBCC''s consumer-guidance restatement (COUNCIL_FACTSHEET), now demoted to corroborating/SUPPLEMENTARY. automatable=false, unchanged.'
WHERE rule_version_id = 'MP34.AS1926.BARRIER_GROUND_GAP_100@2012-07-27';

UPDATE rule_sources SET role = 'SUPPLEMENTARY'
WHERE rule_version_id IN ('MP34.AS1926.BARRIER_MAX_GAP_100@2012-07-27', 'MP34.AS1926.BARRIER_GROUND_GAP_100@2012-07-27')
  AND role = 'PRIMARY';

INSERT INTO rule_sources (rule_version_id, provision_id, role, quote) VALUES
  ('MP34.AS1926.BARRIER_MAX_GAP_100@2012-07-27', p('AS_1926_1_2007@2007', '2.3.7'), 'PRIMARY',
   'The clear space between any adjacent vertical members ... shall not exceed 100 mm at any point.'),
  ('MP34.AS1926.BARRIER_GROUND_GAP_100@2012-07-27', p('AS_1926_1_2007@2007', '2.4'), 'PRIMARY',
   'The height of any opening between the bottom of the barrier and the finished ground level shall not exceed 100 mm.'),
  ('MP34.AS1926.BARRIER_GROUND_GAP_100@2012-07-27', p('AS_1926_1_2007@2007', '2.5.2'), 'SUPPLEMENTARY',
   'The maximum gap under the gate shall not exceed 100 mm at any point when in a closed position.');

SELECT define_rule($r\${
 "rule_id": "AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT", "instrument_version": "AS_1926_1_2007@2007",
 "topic": "POOL_SAFETY.BARRIER_ACCESS", "title": "Gate latching device must resist inadvertent adjustment, locking open, tool-free adjustment, and release through the 10 mm gap",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SECTION",
 "measurement": "POOL_GATE_LATCH_TAMPER_RESISTANT", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_GATE"],
 "sources": [{"ref": "2.5.4.1", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves the second half of open_issues #1 by confirming there is no separate hinge-specific tamper-resistance clause in AS 1926.1-2007 -- the standard's actual tamper-resistance requirement attaches to the LATCHING DEVICE, not the hinge: it must not be inadvertently adjustable, must not be lockable in the open position, must not be adjustable without tools, and must not be releasable by inserting an implement through the 10mm gap at the latch. The only mention of 'hinge' anywhere in the standard (Sec 2.3.4) is unrelated -- gate hinges as a possible climbing foothold, already covered by this project's existing non-climbable-zone rules. automatable=false: compliance with these hardware-construction conditions is a manufactured-product/installation fact, not derivable from site plan geometry.",
 "effective_from": "2007-07-12"}$r\$);

SELECT define_rule($r\${
 "rule_id": "AS1926.S2_5_4_3.LATCH_SHIELDING", "instrument_version": "AS_1926_1_2007@2007",
 "topic": "POOL_SAFETY.BARRIER_ACCESS", "title": "Where the gate latch sits below the height thresholds, it must be shielded: <=10 mm opening within a 450 mm radius of the latch (extended for any hand-hole)",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SECTION",
 "measurement": "POOL_GATE_LATCH_SHIELD_GEOMETRY", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_GATE"],
 "sources": [{"ref": "2.5.4.3", "role": "PRIMARY"}],
 "interpretation_notes": "The alternative compliance path to MP34.A1b.GATE_LATCH_HEIGHT's '(or shielded)' clause, now fully specified from AS 1926.1-2007's own text: applies only where the latch release sits below 1500mm above ground AND 1400mm above the highest lower rail. Where it applies, the shield must prevent any opening >10mm within a 450mm radius of the latch's operating parts (extended to the fence top if that intersects the radius), with hand-hole and edge-rounding conditions. Only one of GATE_LATCH_HEIGHT or this rule need be satisfied for a given gate, not both -- encoded as a separate rule rather than a condition on GATE_LATCH_HEIGHT because this tool cannot verify either from plan geometry alone (both automatable=false) and keeping them distinct preserves each rule's own citation trail. effective_from reflects this clause's own Amendment No. 1 date (5 May 2008), not the standard's original 2007 publication.",
 "effective_from": "2008-05-05"}$r\$);

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: a licensed copy of AS 1926.1-2007 (+ Amdt 1) was sourced and reviewed in full. (1) The "hinge tamper-resistance" figure this issue was tracking does not exist as a separate requirement -- the only mention of "hinge" in the whole standard (Sec 2.3.4) is about gate hinges as a possible climbing foothold, already covered by this project''s non-climbable-zone rules; confirmed absent, not merely unsourced. (2) The two 100mm gap figures (MP34.AS1926.BARRIER_MAX_GAP_100, MP34.AS1926.BARRIER_GROUND_GAP_100), previously held only via QBCC''s consumer-guidance restatement, are now upgraded to VERIFIED_VERBATIM citing the Standard''s own Sec 2.3.7 and 2.4 directly. (3) Two genuinely new, independent requirements were found and encoded: AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT (latching-device hardware integrity) and AS1926.S2_5_4_3.LATCH_SHIELDING (the shielding alternative to MP34.A1b.GATE_LATCH_HEIGHT''s height requirement). The primary standard text is not stored in this repository (copyright); only the clause excerpts needed for these rules are transcribed, consistent with how every other instrument in this dataset is handled.'
WHERE issue_id = 1 AND instrument_id = 'AS_1926_1_2007';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
