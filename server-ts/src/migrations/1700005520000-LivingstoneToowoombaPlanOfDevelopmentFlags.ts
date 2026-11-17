import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #135 (Livingstone) and #161 (Toowoomba), same pattern as Sunshine Coast's #91: builds
 * an informational TRIGGER flag rather than leaving the limitation buried only in internal
 * interpretation_notes, which are never shown to an end user.
 *
 * #135: Schedule 10's own Table SC10.1.1 carries this note verbatim (user-supplied PDF, already used to
 * resolve #138/#139 this session): "The setback standards for the Emerging Community Zone apply where
 * located in an area that is not the subject of a Local Plan, or an approved structure plan area, which has
 * approved documents that vary the effect of the planning scheme with alternative assessment benchmarks for
 * setbacks." This caveat was already repeated in ~8 separate rules' interpretation_notes (LSC.C.RUR_EC_*)
 * but never surfaced as an actual warning to a user.
 *
 * #161: already-held research (TRC.*dh_front_setback_absent and others) already models "within a Schedule 7
 * plan of development" via the existing development_footprint_exists fact as a proxy condition, and the
 * scheme's own Table 5.5:1/5.5:2 text ("the site is not within an Approved Plans of Development listed in
 * Schedule 7") is already captured verbatim -- but, same issue as Livingstone, this was never surfaced as an
 * actual warning.
 */
export class LivingstoneToowoombaPlanOfDevelopmentFlags1700005520000 implements MigrationInterface {
  name = "LivingstoneToowoombaPlanOfDevelopmentFlags1700005520000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

SELECT define_provision('LSC_PLANNING_SCHEME_2018@2025-05-02', 'Table SC10.1.1 note', 'NOTE',
  $q$Note: The setback standards for the Emerging Community Zone apply where located in an area that is not the subject of a Local Plan, or an approved structure plan area, which has approved documents that vary the effect of the planning scheme with alternative assessment benchmarks for setbacks.$q$,
  'VERIFIED_VERBATIM', 'Page SC10-1', 1, NULL, NULL,
  'https://www.livingstone.qld.gov.au/',
  'Already repeated in ~8 separate LSC.C.RUR_EC_* rules'' interpretation_notes, but never surfaced as a user-facing warning until now.');

SELECT define_rule($r\${
 "rule_id": "LSC.C.EC_CHECK_STRUCTURE_PLAN", "instrument_version": "LSC_PLANNING_SCHEME_2018@2025-05-02",
 "topic": "PATHWAY.PLANNING_APPROVAL", "title": "Emerging community zone: check for a Local Plan or approved structure plan area before relying on Schedule 10 setbacks",
 "role": "TRIGGER", "regime": "PLANNING", "enforceability": "MANDATORY", "provision_kind": "NOTE",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LIVINGSTONE"}, {"level": "ZONE", "zone": "LSC:EMERGING_COMMUNITY"}],
 "subjects": ["ANY"],
 "sources": [{"ref": "Table SC10.1.1 note", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #135. Schedule 10's own setback tables for the Emerging Community Zone do not apply within a Local Plan or an approved structure plan area that has its own alternative setback benchmarks -- this tool cannot check for a lot-specific structure plan, so every LSC.C.RUR_EC_* figure this tool reports for an Emerging Community lot should be checked against council records for an applicable structure plan before being relied on.",
 "effective_from": "2025-05-02"}$r\$);

SELECT define_provision('TRC_PLANNING_SCHEME_2012@2026-07-21', 'Table 5.5:1 / 5.5:2, Schedule 7 condition', 'NOTE',
  $q$Dwelling House | Accepted development | If (i) the area of the site is 450m2 or more; and (ii) the site is not a hatchet lot; and (iii) the site is not within an Approved Plans of Development listed in Schedule 7 (or a current Plan of Development listed in Schedule 7).$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL,
  'https://www.tr.qld.gov.au/',
  'Already modelled as a condition (development_footprint_exists used as a proxy for "within a Schedule 7 plan") in several draft rules, but the Schedule 7 plans'' own content was never reviewed and the limitation was never surfaced as a user-facing warning until now.');

SELECT define_rule($r\${
 "rule_id": "TRC.C.LDR_LMDR_CHECK_SCHEDULE_7_POD", "instrument_version": "TRC_PLANNING_SCHEME_2012@2026-07-21",
 "topic": "PATHWAY.PLANNING_APPROVAL", "title": "Low/Low-medium density residential: check Schedule 7 Approved Plans of Development before relying on this tool's setbacks",
 "role": "TRIGGER", "regime": "PLANNING", "enforceability": "MANDATORY", "provision_kind": "NOTE",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "TOOWOOMBA"}, {"level": "ZONE", "zone": "TRC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "TRC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}],
 "subjects": ["ANY"],
 "sources": [{"ref": "Table 5.5:1 / 5.5:2, Schedule 7 condition", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #161. A lot within a Schedule 7 Approved Plan of Development is explicitly excluded from the standard Accepted development / Small Lot Housing Design Code pathway by the scheme's own text -- its own estate-specific plan governs instead, and this tool has not reviewed any individual Schedule 7 plan's content. Every figure this tool reports for a Low or Low-medium density residential lot should be checked against the relevant Schedule 7 plan (if any applies) before being relied on.",
 "effective_from": "2026-07-21"}$r\$);

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: built LSC.C.EC_CHECK_STRUCTURE_PLAN, an informational trigger (same pattern as SCC.C.EC_CHECK_APPROVED_PLAN_OF_DEVELOPMENT / CMB.C.LD_IMPACT_ASSESSMENT elsewhere in this project) surfacing Schedule 10''s own Table SC10.1.1 note for every Emerging Community lot -- this caveat was already repeated in ~8 separate rules'' internal interpretation_notes but was never actually shown to a user before now.'
WHERE issue_id = 135 AND instrument_id = 'LSC_PLANNING_SCHEME_2018';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: built TRC.C.LDR_LMDR_CHECK_SCHEDULE_7_POD, an informational trigger surfacing the scheme''s own Table 5.5:1/5.5:2 Schedule 7 condition for every Low/Low-medium density residential lot -- the project already modelled "within a Schedule 7 plan" as a condition (via development_footprint_exists) in several draft rules, but never surfaced it as an actual warning that the Schedule 7 plan''s own content (not reviewed) governs instead.'
WHERE issue_id = 161 AND instrument_id = 'TRC_PLANNING_SCHEME_2012';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
