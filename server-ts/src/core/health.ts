/**
 * Health check (GET /api/health, and logged at start-up): is everything the app needs reachable?
 *   database      PostgreSQL reachable, login accepted, rules dataset (schema regs) loaded
 *   required      the State services every request needs (address search, council boundaries, cadastre)
 *   councils      each working council's zoning map service (a failure here only affects that council)
 * ok = database and required services are up. Each check reports its time, so slow services show up too.
 */
import { Db } from "./db.js";
import * as geo from "./geo.js";
import * as zoning from "./zoning.js";

interface Check { name: string; ok: boolean; ms: number; detail: string }

async function timed(name: string, fn: () => Promise<string>): Promise<Check> {
  const t0 = Date.now();
  try {
    const detail = await fn();
    return { name, ok: true, ms: Date.now() - t0, detail };
  } catch (e) {
    return { name, ok: false, ms: Date.now() - t0, detail: String((e as Error).message ?? e).slice(0, 300) };
  }
}

const service = (url: string) => async () => {
  const j = await geo.getJson(url, { f: "json" }, 15, 1);
  return j.name ?? j.serviceDescription?.slice?.(0, 60) ?? "answered";
};

export async function health(db: Db) {
  const [database, ...required] = await Promise.all([
    timed("database", async () => {
      const n = await db.q<number>("SELECT count(*) FROM regs.rule_versions WHERE status = 'ACTIVE'");
      if (!n) throw new Error("the rules dataset has no active rules: run db/load_all.sql");
      return `${n} active rules`;
    }),
    timed("State address search", service(geo.GEOCODER.replace(/\/findAddressCandidates$/, ""))),
    timed("State council boundaries", service(geo.LGA_LAYER)),
    timed("State cadastre", service(geo.PARCEL_LAYER)),
  ]);
  const cfg = zoning.loadConfig();
  const councils = await Promise.all(Object.entries<any>(cfg).filter(([k, c]) => !k.startsWith("_") && c.status === "WORKING")
    .map(([k, c]) => timed(`${k} zoning map`, service(c.zone_layer))));
  const ok = database.ok && required.every((c) => c.ok);
  return { ok, checked: new Date().toISOString(), database, required, councils,
    summary: ok ? (councils.every((c) => c.ok) ? "All checks passed" : "Working; some council services are not answering (see councils)")
      : "Not working: " + [database, ...required].filter((c) => !c.ok).map((c) => `${c.name}: ${c.detail}`).join("; ") };
}
