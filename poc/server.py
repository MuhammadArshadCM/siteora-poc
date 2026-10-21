# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/Server.ts + server-ts/src/controllers/RulesController.ts (npm start)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Local web app + JSON API.
#
#   python -I poc/server.py            -> http://localhost:8765
#   GET /api/rules?address=...&structure=SHED&height_m=3&length_m=6&width_m=4[&zone_id=...&precinct=...&date=...]
#   GET /api/zones?lg_id=BRISBANE      -> zones / precincts for a council (for the manual zone picker)
#
# Database: poc/.env (PG_PASSWORD = ...; see .env.example) or PGHOST / PGPORT / PGDATABASE / PGUSER / PGPASSWORD
# (defaults localhost:5432/siteora/postgres; environment variables win over .env).
# """
# import http.server
# import json
# import os
# import pathlib
# import sys
# import traceback
# import urllib.parse
#
# sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
# from siteora_poc import engine  # noqa: E402
#
# PORT = int(os.environ.get("POC_PORT", "8765"))
# DB = engine.Db(os.environ.get("PGHOST", "localhost"), os.environ.get("PGPORT", "5432"),
#                os.environ.get("PGDATABASE", "siteora"), os.environ.get("PGUSER", "postgres"))
# PAGE = (pathlib.Path(__file__).resolve().parent / "static" / "index.html").read_text(encoding="utf-8")
#
#
# class Handler(http.server.BaseHTTPRequestHandler):
#     def _send(self, code, body, ctype="application/json; charset=utf-8"):
#         data = body.encode("utf-8") if isinstance(body, str) else body
#         self.send_response(code)
#         self.send_header("Content-Type", ctype)
#         self.send_header("Content-Length", str(len(data)))
#         self.end_headers()
#         self.wfile.write(data)
#
#     def do_GET(self):
#         url = urllib.parse.urlparse(self.path)
#         qs = {k: v if len(v) > 1 else v[0] for k, v in urllib.parse.parse_qs(url.query).items()}
#         try:
#             if url.path == "/":
#                 return self._send(200, PAGE, "text/html; charset=utf-8")
#             if url.path == "/api/zones":
#                 zones, precincts = engine.council_places(DB, qs["lg_id"])
#                 return self._send(200, json.dumps({"zones": zones, "precincts": precincts}))
#             if url.path == "/api/rules":
#                 precincts = qs.get("precinct")
#                 precincts = [precincts] if isinstance(precincts, str) else precincts
#                 res = engine.run(DB, qs.get("structure", "SHED"), qs, address=qs.get("address"),
#                                  lon=float(qs["lon"]) if qs.get("lon") else None, lat=float(qs["lat"]) if qs.get("lat") else None,
#                                  zone_id=qs.get("zone_id") or None, precincts=precincts, assessment_date=qs.get("date") or None)
#                 return self._send(200, json.dumps(res, ensure_ascii=False, default=str))
#             return self._send(404, json.dumps({"error": "not found"}))
#         except (LookupError, ValueError) as e:
#             return self._send(400, json.dumps({"error": str(e)}))
#         except Exception as e:  # noqa: BLE001 — POC: surface the error to the page
#             traceback.print_exc()
#             return self._send(500, json.dumps({"error": f"{type(e).__name__}: {e}"}))
#
#     def log_message(self, fmt, *args):
#         sys.stderr.write("%s\n" % (fmt % args))
#
#
# if __name__ == "__main__":
#     print(f"Siteora POC on http://localhost:{PORT}  (database {DB.db} on {DB.host}:{DB.port})", flush=True)
#     http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
