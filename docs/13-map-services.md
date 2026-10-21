# Map services — where each property fact comes from (7 SEQ councils)

Researched and point-tested 15 Oct 2026. All sources below are anonymous public services or official open data.
Nothing behind a login or token is used. The configuration lives in `poc/zoning_layers.json`.

## 1. Best way to access

| Approach | Use it for |
|---|---|
| **Live ArcGIS REST point queries** (`<layer>/query?geometry=lon,lat&inSR=4326…`) | The POC, and any layer queried per address. Every service below supports it. |
| **Local cache in PostGIS** (bulk download or paged export, refreshed monthly or at each scheme amendment) | Production. It removes dependence on consultant-hosted or versioned URLs, and makes lookups fast and repeatable. |
| **Version watch** (`editingInfo.lastEditDate`, service names with version numbers) | Detecting a new planning-scheme version. This ties into the scheme-update process in docs/11 Phase 3. |

The data changes only at scheme amendments (a few times a year), so a cache refreshed monthly loses nothing. Keep
the service URL, version label and download date with each cached layer, so results stay traceable.

**Licences.** Every source needs an attribution line in the product:
* Brisbane, Gold Coast, Moreton Bay: CC BY 4.0.
* Sunshine Coast, Logan: CC BY 3.0 AU.
* Redland: **CC BY-SA 4.0**. The share-alike term applies to any redistributed derivative of the data.
* State DCDB and State spatial layers: CC BY 4.0.

## 2. Status by council

| Council | Zone / precinct | Local plans + precincts | Overlays looked up | Mapped max height | Access notes |
|---|---|---|---|---|---|
| Brisbane | ✅ open data (2026-09) | ✅ NP boundary + NP precinct layers (code) | Traditional building character (with sub-category), Dwelling house character | — (none mapped) | Council ArcGIS Online, stable names |
| Gold Coast | ✅ City Plan **V13** open data (no V14 layer published) | — (no local plans with rules) | Ridges, coastal erosion (seawall site/setback, waterfront control area), road widening (**V14**, council MapServer), Mudgeeraba character, flood assessment, water supply buffer, building height | ✅ `HEIGHT_IN_METRES` ('9m', '2(9m)', '1(7.5m)'; 'HX'/Spit text → manual) | Service name carries the version (`City_Plan_Version_13_Open_Data`); check for V14/V15 |
| Moreton Bay | ✅ Oct 2024 (latest) | ✅ `LP` / `LP_PREC` on the zoning layer. Caboolture West **sub-precincts are not in any public queryable layer** | Building heights, bushfire, riparian & wetland setbacks, infrastructure buffers (400 m lake buffer), coastal erosion, heritage & landscape, scenic amenity | ✅ `OVL2_DESC` ('Max 8.5m'). `OVL2_CAT` has a data error, so it is not used | Changes since 2024 are by TLPI (not looked up). North Lakes sits outside the scheme overlays |
| Sunshine Coast | ✅ council MapServer | ✅ `Boundaries_SCC` layers 3 (areas) / 6 (precincts) | Height of buildings, coastal protection, flooding & inundation, character areas | ✅ `LABEL` ('8.5 metres') | Use the council MapServers. Avoid the 2024 OpenData copy (lags amendments) and the `scrcpublic` layers (the proposed 2025 scheme) |
| Logan | ✅ **switched to the v9.2 + TLPI 1/2024 service** | ✅ layers 129 / 130 (Loganholme etc.) | Residential overlay → `dwelling_house_code_applies` (replaces the old assumption), heritage, TLPI flood (high flow / high flood risk), landslide & steep slope | — | Hosted on a consultant (WSP) server. Names carry version and date; a draft new scheme exists. Council-hosted per-lot alternative: `Property_Report_LPS2015` |
| Ipswich | ❌ City Plan 2025 needs a token | ❌ | ❌ OV3 character, OV6 height | ❌ | **Nothing public.** Open data is the superseded 2006 scheme only. The ePlan viewer blocks scripts and its terms allow browser viewing only. **Request the data from the council** (below). Manual zone meanwhile |
| Redland | ✅ City Plan V14 open data | — | Bushfire, coastal erosion prone, flood & storm tide, heritage | — | `<Null>` precinct string handled. LDR5 canal revetment walls are only in council **asset** data |

### Ipswich data request

Send to council@ipswich.qld.gov.au ((07) 3810 6666), the custodian contact on the council's data.gov.au
datasets. Ask for:
* City Plan 2025 **Zones and Precincts**.
* **OV3** Character Places and Areas.
* **OV6** Building Height and Density, with its height attribute.

Preferred delivery is open data (CC BY 4.0, like their 2006 datasets): shapefile, GeoJSON or file geodatabase.
Alternatively, anonymous access to the hosted `Zones_and_Precincts_V2_A1` FeatureServer, or a licence allowing
automated point queries and caching. Also ask for the version and update frequency.

## 3. Road hierarchy (for the street-type setback) — researched, not yet implemented

**Method, tested in every council.**
1. The lot's frontage roads are the DCDB layer-4 parcels with `parcel_typ = 'Road Type Parcel'` that intersect
   the lot buffered by 0.5 m. `feat_name` gives the street name; a corner lot has two.
2. Classify each frontage road from the council's layer:

| Council | Layer | Access street (3 m) | Collector (4 m) | Higher |
|---|---|---|---|---|
| Brisbane | `Roads_hierarchy_overlay_Road_hierarchy` `ROUTE_TYPE` | Neighbourhood / local *(collector and access are lumped)* | ↑ same class | Motorway / Arterial / Suburban / District |
| Gold Coast | City Plan V13 layer 3 (Distributor and above), plus asset `Road_Segment_view` `SEGMENTATION_HIERARCHY` | 1 Residential access | 2 / 3 / 7 collectors | 4 / 5 / 9 |
| Moreton Bay | `OM_Road_Hierarchy` `Hierarchy` | not on the layer | Local / District Collector | Sub-Arterial and above |
| Sunshine Coast | `Transport_SCC/MapServer/0` `LABEL` | Local | Neighbourhood / District Collector | Distributor and above |
| Logan | TLPI service layer 328 `Road_Type` | Urban Access Street / Road | Urban / Rural Collector | Arterial, Main Road, Highway |
| Ipswich | data.gov.au WFS road centre-lines `ROAD_HIERA` (open) | Access Place / Laneway, Access Street | Minor / Major Collector | Sub-Arterial and above |
| Redland | none. Fallback: State `Transportation/RoadsAndTracks/MapServer/10` `class` | Local | Connector | Secondary and above |

**Reliability.**
* "Higher road" vs local: about 90 %.
* Collector vs access street: fair in Moreton Bay, Sunshine Coast, Logan and Ipswich; weak in Brisbane, Gold
  Coast (asset data) and Redland.

Show the result as **"inferred from <source>"** and let the user override it. Keep the 4 m conservative default
when the result is unknown.

## 4. Canal / lake frontage — researched, not yet implemented

Flag the lot if any of these holds:
1. A bordering DCDB parcel (within 0.5 m) is `Watercourse` with a canal, waterway or lake name.
2. A State `InlandWaters/WaterCoursesAndBodies` **Canal area** (`function='Canal Estate'`, layer 31) or
   **Lake** (`Ornamental Lake`, layer 27) lies within 3 m of the lot.
3. A bordering reserve lot overlaps one of those polygons. This catches canals and lakes held as lots.
4. A council layer agrees:
   * Gold Coast V13 layers 71 / 72;
   * Sunshine Coast Overlays layer 29 'Constructed Waterbodies';
   * Redland asset `Marine Walls` (revetments, `assets/a_parks_transport/MapServer/18`).

It was tested on Isle of Capri, Raby Bay and Pelican Waters (all detected), plus one correct negative. Golf-course
"ornamental lakes" can trigger falsely, so show the evidence and ask the user to confirm.

## 5. What the new lookups enable next

* **Mapped heights** now arrive as the fact `mapped_max_height_m`. The council rules that use it are still
  drafts and must be encoded:
  * Moreton Bay RAD1;
  * Sunshine Coast height overlay, including the flood-hazard allowance;
  * Gold Coast building height overlay;
  * Ipswich OV6, once data is available.
* **Overlay-scoped draft rules** can now be curated, because the overlays are detected. Examples: Gold Coast
  ridges and coastal; Moreton Bay riparian, bushfire and lake buffer; Logan landslide, heritage and flood;
  Sunshine Coast coastal and flood.
* Road hierarchy and canal detection (sections 3–4): about 2 days to implement.

## 6. Site constraints (easements, services, flood, vegetation …) — implemented

Configured in `poc/site_layers.json` (190 layers, all validated 16 Oct 2026; sources reviewed the same day, see
the Change log sheet of `docs/data-sources-register.xlsx`) and queried by `server-ts/src/core/site.ts` with the
**whole lot outline**. Polygons that only touch the boundary are excluded; lines and points count within 1 m, and
power lines within 5 m (overhead-line exclusion zones are 3 m or more, and street lines sit 1–2 m off the
boundary). Selection is **council first per category**, with **Queensland Government layers as the fallback**.
Some layers are always added, even where the council has the category: DCDB easements, the Energex / Ergon
network (Before You Dig Australia), Powerlink, petroleum pipelines and State-controlled roads.

| Category | Brisbane | Gold Coast | Moreton Bay | Sunshine Coast | Logan | Ipswich | Redland |
|---|---|---|---|---|---|---|---|
| Easements | council (2) + State | council (3) + State | council (1) + State | State | council (1) + State | State | State |
| Sewer | council (3) | council (3) | council (3) | council (3) | council (3) | council (3) | council (3) |
| Water | council (2) | council (2) | council (2) | council (2) | council (2) | council (2) | council (1) |
| Stormwater | council (4) | council (3) | council (2) | — | council (3) | — | council (2) |
| Electricity | council (2) + State | council (3) + State | State | council (2) + State | council (1) + State | State | council (1) + State |
| Flood | council (5) | council (3) | council (3) | council (1) | council (2) | State | State |
| Vegetation | council (7) | council (6) | council (1) | council (1) | council (4) | State | State |
| Waterway | council (2) | council (6) | State | council (3) | State | State | council (1) |
| Heritage | council (3) | council (3) | State | council (2) | State | State | State |
| Bushfire | council (1) | council (1) | State | council (4) | council (1) | State | State |
| Slope | council (1) | council (1) | council (1) | council (2) | council (2) | — | council (1) |
| Coastal | council (2) | council (1) | State | State | State | State | council (1) |
| Soils | council (1) | council (1) | council (1) | council (1) | council (1) | State | State |
| Airport | council (3) | council (2) | State | council (1) | council (1) | State | council (1) |
| Noise | council (1) | council (1) | council (1) | — | council (2) | — | council (1) |
| Infrastructure | council (1) + State | State | council (1) + State | council (2) + State | council (2) + State | State | council (2) + State |
| Roads | State | State | State | State | State | State | State |

Sources:
* **Water and sewer networks:**
  * Urban Utilities (Brisbane, Ipswich);
  * Unitywater public infrastructure layers (Moreton Bay, Sunshine Coast);
  * Gold Coast, Logan Water and Redland asset layers.
* **Stormwater:** council asset layers. Ipswich publishes none.
* **Electricity:** the Energex / Ergon network (sub-transmission, high and low voltage, overhead and underground,
  plus substations) from Before You Dig Australia's *Look Up and Live* Queensland service (refreshed Jan 2026),
  always shown. It replaced Energex's own public extract, which Energex has deprecated: a 2022 snapshot that is no
  longer updated and prohibits commercial use. BYDA states no licence, so confirm terms before commercial use.
* **Logan Water:** the current *Sewerage Information* and *Water Information* services (edited daily), existing
  assets only. Recycled water still comes from the older AGOL_Water layer, the only source for it.
* **Facts fed to the rules:** any sewer, water or stormwater feature on the lot sets `infrastructure_on_lot`,
  which the QDC MP 1.4 rules use.

Limits:
* Network maps are approximate and can be incomplete. The page says to confirm services with a **Before You Dig
  Australia** enquiry.
* Ipswich planning layers are still not public, so only State layers and Urban Utilities layers apply there.
* Pipe diameter (needed by two MP 1.4 rules) is shown in the details but not yet read into a fact.

Maintenance: `npm run check-services` checks the zoning and overlay layers. Site layers were validated
when built; re-run the same check by loading `site_layers.json`. To add or replace a layer, edit that file:
`category`, `name`, `layer`, and optional `label_field`, `where`, `distance_m`, `always`.
