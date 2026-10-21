# Part 8 — Sample PostgreSQL data

The dataset is plain SQL. Load order is in [`db/load_all.sql`](../db/load_all.sql).

| File | Content |
|---|---|
| `001_schema.sql` | Types, tables, views |
| `002_loader.sql` | `define_provision()`, `define_rule()`, `relate()`, `restrict_boundary()`, `p()`, `pk()`, `supersede_draft()`, `alt_overrides()` |
| `010_reference_data.sql` | Authorities, 7 local governments, state instruments and versions (with SHA-256), structure taxonomy, core facts and measurements (84 facts, 47 measurements in total incl. those added by curated files) |
| `020_state_provisions.sql` | Verbatim clauses from the Building Act, Building Regulation, Planning Regulation, QHC, MP 1.1, MP 1.2, MP 1.4, MP 3.4, NMP 1.9 |
| `021_state_rules.sql` | 106 state rule versions, relationships, state-wide and per-LG instrument applicability, open issues |
| `030_council_*.sql` | **Generated** from `research/councils/*.json`: scheme + version, zones, overlays, every quoted provision, draft rules |
| `031_council_curated.sql`, `032_council_curated_batch2.sql`, `033_council_curated_brisbane.sql` | Hand-encoded council rules (85) that the engine uses |

## Excerpt — a verified provision

```sql
SELECT define_provision('QDC_MP_1_2@2010-03-26', 'A2(d)', 'ACCEPTABLE_SOLUTION',
$t$(d) Subject to A2(c), class 10a buildings or parts may be within the boundary clearances nominated in A2(a)
and (b) where – (i) the height of a part within the boundary clearance is not more than 4.5m and has a mean
height of not more than 3.5m; and (ii) the total length of all buildings or parts, of any class, within the
boundary clearance is not more than 9m along any one boundary; and (iii) the class 10a buildings or parts within
the boundary clearance are located no closer than 1.5m to a required window in a habitable room of an adjoining
dwelling.$t$, 'VERIFIED_VERBATIM', 'Page 10-11', 10);
```

## Excerpt — a council alternative provision overriding the QDC

```sql
SELECT define_rule($r${
 "rule_id": "CMB.C.RR_SIDE_REAR_SETBACK", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.SIDE_REAR", "title": "Rural residential: side and rear setback by wall height (1.5 / 2 / 4 m)",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY",
 "provision_kind": "ACCEPTED_DEVELOPMENT_REQUIREMENT", "measurement": "SCHEME_SETBACK_SIDE", "operator": ">=", "unit": "m",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "wall_height_m"}, 3.0]}, "then": 1.5},
                                  {"if": {"op": "<=", "args": [{"var": "wall_height_m"}, 4.5]}, "then": 2.0}], "else": 4.0},
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"}, {"level": "ZONE", "zone": "CMB:RURAL_RESIDENTIAL_ZONE"}],
 "subjects": ["CLASS_1", "CLASS_10A"],
 "conditions": [[{"fact": "boundary_type", "op": "IN", "value": ["SIDE", "REAR"]},
                 {"fact": "development_footprint_exists", "op": "IS_FALSE"}]],
 "sources": [{"ref": "Table 6.2.11.1 RAD48 (E60) [mb_rr_rad48_side_rear_setback]", "role": "PRIMARY", "quote": "..."}],
 "verification": "VERIFIED_VERBATIM", "automatable": true, "effective_from": "2026-09-11", ...}$r$);
SELECT alt_overrides('CMB.C.RR_SIDE_REAR_SETBACK@2026-09-11',
  ARRAY['QDC12.A2a.SIDE_REAR_CLEARANCE','QDC12.A2b.NARROW_LOT_CLEARANCE','QDC12.A2d.CLASS10A_WITHIN_CLEARANCE'],
  'RAD48 note: alternative provision to QDC MP1.2 A2(a), (b) and (d).');
```

## Flat tabular view (the shape you sketched)

```sql
-- regulatory_rules
SELECT rule_version_id, topic, regime, enforceability, measurement_id, operator, value_expr, unit,
       primary_clauses, instrument, version_label, verification, automatable
FROM regs.v_rule_catalogue WHERE status = 'ACTIVE';
-- rule_conditions
SELECT rule_version_id, group_no, fact_id, operator, value FROM regs.rule_conditions;
-- regulatory_sources
SELECT i.authority_id, i.title, iv.version_label, p.ref_label, p.page_label, iv.source_url, iv.effective_from
FROM regs.provisions p JOIN regs.instrument_versions iv USING (instrument_version_id) JOIN regs.instruments i USING (instrument_id);
```

## Regenerating council data

```bash
npm run import-research                         # rewrites db/030_council_*.sql from research/councils/*.json
```
