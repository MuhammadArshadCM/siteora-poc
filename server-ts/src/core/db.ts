import pg from "pg";

export interface DbOptions {
  host?: string;
  port?: number;
  database?: string;
  user?: string;
  password?: string;
  max?: number;
}

/**
 * Database access through the pg driver (a connection pool) instead of the psql command line.
 * q() keeps the Python contract: the SQL returns one JSON value (json_agg / coalesce(...,'[]')) and q() returns it parsed.
 */
export class Db {
  readonly pool: pg.Pool;
  readonly database: string;
  readonly host: string;
  readonly port: number;

  constructor(opts: DbOptions = {}) {
    this.host = opts.host ?? process.env.PGHOST ?? "localhost";
    this.port = Number(opts.port ?? process.env.PGPORT ?? 5432);
    this.database = opts.database ?? process.env.PGDATABASE ?? "siteora";
    this.pool = new pg.Pool({
      host: this.host, port: this.port, database: this.database,
      user: opts.user ?? process.env.PGUSER ?? "postgres",
      password: opts.password ?? process.env.PGPASSWORD,
      max: opts.max ?? 10,
    });
    // an idle connection that drops (PostgreSQL restarted, network blip) emits 'error' on the pool; without a listener
    // Node stops the whole server. Log it; the pool opens a new connection for the next query.
    this.pool.on("error", (e) => console.warn(`Database connection lost (${e.message}); it will reconnect on the next query.`));
  }

  async q<T = any>(sql: string): Promise<T> {
    let res;
    try {
      res = await this.pool.query({ text: sql, rowMode: "array" });
    } catch (e) {
      throw databaseError(e, this) ?? e;
    }
    if (!res.rows.length || res.rows[0][0] === null || res.rows[0][0] === undefined) return [] as T;
    const v = res.rows[0][0];
    return (typeof v === "string" ? JSON.parse(v) : v) as T;   // json columns arrive parsed; text arrives as JSON text
  }

  async close(): Promise<void> {
    await this.pool.end();
  }
}

/** The database cannot be used (not running, wrong password, database or schema missing). The API answers 503 with
 *  a message that says what to fix, instead of a 500 and a stack trace. */
export class DatabaseUnavailable extends Error {
  constructor(message: string) {
    super(message);
    this.name = "DatabaseUnavailable";
  }
}

function databaseError(e: any, db: Db): DatabaseUnavailable | null {
  const where = `PostgreSQL at ${db.host}:${db.port}, database '${db.database}'`;
  const code = e?.code ?? e?.cause?.code;
  const msg = String(e?.message ?? "");
  if (["ECONNREFUSED", "ENOTFOUND", "ETIMEDOUT", "EAI_AGAIN"].includes(code))
    return new DatabaseUnavailable(`Cannot connect to ${where}: is PostgreSQL running? (${code})`);
  if (code === "28P01" || code === "28000" || /password must be a string|password authentication failed/i.test(msg))
    return new DatabaseUnavailable(`${where} rejected the login: check PG_PASSWORD in poc/.env (or PGPASSWORD).`);
  if (code === "3D000") return new DatabaseUnavailable(`${where} does not exist: create it and load db/load_all.sql.`);
  if (code === "42P01" || code === "3F000" || code === "42883")
    return new DatabaseUnavailable(`The rules dataset is not loaded in ${where} (${msg}): run db/load_all.sql.`);
  if (code === "57P01" || code === "57P03") return new DatabaseUnavailable(`${where} is shutting down or starting up: try again shortly.`);
  return null;
}

/** SQL string literal (Python _lit). */
export function lit(s: unknown): string {
  return "'" + String(s).replace(/'/g, "''") + "'";
}
