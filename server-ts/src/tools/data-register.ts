/**
 * Data source register: an Excel workbook listing every API / map layer the application calls, who publishes it,
 * when it was last updated, how often it is updated, its licence, coordinate system and what it is used for, plus
 * the regulatory documents in the rules database.
 *
 *   npm run data-register                       writes docs/data-sources-register.xlsx
 *   npm run data-register -- --out other.xlsx
 *
 * Everything in the "from the publisher" columns is read live from each service's own metadata (ArcGIS REST layer
 * and service JSON, the ArcGIS item record where one exists, and a feature count) at the time the tool runs.
 * Nothing is guessed: when a publisher does not state something, the cell says so.
 */
import fs from "node:fs";
import path from "node:path";
import ExcelJS from "exceljs";
import { Db } from "../core/db.js";
import { loadEnv, ROOT } from "../core/env.js";
import * as geo from "../core/geo.js";
import * as site from "../core/site.js";
import * as zoning from "../core/zoning.js";
import { pool } from "../core/site.js";
import { parseArgs } from "./args.js";
import { demandPerLookup, factsFor, hostKey, probeHost } from "./integration.js";

/** One test property per council (from parity/cases.json), to count what a lookup sends to each host. */
const TEST_POINTS: [string, number, number][] = [
  ["Brisbane", 153.09865741, -27.51443062], ["Gold Coast", 153.52642, -28.17276], ["Moreton Bay", 153.091757, -27.230425],
  ["Sunshine Coast", 153.084668, -26.644206], ["Logan", 153.183671, -27.665247], ["Redland", 153.272084, -27.520936],
  ["Ipswich", 152.775, -27.62],
];
import { exit } from "./fmt.js";

// ----------------------------------------------------------------------------- publishers
interface Publisher { publisher: string; level: string; licence: string; portal?: string }

/** Who runs each host. Licences for councils / State are from their open-data portals (docs/13-map-services.md);
 *  an ArcGIS item's own licence text, when present, is shown next to it. */
const PUBLISHERS: [RegExp, Publisher][] = [
  [/spatial-gis\.information\.qld\.gov\.au/, { publisher: "Queensland Government (QSpatial)", level: "State", licence: "CC BY 4.0", portal: "https://qldspatial.information.qld.gov.au" }],
  [/utility\.arcgis\.com\/usrsvcs\/servers\/3ec80e95/, { publisher: "Queensland Fire Department / CSIRO (via QSpatial)", level: "State", licence: "CC BY 4.0" }],
  [/services\.ga\.gov\.au/, { publisher: "Geoscience Australia", level: "National (Commonwealth)", licence: "CC BY 4.0", portal: "https://ecat.ga.gov.au" }],
  [/bfVzktoY0OhzQCDj/, { publisher: "Energy Queensland (Energex network)", level: "State-owned utility", licence: "Not stated in service metadata" }],
  [/ug6sGLFkytbXYo4f/, { publisher: "Before You Dig Australia (Look Up and Live; network data from Energex / Ergon Energy)", level: "National (industry body)",
    licence: "Not stated in service metadata: confirm terms with BYDA before commercial use", portal: "https://www.byda.com.au" }],
  [/ocUCNI2h4moKOpKX/, { publisher: "Urban Utilities (Brisbane, Ipswich, Lockyer Valley, Scenic Rim, Somerset)", level: "Council-owned water utility", licence: "Not stated in service metadata" }],
  [/tQg86iShPXJPWQWw/, { publisher: "Unitywater (Moreton Bay, Sunshine Coast, Noosa)", level: "Council-owned water utility", licence: "Not stated in service metadata" }],
  [/dEKgZETqwmDAh1rP/, { publisher: "Brisbane City Council", level: "Local council", licence: "CC BY 4.0", portal: "https://data.brisbane.qld.gov.au" }],
  [/lnVW0dLI3fvST2hd|3vStCH7NDoBOZ5zn|goldcoast\.qld\.gov\.au/, { publisher: "City of Gold Coast", level: "Local council", licence: "CC BY 4.0", portal: "https://data.goldcoast.qld.gov.au" }],
  [/152ojN3Ts9H3cdtl/, { publisher: "City of Moreton Bay", level: "Local council", licence: "CC BY 4.0", portal: "https://datahub.moretonbay.qld.gov.au" }],
  [/scc\.qld\.gov\.au/, { publisher: "Sunshine Coast Council", level: "Local council", licence: "CC BY 3.0 AU", portal: "https://data.sunshinecoast.qld.gov.au" }],
  [/lcc\.wspdigital\.com/, { publisher: "Logan City Council (hosted by consultant WSP)", level: "Local council", licence: "CC BY 3.0 AU", portal: "https://data-logancity.opendata.arcgis.com" }],
  [/ZUCWDRj8F77Xo351/, { publisher: "Logan City Council (incl. Logan Water)", level: "Local council", licence: "CC BY 3.0 AU", portal: "https://data-logancity.opendata.arcgis.com" }],
  [/Rmbsssqb3knXA9RA/, { publisher: "Ipswich City Council", level: "Local council", licence: "CC BY 4.0 (2006 scheme datasets)", portal: "https://data.ipswich.qld.gov.au" }],
  [/VGRM775aS3HJEeB7|redland\.qld\.gov\.au/, { publisher: "Redland City Council", level: "Local council", licence: "CC BY-SA 4.0 (share-alike)", portal: "https://opendata.redland.qld.gov.au" }],
];

/** Old layers that were checked by hand: the publisher has no newer version. Matched on the endpoint URL. */
const REVIEWED: [RegExp, { checked: string; finding: string }][] = [
  [/152ojN3Ts9H3cdtl\/arcgis\/rest\/services\/(OM_|MBRC_PlanningScheme_)/, { checked: "2026-10-16",
    finding: "This is Moreton Bay's current published overlay service (no newer overlay service on the council's ArcGIS organisation). Overlay data changes only at planning-scheme mapping amendments." }],
  [/AdminBoundariesFramework\/MapServer\/15$/, { checked: "2026-10-16",
    finding: "The State's Queensland Floodplain Assessment Overlay has not been reissued since 2013. It is used only where the council publishes no flood mapping." }],
  [/OtherTransport\/MapServer\/175/, { checked: "2026-10-16", finding: "Current State airport-areas layer; no newer version published." }],
  [/Designated_Flood_Level_for_Residential_Buildings/, { checked: "2026-10-16",
    finding: "No newer version published by the City of Gold Coast. The 2026 Flood Risk Overlay and Defined Flood Level 2026 extent are also checked for Gold Coast." }],
  [/Koala_Area_Local_Law12_2023/, { checked: "2026-10-16", finding: "Current Gold Coast koala-area local-law layer; no newer version published." }],
  [/dEKgZETqwmDAh1rP\/arcgis\/rest\/services\/Environmental_Management\/FeatureServer\/10$/, { checked: "2026-10-16", finding: "Current Brisbane layer; no newer version published." }],
  [/geoimage\.scc\.qld\.gov\.au/, { checked: "2026-10-16",
    finding: "The date is the newest record entry date in the data, not a publication date. This is Sunshine Coast's current planning-scheme service." }],
  [/AGOL_Water\/FeatureServer\/14/, { checked: "2026-10-16",
    finding: "Logan Water's current 'Water Information' service has no recycled-water layer, so this older layer is still the only source." }],
  [/VegetationManagement\/MapServer\/201$/, { checked: "2026-10-21",
    finding: "Flora survey trigger map version 10.0 (Sep 2023) is the State's latest version (data.qld.gov.au lists no newer one)." }],
  [/StateRoadInformation\/MapServer\/6$/, { checked: "2026-10-21",
    finding: "This is the Department of Transport and Main Roads' live state-controlled road service; the 2022 date is its catalogue record on data.qld.gov.au, and no newer dataset or service is published." }],
  [/AdminBoundariesFramework\/MapServer\/82$/, { checked: "2026-10-21",
    finding: "State Planning Policy acid sulfate soils trigger area (2021) is the current SPP mapping; it changes only when the SPP mapping is amended." }],
  [/Flood_Awareness_Flood_Risk_Overall\/FeatureServer\/0$/, { checked: "2026-10-21",
    finding: "Brisbane's current Flood Awareness Map (the service linked from its open-data portal; service updated 1 Oct 2025, flood features Oct 2024). Brisbane reissues it after new flood studies; no newer version published. Advisory only — the City Plan flood overlay is what triggers assessment." }],
];

/** Planning-scheme layers checked by hand against the version in force: why their data is still current although it
 *  predates the version (or the service is named for an earlier one). The flag becomes 'Scheme version: checked'. */
const SCHEME_REVIEWED: [RegExp, string][] = [
  [/City_Plan_Version_13_Open_Data/, "Checked 2026-10-21: Version 14 'incorporates Minor and administrative amendment 13 and Interim LGIP amendment'. The council published Version 14 data only for the maps it changed (extractive resources and road widening, Aug 2026); minor, administrative and infrastructure-plan (LGIP) amendments do not redraw zones or the other overlays, so Version 13 open data is the current mapping for these."],
  [/152ojN3Ts9H3cdtl\/arcgis\/rest\/services\/(OM_|MBRC_PlanningScheme_)/, "Checked 2026-10-21: the version in force, Version 8, was 'created by LGIP Amendment No. 2', an infrastructure-plan amendment that does not change overlay mapping. The 2022 overlay data (the council's latest published) is the current mapping."],
  [/maps1\.goldcoast\.qld\.gov\.au\/arcgis\/rest\/services\/V8_Overlays\/MapServer\/13$/, "Checked 2026-10-21: no Version 13 or 14 obstacle limitation surface is published. The OLS is set by Gold Coast Airport's prescribed airspace, not by the planning-scheme version, so this layer is kept; check it against the airport's current OLS before relying on a hit."],
];

/** Source changes made after reviewing the register (newest first). */
const CHANGELOG = [
  { date: "2026-10-21", data: "Bushfire hazard", councils: "Moreton Bay, Redland, Ipswich",
    change: "Removed the State Bushfire Prone Area proxy. Added Moreton Bay's planning-scheme bushfire hazard overlay and Redland's City Plan bushfire hazard overlay. Ipswich: bushfire is now reported as 'not checked automatically' with a warning, and the Queensland Fire Department's Bushfire Prone Area picture map is shown on the map.",
    reason: "The proxy started refusing public access (403); no public State service carries the Bushfire Prone Area any more (QFD publishes it only as image tiles, SEQ July 2017). Ipswich's own bushfire overlay is not public.",
    verified: "Both council overlays answer and return their hazard classes (Very high / High / Medium potential intensity, potential impact buffer). The Ipswich test lookup shows the warning and the map layer." },
  { date: "2026-10-21", data: "Gold Coast airport noise, waterway and heritage overlays", councils: "Gold Coast",
    change: "Removed four layers from the 2015 'City Plan V8 Overlays' service: ANEF contour, 30 m and 60 m waterway buffers, heritage protection boundary. Their City Plan Version 13 equivalents remain: Airport noise exposure area, Waterways, Heritage place, Place in proximity to a local heritage place. The V8 obstacle limitation surface is kept (no newer one is published).",
    reason: "The V8 layers were 2015 mapping, and the Version 13 equivalents were already configured, so they were older duplicates.",
    verified: "Gold Coast test lookup: every airport, waterway and heritage layer answers; no duplicate layers remain." },
  { date: "2026-10-21", data: "Logan zones and precincts", councils: "Logan",
    change: "Zones and precincts now come from Logan City Council's own ArcGIS organisation ('Zones_V9_2_WFL1', layers 4 and 1) instead of the contractor-hosted LoganHub service. Local plans, local-plan precincts and overlays stay on LoganHub.",
    reason: "A council-hosted source is stronger evidence of currency (edited 17 Jul 2025, after v9.2 commenced on 1 Jul 2025) and answers faster. It also settles the version question for zones: the LoganHub service, whose internal title says 'V9.1', holds exactly the same v9.2 zones.",
    verified: "Same 6,920 zones and 6,710 precincts; the same answer at every one of 104 + 93 test points across Logan. Logan test lookup returns the same zone as before." },
  { date: "2026-10-16", data: "Brisbane easements (BCC property parcels)", councils: "Brisbane",
    change: "Added the missing filter PARCEL_TYP_DESC = 'Easement' to the Brisbane property-parcel layer, and the map now applies every layer's filter.",
    reason: "The layer's name described the filter but it was never configured, so every parcel touching the lot (including the lot itself and road reserves) was reported as an easement, and the map drew all parcels.",
    verified: "On the Brisbane test addresses, false easement hits are gone, and a real easement (DSP170890) is still found on the Carindale lot. It agrees with the State DCDB easement layer." },
  { date: "2026-10-16", data: "Priority Development Areas", councils: "All 7",
    change: "PlanningCadastre/PriorityDevelopmentAreas/MapServer/10 → PlanningCadastre/StatePlanning/MapServer/35 (server-ts/src/core/geo.ts).",
    reason: "The State is decommissioning the old service on 30 November 2026 and named StatePlanning as its replacement.",
    verified: "Same fields and the same 51 PDAs; point tests inside all 35 PDAs in the 7 councils gave identical answers on both services." },
  { date: "2026-10-16", data: "Electricity network", councils: "All 7",
    change: "Five Energex layers (Network_Energex: 110 kV, 33 kV, 11 kV, LV lines and distribution substations) → Before You Dig Australia 'Look Up and Live' Queensland network (LUAL_QLD): sub-transmission, high-voltage and low-voltage lines and cables, and substations.",
    reason: "Energex marked Network_Energex as deprecated: a 12 Sep 2022 extract that will not be updated, and its notice prohibits commercial use. The BYDA data was refreshed in Jan 2026, covers Energex and Ergon, and includes underground cables.",
    verified: "On the 12 parity test addresses, every line the 2022 extract found is also found, plus street lines beside 6 more lots and underground cables. Lines are searched within 5 m of the lot: overhead-line exclusion zones are 3 m or more, and street lines sit 1–2 m off the boundary (GDA2020 vs the old GDA94 positions). Everything else in every result was unchanged. BYDA states no licence: confirm terms before commercial use." },
  { date: "2026-10-16", data: "Logan Water sewer and water", councils: "Logan",
    change: "Logan_Water_Asset_Location_Data (2019) and AGOL_Water pipes (2018) → Logan Water's current 'Sewerage Information' (gravity pipes, pressure mains, maintenance holes) and 'Water Information' (supply pipes), filtered to existing assets.",
    reason: "The new services are edited daily; the old ones had not changed since 2018–2019. They also give pipe diameter, material and status.",
    verified: "Tested on Logan lots: the sewer pipe on the test lot is now reported as 150 mm PVC-U reticulation (existing). Recycled water stays on the old layer: the new service has none." },
  { date: "2026-10-16", data: "Urban Utilities trunk mains", councils: "Brisbane, Ipswich",
    change: "Removed the separate trunk-main layers (Sewer_sql 2022/2023, Water_sql 2023).",
    reason: "The current open-data gravity and pressure main layers (edited Sep–Oct 2026), already used by the app, contain every trunk main (11,632 sewer and 7,491 water trunk mains), so the older copies were duplicates.",
    verified: "Counts by subtype compared on both services." },
];

/** Publisher evidence found by hand where the automatic checks cannot see it (checked date in the text). */
const CURATED_EVIDENCE: [RegExp, { evidence: string; strength: string }][] = [
  [/arcgis\.lcc\.wspdigital\.com\/server\/rest\/services\/LoganHub\//, { strength: "Strong", evidence:
    "Hosted by Logan's contractor WSP, but registered as an ArcGIS item ('Logan Planning Scheme 2015 v9.2 TLPI No.1 2024') by a Logan City Council staff account (@logan.qld.gov.au) and listed on ArcGIS Hub with source 'Logan City Council' (checked 2026-10-19)" }],
];

/** Notes from checking a source against the planning scheme in force, by hand (shown with the automatic result). */
const SCHEME_NOTES: [RegExp, string][] = [
  [/LoganHub\/Logan_Planning_Scheme_v9_2_TLPI_No_1_2024/, "Service name matches the scheme in force (v9.2 with TLPI No. 1/2024, published 27 May 2025). Its internal map title says 'V9.1', but its zones and precincts are identical to Logan's own v9.2 layers (checked 2026-10-21 at 197 points), so it is the v9.2 mapping."],
  [/Zones_V9_2_WFL1/, "Logan City Council's own v9.2 zones and precincts (edited 17 Jul 2025, after v9.2 commenced on 1 Jul 2025)."],
];

/** State layers → their record on the Queensland Government open data portal (data.qld.gov.au), which states
 *  the owning agency, the update frequency and when the data was last updated (the map services do not). */
const OPEN_DATA: [RegExp, string][] = [
  [/QldLocator\/GeocodeServer|LandParcelPropertyFramework\/MapServer\/0$/, "property-address-queensland-by-area-of-interest"],
  [/LandParcelPropertyFramework\/MapServer\/(4|9)$/, "cadastral-data-queensland-series"],
  [/LandParcelPropertyFramework\/MapServer\/20$/, "local-government-area-boundaries-queensland"],
  [/StatePlanning\/MapServer\/35$/, "priority-development-areas-economic-development-queensland"],
  [/VegetationManagement\/MapServer\/(109|5)$/, "vegetation-management-act-series"],
  [/VegetationManagement\/MapServer\/201$/, "flora-survey-trigger-map-for-clearing-protected-plants-in-queensland-version-10-0"],
  [/MattersOfStateEnvironmentalSignificance\//, "matters-of-state-environmental-significance-queensland-series"],
  [/AdminBoundariesFramework\/MapServer\/15$/, "queensland-floodplain-assessment-overlay"],
  [/Hosted\/BPA\/FeatureServer/, "bushfire-prone-area-queensland-series"],
  [/StateRoadInformation\//, "state-controlled-roads-queensland"],
  [/AdminBoundariesFramework\/MapServer\/78$/, "heritage-register-boundaries-queensland"],
  [/AdminBoundariesFramework\/MapServer\/61$/, "erosion-prone-area-series"],
  [/CoastalManagement\/MapServer\/(11|12)$/, "storm-tide-queensland-series"],
  [/CoastalManagement\/MapServer\/5$/, "coastal-plan-series"],
  [/AdminBoundariesFramework\/MapServer\/82$/, "state-planning-policy-acid-sulfate-soil-affected-areas-queensland"],
  [/WatercourseIdentificationMap\//, "watercourse-identification-map-queensland-series"],
  [/WetlandProtection\//, "wetland-protection-series"],
];

/** Recommended actions found by hand, used in place of the generic action for that flag. */
const ACTION_NOTES: [RegExp, string][] = [
  [/utility\.arcgis\.com\/usrsvcs\/servers\/3ec80e95/, "Checked 2026-10-19: this proxy of the Queensland Fire Department's Bushfire Prone Area now refuses public access (403), and no public State map service carries it. The State dataset is only a download (data last updated Nov 2020, data.qld.gov.au 'Bushfire prone area - Queensland series'). Moreton Bay, Ipswich and Redland rely on it for bushfire. Use each council's bushfire hazard overlay where published, or download the South East Queensland BPA and host it ourselves."],
];

const firstMatch = <T>(list: [RegExp, T][], url: string): T | null => { for (const [re, v] of list) if (re.test(url)) return v; return null; };

function reviewOf(url: string) {
  for (const [re, r] of REVIEWED) if (re.test(url)) return r;
  return null;
}

function publisherOf(url: string): Publisher {
  for (const [re, p] of PUBLISHERS) if (re.test(url)) return p;
  return { publisher: new URL(url).host, level: "Unknown", licence: "Not stated" };
}

const COUNCIL_NAMES: Record<string, string> = {
  BRISBANE: "Brisbane", GOLD_COAST: "Gold Coast", MORETON_BAY: "Moreton Bay", SUNSHINE_COAST: "Sunshine Coast",
  LOGAN: "Logan", IPSWICH: "Ipswich", REDLAND: "Redland",
  BURKE: "Burke", CENTRAL_HIGHLANDS: "Central Highlands", LIVINGSTONE: "Livingstone", MOUNT_ISA: "Mount Isa",
  ROCKHAMPTON: "Rockhampton", SOUTH_BURNETT: "South Burnett", TOOWOOMBA: "Toowoomba", TOWNSVILLE: "Townsville",
  STATE: "All councils", ALL: "All councils",
};

// ----------------------------------------------------------------------------- what the app calls
interface Use {
  url: string; group: string; useType: string; category: string; council: string; item: string;
  field?: string; filter?: string; fact?: string; selection?: string; notes?: string;
}

function collectUses(): Use[] {
  const uses: Use[] = [
    { url: geo.GEOCODER.replace(/\/findAddressCandidates$/, ""), group: "Core property lookup", useType: "Address search", category: "Address",
      council: "ALL", item: "Address → coordinates (Queensland address locator)", field: "Match_addr, score",
      notes: "Matches below 90 % (or below 95 % with unmatched words) are rejected and the candidates are shown." },
    { url: geo.ADDRESS_LAYER, group: "Core property lookup", useType: "Address point → lot", category: "Address",
      council: "ALL", item: "Address points: links an address to its lot/plan when the point is not inside the lot", field: "lotplan, address" },
    { url: geo.PARCEL_LAYER, group: "Core property lookup", useType: "Land parcel", category: "Cadastre",
      council: "ALL", item: "Lot outline, lot/plan, registered area → lot area, estimated width / depth, site-constraint queries",
      field: "lot, plan, lotplan, lot_area, parcel_typ, tenure", fact: "lot_area_m2, lot_width_m, lot_depth_m" },
    { url: geo.LGA_LAYER, group: "Core property lookup", useType: "Council", category: "Boundaries",
      council: "ALL", item: "Which council the property is in (selects the planning scheme)", field: "lga, abbrev_name" },
    { url: geo.PDA_LAYER, group: "Core property lookup", useType: "Priority Development Area", category: "Boundaries",
      council: "ALL", item: "Whether the property is in a PDA (the council scheme does not apply there)", field: "pda_name, pda_status" },
  ];
  const zc = zoning.loadConfig();
  for (const [lg, c] of Object.entries<any>(zc)) {
    if (lg.startsWith("_")) continue;
    if (c.status !== "WORKING") continue;
    const add = (u: Partial<Use> & { url: string; useType: string; item: string }) =>
      uses.push({ group: "Planning scheme (zoning & overlays)", category: "Planning scheme", council: lg, notes: c.notes, ...u });
    if (c.zone_layer) {
      add({ url: c.zone_layer, useType: "Zone", item: "Zone (and precinct / local plan where on the same layer)",
        field: [c.zone_field, c.precinct_field, c.local_plan_field, c.local_plan_precinct_field].filter(Boolean).join(", ") });
    }
    for (const u of c.precinct_layers ?? []) add({ url: u, useType: "Zone precinct", item: "Zone precinct", field: c.precinct_layer_field });
    if (c.local_plan_layer) add({ url: c.local_plan_layer, useType: "Local / neighbourhood plan", item: "Local or neighbourhood plan", field: c.local_plan_layer_field });
    if (c.local_plan_precinct_layer)
      add({ url: c.local_plan_precinct_layer, useType: "Local plan precinct", item: "Local or neighbourhood plan precinct",
        field: [c.local_plan_precinct_code_field, c.local_plan_precinct_name_field].filter(Boolean).join(", ") });
    for (const ov of c.overlay_layers ?? [])
      add({ url: ov.layer, useType: "Overlay", category: "Overlay", item: ov.name, field: ov.field,
        fact: [ov.value_fact, ov.flag_fact].filter(Boolean).join(", ") || "overlay → rule scope", notes: ov.notes ?? c.notes });
  }
  const sc = site.loadConfig();
  for (const [lg, layers] of Object.entries<any>(sc)) {
    if (!Array.isArray(layers)) continue;
    for (const l of layers)
      uses.push({ url: l.layer, group: "Site constraint", useType: l.geometry === "polygon" ? "Area on the lot" : l.geometry === "point" ? "Asset on / near the lot" : "Line crossing the lot",
        category: l.category, council: lg, item: l.name, field: l.label_field ?? "", filter: l.where,
        fact: l.fact, notes: l.notes,
        selection: lg === "STATE" ? (l.always ? "Always checked (State layer, all councils)" : "Used only where the council has no layer for this category")
          : "Council layer (used first for this category)" + (l.distance_m ? `; includes features within ${l.distance_m} m of the lot` : "") });
  }
  return uses;
}

// ----------------------------------------------------------------------------- metadata
const CRS: Record<number, string> = {
  4283: "GDA94 (geographic)", 7844: "GDA2020 (geographic)", 28356: "GDA94 / MGA zone 56", 7856: "GDA2020 / MGA zone 56",
  28355: "GDA94 / MGA zone 55", 7855: "GDA2020 / MGA zone 55", 3857: "WGS 84 / Web Mercator", 102100: "WGS 84 / Web Mercator",
  4326: "WGS 84 (geographic)", 3577: "GDA94 / Australian Albers", 9473: "GDA2020 / Australian Albers",
};
const datumOf = (wkid?: number) => !wkid ? "" : /GDA2020/.test(CRS[wkid] ?? "") ? "GDA2020" : /GDA94/.test(CRS[wkid] ?? "") ? "GDA94" : /WGS/.test(CRS[wkid] ?? "") ? "WGS 84" : "";
const crsName = (sr: any) => {
  const w = sr?.latestWkid ?? sr?.wkid;
  return w ? `${CRS[w] ?? "EPSG " + w} (${w})` : "";
};

const strip = (s: unknown) => String(s ?? "").replace(/<[^>]+>/g, " ").replace(/&nbsp;/g, " ").replace(/&amp;/g, "&").replace(/\s+/g, " ").trim();
const date = (ms: unknown) => (typeof ms === "number" && ms > 0 ? new Date(ms) : null);

/** Sentences in the publisher's own text that state how often the data is updated. */
function statedFrequency(texts: string[]): string {
  const out: string[] = [];
  // a sentence counts only if it talks about updating AND says how often (or that updates have stopped)
  const about = /\b(updat\w*|refresh\w*|frequency|deprecated)\b/i;
  const often = /\b(nightly|daily|weekly|fortnightly|monthly|quarterly|annual(ly)?|yearly|every \w+ (days?|weeks?|months?|years?)|as required|as needed|regularly|periodically|continuous(ly)?|will not be updated|no longer (be )?updated|deprecated)\b/i;
  for (const t of texts)
    for (const m of strip(t).split(/(?<=[.!?])\s+/))
      if (about.test(m) && often.test(m) && !/annual daily traffic/i.test(m) && !out.includes(m.trim())
          // a deprecation notice counts only when it is about this service / dataset, not another layer it names
          && (!/deprecat|decommission|removed/i.test(m) || /\bthis (service|dataset|layer|data)\b/i.test(m)))
        out.push(m.trim().slice(0, 300));
  return out.slice(0, 3).join(" ");
}

async function safe(url: string, params: Record<string, unknown> = { f: "json" }, timeout = 30): Promise<any> {
  try {
    const j = await geo.getJson(url, params, timeout, 2);
    return j && !j.error ? j : { _error: j?.error?.message ?? "error" };
  } catch (e) {
    return { _error: String((e as Error).message ?? e).slice(0, 160) };
  }
}

/** Date fields that record when a feature was last maintained (not construction, gazettal or expiry dates). */
const UPDATE_DATE_FIELD = /(last_?modif|last_?edit|edited_?(on|date)|updat|entry_?date|currency|attribute_date|feature_date|date_?modified)/i;

const serviceUrl =(u: string) => u.replace(/\/(MapServer|FeatureServer|GeocodeServer)(\/\d+)?$/, "/$1");
const isLayer = (u: string) => /\/(MapServer|FeatureServer)\/\d+$/.test(u);

interface Meta { [k: string]: any }

/** ArcGIS Online organisation id in a hosted-service URL (services*.arcgis.com/<id>/arcgis/...). */
const orgIdOf = (u: string) => (u.match(/arcgis\.com\/([A-Za-z0-9]{16})\/arcgis\//i) ?? [])[1] ?? null;

async function metadata(urls: string[], filters: Map<string, string>): Promise<Map<string, Meta>> {
  const services = new Map<string, any>();
  const svcUrls = [...new Set(urls.map(serviceUrl))];
  process.stdout.write(`reading ${svcUrls.length} services`);
  await pool(svcUrls, 8, async (u) => { services.set(u, await safe(u)); process.stdout.write("."); });
  // who runs each ArcGIS Online organisation (public organisations only; others answer "no permission")
  const orgs = new Map<string, any>();
  for (const id of new Set(urls.map(orgIdOf).filter(Boolean) as string[]))
    orgs.set(id, await safe(`https://www.arcgis.com/sharing/rest/portals/${id}`, { f: "json" }, 20));
  const out = new Map<string, Meta>();
  process.stdout.write(`\nreading ${urls.length} layers`);
  const items = new Map<string, any>();
  await pool(urls, 8, async (u) => {
    const svc = services.get(serviceUrl(u)) ?? {};
    const t0 = Date.now();
    const layer = isLayer(u) ? await safe(u) : svc;
    const ms = Date.now() - t0;
    const where = filters.get(u) ?? "1=1";   // the filter the app uses: proves it still works on the live data
    const count = isLayer(u) && !layer._error ? await safe(`${u}/query`, { where, returnCountOnly: "true", f: "json" }, 45) : null;
    // services that do not track edits: the newest value of a record-maintenance date field, if the layer has one
    let newest: { field: string; value: number } | null = null;
    if (isLayer(u) && !layer._error && !layer.editingInfo) {
      const df = (layer.fields ?? []).find((x: any) => x.type === "esriFieldTypeDate" && UPDATE_DATE_FIELD.test(x.name));
      if (df) {
        const st = await safe(`${u}/query`, { where: "1=1", f: "json",
          outStatistics: JSON.stringify([{ statisticType: "max", onStatisticField: df.name, outStatisticFieldName: "newest" }]) }, 60);
        const attrs = st.features?.[0]?.attributes ?? {};
        const v = attrs.newest ?? attrs.NEWEST;
        if (typeof v === "number") newest = { field: df.name, value: v };
      }
    }
    const itemId = layer.serviceItemId ?? svc.serviceItemId;
    let item: any = null;
    if (itemId) {
      if (!items.has(itemId)) {
        const portals = /arcgis\.com/.test(u) ? ["https://www.arcgis.com"] : [new URL(u).origin + "/arcgis", new URL(u).origin + "/portal"];
        let it: any = null;
        for (const p of portals) {
          it = await safe(`${p}/sharing/rest/content/items/${itemId}`, { f: "json" }, 20);
          if (!it._error && it.id) { it._portal = p; break; }
        }
        items.set(itemId, it && it.id ? it : null);
      }
      item = items.get(itemId);
    }
    const orgId = orgIdOf(u);
    const org = orgId ? orgs.get(orgId) : null;
    out.set(u, { layer, svc, count, item, newest, ms, orgId, org: org && !org._error && org.name ? org : null });
    process.stdout.write(".");
  });
  process.stdout.write("\n");
  return out;
}

// ----------------------------------------------------------------------------- verification checks
/** Who provably publishes the service, and how strong that evidence is. */
function verifyPublisher(url: string, m: Meta): { evidence: string; strength: string } {
  const host = new URL(url).host;
  const curated = firstMatch(CURATED_EVIDENCE, url);
  if (curated) return curated;
  if (m.od && /\.qld\.gov\.au$/i.test(host))
    return { evidence: `Government web domain ${host}; the dataset is owned by "${m.od.org}" on data.qld.gov.au`, strength: "Strong" };
  if (m.org) return { evidence: `ArcGIS Online organisation "${m.org.name}" (${m.org.urlKey}.maps.arcgis.com) owns the service`, strength: "Strong" };
  const I = m.item;
  if (/\.gov\.au$/i.test(host)) return { evidence: `Government web domain: ${host}`, strength: "Strong" };
  // the item is the one the service itself names (serviceItemId), so it belongs to the hosting organisation; its
  // owner account (e.g. "opendata_goldcoast", "QUU_GIS_Admin") identifies the publisher, but less firmly than a name
  if (I?.owner && (!I.orgId || !m.orgId || I.orgId === m.orgId))
    return { evidence: `ArcGIS item (named by the service) owned by account "${I.owner}"; the organisation keeps its details private`, strength: "Medium" };
  return { evidence: `Hosted at ${host}: not a government domain or a verifiable organisation`, strength: "Weak" };
}

/** Do the fields the app reads still exist? (A renamed field silently breaks a lookup.) */
function fieldsCheck(field: string, L: any): string {
  const have = new Set<string>((L.fields ?? []).map((f: any) => String(f.name).toLowerCase()));
  if (!have.size) return "Not checkable (service lists no fields)";
  const wanted = String(field ?? "").split(/,\s*/).map((s) => s.trim()).filter((s) => s && /^[A-Za-z_][\w.]*$/.test(s));
  const missing = wanted.filter((f) => !have.has(f.toLowerCase()));
  return missing.length ? `MISSING: ${missing.join(", ")}` : wanted.length ? `OK (${wanted.join(", ")})` : "OK";
}

/** How current is the data: from the stated frequency, else from the age of the last update. */
function currencyGrade(freq: string, age: number | "", reviewed: boolean): { grade: string; why: string } {
  const often = /nightly|daily|weekly|fortnightly|monthly|near-realtime|real-time/i.exec(freq || "");
  if (often && !/deprecat|will not be updated/i.test(freq)) return { grade: "Current", why: `The publisher states it is updated ${often[0].toLowerCase()}` };
  if (age === "") return { grade: "Unknown", why: "The service exposes no update date: check the publisher's portal" };
  if (age <= 365) return { grade: "Current", why: `Updated ${age} days ago` };
  if (age <= 730) return { grade: "Ageing", why: `Updated ${age} days ago (1–2 years)` };
  return reviewed ? { grade: "Old, checked", why: `Updated ${age} days ago; checked: no newer version is published` }
    : { grade: "Stale", why: `Updated ${age} days ago (over 2 years)` };
}

/** Planning-scheme layers: is the map data from the scheme version in force? */
function schemeMatch(url: string, layerName: string, lastUpdate: Date | null, scheme: any): string {
  if (!scheme) return "";
  const num = (s: string) => (String(s).match(/(\d+(?:[._]\d+)?)/) ?? [])[1]?.replace("_", ".");
  const inForce = num(scheme.version_label);
  const path = decodeURIComponent(new URL(url).pathname);
  const named = (path.match(/(?:version|[^a-z]v)[ _]?(\d+(?:_\d+)?)(?![\d])/i) ?? [])[1]?.replace("_", ".");
  if (named && inForce && Number(named) !== Number(inForce))
    return `VERSION MISMATCH: the service is named for version ${named}; the scheme in force is ${scheme.version_label} (from ${String(scheme.effective_from).slice(0, 10)})`;
  if (!lastUpdate) return `No data date to compare with the scheme in force (${scheme.version_label})`;
  const from = new Date(scheme.effective_from), day = 86400000;
  const fromText = String(scheme.effective_from).slice(0, 10);
  if (lastUpdate >= from) return `OK: data updated on or after the scheme version in force commenced (${fromText})`;
  // councils prepare a version's mapping shortly before it commences (Brisbane v37: data 17 Sep, in force 18 Sep 2026)
  const before = Math.round((from.getTime() - lastUpdate.getTime()) / day);
  if (before <= 90) return `OK: data published ${before} day(s) before the scheme version in force commenced (${fromText}), i.e. prepared for it`;
  return `Data older than the scheme version in force (${scheme.version_label}, from ${fromText}): confirm that amendment did not change this map`;
}

// ----------------------------------------------------------------------------- workbook
const HEADER_FILL: ExcelJS.Fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF1F4E78" } };
const LEVEL_FILL: Record<string, string> = {
  "Local council": "FFE2EFDA", "Council-owned water utility": "FFDDEBF7", "State": "FFFFF2CC", "State-owned utility": "FFFCE4D6",
  "National (Commonwealth)": "FFEDE7F6", "International / commercial": "FFF2F2F2",
};

function sheet(wb: ExcelJS.Workbook, name: string, cols: { header: string; key: string; width: number }[], rows: any[], levelKey?: string) {
  const ws = wb.addWorksheet(name, { views: [{ state: "frozen", ySplit: 1, xSplit: cols.length > 8 ? 2 : 0 }] });
  ws.columns = cols;
  for (const r of rows) ws.addRow(r);
  const head = ws.getRow(1);
  head.font = { bold: true, color: { argb: "FFFFFFFF" } };
  head.fill = HEADER_FILL;
  head.alignment = { vertical: "middle", wrapText: true };
  head.height = 32;
  ws.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: cols.length } };
  ws.eachRow((row, i) => {
    if (i === 1) return;
    row.alignment = { vertical: "top", wrapText: true };
    if (levelKey) {
      const fill = LEVEL_FILL[String(row.getCell(levelKey).value)];
      if (fill) row.getCell(levelKey).fill = { type: "pattern", pattern: "solid", fgColor: { argb: fill } };
    }
    row.eachCell((cell) => {
      const v = cell.value;
      if (typeof v === "string" && /^https?:\/\//.test(v)) cell.value = { text: v, hyperlink: v };
      if (v instanceof Date) cell.numFmt = "yyyy-mm-dd";
    });
  });
  return ws;
}

async function main(): Promise<number> {
  const a = parseArgs(process.argv.slice(2), { booleans: ["no-probe"], defaults: { out: path.join(ROOT, "docs", "data-sources-register.xlsx") } });
  loadEnv();
  const checked = new Date();
  const uses = collectUses();
  const urls = [...new Set(uses.map((u) => u.url))];
  const filters = new Map<string, string>();
  for (const u of uses) if (u.filter && !filters.has(u.url)) filters.set(u.url, u.filter);
  const meta = await metadata(urls, filters);
  // State layers: the dataset record on data.qld.gov.au (owner, update frequency, data last updated)
  const odCache = new Map<string, any>();
  for (const u of urls) {
    const id = firstMatch(OPEN_DATA, u);
    if (!id) continue;
    if (!odCache.has(id)) {
      const p = (await safe("https://www.data.qld.gov.au/api/3/action/package_show", { id }, 30)).result;
      odCache.set(id, p ? { id, title: p.title, org: p.organization?.title ?? "", freq: p.update_frequency ?? "",
        updated: date(Date.parse(p.data_last_updated ?? p.metadata_modified ?? "")), licence: p.license_title ?? "",
        url: `https://www.data.qld.gov.au/dataset/${id}` } : null);
    }
    const m = meta.get(u);
    if (m && odCache.get(id)) m.od = odCache.get(id);
  }
  // planning scheme in force per council (to check the map data is at least as new as the scheme version)
  const schemeDb = new Db({ max: 1 });
  let schemeRows: any[] = [];
  try {
    schemeRows = await schemeDb.q(`SELECT coalesce(json_agg(x), '[]') FROM (SELECT i.lg_id, v.version_label, v.effective_from FROM regs.instruments i
      JOIN regs.instrument_versions v USING (instrument_id) WHERE i.kind = 'PLANNING_SCHEME' AND v.status = 'ACTIVE') x`);
  } finally {
    await schemeDb.close();
  }
  const schemeOf = new Map<string, any>(schemeRows.map((s) => [s.lg_id, s]));

  // ---- one row per (use of a) source
  const rows = uses.map((u, i) => {
    const m = meta.get(u.url)!;
    const L = m.layer ?? {}, S = m.svc ?? {}, I = m.item;
    const pub = publisherOf(u.url);
    const ei = L.editingInfo ?? {};
    const dataEdit = date(ei.dataLastEditDate) ?? date(ei.lastEditDate);
    const itemMod = date(I?.modified);
    const newest = m.newest ? date(m.newest.value) : null;
    const odDate: Date | null = m.od?.updated ?? null;
    // last resorts for map servers that expose no dates: a publication stamp in the service description
    // (Redland: "AutoPublished at 19-10-2026 00:30"), or a date in the service name (Logan: "..._20250527")
    const stamp = /AutoPublished at (\d{2})-(\d{2})-(\d{4})/i.exec(`${S.serviceDescription ?? ""} ${S.description ?? ""}`);
    const published = stamp ? new Date(Date.UTC(+stamp[3], +stamp[2] - 1, +stamp[1])) : null;
    const named = /_(20\d{2})(\d{2})(\d{2})(?=\/|$)/.exec(decodeURIComponent(new URL(u.url).pathname));
    const nameDate = named ? new Date(Date.UTC(+named[1], +named[2] - 1, +named[3])) : null;
    const lastUpdate = dataEdit ?? itemMod ?? newest ?? odDate ?? published ?? nameDate;
    const desc = strip(L.description) || strip(S.serviceDescription) || strip(S.description) || strip(I?.description) || strip(I?.snippet);
    const stated = statedFrequency([L.description, S.serviceDescription, S.description, I?.description, I?.snippet, I?.licenseInfo, S.documentInfo?.Comments]);
    // the State open-data record states a frequency for every dataset (e.g. weekly, near-realtime, non-regular)
    const freq = stated || (m.od?.freq ? `data.qld.gov.au record: ${m.od.freq}` : "");
    const sr = L.sourceSpatialReference ?? L.extent?.spatialReference ?? S.spatialReference ?? S.fullExtent?.spatialReference;
    const wkid = sr?.latestWkid ?? sr?.wkid;
    const status = L._error ? `ERROR: ${L._error}` : "OK (anonymous access)";
    const svcType = (u.url.match(/(MapServer|FeatureServer|GeocodeServer)/) ?? [])[1] ?? "";
    // ---- verification
    const ver = verifyPublisher(u.url, m);
    const age = lastUpdate ? Math.floor((checked.getTime() - lastUpdate.getTime()) / 86400000) : "";
    const cur = currencyGrade(freq, age, Boolean(reviewOf(u.url)));
    const planningLayer = u.group === "Planning scheme (zoning & overlays)"
      || (pub.level === "Local council" && /city plan|planning scheme|overlay|\bOM[-_]|_V\d/i.test(`${u.item} ${u.url}`));
    const filterOk = !u.filter ? "" : m.count?._error ? `ERROR: ${m.count._error}` : typeof m.count?.count === "number"
      ? `OK (${m.count.count} features match)` : "Not checkable";
    return {
      verified: ver.evidence, strength: ver.strength, ms: L._error ? "" : m.ms,
      fieldsOk: L._error ? "" : fieldsCheck(u.field ?? "", L), filterOk,
      grade: cur.grade, gradeWhy: cur.why,
      scheme: [planningLayer ? schemeMatch(u.url, L.name ?? "", lastUpdate, schemeOf.get(u.council)) : "", firstMatch(SCHEME_NOTES, u.url) ?? "", firstMatch(SCHEME_REVIEWED, u.url) ?? ""]
        .filter(Boolean).join(" — "),
      odRecord: m.od?.url ?? "", odOrg: m.od?.org ?? "", odFreq: m.od?.freq ?? "", odUpdated: m.od?.updated ?? "",
      id: `S${String(i + 1).padStart(3, "0")}`,
      group: u.group, useType: u.useType, category: u.category, council: COUNCIL_NAMES[u.council] ?? u.council,
      item: u.item, selection: u.selection ?? (u.group === "Site constraint" ? "" : u.council === "ALL" ? "Always (every address)" : "Council layer"),
      fact: u.fact ?? "", publisher: pub.publisher, level: pub.level,
      layerName: L.name ?? S.mapName ?? S.serviceDescription?.slice?.(0, 60) ?? "", serviceType: svcType,
      geometry: String(L.geometryType ?? "").replace("esriGeometry", ""),
      count: typeof m.count?.count === "number" ? m.count.count : "",
      field: u.field ?? "", filter: u.filter ?? "",
      url: u.url, metaUrl: `${u.url}?f=pjson`,
      itemUrl: I?.id ? `${I._portal}/home/item.html?id=${I.id}` : "",
      portal: pub.portal ?? "",
      licence: pub.licence, itemLicence: strip(I?.licenseInfo).slice(0, 400),
      copyright: strip(L.copyrightText) || strip(S.copyrightText) || strip(I?.accessInformation),
      lastUpdate: lastUpdate ?? "", lastUpdateBasis: dataEdit ? "Layer data last edited (service editingInfo)" : itemMod ? "Item record last modified (ArcGIS item)"
        : newest ? `Newest record date in the data (field ${m.newest.field})`
        : odDate ? "Dataset record on data.qld.gov.au: data last updated"
        : published ? "Publication stamp in the service description ('AutoPublished at')"
        : nameDate ? "Date in the service name" : "Not exposed by this service — see the publisher portal",
      schemaEdit: date(ei.schemaLastEditDate) ?? "",
      itemCreated: date(I?.created) ?? "",
      age,
      freq: freq || "Not stated by the publisher",
      check: "Monthly (npm run check-services), and at every planning-scheme amendment",
      crs: crsName(sr), datum: datumOf(wkid),
      maxRecords: L.maxRecordCount ?? S.maxRecordCount ?? "", version: L.currentVersion ?? S.currentVersion ?? "",
      status, checked,
      notes: u.notes ?? "", description: desc.slice(0, 1500),
      flag: "", action: "",
    };
  });

  // ---- flags: what needs attention, with the recommended action
  for (const r of rows) {
    const notice = String(r.freq);
    if (r.status.startsWith("ERROR")) {
      r.flag = "UNREACHABLE";
      r.action = "The service did not answer during this check. Re-run; if it persists, find the new URL on the publisher portal and update poc/zoning_layers.json or poc/site_layers.json.";
    } else if (/decommission/i.test(notice)) {
      r.flag = "SERVICE BEING DECOMMISSIONED";
      r.action = r.url === geo.PDA_LAYER
        ? "Replacement published by the State: https://spatial-gis.information.qld.gov.au/arcgis/rest/services/PlanningCadastre/StatePlanning/MapServer/35 (same fields, same 51 areas, checked "
          + checked.toISOString().slice(0, 10) + "). Change PDA_LAYER in server-ts/src/core/geo.ts before the decommission date."
        : "Find the replacement service named in the publisher's notice and update the configuration before the decommission date.";
    } else if (/deprecat|will not be updated|no longer (be )?updated/i.test(notice)) {
      r.flag = "DEPRECATED — no further updates";
      r.action = /Energex/.test(r.publisher)
        ? "Energex no longer updates this public layer: treat its lines as indicative only. Confirm services for each site with a Before You Dig Australia (BYDA) enquiry, or ask Energex for current network data."
        : "The publisher no longer updates this layer. Look for a current replacement, or label results from it as indicative.";
    } else if (String(r.fieldsOk).startsWith("MISSING")) {
      r.flag = "FIELD MISSING";
      r.action = `The layer no longer has a field the app reads (${r.fieldsOk.replace("MISSING: ", "")}), so this lookup returns nothing. Find the new field name in the layer metadata and update the configuration.`;
    } else if (String(r.filterOk).startsWith("ERROR")) {
      r.flag = "FILTER BROKEN";
      r.action = `The filter "${r.filter}" no longer works on the live layer (${r.filterOk}). Update it in poc/site_layers.json.`;
    } else if ((String(r.scheme).startsWith("VERSION MISMATCH") || String(r.scheme).startsWith("Data older")) && firstMatch(SCHEME_REVIEWED, r.url)) {
      r.flag = "Scheme version: checked";
      r.action = `No action needed. ${firstMatch(SCHEME_REVIEWED, r.url)}`;
    } else if (String(r.scheme).startsWith("VERSION MISMATCH")) {
      r.flag = "SCHEME VERSION MISMATCH";
      r.action = `${r.scheme}. Look for the service for the scheme version in force on the council's open-data portal${r.portal ? ` (${r.portal})` : ""}, and switch to it; until then, check results against the council's online scheme maps.`;
    } else if (r.strength === "Weak") {
      r.flag = "PUBLISHER NOT VERIFIABLE";
      r.action = `${r.verified}. Ask the publisher to confirm this is their official service (or find it on their open-data portal${r.portal ? `: ${r.portal}` : ""}).`;
    } else if (typeof r.age === "number" && r.age > 730 && reviewOf(r.url)) {
      const rv = reviewOf(r.url)!;
      r.flag = "Old data — checked, no newer version";
      r.action = `No action needed. Checked ${rv.checked}: ${rv.finding} Re-check at the next review.`;
    } else if (typeof r.age === "number" && r.age > 730) {
      r.flag = "Not updated for over 2 years";
      r.action = r.group === "Planning scheme (zoning & overlays)" || /overlay/i.test(r.item)
        ? "Planning-scheme maps change only at amendments, so an old date can be correct. Confirm against the council's current scheme mapping."
        : "Confirm with the publisher that this is still the current version of the data.";
    }
    const note = firstMatch(ACTION_NOTES, r.url);   // a specific recommendation found by hand
    if (note && r.flag) r.action = note;
  }

  const wb = new ExcelJS.Workbook();
  wb.creator = "Siteora";
  wb.created = checked;

  // ---- About
  const about = wb.addWorksheet("About");
  about.columns = [{ width: 34 }, { width: 120 }];
  const levels = new Map<string, number>();
  for (const r of rows) levels.set(r.level, (levels.get(r.level) ?? 0) + 1);
  const aboutRows: [string, string][] = [
    ["Siteora — data source register", ""],
    ["Generated", checked.toISOString().replace("T", " ").slice(0, 16) + " UTC"],
    ["Generated by", "npm run data-register (server-ts/src/tools/data-register.ts). Re-run it to refresh every date and status."],
    ["What it lists", "Every external API and map layer the application calls for an address: the State property lookups, each council's planning-scheme zoning and overlay layers, and the site-constraint layers (easements, sewer, water, stormwater, electricity, flood, vegetation, heritage, bushfire, coastal, airport, noise, soils, slope, waterways). The 'Regulatory documents' sheet lists the legislation, codes and planning schemes the rules come from."],
    ["Selection rule", "Council data first. Queensland Government (State) data is used for a category only where the council publishes nothing; a few State layers (easements in the cadastre, Energex lines, regulated vegetation) are always checked."],
    ["How the data is used", "Live queries at the time of each request (no copy is stored). Zoning and overlays are queried at the address point and inside the lot; site constraints are queried against the whole lot outline, and features that only touch the boundary are ignored."],
    ["'Last updated'", "Taken from each service's own metadata: the date the layer's data was last edited, or, where the service does not expose that, the date its ArcGIS item record was last modified. MapServer services on council servers often expose neither: the cell then says so."],
    ["'Update frequency'", "Quoted only where the publisher states it in the service or item description. Otherwise 'Not stated by the publisher'. The 'Days since last update' column shows how current each layer actually is."],
    ["Coordinate system", "The layer's stored coordinate system. The State cadastre is GDA94; some council and national layers are GDA2020 or Web Mercator. The app requests everything in WGS 84, so the services convert; differences between datums and between cadastre versions explain the small offsets between council map lines and the State lot outline (typically 1–3 m)."],
    ["Licences", "Attribution is required for every source. Redland data is CC BY-SA 4.0 (share-alike applies to redistributed derivative data). Utility layers (Energex, Urban Utilities, Unitywater) state no licence in their services: confirm terms with the utility before commercial redistribution."],
    ["Not available", "Ipswich City Plan 2025 zoning and overlays require a login token and are not used; the zone is chosen manually. Data has been requested from council@ipswich.qld.gov.au. See the 'Councils' sheet."],
    ["", ""],
    ["Needs attention", ""],
    ...[...new Set(rows.map((r) => r.flag).filter(Boolean))].map((f) =>
      [f, `${rows.filter((r) => r.flag === f).length} layer uses — see the 'Issues' sheet`] as [string, string]),
    ...(rows.some((r) => r.flag) ? [] : [["None", "Every layer answered and none is deprecated or more than 2 years old."] as [string, string]]),
    ["", ""],
    ["Sources by publisher level", ""],
    ...[...levels].sort((x, y) => y[1] - x[1]).map(([k, n]) => [k, `${n} layer uses`] as [string, string]),
    ["", ""],
    ["Sheets", ""],
    ["Issues", "Layers that are being decommissioned, deprecated, unreachable, missing a field, on the wrong scheme version, not verifiable or more than 2 years old, with the recommended action."],
    ["Verification summary", "Per council and per publisher type: how many sources are verified (strong / medium / weak), current / ageing / stale, matching the planning scheme in force, and broken."],
    ["How to verify", "The method: each check, what it proves, how this register does it, and how to repeat it by hand."],
    ["All sources", "One row per layer use, with every recorded attribute (filter by council, category, level…)."],
    ["Councils", "Per council: planning scheme, scheme website, zoning service status, counts by level, categories covered."],
    ["Coverage", "Which publisher supplies each site-constraint category in each council."],
    ["Regulatory documents", "Instruments in the rules database: Acts, regulations, QDC / QHC parts, planning schemes, with versions, dates and source URLs."],
    ["Change log", "Source changes made after reviewing this register, with the reason and how each was verified."],
    ["Map display", "Base maps and libraries used to draw the map page."],
  ];
  for (const r of aboutRows) about.addRow(r);
  about.getRow(1).font = { bold: true, size: 16 };
  about.eachRow((row, i) => {
    if (i > 1) { row.getCell(1).font = { bold: true }; row.alignment = { vertical: "top", wrapText: true }; }
  });
  about.eachRow((row) => {
    if (["Needs attention", "Sources by publisher level", "Sheets"].includes(String(row.getCell(1).value))) row.font = { bold: true, size: 12 };
  });

  // ---- Issues
  const FLAG_FILL: Record<string, string> = {
    "SERVICE BEING DECOMMISSIONED": "FFF8CBAD", "UNREACHABLE": "FFF8CBAD", "FIELD MISSING": "FFF8CBAD", "FILTER BROKEN": "FFF8CBAD",
    "SCHEME VERSION MISMATCH": "FFFFE699", "DEPRECATED — no further updates": "FFFFE699", "PUBLISHER NOT VERIFIABLE": "FFFFE699",
    "Not updated for over 2 years": "FFFFF2CC", "Old data — checked, no newer version": "FFE2EFDA", "Scheme version: checked": "FFE2EFDA",
  };
  const order = Object.keys(FLAG_FILL);
  const issues = rows.filter((r) => r.flag).sort((x, y) => order.indexOf(x.flag) - order.indexOf(y.flag) || x.id.localeCompare(y.id));
  const wsIssues = sheet(wb, "Issues", [
    { header: "ID", key: "id", width: 7 },
    { header: "Flag", key: "flag", width: 26 },
    { header: "Council", key: "council", width: 14 },
    { header: "Category", key: "category", width: 14 },
    { header: "Data item", key: "item", width: 40 },
    { header: "Publisher", key: "publisher", width: 28 },
    { header: "Last updated", key: "lastUpdate", width: 12 },
    { header: "Days since last update", key: "age", width: 10 },
    { header: "Publisher's notice", key: "freq", width: 50 },
    { header: "Recommended action", key: "action", width: 70 },
    { header: "API endpoint", key: "url", width: 60 },
  ], issues);
  wsIssues.eachRow((row, i) => {
    const fill = FLAG_FILL[String(row.getCell("flag").value)];
    if (i > 1 && fill) row.getCell("flag").fill = { type: "pattern", pattern: "solid", fgColor: { argb: fill } };
  });

  // ---- All sources
  const wsAll = sheet(wb, "All sources", [
    { header: "ID", key: "id", width: 7 },
    { header: "Flag", key: "flag", width: 20 },
    { header: "Data item (what the app uses it for)", key: "item", width: 42 },
    { header: "Group", key: "group", width: 20 },
    { header: "Lookup type", key: "useType", width: 20 },
    { header: "Category", key: "category", width: 15 },
    { header: "Council", key: "council", width: 14 },
    { header: "When it is used", key: "selection", width: 30 },
    { header: "Publisher", key: "publisher", width: 30 },
    { header: "Publisher level", key: "level", width: 18 },
    { header: "Publisher verified by", key: "verified", width: 40 },
    { header: "Verification strength", key: "strength", width: 11 },
    { header: "Currency grade", key: "grade", width: 11 },
    { header: "Currency reasoning", key: "gradeWhy", width: 34 },
    { header: "Matches the planning scheme in force?", key: "scheme", width: 44 },
    { header: "Answered in (ms)", key: "ms", width: 10 },
    { header: "Fields the app reads are present", key: "fieldsOk", width: 22 },
    { header: "Filter works on live data", key: "filterOk", width: 20 },
    { header: "Layer name (publisher)", key: "layerName", width: 30 },
    { header: "Service type", key: "serviceType", width: 13 },
    { header: "Geometry", key: "geometry", width: 10 },
    { header: "Features in layer", key: "count", width: 11 },
    { header: "Field(s) read", key: "field", width: 22 },
    { header: "Filter applied", key: "filter", width: 20 },
    { header: "Rule fact fed", key: "fact", width: 22 },
    { header: "Last updated", key: "lastUpdate", width: 12 },
    { header: "Last updated — basis", key: "lastUpdateBasis", width: 24 },
    { header: "Days since last update", key: "age", width: 10 },
    { header: "Update frequency (as stated by publisher)", key: "freq", width: 40 },
    { header: "Our check interval", key: "check", width: 26 },
    { header: "Schema last changed", key: "schemaEdit", width: 12 },
    { header: "Item record created", key: "itemCreated", width: 12 },
    { header: "Licence", key: "licence", width: 18 },
    { header: "Licence text (ArcGIS item)", key: "itemLicence", width: 30 },
    { header: "Attribution / copyright", key: "copyright", width: 30 },
    { header: "Coordinate system (stored)", key: "crs", width: 24 },
    { header: "Datum", key: "datum", width: 9 },
    { header: "Max records per request", key: "maxRecords", width: 10 },
    { header: "ArcGIS version", key: "version", width: 9 },
    { header: "API endpoint", key: "url", width: 60 },
    { header: "Layer metadata (JSON)", key: "metaUrl", width: 40 },
    { header: "ArcGIS item page", key: "itemUrl", width: 40 },
    { header: "Publisher open-data portal", key: "portal", width: 32 },
    { header: "State open-data record (data.qld.gov.au)", key: "odRecord", width: 40 },
    { header: "Record: owning agency", key: "odOrg", width: 28 },
    { header: "Record: update frequency", key: "odFreq", width: 14 },
    { header: "Record: data last updated", key: "odUpdated", width: 12 },
    { header: "Access check", key: "status", width: 20 },
    { header: "Checked at", key: "checked", width: 12 },
    { header: "Configuration notes", key: "notes", width: 50 },
    { header: "Publisher description", key: "description", width: 80 },
    { header: "Recommended action (flagged rows)", key: "action", width: 60 },
  ], rows, "level");
  const GRADE_FILL: Record<string, string> = {
    Current: "FFC6EFCE", Ageing: "FFFFEB9C", "Old, checked": "FFE2EFDA", Stale: "FFFFC7CE", Unknown: "FFEDEDED",
    Strong: "FFC6EFCE", Medium: "FFFFEB9C", Weak: "FFFFC7CE",
  };
  wsAll.eachRow((row, i) => {
    if (i === 1) return;
    const fill = FLAG_FILL[String(row.getCell("flag").value)];
    if (fill) row.getCell("flag").fill = { type: "pattern", pattern: "solid", fgColor: { argb: fill } };
    for (const key of ["grade", "strength"]) {
      const g = GRADE_FILL[String(row.getCell(key).value)];
      if (g) row.getCell(key).fill = { type: "pattern", pattern: "solid", fgColor: { argb: g } };
    }
    const sc = String(row.getCell("scheme").value ?? "");
    if (sc) row.getCell("scheme").fill = { type: "pattern", pattern: "solid",
      fgColor: { argb: sc.startsWith("OK") ? "FFC6EFCE" : sc.startsWith("VERSION") ? "FFFFC7CE" : "FFFFEB9C" } };
  });

  // ---- Verification summary: per council and per publisher level
  const summaryRow = (label: string, rs: typeof rows) => {
    const n = (f: (r: (typeof rows)[number]) => boolean) => rs.filter(f).length;
    const answered = rs.filter((r) => typeof r.ms === "number").map((r) => r.ms as number).sort((x, y) => x - y);
    return {
      label, layers: rs.length,
      strong: n((r) => r.strength === "Strong"), medium: n((r) => r.strength === "Medium"), weak: n((r) => r.strength === "Weak"),
      current: n((r) => r.grade === "Current"), ageing: n((r) => r.grade === "Ageing"), old: n((r) => r.grade === "Old, checked"),
      stale: n((r) => r.grade === "Stale"), unknown: n((r) => r.grade === "Unknown"),
      schemeOk: n((r) => String(r.scheme).startsWith("OK")), schemeOlder: n((r) => String(r.scheme).startsWith("Data older")),
      schemeMismatch: n((r) => String(r.scheme).startsWith("VERSION")),
      broken: n((r) => r.status.startsWith("ERROR") || String(r.fieldsOk).startsWith("MISSING") || String(r.filterOk).startsWith("ERROR")),
      median: answered.length ? answered[Math.floor(answered.length / 2)] : "",
    };
  };
  const councilKeys = Object.keys(COUNCIL_NAMES).filter((k) => !["STATE", "ALL"].includes(k));
  const summary = [
    summaryRow("All sources", rows),
    ...councilKeys.map((k) => summaryRow(COUNCIL_NAMES[k], rows.filter((r) => r.council === COUNCIL_NAMES[k]))),
    summaryRow("State / national (all councils)", rows.filter((r) => r.council === COUNCIL_NAMES.ALL)),
    ...[...new Set(rows.map((r) => r.level))].map((lv) => summaryRow(`Publisher level: ${lv}`, rows.filter((r) => r.level === lv))),
  ];
  sheet(wb, "Verification summary", [
    { header: "Group", key: "label", width: 34 },
    { header: "Layer uses", key: "layers", width: 9 },
    { header: "Publisher verified: strong", key: "strong", width: 11 },
    { header: "medium", key: "medium", width: 9 },
    { header: "weak", key: "weak", width: 8 },
    { header: "Currency: current", key: "current", width: 10 },
    { header: "ageing (1–2 y)", key: "ageing", width: 9 },
    { header: "old, checked", key: "old", width: 9 },
    { header: "stale (> 2 y)", key: "stale", width: 9 },
    { header: "unknown (no date)", key: "unknown", width: 10 },
    { header: "Planning layers: match scheme in force", key: "schemeOk", width: 12 },
    { header: "older than scheme version", key: "schemeOlder", width: 11 },
    { header: "version mismatch", key: "schemeMismatch", width: 10 },
    { header: "Broken (unreachable, field missing, filter failing)", key: "broken", width: 14 },
    { header: "Median answer time (ms)", key: "median", width: 11 },
  ], summary);

  // ---- Integration assessment: per host — rate limits, demand, measured behaviour, terms, fitness, risk
  if (!a["no-probe"]) {
    process.stdout.write("integration: probing hosts and counting one lookup per council…\n");
    const sample = new Map<string, string>();
    const isLayerUrl = (u: string) => /\/(MapServer|FeatureServer)\/\d+$/.test(u);
    // probe a working map layer on each host (not the address-search service), else any of its layers
    for (const r of rows) if (isLayerUrl(r.url) && !r.status.startsWith("ERROR") && !sample.has(hostKey(r.url))) sample.set(hostKey(r.url), r.url);
    for (const r of rows) if (!sample.has(hostKey(r.url))) sample.set(hostKey(r.url), r.url);   // hosts with only failing layers
    const demand = await demandPerLookup(TEST_POINTS);
    const probes = new Map<string, any>();
    for (const [k, u] of sample) probes.set(k, /\/(MapServer|FeatureServer)\/\d+$/.test(u) ? await probeHost(u) : null);
    const integ = [...sample.keys()].map((k) => {
      const f = factsFor(k), p = probes.get(k), d = demand.get(k);
      const perLookup = d && d.lookups ? Math.round(d.requests / d.lookups) : null;
      const unitsPerLookup = d && d.lookups && d.units ? Math.round(d.units / d.lookups) : null;
      return {
        host: k, publisher: f?.publisher ?? rows.find((r) => hostKey(r.url) === k)?.publisher ?? "",
        layers: rows.filter((r) => hostKey(r.url) === k).length,
        budget: p?.budgetMax ? `${p.budgetMax.toLocaleString("en-US")} units / minute for the publisher's whole organisation (in use at check: ${p.budgetUsed ?? "?"})`
          : "None published (not ArcGIS Online)",
        unitsPerQuery: p?.unitsPerQuery ?? "",
        perLookup: perLookup ?? "", unitsPerLookup: unitsPerLookup ?? "",
        headroom: p?.budgetMax && unitsPerLookup ? Math.floor(p.budgetMax / unitsPerLookup) : "",
        seq: p?.seq ?? "", burst: p?.burst ?? "", errors: p?.errors ?? "not probed",
        https: p?.https ?? (k.startsWith("http:") ? "HTTP only" : "HTTPS"), cors: p?.cors ?? "", cache: p?.cache ?? "",
        terms: f?.terms ?? "", termsUrl: f?.termsUrl ?? "", sitePlan: f?.sitePlan ?? "", risk: f?.risk ?? "", mitigation: f?.mitigation ?? "",
      };
    });
    // the two map backgrounds (browser only, not probed)
    for (const k of ["tile.openstreetmap.org", "server.arcgisonline.com"]) {
      const f = factsFor(k)!;
      integ.push({ host: k, publisher: f.publisher, layers: 0, budget: "Usage policy (see terms)", unitsPerQuery: "", perLookup: "", unitsPerLookup: "",
        headroom: "", seq: "", burst: "", errors: "not probed (map background)", https: "HTTPS", cors: "", cache: "", terms: f.terms,
        termsUrl: f.termsUrl ?? "", sitePlan: f.sitePlan, risk: f.risk, mitigation: f.mitigation });
    }
    const RISK_FILL: Record<string, string> = { High: "FFFFC7CE", Medium: "FFFFEB9C", Low: "FFC6EFCE" };
    const wsI = sheet(wb, "Integration assessment", [
      { header: "Host (ArcGIS Online: host/organisation)", key: "host", width: 34 },
      { header: "Publisher and what it supplies", key: "publisher", width: 40 },
      { header: "Layers used", key: "layers", width: 8 },
      { header: "Rate limit (published by the service)", key: "budget", width: 34 },
      { header: "Units per query", key: "unitsPerQuery", width: 8 },
      { header: "Requests per property lookup (measured)", key: "perLookup", width: 11 },
      { header: "Units per lookup", key: "unitsPerLookup", width: 9 },
      { header: "Lookups per minute that would use the whole budget", key: "headroom", width: 13 },
      { header: "Answer time, one at a time: median / 95 % (ms)", key: "seq", width: 14 },
      { header: "Answer time, 10 at once: median / 95 % (ms)", key: "burst", width: 14 },
      { header: "Errors in the test (20 queries)", key: "errors", width: 26 },
      { header: "HTTPS", key: "https", width: 12 },
      { header: "Browser access (CORS)", key: "cors", width: 14 },
      { header: "Caching (Cache-Control)", key: "cache", width: 22 },
      { header: "Licence / terms", key: "terms", width: 34 },
      { header: "Terms page", key: "termsUrl", width: 30 },
      { header: "Fitness for drawing site plans", key: "sitePlan", width: 60 },
      { header: "Risk", key: "risk", width: 8 },
      { header: "In place / recommended", key: "mitigation", width: 70 },
    ], integ);
    wsI.eachRow((row, i) => {
      const fill = RISK_FILL[String(row.getCell("risk").value)];
      if (i > 1 && fill) row.getCell("risk").fill = { type: "pattern", pattern: "solid", fgColor: { argb: fill } };
    });
  }

  // ---- Site-plan readiness: the overall verdict per aspect (checked 2026-10-19; numbers from this run)
  const pctOf = (n: number) => `${Math.round((100 * n) / rows.length)} %`;
  const cnt = (f: (r: (typeof rows)[number]) => boolean) => rows.filter(f).length;
  sheet(wb, "Site-plan readiness", [
    { header: "Aspect", key: "aspect", width: 26 },
    { header: "Verdict", key: "verdict", width: 14 },
    { header: "Evidence", key: "evidence", width: 80 },
    { header: "What it means for a site plan / what to do", key: "action", width: 80 },
  ], [
    { aspect: "Data is current", verdict: "Mostly",
      evidence: `Live queries on every request (nothing stored except map drawing, cached 1 hour). Current ${cnt((r) => r.grade === "Current")} (${pctOf(cnt((r) => r.grade === "Current"))}); ageing ${cnt((r) => r.grade === "Ageing")}; old but checked ${cnt((r) => r.grade === "Old, checked")}; stale ${cnt((r) => r.grade === "Stale")}; no date published ${cnt((r) => r.grade === "Unknown")}. Cadastre updated weekly (data.qld.gov.au).`,
      action: "Results reflect the publishers' live data at the time of the lookup. Print the lookup date and each source's 'last updated' on the site plan. Re-run this register monthly and after each planning-scheme amendment." },
    { aspect: "Sources are genuine", verdict: "Yes",
      evidence: `Publisher verified for ${cnt((r) => r.strength !== "Weak")} of ${rows.length} layer uses (strong ${cnt((r) => r.strength === "Strong")}, medium ${cnt((r) => r.strength === "Medium")}); weak ${cnt((r) => r.strength === "Weak")}.`,
      action: "Every source is the council's, the utility's or the State's own published service (or Before You Dig Australia for power lines)." },
    { aspect: "Lot boundaries (positional accuracy)", verdict: "Not survey grade",
      evidence: "State cadastre accuracy varies by lot: ±0.1 m to ±1.5 m on the test lots. Council map lines are typically 1–3 m off the State lot outline (datum and cadastre version).",
      action: "The app shows each lot's boundary accuracy and warns above ±0.5 m. A site plan for approval must take boundaries and dimensions from the registered survey plan (or an identification survey); the map data is for locating constraints, not for measuring setbacks to the centimetre." },
    { aspect: "Planning maps match the scheme in force", verdict: "Mostly",
      evidence: `${cnt((r) => String(r.scheme).startsWith("OK"))} OK; ${cnt((r) => r.flag === "Scheme version: checked")} older or named for an earlier version but checked by hand (the amendments since did not change those maps); ${cnt((r) => /^(VERSION|Data older)/.test(String(r.scheme)) && r.flag !== "Scheme version: checked")} still to confirm.`,
      action: "Moreton Bay and Gold Coast: the amendments in force since their map data (an LGIP amendment; minor, administrative and LGIP amendments) do not redraw zones or overlays. Logan: zones and precincts now come from the council's own v9.2 layers. Re-check after each scheme amendment." },
    { aspect: "Services (pipes, power)", verdict: "Indicative only",
      evidence: "Utility and power data are positioned approximately and rarely give depth; publishers state no licence for several.",
      action: "Show them as 'on or near the lot', never as surveyed positions. A Before You Dig Australia enquiry is required before any excavation (pools, slabs)." },
    { aspect: "Availability", verdict: "Good, one weak point",
      evidence: "All services answered in the test. (The State bushfire proxy became private and was replaced by council overlays; Ipswich bushfire is flagged as not checked automatically.) The State server, which every lookup needs, failed 1 of 30 and 2 of 20 simultaneous queries in two tests; Logan's contractor server is slow (95th percentile about 8 s).",
      action: "In place: retries, clear 503 messages, results degrade instead of failing, a health check (GET /api/health) and an auto-restarting server. Recommended for production: a local copy of the cadastre and the heavy council layers (refreshed when their 'last edited' date changes), so lookups do not depend on every service being up." },
    { aspect: "Rate limits", verdict: "Within limits",
      evidence: "ArcGIS Online publishers have per-minute budgets for their whole organisation (6,000 or 28,800 units/min; a query costs 2 units). A Brisbane lookup uses about 88 units on the server plus the map drawing in the browser. No throttling seen in testing.",
      action: "In place: at most 8 simultaneous requests per ArcGIS Online host and 4 per State or council server; 'Retry-After' honoured; 429 becomes a clear message. At scale (hundreds of lookups per minute), use local copies for the heaviest layers so councils' budgets are not exhausted for their own users." },
    { aspect: "Licences and terms", verdict: "OK, with conditions",
      evidence: "Councils and the State: CC BY (Redland: CC BY-SA). Utilities and BYDA: no licence stated. Map backgrounds: OpenStreetMap tile policy and Esri terms restrict commercial use.",
      action: "Attribute every source on the site plan. Confirm terms with Urban Utilities, Unitywater and BYDA. Replace the two map backgrounds with licensed ones before going live." },
    { aspect: "Security", verdict: "Good",
      evidence: "All data services use HTTPS (most with HSTS); queries are anonymous (no keys to leak); the server only proxies configured layers; inputs are validated.",
      action: "Keep the database password in poc/.env (not committed)." },
  ]);

  // ---- How to verify: the method, for repeating any check by hand
  sheet(wb, "How to verify", [
    { header: "Check", key: "check", width: 26 },
    { header: "What it proves", key: "proves", width: 50 },
    { header: "How this register does it (automatically)", key: "auto", width: 60 },
    { header: "How to check it by hand", key: "manual", width: 60 },
    { header: "Result columns", key: "cols", width: 30 },
  ], [
    { check: "1. The publisher is genuine", proves: "The data comes from the council, utility or agency named, not a copy or a third party.",
      auto: "Resolves the ArcGIS Online organisation that owns the service (from the id in its URL) to its public name; otherwise the owner of the service's ArcGIS item; otherwise the web domain (.gov.au). Strong = named organisation or government domain; Medium = item owner only; Weak = neither.",
      manual: "Open the 'ArcGIS item page' link: the owner and organisation are shown at the top. Or find the same dataset on the publisher's open-data portal (column 'Publisher open-data portal') and compare the service URL.",
      cols: "Publisher verified by; Verification strength" },
    { check: "2. The service is live and unchanged", proves: "The app's lookup still works: the service answers, the fields it reads still exist, and its filter still selects data.",
      auto: "Requests the layer description (timed), compares its field list with the fields the app reads, and counts the features matching the app's filter.",
      manual: "Open 'Layer metadata (JSON)': check the fields listed. Open the 'API endpoint' with /query?where=<filter>&returnCountOnly=true&f=json.",
      cols: "Access check; Answered in (ms); Fields the app reads are present; Filter works on live data; Features in layer" },
    { check: "3. How up to date the data is", proves: "When the data last changed, and how often the publisher updates it.",
      auto: "Takes the layer's own 'data last edited' date; else the ArcGIS item's last modified date; else the newest maintenance date in the records. Quotes any update frequency the publisher states. Grades: Current (≤ 1 year, or stated nightly/daily/weekly/monthly), Ageing (1–2 years), Stale (> 2 years), Old, checked (> 2 years but checked by hand: no newer version exists), Unknown (no date exposed).",
      manual: "In 'Layer metadata (JSON)' look for editingInfo.dataLastEditDate (milliseconds since 1970). On the ArcGIS item page see 'Updated'. On the publisher's portal read the dataset's update frequency.",
      cols: "Last updated; Last updated — basis; Days since last update; Update frequency; Currency grade; Currency reasoning" },
    { check: "4. Planning maps match the scheme in force", proves: "Zoning and overlay maps are for the planning-scheme version that is legally in force (rules come from that version).",
      auto: "Compares the map data date with the commencement of the scheme version in force (from the rules database), and any version number in the service name (e.g. 'Version 13') with the version in force.",
      manual: "Open the council's planning-scheme website (Councils sheet), note the current version and its commencement, and compare with the service name and its last-edited date. Spot-check one property on the council's own scheme map.",
      cols: "Matches the planning scheme in force?" },
    { check: "5. Positions are right", proves: "Lines and areas are where they are on the ground.",
      auto: "Records each layer's stored coordinate system and datum. (Positional agreement is checked by comparing against the State cadastre on test properties; council lines are typically 1–3 m off the State lot outline because of datum and cadastre-version differences.)",
      manual: "Open the property on the publisher's own map viewer ('Map viewer' link in the app's Sources table) and compare with the aerial image.",
      cols: "Coordinate system (stored); Datum" },
    { check: "6. Re-check regularly", proves: "Sources keep working and stay current.",
      auto: "Run 'npm run data-register' (this workbook) monthly and after each planning-scheme amendment; 'npm run check-services' checks the zoning and overlay layers.",
      manual: "Review the Issues sheet; record decisions in the Change log.", cols: "Checked at" },
  ]);

  // ---- Councils
  const zc = zoning.loadConfig();
  const db = new Db();
  let schemes: any[] = [], docs: any[] = [];
  try {
    schemes = await db.q(`SELECT coalesce(json_agg(x), '[]') FROM (
      SELECT i.lg_id, i.title, v.version_label, v.effective_from, v.source_url FROM regs.instruments i
      JOIN regs.instrument_versions v USING (instrument_id) WHERE i.kind = 'PLANNING_SCHEME' AND v.status = 'ACTIVE') x`);
    docs = await db.q(`SELECT coalesce(json_agg(x ORDER BY x.kind, x.lg_id NULLS FIRST, x.title), '[]') FROM (
      SELECT i.instrument_id, i.kind, i.force, i.title, i.citation, i.lg_id, a.name AS authority, a.authority_type,
             v.instrument_version_id, v.version_label, v.published_date, v.effective_from, v.effective_to, v.status, v.source_url,
             v.local_file, v.file_sha256, v.retrieved_at, v.verified_at, v.notes,
             (SELECT count(*) FROM regs.provisions p WHERE p.instrument_version_id = v.instrument_version_id) AS provisions,
             (SELECT count(*) FROM regs.rule_versions r WHERE r.instrument_version_id = v.instrument_version_id AND r.status = 'ACTIVE') AS active_rules,
             (SELECT count(*) FROM regs.rule_versions r WHERE r.instrument_version_id = v.instrument_version_id AND r.status = 'DRAFT') AS draft_rules,
             (SELECT string_agg(DISTINCT coalesce(ap.lg_id, 'all') || ' ' || ap.regime || ' from ' || ap.effective_from
                     || coalesce(' to ' || ap.effective_to, '') || coalesce(' (' || ap.end_condition || ')', ''), '; ')
                FROM regs.instrument_applicability ap WHERE ap.instrument_version_id = v.instrument_version_id) AS applies
      FROM regs.instruments i JOIN regs.authorities a USING (authority_id)
      LEFT JOIN regs.instrument_versions v USING (instrument_id)) x`);
  } finally {
    await db.close();
  }
  const councilRows = Object.keys(COUNCIL_NAMES).filter((k) => !["STATE", "ALL"].includes(k)).map((lg) => {
    const c = zc[lg] ?? {};
    const mine = rows.filter((r) => r.council === COUNCIL_NAMES[lg]);
    const by = (lvl: string) => mine.filter((r) => r.level === lvl).length;
    const s = schemes.find((x) => x.lg_id === lg) ?? {};
    const cats = [...new Set(mine.filter((r) => r.group === "Site constraint").map((r) => r.category))].sort();
    return {
      council: COUNCIL_NAMES[lg], scheme: s.title ?? "", version: s.version_label ?? "", effective: s.effective_from ?? "",
      schemeUrl: s.source_url ?? "", viewer: c.scheme_viewer ?? "",
      zoning: c.status === "WORKING" ? "Automatic (council map service)" : "Manual — zone chosen by the user",
      overlays: (c.overlay_layers ?? []).length,
      councilLayers: by("Local council"), utility: by("Council-owned water utility"),
      cats: cats.join(", "), notes: strip(c.notes),
    };
  });
  sheet(wb, "Councils", [
    { header: "Council", key: "council", width: 15 },
    { header: "Planning scheme", key: "scheme", width: 34 },
    { header: "Version", key: "version", width: 22 },
    { header: "In force from", key: "effective", width: 12 },
    { header: "Scheme source", key: "schemeUrl", width: 40 },
    { header: "Scheme website", key: "viewer", width: 36 },
    { header: "Zoning lookup", key: "zoning", width: 26 },
    { header: "Overlay layers", key: "overlays", width: 9 },
    { header: "Council-published layers", key: "councilLayers", width: 10 },
    { header: "Water-utility layers", key: "utility", width: 10 },
    { header: "Site-constraint categories from the council / its utility", key: "cats", width: 50 },
    { header: "Notes", key: "notes", width: 80 },
  ], councilRows);

  // ---- Coverage matrix: category x council -> publishers
  const cats = [...new Set(rows.filter((r) => r.group === "Site constraint").map((r) => r.category))].sort();
  const councils = Object.keys(COUNCIL_NAMES).filter((k) => !["STATE", "ALL"].includes(k));
  const sc = site.loadConfig();
  const coverage = cats.map((cat) => {
    const row: any = { category: cat };
    for (const lg of councils) {
      const used = site.layersFor(lg).filter((l: any) => l.category === cat);
      row[lg] = [...new Set(used.map((l: any) => `${publisherOf(l.layer).publisher.replace(/ \(.*\)$/, "")} (${l.scope})`))].join("; ") || "—";
    }
    row.state = (sc.STATE ?? []).filter((l: any) => l.category === cat).map((l: any) => l.name + (l.always ? " [always]" : "")).join("; ");
    return row;
  });
  sheet(wb, "Coverage", [
    { header: "Category", key: "category", width: 16 },
    ...councils.map((lg) => ({ header: COUNCIL_NAMES[lg], key: lg, width: 30 })),
    { header: "State / national layers available", key: "state", width: 60 },
  ], coverage);

  // ---- Regulatory documents
  sheet(wb, "Regulatory documents", [
    { header: "Document", key: "title", width: 46 },
    { header: "Kind", key: "kind", width: 18 },
    { header: "Legal force", key: "force", width: 20 },
    { header: "Authority", key: "authority", width: 30 },
    { header: "Authority level", key: "authority_type", width: 16 },
    { header: "Council", key: "lg_id", width: 14 },
    { header: "Citation", key: "citation", width: 24 },
    { header: "Version", key: "version_label", width: 26 },
    { header: "Published", key: "published_date", width: 12 },
    { header: "In force from", key: "effective_from", width: 12 },
    { header: "In force to", key: "effective_to", width: 12 },
    { header: "Status", key: "status", width: 10 },
    { header: "Applies to (council, regime, dates)", key: "applies", width: 60 },
    { header: "Clauses stored", key: "provisions", width: 9 },
    { header: "Active rules", key: "active_rules", width: 9 },
    { header: "Draft rules", key: "draft_rules", width: 9 },
    { header: "Source URL", key: "source_url", width: 50 },
    { header: "Retrieved", key: "retrieved_at", width: 12 },
    { header: "Verified", key: "verified_at", width: 12 },
    { header: "Archived file", key: "local_file", width: 30 },
    { header: "SHA-256", key: "file_sha256", width: 20 },
    { header: "Notes", key: "notes", width: 70 },
  ], docs.map((d) => ({ ...d, retrieved_at: d.retrieved_at ? String(d.retrieved_at).slice(0, 10) : "", verified_at: d.verified_at ? String(d.verified_at).slice(0, 10) : "" })));

  // ---- Change log (source changes made after a register review)
  sheet(wb, "Change log", [
    { header: "Date", key: "date", width: 12 },
    { header: "Data", key: "data", width: 30 },
    { header: "Councils", key: "councils", width: 18 },
    { header: "Change", key: "change", width: 60 },
    { header: "Reason", key: "reason", width: 60 },
    { header: "Verification", key: "verified", width: 60 },
  ], CHANGELOG);

  // ---- Map display
  sheet(wb, "Map display", [
    { header: "Item", key: "item", width: 30 },
    { header: "Used for", key: "use", width: 44 },
    { header: "Provider", key: "provider", width: 30 },
    { header: "Provider level", key: "level", width: 22 },
    { header: "URL", key: "url", width: 70 },
    { header: "Licence / terms", key: "licence", width: 50 },
  ], [
    { item: "OpenStreetMap tiles", use: "'Streets' base map on the map page (display only)", provider: "OpenStreetMap Foundation", level: "International / commercial",
      url: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", licence: "ODbL; attribution '© OpenStreetMap contributors'. Tile usage policy limits heavy use: use a commercial tile provider in production." },
    { item: "Esri World Imagery", use: "'Aerial' base map on the map page (display only)", provider: "Esri", level: "International / commercial",
      url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer", licence: "Esri Master License Agreement / ArcGIS terms of use; attribution required." },
    { item: "Bushfire Prone Area (QFD, picture map)", use: "Reference layer on the map: switched on where bushfire is not checked automatically (Ipswich); available for every council (display only, not tested against the lot)",
      provider: "Queensland Fire Department (Public Safety Business Agency organisation)", level: "State",
      url: "https://tiles.arcgis.com/tiles/vkTwD8kHw2woKBqV/arcgis/rest/services/Bushfire_Prone_Areas/MapServer",
      licence: "Published publicly by the State (SEQ mapping updated July 2017); attribution: Queensland Fire Department." },
    { item: "Leaflet 1.9.4", use: "Map library", provider: "Leaflet (open source)", level: "International / commercial",
      url: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.min.js", licence: "BSD-2-Clause" },
    { item: "Esri Leaflet 3.0.12", use: "Draws the ArcGIS layers on the map", provider: "Esri (open source)", level: "International / commercial",
      url: "https://unpkg.com/esri-leaflet@3.0.12/dist/esri-leaflet.js", licence: "Apache-2.0" },
  ], "level");

  fs.mkdirSync(path.dirname(a.out), { recursive: true });
  try {
    await wb.xlsx.writeFile(a.out);
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code !== "EBUSY" && (e as NodeJS.ErrnoException).code !== "EPERM") throw e;
    // the workbook is open in Excel (Windows locks it): save beside it and say so
    const alt = a.out.replace(/\.xlsx$/, ` (${checked.toISOString().slice(0, 16).replace(/[T:]/g, "-")}).xlsx`);
    await wb.xlsx.writeFile(alt);
    console.log(`${a.out} is open in another program, so this register was saved as:`);
    a.out = alt;
  }
  const errors = rows.filter((r) => r.status.startsWith("ERROR")).length;
  console.log(`${a.out}\n${rows.length} layer uses (${urls.length} distinct endpoints), ${docs.length} regulatory document versions; ${errors} endpoint error(s)`);
  return 0;
}

main().then(exit, (e) => { console.error(e); exit(1); });
