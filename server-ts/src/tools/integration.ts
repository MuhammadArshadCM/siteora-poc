/**
 * Integration assessment for the data source register: how far each map-service host can be trusted for site plans.
 *
 * Measured live, per host (ArcGIS Online: per publisher organisation):
 *   - the publisher's rate-limit budget and the cost of one query, from ArcGIS Online's own response headers
 *     (x-esri-org-request-units-per-min, x-esri-query-request-units)
 *   - how many requests one property lookup sends there (a real lookup per council, counted)
 *   - answer times one at a time and in a burst, and any errors under that load
 *   - HTTPS and HSTS, whether browsers may call it directly (CORS), and response caching
 * Known facts per host (licence, terms, accuracy statements, fitness for drawing site plans, risk, mitigation) are in
 * HOST_FACTS below, each with the date it was checked.
 */
import { Db } from "../core/db.js";
import * as engine from "../core/engine.js";

export interface HostFacts {
  publisher: string;
  terms: string;
  termsUrl?: string;
  sitePlan: string;    // fitness for drawing a site plan
  risk: "Low" | "Medium" | "High";
  mitigation: string;
}

/** Checked 2026-10-19. Keyed by host, or by "host/<ArcGIS organisation id>" for ArcGIS Online. */
export const HOST_FACTS: [RegExp, HostFacts][] = [
  [/^spatial-gis\.information\.qld\.gov\.au$/, {
    publisher: "Queensland Government (QSpatial): address search, cadastre (DCDB), council boundaries, PDA and State overlays",
    terms: "CC BY 4.0 (© State of Queensland); attribution required.", termsUrl: "https://www.qld.gov.au/legal/copyright",
    sitePlan: "Cadastre boundaries are not survey-accurate: each lot carries its own accuracy code (±0.1 m to ±1.5 m on the test lots, e.g. Ashgrove ±1.5 m). The app shows it and warns above ±0.5 m. Final setbacks need the registered survey plan or an identification survey.",
    risk: "High",
    mitigation: "Every lookup depends on it (address, lot, council). In two tests it failed 1 of 30 and 2 of 20 simultaneous queries ('Error performing query operation'). In place: at most 4 simultaneous requests, 2 retries 1–2 s apart, 503 with a clear message. Recommended for production: keep a local copy of the cadastre (weekly download from data.qld.gov.au) so lot lookups do not depend on the live service.",
  }],
  [/^services\.ga\.gov\.au$/, {
    publisher: "Geoscience Australia: national electricity transmission lines",
    terms: "CC BY 4.0 (© Commonwealth of Australia).", termsUrl: "https://www.ga.gov.au/copyright",
    sitePlan: "National-scale data: line positions are approximate (tens of metres). Use only as an alert that a major line is nearby.",
    risk: "Low", mitigation: "Not essential (one layer). Treat as an alert only.",
  }],
  [/ug6sGLFkytbXYo4f/, {
    publisher: "Before You Dig Australia (Look Up and Live): Energex / Ergon network",
    terms: "No licence stated in the service. Look Up and Live is a public safety service.", termsUrl: "https://www.byda.com.au",
    sitePlan: "Shows that lines and cables are on or near the lot (refreshed Jan 2026). Not a substitute for a BYDA enquiry: positions are indicative and the data is for safety awareness.",
    risk: "Medium",
    mitigation: "Confirm the terms of use with BYDA before commercial use. Keep the statement that services must be confirmed by a BYDA enquiry.",
  }],
  [/ocUCNI2h4moKOpKX|tQg86iShPXJPWQWw/, {
    publisher: "Council-owned water utilities (Urban Utilities; Unitywater): sewer and water mains",
    terms: "No licence stated in the services (public open-data services).",
    sitePlan: "Asset positions are indicative; depth is mostly not given. Building near or over sewers needs the utility's approval and a BYDA enquiry.",
    risk: "Medium", mitigation: "Confirm terms with each utility. Show assets as 'on or near the lot: confirm with a BYDA enquiry'.",
  }],
  [/dEKgZETqwmDAh1rP/, {
    publisher: "Brisbane City Council (BrisMAP Public): City Plan zoning, overlays, assets",
    terms: "CC BY 4.0; 'Discrepancies may occur' (item licence text).", termsUrl: "https://data.brisbane.qld.gov.au",
    sitePlan: "City Plan mapping is the legal map for the scheme (updated at each amendment; v37 data 17 Sep 2026). Asset layers are indicative.",
    risk: "Low", mitigation: "Its ArcGIS Online budget is shared by every user of Brisbane's data: the app sends about 44 requests (88 units) per lookup. In place: at most 8 simultaneous requests; map layers clipped and cached by the server.",
  }],
  [/lnVW0dLI3fvST2hd|3vStCH7NDoBOZ5zn|maps1\.goldcoast\.qld\.gov\.au/, {
    publisher: "City of Gold Coast: City Plan zoning, overlays, assets",
    terms: "CC BY 4.0.", termsUrl: "https://data.goldcoast.qld.gov.au",
    sitePlan: "Zoning and overlays are Version 13 open data while Version 14 is in force: Version 14 was a minor, administrative and LGIP amendment, and the council published V14 data only for the maps it changed. Only the airport obstacle limitation surface still comes from the 2015 'City Plan V8' service (no newer one is published). The council's own disclaimer (Designated Flood Level): 'provided for information only… for accurate floor level, a licensed surveyor should be engaged'.",
    risk: "Low", mitigation: "Done 2026-10-21: the 2015 V8 duplicates of the airport noise, waterway and heritage overlays were removed. Re-check after the next scheme amendment.",
  }],
  [/152ojN3Ts9H3cdtl/, {
    publisher: "City of Moreton Bay: planning scheme zoning and overlays",
    terms: "CC BY 4.0.", termsUrl: "https://datahub.moretonbay.qld.gov.au",
    sitePlan: "Overlay data dated 2022 is the council's latest published; the scheme version in force commenced Sep 2026.",
    risk: "Low", mitigation: "Ask the council to confirm the 2026 amendment did not change the overlay mapping.",
  }],
  [/geoimage\.scc\.qld\.gov\.au/, {
    publisher: "Sunshine Coast Council: planning scheme zoning and overlays (council server)",
    terms: "CC BY 3.0 AU.", termsUrl: "https://data.sunshinecoast.qld.gov.au",
    sitePlan: "The services expose no update dates, so currency cannot be shown automatically. The council states the layers are 'published for planning purposes only'.",
    risk: "Medium", mitigation: "Ask the council for the publication date or an update feed; check against the online scheme maps after each amendment.",
  }],
  [/ZUCWDRj8F77Xo351|wspdigital\.com/, {
    publisher: "Logan City Council: planning scheme (served by its contractor WSP) and Logan Water assets",
    terms: "CC BY 3.0 AU.", termsUrl: "https://data-logancity.opendata.arcgis.com",
    sitePlan: "Zones and precincts come from the council's own v9.2 layers (edited 17 Jul 2025); local plans and overlays from the contractor-hosted v9.2 + TLPI 1/2024 service (identical zones, so the 'V9.1' internal title is a label only). Logan Water assets are updated daily. Logan's disclaimer: it makes 'no representations or warranties about its accuracy, reliability, completeness or suitability for any particular purpose'.",
    risk: "Medium", mitigation: "Done 2026-10-21: zones and precincts moved to the council's own ArcGIS organisation. The contractor server (slow: up to 8 s at the 95th percentile) still serves local plans and overlays, at most 3 simultaneous requests.",
  }],
  [/VGRM775aS3HJEeB7|gis\.redland\.qld\.gov\.au/, {
    publisher: "Redland City Council: City Plan zoning and overlays; water / sewer / stormwater assets",
    terms: "CC BY-SA 4.0 (share-alike applies to redistributed derivative data).", termsUrl: "https://opendata.redland.qld.gov.au",
    sitePlan: "City Plan service published 2 Jul 2025; asset service republished nightly.",
    risk: "Low", mitigation: "Note the share-alike licence if derived data is redistributed.",
  }],
  [/Rmbsssqb3knXA9RA/, {
    publisher: "Ipswich City Council (City Plan 2025 needs a login token: not used)",
    terms: "Not public.", sitePlan: "Zoning chosen by hand; State and Urban Utilities layers only. Bushfire is not checked automatically (the result says so, and the Queensland Fire Department's Bushfire Prone Area picture map is shown).",
    risk: "High", mitigation: "Request open data or anonymous access from council@ipswich.qld.gov.au (see docs/13).",
  }],
  [/^utility\.arcgis\.com$/, {
    publisher: "Proxy of the Queensland Fire Department's Bushfire Prone Area",
    terms: "No longer public (403).", sitePlan: "Not available: no bushfire check for Moreton Bay, Ipswich or Redland from this source.",
    risk: "High", mitigation: "Use each council's bushfire overlay, or host the State's downloadable Bushfire Prone Area (South East Queensland).",
  }],
  [/^tile\.openstreetmap\.org$/, {
    publisher: "OpenStreetMap Foundation tile servers (map background only)",
    terms: "ODbL data; the tile usage policy forbids heavy or commercial-scale use of these servers.", termsUrl: "https://operations.osmfoundation.org/policies/tiles/",
    sitePlan: "Background only (not used in any check).", risk: "Medium",
    mitigation: "Before production, switch to a commercial tile provider or self-hosted tiles.",
  }],
  [/^server\.arcgisonline\.com$/, {
    publisher: "Esri World Imagery (aerial background only)",
    terms: "Esri terms of use: attribution required; commercial use generally needs an ArcGIS account or API key.", termsUrl: "https://www.esri.com/en-us/legal/terms/full-master-agreement",
    sitePlan: "Background only. Imagery dates vary by area.", risk: "Medium",
    mitigation: "Before production, use an ArcGIS Location Platform API key or another licensed imagery source (e.g. Queensland Globe imagery under its terms).",
  }],
];

export const factsFor = (key: string): HostFacts | null => { for (const [re, f] of HOST_FACTS) if (re.test(key)) return f; return null; };

/** "host" or "host/<org>" for ArcGIS Online. */
export const hostKey = (u: string) => {
  const x = new URL(u);
  const org = (u.match(/arcgis\.com\/([A-Za-z0-9]{16})\//) ?? [])[1];
  return org ? `${x.host}/${org}` : x.host;
};

const pct = (xs: number[], p: number) => { const s = [...xs].sort((a, b) => a - b); return s.length ? s[Math.min(s.length - 1, Math.floor(p * s.length))] : ""; };

/** Live probe: 10 queries one at a time, then 10 at once (tiny count-only queries), plus the headers that matter. */
export async function probeHost(sampleLayer: string) {
  const env = JSON.stringify({ xmin: 153.02, ymin: -27.47, xmax: 153.0205, ymax: -27.4695, spatialReference: { wkid: 4326 } });
  const url = `${sampleLayer}/query?where=1%3D1&geometry=${encodeURIComponent(env)}&geometryType=esriGeometryEnvelope&inSR=4326`
    + "&spatialRel=esriSpatialRelIntersects&returnCountOnly=true&f=json";
  const one = async () => {
    const t0 = Date.now();
    try {
      const r = await fetch(url, { headers: { Origin: "http://localhost:8766", "User-Agent": "siteora-poc/0.1" }, signal: AbortSignal.timeout(30000) });
      const text = await r.text();
      let err: string | null = null;
      try { const j = JSON.parse(text); if (j.error) err = `${j.error.code} ${j.error.message}`; } catch { err = "not JSON"; }
      return { ok: r.ok && !err, status: r.status, err, ms: Date.now() - t0, h: r.headers };
    } catch (e) {
      return { ok: false, status: 0, err: String((e as any).cause?.code ?? (e as Error).message).slice(0, 60), ms: Date.now() - t0, h: null as any };
    }
  };
  const seq = [];
  for (let i = 0; i < 10; i++) seq.push(await one());
  const burst = await Promise.all(Array.from({ length: 10 }, one));
  const all = [...seq, ...burst];
  const h = all.find((r) => r.h)?.h;
  const errors = all.filter((r) => !r.ok).map((r) => r.err ?? `HTTP ${r.status}`);
  const budget = h?.get("x-esri-org-request-units-per-min") ?? "";
  return {
    seq: `${pct(seq.map((r) => r.ms), 0.5)} / ${pct(seq.map((r) => r.ms), 0.95)}`,
    burst: `${pct(burst.map((r) => r.ms), 0.5)} / ${pct(burst.map((r) => r.ms), 0.95)}`,
    errors: errors.length ? `${errors.length} of 20: ${[...new Set(errors)].join("; ").slice(0, 160)}` : "none of 20",
    budgetMax: Number((budget.match(/max=(\d+)/) ?? [])[1]) || null,
    budgetUsed: Number((budget.match(/usage=(\d+)/) ?? [])[1]) || null,
    unitsPerQuery: Number(h?.get("x-esri-query-request-units") ?? 0) || null,
    https: sampleLayer.startsWith("https://") ? (h?.get("strict-transport-security") ? "HTTPS + HSTS" : "HTTPS") : "HTTP only",
    cors: h?.get("access-control-allow-origin") ? "Allowed" : "Not allowed (server-side only)",
    cache: h?.get("cache-control") ?? "",
  };
}

/** Requests (and ArcGIS Online units) one property lookup sends to each host: a real lookup per council, counted. */
export async function demandPerLookup(points: [string, number, number][]) {
  const per = new Map<string, { requests: number; units: number; lookups: number }>();
  const orig = globalThis.fetch;
  globalThis.fetch = (async (u: any, o: any) => {
    const r = await orig(u, o);
    try {
      const k = hostKey(String(u));
      const e = per.get(k) ?? { requests: 0, units: 0, lookups: 0 };
      e.requests++;
      e.units += Number(r.headers.get("x-esri-query-request-units") ?? 0);
      per.set(k, e);
    } catch { /* not a URL we track */ }
    return r;
  }) as typeof fetch;
  const db = new Db({ max: 2 });
  const seen = new Map<string, Set<string>>();
  try {
    for (const [name, lon, lat] of points) {
      const before = new Map([...per].map(([k, v]) => [k, v.requests]));
      try {
        await engine.run(db, "SHED", { height_m: "3", length_m: "6", width_m: "4" }, { lon, lat });
      } catch { /* a failed lookup still counts the requests it sent */ }
      for (const [k, v] of per) if (v.requests > (before.get(k) ?? 0)) (seen.get(k) ?? seen.set(k, new Set()).get(k)!).add(name);
    }
  } finally {
    globalThis.fetch = orig;
    await db.close();
  }
  for (const [k, v] of per) v.lookups = seen.get(k)?.size ?? 0;
  return per;
}
