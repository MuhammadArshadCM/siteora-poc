import { Inject, Injectable } from "@tsed/di";
import { DbService } from "./DbService.js";

export interface BlockedSource {
  id: number;
  issue_id: number | null;
  lg_id: string | null;
  label: string;
  url: string | null;
  status: "BLOCKED" | "DOCUMENT_UPLOADED" | "QHC_OPTED_UNBLOCKED";
  uploaded_file_path: string | null;
  uploaded_at: string | null;
  notes: string | null;
}

/**
 * Council/department sources that 403 to automated fetching (regs.blocked_sources, db/067). Lets an admin see
 * them in one place, record that they fetched a replacement document by hand, or mark the block moot because the
 * council has since adopted the Queensland Housing Code. Uses the pool directly (not Db.q(), which assumes a
 * single JSON-returning SELECT) since this service also writes.
 */
@Injectable()
export class BlockedSourcesService {
  @Inject()
  readonly db!: DbService;

  async list(): Promise<BlockedSource[]> {
    const res = await this.db.pool.query(
      `SELECT blocked_source_id AS id, issue_id, lg_id, label, url, status, uploaded_file_path, uploaded_at, notes
       FROM regs.blocked_sources ORDER BY lg_id NULLS FIRST, blocked_source_id`
    );
    return res.rows;
  }

  async get(id: number): Promise<BlockedSource | null> {
    const res = await this.db.pool.query(
      `SELECT blocked_source_id AS id, issue_id, lg_id, label, url, status, uploaded_file_path, uploaded_at, notes
       FROM regs.blocked_sources WHERE blocked_source_id = $1`,
      [id]
    );
    return res.rows[0] ?? null;
  }

  /** Record that an admin fetched the document by hand and saved it under research/sources/. */
  async recordUpload(id: number, relPath: string): Promise<void> {
    await this.db.pool.query(
      `UPDATE regs.blocked_sources SET status = 'DOCUMENT_UPLOADED', uploaded_file_path = $2, uploaded_at = now()
       WHERE blocked_source_id = $1`,
      [id, relPath]
    );
  }

  /** The council has since adopted the QHC: this block no longer matters the way it did. Closes the linked
   *  open_issue too, if there is one — the admin decided it is resolved by visiting this page. */
  async markQhcOpted(id: number): Promise<void> {
    const row = await this.get(id);
    if (!row) return;
    await this.db.pool.query(`UPDATE regs.blocked_sources SET status = 'QHC_OPTED_UNBLOCKED' WHERE blocked_source_id = $1`, [id]);
    if (row.issue_id != null) {
      await this.db.pool.query(`UPDATE regs.open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = $1 AND resolved_at IS NULL`, [row.issue_id]);
    }
  }
}
