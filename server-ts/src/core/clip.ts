/**
 * Clip geometry to a rectangle, for drawing: council overlays are often one feature for the whole city (e.g. all of
 * Brisbane's "flood planning area 2"), so the map only needs the part inside the view.
 * Coordinates are [x, y] (lon, lat). Polygons: Sutherland–Hodgman per ring (rings stay closed; output rings may run
 * along the box edge, which is fine for filling). Lines: segments clipped with Liang–Barsky, split where they leave.
 */
export type Box = [number, number, number, number];   // xmin, ymin, xmax, ymax
type Pt = number[];

function clipEdge(pts: Pt[], inside: (p: Pt) => boolean, cross: (a: Pt, b: Pt) => Pt): Pt[] {
  const out: Pt[] = [];
  for (let i = 0; i < pts.length; i++) {
    const cur = pts[i], prev = pts[(i + pts.length - 1) % pts.length];
    const ci = inside(cur), pi = inside(prev);
    if (ci) {
      if (!pi) out.push(cross(prev, cur));
      out.push(cur);
    } else if (pi) out.push(cross(prev, cur));
  }
  return out;
}

const atX = (a: Pt, b: Pt, x: number): Pt => [x, a[1] + ((b[1] - a[1]) * (x - a[0])) / (b[0] - a[0])];
const atY = (a: Pt, b: Pt, y: number): Pt => [a[0] + ((b[0] - a[0]) * (y - a[1])) / (b[1] - a[1]), y];

/** One ring clipped to the box; null if nothing is left. */
export function clipRing(ring: Pt[], [x0, y0, x1, y1]: Box): Pt[] | null {
  let pts = ring.length > 1 && ring[0][0] === ring[ring.length - 1][0] && ring[0][1] === ring[ring.length - 1][1] ? ring.slice(0, -1) : ring;
  pts = clipEdge(pts, (p) => p[0] >= x0, (a, b) => atX(a, b, x0));
  pts = clipEdge(pts, (p) => p[0] <= x1, (a, b) => atX(a, b, x1));
  pts = clipEdge(pts, (p) => p[1] >= y0, (a, b) => atY(a, b, y0));
  pts = clipEdge(pts, (p) => p[1] <= y1, (a, b) => atY(a, b, y1));
  return pts.length >= 3 ? [...pts, pts[0]] : null;
}

/** A path clipped to the box: the parts inside, as separate paths. */
export function clipPath(path: Pt[], [x0, y0, x1, y1]: Box): Pt[][] {
  const out: Pt[][] = [];
  let cur: Pt[] = [];
  for (let i = 1; i < path.length; i++) {
    const a = path[i - 1], b = path[i];
    const dx = b[0] - a[0], dy = b[1] - a[1];
    let t0 = 0, t1 = 1, ok = true;
    for (const [p, q] of [[-dx, a[0] - x0], [dx, x1 - a[0]], [-dy, a[1] - y0], [dy, y1 - a[1]]]) {
      if (p === 0) { if (q < 0) { ok = false; break; } continue; }
      const r = q / p;
      if (p < 0) { if (r > t1) { ok = false; break; } if (r > t0) t0 = r; }
      else { if (r < t0) { ok = false; break; } if (r < t1) t1 = r; }
    }
    if (!ok) { if (cur.length > 1) out.push(cur); cur = []; continue; }
    const s: Pt = [a[0] + t0 * dx, a[1] + t0 * dy], e: Pt = [a[0] + t1 * dx, a[1] + t1 * dy];
    if (!cur.length) cur.push(s);
    cur.push(e);
    if (t1 < 1) { out.push(cur); cur = []; }
  }
  if (cur.length > 1) out.push(cur);
  return out;
}

/** ArcGIS JSON geometry → GeoJSON geometry clipped to the box (null if nothing is inside). */
export function clipEsriGeometry(g: any, box: Box): any | null {
  if (!g) return null;
  if (g.rings) {
    // ArcGIS rings are flat (outer rings clockwise, holes counter-clockwise); keeping them as one polygon with even-odd
    // filling draws holes correctly without needing to re-nest them
    const rings = g.rings.map((r: Pt[]) => clipRing(r, box)).filter(Boolean);
    return rings.length ? { type: "Polygon", coordinates: rings } : null;
  }
  if (g.paths) {
    const paths = g.paths.flatMap((p: Pt[]) => clipPath(p, box));
    return paths.length ? { type: "MultiLineString", coordinates: paths } : null;
  }
  if (typeof g.x === "number") {
    const [x0, y0, x1, y1] = box;
    return g.x >= x0 && g.x <= x1 && g.y >= y0 && g.y <= y1 ? { type: "Point", coordinates: [g.x, g.y] } : null;
  }
  return null;
}
