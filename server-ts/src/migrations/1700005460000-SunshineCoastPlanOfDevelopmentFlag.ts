import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #91, #92 (partial), #95 for Sunshine Coast.
 *
 * #91: builds exactly what the issue itself requested -- a flag rule. The Dwelling house code's own footnote
 * 4 (verbatim, already held in research/councils/sunshine_coast.json) states that a Structure Plan, as varied
 * by an approved master plan or plan of development, may set alternative requirements for a dwelling house
 * that are DEEMED to represent compliance with the Dwelling house code. This is a real, scheme-acknowledged
 * possibility that this tool cannot check (the POD/structure plan variation documents are not in the main
 * scheme text and are lot-specific) -- so it is encoded as an informational TRIGGER, same role/pattern already
 * used elsewhere in this project (e.g. CMB.C.LD_IMPACT_ASSESSMENT), surfaced whenever a Dwelling house/Class
 * 10a is assessed on Emerging community land.
 *
 * #92: the AO24 's'-suffix finding was already correctly described (no action needed, closing that part);
 * left OPEN overall -- whether Palmview precincts beyond Mixed/Medium Density Residential also host a
 * dwelling house genuinely needs fetching the rest of the Palmview Structure Plan's precinct tables.
 *
 * #95: confirmed State PDAs (Caloundra South/Aura, Beerwah East etc.) are jurisdictionally outside the
 * Planning Act / City Plan by design (administered under their own PDA Development Scheme, Economic
 * Development Act) -- this project already generically flags this via the existing in_priority_development_area
 * fact ("Lot in a PDA ... QHC/QDC siting parts do not apply"). Not a coverage gap in this tool's City Plan
 * extraction; closing with this confirmation.
 */
export class SunshineCoastPlanOfDevelopmentFlag1700005460000 implements MigrationInterface {
  name = "SunshineCoastPlanOfDevelopmentFlag1700005460000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

SELECT define_provision('SCC_PLANNING_SCHEME_2014@2024-01-23', '9.3.6 Dwelling house code, footnote 4', 'NOTE',
  $q$Editor's note--a Structure Plan, as varied by an approved master plan or an approved plan of development for a variation approval or reconfiguring a lot, may vary or specify alternative requirements for accepted development or performance outcomes and acceptable outcomes for assessable development for a dwelling house. In such cases, compliance with these alternative requirements ... will be deemed to represent compliance with the comparable provisions of the Dwelling house code.$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL,
  'https://publicdocs.scc.qld.gov.au/hpecmwebdrawer/Record/22407391/File/document',
  'Applies to the Dwelling house code generally (not just Palmview) -- surfaced as a TRIGGER for Emerging community lots since that is where a Structure Plan/POD variation is most likely to exist.');

SELECT define_rule($r\${
 "rule_id": "SCC.C.EC_CHECK_APPROVED_PLAN_OF_DEVELOPMENT", "instrument_version": "SCC_PLANNING_SCHEME_2014@2024-01-23",
 "topic": "PATHWAY.PLANNING_APPROVAL", "title": "Emerging community zone: check for an approved Structure Plan / plan of development variation before relying on the Dwelling house code figures",
 "role": "TRIGGER", "regime": "PLANNING", "enforceability": "MANDATORY", "provision_kind": "NOTE",
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "SUNSHINE_COAST"}, {"level": "ZONE", "zone": "SCC:EMERGING_COMMUNITY"}],
 "subjects": ["ANY"],
 "sources": [{"ref": "9.3.6 Dwelling house code, footnote 4", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #91. This footnote applies project-wide to the Dwelling house code (not just Palmview), so it is surfaced for every Emerging community lot -- a lot-specific Structure Plan/POD variation is not something this tool can check (not in the main scheme text, and varies per approval). Where one exists and applies, it is DEEMED to satisfy the Dwelling house code, so its own figures govern instead of the ones this tool otherwise reports.",
 "effective_from": "2024-01-23"}$r\$);

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: built exactly what this issue requested -- SCC.C.EC_CHECK_APPROVED_PLAN_OF_DEVELOPMENT, an informational trigger (same pattern as CMB.C.LD_IMPACT_ASSESSMENT elsewhere in this project) that surfaces the Dwelling house code''s own footnote 4 (Structure Plan / approved plan of development variations are DEEMED to satisfy the Dwelling house code) for every Emerging community lot, not just Palmview.'
WHERE issue_id = 91 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';

UPDATE open_issues SET description =
  'NARROWED 2026-11-17: the AO24 ''s''-suffix finding was already correctly and precisely described (no accepted-development pathway, but may still matter for code assessment) -- no action needed on that part. Genuinely still open: whether Palmview precincts beyond the Mixed Density and Medium Density Residential precinct tables also list a dwelling house was only checked by a text search, not a full read of the Palmview Structure Plan''s other precinct tables -- would need fetching those tables directly.'
WHERE issue_id = 92 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';

UPDATE open_issues SET resolved_at = '2026-11-17', description =
  'RESOLVED 2026-11-17: confirmed State PDAs (Caloundra South/Aura, Beerwah East etc.) are jurisdictionally outside the Planning Act / City Plan by design -- they are administered under their own PDA Development Scheme (Economic Development Act 1987/2012), a wholly separate legal instrument. This project already generically flags PDA land via the existing in_priority_development_area fact ("Lot in a PDA (Economic Development Act) -- QHC/QDC siting parts do not apply"). Not a coverage gap in this tool''s City Plan extraction -- no fix needed.'
WHERE issue_id = 95 AND instrument_id = 'SCC_PLANNING_SCHEME_2014';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
