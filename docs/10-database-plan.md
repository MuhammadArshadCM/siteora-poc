# Database plan — for review

**Status:** reviewed and applied 9 Oct 2026. Items 5.1–5.5 are applied in `siteora` (schema `regs`), and
5.8–5.10 are confirmed as-is. 5.6, 5.7 and 5.11 are deferred. Sections 2–3 describe the schema as it stood at
review; see "Changes applied" at the end for what changed.

Where to see it: pgAdmin / DBeaver → `siteora` → Schemas → **`regs`** → Tables (24) and Views (7).
`public` is intentionally empty.

---

## 1. Design principles

1. **One home for every rule.** All rule types (setback, height, site cover, pool, barrier…) share one set of
   tables. Typed lists such as "setback rules" are *views*, not separate tables, so versioning, sources and
   precedence work the same for every rule.
2. **Every number has a source.** A rule cannot be inserted without a link to a stored clause with its exact
   words, page, document version and file hash.
3. **Rules are versioned, never overwritten.** A change creates a new version row with new dates, and the old
   row is closed.
4. **Conditions and formulas are data.** No program code is stored in the database.
5. **Precedence is explicit.** "Council rule X replaces QDC rule Y" is a stored row with its legal basis. It is
   never guessed from which rule looks more specific.
6. **Geometry stays out.** This schema says *what to measure*. Lot boundaries and building footprints belong in
   the application's PostGIS tables.

---

## 2. The tables at a glance

```
 SOURCES (where the law comes from)              PLACES (where it applies)
 ─────────────────────────────────              ─────────────────────────
 authorities ──< instruments ──< instrument_versions ──< provisions
                     │                 │                (verbatim clauses)
                     │                 └──< instrument_applicability   (which version applies to which council, when)
 local_governments ──┘
                     ├──< zones ──< precincts
                     ├──< overlays
                     └──< local_plans

 VOCABULARY (what can be described)              RULES (the regulatory content)
 ──────────────────────────────────              ──────────────────────────────
 building_classifications                        rules ──< rule_versions ──┬──< rule_scopes      (where)
 structure_types ──< structure_type_terms                                   ├──< rule_subjects    (what structure)
 facts            (allowed inputs)                                          ├──< rule_conditions  (when)
 measurements     (what is measured, how)                                   ├──< rule_sources     (why — clause + quote)
                                                                            └──< rule_relationships (precedence)
 QUALITY
 ───────
 verification_log, open_issues
```

`──<` means "one to many".

---

## 3. Table-by-table

Row counts are as loaded today.

### 3.1 Sources

| Table | Rows | Purpose | Key columns |
|---|---|---|---|
| `authorities` | 11 | Who makes law: Parliament, State, ABCB, Standards Australia, 7 councils | `authority_id` (e.g. `BCC`), `name`, `authority_type` |
| `local_governments` | 7 | The councils in scope | `lg_id` (e.g. `BRISBANE`), `official_name`, `former_names` |
| `instruments` | 20 | A document: Act, Regulation, QDC part, planning scheme, Australian Standard | `instrument_id` (e.g. `QDC_MP_1_2`), `kind`, `force` (statute / statutory instrument / adoptable / referenced standard / guidance), `lg_id` for schemes |
| `instrument_versions` | 19 | One published version or reprint of a document | `instrument_version_id` (e.g. `QDC_MP_1_2@2010-03-26`), `version_label`, `published_date`, `effective_from`, `effective_to`, `status`, `source_url`, `local_file`, `file_sha256`, `retrieved_at`, `verified_at` |
| `provisions` | 661 | One clause, table row or figure, with its **exact words** | `provision_id`, `instrument_version_id`, `ref_label` (e.g. `A2(d)`), `kind`, `page_label`, `pdf_page`, `url_anchor`, `verbatim_text`, `verification` |
| `instrument_applicability` | 32 | Which document version applies to which council, for which regime, between which dates. **This is where the QHC transition lives.** | `instrument_version_id`, `lg_id` (null = statewide), `regime`, `effective_from`, `effective_to`, `end_condition`, `basis_provision_id` |

### 3.2 Places

| Table | Rows | Purpose | Key columns |
|---|---|---|---|
| `zones` | 89 | Planning-scheme zones | `zone_id` (e.g. `BCC:LOW_DENSITY_RESIDENTIAL_ZONE`), `instrument_id`, `zone_code`, `name`, `dwelling_house_permitted` |
| `precincts` | 6 | Precincts inside a zone | `precinct_id`, `zone_id`, `name` |
| `overlays` | 46 | Overlays (flood, character, ridges…) | `overlay_id`, `instrument_id`, `name`, `is_relevant_overlay` |
| `local_plans` | 1 | Neighbourhood / local plans | `local_plan_id`, `instrument_id`, `name`, `plan_type` |

### 3.3 Vocabulary

| Table | Rows | Purpose | Key columns |
|---|---|---|---|
| `building_classifications` | 4 | NCC classes 1a, 2, 10a, 10b | `ncc_class`, `description` |
| `structure_types` | 28 | Tree of things a rule can target: `ANY → CLASS_10A → SHED`, `POOL → POOL_INGROUND`… | `structure_type_id`, `parent_id`, `ncc_class`, `is_building` |
| `structure_type_terms` | 0 | Maps a document's own words ("open carport", "covered outdoor room") onto the tree | `instrument_id`, `term`, `structure_type_id` |
| `facts` | 84 | The only inputs a rule may use (lot area, wall height, boundary type…), with type and unit | `fact_id`, `type`, `unit`, `allowed_values`, `source` (property data / design input / geometry…), `derivation` |
| `measurements` | 47 | What a numeric requirement is measured on: from where, to where, how | `measurement_id`, `measurement_type` (min distance, max height, area ratio…), `subject_geometry`, `reference_geometry`, `evaluate_per_part`, `postgis_hint` |

### 3.4 Rules

| Table | Rows | Purpose | Key columns |
|---|---|---|---|
| `rules` | 439 | Stable identity of a rule across versions | `rule_id`, `instrument_id`, `topic` (e.g. `SETBACK.SIDE_REAR`), `title` |
| `rule_versions` | 439 | **The rule content for one period** | `rule_version_id`, `role` (requirement / exemption / relaxation / trigger), `regime` (building / planning / pool safety…), `enforceability`, `measurement_id`, `operator`, `value_expr` (number or formula), `unit`, `on_noncompliance`, `effective_from/to`, `status` (DRAFT / ACTIVE / SUPERSEDED), `verification`, `automatable`, `interpretation_notes` |
| `rule_scopes` | 1,490 | Where it applies: State, council, zone, precinct, overlay, local plan (include or exclude) | `rule_version_id`, `level`, `lg_id`/`zone_id`/`precinct_id`/`overlay_id`/`local_plan_id`, `exclude` |
| `rule_subjects` | 704 | Which structure types it applies to (include or exclude) | `rule_version_id`, `structure_type_id`, `exclude` |
| `rule_conditions` | 392 | When it applies: "lot area ≥ 450", "boundary is SIDE or REAR". Rows in a group are AND; groups are OR. | `rule_version_id`, `group_no`, `fact_id`, `operator`, `value` |
| `rule_sources` | 476 | Why: the clause(s) relied on, with the exact quote | `rule_version_id`, `provision_id`, `role` (PRIMARY / DEFINITION / …), `quote` |
| `rule_relationships` | 479 | Precedence between rules | `from_rule_version_id`, `to_rule_version_id` or `to_rule_id`, `type` (OVERRIDES, REPLACES, EXEMPTS, RELAXES, SUPPLEMENTS, ALTERNATIVE_TO, CONDITIONAL_ON, FALLS_BACK_TO, UNRESOLVED), `basis_provision_id` |

### 3.5 Quality

| Table | Rows | Purpose |
|---|---|---|
| `verification_log` | 0 | Who checked which rule/clause, when, how, and the result |
| `open_issues` | 70 | Known gaps and questions blocking automation |

### 3.6 Views

| View | Shows |
|---|---|
| `v_rule_catalogue` | One readable row per rule version: value, unit, clause, document, version, status |
| `v_setback_rules`, `v_height_rules`, `v_site_coverage_rules`, `v_pool_rules` | The typed lists from your brief, filtered from the catalogue |
| `v_rule_exceptions` | Every exemption and relaxation and what it affects |
| `v_untraceable_rules` | Rules with no source — must always be empty |

---

## 4. One rule traced through the tables

"QDC MP 1.2 A2(a): side and rear clearance 1.5 m / 2 m / +0.5 m per 3 m, by height of each part."

| Table | Row(s) |
|---|---|
| `instruments` | `QDC_MP_1_2` — QDC MP 1.2, kind QDC_MANDATORY_PART |
| `instrument_versions` | `QDC_MP_1_2@2010-03-26` — published 11 Mar 2010, file `mp1-2.pdf`, sha256 `27f8…cb20` |
| `instrument_applicability` | MP 1.2 applies to `BRISBANE` (and each other council) for BUILDING from 2026-09-01 to 2029-08-31, ending earlier if the council adopts the QHC; basis = Building Reg s106 |
| `provisions` | `A2(a)`, page 9: *"(i) where the height of that part is 4.5m or less - 1.5m; and (ii) …"* |
| `rules` | `QDC12.A2a.SIDE_REAR_CLEARANCE`, topic `SETBACK.SIDE_REAR` |
| `rule_versions` | `…@2010-03-26`: REQUIREMENT, BUILDING, DEEMED_TO_COMPLY, measurement `MP_SIDE_REAR_CLEARANCE_OMP`, operator `>=`, value = `case part_height ≤ 4.5 → 1.5; ≤ 7.5 → 2.0; else 2 + 0.5 × ceil((h − 7.5)/3)`, unit m, on fail → REFERRAL_TO_LOCAL_GOVERNMENT |
| `rule_scopes` | STATE |
| `rule_subjects` | CLASS_1, CLASS_10A, OUTDOOR_STRUCTURE, CLASS_10B; **exclude** POOL |
| `rule_conditions` | group 1: lot_area ≥ 450 AND road_frontage > 15 AND boundary_type IN (SIDE, REAR); group 2: lot_area ≥ 450 AND lot not rectangular AND boundary_type IN (SIDE, REAR) |
| `rule_sources` | PRIMARY → provision `A2(a)` with quote; DEFINITION → "outermost projection" |
| `rule_relationships` | `A2(c)` fences EXEMPTS this; `A2(d)` Class 10a RELAXES this; Gold Coast zone rule OVERRIDES this in its zone |

---

## 5. Review findings and proposed changes

Each item has a recommendation. Reply with the item numbers you accept, change or reject.

### High priority

**5.1 Clean up `zones`.** The 89 rows were created from the text the researchers wrote, so:
- some are not zones at all: `BCC:ALL`, `BCC:ANY`, "any zone in Traditional building character overlay";
- some are precincts or neighbourhood-plan areas stored as zones: `LCC:LOW_DENSITY_RESIDENTIAL_ZONE_SMALL_LOT_PRECINCT`, `BCC:NP_LOW_DENSITY_LIVING_PRECINCT_NPP_001`;
- there is one duplicate with a heading artefact: `…NPP_002_HEADING_RULE_9496…`.

*Proposal:* rebuild the place tables from each scheme's official zone and precinct list:
- `zones` holds real zones only, using the scheme's own codes;
- `precincts` holds zone precincts;
- `local_plans` and a new `local_plan_precincts` table hold neighbourhood-plan areas;
- pseudo-zones ("all", "any") are deleted, and those rules are scoped to the council instead.

Curated rules are re-pointed to the clean IDs. The same `zone_code` must later match the code in your zone map layer.

**5.2 Fill in `zones.dwelling_house_permitted`.** It is empty for all 89 zones, but it decides whether the QHC
applies at all (QHC s4(2)). *Proposal:* set it from each scheme's table of assessment (the research already
quotes those tables), with the source clause.

**5.3 Make the schema visible by default.** *Proposal:* `ALTER DATABASE siteora SET search_path = regs, public;`
so queries work without the `regs.` prefix. This touches no data.

### Medium priority

**5.4 Separate draft council rules from live rules.** 200 drafts sit in `rule_versions` with status DRAFT next to
the 175 active ones. The engine ignores them, but they clutter the tables and views.
*Option A (recommended):* keep them in place and add `v_active_rules`, a view of ACTIVE rules only.
*Option B:* move drafts to a staging schema, `regs_staging`, and promote rules into `regs` only once curated.

**5.5 Tidy council clause labels.** Council `provisions.ref_label` values carry a research key, e.g.
`Table 9.3.2.3.1 PO7/AO7.1(a) [dh_ao7_1a_outbuilding_total_floor_area_150]`. *Proposal:* add a `research_key`
column, keep `ref_label` as the real clause label, and add `section`/`clause`/`table_ref` values where known.

**5.6 Lock verified rules and add audit columns.** *Proposal:*
- add `created_by`, `updated_at` and `updated_by` to `rule_versions` and `provisions`;
- add a trigger that blocks edits to the content of an ACTIVE, verified rule version (a change must create a new version instead);
- fill `verification_log` from the research fetch logs, so each provision records when, how and from which URL it was taken.

**5.7 Consistent value lists.** A few columns use free text with a check list (`authority_type`,
`measurement_type`, `rule_sources.role`, `open_issues.severity`, `local_plans.plan_type`), while others use
Postgres enum types. *Proposal:* make them all enum types, for consistency and clearer documentation in the UI.

### Low priority / confirm only

**5.8 Keys stay readable text** (`QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26`) rather than numeric IDs. They are
stable, self-explanatory in logs, and the dataset is small. *Recommend: keep.*

**5.9 Typed rule tables stay as views** (`v_setback_rules` etc.), not separate tables. *Recommend: keep* (see principle 1).

**5.10 Only the current version of each council scheme is loaded.** Historic versions are needed only to
validate past approvals. *Recommend: add later, on demand.*

**5.11 `structure_type_terms` is empty.** *Proposal:* fill it with the defined terms already captured, such as
QHC "covered outdoor room", "carport" and "gatehouse", and MP 1.2 "open carport", so each document's wording maps
to the structure tree with its definition clause.

---

## 6. How changes get stored

1. Apply the accepted items to the SQL files in `db/`, with schema changes in `001_schema.sql` and data
   changes in the data files. For 5.1, the generator (now `npm run import-research`) gets a zone mapping.
2. Rebuild in a scratch database and run the regression check (now `npm run check`): all invariants and example outputs must pass. Any
   change in an example's result is shown to you before going further.
3. Rebuild `regs` in `siteora` (`DROP SCHEMA regs CASCADE` + `db/load_all.sql`). Only the `regs` schema is touched.
4. Re-run the regression check (`npm run check`) against `siteora` and report the new row counts.

---

## Changes applied (9 Oct 2026)

| Item | Decision | What changed |
|---|---|---|
| 5.1 Zones | Applied | New `research/places.json` lists each council's real zones (scheme names), precincts, local plans and local-plan precincts. It maps every zone string in the research to proper scopes. The generator now fails if research mentions an unmapped place. New tables: `regulated_zones` (the 41 zones allowed by Planning Regulation 2017 s6 / sch 2, with the clause) and `local_plan_precincts`. `zones.regulated_zone_id` links each scheme zone to its regulated zone. Pseudo-zones ("all", "any") are gone; those rules are now council-wide. Result: 47 zones, 29 precincts, 7 local plans, 5 local-plan precincts. Curated rules re-pointed. |
| 5.1 (scope semantics) | Applied | Zone, precinct, local-plan and local-plan-precinct scope rows are now **alternatives** (a rule listing "Emerging community zone" and "LDR Acreage precinct" applies in either). Overlays remain a separate must-match group, and exclude rows still remove the rule. See docs/07. |
| 5.2 Dwelling house permitted | Applied | Set from each scheme's table of assessment, with the table recorded in `zones.dwelling_house_basis`. 33 zones true, 1 false (Redland Conservation zone), 13 left NULL where the research does not establish it. |
| 5.3 search_path | Applied | `load_all.sql` runs `ALTER DATABASE … SET search_path = regs, public`; reconnect to see tables without the `regs.` prefix. |
| 5.4 Drafts | Option A | Drafts stay in `rule_versions` (status DRAFT); new view `v_active_rules` shows only rules the engine uses. |
| 5.5 Clause labels | Applied | New `provisions.research_key`. Council `ref_label` is now the clause as printed, e.g. `Table 9.3.2.3.1 PO7/AO7.1(a)`. Curated rules cite council clauses by research key. |
| 5.6 Audit + lock | Deferred | — |
| 5.7 Enums | Deferred | — |
| 5.8–5.10 | Kept as recommended | — |
| 5.11 Term mapping | Deferred | — |

Verification: full rebuild + regression check PASS. All six example scenarios produce the same rule results as
before the change; only the printed clause labels changed (the research-key suffix was removed).
