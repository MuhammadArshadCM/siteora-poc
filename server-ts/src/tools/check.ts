/**
 * Regression checks for the regs dataset.
 *
 * 1. Integrity invariants (every one must return zero rows).
 * 2. Every examples/*.json scenario reproduces its recorded examples/*.out.md.
 *
 *   npm run check
 *   npm run check -- --update     rewrites the recorded outputs (review the diff before committing)
 */
import fs from "node:fs";
import path from "node:path";
import { Db } from "../core/db.js";
import { loadEnv, ROOT } from "../core/env.js";
import * as evaluate from "../core/evaluate.js";
import { parseArgs } from "./args.js";
import { exit } from "./fmt.js";

const INVARIANTS: Record<string, string> = {
  "active rule without PRIMARY source":
    "SELECT rule_version_id FROM regs.v_untraceable_rules",
  "relationship target rule_id does not exist":
    "SELECT relationship_id FROM regs.rule_relationships r WHERE r.to_rule_id IS NOT NULL "
    + "AND NOT EXISTS (SELECT 1 FROM regs.rules x WHERE x.rule_id = r.to_rule_id)",
  "automatable rule that is not verified":
    "SELECT rule_version_id FROM regs.rule_versions WHERE automatable "
    + "AND verification NOT IN ('VERIFIED_VERBATIM','VERIFIED_FROM_FIGURE')",
  "condition references a boundary_type value outside the fact's allowed values":
    "SELECT c.condition_id FROM regs.rule_conditions c, jsonb_array_elements_text(CASE WHEN jsonb_typeof(c.value)='array' "
    + "THEN c.value ELSE jsonb_build_array(c.value) END) v WHERE c.fact_id = 'boundary_type' "
    + "AND v NOT IN (SELECT unnest(allowed_values) FROM regs.facts WHERE fact_id = 'boundary_type')",
  "value expression references an unknown fact":
    "SELECT DISTINCT v #>> '{}' FROM regs.rule_versions rv, jsonb_path_query(rv.value_expr, 'lax $.**.var') v "
    + "WHERE rv.status = 'ACTIVE' AND NOT EXISTS (SELECT 1 FROM regs.facts f WHERE f.fact_id = v #>> '{}')",
  "provision text contains a carriage return (line-ending corruption)":
    "SELECT provision_id FROM regs.provisions WHERE verbatim_text LIKE '%' || chr(13) || '%'",
  "active curated council rule still has an ACTIVE draft for the same provision":
    "SELECT r.from_rule_version_id FROM regs.rule_relationships r JOIN regs.rule_versions d ON d.rule_version_id = r.to_rule_version_id "
    + "WHERE r.type = 'REPLACES' AND d.status = 'ACTIVE' AND r.from_rule_version_id LIKE '%.C.%'",
};

async function main(): Promise<number> {
  const a = parseArgs(process.argv.slice(2), { booleans: ["update"] });
  loadEnv();
  const db = new Db();
  let failed = 0;
  try {
    for (const [name, sql] of Object.entries(INVARIANTS)) {
      const rows: any[] = await db.q(`SELECT coalesce(json_agg(x), '[]') FROM (${sql}) x`);
      failed += rows.length ? 1 : 0;
      console.log(`[invariant] ${name}: ${rows.length ? `FAIL (${rows.length}): ${JSON.stringify(rows.slice(0, 3))}` : "ok"}`);
    }
    const dir = path.join(ROOT, "examples");
    for (const f of fs.readdirSync(dir).filter((x) => x.endsWith(".json")).sort()) {
      const scen: evaluate.Scenario = JSON.parse(fs.readFileSync(path.join(dir, f), "utf-8"));
      const out = evaluate.render(scen, await evaluate.resolve(db, scen));
      const expected = path.join(dir, f.replace(/\.json$/, ".out.md"));
      if (a.update || !fs.existsSync(expected)) {
        fs.writeFileSync(expected, out, "utf-8");
        console.log(`[example]   ${f}: recorded`);
      } else if (out === fs.readFileSync(expected, "utf-8").replace(/\r\n/g, "\n")) {
        console.log(`[example]   ${f}: ok`);
      } else {
        failed++;
        console.log(`[example]   ${f}: FAIL — output differs from ${path.basename(expected)}`);
      }
    }
  } finally {
    await db.close();
  }
  console.log(failed ? `${failed} check(s) failed` : "PASS");
  return failed ? 1 : 0;
}

main().then(exit, (e) => { console.error(e); exit(1); });
