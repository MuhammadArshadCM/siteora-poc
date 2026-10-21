# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/core/zoning.ts
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Council zoning lookup: point -> scheme zone / precinct / local plan text -> ids in the regs schema.
#
# Each council publishes its own zoning map service; tested endpoints are configured in
# poc/zoning_layers.json. Councils without a working endpoint return None and the caller asks for the
# zone manually.
# """
# import json
# import pathlib
# import re
#
# from . import geo
#
# CONFIG = pathlib.Path(__file__).resolve().parent.parent / "zoning_layers.json"
# _WORDS = r"\b(zone|precinct|sub precinct|neighbourhood plan|local plan|plan)\b"
#
#
# def _norm(s):
#     s = (s or "").lower().replace("–", "-").replace("-", " ")
#     s = re.sub(r"[^a-z0-9 ]+", " ", s)
#     s = re.sub(_WORDS, " ", s)
#     return re.sub(r"\s+", " ", s).strip()
#
#
# def load_config():
#     return json.loads(CONFIG.read_text(encoding="utf-8")) if CONFIG.exists() else {}
#
#
# def _first(layer, lon, lat):
#     feats = geo.point_query(layer, lon, lat)
#     return feats[0]["attributes"] if feats else None
#
#
# def lookup(lg_id, points):
#     """Query the council's zoning layers at the first point that hits a zone polygon.
#
#     points: candidate (lon, lat) pairs, e.g. the address point then a point inside the parcel
#     (address points can fall on unzoned road reserve). Returns None if no service or no hit.
#     """
#     cfg = load_config().get(lg_id)
#     if not cfg or cfg.get("status") != "WORKING":
#         return None
#     nulls = set(cfg.get("null_values", [])) | {""}
#     clean = lambda v: None if v is None or str(v).strip() in nulls else str(v).strip()
#     for lon, lat in points:
#         a = _first(cfg["zone_layer"], lon, lat)
#         if not a:
#             continue
#         out = {"zone_text": clean(a.get(cfg["zone_field"])), "precinct_text": None, "local_plan_text": None,
#                "local_plan_precinct_text": None, "source": cfg["zone_layer"], "point": [lon, lat],
#                "notes": cfg.get("notes"), "raw": a}
#         if cfg.get("precinct_field"):
#             out["precinct_text"] = clean(a.get(cfg["precinct_field"]))
#         for layer in cfg.get("precinct_layers", []):
#             pa = _first(layer, lon, lat)
#             if pa and clean(pa.get(cfg["precinct_layer_field"])):
#                 out["precinct_text"] = clean(pa.get(cfg["precinct_layer_field"]))
#                 break
#         if cfg.get("local_plan_field"):
#             out["local_plan_text"] = clean(a.get(cfg["local_plan_field"]))
#             out["local_plan_precinct_text"] = clean(a.get(cfg.get("local_plan_precinct_field")))
#         if cfg.get("local_plan_layer"):   # neighbourhood plans on their own layers (Brisbane)
#             la = _first(cfg["local_plan_layer"], lon, lat)
#             out["local_plan_text"] = clean((la or {}).get(cfg["local_plan_layer_field"]))
#             pa = (_first(cfg["local_plan_precinct_layer"], lon, lat)
#                   if out["local_plan_text"] and cfg.get("local_plan_precinct_layer") else None)
#             out["local_plan_precinct_code"] = clean((pa or {}).get(cfg.get("local_plan_precinct_code_field")))
#             if cfg.get("local_plan_precinct_name_field"):
#                 out["local_plan_precinct_text"] = clean((pa or {}).get(cfg["local_plan_precinct_name_field"]))
#         return out
#     return None
#
#
# def overlays(lg_id, points):
#     """Overlay polygons at the property: [{'name', 'text', 'overlay_ids', 'source'}]. A hit at any of
#     the points counts (an overlay on part of the lot still applies to work on that part)."""
#     cfg = load_config().get(lg_id) or {}
#     out = []
#     for ov in cfg.get("overlay_layers", []):
#         texts = []
#         for lon, lat in points:
#             texts += [f["attributes"].get(ov["field"]) for f in geo.point_query(ov["layer"], lon, lat, ov["field"])]
#         for t in dict.fromkeys(str(t).strip() for t in texts if t not in (None, "")):
#             ids = ov.get("map", {}).get(t, ov.get("map", {}).get("*", []))   # '*': any value in the layer
#             hit = {"name": ov["name"], "text": t, "overlay_ids": ids, "source": ov["layer"]}
#             if ov.get("flag_fact"):
#                 hit["flag_fact"] = ov["flag_fact"]
#             if ov.get("value_fact"):   # value overlays, e.g. a mapped maximum height '8.5m'
#                 m = re.search(r"(\d+(?:\.\d+)?)\s*(?:metres?|m)(?![a-z])", t)   # '9m', '2(9m)' -> 9, '1(7.5m)' -> 7.5, '8.5 metres'
#                 hit["value_fact"], hit["value"] = ov["value_fact"], float(m.group(1)) if m else None
#             out.append(hit)
#     return out
#
#
# def overlay_flags(lg_id, hits):
#     """Yes/no facts from 'flag' overlays: True if the layer was hit, False if configured but not hit."""
#     cfg = load_config().get(lg_id) or {}
#     return {ov["flag_fact"]: any(h.get("flag_fact") == ov["flag_fact"] for h in hits)
#             for ov in cfg.get("overlay_layers", []) if ov.get("flag_fact")}
#
#
# def _contains(a, b):
#     a, b = _norm(a), _norm(b)
#     return bool(a and b) and (a in b or b in a)
#
#
# def match(found, zones, precincts, local_plans, local_plan_precincts):
#     """Map map-service text onto regs ids. Returns (zone_id, [precinct_id], [local_plan_id], [lpp_id], notes)."""
#     notes = []
#     zt = _norm(found["zone_text"])
#     zone_id = next((z["zone_id"] for z in zones if _norm(z["name"]) == zt), None)
#     if not zone_id:   # layer text may append the precinct, e.g. 'Character residential (Character)'
#         cands = [z for z in zones if _norm(z["name"]) and _norm(z["name"]) in zt]
#         zone_id = max(cands, key=lambda z: len(_norm(z["name"])))["zone_id"] if cands else None
#     if not zone_id:
#         notes.append(f"Zone '{found['zone_text']}' from the council map is not one of the zones in the rules dataset "
#                      "(no zone-specific council rules loaded for it).")
#     pids = []
#     ptext = found.get("precinct_text")
#     if ptext and zone_id:
#         pt = _norm(ptext)
#         mine = [p for p in precincts if p["zone_id"] == zone_id]
#         # exact name or code first ('Suburban' must not also match 'Large suburban' / 'Urban neighbourhood')
#         exact = [p for p in mine if pt in (_norm(p["name"]), _norm(p["precinct_id"].rsplit("/", 1)[-1]))]
#         if exact:
#             pids = [p["precinct_id"] for p in exact]
#         else:   # otherwise the single longest precinct name that appears as whole words in the map text
#             within = [p for p in mine if _norm(p["name"]) and f" {_norm(p['name'])} " in f" {pt} "]
#             pids = [max(within, key=lambda p: len(_norm(p["name"])))["precinct_id"]] if within else []
#         if not pids:
#             notes.append(f"Precinct '{ptext}' from the council map has no rules of its own in the dataset.")
#     lps, lpps = [], []
#     if found.get("local_plan_text"):
#         lps = [lp["local_plan_id"] for lp in local_plans if _contains(lp["name"], found["local_plan_text"])]
#         lpt = found.get("local_plan_precinct_text")
#         code = found.get("local_plan_precinct_code")
#         if lps and code:
#             lpps = [x["local_plan_precinct_id"] for x in local_plan_precincts
#                     if x["local_plan_id"] in lps and x["local_plan_precinct_id"].endswith("/" + code)]
#             if not lpps:
#                 notes.append(f"Neighbourhood plan precinct {code} has no rules of its own in the dataset.")
#         elif lps and lpt:
#             # exact name match: map text 'Urban living' must not select the dataset's
#             # 'Urban living precinct - Next generation sub-precinct' (sub-precincts are not mapped publicly)
#             lpps = [x["local_plan_precinct_id"] for x in local_plan_precincts
#                     if x["local_plan_id"] in lps and _norm(x["name"].split("(")[0]) == _norm(lpt)]
#             subs = [x["name"] for x in local_plan_precincts if x["local_plan_id"] in lps and not lpps
#                     and _norm(lpt) and _norm(x["name"]).startswith(_norm(lpt) + " ")]
#             if subs:
#                 notes.append(f"Local plan precinct '{lpt}': rules exist for {', '.join(subs)}, which the public map "
#                              "does not show — check the local plan map and choose it manually if it applies.")
#         if not lps:
#             notes.append(f"Local / neighbourhood plan '{found['local_plan_text']}' has no rules in the dataset yet.")
#     return zone_id, pids, lps, lpps, notes
