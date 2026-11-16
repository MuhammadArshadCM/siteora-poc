import fs from "node:fs";
import path from "node:path";
import { Controller, Inject } from "@tsed/di";
import { PathParams, QueryParams } from "@tsed/platform-params";
import { Req, Res } from "@tsed/platform-http";
import { Get, Post } from "@tsed/schema";
import type { Request, Response } from "express";
import { POC_DIR, SOURCES_DIR } from "../core/env.js";
import { geoCacheStats } from "../core/geo.js";
import { BlockedSourcesService } from "../services/BlockedSourcesService.js";
import { TypeOrmService } from "../services/TypeOrmService.js";

const PAGE = path.join(POC_DIR, "static", "admin-blocked-sources.html");
const MAX_UPLOAD_BYTES = 50 * 1024 * 1024;   // 50MB — see upload()'s request.destroy() below

/**
 * Admin page for sources that return HTTP 403 (or similar) to automated fetching, tracked in regs.blocked_sources
 * (db/067). An admin can see them in one place, upload a document they fetched by hand in a browser, or mark the
 * block moot because the council has since adopted the Queensland Housing Code.
 *   GET  /admin/blocked-sources                 the page
 *   GET  /api/admin/blocked-sources              the list, as JSON
 *   POST /api/admin/blocked-sources/:id/upload   raw file body; ?filename=... names it. Saved under
 *                                                 research/sources/<lg_id or 'STATE'>/
 *   POST /api/admin/blocked-sources/:id/qhc-opted  mark QHC_OPTED_UNBLOCKED; resolves the linked open_issue too
 *   GET  /api/admin/migrations                   TypeORM schema_migrations rows actually applied to this DB
 * TODO before production: none of this is authenticated — see the production-readiness review. Put a
 * shared bearer-token check in front of everything under /admin and /api/admin before this is reachable
 * from outside localhost.
 */
@Controller("/")
export class AdminController {
  @Inject()
  protected sources!: BlockedSourcesService;

  @Inject()
  protected typeorm!: TypeOrmService;

  @Get("/admin/blocked-sources")
  page(@Res() res: Response) {
    res.type("text/html; charset=utf-8").send(fs.readFileSync(PAGE, "utf-8"));
  }

  @Get("/api/admin/blocked-sources")
  async list(@Res() res: Response) {
    try {
      res.status(200).json(await this.sources.list());
    } catch (e) {
      res.status(500).json({ error: String((e as Error).message) });
    }
  }

  @Post("/api/admin/blocked-sources/:id/upload")
  async upload(@PathParams("id") id: string, @QueryParams("filename") filename: string | undefined, @Req() req: Request, @Res() res: Response) {
    try {
      const row = await this.sources.get(Number(id));
      if (!row) return void res.status(404).json({ error: `No blocked source with id ${id}` });

      const chunks: Buffer[] = [];
      let total = 0;
      let tooLarge = false;
      await new Promise<void>((resolve, reject) => {
        req.on("data", (c: Buffer) => {
          total += c.length;
          if (total > MAX_UPLOAD_BYTES) {
            tooLarge = true;
            req.destroy();   // stop reading further bytes; 'error' fires next, caught below
            return;
          }
          chunks.push(c);
        });
        req.on("end", () => resolve());
        req.on("error", (e) => (tooLarge ? resolve() : reject(e)));   // destroy()'s error is expected once tooLarge
      });
      if (tooLarge) return void res.status(413).json({ error: `File too large — limit is ${MAX_UPLOAD_BYTES / (1024 * 1024)}MB.` });
      const body = Buffer.concat(chunks);
      if (!body.length) return void res.status(400).json({ error: "Empty request body — send the file's raw bytes." });

      const safeName = (filename || `upload-${Date.now()}.pdf`).replace(/[^A-Za-z0-9._-]/g, "_");
      const dir = path.join(SOURCES_DIR, row.lg_id || "STATE");
      fs.mkdirSync(dir, { recursive: true });
      const absPath = path.join(dir, safeName);
      fs.writeFileSync(absPath, body);

      const relPath = path.relative(path.join(SOURCES_DIR, ".."), absPath).replace(/\\/g, "/");
      await this.sources.recordUpload(Number(id), relPath);
      res.status(200).json({ ok: true, saved_to: relPath, bytes: body.length });
    } catch (e) {
      res.status(500).json({ error: String((e as Error).message) });
    }
  }

  @Post("/api/admin/blocked-sources/:id/qhc-opted")
  async qhcOpted(@PathParams("id") id: string, @Res() res: Response) {
    try {
      const row = await this.sources.get(Number(id));
      if (!row) return void res.status(404).json({ error: `No blocked source with id ${id}` });
      await this.sources.markQhcOpted(Number(id));
      res.status(200).json({ ok: true });
    } catch (e) {
      res.status(500).json({ error: String((e as Error).message) });
    }
  }

  /** Which TypeORM migrations (src/migrations/) have actually been applied to this database — see core/datasource.ts. */
  @Get("/api/admin/migrations")
  async migrations(@Res() res: Response) {
    try {
      res.status(200).json(await this.typeorm.appliedMigrations());
    } catch (e) {
      res.status(503).json({ error: `Could not read schema_migrations: ${(e as Error).message}` });
    }
  }

  /** In-memory external-API response cache stats (hits/misses since process start) — see core/geo.ts's getJson(). */
  @Get("/api/admin/cache-stats")
  cacheStats(@Res() res: Response) {
    res.status(200).json(geoCacheStats());
  }
}
