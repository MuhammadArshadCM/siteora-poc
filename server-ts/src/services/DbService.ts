import { Injectable, OnDestroy } from "@tsed/di";
import { Db } from "../core/db.js";

/** One connection pool for the whole app (PGHOST / PGPORT / PGDATABASE / PGUSER / PGPASSWORD, or poc/.env). */
@Injectable()
export class DbService extends Db implements OnDestroy {
  constructor() {
    super();
  }

  async $onDestroy(): Promise<void> {
    await this.close();
  }
}
