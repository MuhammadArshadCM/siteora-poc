# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/core/evaluate.ts + server-ts/src/tools/evaluate.ts (npm run evaluate)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Reference rule resolver for the regs schema (illustrates docs/07-precedence.md).
#
# Not the production engine: it resolves which rules apply and what value they
# require; it does not measure geometry. Reads the DB through psql (no driver).
#
# Usage:
#   python -I tools/evaluate.py examples/brisbane_shed_pool.json [--host localhost] [--port 5432] [--db siteora] [--user postgres]
# Password: set PGPASSWORD (or use a pgpass file).
# """
# import argparse
# import json
# import math
# import os
# import subprocess
# import sys
#
# PSQL = os.environ.get("PSQL", r"C:\Program Files\PostgreSQL\18\bin\psql.exe")
# UNKNOWN = object()
#
#
# # ----------------------------------------------------------------------------- data access
# def query(args, sql):
#     out = subprocess.run([PSQL, "-h", args.host, "-p", str(args.port), "-U", args.user, "-d", args.db, "-At", "-c", sql],
#                          capture_output=True, text=True, encoding="utf-8", check=True).stdout.strip()
#     return json.loads(out) if out else []
#
#
# def load(args, lg, date):
#     d = f"'{date}'::date"
#     active_ivs = query(args, f"""
#       SELECT coalesce(json_agg(DISTINCT iv.instrument_version_id), '[]') FROM regs.instrument_versions iv
#       WHERE (EXISTS (SELECT 1 FROM regs.instrument_applicability a WHERE a.instrument_version_id = iv.instrument_version_id
#                       AND (a.lg_id IS NULL OR a.lg_id = '{lg}') AND a.effective_from <= {d}
#                       AND (a.effective_to IS NULL OR a.effective_to >= {d})))
#          OR (NOT EXISTS (SELECT 1 FROM regs.instrument_applicability a WHERE a.instrument_version_id = iv.instrument_version_id)
#              AND coalesce(iv.effective_from, '1900-01-01') <= {d} AND (iv.effective_to IS NULL OR iv.effective_to >= {d}))""")
#     rules = query(args, f"""
#       SELECT coalesce(json_agg(r), '[]') FROM (
#         SELECT rv.rule_version_id, rv.rule_id, ru.topic, ru.title, rv.instrument_version_id, rv.role, rv.regime,
#                rv.enforceability, rv.measurement_id, rv.operator, rv.value_expr, rv.unit, rv.permits_btb,
#                rv.on_noncompliance, rv.verification, rv.automatable, rv.interpretation_notes,
#                i.title AS instrument, iv.version_label,
#                (SELECT json_agg(json_build_object('level', s.level, 'lg', s.lg_id, 'zone', s.zone_id, 'precinct', s.precinct_id,
#                         'overlay', s.overlay_id, 'local_plan', s.local_plan_id, 'local_plan_precinct', s.local_plan_precinct_id,
#                         'exclude', s.exclude)) FROM regs.rule_scopes s
#                  WHERE s.rule_version_id = rv.rule_version_id) AS scopes,
#                (SELECT json_agg(json_build_object('id', s.structure_type_id, 'exclude', s.exclude)) FROM regs.rule_subjects s
#                  WHERE s.rule_version_id = rv.rule_version_id) AS subjects,
#                (SELECT json_agg(json_build_object('group', c.group_no, 'fact', c.fact_id, 'op', c.operator, 'value', c.value))
#                   FROM regs.rule_conditions c WHERE c.rule_version_id = rv.rule_version_id) AS conditions,
#                (SELECT json_agg(json_build_object('ref', p.ref_label, 'role', s.role, 'page', p.page_label, 'url', coalesce(p.url_anchor, iv2.source_url), 'quote', s.quote, 'text', p.verbatim_text))
#                   FROM regs.rule_sources s JOIN regs.provisions p USING (provision_id)
#                   JOIN regs.instrument_versions iv2 ON iv2.instrument_version_id = p.instrument_version_id
#                  WHERE s.rule_version_id = rv.rule_version_id) AS sources
#         FROM regs.rule_versions rv JOIN regs.rules ru USING (rule_id)
#         JOIN regs.instrument_versions iv ON iv.instrument_version_id = rv.instrument_version_id
#         JOIN regs.instruments i ON i.instrument_id = iv.instrument_id
#         WHERE rv.status = 'ACTIVE' AND rv.effective_from <= {d} AND (rv.effective_to IS NULL OR rv.effective_to >= {d})) r""")
#     rels = query(args, """SELECT coalesce(json_agg(json_build_object('from', from_rule_version_id, 'to_rv', to_rule_version_id,
#                            'to_rule', to_rule_id, 'type', type)), '[]') FROM regs.rule_relationships""")
#     parents = dict(query(args, "SELECT coalesce(json_agg(json_build_array(structure_type_id, parent_id)), '[]') FROM regs.structure_types"))
#     boundary_meas = set(query(args, """SELECT coalesce(json_agg(measurement_id), '[]') FROM regs.measurements
#                                       WHERE (reference_geometry LIKE 'BOUNDARY%' OR reference_geometry = 'COMMON_BOUNDARY')
#                                         -- waterway setbacks apply to the one boundary facing the water: evaluated once per lot
#                                         AND reference_geometry <> 'BOUNDARY_ADJOINING_CANAL_OR_LAKE'"""))
#     return set(active_ivs), rules, rels, parents, boundary_meas
#
#
# # ----------------------------------------------------------------------------- expression language
# def ev(e, facts):
#     """Evaluate an expression AST. Returns a number/bool/str, None (no value) or UNKNOWN (missing fact)."""
#     if e is None or isinstance(e, (int, float, str, bool)):
#         return e
#     if "var" in e:
#         return facts.get(e["var"], UNKNOWN)
#     op = e["op"]
#     if op == "unencoded":
#         return None
#     if op == "case":
#         for w in e["when"]:
#             c = ev(w["if"], facts)
#             if c is UNKNOWN:
#                 return UNKNOWN
#             if c:
#                 return ev(w["then"], facts)
#         return ev(e.get("else"), facts)
#     if op == "switch":
#         k = ev(e["on"], facts)
#         if k is UNKNOWN:
#             return UNKNOWN
#         return ev(e["cases"].get(k, e.get("default")), facts)
#     if op == "interpolate":
#         x = ev(e["x"], facts)
#         if x is UNKNOWN:
#             return UNKNOWN
#         (x0, y0), (x1, y1) = e["points"][0], e["points"][-1]
#         if not x0 <= x <= x1:
#             return None
#         return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
#     if op == "lookup_range":
#         x = ev(e["x"], facts)
#         if x is UNKNOWN:
#             return UNKNOWN
#         x = round(x, 3)
#         for r in e["rows"]:
#             if r.get("min", -math.inf) <= x <= r.get("max", math.inf):
#                 return r["value"]
#         return None
#     args = [ev(a, facts) for a in e["args"]]
#     if any(a is UNKNOWN for a in args):
#         return UNKNOWN
#     if any(a is None for a in args):
#         return None
#     if op in ("min_of", "max_of", "avg_of"):
#         xs = args[0]
#         return {"min_of": min, "max_of": max, "avg_of": lambda v: sum(v) / len(v)}[op](xs)
#     fn = {"+": lambda a, b: a + b, "-": lambda a, b: a - b, "*": lambda a, b: a * b, "/": lambda a, b: a / b,
#           "<=": lambda a, b: a <= b, "<": lambda a, b: a < b, ">=": lambda a, b: a >= b, ">": lambda a, b: a > b,
#           "=": lambda a, b: a == b, "ceil": math.ceil, "is_true": bool,
#           "min": lambda *a: min(a), "max": lambda *a: max(a)}[op]
#     return fn(*args)
#
#
# def cond(c, facts):
#     v = facts.get(c["fact"], UNKNOWN)
#     op, want = c["op"], c["value"]
#     if op == "IS_NULL":
#         return v is UNKNOWN or v is None
#     if op == "IS_NOT_NULL":
#         return not (v is UNKNOWN or v is None)
#     if v is UNKNOWN:
#         return UNKNOWN
#     return {"IS_TRUE": lambda: v is True, "IS_FALSE": lambda: v is False, "=": lambda: v == want, "<>": lambda: v != want,
#             ">=": lambda: v >= want, ">": lambda: v > want, "<=": lambda: v <= want, "<": lambda: v < want,
#             "IN": lambda: v in want, "NOT_IN": lambda: v not in want}[op]()
#
#
# def conditions_hold(rule, facts):
#     """DNF: True / False / UNKNOWN."""
#     groups = {}
#     for c in rule["conditions"] or []:
#         groups.setdefault(c["group"], []).append(c)
#     if not groups:
#         return True
#     any_unknown = False
#     for cs in groups.values():
#         rs = [cond(c, facts) for c in cs]
#         if all(r is True for r in rs):
#             return True
#         if not any(r is False for r in rs):
#             any_unknown = True
#     return UNKNOWN if any_unknown else False
#
#
# # ----------------------------------------------------------------------------- scope / subject matching
# def ancestors(st, parents):
#     out = []
#     while st:
#         out.append(st)
#         st = parents.get(st)
#     return out
#
#
# def subject_matches(rule, structure, parents):
#     chain = ancestors(structure, parents)
#     subs = rule["subjects"] or []
#     if any(s["exclude"] and s["id"] in chain for s in subs):
#         return False
#     return any(not s["exclude"] and s["id"] in chain for s in subs)
#
#
# def scope_matches(rule, site):
#     """Scope semantics (docs/07): LG rows must match; place rows (zone / precinct / local plan /
#     local plan precinct) are alternatives; overlay rows are alternatives and must also match;
#     any matching exclude row removes the rule."""
#     scopes = rule["scopes"] or [{"level": "STATE", "exclude": False}]
#     hit = {
#         "STATE": lambda s: True,
#         "LOCAL_GOVERNMENT": lambda s: s["lg"] == site["lg"],
#         "PLANNING_SCHEME": lambda s: s["lg"] == site["lg"],
#         "ZONE": lambda s: s["zone"] == site.get("zone"),
#         "PRECINCT": lambda s: s["precinct"] in site.get("precincts", []),
#         "LOCAL_PLAN": lambda s: s["local_plan"] in site.get("local_plans", []),
#         "LOCAL_PLAN_PRECINCT": lambda s: s["local_plan_precinct"] in site.get("local_plan_precincts", []),
#         "OVERLAY": lambda s: s["overlay"] in site.get("overlays", []),
#     }
#     groups = {"LOCAL_GOVERNMENT": "lg", "PLANNING_SCHEME": "lg", "ZONE": "place", "PRECINCT": "place",
#               "LOCAL_PLAN": "place", "LOCAL_PLAN_PRECINCT": "place", "OVERLAY": "overlay", "STATE": "state"}
#     includes = {}
#     for s in scopes:
#         h = hit.get(s["level"], lambda s: False)(s)
#         if s["exclude"]:
#             if h:
#                 return False
#             continue
#         includes.setdefault(groups.get(s["level"], s["level"]), []).append(h)
#     return all(any(v) for v in includes.values())
#
#
# # ----------------------------------------------------------------------------- resolution
# def resolve(args, scenario):
#     site = scenario["site"]
#     active_ivs, rules, rels, parents, boundary_meas = load(args, site["lg"], scenario["assessment_date"])
#     by_rv = {r["rule_version_id"]: r for r in rules}
#     results = []
#     for item in scenario["structures"]:
#         structure = item["structure_type"]
#         # one lot-level pass (height, site cover, size, barrier) + one pass per boundary (setbacks)
#         contexts = [{"boundary_type": None}] + (item.get("boundaries") or [])
#         base_facts = {**scenario.get("facts", {}), **item.get("facts", {})}
#         for ctx in contexts:
#             facts = {**base_facts, **ctx}
#             cand, status = {}, {}
#             lot_pass = ctx.get("boundary_type") is None
#             for r in rules:
#                 if r["instrument_version_id"] not in active_ivs or not scope_matches(r, site):
#                     continue
#                 if r["role"] in ("REQUIREMENT", "RELAXATION") and (r["measurement_id"] in boundary_meas) == lot_pass:
#                     continue
#                 if not subject_matches(r, structure, parents):
#                     continue
#                 h = conditions_hold(r, facts)
#                 status[r["rule_version_id"]] = h
#                 if h is not False:
#                     cand[r["rule_version_id"]] = r
#             # FALLS_BACK_TO: a listed row whose limits are exceeded hands the subject to the target row
#             for rel in rels:
#                 if rel["type"] == "FALLS_BACK_TO" and status.get(rel["from"]) is False and rel["to_rv"] in by_rv:
#                     t = by_rv[rel["to_rv"]]
#                     if t["instrument_version_id"] in active_ivs and conditions_hold(t, facts) is not False:
#                         cand.setdefault(t["rule_version_id"], {**t, "_via": f"falls back from {rel['from']}"})
#             removed = {}
#             for rel in rels:
#                 if rel["from"] not in cand:
#                     continue
#                 targets = [rv for rv, r in cand.items() if rv == rel["to_rv"] or r["rule_id"] == rel["to_rule"]]
#                 if rel["type"] in ("OVERRIDES", "REPLACES") or (rel["type"] == "EXEMPTS" and status.get(rel["from"]) is True):
#                     for t in targets:
#                         removed[t] = f"{rel['type']} by {rel['from']}"
#                 if rel["type"] == "RELAXES" and status.get(rel["from"]) is True:
#                     for t in targets:
#                         removed[t] = f"RELAXED by {rel['from']}"
#             live = [r for rv, r in cand.items() if rv not in removed and r["role"] in ("REQUIREMENT", "RELAXATION")]
#             unresolved = {}
#             live_ids = {r["rule_version_id"] for r in live}
#             for rel in rels:
#                 if rel["type"] != "UNRESOLVED" or rel["from"] not in live_ids:
#                     continue
#                 for r in live:
#                     if r["rule_version_id"] == rel["to_rv"] or r["rule_id"] == rel["to_rule"]:
#                         unresolved[r["rule_version_id"]] = unresolved[rel["from"]] = f"unresolved interaction {rel['from']} / {r['rule_version_id']}"
#             for r in live:
#                 req = ev(r["value_expr"], facts)
#                 state = ("MANUAL_REVIEW" if status.get(r["rule_version_id"]) is UNKNOWN or req is UNKNOWN or req is None
#                          or not r["automatable"] or r["rule_version_id"] in unresolved else "DETERMINED")
#                 results.append({"structure": item["label"], "boundary": ctx.get("boundary_type"), "regime": r["regime"],
#                                 "topic": r["topic"], "rule": r["rule_version_id"], "title": r["title"], "role": r["role"],
#                                 "measurement": r["measurement_id"], "operator": r["operator"],
#                                 "required": None if req in (None, UNKNOWN) else round(req, 3) if isinstance(req, float) else req,
#                                 "unit": r["unit"], "state": state, "on_noncompliance": r["on_noncompliance"],
#                                 "instrument": f"{r['instrument']} ({r['version_label']})",
#                                 "sources": [s["ref"] for s in (r["sources"] or []) if s["role"] == "PRIMARY"],
#                                 "source_detail": [s for s in (r["sources"] or []) if s["role"] == "PRIMARY"],
#                                 "interpretation_notes": r.get("interpretation_notes"),
#                                 "via": r.get("_via") or unresolved.get(r["rule_version_id"])})
#             for rv, why in removed.items():
#                 results.append({"structure": item["label"], "boundary": ctx.get("boundary_type"), "rule": rv,
#                                 "state": "DISPLACED", "why": why, "topic": cand[rv]["topic"], "regime": cand[rv]["regime"]})
#     return results
#
#
# def main():
#     sys.stdout.reconfigure(encoding="utf-8")
#     ap = argparse.ArgumentParser()
#     ap.add_argument("scenario")
#     ap.add_argument("--host", default=os.environ.get("PGHOST", "localhost"))
#     ap.add_argument("--port", default=os.environ.get("PGPORT", "5432"))
#     ap.add_argument("--db", default=os.environ.get("PGDATABASE", "siteora"))
#     ap.add_argument("--user", default=os.environ.get("PGUSER", "postgres"))
#     ap.add_argument("--json", action="store_true")
#     args = ap.parse_args()
#     scenario = json.load(open(args.scenario, encoding="utf-8"))
#     res = resolve(args, scenario)
#     if args.json:
#         print(json.dumps(res, indent=1, ensure_ascii=False))
#         return
#     print(f"# {scenario['title']}  (assessment date {scenario['assessment_date']})\n")
#     for s in dict.fromkeys(r["structure"] for r in res):
#         print(f"## {s}")
#         for r in sorted((x for x in res if x["structure"] == s and x["state"] != "DISPLACED"),
#                         key=lambda x: (x["regime"], x["topic"], str(x["boundary"]))):
#             if r["operator"] in ("IS_TRUE", "IS_FALSE"):
#                 req = "must hold" if r["operator"] == "IS_TRUE" else "must not occur"
#             elif r["required"] == 0 and r["operator"] == ">=":
#                 req = "BTB permitted (0 m)"
#             else:
#                 req = f"{r['operator']} {r['required']} {r['unit'] or ''}"
#             print(f"- [{r['regime']}] {r['topic']} {('(' + r['boundary'] + ')') if r['boundary'] else ''}: {req}  [{r['state']}]")
#             print(f"    {r['rule']} — {r['title']}")
#             print(f"    source: {r['instrument']} — {'; '.join(r['sources'])}" + (f"  ({r['via']})" if r.get("via") else ""))
#         disp = [x for x in res if x["structure"] == s and x["state"] == "DISPLACED"]
#         if disp:
#             print("  displaced:")
#             for x in disp:
#                 print(f"    - {x['rule']} ({x['boundary']}): {x['why']}")
#         print()
#
#
# if __name__ == "__main__":
#     sys.exit(main())
