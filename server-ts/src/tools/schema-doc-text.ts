/** Hand-written parts of db/README.md (table purposes, ER diagram, research → table map), used by schema-doc.ts. */
export const GROUPS: [string, [string, string, string][]][] = [
 [
  "Sources — where the law comes from",
  [
   [
    "authorities",
    "Bodies that make the law: Parliament, State Government, ABCB, Standards Australia, the 7 councils.",
    "db/010"
   ],
   [
    "local_governments",
    "The councils in scope.",
    "db/010"
   ],
   [
    "instruments",
    "A legal document: Act, Regulation, QDC part, planning scheme, Australian Standard.",
    "db/010 (state), db/030 (planning schemes)"
   ],
   [
    "instrument_versions",
    "One published version / reprint of a document, with dates, URL, archived file and SHA-256.",
    "db/010, db/030"
   ],
   [
    "provisions",
    "One clause, table row or figure with its exact words (verbatim_text). Council provisions carry research_key = the record in research/councils/*.json they came from.",
    "db/020 (state), db/030 (council)"
   ],
   [
    "instrument_applicability",
    "Which document version applies to which council, for which regime, between which dates (this is where the QHC transition is recorded).",
    "db/021, db/030"
   ]
  ]
 ],
 [
  "Places — where rules apply",
  [
   [
    "regulated_zones",
    "The 41 zones a planning scheme may use (Planning Regulation 2017 s6, sch 2).",
    "db/020"
   ],
   [
    "zones",
    "Each council scheme's zones, linked to the regulated zone, with whether a dwelling house is a permitted use.",
    "research/places.json via db/030"
   ],
   [
    "precincts",
    "Precincts inside a zone.",
    "research/places.json via db/030"
   ],
   [
    "overlays",
    "Overlays (flood, character, ridges, canals…).",
    "research/councils/*.json via db/030"
   ],
   [
    "local_plans",
    "Neighbourhood / local plans.",
    "research/places.json via db/030"
   ],
   [
    "local_plan_precincts",
    "Precincts inside a local plan.",
    "research/places.json via db/030"
   ]
  ]
 ],
 [
  "Vocabulary — what rules can talk about",
  [
   [
    "building_classifications",
    "NCC building classes (1a, 2, 10a, 10b).",
    "db/010"
   ],
   [
    "structure_types",
    "Tree of things a rule can target (ANY → CLASS_10A → SHED; POOL → POOL_INGROUND …).",
    "db/010"
   ],
   [
    "structure_type_terms",
    "A document's own words mapped to the structure tree (not yet populated).",
    "—"
   ],
   [
    "facts",
    "The only inputs a rule may use (lot area, wall height, boundary type…), with type, unit and how to derive them.",
    "db/010, db/031, db/032"
   ],
   [
    "measurements",
    "What a numeric requirement is measured on: from where, to where, how.",
    "db/010, db/031, db/032"
   ]
  ]
 ],
 [
  "Rules — the regulatory content",
  [
   [
    "rules",
    "Stable identity of a rule across versions (id, document, topic, title).",
    "db/021, db/030, db/031, db/032"
   ],
   [
    "rule_versions",
    "The rule content for one period: role, regime, enforceability, measurement, operator, value/formula (value_expr), unit, consequence of failure, dates, status (DRAFT/ACTIVE/SUPERSEDED), verification, automatable.",
    "same"
   ],
   [
    "rule_scopes",
    "Where a rule applies: council, zone, precinct, local plan, overlay (include or exclude).",
    "same"
   ],
   [
    "rule_subjects",
    "Which structure types a rule applies to (include or exclude).",
    "same"
   ],
   [
    "rule_conditions",
    "When a rule applies, e.g. lot_area_m2 >= 450. Rows with the same group_no are AND-ed; groups are OR-ed.",
    "same"
   ],
   [
    "rule_sources",
    "Why: the provision(s) a rule relies on, with the exact quote. Every active rule has a PRIMARY source.",
    "same"
   ],
   [
    "rule_relationships",
    "Precedence between rules: OVERRIDES, REPLACES, EXEMPTS, RELAXES, SUPPLEMENTS, ALTERNATIVE_TO, CONDITIONAL_ON, FALLS_BACK_TO, UNRESOLVED, each with its legal basis.",
    "same"
   ]
  ]
 ],
 [
  "Quality",
  [
   [
    "verification_log",
    "Who checked which rule/provision, when, how (not yet populated).",
    "—"
   ],
   [
    "open_issues",
    "Known gaps and questions that block automation (incl. each research file's open_questions).",
    "db/021, db/030"
   ]
  ]
 ]
];

export const ER = "```mermaid\nerDiagram\n  authorities ||--o{ instruments : makes\n  authorities ||--o{ local_governments : is\n  local_governments ||--o{ instruments : \"owns (schemes)\"\n  instruments ||--o{ instrument_versions : \"has versions\"\n  instrument_versions ||--o{ provisions : contains\n  instrument_versions ||--o{ instrument_applicability : \"applies via\"\n  local_governments ||--o{ instrument_applicability : \"in\"\n  instruments ||--o{ zones : defines\n  regulated_zones ||--o{ zones : \"corresponds to\"\n  zones ||--o{ precincts : contains\n  instruments ||--o{ overlays : defines\n  instruments ||--o{ local_plans : defines\n  local_plans ||--o{ local_plan_precincts : contains\n  instruments ||--o{ rules : \"source of\"\n  rules ||--o{ rule_versions : \"has versions\"\n  instrument_versions ||--o{ rule_versions : \"version of law\"\n  measurements ||--o{ rule_versions : \"measured by\"\n  rule_versions ||--o{ rule_scopes : \"applies where\"\n  rule_versions ||--o{ rule_subjects : \"applies to\"\n  rule_versions ||--o{ rule_conditions : \"applies when\"\n  rule_versions ||--o{ rule_sources : \"cites\"\n  provisions ||--o{ rule_sources : \"cited by\"\n  rule_versions ||--o{ rule_relationships : \"from\"\n  rules ||--o{ rule_relationships : \"to (all versions)\"\n  facts ||--o{ rule_conditions : \"tested in\"\n  structure_types ||--o{ rule_subjects : \"\"\n  building_classifications ||--o{ structure_types : \"\"\n  zones ||--o{ rule_scopes : \"\"\n  precincts ||--o{ rule_scopes : \"\"\n  overlays ||--o{ rule_scopes : \"\"\n  local_plans ||--o{ rule_scopes : \"\"\n  local_plan_precincts ||--o{ rule_scopes : \"\"\n  local_governments ||--o{ rule_scopes : \"\"\n```";

export const RESEARCH_MAP = "| Field in `research/councils/<council>.json` | Stored in |\n|---|---|\n| `planning_scheme` (name, version, version_commenced, official_urls) | `instruments` (kind PLANNING_SCHEME) + `instrument_versions` + `instrument_applicability` (regime PLANNING) |\n| `qdc_qhc_relationship.quotes[]` | `provisions` (kind APPLICATION, ref_label `QDC relationship: …`) |\n| `definitions[]` | `provisions` (kind DEFINITION, ref_label `def <term>`) |\n| `levels_of_assessment[]` | `provisions` (kind LEVEL_OF_ASSESSMENT, ref_label `LOA …`) |\n| `overlays_affecting_siting[]` | `overlays` + `provisions` (ref_label `overlay …`) |\n| `rules[]` → verbatim text, clause, page, URL, verification | `provisions` (one row per rule, `research_key` = `rule_key`) |\n| `rules[]` (except provision_type DEFINITION) → the rule | `rules` + `rule_versions` (status DRAFT, or SUPERSEDED once curated) + `rule_scopes` + `rule_subjects` + `rule_sources` |\n| `rules[].zones` | `rule_scopes`, mapped through `research/places.json` → zones / precincts / local plans |\n| `rules[].alternative_provision_to_qdc_qhc = YES` | `rule_relationships` type OVERRIDES → the matching QDC rules |\n| `open_questions[]` | `open_issues` |\n| `fetch_log[]` | not loaded (kept in the JSON as research provenance) |\n\nCurated rules (`db/031` to `db/036`) are hand-encoded from the same provisions. Each one `REPLACES` its draft,\nwhich then shows status SUPERSEDED.";
