# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/tools/schema-doc.ts (npm run schema-doc)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Generate db/README.md (table plan + relationships) from the live database.
#
# Purposes are written by hand below; columns, types, keys, foreign keys and row counts are read
# from the database, so the document always matches the schema actually loaded.
#
# Usage: PGPASSWORD=... python -I tools/schema_doc.py [--db siteora]
# """
# import argparse
# import pathlib
# import sys
#
# sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
# import evaluate  # noqa: E402  (reuses its psql query helper)
#
# ROOT = pathlib.Path(__file__).resolve().parent.parent
#
# GROUPS = [
#     ("Sources — where the law comes from", [
#         ("authorities", "Bodies that make the law: Parliament, State Government, ABCB, Standards Australia, the 7 councils.", "db/010"),
#         ("local_governments", "The councils in scope.", "db/010"),
#         ("instruments", "A legal document: Act, Regulation, QDC part, planning scheme, Australian Standard.", "db/010 (state), db/030 (planning schemes)"),
#         ("instrument_versions", "One published version / reprint of a document, with dates, URL, archived file and SHA-256.", "db/010, db/030"),
#         ("provisions", "One clause, table row or figure with its exact words (verbatim_text). Council provisions carry research_key = the record in research/councils/*.json they came from.", "db/020 (state), db/030 (council)"),
#         ("instrument_applicability", "Which document version applies to which council, for which regime, between which dates (this is where the QHC transition is recorded).", "db/021, db/030"),
#     ]),
#     ("Places — where rules apply", [
#         ("regulated_zones", "The 41 zones a planning scheme may use (Planning Regulation 2017 s6, sch 2).", "db/020"),
#         ("zones", "Each council scheme's zones, linked to the regulated zone, with whether a dwelling house is a permitted use.", "research/places.json via db/030"),
#         ("precincts", "Precincts inside a zone.", "research/places.json via db/030"),
#         ("overlays", "Overlays (flood, character, ridges, canals…).", "research/councils/*.json via db/030"),
#         ("local_plans", "Neighbourhood / local plans.", "research/places.json via db/030"),
#         ("local_plan_precincts", "Precincts inside a local plan.", "research/places.json via db/030"),
#     ]),
#     ("Vocabulary — what rules can talk about", [
#         ("building_classifications", "NCC building classes (1a, 2, 10a, 10b).", "db/010"),
#         ("structure_types", "Tree of things a rule can target (ANY → CLASS_10A → SHED; POOL → POOL_INGROUND …).", "db/010"),
#         ("structure_type_terms", "A document's own words mapped to the structure tree (not yet populated).", "—"),
#         ("facts", "The only inputs a rule may use (lot area, wall height, boundary type…), with type, unit and how to derive them.", "db/010, db/031, db/032"),
#         ("measurements", "What a numeric requirement is measured on: from where, to where, how.", "db/010, db/031, db/032"),
#     ]),
#     ("Rules — the regulatory content", [
#         ("rules", "Stable identity of a rule across versions (id, document, topic, title).", "db/021, db/030, db/031, db/032"),
#         ("rule_versions", "The rule content for one period: role, regime, enforceability, measurement, operator, value/formula (value_expr), unit, consequence of failure, dates, status (DRAFT/ACTIVE/SUPERSEDED), verification, automatable.", "same"),
#         ("rule_scopes", "Where a rule applies: council, zone, precinct, local plan, overlay (include or exclude).", "same"),
#         ("rule_subjects", "Which structure types a rule applies to (include or exclude).", "same"),
#         ("rule_conditions", "When a rule applies, e.g. lot_area_m2 >= 450. Rows with the same group_no are AND-ed; groups are OR-ed.", "same"),
#         ("rule_sources", "Why: the provision(s) a rule relies on, with the exact quote. Every active rule has a PRIMARY source.", "same"),
#         ("rule_relationships", "Precedence between rules: OVERRIDES, REPLACES, EXEMPTS, RELAXES, SUPPLEMENTS, ALTERNATIVE_TO, CONDITIONAL_ON, FALLS_BACK_TO, UNRESOLVED, each with its legal basis.", "same"),
#     ]),
#     ("Quality", [
#         ("verification_log", "Who checked which rule/provision, when, how (not yet populated).", "—"),
#         ("open_issues", "Known gaps and questions that block automation (incl. each research file's open_questions).", "db/021, db/030"),
#     ]),
# ]
#
# ER = """```mermaid
# erDiagram
#   authorities ||--o{ instruments : makes
#   authorities ||--o{ local_governments : is
#   local_governments ||--o{ instruments : "owns (schemes)"
#   instruments ||--o{ instrument_versions : "has versions"
#   instrument_versions ||--o{ provisions : contains
#   instrument_versions ||--o{ instrument_applicability : "applies via"
#   local_governments ||--o{ instrument_applicability : "in"
#   instruments ||--o{ zones : defines
#   regulated_zones ||--o{ zones : "corresponds to"
#   zones ||--o{ precincts : contains
#   instruments ||--o{ overlays : defines
#   instruments ||--o{ local_plans : defines
#   local_plans ||--o{ local_plan_precincts : contains
#   instruments ||--o{ rules : "source of"
#   rules ||--o{ rule_versions : "has versions"
#   instrument_versions ||--o{ rule_versions : "version of law"
#   measurements ||--o{ rule_versions : "measured by"
#   rule_versions ||--o{ rule_scopes : "applies where"
#   rule_versions ||--o{ rule_subjects : "applies to"
#   rule_versions ||--o{ rule_conditions : "applies when"
#   rule_versions ||--o{ rule_sources : "cites"
#   provisions ||--o{ rule_sources : "cited by"
#   rule_versions ||--o{ rule_relationships : "from"
#   rules ||--o{ rule_relationships : "to (all versions)"
#   facts ||--o{ rule_conditions : "tested in"
#   structure_types ||--o{ rule_subjects : ""
#   building_classifications ||--o{ structure_types : ""
#   zones ||--o{ rule_scopes : ""
#   precincts ||--o{ rule_scopes : ""
#   overlays ||--o{ rule_scopes : ""
#   local_plans ||--o{ rule_scopes : ""
#   local_plan_precincts ||--o{ rule_scopes : ""
#   local_governments ||--o{ rule_scopes : ""
# ```"""
#
# RESEARCH_MAP = """| Field in `research/councils/<council>.json` | Stored in |
# |---|---|
# | `planning_scheme` (name, version, version_commenced, official_urls) | `instruments` (kind PLANNING_SCHEME) + `instrument_versions` + `instrument_applicability` (regime PLANNING) |
# | `qdc_qhc_relationship.quotes[]` | `provisions` (kind APPLICATION, ref_label `QDC relationship: …`) |
# | `definitions[]` | `provisions` (kind DEFINITION, ref_label `def <term>`) |
# | `levels_of_assessment[]` | `provisions` (kind LEVEL_OF_ASSESSMENT, ref_label `LOA …`) |
# | `overlays_affecting_siting[]` | `overlays` + `provisions` (ref_label `overlay …`) |
# | `rules[]` → verbatim text, clause, page, URL, verification | `provisions` (one row per rule, `research_key` = `rule_key`) |
# | `rules[]` (except provision_type DEFINITION) → the rule | `rules` + `rule_versions` (status DRAFT, or SUPERSEDED once curated) + `rule_scopes` + `rule_subjects` + `rule_sources` |
# | `rules[].zones` | `rule_scopes`, mapped through `research/places.json` → zones / precincts / local plans |
# | `rules[].alternative_provision_to_qdc_qhc = YES` | `rule_relationships` type OVERRIDES → the matching QDC rules |
# | `open_questions[]` | `open_issues` |
# | `fetch_log[]` | not loaded (kept in the JSON as research provenance) |
#
# Curated rules (`db/031`, `db/032`) are hand-encoded from the same provisions. Each one `REPLACES` its draft,
# which then shows status SUPERSEDED."""
#
#
# def main():
#     ap = argparse.ArgumentParser()
#     ap.add_argument("--host", default="localhost")
#     ap.add_argument("--port", default="5432")
#     ap.add_argument("--db", default="siteora")
#     ap.add_argument("--user", default="postgres")
#     args = ap.parse_args()
#     cols = evaluate.query(args, """SELECT coalesce(json_agg(x ORDER BY table_name, ordinal_position), '[]') FROM (
#         SELECT c.table_name, c.column_name, c.ordinal_position, c.is_nullable,
#                CASE WHEN c.data_type = 'USER-DEFINED' THEN c.udt_name WHEN c.data_type = 'ARRAY' THEN replace(c.udt_name, '_', '') || '[]'
#                     ELSE c.data_type END AS type
#         FROM information_schema.columns c JOIN information_schema.tables t USING (table_schema, table_name)
#         WHERE c.table_schema = 'regs' AND t.table_type = 'BASE TABLE') x""")
#     pks = evaluate.query(args, """SELECT coalesce(json_agg(json_build_array(tc.table_name, kcu.column_name)), '[]')
#         FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu
#           ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
#         WHERE tc.table_schema = 'regs' AND tc.constraint_type = 'PRIMARY KEY'""")
#     fks = evaluate.query(args, """SELECT coalesce(json_agg(json_build_array(tc.table_name, kcu.column_name, ccu.table_name, ccu.column_name)), '[]')
#         FROM information_schema.table_constraints tc
#         JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
#         JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
#         WHERE tc.table_schema = 'regs' AND tc.constraint_type = 'FOREIGN KEY'""")
#     counts = dict(evaluate.query(args, """SELECT coalesce(json_agg(json_build_array(relname, n)), '[]') FROM (
#         SELECT c.relname, (xpath('/row/n/text()', query_to_xml(format('SELECT count(*) AS n FROM regs.%I', c.relname), false, true, '')))[1]::text::int AS n
#         FROM pg_class c JOIN pg_namespace ns ON ns.oid = c.relnamespace WHERE ns.nspname = 'regs' AND c.relkind = 'r') x"""))
#     pk = {(t, c) for t, c in pks}
#     fk = {(t, c): f"{rt}.{rc}" for t, c, rt, rc in fks}
#     by_table = {}
#     for c in cols:
#         by_table.setdefault(c["table_name"], []).append(c)
#
#     documented = {t for _, ts in GROUPS for t, _, _ in ts}
#     missing = set(by_table) - documented
#     if missing:
#         raise SystemExit(f"tables without a purpose in schema_doc.py: {sorted(missing)}")
#
#     out = [
#         "# Database plan — tables and relationships",
#         "",
#         "> Generated by `tools/schema_doc.py` from the live database (schema `regs`). Do not edit by hand: re-run the script after any schema change.",
#         "",
#         "## Where the data is",
#         "",
#         "* Database **`siteora`**, schema **`regs`** (26 tables, 7 views). The `public` schema is intentionally empty.",
#         "* In pgAdmin / DBeaver: `siteora → Schemas → regs → Tables`. `search_path` is set to `regs, public`, so plain `SELECT * FROM zones` works after reconnecting.",
#         "* Load or reload everything: `psql -h localhost -U postgres -d siteora -c \"DROP SCHEMA IF EXISTS regs CASCADE\"` then `psql -h localhost -U postgres -d siteora -v ON_ERROR_STOP=1 -f db/load_all.sql`.",
#         "* Verify: `python -I tools/verify_load.py` (research files → tables, record by record) and `python -I tools/check.py` (integrity + worked examples).",
#         "",
#         "## Relationships",
#         "",
#         ER,
#         "",
#         "Every arrow is a foreign key in the database, so a row cannot point at something that does not exist.",
#         "",
#         "## How the research files map to tables",
#         "",
#         RESEARCH_MAP,
#         "",
#         "## Tables",
#         "",
#     ]
#     for group, tables in GROUPS:
#         out += [f"### {group}", ""]
#         for t, purpose, source in tables:
#             out += [f"#### `{t}` — {counts.get(t, 0):,} rows", "", purpose, "", f"*Loaded by:* {source}", "",
#                     "| Column | Type | Null | Key / references |", "|---|---|---|---|"]
#             for c in by_table[t]:
#                 key = []
#                 if (t, c["column_name"]) in pk:
#                     key.append("**PK**")
#                 if (t, c["column_name"]) in fk:
#                     key.append(f"→ `{fk[(t, c['column_name'])]}`")
#                 out.append(f"| `{c['column_name']}` | {c['type']} | {'yes' if c['is_nullable'] == 'YES' else 'no'} | {' '.join(key)} |")
#             out.append("")
#     out += ["## Views", "",
#             "| View | Shows |", "|---|---|",
#             "| `v_rule_catalogue` | One readable row per rule version: topic, value, unit, primary clause, document, version, status |",
#             "| `v_active_rules` | Only the rules the engine uses (status ACTIVE) |",
#             "| `v_setback_rules`, `v_height_rules`, `v_site_coverage_rules`, `v_pool_rules` | Typed lists filtered from the catalogue |",
#             "| `v_rule_exceptions` | Every exemption / relaxation and the rule it affects |",
#             "| `v_untraceable_rules` | Rules with no PRIMARY source — must always be empty |", ""]
#     (ROOT / "db" / "README.md").write_text("\n".join(out), encoding="utf-8")
#     print(f"db/README.md written: {len(by_table)} tables, {len(fks)} foreign keys")
#
#
# if __name__ == "__main__":
#     main()
