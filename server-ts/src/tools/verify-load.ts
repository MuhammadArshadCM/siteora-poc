/**
 * Verify that every record in the research files is in the database, unchanged.
 *
 * For each research/councils/<council>.json it checks:
 *   * the planning scheme instrument and version exist;
 *   * every rule's verbatim text is stored in provisions (matched by research_key) — exact string match;
 *   * every non-definition rule has a rule (DRAFT, SUPERSEDED or curated);
 *   * definitions, levels of assessment, QDC-relationship quotes, overlay quotes and open questions were loaded;
 * and for research/places.json that every zone, precinct, local plan and local-plan precinct exists with the
 * same dwelling-house flag. Exit code 1 on any mismatch.
 *
 *   npm run verify-load
 */
import path from "node:path";
import { Db, lit } from "../core/db.js";
import { loadEnv, ROOT } from "../core/env.js";
import { COUNCILS, readResearch } from "./import-council-research.js";
import { exit, left, right } from "./fmt.js";

async function main(): Promise<number> {
  loadEnv();
  const db = new Db();
  const q = (sql: string) => db.q<any>(sql);
  let problems = 0;
  try {
    console.log(`${left("council", 15)} ${right("rules", 6)} ${right("text ok", 8)} ${right("rule rows", 9)} ${right("defs", 5)} ${right("LOA", 4)} ${right("QDC q", 6)} ${right("ovl q", 6)} ${right("issues", 7)}  result`);
    for (const [slugName, [, authority, inst]] of Object.entries(COUNCILS)) {
      const d = readResearch(path.join(ROOT, "research", "councils", `${slugName}.json`));
      const ivs: string[] = await q(`SELECT coalesce(json_agg(instrument_version_id), '[]') FROM regs.instrument_versions WHERE instrument_id = ${lit(inst)}`);
      if (ivs.length !== 1) {
        console.log(`${left(slugName, 15)} planning scheme version missing or duplicated: ${JSON.stringify(ivs)}`);
        problems++;
        continue;
      }
      const iv = ivs[0];
      const stored: Record<string, string> = Object.fromEntries(await q(`SELECT coalesce(json_agg(json_build_array(research_key, verbatim_text)), '[]')
        FROM regs.provisions WHERE instrument_version_id = ${lit(iv)} AND research_key IS NOT NULL`));
      const rules: any[] = d.rules;
      const textOk = rules.filter((r) => r.rule_key in stored && stored[r.rule_key] === (r.verbatim_text ?? null)).length;
      const ruleIds = new Set<string>(await q(`SELECT coalesce(json_agg(rule_id), '[]') FROM regs.rules WHERE instrument_id = ${lit(inst)}`));
      const expectedRules = rules.filter((r) => r.provision_type !== "DEFINITION");
      const ruleRows = expectedRules.filter((r) => ruleIds.has(`${authority}.${r.rule_key}`)).length;
      const countKind = (where: string) =>
        q(`SELECT count(*) FROM regs.provisions WHERE instrument_version_id = ${lit(iv)} AND research_key IS NULL AND ${where}`);
      const got: Record<string, [number, number]> = {
        defs: [await countKind("kind = 'DEFINITION'"), (d.definitions ?? []).length],
        loa: [await countKind("kind = 'LEVEL_OF_ASSESSMENT'"), (d.levels_of_assessment ?? []).length],
        qdc: [await countKind("ref_label LIKE 'QDC relationship:%'"), (d.qdc_qhc_relationship?.quotes ?? []).length],
        ovl: [await countKind("ref_label LIKE 'overlay %'"), (d.overlays_affecting_siting ?? []).length],
        issues: [await q(`SELECT count(*) FROM regs.open_issues WHERE instrument_id = ${lit(inst)}`), (d.open_questions ?? []).length],
      };
      const ok = textOk === rules.length && ruleRows === expectedRules.length && Object.values(got).every(([a, b]) => a === b);
      problems += ok ? 0 : 1;
      const f = (k: string) => `${got[k][0]}/${got[k][1]}`;
      console.log(`${left(slugName, 15)} ${right(rules.length, 6)} ${right(textOk, 8)} ${right(ruleRows, 4)}/${left(expectedRules.length, 4)} ${right(f("defs"), 5)} ${right(f("loa"), 4)} `
        + `${right(f("qdc"), 6)} ${right(f("ovl"), 6)} ${right(f("issues"), 7)}  ${ok ? "OK" : "MISMATCH"}`);
      for (const r of rules) {
        if (!(r.rule_key in stored)) console.log(`    missing provision for ${r.rule_key}`);
        else if (stored[r.rule_key] !== (r.verbatim_text ?? null)) console.log(`    verbatim text differs for ${r.rule_key}`);
      }
    }

    console.log();
    const places: Record<string, any> = readResearch(path.join(ROOT, "research", "places.json")).councils;
    const zones = new Map<string, any>((await q("SELECT coalesce(json_agg(z), '[]') FROM regs.zones z")).map((z: any) => [z.zone_id, z]));
    const precincts = new Set<string>(await q("SELECT coalesce(json_agg(precinct_id), '[]') FROM regs.precincts"));
    const lps = new Set<string>(await q("SELECT coalesce(json_agg(local_plan_id), '[]') FROM regs.local_plans"));
    const lpps = new Set<string>(await q("SELECT coalesce(json_agg(local_plan_precinct_id), '[]') FROM regs.local_plan_precincts"));
    console.log(`${left("council", 15)} ${right("zones", 6)} ${right("flag ok", 8)} ${right("precincts", 10)} ${right("local plans", 12)} ${right("lp precincts", 13)}  result`);
    for (const [slugName, pl] of Object.entries(places)) {
      const a = pl.authority;
      const zs: [string, any][] = pl.zones.map((z: any) => [`${a}:${z.code}`, z]);
      const zOk = zs.filter(([zid]) => zones.has(zid)).length;
      const fOk = zs.filter(([zid, z]) => zones.has(zid) && zones.get(zid).dwelling_house_permitted === (z.dwelling_house_permitted ?? null)
        && zones.get(zid).regulated_zone_id === (z.regulated ?? null)).length;
      const pExp = pl.precincts.map((p: any) => `${a}:${p.zone}/${p.code}`);
      const lpExp = pl.local_plans.map((x: any) => `${a}:${x.code}`);
      const lppExp = pl.local_plans.flatMap((x: any) => x.precincts.map((p: any) => `${a}:${x.code}/${p.code}`));
      const pOk = pExp.filter((x: string) => precincts.has(x)).length;
      const lpOk = lpExp.filter((x: string) => lps.has(x)).length;
      const lppOk = lppExp.filter((x: string) => lpps.has(x)).length;
      const ok = zOk === fOk && fOk === zs.length && pOk === pExp.length && lpOk === lpExp.length && lppOk === lppExp.length;
      problems += ok ? 0 : 1;
      console.log(`${left(slugName, 15)} ${right(zOk, 2)}/${left(zs.length, 3)} ${right(fOk, 4)}/${left(zs.length, 3)} ${right(pOk, 5)}/${left(pExp.length, 4)} ${right(lpOk, 6)}/${left(lpExp.length, 5)} `
        + `${right(lppOk, 6)}/${left(lppExp.length, 6)}  ${ok ? "OK" : "MISMATCH"}`);
    }
  } finally {
    await db.close();
  }
  console.log();
  console.log(problems ? `${problems} mismatch(es)` : "PASS — every research record is in the database unchanged");
  return problems ? 1 : 0;
}

main().then(exit, (e) => { console.error(e); exit(1); });
