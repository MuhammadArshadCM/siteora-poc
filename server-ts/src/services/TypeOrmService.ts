import { Injectable, OnDestroy, OnInit } from "@tsed/di";
import type { DataSource } from "typeorm";
import { AppDataSource } from "../core/datasource.js";

/**
 * DI-managed lifecycle wrapper around the migrations DataSource (core/datasource.ts), so the app connects
 * on startup and disconnects on shutdown the same way DbService does for the pg.Pool. Not used for
 * runtime rule queries (see datasource.ts's header comment) — today this only backs
 * GET /api/admin/migrations, which exists so a production operator can see which migrations (schema_
 * migrations table) have actually been applied to this database, instead of having to guess from which
 * db/*.sql files someone remembers running by hand.
 *
 * Connecting is best-effort at startup: a DB hiccup during deploy must not stop the whole server coming
 * up (same philosophy as index.ts's own startup health check) — failure here just means the migrations
 * endpoint reports unavailable until the next lazy retry.
 */
@Injectable()
export class TypeOrmService implements OnInit, OnDestroy {
  readonly dataSource: DataSource = AppDataSource;

  async $onInit(): Promise<void> {
    try {
      if (!this.dataSource.isInitialized) await this.dataSource.initialize();
    } catch (e) {
      console.warn(`${new Date().toISOString()} TypeORM DataSource did not connect at startup (will retry lazily on next use): ${(e as Error).message}`);
    }
  }

  async $onDestroy(): Promise<void> {
    if (this.dataSource.isInitialized) await this.dataSource.destroy();
  }

  private async ensureInitialized(): Promise<void> {
    if (!this.dataSource.isInitialized) await this.dataSource.initialize();
  }

  /** Migrations actually applied to this database (schema_migrations table), most recent first. */
  async appliedMigrations(): Promise<Array<{ id: number; timestamp: string; name: string }>> {
    await this.ensureInitialized();
    return this.dataSource.query(`SELECT id, timestamp, name FROM public.schema_migrations ORDER BY id DESC`);
  }
}
