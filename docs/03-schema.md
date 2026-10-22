# Part 3 — Database schema

DDL: [`db/001_schema.sql`](../db/001_schema.sql). Loader functions: [`db/002_loader.sql`](../db/002_loader.sql).
Everything lives in schema `regs`. No PostGIS dependency: the dataset stores *what to measure*;
geometry lives in the application database.

## 1. Entity overview

```
authorities ─┬─ local_governments
             └─ instruments ── instrument_versions ── provisions (clause tree, verbatim text)
                     │                 │
                     │                 └── instrument_applicability (which version governs which LG, when, for which regime)
                     ├─ zones ── precincts            (zones.regulated_zone_id → regulated_zones, Planning Reg sch 2)
                     ├─ overlays
                     └─ local_plans ── local_plan_precincts

rules ── rule_versions ─┬─ rule_scopes      (LG must match; ZONE / PRECINCT / LOCAL_PLAN / LOCAL_PLAN_PRECINCT are alternatives; OVERLAY must match)
                        ├─ rule_subjects    (structure_types taxonomy, include/exclude)
                        ├─ rule_conditions  (DNF: OR of AND-groups over facts)
                        ├─ rule_sources     (≥1 PRIMARY provision, with the exact quote relied on)
                        ├─ measurement_id → measurements (what is measured, from what, to what)
                        └─ value_expr       (typed expression AST, jsonb)
rule_relationships  (OVERRIDES, REPLACES, MODIFIES, EXEMPTS, RELAXES, SUPPLEMENTS, ALTERNATIVE_TO,
                     CONDITIONAL_ON, FALLS_BACK_TO, DEFINES_TERM_FOR, UNRESOLVED) — each with a legal basis provision
facts               (the only inputs rules may reference)
structure_types, structure_type_terms, building_classifications
verification_log, open_issues
views: v_rule_catalogue, v_active_rules, v_setback_rules, v_height_rules, v_site_coverage_rules, v_pool_rules,
       v_rule_exceptions, v_untraceable_rules (must be empty)
```

Why this shape rather than `setback_rules`, `height_rules`, `pool_rules` tables: the rules share one
lifecycle (versioning, sources, scopes, precedence). Splitting by type would duplicate all of that and make
cross-type relationships (e.g. a pool rule that falls back to a dwelling setback) awkward. The typed tables you
asked for exist as **views** over `v_rule_catalogue`.

## 2. Rule representation

A rule is authored as one JSON document and normalised by `regs.define_rule()`:

```json
{
 "rule_id": "QDC12.A2a.SIDE_REAR_CLEARANCE", "instrument_version": "QDC_MP_1_2@2010-03-26",
 "topic": "SETBACK.SIDE_REAR", "title": "Side and rear boundary clearance by height of part",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "MP_SIDE_REAR_CLEARANCE_OMP", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [
     {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 4.5]}, "then": 1.5},
     {"if": {"op": "<=", "args": [{"var": "part_height_m"}, 7.5]}, "then": 2.0}],
   "else": {"op": "+", "args": [2.0, {"op": "*", "args": [0.5,
           {"op": "ceil", "args": [{"op": "/", "args": [{"op": "-", "args": [{"var": "part_height_m"}, 7.5]}, 3]}]}]}]}},
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT",
 "subjects": ["CLASS_1", "CLASS_10A", "OUTDOOR_STRUCTURE", "CLASS_10B", {"id": "POOL", "exclude": true}],
 "conditions": [[{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "road_frontage_m", "op": ">", "value": 15}],
                [{"fact": "lot_area_m2", "op": ">=", "value": 450}, {"fact": "lot_is_rectangular_or_near", "op": "IS_FALSE"}]],
 "sources": [{"ref": "A2(a)", "role": "PRIMARY", "quote": "(i) where the height of that part is 4.5m or less - 1.5m; ..."}],
 "verification": "VERIFIED_VERBATIM", "automatable": true,
 "interpretation_notes": "Evaluated per part ... 'every 3m or part' => ceil.",
 "effective_from": "2010-03-26", "effective_to": "2029-08-31"
}
```

* **Conditions** decide *whether* the rule applies. They are stored as rows (`rule_conditions`) in disjunctive
  normal form: the rule applies if any `group_no` has all its rows true. Rows are queryable and indexable
  ("which rules depend on lot width?").
* **The value** says *what is required*. It is an expression tree, so a requirement can be a constant, a
  tiered function of height, a lookup table, a graph, or a reference to another rule's value.
* **Unknown facts are first-class.** A missing input yields UNKNOWN (not false), and the engine routes the rule
  to manual review instead of passing it.

### Expression language (safe, non-Turing-complete)

| Node | Meaning |
|---|---|
| number / string / bool / null | literal (`null` = "no value stated" ⇒ manual review) |
| `{"var": "fact_id"}` | a fact from `regs.facts` (validated vocabulary with units and derivation rules) |
| `+ - * /`, `min`, `max`, `ceil` | arithmetic |
| `<= < >= > =`, `is_true` | comparisons (inside `case`) |
| `{"op":"case","when":[{"if":…,"then":…}],"else":…}` | first matching branch |
| `{"op":"switch","on":{"var":"boundary_type"},"cases":{…},"default":…}` | table columns (e.g. QHC frontage types) |
| `{"op":"lookup_range","x":…,"rows":[{"min","max","value"}]}` | banded tables (MP 1.2 Table A2) |
| `{"op":"interpolate","x":…,"points":[[x,y],…],"extrapolate":"NONE"}` | graphs (MP 1.2 Table A1) — outside the drawn range returns null |
| `min_of / max_of / avg_of` | over array facts (neighbour setbacks) |
| `{"op":"unencoded","text":…}` | provision captured but not yet encoded — always manual review |

No loops, no user functions, no I/O. The evaluator is around 60 lines ([`server-ts/src/core/evaluate.ts`](../server-ts/src/core/evaluate.ts) `ev()`), and
porting it to SQL, TypeScript or Rust is trivial. Formulas from the law are kept **exactly** as published
(e.g. QHC Table A1 `(lot width − 5.34) / 3.11`). Any clamping or rounding not in the text is **not** added;
it is noted in `interpretation_notes`.

## 3. Measurement definitions

`measurements` records, for each numeric requirement: `measurement_type` (MIN_HORIZONTAL_DISTANCE,
MAX_VERTICAL_HEIGHT, MEAN_HEIGHT, AREA_RATIO, AREA, LENGTH_ALONG_BOUNDARY, WIDTH, EXCLUSION_ZONE,
CLEAR_ZONE, PRESENCE, COMPOSITE), `subject_geometry`, `reference_geometry`, `boundary_selector`,
`vertical_projection`, `evaluate_per_part` and a PostGIS hint. The measuring point differs by instrument, and
this matters:

| Instrument | Building | Structure | Pool | Garage door |
|---|---|---|---|---|
| MP 1.1/1.2 (2010) | **outermost projection** (incl. fascia, attached sunhoods) | outermost projection | water's edge | — |
| QHC (2026) | **façade of the external wall** (eaves tested separately as "weather control elements") | outermost projection (Planning Reg sch 4) | water's edge | door to the access boundary |
| Planning schemes | per scheme definition (usually OMP) | per scheme | per scheme | per scheme |

Cases that are not a simple minimum distance: per-part clearances that vary with the height of each part
(`evaluate_per_part`); aggregate built-to-boundary length along one boundary (including existing buildings
of any class under MP 1.x); corner truncation exclusion zones; MP 1.4 clear zones (3-D, infinite height over
maintenance covers); site cover ratios with instrument-specific inclusions; mean height = elevational area ÷
length.

## 4. Versioning

* `instrument_versions` holds one row per published version or reprint, with `effective_from`/`effective_to`,
  `published_date`, `superseded_by`, `status`, URL, archived file and SHA-256.
* `rule_versions` holds the rule content per period (`effective_from`, `effective_to`, `status`). A
  rule's identity (`rules`) is stable across versions, so history and diffs are queryable.
* `instrument_applicability` answers "which version governs **this council** on **this date** for **this
  regime**". This is essential because the same QDC part can be in force in one LGA and not another (QHC
  transition).
* **Which date?** Building assessment uses the provisions in force **when the application is approved**
  (Building Act s36(2)). The engine takes `assessment_date` as an input and resolves everything as at that
  date. Historical validation ("was this compliant when built?") is the same query with an older date.
* Rule versions are never updated in place after verification. A change creates a new version and closes the
  old one. `verification_log` records who checked what, against which file hash.

## 5. Traceability

Every active rule version must have a PRIMARY `rule_sources` row pointing to a `provisions` row with
`verbatim_text`, `ref_label` (section / clause / table / row), `page_label`, `pdf_page`, `url_anchor`, and
instrument version (URL, file hash, retrieved/verified dates). `define_rule()` refuses to load a rule without
one, and `v_untraceable_rules` must return zero rows (it does). The engine can therefore always say:

> "Side setback ≥ 1.5 m — rule `QDC12.A2a.SIDE_REAR_CLEARANCE`, QDC MP 1.2 (published 11 Mar 2010) A2(a)(i):
> 'where the height of that part is 4.5m or less - 1.5m'."

## 6. Two-tier council data

* `db/030_council_*.sql` is **generated** from the research files (`research/councils/*.json`) by
  `server-ts/src/tools/import-council-research.ts` (`npm run import-research`). Every quoted provision is loaded verbatim, and every extracted rule is loaded
  as a `DRAFT`, `automatable = false` rule with the extracted value and the conditions kept as text.
* `db/031_council_curated.sql` to `db/036_council_curated_remaining_zones.sql` are hand-encoded: proper scopes (zones/precincts/local plans), subjects,
  conditions and expressions. Each curated rule `REPLACES` its draft, which becomes `SUPERSEDED`.
  Only curated (ACTIVE) rules are used by the engine.

This keeps everything traceable now while making the automation boundary explicit.
