import fs from "node:fs";
import path from "node:path";
import ExcelJS from "exceljs";
import { ROOT } from "./env.js";

/**
 * Search log: every successful /api/rules search is appended to server-ts/logs/ (git-ignored):
 *   search-log.xlsx   sheet "Searches" (one row per search) and sheet "Data sources" (one row per dataset per search,
 *                     tied to its search by the Search no.), with clickable links
 *   searches.jsonl    one JSON record per search (full detail, also the backup if the workbook is open in Excel)
 */
const LOG_DIR = path.join(ROOT, "server-ts", "logs");
const XLSX = path.join(LOG_DIR, "search-log.xlsx");

const SEARCHES: [string, string, number][] = [
  ["Search no.", "no", 10], ["Date and time", "time", 20], ["Address typed", "typed", 34], ["Matched address", "address", 38],
  ["Latitude", "lat", 12], ["Longitude", "lon", 12], ["Council", "council", 16], ["Lot / plan", "lotplan", 14], ["Zone", "zone", 30],
  ["Structure", "structure", 14], ["Warnings", "warnings", 50],
];
const SOURCES: [string, string, number][] = [
  ["Search no.", "no", 10], ["Address", "address", 34], ["Type", "kind", 16], ["Dataset", "dataset", 34], ["Publisher / layer", "publisher", 40],
  ["Result for this property", "result", 44], ["Layer details", "layer", 16], ["Query for this point", "query", 20], ["Map viewer", "viewer", 14],
];

function style(ws: ExcelJS.Worksheet, cols: [string, string, number][]) {
  ws.columns = cols.map(([header, key, width]) => ({ header, key, width }));
  const head = ws.getRow(1);
  head.font = { bold: true, color: { argb: "FFFFFFFF" } };
  head.fill = { type: "pattern", pattern: "solid", fgColor: { argb: "FF1F4E78" } };
  head.alignment = { vertical: "middle", wrapText: true };
  head.height = 22;
  ws.views = [{ state: "frozen", ySplit: 1 }];
  ws.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: cols.length } };
}

const link = (url: unknown, text: string) => (url ? { text, hyperlink: String(url) } : "");

let chain: Promise<void> = Promise.resolve();

export function logSearch(searched: string, structure: string, result: any): void {
  const loc = result?.location;
  if (!loc) return;
  const at = new Date();
  try {
    fs.mkdirSync(LOG_DIR, { recursive: true });
    fs.appendFileSync(path.join(LOG_DIR, "searches.jsonl"), JSON.stringify({ searched_at: at.toISOString(), searched_input: searched, structure,
      matched_address: loc.geocode?.address ?? null, lon: loc.lon, lat: loc.lat, council: loc.council?.lga_name ?? null, lotplan: loc.parcel?.lotplan ?? null,
      sources: loc.sources, site_constraints: loc.site_constraints, warnings: loc.warnings }) + "\n");
  } catch (e) {
    console.warn(`${new Date().toISOString()} search log (jsonl) not written: ${(e as Error).message}`);
  }
  chain = chain.then(() => appendWorkbook(at, searched, structure, loc)).catch((e) =>
    console.warn(`${new Date().toISOString()} search-log.xlsx not updated (is it open in Excel? close it): ${(e as Error).message}`));
}

async function appendWorkbook(at: Date, searched: string, structure: string, loc: any): Promise<void> {
  const wb = new ExcelJS.Workbook();
  if (fs.existsSync(XLSX)) await wb.xlsx.readFile(XLSX);
  let ws1 = wb.getWorksheet("Searches");
  let ws2 = wb.getWorksheet("Data sources");
  if (!ws1) { ws1 = wb.addWorksheet("Searches"); style(ws1, SEARCHES); }
  if (!ws2) { ws2 = wb.addWorksheet("Data sources"); style(ws2, SOURCES); }
  ws1.columns = SEARCHES.map(([header, key, width]) => ({ header, key, width }));
  ws2.columns = SOURCES.map(([header, key, width]) => ({ header, key, width }));

  const no = ws1.rowCount;   // header is row 1, so the first search is no. 1
  const address = loc.geocode?.address ?? searched;
  const zone = (loc.sources ?? []).find((s: any) => s.what === "Zone")?.result ?? "";
  ws1.addRow({ no, time: at.toLocaleString("en-AU", { timeZone: "Australia/Brisbane", hour12: false }), typed: searched, address, lat: loc.lat, lon: loc.lon,
    council: loc.council?.lga_name ?? "", lotplan: loc.parcel?.lotplan ?? "", zone, structure, warnings: (loc.warnings ?? []).join("\n") });

  const add = (r: Record<string, unknown>) => ws2!.addRow({ no, address, ...r });
  for (const s of loc.sources ?? [])
    add({ kind: "Location lookup", dataset: s.what, publisher: s.source, result: s.result, layer: link(s.layer_url, "Layer details"),
      query: link(s.query_url, "Open query"), viewer: link(s.viewer_url, "Open map") });
  for (const c of loc.site_constraints ?? [])
    add({ kind: "Site constraint", dataset: `${c.category}: ${c.name}`, publisher: c.scope === "State" ? "State layer" : "Council layer",
      result: c.status === "ok" ? (c.hit ? `Found: ${(c.values ?? []).join("; ") || c.count}` : "None on or near the lot") : `Error: ${c.error}`,
      layer: link(c.layer ? `${c.layer}?f=html` : "", "Layer details") });

  for (const ws of [ws1, ws2]) {
    ws.eachRow((row, i) => {
      if (i === 1) return;
      row.alignment = { vertical: "top", wrapText: true };
      row.eachCell((cell) => { if (typeof cell.value === "object" && cell.value && "hyperlink" in cell.value) cell.font = { color: { argb: "FF0563C1" }, underline: true }; });
    });
    ws.autoFilter = { from: { row: 1, column: 1 }, to: { row: 1, column: ws.columnCount } };
  }
  await wb.xlsx.writeFile(XLSX);
}
