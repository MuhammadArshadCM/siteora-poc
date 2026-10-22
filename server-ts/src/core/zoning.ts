/** Council zoning / overlay / local-plan lookup. Port of poc/siteora_poc/zoning.py (config: poc/zoning_layers.json). */
import path from "node:path";
import { POC_DIR, readJson } from "./env.js";
import { pointQuery } from "./geo.js";
import { unique } from "./py.js";

export const CONFIG = path.join(POC_DIR, "zoning_layers.json");
const WORDS = /\b(zone|precinct|sub precinct|neighbourhood plan|local plan|plan)\b/g;

export function norm(s: string | null | undefined): string {
  let t = (s ?? "").toLowerCase().replace(/–/g, "-").replace(/-/g, " ");
  t = t.replace(/[^a-z0-9 ]+/g, " ");
  t = t.replace(WORDS, " ");
  t = t.replace(/\b([a-z]+)ies\b/g, "$1y");   // plural map text, e.g. Redland's 'Emerging Communities' = 'Emerging community zone'
  return t.replace(/\s+/g, " ").trim();
}

export function loadConfig(): Record<string, any> {
  return readJson(CONFIG, {});
}

async function first(layer: string, lon: number, lat: number): Promise<Record<string, any> | null> {
  const feats = await pointQuery(layer, lon, lat);
  return feats.length ? feats[0].attributes : null;
}

export interface Found {
  zone_text: string | null; precinct_text: string | null; local_plan_text: string | null; local_plan_precinct_text: string | null;
  local_plan_precinct_code?: string | null; source: string; point: [number, number]; notes?: string; raw: Record<string, any>;
}

/** The council's zoning layers at the first point that hits a zone polygon (address point, then a point inside the parcel). */
export async function lookup(lgId: string, points: [number, number][]): Promise<Found | null> {
  const cfg = loadConfig()[lgId];
  if (!cfg || cfg.status !== "WORKING") return null;
  const nulls = new Set<string>([...(cfg.null_values ?? []), ""]);
  const clean = (v: any): string | null => (v === null || v === undefined || nulls.has(String(v).trim()) ? null : String(v).trim());
  for (const [lon, lat] of points) {
    const a = await first(cfg.zone_layer, lon, lat);
    if (!a) continue;
    const out: Found = { zone_text: clean(a[cfg.zone_field]), precinct_text: null, local_plan_text: null,
      local_plan_precinct_text: null, source: cfg.zone_layer, point: [lon, lat], notes: cfg.notes ?? null, raw: a };
    if (cfg.precinct_field) out.precinct_text = clean(a[cfg.precinct_field]);
    for (const layer of cfg.precinct_layers ?? []) {
      const pa = await first(layer, lon, lat);
      if (pa && clean(pa[cfg.precinct_layer_field])) {
        out.precinct_text = clean(pa[cfg.precinct_layer_field]);
        break;
      }
    }
    if (cfg.local_plan_field) {
      out.local_plan_text = clean(a[cfg.local_plan_field]);
      out.local_plan_precinct_text = clean(a[cfg.local_plan_precinct_field]);
    }
    if (cfg.local_plan_layer) {   // neighbourhood plans on their own layers
      const la = await first(cfg.local_plan_layer, lon, lat);
      out.local_plan_text = clean((la ?? {})[cfg.local_plan_layer_field]);
      const pa = out.local_plan_text && cfg.local_plan_precinct_layer ? await first(cfg.local_plan_precinct_layer, lon, lat) : null;
      out.local_plan_precinct_code = clean((pa ?? {})[cfg.local_plan_precinct_code_field]);
      if (cfg.local_plan_precinct_name_field) out.local_plan_precinct_text = clean((pa ?? {})[cfg.local_plan_precinct_name_field]);
    }
    return out;
  }
  return null;
}

export interface OverlayHit { name: string; text: string; overlay_ids: string[]; source: string; flag_fact?: string; value_fact?: string; value?: number | null }

/** Overlay polygons at the property. A hit at any of the points counts. A layer whose service fails is skipped and
 *  its name added to `failed` (when given), so one slow council service does not fail the whole request. */
export async function overlays(lgId: string, points: [number, number][], failed?: { name: string; layer: string; error: string }[]):
  Promise<OverlayHit[]> {
  const cfg = loadConfig()[lgId] ?? {};
  const out: OverlayHit[] = [];
  for (const ov of cfg.overlay_layers ?? []) {
    const texts: any[] = [];
    try {
      for (const [lon, lat] of points) texts.push(...(await pointQuery(ov.layer, lon, lat, ov.field)).map((f) => f.attributes[ov.field]));
    } catch (e) {
      if (!failed) throw e;
      failed.push({ name: ov.name, layer: ov.layer, error: String((e as Error).message ?? e).slice(0, 200) });
      continue;
    }
    for (const t of unique(texts.filter((t) => t !== null && t !== undefined && t !== "").map((t) => String(t).trim()))) {
      const map = ov.map ?? {};
      const ids = Object.prototype.hasOwnProperty.call(map, t) ? map[t] : (map["*"] ?? []);   // '*': any value in the layer
      const hit: OverlayHit = { name: ov.name, text: t, overlay_ids: ids, source: ov.layer };
      if (ov.flag_fact) hit.flag_fact = ov.flag_fact;
      if (ov.value_fact) {   // value overlays, e.g. a mapped maximum height '8.5m'
        const m = /(\d+(?:\.\d+)?)\s*(?:metres?|m)(?![a-z])/.exec(t);
        hit.value_fact = ov.value_fact;
        hit.value = m ? parseFloat(m[1]) : null;
      }
      out.push(hit);
    }
  }
  return out;
}

/** Yes/no facts from 'flag' overlays: true if the layer was hit, false if configured but not hit. A layer that failed
 *  to answer gives no fact at all (unknown → the rules that need it go to manual review), never a false "no". */
export function overlayFlags(lgId: string, hits: OverlayHit[], failedLayers: string[] = []): Record<string, boolean> {
  const cfg = loadConfig()[lgId] ?? {};
  const out: Record<string, boolean> = {};
  const layers = (cfg.overlay_layers ?? []).filter((ov: any) => ov.flag_fact);
  for (const fact of unique<string>(layers.map((ov: any) => ov.flag_fact))) {
    if (hits.some((h) => h.flag_fact === fact)) out[fact] = true;
    else if (!layers.some((ov: any) => ov.flag_fact === fact && failedLayers.includes(ov.layer))) out[fact] = false;
  }
  return out;
}

function containsNorm(a: string, b: string): boolean {
  const x = norm(a), y = norm(b);
  return Boolean(x && y) && (x.includes(y) || y.includes(x));
}

/** Map map-service text onto regs ids: [zone_id, precinct_ids, local_plan_ids, lpp_ids, notes]. */
export function match(found: Found, zones: any[], precincts: any[], localPlans: any[], localPlanPrecincts: any[]):
  [string | null, string[], string[], string[], string[]] {
  const notes: string[] = [];
  const zt = norm(found.zone_text);
  let zoneId: string | null = zones.find((z) => norm(z.name) === zt)?.zone_id ?? null;
  if (!zoneId) {   // layer text may append the precinct, e.g. 'Character residential (Character)'
    const cands = zones.filter((z) => norm(z.name) && zt.includes(norm(z.name)));
    zoneId = cands.length ? cands.reduce((b, z) => (norm(z.name).length > norm(b.name).length ? z : b)).zone_id : null;
  }
  if (!zoneId) notes.push(`Zone '${found.zone_text}' from the council map is not one of the zones in the rules dataset `
    + "(no zone-specific council rules loaded for it).");
  let pids: string[] = [];
  const ptext = found.precinct_text;
  if (ptext && zoneId) {
    const pt = norm(ptext);
    const mine = precincts.filter((p) => p.zone_id === zoneId);
    // exact name or code first ('Suburban' must not also match 'Large suburban' / 'Urban neighbourhood')
    const exact = mine.filter((p) => pt === norm(p.name) || pt === norm(String(p.precinct_id).split("/").pop()));
    if (exact.length) pids = exact.map((p) => p.precinct_id);
    else {   // otherwise the single longest precinct name that appears as whole words in the map text
      const within = mine.filter((p) => norm(p.name) && ` ${pt} `.includes(` ${norm(p.name)} `));
      pids = within.length ? [within.reduce((b, p) => (norm(p.name).length > norm(b.name).length ? p : b)).precinct_id] : [];
    }
    if (!pids.length) notes.push(`Precinct '${ptext}' from the council map has no rules of its own in the dataset.`);
  }
  let lps: string[] = [], lpps: string[] = [];
  if (found.local_plan_text) {
    lps = localPlans.filter((lp) => containsNorm(lp.name, found.local_plan_text!)).map((lp) => lp.local_plan_id);
    const lpt = found.local_plan_precinct_text;
    const code = found.local_plan_precinct_code;
    if (lps.length && code) {
      lpps = localPlanPrecincts.filter((x) => lps.includes(x.local_plan_id) && String(x.local_plan_precinct_id).endsWith("/" + code))
        .map((x) => x.local_plan_precinct_id);
      if (!lpps.length) notes.push(`Neighbourhood plan precinct ${code} has no rules of its own in the dataset.`);
    } else if (lps.length && lpt) {
      // exact name match: map text 'Urban living' must not select 'Urban living precinct - Next generation sub-precinct'
      lpps = localPlanPrecincts.filter((x) => lps.includes(x.local_plan_id) && norm(String(x.name).split("(")[0]) === norm(lpt))
        .map((x) => x.local_plan_precinct_id);
      const subs = localPlanPrecincts.filter((x) => lps.includes(x.local_plan_id) && !lpps.length && norm(lpt)
        && norm(x.name).startsWith(norm(lpt) + " ")).map((x) => x.name);
      if (subs.length) notes.push(`Local plan precinct '${lpt}': rules exist for ${subs.join(", ")}, which the public map `
        + "does not show — check the local plan map and choose it manually if it applies.");
    }
    if (!lps.length) notes.push(`Local / neighbourhood plan '${found.local_plan_text}' has no rules in the dataset yet.`);
  }
  return [zoneId, pids, lps, lpps, notes];
}
