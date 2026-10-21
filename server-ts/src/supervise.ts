/**
 * `npm start`: runs the server and keeps it running.
 *   - If the server stops unexpectedly it is started again after 1, 2, 4 … up to 30 seconds (the wait resets once it
 *     has run for a minute). Exit code 2 (e.g. port already in use) is a configuration problem: no restart.
 *   - Everything the server prints also goes to server-ts/logs/server.log (with times), so the reason for a stop can be
 *     read afterwards. The log is rotated to server.log.1 when it passes 5 MB.
 *   - Ctrl+C stops the server cleanly and does not restart it.
 * For development use `npm run dev` instead (rebuild and restart on every code change).
 */
import { spawn, type ChildProcess } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SERVER = path.join(HERE, "index.js");
const LOG_DIR = path.resolve(HERE, "..", "..", "logs");
const LOG = path.join(LOG_DIR, "server.log");
fs.mkdirSync(LOG_DIR, { recursive: true });

function rotate() {
  try {
    if (fs.statSync(LOG).size > 5 * 1024 * 1024) fs.renameSync(LOG, LOG + ".1");
  } catch { /* no log yet */ }
}

function log(line: string) {
  rotate();
  fs.appendFileSync(LOG, line.endsWith("\n") ? line : line + "\n");
}

const stamp = () => new Date().toISOString();
let child: ChildProcess | null = null;
let stopping = false;
let delay = 1000;

function start() {
  const startedAt = Date.now();
  log(`${stamp()} [supervisor] starting the server`);
  child = spawn(process.execPath, [SERVER], { stdio: ["ignore", "pipe", "pipe"], env: process.env });
  for (const [stream, out] of [[child.stdout!, process.stdout], [child.stderr!, process.stderr]] as const)
    stream.on("data", (chunk: Buffer) => { out.write(chunk); log(chunk.toString()); });
  child.on("exit", (code, signal) => {
    child = null;
    if (stopping) return;
    const ran = Date.now() - startedAt;
    if (code === 2) {
      const msg = `${stamp()} [supervisor] the server stopped with a configuration problem (see above): not restarting`;
      console.error(msg); log(msg);
      process.exit(2);
    }
    if (ran > 60_000) delay = 1000;   // it was healthy for a while: restart quickly
    const msg = `${stamp()} [supervisor] the server stopped (${signal ?? `exit code ${code}`}) after ${Math.round(ran / 1000)} s; `
      + `restarting in ${delay / 1000} s. Details: ${LOG}`;
    console.error(msg); log(msg);
    setTimeout(start, delay);
    delay = Math.min(delay * 2, 30_000);
  });
}

function stop(signal: NodeJS.Signals) {
  stopping = true;
  log(`${stamp()} [supervisor] ${signal}: stopping the server`);
  if (!child) process.exit(0);
  child.once("exit", () => process.exit(0));
  child.kill(signal);
  setTimeout(() => process.exit(0), 6000).unref();
}
process.on("SIGINT", () => stop("SIGINT"));
process.on("SIGTERM", () => stop("SIGTERM"));

console.log(`Server log: ${LOG}`);
start();
