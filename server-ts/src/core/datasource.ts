import "reflect-metadata";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { DataSource } from "typeorm";
import { loadEnv, ROOT } from "./env.js";

loadEnv();   // poc/.env (PG_PASSWORD -> PGPASSWORD etc.) before reading process.env below — same as index.ts

const here = path.dirname(fileURLToPath(import.meta.url));

/**
 * Owns schema migrations only (src/migrations/ — one class per historical db/*.sql file, replayed
 * verbatim, plus new migrations written directly against TypeORM from here on; see README). The app's
 * own query layer (core/db.ts's Db/pg.Pool, used by RulesService/BlockedSourcesService) is untouched —
 * TypeORM is the migration framework here, not the runtime ORM. That hand-rolled query-building pattern
 * (SQL that returns one json_agg() value, parsed in Db.q()) is deeply embedded through engine.ts; moving
 * runtime queries onto TypeORM entities/repositories would be a much larger, separate rewrite with real
 * correctness risk for a rules engine this size, and isn't what "fix the missing migration tracking"
 * calls for.
 *
 * CLI usage (from server-ts/, after `npm run build`):
 *   npx typeorm migration:run    -d dist/src/core/datasource.js
 *   npx typeorm migration:revert -d dist/src/core/datasource.js
 *   npx typeorm migration:show   -d dist/src/core/datasource.js
 * (or the npm scripts: npm run migration:run / migration:revert / migration:show)
 */
export const AppDataSource = new DataSource({
  type: "postgres",
  host: process.env.PGHOST ?? "localhost",
  port: Number(process.env.PGPORT ?? 5432),
  database: process.env.PGDATABASE ?? "siteora",
  username: process.env.PGUSER ?? "postgres",
  password: process.env.PGPASSWORD,
  // Pinned explicitly: the last migration (SetDefaultSearchPath) sets this database's own default
  // search_path to "regs, public" for the app's own connections — without this, TypeORM would resolve
  // schema_migrations against whatever the connection's current search_path happens to be and silently
  // stop seeing its own tracking table on every connection after that migration runs (found by testing
  // this exact sequence against a scratch database).
  schema: "public",
  entities: [],
  migrations: [path.join(here, "..", "migrations", "*.js")],
  migrationsTableName: "schema_migrations",
  synchronize: false,
  logging: ["error", "warn", "migration"],
});
