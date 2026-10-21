# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/tools/import-council-research.ts (npm run import-research)
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Convert council research files (research/councils/*.json) into SQL seed files.
#
# Every quoted provision is loaded verbatim into regs.provisions, and every
# extracted rule becomes a DRAFT rule version with automatable = false. Values
# are carried over exactly as extracted; nothing is inferred. Rules are promoted
# to ACTIVE/automatable only by hand in db/031_council_curated.sql after review.
#
# Usage: python -I tools/import_council_research.py   (writes db/030_council_<slug>.sql)
# """
# import json
# import pathlib
# import re
#
# ROOT = pathlib.Path(__file__).resolve().parent.parent
# RESEARCH = ROOT / "research" / "councils"
# PLACES = json.loads((ROOT / "research" / "places.json").read_text(encoding="utf-8"))["councils"]
# OUT = ROOT / "db"
# RESEARCH_DATE = "2026-10-08"
#
# COUNCILS = {
#     "brisbane": ("BRISBANE", "BCC", "BCC_CITY_PLAN_2014"),
#     "gold_coast": ("GOLD_COAST", "CGC", "CGC_CITY_PLAN"),
#     "moreton_bay": ("MORETON_BAY", "CMB", "MBRC_PLANNING_SCHEME_2016"),
#     "sunshine_coast": ("SUNSHINE_COAST", "SCC", "SCC_PLANNING_SCHEME_2014"),
#     "logan": ("LOGAN", "LCC", "LCC_PLANNING_SCHEME_2015"),
#     "ipswich": ("IPSWICH", "ICC", "ICC_CITY_PLAN_2025"),
#     "redland": ("REDLAND", "RCC", "RCC_CITY_PLAN_2018"),
# }
#
# # topic -> (measurement, operator used when the extracted operator is not a plain comparison, taxonomy topic)
# TOPICS = {
#     "FRONT_SETBACK": ("SCHEME_SETBACK_FRONT", ">=", "SETBACK.FRONTAGE"),
#     "SECONDARY_FRONTAGE_SETBACK": ("SCHEME_SETBACK_SECONDARY_FRONTAGE", ">=", "SETBACK.SECONDARY_ROAD"),
#     "SIDE_SETBACK": ("SCHEME_SETBACK_SIDE", ">=", "SETBACK.SIDE"),
#     "REAR_SETBACK": ("SCHEME_SETBACK_REAR", ">=", "SETBACK.REAR"),
#     "BUILT_TO_BOUNDARY": ("SCHEME_BTB_LENGTH", "<=", "SETBACK.SIDE_REAR.BTB"),
#     "GARAGE_CARPORT_FRONTAGE": ("SCHEME_GARAGE_CARPORT", ">=", "GARAGE.FRONTAGE"),
#     "SITE_COVER": ("SCHEME_SITE_COVER", "<=", "SITE_COVER"),
#     "BUILDING_HEIGHT": ("SCHEME_HEIGHT", "<=", "HEIGHT.BUILDING"),
#     "WALL_HEIGHT": ("SCHEME_HEIGHT", "<=", "HEIGHT.WALL"),
#     "OUTBUILDING_SIZE": ("SCHEME_OUTBUILDING_SIZE", "<=", "OUTBUILDING.SIZE"),
#     "POOL_SETBACK": ("SCHEME_POOL_SETBACK", ">=", "POOL.SETBACK"),
#     "LANDSCAPE_OR_IMPERVIOUS": ("SCHEME_LANDSCAPE", ">=", "LANDSCAPE.OPEN_SPACE"),
#     "SEPARATION": ("SCHEME_SEPARATION", ">=", "SEPARATION.BUILDINGS"),
#     "OTHER": ("SCHEME_OTHER", "=", "OTHER"),
# }
#
# # Which legacy QDC rules an alternative provision on this topic displaces (Building Act s33(4)).
# QDC_TARGETS = {
#     "FRONT_SETBACK": ["QDC12.A1a.ROAD_SETBACK", "QDC11.A1a.FRONTAGE_SETBACK"],
#     "SECONDARY_FRONTAGE_SETBACK": ["QDC12.A1a.ROAD_SETBACK", "QDC11.A1a.SIDE_TO_CORNER_STREET"],
#     "SIDE_SETBACK": ["QDC12.A2a.SIDE_REAR_CLEARANCE", "QDC11.A2a.SIDE_REAR_CLEARANCE"],
#     "REAR_SETBACK": ["QDC12.A2a.SIDE_REAR_CLEARANCE", "QDC11.A2a.SIDE_REAR_CLEARANCE"],
#     "BUILT_TO_BOUNDARY": ["QDC12.A2d.CLASS10A_WITHIN_CLEARANCE", "QDC11.A2d.CLASS10A_WITHIN_CLEARANCE"],
#     "SITE_COVER": ["QDC12.A3.SITE_COVER", "QDC11.A3.SITE_COVER"],
#     "BUILDING_HEIGHT": ["QDC12.A4.BUILDING_HEIGHT", "QDC11.A4.BUILDING_HEIGHT"],
# }
#
# KIND = {
#     "ACCEPTABLE_OUTCOME": "ACCEPTABLE_OUTCOME",
#     "PERFORMANCE_OUTCOME": "PERFORMANCE_OUTCOME",
#     "TABLE": "TABLE",
#     "ACCEPTED_DEVELOPMENT_REQUIREMENT": "ACCEPTED_DEVELOPMENT_REQUIREMENT",
#     "DEFINITION": "DEFINITION",
#     "OTHER": "OTHER",
# }
#
# VERIF = {"VERIFIED_VERBATIM", "COUNCIL_FACTSHEET", "SECONDARY_SOURCE_ONLY", "UNVERIFIED"}
#
#
# def q(s):
#     """SQL literal using dollar quoting that cannot collide with the text."""
#     if s is None:
#         return "NULL"
#     s = str(s)
#     tag = "$q$"
#     n = 0
#     while tag in s:
#         n += 1
#         tag = f"$q{n}$"
#     return f"{tag}{s}{tag}"
#
#
# def slug(s):
#     return re.sub(r"[^A-Z0-9]+", "_", s.upper()).strip("_")[:100]
#
#
# def place_scopes(r, places, authority):
#     """Map a research rule's zone strings to scope rows using research/places.json.
#
#     Returns (scopes, notes). Raises on any zone string that places.json does not cover, so new
#     research cannot silently create pseudo-zones.
#     """
#     for pattern, rows in places.get("rule_key_scopes", {}).items():
#         if re.search(pattern, r["rule_key"]):
#             return [qualify(x, authority) for x in rows], []
#     scopes, notes = [], []
#     for z in r.get("zones") or []:
#         if z not in places["raw_scopes"]:
#             raise KeyError(f"{authority} rule {r['rule_key']}: zone string not in research/places.json: {z!r}")
#         rows = places["raw_scopes"][z]
#         if rows == "UNMAPPED":
#             notes.append(f"Zone text '{z}' could not be mapped to a scheme place; rule left council-wide.")
#             continue
#         if not rows:          # 'all zones' etc. => no place restriction
#             return [], notes
#         scopes += [qualify(x, authority) for x in rows]
#     return scopes, notes
#
#
# def qualify(row, authority):
#     """Prefix place ids with the authority code (places.json stores them unqualified)."""
#     out = dict(row)
#     for k in ("zone", "precinct", "local_plan", "local_plan_precinct"):
#         if k in out:
#             out[k] = f"{authority}:{out[k]}"
#     if "overlay" in out:
#         out["overlay"] = f"{authority}:OV:{out['overlay']}"
#     return out
#
#
# def subjects_for(scope):
#     s = (scope or "").lower()
#     out = []
#     if "pool" in s:
#         out.append("POOL")
#     if any(k in s for k in ("class 10", "outbuilding", "shed", "garage", "carport", "non-habitable")):
#         out.append("CLASS_10A")
#     if any(k in s for k in ("dwelling", "house", "class 1")):
#         out.append("CLASS_1")
#     if any(k in s for k in ("deck", "patio", "pergola", "verandah")):
#         out.append("OUTDOOR_STRUCTURE")
#     if "structure" in s and not out:
#         out.append("ANY")
#     if any(k in s for k in ("all buildings", "buildings and structures", "any building")):
#         out = ["ANY"]
#     return out or ["ANY"], not out
#
#
# def date_or_none(s):
#     return s if s and re.fullmatch(r"\d{4}-\d{2}-\d{2}", s) else None
#
#
# def build(slug_name):
#     path = RESEARCH / f"{slug_name}.json"
#     if not path.exists():
#         return None
#     d = json.loads(path.read_text(encoding="utf-8"))
#     lg, authority, inst = COUNCILS[slug_name]
#     ps = d["planning_scheme"]
#     commenced = date_or_none(ps.get("version_commenced"))
#     eff = commenced or RESEARCH_DATE
#     iv = f"{inst}@{eff}"
#     urls = ps.get("official_urls") or []
#     L = []
#     w = L.append
#     w(f"-- Generated by tools/import_council_research.py from research/councils/{slug_name}.json")
#     w("-- DO NOT EDIT BY HAND: re-run the generator. Places come from research/places.json;")
#     w("-- curated rules live in db/031_council_curated.sql and db/032_council_curated_batch2.sql.")
#     w("SET search_path = regs, public;\n")
#     w("INSERT INTO instruments (instrument_id, authority_id, lg_id, kind, force, title, notes) VALUES "
#       f"({q(inst)}, {q(authority)}, {q(lg)}, 'PLANNING_SCHEME', 'STATUTORY_INSTRUMENT', {q(ps['name'])}, {q(ps.get('notes'))});")
#     w("INSERT INTO instrument_versions (instrument_version_id, instrument_id, version_label, effective_from, status, source_url, retrieved_at, notes) VALUES "
#       f"({q(iv)}, {q(inst)}, {q(ps.get('version'))}, {q(eff)}, 'ACTIVE', {q(urls[0] if urls else None)}, {q(RESEARCH_DATE)}, "
#       f"{q(None if commenced else 'Commencement date UNVERIFIED; research date used as effective_from.')});")
#     w(f"INSERT INTO instrument_applicability (instrument_version_id, lg_id, regime, effective_from, basis_provision_id, confidence, notes) VALUES "
#       f"({q(iv)}, {q(lg)}, 'PLANNING', {q(eff)}, NULL, {q('VERIFIED_VERBATIM' if commenced else 'UNVERIFIED')}, 'Version in force at research date; earlier versions not loaded.');\n")
#
#     # Places (from research/places.json) and overlays (from the research file)
#     places = PLACES[slug_name]
#     assert places["authority"] == authority
#     for z in places["zones"]:
#         w("INSERT INTO zones (zone_id, instrument_id, zone_code, name, regulated_zone_id, dwelling_house_permitted, dwelling_house_basis) VALUES "
#           f"({q(authority + ':' + z['code'])}, {q(inst)}, {q(z['code'])}, {q(z['name'])}, {q(z['regulated'])}, "
#           f"{'NULL' if z['dwelling_house_permitted'] is None else str(z['dwelling_house_permitted']).lower()}, {q(z['basis'])});")
#     for pr in places["precincts"]:
#         w("INSERT INTO precincts (precinct_id, zone_id, name) VALUES "
#           f"({q(authority + ':' + pr['zone'] + '/' + pr['code'])}, {q(authority + ':' + pr['zone'])}, {q(pr['name'])});")
#     for lp in places["local_plans"]:
#         w("INSERT INTO local_plans (local_plan_id, instrument_id, name, plan_type) VALUES "
#           f"({q(authority + ':' + lp['code'])}, {q(inst)}, {q(lp['name'])}, {q(lp['type'])});")
#         for pr in lp["precincts"]:
#             w("INSERT INTO local_plan_precincts (local_plan_precinct_id, local_plan_id, name) VALUES "
#               f"({q(authority + ':' + lp['code'] + '/' + pr['code'])}, {q(authority + ':' + lp['code'])}, {q(pr['name'])});")
#     overlays = {}
#     for r in d.get("rules", []):
#         if r.get("overlay"):
#             overlays.setdefault(f"{authority}:OV:{slug(r['overlay'])}", r["overlay"])
#     for o in d.get("overlays_affecting_siting", []):
#         overlays.setdefault(f"{authority}:OV:{slug(o['overlay'])}", o["overlay"])
#     for oid, name in sorted(overlays.items()):
#         w(f"INSERT INTO overlays (overlay_id, instrument_id, name) VALUES ({q(oid)}, {q(inst)}, {q(name)});")
#     w("")
#
#     seen = set()
#
#     def prov(ref, kind, text, ver, url=None, page=None, code=None, notes=None, research_key=None):
#         ref = ref[:200]
#         if research_key is None:          # label must be unique among non-keyed provisions
#             base, n = ref, 1
#             while ref in seen:
#                 n += 1
#                 ref = f"{base} #{n}"
#             seen.add(ref)
#         ver = ver if ver in VERIF else "UNVERIFIED"
#         if not text:
#             ver = "UNVERIFIED"
#         w(f"SELECT define_provision({q(iv)}, {q(ref)}, '{kind}', {q(text)}, '{ver}', {q(page)}, NULL, {q(code)}, NULL, {q(url)}, {q(notes)}, {q(research_key)});")
#         return ref
#
#     for i, x in enumerate(d.get("qdc_qhc_relationship", {}).get("quotes", [])):
#         prov(f"QDC relationship: {x.get('clause') or i}", "APPLICATION", x.get("text"), "VERIFIED_VERBATIM", x.get("source_url"))
#     for x in d.get("definitions", []):
#         prov(f"def {x['term']}", "DEFINITION", x.get("text"), "VERIFIED_VERBATIM", x.get("source_url"), None, x.get("clause"))
#     for x in d.get("levels_of_assessment", []):
#         prov(f"LOA {x.get('clause')} {x.get('use_or_work')} / {x.get('zone')}", "LEVEL_OF_ASSESSMENT", x.get("quote"),
#              "VERIFIED_VERBATIM", x.get("source_url"), None, None, f"Level: {x.get('level')}. Conditions: {x.get('conditions')}")
#     for x in d.get("overlays_affecting_siting", []):
#         prov(f"overlay {x['overlay']} {x.get('clause') or ''}".strip(), "OTHER", x.get("quote"), "VERIFIED_VERBATIM",
#              x.get("source_url"), None, x.get("code"), x.get("effect"))
#     w("")
#
#     rule_ids = []
#     for r in d.get("rules", []):
#         prov(r.get("clause") or r["rule_key"], KIND.get(r.get("provision_type"), "OTHER"),
#              r.get("verbatim_text"), r.get("verification_status"), r.get("source_url"), r.get("page_or_anchor"), r.get("code"),
#              r.get("measurement_notes"), research_key=r["rule_key"])
#         if r.get("provision_type") == "DEFINITION":
#             continue
#         topic = r.get("topic") or "OTHER"
#         meas, default_op, tax = TOPICS.get(topic, TOPICS["OTHER"])
#         st = r.get("structured") or {}
#         op, val = st.get("operator"), st.get("value")
#         simple = op in (">=", "<=", "=") and isinstance(val, (int, float)) and not isinstance(val, bool)
#         value = val if simple else {"op": "unencoded", "text": st.get("formula_text") or r.get("verbatim_text"),
#                                     "extracted_value": val, "extracted_operator": op}
#         alt = (r.get("alternative_provision_to_qdc_qhc") or "UNKNOWN").split()[0].upper()
#         ptype = r.get("provision_type")
#         if alt == "YES":
#             regime, outcome = "BUILDING", "REFERRAL_TO_LOCAL_GOVERNMENT"
#         else:
#             regime, outcome = "PLANNING", ("ASSESS_AGAINST_PERFORMANCE_OUTCOME" if ptype == "PERFORMANCE_OUTCOME"
#                                             else "PLANNING_APPROVAL_REQUIRED")
#         enf = "DISCRETIONARY" if ptype == "PERFORMANCE_OUTCOME" else "DEEMED_TO_COMPLY"
#         subjects, defaulted = subjects_for(r.get("structure_scope"))
#         place, place_notes = place_scopes(r, places, authority)
#         scopes = [{"level": "LOCAL_GOVERNMENT", "lg": lg}] + place
#         if r.get("overlay"):
#             scopes.append({"level": "OVERLAY", "overlay": f"{authority}:OV:{slug(r['overlay'])}"})
#         notes = [f"AUTO-IMPORTED (draft). Extracted structure: {json.dumps(st, ensure_ascii=False)}",
#                  f"Lot conditions (not encoded): {r.get('lot_conditions')}" if r.get("lot_conditions") else None,
#                  f"Local plan: {r.get('local_plan')}" if r.get("local_plan") else None,
#                  f"Structure scope '{r.get('structure_scope')}' mapped by keyword to {subjects}" + (" (default)" if defaulted else ""),
#                  f"Alternative provision to QDC/QHC: {r.get('alternative_provision_to_qdc_qhc')}",
#                  f"Researcher notes: {r.get('notes')}" if r.get("notes") else None] + place_notes
#         doc = {
#             "rule_id": f"{authority}.{r['rule_key']}", "instrument_version": iv, "topic": tax,
#             "title": (r.get("clause") or r["rule_key"])[:200],
#             "role": "REQUIREMENT", "regime": regime, "enforceability": enf,
#             "provision_kind": KIND.get(ptype, "OTHER"), "measurement": meas,
#             "operator": op if op in (">=", "<=", "=") else default_op, "value": value, "unit": st.get("unit"),
#             "on_noncompliance": outcome, "effective_from": eff,
#             "verification": r.get("verification_status") if r.get("verification_status") in VERIF else "UNVERIFIED",
#             "automatable": False, "scopes": scopes, "subjects": subjects,
#             "sources": [{"key": r["rule_key"], "role": "PRIMARY"}],
#             "interpretation_notes": "\n".join(n for n in notes if n),
#         }
#         w(f"SELECT define_rule({q(json.dumps(doc, ensure_ascii=False))}::jsonb);")
#         rv = f"{doc['rule_id']}@{eff}"
#         rule_ids.append(rv)
#         w(f"UPDATE rule_versions SET status = 'DRAFT' WHERE rule_version_id = {q(rv)};")
#         if alt == "YES":
#             for target in QDC_TARGETS.get(topic, []):
#                 w("INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes) VALUES "
#                   f"({q(rv)}, {q(target)}, 'OVERRIDES', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM', "
#                   "'Alternative provision (Building Act s33(4)): QDC applies only to the extent this provision does not. Scope must be confirmed per rule (zone/precinct/structure).');")
#     w("")
#     for oq in d.get("open_questions", []):
#         w(f"INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES ({q(lg)}, {q(inst)}, 'MEDIUM', {q(oq)});")
#     return "\n".join(L) + "\n", len(rule_ids)
#
#
# if __name__ == "__main__":
#     for name in COUNCILS:
#         res = build(name)
#         if res is None:
#             print(f"{name}: no research file")
#             continue
#         sql, n = res
#         (OUT / f"030_council_{name}.sql").write_text(sql, encoding="utf-8")
#         print(f"{name}: {n} draft rules")
