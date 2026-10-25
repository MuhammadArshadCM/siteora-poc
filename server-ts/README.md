# Siteora API — TypeScript / Ts.ED

**The application.** Address + structure → applicable siting rules, site constraints and sources, plus the
command-line tools that build and check the rules dataset. It uses the PostgreSQL rules database (`regs` schema),
the map-service configuration in `poc/zoning_layers.json` and `poc/site_layers.json`, and the web page
`poc/static/index.html`.

This replaced the original Python code (`poc/*.py`, `tools/*.py`) on 2026-10-16. That code is kept, commented out,
for reference only. Every output was checked against it before it was retired: API responses, rule results,
reports, generated SQL (byte for byte), the database verification, the schema document and the service health check.
The Python results are recorded in `parity/golden/`, so the parity test keeps checking against them.

## Layout

```
src/core/            framework-free logic (unit-testable, used by the tools and the parity test)
  py.ts              Python-compatible primitives (round half-to-even, truthiness, ==, urlencode, str(), repr())
  pyjson.ts          JSON reader/writer that keeps 6.0 vs 6 (the SQL generator needs it)
  db.ts              pg connection pool; q(sql) returns the query's single JSON value
  evaluate.ts        rule resolver: scope → conditions → precedence → value
  geo.ts             State geocoder, cadastre, LGA, PDA, parcel geometry
  zoning.ts          council zoning / precinct / local plan / overlay lookups
  site.ts            site constraints (easements, sewer/water/stormwater, flood, vegetation …)
  engine.ts          locate → facts → resolve → explain
  env.ts             poc/.env loading, repository paths
src/services/        Ts.ED injectables (DbService = pool, RulesService = engine)
src/controllers/     RulesController: GET /, /api/rules, /api/zones
src/Server.ts        Ts.ED configuration (Express platform)
src/index.ts         bootstrap
src/tools/           command-line tools (below)
parity/              parity test, its cases and the recorded reference results (golden/)
```

## Run

Node 20+ and the `siteora` database. The database password is read from `poc/.env` (`PG_PASSWORD = ...`) or the
standard `PGHOST` / `PGPORT` / `PGDATABASE` / `PGUSER` / `PGPASSWORD` environment variables.

Every command works from the repository root or from `server-ts/`:

```bash
npm run install:server         # first time only (inside server-ts/: npm install)
npm run build
npm start                      # http://localhost:8766   (POC_PORT to change) — kept running, see below
npm run dev                    # development: rebuilds and restarts on every change in src/ (nodemon)
npm run start:once             # the server alone, without the supervisor
```

`npm start` runs the server under a small supervisor (`src/supervise.ts`):
* **Restarts:** if the server stops unexpectedly, it is started again after 1, 2, 4 … 30 seconds.
* **Log file:** everything the server prints also goes to `server-ts/logs/server.log`, with times, so the reason for a
  stop can be read afterwards.
* **Ctrl+C** stops it cleanly.
* **Port already in use:** the server says so (another copy is probably running) and the supervisor does not retry.

At start-up the server checks the database, the rules dataset and the State and council map services, and prints
what is wrong, if anything. `GET /api/health` repeats the check at any time.

```
GET /api/rules?address=...&structure=SHED&height_m=3&length_m=6&width_m=4[&zone_id=&precinct=&date=&lon=&lat=&scope=setbacks|maps]
GET /api/zones?lg_id=BRISBANE
GET /api/features?layer=<configured layer URL>&bbox=xmin,ymin,xmax,ymax   (map: a layer clipped to the view)
GET /api/health                (200 all well / 503 with what is not working, and how long each service took)
```

`scope` narrows the response (and the work done): omitted or `all` is the full result, unchanged; `scope=setbacks`
still resolves the location (rules need the zone) but returns only setback-category rules — everything under
`SETBACK.*` or `SEPARATION.*`, the same definition `regs.v_setback_rules` uses — and the `location`/map-only fields
are left for the client to ignore; `scope=maps` does not run the rule engine at all (no DB rule load, no facts beyond
what `locate()` already produces) and returns the location/zoning/overlay/site-constraint data with `rules: []` and
`council_rules: null`. The web page's "Setbacks only" / "Maps only" checkboxes set this.

Errors are `{"error": "..."}`, and the message says what to do:

| Status | When |
|---|---|
| 400 | Bad input, address not found, outside the 7 councils |
| 503 | A required service is unavailable: no internet / DNS, a map service down or rate-limiting (429), or PostgreSQL not running, rejecting the password, or missing the rules dataset. Map calls are retried (1 s, then 2 s; a 429 waits as long as the service asks, up to 15 s) before giving up. At most 4 requests run at once per State or council server and 8 per ArcGIS Online host, across all users. |
| 500 | A fault in the code. The message carries a reference that matches the full error in `logs/server.log`. |

Optional lookups degrade instead of failing the result. These are the land parcel, the Priority Development Area,
the council zoning map, single overlay maps and site-constraint layers. A lookup whose service does not answer
becomes a warning, and the Sources table says "lookup failed". Any fact it would have given is left unknown, so the
rules that need it go to manual review (never a false "no").

TypeScript is pinned to 5.9 and built with `tsc`: Ts.ED dependency injection needs `emitDecoratorMetadata`, which
esbuild-based runners (tsx) and TypeScript 7 do not provide.

## Command-line tools

Run `npm run build` first (the parity scripts build by themselves).

| Command | What it does |
|---|---|
| `npm run cli -- "15 Jubilee Terrace, Ashgrove QLD 4060" --structure SHED --height 3 --length 6 --width 4` | Rules for an address in the terminal (`--json` for the full response, `--help` for all options) |
| `npm run evaluate -- examples/brisbane_shed_pool.json` | Rules for a scenario file (`--json` for the full result) |
| `npm run check` | Integrity invariants + every `examples/*.json` reproduces its `examples/*.out.md` (`-- --update` re-records them) |
| `npm run verify-load` | Every record in `research/` is in the database, word for word |
| `npm run import-research` | Regenerates `db/030_council_*.sql` from `research/councils/*.json` (`-- --check` compares without writing) |
| `npm run schema-doc` | Regenerates `db/README.md` from the live database |
| `npm run check-services` | Health check of every council map layer (`-- LOGAN` for one council) |
| `npm run data-register` | Writes `docs/data-sources-register.xlsx`: every API / layer used, publisher, level (council / utility / State / national), last updated, stated update frequency, licence, coordinate system, issues to act on, and the regulatory documents |

## Parity test

```bash
npm run parity:offline         # database only (about 1 minute)
npm run parity                 # + live end-to-end cases against council / State map services (about 5–10 minutes)
npm run parity -- --record     # re-record parity/golden/ from the current output (see below)
```

| Part | What is compared |
|---|---|
| 0 | The comparator catches a deliberately wrong result (changed value, state, missing rule, extra field, text) |
| 1 | `round()` on tie values, truthiness and `urlencode` against values recorded from real Python |
| 2 | Every `examples/*.json` scenario: `resolve()` vs `golden/examples.json` (full JSON), and the report vs `examples/*.out.md` |
| 3 | `parity/cases.json` (all 7 councils, a 2029 QHC date, a manual zone, error cases): `engine.run()` vs `golden/engine.json`, the whole API response |
| 4 | The SQL generator reproduces `db/030_council_*.sql` byte for byte |

The comparison is semantic: numbers compare numerically, `null` equals a missing key, and rule lists are put in a
canonical order. Python printed whole-number floats as `612.0`, JavaScript as `612`; that one difference is
normalised. A map service that times out is excluded for that layer. A case that differs is run once more, and only
a difference that repeats is reported.

**When it fails:**
* **Parts 0–2 or 4** mean the code or the database changed the results. Find out why before going further.
* **Part 3** can also fail because a council changed its map data (a rezoning, a new overlay version). Check the
  reported fields against the council's map. If the new answer is right, run `npm run parity -- --record` to
  accept it, and keep the change in git so it is reviewed.

Run `npm run parity:offline` after any code change, and `npm run parity` before a release. Add a case to
`parity/cases.json` (then `--record` it) whenever a bug is found.

## Python behaviour kept (see `src/core/py.ts`)

The rules and reports were first written in Python. These behaviours are reproduced so the results did not change:

* `round(x, n)` rounds exact binary ties to even: `round(0.0625, 3) == 0.062` (JS `toFixed` gives 0.063).
* Truthiness: an empty list or dict is false (in JavaScript it is true).
* `==` on lists is element-wise; `x in "text"` is a substring test.
* `urlencode` encodes `* ! ' ( )` (JavaScript's `encodeURIComponent` does not).
* Messages print `True` / `False` / `None` and Python list repr, so error texts are unchanged.
* `float("abc")` raises: invalid numeric input is a 400 error, not `NaN`.
