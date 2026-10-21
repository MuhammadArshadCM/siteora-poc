# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/parity/golden/*.json (the Python results it produced, recorded 2026-10-16)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Python reference outputs for the parity test (run by parity.ts; not used in production).
#
#   python -I py_dump.py examples <out.json>             evaluate.resolve() for every examples/*.json
#   python -I py_dump.py engine <cases.json> <out.json>  engine.run() for every case
# """
# import json
# import pathlib
# import sys
#
# ROOT = pathlib.Path(__file__).resolve().parents[2]
# sys.path.insert(0, str(ROOT / "poc"))
# sys.path.insert(0, str(ROOT / "tools"))
# from siteora_poc import engine  # noqa: E402  (also loads poc/.env)
# import evaluate  # noqa: E402
#
# DB = engine.Db()
#
#
# def examples(out):
#     res = {}
#     for p in sorted((ROOT / "examples").glob("*.json")):
#         res[p.name] = evaluate.resolve(DB, json.loads(p.read_text(encoding="utf-8")))
#     pathlib.Path(out).write_text(json.dumps(res, ensure_ascii=False, default=str), encoding="utf-8")
#
#
# def engine_cases(cases_file, out):
#     res = {}
#     for c in json.loads(pathlib.Path(cases_file).read_text(encoding="utf-8")):
#         try:
#             res[c["id"]] = {"ok": engine.run(DB, c["structure"], c.get("inputs", {}), address=c.get("address"), lon=c.get("lon"),
#                                             lat=c.get("lat"), zone_id=c.get("zone_id"), precincts=c.get("precincts"),
#                                             assessment_date=c.get("date"))}
#         except (LookupError, ValueError) as e:
#             res[c["id"]] = {"error": str(e)}
#     pathlib.Path(out).write_text(json.dumps(res, ensure_ascii=False, default=str), encoding="utf-8")
#
#
# if __name__ == "__main__":
#     sys.stdout.reconfigure(encoding="utf-8")
#     if sys.argv[1] == "examples":
#         examples(sys.argv[2])
#     else:
#         engine_cases(sys.argv[2], sys.argv[3])
