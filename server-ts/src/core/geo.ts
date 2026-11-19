/** Queensland Government spatial lookups: address -> point -> council, parcel, PDA. Port of poc/siteora_poc/geo.py. */
import { LookupError, pyRepr, pyRound, urlencode } from "./py.js";

/**
 * The one coordinate system used for every query, answer and drawn shape: GDA2020 geographic (EPSG:7844), lon/lat degrees.
 * The map services publish in mixed systems (Web Mercator, GDA94 and GDA2020 MGA zones, WGS 84). Asking for "4326" gives
 * the State's Web Mercator layers (cadastre, bushfire …) with no GDA94→GDA2020 shift, about 1.5 m from the layers that
 * are shifted (checked on the same lot, 16 Oct 2026: DCDB 4326 ≠ council parcel 4326, but DCDB 7844 = council parcel).
 * Asking every service for 7844 puts them on one datum, and it is also where the aerial imagery lines up.
 */
export const SR = 7844;

export const QSPATIAL ="https://spatial-gis.information.qld.gov.au/arcgis/rest/services";
export const GEOCODER = `${QSPATIAL}/Location/QldLocator/GeocodeServer/findAddressCandidates`;
export const CADASTRE = `${QSPATIAL}/PlanningCadastre/LandParcelPropertyFramework/MapServer`;
export const ADDRESS_LAYER = `${CADASTRE}/0`;
export const PARCEL_LAYER = `${CADASTRE}/4`;
export const LGA_LAYER = `${CADASTRE}/20`;
// The old PriorityDevelopmentAreas/MapServer/10 is decommissioned on 30 Nov 2026; StatePlanning/35 is the State replacement
// (same fields and areas; all 35 SEQ PDAs gave identical answers on 16 Oct 2026).
export const PDA_LAYER = `${QSPATIAL}/PlanningCadastre/StatePlanning/MapServer/35`;

export const LGA_TO_LG: Record<string, string> = {
  BRISBANE: "BRISBANE", "GOLD COAST": "GOLD_COAST", "MORETON BAY": "MORETON_BAY",
  "SUNSHINE COAST": "SUNSHINE_COAST", LOGAN: "LOGAN", IPSWICH: "IPSWICH", REDLAND: "REDLAND",
  BURKE: "BURKE", "CENTRAL HIGHLANDS": "CENTRAL_HIGHLANDS", LIVINGSTONE: "LIVINGSTONE",
  "MOUNT ISA": "MOUNT_ISA", ROCKHAMPTON: "ROCKHAMPTON", "SOUTH BURNETT": "SOUTH_BURNETT",
  TOOWOOMBA: "TOOWOOMBA", TOWNSVILLE: "TOWNSVILLE",
};

export type Rings = number[][][];
export interface Feature { attributes: Record<string, any>; geometry?: { rings?: Rings } }

/** A map service could not be reached at all (no internet, DNS failure, connection refused, timeout). The API answers
 *  503 with this message instead of a 500 and a stack trace. */
export class ServiceUnavailable extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ServiceUnavailable";
  }
}

const NETWORK_CODES: Record<string, string> = {
  ENOTFOUND: "its address could not be looked up (DNS)", EAI_AGAIN: "its address could not be looked up (DNS)",
  ECONNREFUSED: "the connection was refused", ECONNRESET: "the connection was reset", ETIMEDOUT: "the connection timed out",
  UND_ERR_CONNECT_TIMEOUT: "the connection timed out", UND_ERR_SOCKET: "the connection dropped",
};

function networkFailure(e: any, url: string): ServiceUnavailable | null {
  const code = e?.cause?.code ?? e?.code;
  const why = NETWORK_CODES[code] ?? (e?.name === "TimeoutError" ? "it did not answer in time" : null);
  return why ? new ServiceUnavailable(`Cannot reach the map service ${new URL(url).host}: ${why}. `
    + "Check the internet connection and try again.") : null;
}

// -----------------------------------------------------------------------------------------------------------------
// Response cache. Everything queried here — zoning/overlay/precinct boundaries, cadastre, geocoded addresses — changes
// on a scheme amendment or subdivision (weeks to months apart), never within a session, so caching is safe and is the
// single highest-leverage way to reduce load on the shared, anonymous, per-organisation rate limits these public
// services enforce: a repeat lookup of the same query costs that shared budget nothing once it is cached, regardless
// of who else is using it that hour. In-memory only for now, keyed on the exact (url, params, post) triple, so it is
// correct-by-construction (a different outFields/returnGeometry/etc. is automatically a different key) — a
// Postgres-backed cache that survives a restart is the natural next step, not done here to ship this first. Clears on
// process restart, which already matches the supervisor's restart-on-crash design (core/supervise.ts).
// Request coalescing: the cache stores the in-flight PROMISE, not just the resolved value, so concurrent callers for
// the same not-yet-finished query (e.g. two users' requests both needing the same council's zoning layer at the same
// moment) share one real network call instead of each firing their own. A failed request is evicted immediately
// (never cached) so a transient failure is retried fresh next time, not "remembered" as permanent.
interface CacheEntry { promise: Promise<any>; expires: number }
const responseCache = new Map<string, CacheEntry>();
const CACHE_TTL_MS = Number(process.env.SITEORA_GEO_CACHE_TTL_MS ?? 7 * 24 * 60 * 60 * 1000);   // 7 days
const CACHE_MAX_ENTRIES = 20000;   // oldest (by insertion order) evicted first past this
const CACHE_DISABLED = process.env.SITEORA_NO_CACHE === "1";
let cacheHits = 0, cacheMisses = 0;

function cacheKey(url: string, params: Record<string, unknown>, post: boolean): string {
  const sorted = Object.keys(params).sort().map((k) => [k, params[k]]);   // stable regardless of key insertion order
  return `${post ? "POST" : "GET"} ${url}?${JSON.stringify(sorted)}`;
}

/** Hits/misses since process start, and the current entry count — see GET /api/admin/cache-stats. */
export function geoCacheStats() {
  const total = cacheHits + cacheMisses;
  return { entries: responseCache.size, hits: cacheHits, misses: cacheMisses,
    hit_rate_pct: total ? pyRound((cacheHits / total) * 100, 1) : null, disabled: CACHE_DISABLED, ttl_ms: CACHE_TTL_MS };
}

/** GET (or POST, for long geometries — long GET URLs fail silently on some servers) an ArcGIS REST call, with retries
 *  1 s and 2 s apart, so a short network blip (e.g. just after the PC wakes) does not fail the request. Cached — see
 *  the block comment above. */
export async function getJson(url: string, params: Record<string, unknown>, timeoutS = 20, attempts = 3, post = false): Promise<any> {
  if (!CACHE_DISABLED) {
    const key = cacheKey(url, params, post);
    const hit = responseCache.get(key);
    if (hit && hit.expires > Date.now()) { cacheHits++; return hit.promise; }
    if (hit) responseCache.delete(key);   // expired
    cacheMisses++;
    const promise = fetchJsonUncached(url, params, timeoutS, attempts, post);
    if (responseCache.size >= CACHE_MAX_ENTRIES) {
      const oldest = responseCache.keys().next().value;
      if (oldest !== undefined) responseCache.delete(oldest);
    }
    responseCache.set(key, { promise, expires: Date.now() + CACHE_TTL_MS });
    promise.catch(() => responseCache.delete(key));   // never remember a failure
    return promise;
  }
  return fetchJsonUncached(url, params, timeoutS, attempts, post);
}

async function fetchJsonUncached(url: string, params: Record<string, unknown>, timeoutS: number, attempts: number, post: boolean): Promise<any> {
  const body = urlencode(params);
  const host = new URL(url).host;
  let data: any;
  for (let i = 0; i < attempts; i++) {
    let wait = 1000 * 2 ** i;
    try {
      const res = await withHostSlot(host, () => fetch(post ? url : `${url}?${body}`, {
        method: post ? "POST" : "GET",
        headers: { "User-Agent": "siteora-poc/0.1", ...(post ? { "Content-Type": "application/x-www-form-urlencoded" } : {}) },
        body: post ? body : undefined,
        signal: AbortSignal.timeout(timeoutS * 1000),
      }).then(async (r) => ({ r, text: await r.text() })));
      if (res.r.status === 429) {
        // rate limited (ArcGIS Online: the publisher's per-minute request budget is used up): wait as asked, then retry
        wait = retryAfterMs(res.r.headers.get("retry-after"), wait);
        throw new RateLimited(`The map service ${host} is limiting requests (HTTP 429). Try again in a minute.`);
      }
      if (!res.r.ok) throw new HttpError(`HTTP Error ${res.r.status}: ${res.r.statusText}`);
      data = JSON.parse(res.text);
      // ArcGIS reports its own failures inside a normal response; a server-side one (code 5xx, e.g. "Error performing
      // query operation" when the service is overloaded) is temporary, so it is retried like a network failure
      const code = Number(data?.error?.code);
      if (code === 429) throw new RateLimited(`The map service ${host} is limiting requests (${data.error.message ?? 429}). Try again in a minute.`);
      if (code >= 500) throw new ServiceUnavailable(`The map service ${host} returned an error `
        + `(${data.error.message ?? code}). Try again shortly.`);
      break;
    } catch (e) {
      if (e instanceof SyntaxError) throw e;              // not JSON: not a transient failure
      if (i === attempts - 1) {
        if (e instanceof ServiceUnavailable) throw e;
        if (e instanceof HttpError && /^HTTP Error 5\d\d/.test(e.message))
          throw new ServiceUnavailable(`The map service ${host} is not working (${e.message}). Try again shortly.`);
        throw networkFailure(e, url) ?? e;
      }
      await new Promise((r) => setTimeout(r, wait));
    }
  }
  if (data && typeof data === "object" && "error" in data) throw new Error(`${url}: ${pyRepr(data.error)}`);
  return data;
}

class HttpError extends Error {}

/** Rate limited by the publisher: a ServiceUnavailable (503 with a clear message) once retries are used up. */
class RateLimited extends ServiceUnavailable {}

function retryAfterMs(header: string | null, fallback: number): number {
  const s = Number(header);
  if (Number.isFinite(s) && s >= 0) return Math.min(s * 1000, 15000);
  const t = header ? Date.parse(header) - Date.now() : NaN;
  return Number.isFinite(t) && t > 0 ? Math.min(t, 15000) : Math.max(fallback, 5000);
}

/** How many requests may be in flight to one host at once, across all users of this server. Being a polite client
 *  matters: the State server failed 1 in 30 simultaneous queries in testing, and ArcGIS Online throttles a publisher's
 *  whole organisation (all its users) once its per-minute request budget is used. */
const HOST_LIMITS: [RegExp, number][] = [
  [/(^|\.)arcgis\.com$/, 8],                 // ArcGIS Online: fast, but budgets are shared by everyone using that council's data
  [/wspdigital\.com$/, 3],                   // Logan's contractor-hosted server: slow under load
  [/./, 4],                                  // State and council servers (spatial-gis.information.qld.gov.au etc.)
];
const inFlight = new Map<string, number>();
const queues = new Map<string, (() => void)[]>();

async function withHostSlot<T>(host: string, fn: () => Promise<T>): Promise<T> {
  const limit = HOST_LIMITS.find(([re]) => re.test(host))![1];
  if ((inFlight.get(host) ?? 0) >= limit)
    await new Promise<void>((resolve) => { (queues.get(host) ?? queues.set(host, []).get(host)!).push(resolve); });
  inFlight.set(host, (inFlight.get(host) ?? 0) + 1);
  try {
    return await fn();
  } finally {
    inFlight.set(host, inFlight.get(host)! - 1);
    queues.get(host)?.shift()?.();
  }
}

export async function pointQuery(layer: string, lon: number, lat: number, outFields = "*", geometry = false,
                                 where = "1=1", distanceM?: number): Promise<Feature[]> {
  const params: Record<string, unknown> = { geometry: `${lon},${lat}`, geometryType: "esriGeometryPoint", inSR: SR,
    spatialRel: "esriSpatialRelIntersects", outFields, where, returnGeometry: String(geometry), outSR: SR, f: "json" };
  if (distanceM) Object.assign(params, { distance: distanceM, units: "esriSRUnit_Meter" });
  return (await getJson(`${layer}/query`, params)).features;
}

/** Same job as pointQuery, for a GeoServer WFS endpoint (GeoJSON) instead of an ArcGIS REST FeatureServer -- e.g. a
 *  dataset published on data.gov.au/CKAN rather than the council's own GIS. A lon/lat bounding box (CQL BBOX, in
 *  degrees) stands in for ArcGIS's point+distance search; GeoJSON properties are remapped to `attributes` so
 *  callers (streetHierarchyType) don't need to know which kind of source they got. */
async function wfsPointQuery(layer: string, typeName: string, lon: number, lat: number, distanceM: number): Promise<Feature[]> {
  const dLat = distanceM / 111320, dLon = distanceM / (111320 * Math.cos(lat * Math.PI / 180));
  // WFS 2.0.0's CQL BBOX wants EPSG:4326's own (lat, lon) axis order here, confirmed live (19 Nov 2026) against
  // data.gov.au's GeoServer -- (lon, lat), the GeoJSON/ArcGIS convention used everywhere else, silently matches 0
  // features instead of erroring.
  const bbox = [lat - dLat, lon - dLon, lat + dLat, lon + dLon].join(",");
  const data = await getJson(layer, { service: "WFS", version: "2.0.0", request: "GetFeature", typeName,
    outputFormat: "json", cql_filter: `BBOX(the_geom,${bbox})` });
  return (data.features ?? []).map((f: any) => ({ attributes: f.properties ?? {} }));
}

/** Features that intersect the lot (or lie within distanceM). excludeTouching: drop polygons that only share the boundary. */
export async function lotQuery(layer: string, rings: Rings, outFields = "*", distanceM?: number | null, where = "1=1",
                               excludeTouching = false): Promise<Feature[]> {
  const params: Record<string, unknown> = {
    geometry: JSON.stringify({ rings, spatialReference: { wkid: SR } }), geometryType: "esriGeometryPolygon", inSR: SR,
    spatialRel: "esriSpatialRelIntersects", outFields, where, returnGeometry: "false", f: "json" };
  if (distanceM) Object.assign(params, { distance: distanceM, units: "esriSRUnit_Meter" });
  const data = await getJson(`${layer}/query`, params, 30, 3, true);
  let feats: Feature[] = data.features;
  if (excludeTouching && feats.length && !distanceM) {
    const oid: string | undefined = data.objectIdFieldName
      ?? Object.keys(feats[0].attributes).find((k) => ["objectid", "fid", "oid"].includes(k.toLowerCase()));
    if (oid) {
      const touch: Feature[] = (await getJson(`${layer}/query`, { ...params, spatialRel: "esriSpatialRelTouches", outFields: oid }, 30, 3, true)).features;
      const onlyTouch = new Set(touch.map((t) => t.attributes[oid]));
      feats = feats.filter((f) => !onlyTouch.has(f.attributes[oid]));
    }
  }
  return feats;
}

/** Neighbouring parcels that share a boundary with the lot (Touches, not Intersects - excludes the lot itself and
 *  anything that only overlaps). Returns each neighbour's centroid, for testing against another layer (e.g. which
 *  precinct the neighbour is in) - never the neighbour's own attributes, since "shares a boundary" is all that
 *  Touches establishes. */
export async function touchingNeighbours(layer: string, rings: Rings, where = "1=1"): Promise<[number, number][]> {
  const params: Record<string, unknown> = {
    geometry: JSON.stringify({ rings, spatialReference: { wkid: SR } }), geometryType: "esriGeometryPolygon", inSR: SR,
    spatialRel: "esriSpatialRelTouches", outFields: "", where, returnGeometry: "true", outSR: SR, f: "json" };
  const data = await getJson(`${layer}/query`, params, 30, 3, true);
  const feats: Feature[] = data.features ?? [];
  return feats.map((f) => {
    const ring = f.geometry?.rings?.[0] ?? [];
    const n = ring.length || 1;
    return [ring.reduce((s: number, p: number[]) => s + p[0], 0) / n, ring.reduce((s: number, p: number[]) => s + p[1], 0) / n];
  });
}

export interface Geocode { address: string; lon: number; lat: number; score: number; unmatched_input: string | null; source: string }

/** Exact-enough match only (score >= 95, or >= 90 with nothing unmatched); otherwise list the candidates. */
export async function geocode(address: string): Promise<Geocode> {
  const data = await getJson(GEOCODER, { SingleLine: address, outSR: SR, maxLocations: 5, outFields: "Match_addr,ExInfo,City,Subregion", f: "json" });
  const cands: any[] = data.candidates ?? [];
  // the geocoder never matches postcodes, so a postcode alone in ExInfo is not a mismatch
  const unmatched = (c: any): string => String(c.attributes.ExInfo ?? "").split("|").map((t: string) => t.trim())
    .filter((t: string) => t && !/^\d{4}$/.test(t)).join(" | ");
  const good = cands.filter((c) => c.score >= 95 || (c.score >= 90 && !unmatched(c)));
  if (!good.length) {
    const listed = cands.slice(0, 5).map((c) => `${c.address} (${pyRound(c.score, 0).toFixed(0)}%)`).join("; ") || "none";
    throw new LookupError(`No exact match for ${pyRepr(address)}. Closest candidates: ${listed}. `
      + "Check the street type, suburb and postcode, or enter one of the candidates.");
  }
  const best = good[0];
  return { address: best.address, lon: best.location.x, lat: best.location.y, score: best.score,
    unmatched_input: unmatched(best) || null, source: "QldLocator geocoder (Queensland Government)" };
}

export async function councilAt(lon: number, lat: number): Promise<{ lga_name: string; lg_id: string | null }> {
  const feats = await pointQuery(LGA_LAYER, lon, lat, "lga,abbrev_name");
  if (!feats.length) throw new LookupError("Point is not inside a Queensland local government area");
  const a = feats[0].attributes;
  return { lga_name: a.lga, lg_id: LGA_TO_LG[a.abbrev_name] ?? null };
}

/** The land parcel at the point; falls back to the address point's lot/plan (geocoded points can land on the road). */
export async function parcelAt(lon: number, lat: number): Promise<Record<string, any> & { rings: Rings }> {
  let feats = (await pointQuery(PARCEL_LAYER, lon, lat, "lot,plan,lotplan,lot_area,parcel_typ,tenure,acc_code,surv_ind", true)).filter((f) => f.attributes.lotplan);
  if (!feats.length) {
    const addrs = await pointQuery(ADDRESS_LAYER, lon, lat, "lotplan,address", false, "1=1", 25);
    const lotplans = addrs.map((a) => a.attributes.lotplan).filter(Boolean);
    if (lotplans.length)
      feats = (await getJson(`${PARCEL_LAYER}/query`, { where: `lotplan = '${lotplans[0]}'`, outFields: "lot,plan,lotplan,lot_area,parcel_typ,tenure,acc_code,surv_ind",
        returnGeometry: "true", outSR: SR, f: "json" })).features;
  }
  if (!feats.length) throw new LookupError("No land parcel found at this address");
  const f = feats[0];
  return { ...f.attributes, rings: f.geometry!.rings! };
}

/** The street name (incl. type, e.g. "Califer Street"; no house number or suburb) parsed out of a geocoder match
 *  like "8 Alice Street, Mornington, Queensland" -- strips the part before the first comma down to its own
 *  leading house-number/unit token (the only one guaranteed to contain a digit), e.g. "8", "28B", "U2/8". Null if
 *  nothing is left to strip to (the address line was just a bare street name, e.g. a vacant-lot match). */
export function streetNameFromAddress(address: string): string | null {
  const line = address.split(",")[0]?.trim() ?? "";
  const stripped = line.replace(/^\S*\d\S*\s+/, "").trim();
  return stripped && stripped !== line ? stripped : null;
}

/** The street name at a point, from the state Addresses layer -- only a fallback for when no geocoded address
 *  text is available (a bare lon/lat query); near a corner, the NEAREST address point within the buffer can
 *  belong to the cross street, not the one actually being asked about, so prefer streetNameFromAddress()
 *  whenever an address string was given. Null if no address point is close enough to read one from. */
export async function streetNameAt(lon: number, lat: number): Promise<string | null> {
  const feats = await pointQuery(ADDRESS_LAYER, lon, lat, "street_name,street_type", false, "1=1", 40);
  if (!feats.length) return null;
  const a = feats[0].attributes;
  const name = [a.street_name, a.street_type].filter(Boolean).join(" ").trim();
  return name || null;
}

export type StreetType = "COLLECTOR" | "ACCESS_STREET";

const normStreet = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();

/** One council's public road-classification layer, enough to answer QDC MP 1.1 Table A1's "access place/access
 *  street" vs "collector street" question (everything above collector -- arterial etc. -- is outside Table A1's
 *  coverage either way, and stays unresolved). nameField null means the layer carries no usable per-segment road
 *  name (so matching is spatial-only, a tighter distanceM, and a lower-confidence result -- noted per source). */
export interface StreetHierarchySource {
  layer: string;
  nameField: string | null;
  classField: string;
  distanceM: number;
  /** true: this layer only maps collector-and-above roads, so no name match => an ordinary access place/access
   *  street by elimination. false: a full road network layer, so no match stays genuinely unresolved. */
  sparseCollectorOnly: boolean;
  classify: (raw: string) => StreetType | null;
  /** Appended to the fact's displayed source string when a council caveats the layer itself (not just the spatial
   *  match), so the caveat travels with the result the user actually sees instead of staying a code comment. */
  confidenceNote?: string;
  /** Set when `layer` is a GeoServer WFS endpoint (GeoJSON), not an ArcGIS REST FeatureServer -- e.g. a dataset
   *  published via data.gov.au/CKAN rather than the council's own GIS. The value is the WFS typeName. */
  wfsTypeName?: string;
}

export const STREET_HIERARCHY_SOURCES: Record<string, StreetHierarchySource> = {
  // Only lists collector-and-above roads (Local/District Collector, Sub-Arterial, Arterial, Motorway) -- no match
  // at all (the common case) => an ordinary access place/access street by elimination (Table A1 gives those two
  // the same figures anyway). Matched within 2km (not a tight frontage buffer) because the same street name can
  // recur elsewhere in this LGA (e.g. two separate 'Lindsay Road's, ~16km apart) -- 2km safely disambiguates
  // those while still catching the matching segment regardless of where along a long collector the lot sits.
  MORETON_BAY: {
    layer: "https://services-ap1.arcgis.com/152ojN3Ts9H3cdtl/ArcGIS/rest/services/OM_Road_Hierarchy_WebMercator_OpenData/FeatureServer/0",
    nameField: "ROAD_NAME", classField: "Hierarchy", distanceM: 2000, sparseCollectorOnly: true,
    classify: (h) => (h === "Local Collector" || h === "District Collector" ? "COLLECTOR" : null),
  },
  // Full road network, RoadClass values are near-verbatim QDC terms. FEAT_NAME is null on some polygon segments
  // (gaps between named sections), and a deep or corner lot's address point can sit well over 100m from its own
  // street's indexed line -- distanceM is generous (200m) because the name match (not the buffer) is what keeps
  // this safe: the same street name recurring twice within 200m of one address is effectively never the case.
  ROCKHAMPTON: {
    layer: "https://services-ap1.arcgis.com/hx2J5p82likyGt5G/arcgis/rest/services/Road_Heirarchy/FeatureServer/0",
    nameField: "FEAT_NAME", classField: "RoadClass", distanceM: 200, sparseCollectorOnly: false,
    classify: (c) => (/Access (Place|Street)$|^(Rural|Industrial) Access$/i.test(c) ? "ACCESS_STREET" : /Collector/i.test(c) ? "COLLECTOR" : null),
  },
  // Full road network, Hierarchy values are literally 'Access' / 'Collector' / 'Sub-Arterial' / 'Distributor' / etc.
  MOUNT_ISA: {
    layer: "https://services8.arcgis.com/g9mppFwSsmIw9E0Z/arcgis/rest/services/Road_Heirarchy/FeatureServer/0",
    nameField: "Name", classField: "Hierarchy", distanceM: 200, sparseCollectorOnly: false,
    classify: (h) => (h === "Access" ? "ACCESS_STREET" : h === "Collector" ? "COLLECTOR" : null),
  },
  // Brisbane City Plan's own Road hierarchy overlay. DESCRIPTION is "ROAD NAME, SUBURB" -- the name is matched as a
  // prefix, not full equality. 200m buffer for the same reason as Rockhampton/Mount Isa above.
  //
  // NOTE (found 6 Nov 2026): the service literally named "Road_hierarchy" on this same host -- the one previously
  // configured here -- is NOT the city-wide overlay despite the name: it holds only 327 segments, all of them in
  // Albany Creek / Aspley / Bald Hills / Bridgeman Downs / Carseldine / McDowall (checked live: every DESCRIPTION
  // value's suburb falls in that list, a tiny pocket of outer-north Brisbane). Every other suburb silently got
  // zero features back and stayed "unresolved", which is how this was reported broken for Ashgrove. The actual
  // city-wide layer, confirmed live (41,753 segments, every suburb checked, same field schema), is
  // 'Roads_hierarchy_overlay_Road_hierarchy' -- swapped in below.
  BRISBANE: {
    layer: "https://services2.arcgis.com/dEKgZETqwmDAh1rP/arcgis/rest/services/Roads_hierarchy_overlay_Road_hierarchy/FeatureServer/0",
    nameField: "DESCRIPTION", classField: "ROUTE_TYPE", distanceM: 200, sparseCollectorOnly: false,
    classify: (r) => (r === "Neighbourhood / local" ? "ACCESS_STREET" : r === "District" ? "COLLECTOR" : null),
    // District -> COLLECTOR is the pre-existing mapping, carried over unchanged. Researched 6 Nov 2026: no
    // authoritative source found either confirming or refuting it -- City Plan 2014's own Road hierarchy overlay
    // code (Part 8 s8.2.18) could not be retrieved (City Plan Online requires a session), and QDC's "collector
    // street" definition is purely functional (Queensland Streets traffic-performance criteria), not tied to any
    // council's own tier names. "Suburban" (2,584 segments, below District in Brisbane's 5-tier hierarchy:
    // Neighbourhood/local, Suburban, District, Arterial, Motorway) is left unmapped (-> null -> manual review)
    // rather than guessed at, since getting District/Suburban backwards would silently change the computed
    // front-setback figure. Separately: an archived (2022) copy of this overlay's own map page states "This map
    // is notional only and should not be used for interpreting City Plan provisions relating to specific sites" --
    // a caveat from Council itself on using this layer for site-specific determinations at all, so its result is
    // surfaced as DERIVED (confirm before relying on it), same as every other auto-resolved fact in this project.
    confidenceNote: "Council's own map notes this layer is notional only and should not be used for interpreting "
      + "City Plan provisions relating to specific sites -- confirm against the registered road hierarchy overlay before relying on this.",
  },
  // This layer (Sunshine Coast's own "2031 Functional Transport Hierarchy", Fig 9.4.8A) carries no per-segment road
  // name at all -- LOWER CONFIDENCE: matched purely on spatial proximity, not verified against the lot's actual
  // frontage street name. 60m (not a tight frontage buffer) because the mapped line can sit further than that
  // from a deep lot's address point; a wrong-road pickup is still unlikely at this range outside dense intersections.
  SUNSHINE_COAST: {
    layer: "https://geoimage.scc.qld.gov.au/arcgis/rest/services/PlanningCadastre/PlanningScheme_SunshineCoast_Transport_SCC/MapServer/0",
    nameField: null, classField: "LABEL", distanceM: 60, sparseCollectorOnly: false,
    classify: (l) => (/Collector Street/i.test(l) ? "COLLECTOR" : /^Local/i.test(l) ? "ACCESS_STREET" : null),
  },
  // Road_Segment_view carries no reliable per-segment road name either (STREET_START/STREET_END are placeholder
  // text, not real data) -- LOWER CONFIDENCE, spatial-only, same reasoning as Sunshine Coast above. It is a road
  // *surface* polygon layer broken into many small segments, several of them with a null LDG_HIERARCHY (data
  // gaps) -- 60m and taking the first segment that actually classifies (not just the nearest) works around that.
  GOLD_COAST: {
    layer: "https://services-ap1.arcgis.com/lnVW0dLI3fvST2hd/arcgis/rest/services/Road_Segment_view/FeatureServer/0",
    nameField: null, classField: "LDG_HIERARCHY", distanceM: 60, sparseCollectorOnly: false,
    classify: (h) => (/^ACCESS /i.test(h) ? "ACCESS_STREET" : /^COLLECTOR /i.test(h) ? "COLLECTOR" : null),
  },
  // Toowoomba Regional Council's own planning-scheme Road Hierarchy layer (not the separate TTM_Road_Category
  // layer, which is a traffic-management/clearway classification and does not map to QDC's land-use hierarchy at
  // all). HIERARCHY values are LOCAL/COLLECTOR/DISTRIBUTOR/SUB-ARTERIAL/REGIONAL ARTERIAL/HIGHWAY; has its own
  // ROAD_NAME field, so this is name-matched like Brisbane/Rockhampton/Mount Isa (high confidence).
  TOOWOOMBA: {
    layer: "https://maps.tr.qld.gov.au/arcgis/rest/services/External/External_PlanningScheme/MapServer/8",
    nameField: "ROAD_NAME", classField: "HIERARCHY", distanceM: 200, sparseCollectorOnly: false,
    classify: (h) => (h === "LOCAL" ? "ACCESS_STREET" : h === "COLLECTOR" ? "COLLECTOR" : null),
  },
  // Townsville's road centreline HIERARCHY is a numeric code (1=Freeway, 2=Highway, 3=Main Road, 4=Secondary Road,
  // 5=Trafficable Road -- read from the layer's own renderer legend, since the field metadata exposes no domain).
  // 5 ('Trafficable Road', the layer's own default) is treated as the ordinary access place/access street case,
  // and 4 ('Secondary Road') as the collector case -- a standard-shaped 5-tier hierarchy, but MEDIUM CONFIDENCE
  // since neither label uses QDC's own terms the way other councils' layers do. Has its own ROAD_NAME field.
  TOWNSVILLE: {
    layer: "https://services6.arcgis.com/3VCE6mezZtwKJeIR/arcgis/rest/services/TCC_Road_Centerlines_GDA2020/FeatureServer/0",
    nameField: "ROAD_NAME", classField: "HIERARCHY", distanceM: 200, sparseCollectorOnly: false,
    classify: (h) => (h === "5" ? "ACCESS_STREET" : h === "4" ? "COLLECTOR" : null),
  },
  // Logan's planning-scheme Road hierarchy layer (LoganHub) has no per-segment road name -- LOWER CONFIDENCE,
  // spatial-only, same reasoning as Sunshine Coast/Gold Coast above. Road_Type values are near-verbatim QDC terms.
  LOGAN: {
    layer: "https://arcgis.lcc.wspdigital.com/server/rest/services/LoganHub/Logan_Planning_Scheme_v9_2_TLPI_No_1_2024_20250527/MapServer/328",
    nameField: null, classField: "Road_Type", distanceM: 60, sparseCollectorOnly: false,
    classify: (t) => (/Access/i.test(t) ? "ACCESS_STREET" : /Collector/i.test(t) ? "COLLECTOR" : null),
  },
  // Not the council's own GIS (Ipswich City Plan's zoning/overlay service is token-gated -- see poc/zoning_layers.json)
  // but a separate, no-auth, council-owned dataset published on data.gov.au (a GeoServer WFS, not ArcGIS REST --
  // see wfsTypeName): "Ipswich Road Network", OWNER='Ipswich City Council', 13,737 segments covering the whole LGA.
  // Found 19 Nov 2026 -- supersedes the 3 Nov conclusion below that no public source exists; that check predates
  // this dataset's current data.gov.au listing (it moved platforms, breaking the old CKAN API path it was likely
  // checked through). ROAD_HIERA values, confirmed by sampling the full dataset: Access Place/Laneway, Access
  // Street, Industrial Access, Rural Access Way, Local, Rural Street -> access; Industrial/Major/Minor/Rural
  // Collector -> collector; everything Sub-Arterial and above (incl. Highway, Freeway/Motorway) and "To Be
  // Advised" is outside Table A1's coverage either way, same treatment as Brisbane's Arterial.
  IPSWICH: {
    layer: "https://data.gov.au/geoserver/ipswich-road-centre-lines/wfs", wfsTypeName: "ckan_c4fa7932_6485_4b05_98b5_5a1ea5db7dd2",
    nameField: "ROAD_NAME", classField: "ROAD_HIERA", distanceM: 200, sparseCollectorOnly: false,
    classify: (h) => (/^(Access Place\/Laneway|Access Street|Industrial Access|Rural Access Way|Local|Rural Street)$/i.test(h) ? "ACCESS_STREET"
      : /Collector/i.test(h) ? "COLLECTOR" : null),
  },
};

// Redland, Livingstone, Burke, Central Highlands, South Burnett: confirmed (3 Nov 2026, after a thorough pass of
// each council's own GIS and the state's own "Roads and tracks" dataset -- its 'class' field is too coarse,
// classifying both a known Brisbane collector and a known access street as "Local") to have no usable
// road-classification source of their own. The only fallback found, OpenStreetMap's Overpass API, explicitly
// states its public endpoint "is intended for browser-based and human-operated tools... for automated use, run a
// local Overpass API instance" -- confirmed live (3 Nov 2026) by querying it directly, so it is not used here.
// These 5 councils rely on the manual --street-type input instead (see cli.ts / buildFacts below). Ipswich was in
// this list too until 19 Nov 2026 (see STREET_HIERARCHY_SOURCES.IPSWICH above).

/** QDC MP 1.1 Table A1 needs the street's functional classification (access place/access street vs. collector
 *  street -- everything above that is outside the table's coverage and stays unresolved either way). Derives it
 *  from whichever council source is registered for lg_id, or null if none is (left for manual review, as today). */
export async function streetHierarchyType(lgId: string, streetName: string, lon: number, lat: number): Promise<StreetType | null> {
  const src = STREET_HIERARCHY_SOURCES[lgId];
  if (!src) return null;
  const feats = src.wfsTypeName
    ? await wfsPointQuery(src.layer, src.wfsTypeName, lon, lat, src.distanceM)
    : await pointQuery(src.layer, lon, lat, src.nameField ? `${src.nameField},${src.classField}` : src.classField, false, "1=1", src.distanceM);
  let hit: Feature | undefined;
  if (src.nameField) {
    const target = normStreet(streetName);
    if (!target) return null;
    hit = feats.find((f) => normStreet(String(f.attributes[src.nameField!] ?? "")).startsWith(target) || target.startsWith(normStreet(String(f.attributes[src.nameField!] ?? ""))));
  } else {
    // spatial-only sources (no road name to match on): several overlapping/adjacent segments can come back with
    // a null class value (data gaps) -- take the first one that actually classifies, not just the nearest.
    hit = feats.find((f) => src.classify(String(f.attributes[src.classField] ?? "")) !== null);
  }
  if (!hit) return src.sparseCollectorOnly ? "ACCESS_STREET" : null;
  return src.classify(String(hit.attributes[src.classField] ?? ""));
}

export const BCC_PARCEL_LAYER = "https://services2.arcgis.com/dEKgZETqwmDAh1rP/arcgis/rest/services/property_boundaries_parcel/FeatureServer/0";

/** Brisbane City Council's own copy of the lot outline (what the City Plan map draws). It sits up to a few metres from the State DCDB outline. */
export async function bccParcelRings(lotplan: string): Promise<Rings | null> {
  if (!/^[A-Za-z0-9]+$/.test(lotplan)) return null;
  const feats: Feature[] = (await getJson(`${BCC_PARCEL_LAYER}/query`, { where: `LOTPLAN = '${lotplan}' AND PARCEL_TYP_DESC = 'Lot'`,
    outFields: "LOTPLAN", returnGeometry: "true", outSR: SR, f: "json" })).features;
  return feats.length === 1 && feats[0].geometry?.rings ? feats[0].geometry.rings : null;
}

export async function pdaAt(lon: number, lat: number): Promise<Record<string, any> | null> {
  const feats = await pointQuery(PDA_LAYER, lon, lat, "pda_name,pda_status");
  return feats.length ? feats[0].attributes : null;
}

// ----------------------------------------------------------------------------- parcel geometry
type Pt = [number, number];

/** Lon/lat -> local metres (equirectangular about the first vertex; fine at lot scale). */
function project(rings: Rings): Pt[][] {
  const [lon0, lat0] = rings[0][0];
  const kx = 111320.0 * Math.cos((lat0 * Math.PI) / 180);
  const ky = 110540.0;
  return rings.map((ring) => ring.map(([x, y]) => [(x - lon0) * kx, (y - lat0) * ky] as Pt));
}

function area(ring: Pt[]): number {
  let s = 0;
  for (let i = 0; i < ring.length; i++) {
    const [x1, y1] = ring[i], [x2, y2] = ring[(i + 1) % ring.length];
    s += x1 * y2 - x2 * y1;
  }
  return Math.abs(s) / 2;
}

function hull(points: Pt[]): Pt[] {
  const seen = new Map<string, Pt>();
  for (const p of points) seen.set(`${p[0]},${p[1]}`, p);
  const pts = [...seen.values()].sort((a, b) => (a[0] - b[0]) || (a[1] - b[1]));
  if (pts.length < 3) return pts;
  const cross = (o: Pt, a: Pt, b: Pt) => (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
  const lower: Pt[] = [], upper: Pt[] = [];
  for (const p of pts) {
    while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], p) <= 0) lower.pop();
    lower.push(p);
  }
  for (const p of [...pts].reverse()) {
    while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], p) <= 0) upper.pop();
    upper.push(p);
  }
  return [...lower.slice(0, -1), ...upper.slice(0, -1)];
}

/** Lot width/depth (minimum-area bounding rectangle) and rectangularity. ESTIMATES. */
export function parcelMetrics(rings: Rings) {
  const proj = project(rings);
  const outer = proj.reduce((best, r) => (area(r) > area(best) ? r : best), proj[0]);
  const a = area(outer);
  const h = hull(outer);
  let best: [number, number, number] | null = null;
  for (let i = 0; i < h.length; i++) {
    const [x1, y1] = h[i], [x2, y2] = h[(i + 1) % h.length];
    const ang = Math.atan2(y2 - y1, x2 - x1);
    const c = Math.cos(-ang), s = Math.sin(-ang);
    const xs = h.map(([x, y]) => x * c - y * s), ys = h.map(([x, y]) => x * s + y * c);
    const w = Math.max(...xs) - Math.min(...xs), hh = Math.max(...ys) - Math.min(...ys);
    if (best === null || w * hh < best[0]) best = [w * hh, Math.min(w, hh), Math.max(w, hh)];
  }
  const [rectArea, width, depth] = best!;
  return { computed_area_m2: pyRound(a, 1), est_width_m: pyRound(width, 2), est_depth_m: pyRound(depth, 2),
    rectangularity: rectArea ? pyRound(a / rectArea, 3) : null };
}

/**
 * Battle-axe/rear lot shape SIGNAL (not a ground truth): a narrow access handle (<= 9 m, driveway-width)
 * running a real span of the lot's length, connecting to a much wider body set back behind it. Derived
 * purely from the parcel outline we already fetch for parcelMetrics() -- no road-reserve layer, so this
 * cannot know which end actually touches the street, only that the shape has the handle+body profile.
 * Used to PRE-FILL the user-facing is_battle_axe_lot input, which stays editable: a corner lot on a curve,
 * a trapezoidal lot, or a lot on a cul-de-sac bulb can also read as non-rectangular without being battle-axe,
 * so this is a starting guess, not an answer to trust unseen.
 */
export function battleAxeSignal(rings: Rings): { likely_battle_axe: boolean | null; handle_width_m: number | null; body_width_m: number | null } {
  const proj = project(rings);
  const outer = proj.reduce((best, r) => (area(r) > area(best) ? r : best), proj[0]);
  const h = hull(outer);
  if (h.length < 3) return { likely_battle_axe: null, handle_width_m: null, body_width_m: null };
  // Same rotating-calipers search as parcelMetrics, but this time keep the winning angle so the actual
  // (possibly concave) outline can be profiled along that axis, not just reduced to its bounding box.
  let bestAngle = 0, bestBoxArea = Infinity, longIsX = true;
  for (let i = 0; i < h.length; i++) {
    const [x1, y1] = h[i], [x2, y2] = h[(i + 1) % h.length];
    const ang = Math.atan2(y2 - y1, x2 - x1);
    const c = Math.cos(-ang), s = Math.sin(-ang);
    const xs = h.map(([x, y]) => x * c - y * s), ys = h.map(([x, y]) => x * s + y * c);
    const w = Math.max(...xs) - Math.min(...xs), d = Math.max(...ys) - Math.min(...ys);
    if (w * d < bestBoxArea) { bestBoxArea = w * d; bestAngle = ang; longIsX = w >= d; }
  }
  const c = Math.cos(-bestAngle), s = Math.sin(-bestAngle);
  let rotated = outer.map(([x, y]) => [x * c - y * s, x * s + y * c] as Pt);
  if (!longIsX) rotated = rotated.map(([x, y]) => [y, -x] as Pt);   // keep the lot's longer dimension along x
  const xsAll = rotated.map((p) => p[0]);
  const xMin = Math.min(...xsAll), length = Math.max(...xsAll) - xMin;
  if (length <= 0) return { likely_battle_axe: null, handle_width_m: null, body_width_m: null };

  const widthAt = (x: number): number => {
    const ys: number[] = [];
    for (let i = 0; i < rotated.length; i++) {
      const [x1, y1] = rotated[i], [x2, y2] = rotated[(i + 1) % rotated.length];
      if ((x1 <= x && x2 > x) || (x2 <= x && x1 > x)) ys.push(y1 + ((x - x1) / (x2 - x1)) * (y2 - y1));
    }
    return ys.length >= 2 ? Math.max(...ys) - Math.min(...ys) : 0;
  };

  const N = 30;
  const widths = Array.from({ length: N }, (_, i) => widthAt(xMin + (length * (i + 0.5)) / N));
  const endSpan = Math.max(3, Math.round(N * 0.3));
  const leftEnd = widths.slice(0, endSpan), rightEnd = widths.slice(-endSpan);
  const leftMin = Math.min(...leftEnd), rightMin = Math.min(...rightEnd);
  const bodyMax = Math.max(...widths);
  const [handleWidth, handleEnd] = leftMin <= rightMin ? [leftMin, leftEnd] : [rightMin, rightEnd];
  // A genuine handle stays narrow across a real span -- an hourglass-shaped lot can pinch to one narrow
  // sample and widen straight back out, which is not a battle-axe/rear lot.
  const narrowRun = handleEnd.filter((w) => w <= handleWidth * 1.4).length;
  const likely = handleWidth > 0 && handleWidth <= 9 && bodyMax >= handleWidth * 2.2 && narrowRun >= endSpan * 0.6;
  return { likely_battle_axe: likely, handle_width_m: pyRound(handleWidth, 1), body_width_m: pyRound(bodyMax, 1) };
}
