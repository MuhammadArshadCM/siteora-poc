import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Fixes a defect in As1926GateHardwareFromPrimaryText: the two new rules (AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT,
 * AS1926.S2_5_4_3.LATCH_SHIELDING) were defined with instrument_version "AS_1926_1_2007@2007" directly.
 * instrument_applicability only has a row for "QDC_MP_3_4@2012-07-27" (POOL_SAFETY, statewide) -- AS 1926.1's
 * own instrument_version was never added there, so loaded.activeIvs never included it and the two rules
 * silently never evaluated (confirmed via examples/brisbane_shed_pool.json re-check: neither rule appeared).
 *
 * Fix follows this project's own established convention (e.g. MP34.AS1926.BARRIER_MAX_GAP_100/GROUND_GAP_100,
 * which cite AS 1926.1/QBCC content but are themselves filed under QDC_MP_3_4@2012-07-27 for applicability):
 * re-file both rules under QDC_MP_3_4@2012-07-27, with their PRIMARY source explicitly cross-referencing the
 * AS_1926_1_2007@2007 provision via the "iv" key (same pattern used throughout db/021_state_rules.sql for
 * cross-instrument citations, e.g. Building Act definitions cited from QDC MP 1.2 rules).
 */
export class FixAs1926NewRulesApplicability1700004320000 implements MigrationInterface {
  name = "FixAs1926NewRulesApplicability1700004320000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

DELETE FROM rule_sources WHERE rule_version_id IN (
  'AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT@2007-07-12', 'AS1926.S2_5_4_3.LATCH_SHIELDING@2008-05-05');
DELETE FROM rule_subjects WHERE rule_version_id IN (
  'AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT@2007-07-12', 'AS1926.S2_5_4_3.LATCH_SHIELDING@2008-05-05');
DELETE FROM rule_versions WHERE rule_version_id IN (
  'AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT@2007-07-12', 'AS1926.S2_5_4_3.LATCH_SHIELDING@2008-05-05');
DELETE FROM rules WHERE rule_id IN (
  'AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT', 'AS1926.S2_5_4_3.LATCH_SHIELDING');

SELECT define_rule($r\${
 "rule_id": "AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_ACCESS", "title": "Gate latching device must resist inadvertent adjustment, locking open, tool-free adjustment, and release through the 10 mm gap",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SECTION",
 "measurement": "POOL_GATE_LATCH_TAMPER_RESISTANT", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_GATE"],
 "sources": [{"ref": "2.5.4.1", "role": "PRIMARY", "iv": "AS_1926_1_2007@2007"}],
 "interpretation_notes": "Resolves the second half of open_issues #1 by confirming there is no separate hinge-specific tamper-resistance clause in AS 1926.1-2007 -- the standard's actual tamper-resistance requirement attaches to the LATCHING DEVICE, not the hinge: it must not be inadvertently adjustable, must not be lockable in the open position, must not be adjustable without tools, and must not be releasable by inserting an implement through the 10mm gap at the latch. The only mention of 'hinge' anywhere in the standard (Sec 2.3.4) is unrelated -- gate hinges as a possible climbing foothold, already covered by this project's existing non-climbable-zone rules. automatable=false: compliance with these hardware-construction conditions is a manufactured-product/installation fact, not derivable from site plan geometry. Filed under QDC_MP_3_4@2012-07-27 (not AS_1926_1_2007@2007) for applicability, same convention as MP34.AS1926.BARRIER_MAX_GAP_100/GROUND_GAP_100 -- AS 1926.1 has no instrument_applicability row of its own in this dataset.",
 "effective_from": "2007-07-12"}$r\$);

SELECT define_rule($r\${
 "rule_id": "AS1926.S2_5_4_3.LATCH_SHIELDING", "instrument_version": "QDC_MP_3_4@2012-07-27",
 "topic": "POOL_SAFETY.BARRIER_ACCESS", "title": "Where the gate latch sits below the height thresholds, it must be shielded: <=10 mm opening within a 450 mm radius of the latch (extended for any hand-hole)",
 "role": "REQUIREMENT", "regime": "POOL_SAFETY", "enforceability": "MANDATORY", "provision_kind": "SECTION",
 "measurement": "POOL_GATE_LATCH_SHIELD_GEOMETRY", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["POOL_GATE"],
 "sources": [{"ref": "2.5.4.3", "role": "PRIMARY", "iv": "AS_1926_1_2007@2007"}],
 "interpretation_notes": "The alternative compliance path to MP34.A1b.GATE_LATCH_HEIGHT's '(or shielded)' clause, now fully specified from AS 1926.1-2007's own text: applies only where the latch release sits below 1500mm above ground AND 1400mm above the highest lower rail. Where it applies, the shield must prevent any opening >10mm within a 450mm radius of the latch's operating parts (extended to the fence top if that intersects the radius), with hand-hole and edge-rounding conditions. Only one of GATE_LATCH_HEIGHT or this rule need be satisfied for a given gate, not both -- encoded as a separate rule rather than a condition on GATE_LATCH_HEIGHT because this tool cannot verify either from plan geometry alone (both automatable=false) and keeping them distinct preserves each rule's own citation trail. effective_from reflects this clause's own Amendment No. 1 date (5 May 2008), not the standard's original 2007 publication. Filed under QDC_MP_3_4@2012-07-27 (not AS_1926_1_2007@2007) for applicability, same convention as MP34.AS1926.BARRIER_MAX_GAP_100/GROUND_GAP_100 -- AS 1926.1 has no instrument_applicability row of its own in this dataset.",
 "effective_from": "2008-05-05"}$r\$);
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
