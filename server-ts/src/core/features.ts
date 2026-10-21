/**
 * Map features for the browser, clipped to the view: GET /api/features.
 *
 * Many council overlays are a handful of city-wide features (Brisbane's creek flood planning area: 11 features, 13 MB
 * for one street view), and the services cannot clip. So the server asks which features touch the view (ids only),
 * downloads each feature's full geometry once (cached), and returns only the part inside the view as GeoJSON.
 * Only layers named in poc/site_layers.json or poc/zoning_layers.json are served, so this is not an open proxy.
 */
import { Box, clipEsriGeometry } from "./clip.js";
import { getJson } from "./geo.js";
import { LookupError, ValueError } from "./py.js";
import * as site from "./site.js";
import * as zoning from "./zoning.js";

const TTL_MS = 60 * 60 * 1000;
const MAX_BOX_DEG = 0.1;             // about 10 km: the map draws constraint layers from zoom 15 (about 5 km wide)
const cache = new Map<string, { at: number; feature: any }>();   // "<layer>|<objectid>" -> ArcGIS feature (WGS 84)

/** Every layer URL the application is configured to use (allowlist). */
function allowedLayers(): Set<string> {
  const out = new Set<string>();
  for (const v of Object.values<any>(site.loadConfig())) if (Array.isArray(v)) for (const l of v) out.add(l.layer);
  for (const [k, c] of Object.entries<any>(zoning.loadConfig())) {
    if (k.startsWith("_")) continue;
    for (const u of [c.zone_layer, c.local_plan_layer, c.local_plan_precinct_layer, ...(c.precinct_layers ?? []),
      ...(c.overlay_layers ?? []).map((o: any) => o.layer)]) if (u) out.add(u);
  }
  return out;
}

/** The filter configured for this layer (the browser cannot choose its own). */
function configuredWhere(layer: string): string {
  for (const v of Object.values<any>(site.loadConfig())) if (Array.isArray(v)) for (const l of v) if (l.layer === layer && l.where) return l.where;
  return "1=1";
}

const R = 6378137;
const toMercator = (lon: number, lat: number) => [R * (lon * Math.PI) / 180, R * Math.log(Math.tan(Math.PI / 4 + (lat * Math.PI) / 360))];
const toLonLat = (x: number, y: number) => [((x / R) * 180) / Math.PI, ((2 * Math.atan(Math.exp(y / R)) - Math.PI / 2) * 180) / Math.PI];

/** Quantized ArcGIS geometry (integers; after the first point of each part, deltas) → lon/lat. */
export function dequantize(g: any, t: any): any {
  if (!g || !t) return g;
  const [sx, sy] = t.scale, [tx, ty] = t.translate, up = t.originPosition !== "lowerLeft";
  const part = (pts: number[][]) => {
    let X = 0, Y = 0;
    return pts.map(([dx, dy]) => {
      X += dx; Y += dy;
      return toLonLat(tx + X * sx, up ? ty - Y * sy : ty + Y * sy);
    });
  };
  if (g.rings) return { rings: g.rings.map(part) };
  if (g.paths) return { paths: g.paths.map(part) };
  if (typeof g.x === "number") { const [x, y] = toLonLat(tx + g.x * sx, up ? ty - g.y * sy : ty + g.y * sy); return { x, y }; }
  return g;
}

/** 7 decimals (about 1 cm) is plenty for drawing and keeps the response small. */
function roundCoords(g: any): any {
  if (!g) return g;
  const r = (v: any): any => (typeof v === "number" ? Math.round(v * 1e7) / 1e7 : v.map(r));
  return { ...g, coordinates: r(g.coordinates) };
}

export function parseBox(s: string | undefined): Box {
  const b = String(s ?? "").split(",").map(Number);
  if (b.length !== 4 || b.some((x) => !Number.isFinite(x)) || b[0] >= b[2] || b[1] >= b[3])
    throw new ValueError("bbox must be xmin,ymin,xmax,ymax in degrees");
  if (b[2] - b[0] > MAX_BOX_DEG || b[3] - b[1] > MAX_BOX_DEG) throw new ValueError("bbox too large: zoom in");
  return b as Box;
}

export async function featuresInBox(layer: string, box: Box): Promise<any> {
  if (!allowedLayers().has(layer)) throw new LookupError("layer is not one of the configured map layers");
  const where = configuredWhere(layer);
  const envelope = JSON.stringify({ xmin: box[0], ymin: box[1], xmax: box[2], ymax: box[3], spatialReference: { wkid: 4326 } });
  const ids = await getJson(`${layer}/query`, { where, geometry: envelope, geometryType: "esriGeometryEnvelope", inSR: 4326,
    spatialRel: "esriSpatialRelIntersects", returnIdsOnly: "true", f: "json" }, 30, 3, true);
  const oidField: string = ids.objectIdFieldName ?? "OBJECTID";
  const wanted: number[] = ids.objectIds ?? [];
  const now = Date.now();
  // the cache key includes the filter, so the same layer with another filter never shares entries
  const key = (id: number) => `${layer}|${where}|${id}`;
  const missing = wanted.filter((id) => { const c = cache.get(key(id)); return !c || now - c.at > TTL_MS; });
  // full geometry, once per feature: in Web Mercator (the services' native system, so no server-side reprojection of
  // millions of points) and quantized to 0.25 m integers (about 5x smaller; flood steps are 2.5 m, nothing visible is lost)
  const [mx0, my0] = toMercator(box[0], box[3]);
  const quant = JSON.stringify({ mode: "view", originPosition: "upperLeft", tolerance: 0.25,
    extent: { xmin: mx0, ymin: my0 - 1, xmax: mx0 + 1, ymax: my0, spatialReference: { wkid: 102100 } } });
  for (let i = 0; i < missing.length; i += 25) {
    const part = missing.slice(i, i + 25);
    const r = await getJson(`${layer}/query`, { objectIds: part.join(","), outFields: "*", returnGeometry: "true", outSR: 102100,
      quantizationParameters: quant, f: "json" }, 120, 3, true);
    for (const f of r.features ?? []) {
      f.geometry = dequantize(f.geometry, r.transform);
      cache.set(key(f.attributes[oidField]), { at: now, feature: f });
    }
  }
  const features = [];
  for (const id of wanted) {
    const f = cache.get(key(id))?.feature;
    const geometry = f ? roundCoords(clipEsriGeometry(f.geometry, box)) : null;
    if (geometry) features.push({ type: "Feature", id, properties: f.attributes, geometry });
  }
  return { type: "FeatureCollection", features };
}
