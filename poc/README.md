# Siteora POC — address → applicable siting rules

> **The application now runs on TypeScript / Ts.ED** ([server-ts/](../server-ts/README.md)). The Python code in this
> folder is retired and commented out. This folder still holds the files the server uses: the web page
> (`static/index.html`), the map-service configuration (`zoning_layers.json`, `site_layers.json`) and `.env`.

Give it a Queensland address and a proposed structure (shed, garage, carport, patio, pergola, deck, pool,
pool fence). It returns every rule that applies — required value, the clause it comes from with the exact
text, and whether it can be decided automatically or needs a person — using the `regs` rules database.

```
address ──► State geocoder ──► point ──┬─► council (LGA boundaries)
                                       ├─► land parcel: lot/plan, registered area, outline → est. width/depth
                                       ├─► Priority Development Area?
                                       └─► council zoning map → zone / precinct  (or choose the zone manually)
                                                │
   structure inputs (type, height, size…) ──────┤
                                                ▼
                         rules engine (server-ts/src/core/evaluate.ts, reads schema regs)
                         scope → conditions → precedence → versions
                                                ▼
             rules per boundary + values + clause text + what is still unknown
```

## Run

Needs Node.js 20+, the `siteora` database loaded (`db/load_all.sql`), and internet access to the council and
Queensland Government map services.

Put the database password in `poc/.env` (copy `poc/.env.example`; the file is git-ignored):

```
PG_PASSWORD = <your password>
```

```powershell
npm run install:server                      # first time only (from the repository root)
npm run build
npm start                                   # web page:  http://localhost:8766
```

Command line:

```bash
npm run cli -- "30 Wises Road, Buderim QLD 4556" --structure SHED --height 3 --length 6 --width 4 --slope 5
npm run cli -- "15 Jubilee Terrace, Ashgrove QLD 4060" --structure POOL_INGROUND --height 0.3 --length 8 --width 4 --json
npm run cli -- --lon 152.9891 --lat -27.4467 --structure CARPORT --height 3 --length 6 --width 6 --zone BCC:LOW_DENSITY_RESIDENTIAL
```

JSON API (same as the page uses):

```
GET /api/rules?address=...&structure=SHED&height_m=3&length_m=6&width_m=4
              [&mean_height_m=&lot_slope_pct=&window_distance_m=&existing_outbuildings_m2=
               &is_corner_lot=yes&adjoins_canal_or_lake=yes&is_attached_to_dwelling=yes
               &zone_id=BCC:LOW_DENSITY_RESIDENTIAL&precinct=...&date=2026-10-09
               &scope=setbacks|maps]   # the page's "Setbacks only" / "Maps only" checkboxes; omitted = everything
GET /api/zones?lg_id=BRISBANE
GET /api/features?layer=<configured layer URL>&bbox=xmin,ymin,xmax,ymax   (map: a layer clipped to the view)
```

`scope=setbacks` still resolves the property's zone/overlays (rules need them) but returns only setback-category
rules (`SETBACK.*` / `SEPARATION.*`, the same topics `regs.v_setback_rules` uses) — `location` is still present in
the reply for context, the page just doesn't show the map/constraints/sources cards for it. `scope=maps` skips the
rule engine entirely (no DB rule load or evaluation) and returns only the location/zoning/overlay/site-constraint
data, with `rules: []` and `council_rules: null`.

Database connection comes from `poc/.env` (`PG_PASSWORD`, optional `PG_HOST` / `PG_PORT` / `PG_DATABASE` /
`PG_USER`) or the standard `PGHOST` / `PGPORT` / `PGDATABASE` / `PGUSER` / `PGPASSWORD` environment variables, which
take precedence (defaults `localhost` / `5432` / `siteora` / `postgres`).

## Querying the database directly

The POC is a thin layer; everything it shows can be queried in Beekeeper:

```sql
-- what the rules dataset knows about a council
SELECT zone_id, name, dwelling_house_permitted FROM zones WHERE zone_id LIKE 'BCC:%';

-- every active setback rule that can apply in a zone (State rules have no zone scope)
SELECT r.rule_version_id, r.title, r.value_expr, r.unit, r.primary_clauses, r.instrument
FROM v_active_rules r
WHERE r.topic LIKE 'SETBACK.%'
  AND (NOT EXISTS (SELECT 1 FROM rule_scopes s WHERE s.rule_version_id = r.rule_version_id
                   AND s.level IN ('ZONE','PRECINCT','LOCAL_PLAN','LOCAL_PLAN_PRECINCT'))
       OR EXISTS (SELECT 1 FROM rule_scopes s WHERE s.rule_version_id = r.rule_version_id
                  AND s.zone_id = 'BCC:LOW_DENSITY_RESIDENTIAL'))
  AND NOT EXISTS (SELECT 1 FROM rule_scopes s WHERE s.rule_version_id = r.rule_version_id
                  AND s.level = 'LOCAL_GOVERNMENT' AND s.lg_id <> 'BRISBANE');
```

Plain SQL lists *candidate* rules. Deciding which one actually governs (conditions such as lot area,
height and boundary type, exemptions, council alternative provisions overriding the QDC, the QHC
transition dates) is what the rules engine (`server-ts/src/core/evaluate.ts`) does — that is why the POC calls the engine rather than a
single query.

## What the output means

| State | Meaning |
|---|---|
| `DETERMINED` | The rule applies and its value is fixed for these inputs. |
| `MANUAL_REVIEW` | The rule may apply but an input is unknown (listed under "Inputs that would resolve…"), the text needs judgement, or two rules interact in a way the law does not settle. |
| *Displaced* | Shown under "Instruments in force and facts used": rules removed by precedence, with the reason (e.g. QDC A4 overridden by Brisbane City Plan AO2). |

Every fact used is listed with its source: public data, user input, **ESTIMATED** (derived from the parcel
outline) or **ASSUMED** (a default the POC had to make). Treat ESTIMATED and ASSUMED values as things to
confirm.

## "Why only State (QDC) rules?" — the council-rules section

Each result also lists the council rules that are **in scope for this place but did not apply**, with the reason
(e.g. *needs lot_area_m2 < 450 (here: 612)*, *does not cover a shed*), how many council rules belong to other
zones/overlays/plans, and the council clauses for this place that are **not yet encoded** (drafts — read them
yourself). A Brisbane lot of 450 m² or more outside the character overlays legitimately gets QDC MP 1.2 setbacks and
site cover: the City Plan sets only the 9.5 m height for it.

## Seeing the maps and the sources

Every result page has:

* **Map**: the parcel outline (red), the address point, and every council layer used for the result (zone,
  precinct, local plan, overlays), drawn live from the source services. Layers on this lot are switched on.
  Others can be toggled in the top-right panel, with a Streets / Aerial imagery switch. Click a shape to see its
  attributes.
* **Site constraints on this lot**: easements, sewer / water / stormwater mains, electricity lines, flood,
  vegetation, waterways, heritage, bushfire, slope, coastal, acid sulfate soils, airport and noise. Each layer is
  tested against the whole lot (council data first, Queensland Government data where the council has none) and
  drawn on the map with the same filter, in one colour per category (shown next to each row in the table). Power
  lines are drawn on top in amber: solid overhead, dashed underground. They count when on or within 5 m of the lot,
  so a "Yes" can be a line in the street beside it. Areas (flood, noise, vegetation …) are drawn in the publisher's
  own colours, with the publisher's legend wording next to each value in the table. They're filled without outlines,
  as the councils draw them. Flood areas are traced from 2.5–5 m model grid cells, so their edges are stepped close
  up on every map. The server clips them to the view (`/api/features`): Brisbane stores each flood planning area as
  one city-wide feature, about 13 MB per view straight from the service. See `poc/site_layers.json` and
  [docs/13-map-services.md](../docs/13-map-services.md) §6.
* **Sources used for this property**: one row per lookup (geocoder, council boundary, cadastre, PDA, zone,
  precinct, local plan, each overlay) with what it returned and three links:
  * **API result**: the exact query for this property, as a readable page from the source service;
  * **Layer**: the layer's fields, description and service details;
  * **Map viewer**: the layer opened in the ArcGIS Map Viewer at this property.
* The council's **planning scheme website** link, where known.

The API response carries the same data in `location.sources`, `location.parcel_geometry` and `scheme_viewer`.

## Updating a source URL

All council map services are in `poc/zoning_layers.json`, one block per council; nothing is hard-coded elsewhere.
When a council publishes a new version or moves a service:

1. Run `npm run check-services` (or `npm run check-services -- LOGAN` for one council). It checks every configured layer is
   reachable, that the configured field still exists, and when the data was last edited. Run it monthly.
2. Edit the `zone_layer`, `precinct_layers`, `local_plan_*` or `overlay_layers[].layer` URL, and the `field` if
   it changed. For overlays, `map` turns layer values into rule-dataset overlay ids: `"*"` means any value, and
   `value_fact` reads a number such as a mapped height.
3. Run `npm run check-services` again, then test an address in that council. Restart the server to pick up changes.

Where each source came from, and the alternatives, are in [docs/13-map-services.md](../docs/13-map-services.md).

## Automatic zone lookup (council map services)

Configured in `zoning_layers.json`; each endpoint was tested with a point query on 9 Oct 2026.

| Council | Zoning map service | Zone / precinct |
|---|---|---|
| Brisbane | Brisbane City Plan 2014 open data (edited 2026-09-17) | zone, precinct, neighbourhood plan + precinct, **overlays**: Traditional building character (with sub-category), Dwelling house character |
| Gold Coast | City Plan **Version 13** open data — scheme in force is Version 14; check for zoning changes | zone, precinct |
| Moreton Bay | MBRC zones open data (last edited Oct 2024) | zone, precinct, local plan |
| Sunshine Coast | Planning Scheme 2014 zoning MapServer | zone, precinct (separate layers) |
| Logan | Logan Planning Scheme v9.2 MapServer (hosted on a consultant's server — URL may change) | zone, precinct (separate layer) |
| **Ipswich** | **City Plan 2025 layer requires a login token — not used. Choose the zone manually.** | — |
| Redland | City Plan Version 14 open data | zone, precinct (LDR1–LDR5) |

The address point is tried first, then a point inside the parcel (address points can sit on unzoned road
reserve). Map text is matched to the dataset's zones/precincts by name; anything that does not match is
reported as a warning rather than guessed.

## Known limits (it is a POC)

* **Zoning**: automatic for 6 councils (table above); Ipswich needs the zone picked by hand.
* **Overlays** are looked up for 6 councils (all except Ipswich, whose City Plan 2025 data is not public) — see
  [docs/13-map-services.md](../docs/13-map-services.md). Mapped maximum heights (Gold Coast, Moreton Bay, Sunshine
  Coast) are read into the fact `mapped_max_height_m`; the council rules that use them are still drafts.
* **Lot width / frontage / depth** are estimated from the parcel's minimum bounding rectangle; the actual
  road frontage is not identified. Corner lots and canal frontage must be ticked by the user.
* **Sewer / water mains** (QDC MP 1.4) are not checked — those rules always show as manual review.
* The POC resolves *which rules apply and what they require*. It does not measure a drawn design against them.
* Address matching uses the State geocoder; fuzzy matches below 90% are rejected and the candidates shown.
