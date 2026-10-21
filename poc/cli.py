# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/tools/cli.ts (npm run cli)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Command line: python -I poc/cli.py "15 Jubilee Terrace, Bardon QLD 4065" --structure SHED --height 3 --length 6 --width 4
#
# Prints the applicable rules per boundary with their source clause. --json prints the full response.
# Database connection: poc/.env (PG_PASSWORD = ...; see .env.example) or PGHOST / PGPORT / PGDATABASE / PGUSER / PGPASSWORD
# (defaults localhost:5432/siteora/postgres; environment variables win over .env).
# """
# import argparse
# import json
# import os
# import pathlib
# import sys
#
# sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
# from siteora_poc import engine  # noqa: E402
#
#
# def main():
#     ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
#     ap.add_argument("address", nargs="?")
#     ap.add_argument("--lon", type=float)
#     ap.add_argument("--lat", type=float)
#     ap.add_argument("--structure", default="SHED", choices=sorted(engine.STRUCTURES))
#     ap.add_argument("--height", dest="height_m")
#     ap.add_argument("--length", dest="length_m")
#     ap.add_argument("--width", dest="width_m")
#     ap.add_argument("--mean-height", dest="mean_height_m")
#     ap.add_argument("--slope", dest="lot_slope_pct", help="lot slope %%")
#     ap.add_argument("--window-distance", dest="window_distance_m", help="distance to neighbour's habitable window (m)")
#     ap.add_argument("--corner", dest="is_corner_lot", action="store_const", const="yes", help="lot is on a road corner")
#     ap.add_argument("--canal", dest="adjoins_canal_or_lake", action="store_const", const="yes", help="lot adjoins a canal or lake")
#     ap.add_argument("--attached", dest="is_attached_to_dwelling", default="no")
#     ap.add_argument("--roofed", dest="is_roofed", default="yes")
#     ap.add_argument("--enclosed", dest="is_enclosed", default="yes")
#     ap.add_argument("--zone", help="zone id override, e.g. BCC:LOW_DENSITY_RESIDENTIAL")
#     ap.add_argument("--precinct", action="append", help="precinct id override (repeatable)")
#     ap.add_argument("--date", help="assessment date YYYY-MM-DD (default today)")
#     ap.add_argument("--json", action="store_true")
#     a = ap.parse_args()
#     if not a.address and (a.lon is None or a.lat is None):
#         ap.error("give an address or --lon/--lat")
#     sys.stdout.reconfigure(encoding="utf-8")
#     db = engine.Db(os.environ.get("PGHOST", "localhost"), os.environ.get("PGPORT", "5432"),
#                    os.environ.get("PGDATABASE", "siteora"), os.environ.get("PGUSER", "postgres"))
#     inputs = {k: v for k, v in vars(a).items() if k.endswith(("_m", "_pct", "_lot", "_dwelling", "_lake")) or k.startswith("is_")}
#     try:
#         res = engine.run(db, a.structure, inputs, address=a.address, lon=a.lon, lat=a.lat, zone_id=a.zone,
#                          precincts=a.precinct, assessment_date=a.date)
#     except (LookupError, ValueError) as e:
#         print(f"Error: {e}")
#         sys.exit(2)
#     if a.json:
#         print(json.dumps(res, indent=1, ensure_ascii=False, default=str))
#         return
#     loc = res["location"]
#     print(f"Address : {loc.get('geocode', {}).get('address', '(coordinates)')}  [{loc['lat']:.6f}, {loc['lon']:.6f}]")
#     print(f"Council : {loc['council']['lga_name']}")
#     p = loc.get("parcel") or {}
#     print(f"Lot     : {p.get('lotplan')}  area {p.get('lot_area')} m2  est. width {p.get('est_width_m')} m  depth {p.get('est_depth_m')} m")
#     z = loc["zoning"]
#     print(f"Zone    : {z['zone_id'] or 'UNKNOWN'}  precincts {z['precincts'] or '-'}"
#           + (f"  (map: {z['from_map']['zone_text']})" if z.get("from_map") else ""))
#     print(f"Overlays: {'; '.join(f"{o['name']} ({o['text']})" for o in loc.get('overlays') or []) or '-'}")
#     print(f"NP/LP   : {', '.join(z['local_plans'] + z['local_plan_precincts']) or ((z.get('from_map') or {}).get('local_plan_text') or '-')}")
#     print(f"Date    : {res['assessment_date']}   Structure: {res['structure']['label']}")
#     print("\nInstruments in force:")
#     for i in res["applicable_instruments"]:
#         print(f"  [{i['regime']}] {i['instrument']} — {i['version']}")
#     print("\nApplicable rules:")
#     for r in res["rules"]:
#         if r["operator"] in ("IS_TRUE", "IS_FALSE"):
#             req = "must hold" if r["operator"] == "IS_TRUE" else "must not occur"
#         elif r["required"] == 0 and r["operator"] == ">=":
#             req = "built to boundary permitted"
#         else:
#             req = f"{r['operator']} {r['required']} {r['unit'] or ''}"
#         where = r["boundary"] or ("canal/lake boundary" if r["topic"] == "SETBACK.WATERWAY" else "whole lot")
#         print(f"  {where:24} {r['topic']:28} {req:28} [{r['state']}]")
#         print(f"  {'':24} {r['title']}")
#         print(f"  {'':24} {r['instrument']} — {'; '.join(r['sources'])}")
#     c = res["council_rules"]
#     print(f"\nCouncil rules in scope here that did not apply ({c['other_places_count']} more apply only to other zones/overlays/plans):")
#     for x in c["in_scope_not_applicable"]:
#         print(f"  - {x['title']}\n      why not: {x['why']}")
#     if c["not_yet_encoded"]:
#         print("Council clauses for this place not yet encoded as rules (read them yourself):")
#         for g in c["not_yet_encoded"]:
#             print(f"  - {g['code']}: {g['count']} clause(s)")
#     if res["missing_inputs"]:
#         print("\nInputs that would resolve MANUAL_REVIEW items:")
#         for m in res["missing_inputs"]:
#             print(f"  - {m['fact']}: {m['description']}")
#     if res["warnings"]:
#         print("\nWarnings:")
#         for w in res["warnings"]:
#             print(f"  - {w}")
#
#
# if __name__ == "__main__":
#     main()
