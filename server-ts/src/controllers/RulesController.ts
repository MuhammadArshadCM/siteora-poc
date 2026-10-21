import fs from "node:fs";
import path from "node:path";
import { Controller, Inject } from "@tsed/di";
import { QueryParams } from "@tsed/platform-params";
import { Res } from "@tsed/platform-http";
import { Get } from "@tsed/schema";
import type { Response } from "express";
import { POC_DIR } from "../core/env.js";
import * as features from "../core/features.js";
import { randomUUID } from "node:crypto";
import { DatabaseUnavailable } from "../core/db.js";
import { ServiceUnavailable } from "../core/geo.js";
import { health } from "../core/health.js";
import { LookupError, ValueError } from "../core/py.js";
import { RulesService } from "../services/RulesService.js";

const PAGE = path.join(POC_DIR, "static", "index.html");

/**
 * Same HTTP contract as poc/server.py, so poc/static/index.html works unchanged:
 *   GET /                          the web page
 *   GET /api/rules?address=...&structure=SHED&height_m=3&length_m=6&width_m=4[&zone_id=&precinct=&date=&lon=&lat=]
 *   GET /api/zones?lg_id=BRISBANE
 *   GET /api/features?layer=<configured layer URL>&bbox=xmin,ymin,xmax,ymax   (map drawing: features clipped to the view)
 *   GET /api/health                 database, rules dataset and State map services reachable?
 * Errors: {"error": "..."} with 400 (bad input / not found), 503 (database or a required map service unavailable:
 * the message says what to fix) or 500 (a fault in the code; the message carries a reference to the server log).
 */
@Controller("/")
export class RulesController {
  @Inject()
  protected rules!: RulesService;

  @Get("/")
  page(@Res() res: Response) {
    res.type("text/html; charset=utf-8").send(fs.readFileSync(PAGE, "utf-8"));
  }

  @Get("/api/zones")
  async zones(@QueryParams() qs: Record<string, any>, @Res() res: Response) {
    return this.reply(res, () => this.rules.zones(String(qs.lg_id ?? "")));
  }

  @Get("/api/rules")
  async rulesFor(@QueryParams() qs: Record<string, any>, @Res() res: Response) {
    return this.reply(res, () => {
      const one = (v: any) => (Array.isArray(v) ? v[v.length - 1] : v);   // like parse_qs + single-value collapse
      const inputs: Record<string, any> = {};
      for (const [k, v] of Object.entries(qs)) if (v !== "") inputs[k] = Array.isArray(v) ? v : String(v);
      const precinct = qs.precinct;
      return this.rules.run(String(one(qs.structure) || "SHED"), Object.fromEntries(Object.entries(inputs).map(([k, v]) => [k, one(v)])), {
        address: one(qs.address) || null,
        lon: one(qs.lon) ? Number(one(qs.lon)) : null,
        lat: one(qs.lat) ? Number(one(qs.lat)) : null,
        zoneId: one(qs.zone_id) || null,
        precincts: precinct === undefined || precinct === "" ? null : Array.isArray(precinct) ? precinct : [String(precinct)],
        assessmentDate: one(qs.date) || null,
      });
    });
  }

  /** Is everything the app needs reachable? 200 when all is well, 503 otherwise (with what is wrong). */
  @Get("/api/health")
  async healthCheck(@Res() res: Response) {
    const h = await health(this.rules.db);
    res.status(h.ok ? 200 : 503).json(h);
  }

  /** A configured map layer's features clipped to the view (see core/features.ts). */
  @Get("/api/features")
  async features(@QueryParams() qs: Record<string, any>, @Res() res: Response) {
    return this.reply(res, () => features.featuresInBox(String(qs.layer ?? ""), features.parseBox(qs.bbox)));
  }

  private async reply(res: Response, fn: () => Promise<unknown>) {
    try {
      res.status(200).json(await fn());
    } catch (e) {
      const err = e as Error;
      if (err instanceof LookupError || err instanceof ValueError) {
        res.status(400).json({ error: err.message });
      } else if (err instanceof ServiceUnavailable || err instanceof DatabaseUnavailable) {
        console.warn(`${new Date().toISOString()} ${err.message}`);   // one line: not a code fault, no stack trace
        res.status(503).json({ error: err.message });
      } else {
        // a fault in our code: full detail in the server log, a reference the user can quote
        const ref = randomUUID().slice(0, 8);
        console.error(`${new Date().toISOString()} [error ${ref}]`, err);
        res.status(500).json({ error: `Internal error (${err.name}: ${err.message}). Reference ${ref} in the server log.`, ref });
      }
    }
  }
}
