# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/tools/check.ts (npm run check)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Regression checks for the regs dataset.
#
# 1. Integrity invariants (every one must return zero rows).
# 2. Every examples/*.json scenario reproduces its recorded examples/*.out.md.
#
# Usage:  PGPASSWORD=... python -I tools/check.py [--db siteora] [--update]
#         --update rewrites the recorded outputs (review the diff before committing).
# """
# import argparse
# import pathlib
# import subprocess
# import sys
#
# sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
# import evaluate  # noqa: E402
#
# ROOT = pathlib.Path(__file__).resolve().parent.parent
#
# INVARIANTS = {
#     "active rule without PRIMARY source":
#         "SELECT rule_version_id FROM regs.v_untraceable_rules",
#     "relationship target rule_id does not exist":
#         "SELECT relationship_id FROM regs.rule_relationships r WHERE r.to_rule_id IS NOT NULL "
#         "AND NOT EXISTS (SELECT 1 FROM regs.rules x WHERE x.rule_id = r.to_rule_id)",
#     "automatable rule that is not verified":
#         "SELECT rule_version_id FROM regs.rule_versions WHERE automatable "
#         "AND verification NOT IN ('VERIFIED_VERBATIM','VERIFIED_FROM_FIGURE')",
#     "condition references a boundary_type value outside the fact's allowed values":
#         "SELECT c.condition_id FROM regs.rule_conditions c, jsonb_array_elements_text(CASE WHEN jsonb_typeof(c.value)='array' "
#         "THEN c.value ELSE jsonb_build_array(c.value) END) v WHERE c.fact_id = 'boundary_type' "
#         "AND v NOT IN (SELECT unnest(allowed_values) FROM regs.facts WHERE fact_id = 'boundary_type')",
#     "value expression references an unknown fact":
#         "SELECT DISTINCT v #>> '{}' FROM regs.rule_versions rv, jsonb_path_query(rv.value_expr, 'lax $.**.var') v "
#         "WHERE rv.status = 'ACTIVE' AND NOT EXISTS (SELECT 1 FROM regs.facts f WHERE f.fact_id = v #>> '{}')",
#     "provision text contains a carriage return (line-ending corruption)":
#         "SELECT provision_id FROM regs.provisions WHERE verbatim_text LIKE '%' || chr(13) || '%'",
#     "active curated council rule still has an ACTIVE draft for the same provision":
#         "SELECT r.from_rule_version_id FROM regs.rule_relationships r JOIN regs.rule_versions d ON d.rule_version_id = r.to_rule_version_id "
#         "WHERE r.type = 'REPLACES' AND d.status = 'ACTIVE' AND r.from_rule_version_id LIKE '%.C.%'",
# }
#
#
# def main():
#     ap = argparse.ArgumentParser()
#     ap.add_argument("--host", default="localhost")
#     ap.add_argument("--port", default="5432")
#     ap.add_argument("--db", default="siteora")
#     ap.add_argument("--user", default="postgres")
#     ap.add_argument("--update", action="store_true")
#     args = ap.parse_args()
#     sys.stdout.reconfigure(encoding="utf-8")
#     failed = 0
#     for name, sql in INVARIANTS.items():
#         rows = evaluate.query(args, f"SELECT coalesce(json_agg(x), '[]') FROM ({sql}) x")
#         status = "ok" if not rows else f"FAIL ({len(rows)}): {rows[:3]}"
#         failed += bool(rows)
#         print(f"[invariant] {name}: {status}")
#     for scen in sorted((ROOT / "examples").glob("*.json")):
#         expected = scen.with_suffix(".out.md")
#         out = subprocess.run([sys.executable, "-I", str(ROOT / "tools" / "evaluate.py"), str(scen), "--host", args.host,
#                               "--port", str(args.port), "--db", args.db, "--user", args.user],
#                              capture_output=True, text=True, encoding="utf-8", check=True).stdout
#         if args.update or not expected.exists():
#             expected.write_text(out, encoding="utf-8")
#             print(f"[example]   {scen.name}: recorded")
#         elif out == expected.read_text(encoding="utf-8"):
#             print(f"[example]   {scen.name}: ok")
#         else:
#             failed += 1
#             print(f"[example]   {scen.name}: FAIL — output differs from {expected.name}")
#     print("PASS" if not failed else f"{failed} check(s) failed")
#     return 1 if failed else 0
#
#
# if __name__ == "__main__":
#     sys.exit(main())
