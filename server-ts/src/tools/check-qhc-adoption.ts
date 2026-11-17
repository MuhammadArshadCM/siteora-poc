/**
 * Per-council keyword check for Queensland Housing Code (QHC) adoption, built in response to
 * open_issues #4: there is no central department register of QHC adoption effective days to poll (checked
 * directly, confirmed none exists) -- each council instead amends its OWN planning scheme to state how the
 * QHC applies, and the correct recheck target is each council's own live scheme page. This fetches each
 * council's known public planning-scheme URL (instrument_versions.source_url) and searches its text for
 * "Housing Code" or "QHC" -- a hit means the council may now reference the QHC and its scheme text should
 * be re-read to confirm adoption; a miss means no change was found on that page.
 *
 * This is a lightweight landing-page signal, not a full-document audit: some of these URLs are SPA/ePlan
 * viewers or map applications that return no readable text (reported as SKIP, not a failure), and even a
 * reachable HTML page might not surface a keyword appearing only deep in the scheme's own PDF. Run this
 * periodically (e.g. monthly, alongside `npm run check-services`) as a cheap first-pass trigger for a
 * closer manual look, not as a substitute for one.
 *
 *   npm run check-qhc
 */
import { Db } from "../core/db.js";
import { loadEnv } from "../core/env.js";
import { exit, left } from "./fmt.js";

const KEYWORD_RE = /housing code|\bQHC\b/i;
const TIMEOUT_S = 20;

interface Row { lg_id: string; instrument_version_id: string; source_url: string | null }

async function checkOne(url: string): Promise<{ status: "HIT" | "CLEAR" | "SKIP" | "ERROR"; detail: string }> {
  let res: Response;
  try {
    res = await fetch(url, {
      headers: { "User-Agent": "siteora-poc/0.1 (planning-rules research; qhc adoption check)" },
      signal: AbortSignal.timeout(TIMEOUT_S * 1000),
    });
  } catch (e) {
    return { status: "ERROR", detail: String((e as Error).message ?? e).slice(0, 100) };
  }
  if (!res.ok) return { status: "ERROR", detail: `HTTP ${res.status}` };
  const contentType = res.headers.get("content-type") ?? "";
  if (!/text\/html|text\/plain/i.test(contentType)) return { status: "SKIP", detail: `not text (${contentType.split(";")[0] || "unknown"})` };
  const body = await res.text();
  const m = body.match(KEYWORD_RE);
  if (m) return { status: "HIT", detail: `found "${m[0]}" -- re-read this council's scheme text to confirm adoption` };
  return { status: "CLEAR", detail: "no mention found on this page" };
}

async function main(): Promise<number> {
  loadEnv();
  const db = new Db();
  let hits = 0, errors = 0;
  try {
    const rows: Row[] = await db.q(`
      SELECT coalesce(json_agg(x), '[]') FROM (
        SELECT i.lg_id, iv.instrument_version_id, iv.source_url
        FROM regs.instrument_versions iv
        JOIN regs.instruments i ON i.instrument_id = iv.instrument_id
        WHERE i.kind = 'PLANNING_SCHEME' AND iv.status = 'ACTIVE'
        ORDER BY i.lg_id
      ) x`);
    console.log(`${left("council", 18)} status   detail`);
    for (const r of rows) {
      if (!r.source_url) {
        console.log(`${left(r.lg_id, 18)} SKIP     no source_url on ${r.instrument_version_id}`);
        continue;
      }
      const { status, detail } = await checkOne(r.source_url);
      if (status === "HIT") hits++;
      if (status === "ERROR") errors++;
      console.log(`${left(r.lg_id, 18)} ${left(status, 8)} ${detail}`);
    }
  } finally {
    await db.close();
  }
  console.log();
  if (hits) console.log(`${hits} council(s) mention "Housing Code"/"QHC" on their scheme page -- re-check those directly (open_issues #4).`);
  else console.log(`No council's scheme page mentions "Housing Code"/"QHC" yet (${errors} unreachable/blocked, checked lightly only).`);
  return hits ? 1 : 0;   // non-zero only means "found something to look at", not that the check itself failed
}

main().then(exit, (e) => { console.error(e); exit(1); });
