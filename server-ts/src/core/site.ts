/**
 * Site constraints (easements, services, flood, vegetation…). Port of poc/siteora_poc/site.py; config poc/site_layers.json.
 * Council first per category, State fallback ('always' State layers are added regardless); whole-lot queries.
 */
import path from "node:path";
import { POC_DIR, readJson } from "./env.js";
import { lotQuery, Rings } from "./geo.js";
import { cmpTuple, unique } from "./py.js";

export const CONFIG = path.join(POC_DIR, "site_layers.json");

export function loadConfig(): Record<string, any> {
  return readJson(CONFIG, {});
}

export function layersFor(lgId: string): any[] {
  const cfg = loadConfig();
  const council = (cfg[lgId] ?? []).map((l: any) => ({ ...l, scope: "council" }));
  const have = new Set(council.map((l: any) => l.category));
  const state = (cfg.STATE ?? []).filter((l: any) => !have.has(l.category) || l.always).map((l: any) => ({ ...l, scope: "State" }));
  return [...council, ...state];
}

function meta(l: any): Record<string, any> {
  const out: Record<string, any> = {};
  // where: the map page applies the same filter, so it draws only what was tested (e.g. easements, not every parcel)
  for (const k of ["category", "name", "layer", "geometry", "scope", "distance_m", "fact", "label_field", "where"]) out[k] = l[k] ?? null;
  return out;
}

async function check(l: any, rings: Rings): Promise<Record<string, any>> {
  try {
    const feats = await lotQuery(l.layer, rings, "*", l.distance_m, l.where ?? "1=1", l.geometry === "polygon");
    const labels: string[] = [], details: Record<string, any>[] = [];
    for (const f of feats) {
      const a = f.attributes ?? {};
      const lab = l.label_field ? a[l.label_field] : null;
      if (lab !== null && lab !== undefined && lab !== "") labels.push(String(lab).trim());
      const d: Record<string, any> = {};
      for (const k of l.show_fields ?? []) if (a[k] !== null && a[k] !== undefined && a[k] !== "") d[k] = a[k];
      details.push(d);
    }
    // sorted, so the result does not depend on the order a service happens to return features in
    const byText = (a: unknown, b: unknown) => { const x = JSON.stringify(a), y = JSON.stringify(b); return x < y ? -1 : x > y ? 1 : 0; };
    return { ...meta(l), status: "ok", hit: feats.length > 0, count: feats.length, values: unique(labels).sort(byText).slice(0, 12),
      details: details.sort(byText).slice(0, 20) };
  } catch (e) {   // one failing service must not break the result
    return { ...meta(l), status: "error", error: String((e as Error).message ?? e).slice(0, 160), hit: null, features: [] };
  }
}

/** Run tasks with at most `limit` in flight (ThreadPoolExecutor equivalent). */
export async function pool<T, R>(items: T[], limit: number, fn: (t: T) => Promise<R>): Promise<R[]> {
  const out: R[] = new Array(items.length);
  let next = 0;
  const worker = async () => {
    while (next < items.length) {
      const i = next++;
      out[i] = await fn(items[i]);
    }
  };
  await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
  return out;
}

/** Query every selected layer against the lot; hits first within each category. */
export async function constraints(lgId: string, rings: Rings | null | undefined, workers = 16): Promise<any[]> {
  const ls = layersFor(lgId);
  if (!rings || !ls.length) return [];
  const rows = await pool(ls, workers, (l) => check(l, rings));
  return rows.sort((a, b) => cmpTuple([a.category, !a.hit, a.name], [b.category, !b.hit, b.name]));
}

/** Yes/no facts from layers that declare one: true if any hits; false only if every such layer answered and none hit. */
export function factsFrom(rows: any[]): Record<string, boolean> {
  const out = new Map<string, boolean | null>();
  for (const r of rows) {
    const f = r.fact;
    if (!f) continue;
    const cur = out.get(f) ?? null;
    if (r.status !== "ok") out.set(f, cur === true ? true : null);
    else if (r.hit) out.set(f, true);
    else if (cur === null && !out.has(f)) out.set(f, false);
  }
  return Object.fromEntries([...out].filter(([, v]) => v !== null)) as Record<string, boolean>;
}
