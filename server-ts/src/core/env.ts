import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

/** Repository root (…/siteora poc). Compiled files live in server-ts/dist/src/core. */
export const ROOT = process.env.SITEORA_ROOT
  ?? path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..", "..", "..");
export const POC_DIR = path.join(ROOT, "poc");

const ALIASES: Record<string, string> = {
  PG_PASSWORD: "PGPASSWORD", PG_HOST: "PGHOST", PG_PORT: "PGPORT", PG_DATABASE: "PGDATABASE", PG_USER: "PGUSER",
};

/** Same rules as poc/siteora_poc/__init__.py: KEY = VALUE lines from poc/.env; real environment variables win. */
export function loadEnv(file = path.join(POC_DIR, ".env")): void {
  if (!fs.existsSync(file)) return;
  for (let line of fs.readFileSync(file, "utf-8").replace(/^﻿/, "").split(/\r?\n/)) {
    line = line.trim();
    if (!line || line.startsWith("#") || !line.includes("=")) continue;
    const i = line.indexOf("=");
    const key = line.slice(0, i).trim();
    const value = line.slice(i + 1).trim().replace(/^['"]|['"]$/g, "");
    for (const k of [key, ALIASES[key]]) if (k && process.env[k] === undefined) process.env[k] = value;
  }
}

export function readJson<T = any>(file: string, fallback: T): T {
  return fs.existsSync(file) ? (JSON.parse(fs.readFileSync(file, "utf-8")) as T) : fallback;
}

/** Local date as YYYY-MM-DD (Python dt.date.today().isoformat()). */
export function today(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}
