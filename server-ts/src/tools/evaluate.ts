/**
 * Reference resolver from the command line: which rules apply to a scenario, with what value, and why.
 *
 *   npm run evaluate -- examples/brisbane_shed_pool.json          markdown report (same as examples/*.out.md)
 *   npm run evaluate -- examples/brisbane_shed_pool.json --json   full result
 */
import fs from "node:fs";
import path from "node:path";
import { Db } from "../core/db.js";
import { loadEnv } from "../core/env.js";
import * as evaluate from "../core/evaluate.js";
import { parseArgs, usage } from "./args.js";
import { exit } from "./fmt.js";

async function main(): Promise<number> {
  const a = parseArgs(process.argv.slice(2), { booleans: ["json"] });
  if (!a._[0]) usage("usage: npm run evaluate -- <scenario.json> [--json]");
  // npm runs scripts inside server-ts/; resolve the path against the directory the command was typed in
  const file = path.resolve(process.env.INIT_CWD ?? process.cwd(), a._[0]);
  const scenario: evaluate.Scenario = JSON.parse(fs.readFileSync(file, "utf-8"));
  loadEnv();
  const db = new Db({ host: a.host, port: a.port, database: a.db, user: a.user });
  try {
    const res = await evaluate.resolve(db, scenario);
    process.stdout.write(a.json ? JSON.stringify(res, null, 1) + "\n" : evaluate.render(scenario, res));
  } finally {
    await db.close();
  }
  return 0;
}

main().then(exit, (e) => { console.error(e); exit(1); });
