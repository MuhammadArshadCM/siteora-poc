# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/tools/check-services.ts (npm run check-services)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Health check for every map service in poc/zoning_layers.json.
#
#   python -I poc/check_services.py              # all councils
#   python -I poc/check_services.py LOGAN        # one council
#
# For each configured layer: is it reachable without a login, does the configured field still exist, and when was
# its data last edited. Run it monthly or when a lookup starts failing. To update a source, edit the URL / field in
# poc/zoning_layers.json and run this again (see docs/13-map-services.md).
# """
# import datetime as dt
# import pathlib
# import sys
#
# sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
# from siteora_poc import geo, zoning  # noqa: E402
#
#
# def layers(cfg):
#     """(purpose, url, field) for every layer a council config uses."""
#     if cfg.get("zone_layer"):
#         yield "zone", cfg["zone_layer"], cfg.get("zone_field")
#         if cfg.get("precinct_field"):
#             yield "zone precinct (same layer)", cfg["zone_layer"], cfg["precinct_field"]
#         if cfg.get("local_plan_field"):
#             yield "local plan (same layer)", cfg["zone_layer"], cfg["local_plan_field"]
#     for u in cfg.get("precinct_layers", []):
#         yield "zone precinct", u, cfg.get("precinct_layer_field")
#     if cfg.get("local_plan_layer"):
#         yield "local plan", cfg["local_plan_layer"], cfg.get("local_plan_layer_field")
#     if cfg.get("local_plan_precinct_layer"):
#         yield "local plan precinct", cfg["local_plan_precinct_layer"], cfg.get("local_plan_precinct_name_field") or cfg.get("local_plan_precinct_code_field")
#     for ov in cfg.get("overlay_layers", []):
#         yield "overlay: " + ov["name"], ov["layer"], ov["field"]
#
#
# def check(url, field):
#     try:
#         j = geo.get_json(url, {"f": "json"}, timeout=30)
#     except Exception as e:  # noqa: BLE001 — report every failure, keep going
#         return "FAIL", str(e)[:90], None
#     fields = {f["name"] for f in j.get("fields", [])}
#     if field and fields and field not in fields:
#         return "FIELD?", f"'{field}' missing; fields: {', '.join(sorted(fields))[:80]}", j.get("name")
#     ts = (j.get("editingInfo") or {}).get("dataLastEditDate") or (j.get("editingInfo") or {}).get("lastEditDate")
#     edited = dt.datetime.fromtimestamp(ts / 1000, dt.timezone.utc).date().isoformat() if ts else "n/a (MapServer)"
#     return "OK", f"data last edited {edited}", j.get("name")
#
#
# def main():
#     sys.stdout.reconfigure(encoding="utf-8")
#     cfg = zoning.load_config()
#     want = [a.upper() for a in sys.argv[1:]] or [k for k in cfg if not k.startswith("_")]
#     bad = 0
#     for lg in want:
#         c = cfg[lg]
#         print(f"\n{lg}  [{c.get('status')}]  scheme: {c.get('scheme_viewer') or '-'}")
#         if c.get("status") != "WORKING":
#             print(f"  skipped: {c.get('notes')}")
#             continue
#         for purpose, url, field in layers(c):
#             status, msg, name = check(url, field)
#             bad += status != "OK"
#             print(f"  {status:6} {purpose:55} {name or '':38} {msg}\n         {url}")
#     print(f"\n{'All layers OK' if not bad else f'{bad} layer(s) need attention'}")
#     sys.exit(1 if bad else 0)
#
#
# if __name__ == "__main__":
#     main()
