import { loadEnv } from "./core/env.js";

loadEnv();   // poc/.env (PG_PASSWORD …) before anything reads process.env

const PORT = Number(process.env.POC_PORT ?? 8766);
const stamp = () => new Date().toISOString();

// Last line of defence: an error nothing else caught. Log it with a time so the cause can be found in the log, then
// stop (the process state is unknown); `npm start` runs under the supervisor, which starts a fresh server.
process.on("uncaughtException", (e) => {
  console.error(`${stamp()} [fatal] uncaught exception — restarting:`, e);
  process.exit(1);
});
// A promise that failed without a handler: log it and keep serving (the request that caused it already answered).
process.on("unhandledRejection", (e) => {
  console.error(`${stamp()} [error] unhandled promise rejection (server keeps running):`, e);
});

const { PlatformExpress } = await import("@tsed/platform-express");
const { Server } = await import("./Server.js");

let platform: Awaited<ReturnType<typeof PlatformExpress.bootstrap>>;
try {
  platform = await PlatformExpress.bootstrap(Server);
  await platform.listen();
} catch (e) {
  const err = e as NodeJS.ErrnoException;
  if (err.code === "EADDRINUSE") {
    console.error(`${stamp()} Port ${PORT} is already in use: another copy of the server is probably running. `
      + `Stop it (or close its terminal), or start this one on another port: set POC_PORT=${PORT + 1}.`);
    process.exit(2);   // 2 = configuration problem: the supervisor does not retry
  }
  console.error(`${stamp()} [fatal] the server could not start:`, err);
  process.exit(1);
}
console.log(`Siteora API (Ts.ED) on http://localhost:${PORT}`);

// Start-up check: say clearly if the database or the State services are not usable (the server still runs, and
// recovers by itself when they come back; GET /api/health repeats this check at any time).
{
  const { health } = await import("./core/health.js");
  const { Db } = await import("./core/db.js");
  const db = new Db({ max: 1 });
  try {
    const h = await health(db);
    console.log(`${stamp()} Health: ${h.summary}`);
    // the summary already names a failing database / State service; list the council services that are not answering
    for (const c of h.councils.filter((c) => !c.ok)) console.warn(`  - ${c.name}: ${c.detail}`);
  } finally {
    await db.close();
  }
}

let stopping = false;
async function shutdown(signal: string) {
  if (stopping) return;
  stopping = true;
  console.log(`${stamp()} ${signal}: stopping`);
  const force = setTimeout(() => process.exit(0), 5000);   // do not hang on open connections
  force.unref();
  try {
    await platform.stop();
  } finally {
    process.exit(0);
  }
}
process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
