# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/core/site.ts
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Site constraints: easements, vegetation, flood, sewer / water / stormwater, electricity, heritage…
#
# Layers are configured in poc/site_layers.json:
#   {"STATE": [layer, ...], "BRISBANE": [layer, ...], ...}
#   layer = {"category", "name", "layer", "geometry", "label_field", "show_fields", "where"?, "distance_m"?, "always"?, "fact"?}
#
# Selection per category is council first: if the council publishes any layer for a category, only its layers are
# used; otherwise the State layers for that category are the fallback. A State layer with "always": true is used
# even when the council has the category (e.g. Powerlink transmission lines). Each layer is queried with the whole
# lot polygon (an easement or sewer line at the back of the lot is not under the address point).
# """
# import concurrent.futures as cf
# import json
# import pathlib
#
# from . import geo
#
# CONFIG = pathlib.Path(__file__).resolve().parent.parent / "site_layers.json"
#
#
# def load_config():
#     return json.loads(CONFIG.read_text(encoding="utf-8")) if CONFIG.exists() else {}
#
#
# def layers_for(lg_id):
#     cfg = load_config()
#     council = [{**l, "scope": "council"} for l in cfg.get(lg_id, [])]
#     have = {l["category"] for l in council}
#     state = [{**l, "scope": "State"} for l in cfg.get("STATE", []) if l["category"] not in have or l.get("always")]
#     return council + state
#
#
# def _check(l, rings):
#     try:
#         feats = geo.lot_query(l["layer"], rings, distance_m=l.get("distance_m"), where=l.get("where", "1=1"),
#                                exclude_touching=l.get("geometry") == "polygon")
#     except Exception as e:  # noqa: BLE001 — one failing service must not break the result
#         return {**_meta(l), "status": "error", "error": str(e)[:160], "hit": None, "features": []}
#     labels, details = [], []
#     for f in feats:
#         a = f.get("attributes", {})
#         lab = a.get(l.get("label_field")) if l.get("label_field") else None
#         if lab not in (None, ""):
#             labels.append(str(lab).strip())
#         details.append({k: a.get(k) for k in l.get("show_fields", []) if a.get(k) not in (None, "")})
#     return {**_meta(l), "status": "ok", "hit": bool(feats), "count": len(feats),
#             "values": list(dict.fromkeys(labels))[:12], "details": details[:20]}
#
#
# def _meta(l):
#     return {k: l.get(k) for k in ("category", "name", "layer", "geometry", "scope", "distance_m", "fact", "label_field")}
#
#
# def constraints(lg_id, rings, workers=16):
#     """Query every selected layer against the lot. Returns one row per layer, hits first within each category."""
#     ls = layers_for(lg_id)
#     if not rings or not ls:
#         return []
#     with cf.ThreadPoolExecutor(min(workers, len(ls))) as ex:
#         rows = list(ex.map(lambda l: _check(l, rings), ls))
#     return sorted(rows, key=lambda r: (r["category"], not r["hit"], r["name"]))
#
#
# def facts_from(rows):
#     """Yes/no facts from layers that declare one (e.g. sewer/water mains -> infrastructure_on_lot).
#     True if any such layer hits; False only if every such layer answered and none hit."""
#     out = {}
#     for r in rows:
#         f = r.get("fact")
#         if not f:
#             continue
#         cur = out.get(f)
#         if r["status"] != "ok":
#             out[f] = cur if cur is True else None
#         elif r["hit"]:
#             out[f] = True
#         elif cur is None and f not in out:
#             out[f] = False
#     return {k: v for k, v in out.items() if v is not None}
