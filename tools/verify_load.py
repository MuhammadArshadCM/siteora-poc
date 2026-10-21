# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/tools/verify-load.ts (npm run verify-load)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Verify that every record in the research files is in the database, unchanged.
#
# For each research/councils/<council>.json it checks:
#   * the planning scheme instrument and version exist;
#   * every rule's verbatim text is stored in provisions (matched by research_key) — exact string match;
#   * every non-definition rule has a rule (DRAFT, SUPERSEDED or curated);
#   * definitions, levels of assessment, QDC-relationship quotes, overlay quotes and open questions were loaded;
# and for research/places.json that every zone, precinct, local plan and local-plan precinct exists with the
# same dwelling-house flag. Exit code 1 on any mismatch.
#
# Usage: PGPASSWORD=... python -I tools/verify_load.py [--db siteora]
# """
# import argparse
# import json
# import pathlib
# import sys
#
# sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
# import evaluate  # noqa: E402
# import import_council_research as gen  # noqa: E402
#
# ROOT = pathlib.Path(__file__).resolve().parent.parent
#
#
# def main():
#     ap = argparse.ArgumentParser()
#     ap.add_argument("--host", default="localhost")
#     ap.add_argument("--port", default="5432")
#     ap.add_argument("--db", default="siteora")
#     ap.add_argument("--user", default="postgres")
#     args = ap.parse_args()
#     sys.stdout.reconfigure(encoding="utf-8")
#     q = lambda sql: evaluate.query(args, sql)
#     problems = 0
#     print(f"{'council':15} {'rules':>6} {'text ok':>8} {'rule rows':>9} {'defs':>5} {'LOA':>4} {'QDC q':>6} {'ovl q':>6} {'issues':>7}  result")
#     for slug_name, (lg, authority, inst) in gen.COUNCILS.items():
#         d = json.loads((ROOT / "research" / "councils" / f"{slug_name}.json").read_text(encoding="utf-8"))
#         ivs = q(f"SELECT coalesce(json_agg(instrument_version_id), '[]') FROM regs.instrument_versions WHERE instrument_id = '{inst}'")
#         if len(ivs) != 1:
#             print(f"{slug_name:15} planning scheme version missing or duplicated: {ivs}")
#             problems += 1
#             continue
#         iv = ivs[0]
#         stored = dict(q(f"""SELECT coalesce(json_agg(json_build_array(research_key, verbatim_text)), '[]')
#                             FROM regs.provisions WHERE instrument_version_id = '{iv}' AND research_key IS NOT NULL"""))
#         rules = d["rules"]
#         text_ok = sum(1 for r in rules if r["rule_key"] in stored and stored[r["rule_key"]] == r.get("verbatim_text"))
#         rule_ids = set(q(f"SELECT coalesce(json_agg(rule_id), '[]') FROM regs.rules WHERE instrument_id = '{inst}'"))
#         expected_rules = [r for r in rules if r.get("provision_type") != "DEFINITION"]
#         rule_rows = sum(1 for r in expected_rules if f"{authority}.{r['rule_key']}" in rule_ids)
#
#         def count_kind(where):
#             return q(f"SELECT count(*) FROM regs.provisions WHERE instrument_version_id = '{iv}' AND research_key IS NULL AND {where}")
#
#         got = {
#             "defs": (count_kind("kind = 'DEFINITION'"), len(d.get("definitions", []))),
#             "loa": (count_kind("kind = 'LEVEL_OF_ASSESSMENT'"), len(d.get("levels_of_assessment", []))),
#             "qdc": (count_kind("ref_label LIKE 'QDC relationship:%'"), len(d.get("qdc_qhc_relationship", {}).get("quotes", []))),
#             "ovl": (count_kind("ref_label LIKE 'overlay %'"), len(d.get("overlays_affecting_siting", []))),
#             "issues": (q(f"SELECT count(*) FROM regs.open_issues WHERE instrument_id = '{inst}'"), len(d.get("open_questions", []))),
#         }
#         ok = (text_ok == len(rules) and rule_rows == len(expected_rules) and all(a == b for a, b in got.values()))
#         problems += not ok
#         fmt = lambda k: f"{got[k][0]}/{got[k][1]}"
#         print(f"{slug_name:15} {len(rules):>6} {text_ok:>8} {rule_rows:>4}/{len(expected_rules):<4} {fmt('defs'):>5} {fmt('loa'):>4} "
#               f"{fmt('qdc'):>6} {fmt('ovl'):>6} {fmt('issues'):>7}  {'OK' if ok else 'MISMATCH'}")
#         for r in rules:
#             if r["rule_key"] not in stored:
#                 print(f"    missing provision for {r['rule_key']}")
#             elif stored[r["rule_key"]] != r.get("verbatim_text"):
#                 print(f"    verbatim text differs for {r['rule_key']}")
#
#     print()
#     places = json.loads((ROOT / "research" / "places.json").read_text(encoding="utf-8"))["councils"]
#     zones = {z["zone_id"]: z for z in q("SELECT coalesce(json_agg(z), '[]') FROM regs.zones z")}
#     precincts = set(q("SELECT coalesce(json_agg(precinct_id), '[]') FROM regs.precincts"))
#     lps = set(q("SELECT coalesce(json_agg(local_plan_id), '[]') FROM regs.local_plans"))
#     lpps = set(q("SELECT coalesce(json_agg(local_plan_precinct_id), '[]') FROM regs.local_plan_precincts"))
#     print(f"{'council':15} {'zones':>6} {'flag ok':>8} {'precincts':>10} {'local plans':>12} {'lp precincts':>13}  result")
#     for slug_name, pl in places.items():
#         a = pl["authority"]
#         zs = [(f"{a}:{z['code']}", z) for z in pl["zones"]]
#         z_ok = sum(1 for zid, _ in zs if zid in zones)
#         f_ok = sum(1 for zid, z in zs if zid in zones and zones[zid]["dwelling_house_permitted"] == z["dwelling_house_permitted"]
#                    and zones[zid]["regulated_zone_id"] == z["regulated"])
#         p_exp = [f"{a}:{p['zone']}/{p['code']}" for p in pl["precincts"]]
#         lp_exp = [f"{a}:{x['code']}" for x in pl["local_plans"]]
#         lpp_exp = [f"{a}:{x['code']}/{p['code']}" for x in pl["local_plans"] for p in x["precincts"]]
#         p_ok, lp_ok, lpp_ok = (sum(1 for x in p_exp if x in precincts), sum(1 for x in lp_exp if x in lps),
#                                sum(1 for x in lpp_exp if x in lpps))
#         ok = (z_ok == f_ok == len(zs) and p_ok == len(p_exp) and lp_ok == len(lp_exp) and lpp_ok == len(lpp_exp))
#         problems += not ok
#         print(f"{slug_name:15} {z_ok:>2}/{len(zs):<3} {f_ok:>4}/{len(zs):<3} {p_ok:>5}/{len(p_exp):<4} {lp_ok:>6}/{len(lp_exp):<5} "
#               f"{lpp_ok:>6}/{len(lpp_exp):<6}  {'OK' if ok else 'MISMATCH'}")
#
#     print()
#     print("PASS — every research record is in the database unchanged" if not problems else f"{problems} mismatch(es)")
#     return 1 if problems else 0
#
#
# if __name__ == "__main__":
#     sys.exit(main())
