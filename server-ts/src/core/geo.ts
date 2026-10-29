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

/** GET (or POST, for long geometries — long GET URLs fail silently on some servers) an ArcGIS REST call, with retries
 *  1 s and 2 s apart, so a short network blip (e.g. just after the PC wakes) does not fail the request. */
export async function getJson(url: string, params: Record<string, unknown>, timeoutS = 20, attempts = 3, post = false): Promise<any> {
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
