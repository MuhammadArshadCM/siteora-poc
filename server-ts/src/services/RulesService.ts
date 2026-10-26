import { Inject, Injectable } from "@tsed/di";
import * as engine from "../core/engine.js";
import { logSearch } from "../core/searchlog.js";
import { DbService } from "./DbService.js";

/** Thin Ts.ED wrapper around the framework-free engine (src/core), so the core stays testable on its own. */
@Injectable()
export class RulesService {
  @Inject()
  readonly db!: DbService;

  async run(structure: string, inputs: Record<string, any>, opts: engine.RunOptions) {
    const result = await engine.run(this.db, structure, inputs, opts);
    logSearch(opts.address || `${opts.lat}, ${opts.lon}`, structure, result);
    return result;
  }

  async zones(lgId: string) {
    const [zones, precincts] = await engine.councilPlaces(this.db, lgId);
    return { zones, precincts };
  }
}
