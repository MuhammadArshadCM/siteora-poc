# Siteora — Queensland siting rules dataset (Class 10a & pools)

A versioned, source-traceable PostgreSQL dataset of the rules that govern setbacks and related controls for
Class 10a structures and swimming pools in seven South-East Queensland councils, plus a reference resolver.

Status as at **9 Oct 2026**.

## Headline findings

* **Legacy QDC MP 1.1/1.2 (2010) still govern siting in all seven councils.** The Queensland Housing Code
  commenced 1 Sep 2026, but under Building Regulation 2021 s106 an existing scheme keeps MP 1.1/1.2 until the
  council amends its scheme to adopt the QHC, or until **1 Sep 2029**. None of the seven councils has adopted it.
  The dataset holds both rule sets and switches per council by date.
* **Council rules displace the QDC only where the scheme declares them** as alternative provisions (Building Act
  s33) or s32 standards. Every other council number belongs to the planning track.
* There is **no Queensland "Pool Safety Act"**. Pool barriers sit in Building Act ch 8, and the pool safety
  standard is QDC MP 3.4 (with AS 1926.1/.2-**2007** as modified).

## Contents

| Path | What |
|---|---|
| [`docs/01-regulatory-source-map.md`](docs/01-regulatory-source-map.md) | Part 1 — instruments, legal relationships, council schemes in force |
| [`docs/02-rule-taxonomy.md`](docs/02-rule-taxonomy.md) | Part 2 — rule topics and classification dimensions |
| [`docs/03-schema.md`](docs/03-schema.md) | Part 3 — schema, expression language, measurement, versioning, traceability |
| [`docs/04-council-rules.md`](docs/04-council-rules.md) | Part 4 — per-council findings and curated rules |
| [`docs/05-qdc-and-qhc.md`](docs/05-qdc-and-qhc.md) | Part 5 — QDC/QHC provisions and their interaction with local rules |
| [`docs/06-pool-rules.md`](docs/06-pool-rules.md) | Part 6 — pool setbacks and barriers |
| [`docs/07-precedence.md`](docs/07-precedence.md) | Part 7 — precedence algorithm |
| [`docs/08-sample-data.md`](docs/08-sample-data.md) | Part 8 — SQL files and excerpts |
| [`docs/09-example-evaluation.md`](docs/09-example-evaluation.md) | Part 9 — worked example (Brisbane, 2026 and 2029; Gold Coast contrast) |
| [`docs/11-project-plan.md`](docs/11-project-plan.md) | Project plan — Class 10a + pool siting check (five items, scheme updates, QDC→QHC switch) |
| [`docs/12-client-questions.md`](docs/12-client-questions.md) | Questions for the client about inputs (neighbour setbacks, built to boundary, height, site cover…) |
| [`docs/13-map-services.md`](docs/13-map-services.md) | Map services per council: zoning, local plans, overlays, mapped heights, road hierarchy, canals; access approach and licences |
| [`db/`](db/) | Historical schema + data as hand-applied SQL files (001-069); superseded by `server-ts/src/migrations/` (see below) as the source of truth for building a database from scratch — kept for provenance/history, not for loading a fresh database any more |
| [`research/councils/`](research/councils/) | Raw council research (verbatim quotes, URLs, fetch logs, open questions) |
| [`server-ts/`](server-ts/README.md) | **The application** (TypeScript / Ts.ED): web page + API on :8766, rules engine, command-line tools, parity test |
| [`server-ts/src/core/evaluate.ts`](server-ts/src/core/evaluate.ts) | Rule resolver (which rule applies, what value, why) |
| [`server-ts/src/tools/`](server-ts/src/tools/) | `check` (integrity invariants + recorded examples), `verify-load`, `import-research` (regenerates `db/030_council_*.sql`), `validate-setbacks` (read-only setback audit → `validation/`), `schema-doc`, `check-services`, `cli`, `evaluate` |
| [`docs/data-sources-register.xlsx`](docs/data-sources-register.xlsx) | Data source register: every API and map layer used, who publishes it, when it was last updated, licence, issues (`npm run data-register` refreshes it) |
| [`examples/`](examples/) | Scenarios and their outputs |
| [`validation/`](validation/validation_report.md) | Setback dataset validation (14 councils, 22 Oct 2026): report, CSVs, proposed change sets. `npm run validate-setbacks` re-runs it (read-only) |
| [`poc/`](poc/README.md) | Web page, map-service configuration (`zoning_layers.json`, `site_layers.json`) and `.env` used by the server; the original Python code, retired and commented out |
| [`tools/`](tools/) | The original Python tools, retired and commented out (replaced by `server-ts/src/tools/`) |

## Load and run

```bash
# fresh database (schema `regs`), built from server-ts/src/migrations/ via TypeORM — this is now the only
# supported way to build a database from scratch (see "Database migrations" below for details/history):
export PGPASSWORD=...                                          # local password
createdb -h localhost -U postgres siteora                      # first time only
cd server-ts
npm run install:server                                         # first time only
npm run migration:run                                          # builds + applies every migration in order
npm run check                                                  # integrity invariants + recorded example outputs
npm run verify-load                                            # every research record is in the database unchanged
npm run evaluate -- examples/brisbane_shed_pool.json           # defaults: localhost:5432 / siteora / postgres
npm start                                                      # web page + API: http://localhost:8766
```

Requires PostgreSQL 13+ (tested on 18.6) and Node.js 20+. The database password goes in `poc/.env`
(`PG_PASSWORD = ...`). Python is no longer needed: the original Python code is kept, commented out, for reference.

## External map services — rate limits and caching

Every zone/overlay/cadastre/geocoding lookup calls a public Queensland Government or council ArcGIS service, all
anonymous (no API key). These enforce a rate limit that is **shared across every caller of that organisation's
services, not just this app** — so a council's own staff traffic, or anyone else's, can exhaust the budget and
your requests get throttled as collateral, worst exactly during AU business hours (peak usage for everyone,
including real users of this app). `server-ts/src/core/geo.ts`'s `getJson()` caches every response in-memory for
7 days (`SITEORA_GEO_CACHE_TTL_MS` to change it, `SITEORA_NO_CACHE=1` to disable for debugging) — this is the
main mitigation, since it reduces how often this app asks at all, which helps regardless of who else is using the
shared quota that hour. `GET /api/admin/cache-stats` shows hit/miss counts. This sits below, and is complementary
to, `engine.ts`'s separate `locateCached()` (a 2-minute cache for the same-session "fill in a blank and
resubmit" case, not a rate-limit mitigation). Still open: the cache is in-memory only (cleared on restart); a
Postgres-backed cache, and mirroring the slow-changing layers (zoning/overlays) into local PostGIS on a periodic
sync instead of querying them live at all, are the natural next steps.

## Database migrations

`server-ts/src/migrations/` (TypeORM) is the source of truth for building a database — `npm run migration:run`
applies every migration in order and records each one in a `schema_migrations` table, so a fresh database and
the long-running dev database stay reproducible and auditable (`GET /api/admin/migrations` shows what has
actually been applied to a given database). This replaced the old process of running `db/load_all.sql` by hand
with no tracking of what had been applied where — that gap let the dev database and the file history silently
drift apart (confirmed and reconciled once, in `CatchUpUndocumentedClosures`, when this migration system was
introduced; see that file's comment for what had drifted and why).

- `db/001` through `db/069` are the project's original hand-applied SQL files, preserved for history. Each is
  wrapped verbatim in its own migration class (`server-ts/scripts/generate-migrations.mjs` is the one-time
  generator that produced them — do not rerun it; it regenerates the whole directory from scratch).
- **New changes from here on should be written directly as a new TypeORM migration** in
  `server-ts/src/migrations/` (`npx typeorm migration:create src/migrations/MyChange` from `server-ts/`, or a
  hand-written file following the existing ones' shape), not as a new `db/0NN_*.sql` file.
- Migrations are forward-only by convention here: `down()` throws for every migration ported from the old SQL
  history, since most of them are data/content changes (not clean DDL) with no safe automated rollback — revert
  from a backup instead. Write a real `down()` for any new, purely-structural migration where one is actually
  safe.
- Useful commands (run from `server-ts/`, each does `npm run build` first):
  `npm run migration:run` / `npm run migration:revert` (undoes the single most recent migration) /
  `npm run migration:show` (lists pending vs. applied without running anything).
- TypeORM is used here only as the migration framework, not as the application's runtime ORM — the app's own
  queries (`server-ts/src/core/engine.ts` etc.) are unchanged, hand-written SQL via `pg`; see
  `server-ts/src/core/datasource.ts`'s header comment for why.

## Dataset size

| | Count |
|---|---|
| Verbatim provisions | 663 |
| Active rule versions (engine-usable) | 191 — 106 state, 85 curated council; 165 automatable |
| Draft council rules (verbatim value, not yet encoded) | 187 |
| Rule relationships | 522 (OVERRIDES, REPLACES, FALLS_BACK_TO, EXEMPTS, RELAXES, SUPPLEMENTS, ALTERNATIVE_TO, CONDITIONAL_ON, UNRESOLVED) |
| Open issues | 70 |
| Untraceable active rules | 0 |

## Verification policy

* `VERIFIED_VERBATIM`: value read from the official text held or fetched (PDF text extraction or the council's ePlan API).
* `VERIFIED_FROM_FIGURE`: read from an official figure (QHC Table A1 formulas, MP 1.2 Table A1 graph, MP 3.4 Figure 1).
* `COUNCIL_FACTSHEET` / `SECONDARY_SOURCE_ONLY` / `UNVERIFIED` / `REFERENCED_STANDARD_NOT_HELD`: stored, never automated.
* `automatable = false` wherever the text needs judgement ("rectangular or near rectangular", "used for
  entertainment"), the scope is inferred, or inputs are subjective. The engine routes these to manual review.
* Interpretations made while encoding are written into `rule_versions.interpretation_notes`.

## Not yet done

* AS 1926.1/.2-2007 barrier detail (gaps, latch heights) and NCC fire separation: texts not held.
* Map-based inputs (zone, precinct, overlay, mapped heights) and the QHC adoption register (department site blocks scripted access).
* 200 council draft rules to curate (69 done); Brisbane neighbourhood plans beyond New Farm and Sherwood–Graceville.
* Legal review of open interpretations (`open_issues`, `UNRESOLVED` relationships) by a building certifier or planner.
