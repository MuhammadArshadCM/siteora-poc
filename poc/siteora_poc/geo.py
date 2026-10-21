# RETIRED 2026-10-16: the project now runs on TypeScript / Ts.ED only (see server-ts/README.md).
# Replaced by: server-ts/src/core/geo.ts
# This file is kept, commented out, for reference only; nothing imports or runs it.
# To restore it, remove the leading "# " from every line below this header.
#
# """Queensland Government spatial lookups: address -> point -> council, parcel, PDA.
#
# All services are public ArcGIS REST endpoints run by the Queensland Government
# (spatial-gis.information.qld.gov.au). Stdlib only.
# """
# import http.client
# import json
# import math
# import re
# import urllib.error
# import urllib.parse
# import urllib.request
#
# QSPATIAL = "https://spatial-gis.information.qld.gov.au/arcgis/rest/services"
# GEOCODER = f"{QSPATIAL}/Location/QldLocator/GeocodeServer/findAddressCandidates"
# CADASTRE = f"{QSPATIAL}/PlanningCadastre/LandParcelPropertyFramework/MapServer"
# ADDRESS_LAYER = f"{CADASTRE}/0"
# PARCEL_LAYER = f"{CADASTRE}/4"
# LGA_LAYER = f"{CADASTRE}/20"
# PDA_LAYER = f"{QSPATIAL}/PlanningCadastre/PriorityDevelopmentAreas/MapServer/10"
#
# # LGA layer 'abbrev_name' -> regs.local_governments.lg_id
# LGA_TO_LG = {
#     "BRISBANE": "BRISBANE", "GOLD COAST": "GOLD_COAST", "MORETON BAY": "MORETON_BAY",
#     "SUNSHINE COAST": "SUNSHINE_COAST", "LOGAN": "LOGAN", "IPSWICH": "IPSWICH", "REDLAND": "REDLAND",
# }
#
#
# def get_json(url, params, timeout=20, attempts=3, post=False):
#     """GET (or POST, for long geometries — long GET URLs fail silently on some servers) an ArcGIS REST call."""
#     body = urllib.parse.urlencode(params).encode() if post else None
#     full = url if post else f"{url}?{urllib.parse.urlencode(params)}"
#     req = urllib.request.Request(full, data=body, headers={"User-Agent": "siteora-poc/0.1",
#                                  **({"Content-Type": "application/x-www-form-urlencoded"} if post else {})})
#     for i in range(attempts):
#         try:
#             with urllib.request.urlopen(req, timeout=timeout) as r:
#                 data = json.loads(r.read().decode("utf-8"))
#             break
#         except (urllib.error.URLError, TimeoutError, ConnectionError, http.client.HTTPException):   # incl. dropped connections
#             if i == attempts - 1:
#                 raise
#     if "error" in data:
#         raise RuntimeError(f"{url}: {data['error']}")
#     return data
#
#
# def point_query(layer, lon, lat, out_fields="*", geometry=False, where="1=1", distance_m=None):
#     params = {"geometry": f"{lon},{lat}", "geometryType": "esriGeometryPoint", "inSR": 4326,
#               "spatialRel": "esriSpatialRelIntersects", "outFields": out_fields, "where": where,
#               "returnGeometry": str(geometry).lower(), "outSR": 4326, "f": "json"}
#     if distance_m:
#         params.update({"distance": distance_m, "units": "esriSRUnit_Meter"})
#     return get_json(f"{layer}/query", params)["features"]
#
#
# def lot_query(layer, rings, out_fields="*", distance_m=None, where="1=1", exclude_touching=False):
#     """Features of a layer that intersect the lot (or lie within distance_m of it). rings: lon/lat parcel rings.
#
#     exclude_touching (polygon layers): drop features that only share a boundary with the lot, e.g. an easement
#     or overlay polygon on the neighbouring land that ends at the fence line."""
#     params = {"geometry": json.dumps({"rings": rings, "spatialReference": {"wkid": 4326}}),
#               "geometryType": "esriGeometryPolygon", "inSR": 4326, "spatialRel": "esriSpatialRelIntersects",
#               "outFields": out_fields, "where": where, "returnGeometry": "false", "f": "json"}
#     if distance_m:
#         params.update({"distance": distance_m, "units": "esriSRUnit_Meter"})
#     data = get_json(f"{layer}/query", params, timeout=30, post=True)
#     feats = data["features"]
#     if exclude_touching and feats and not distance_m:
#         oid = data.get("objectIdFieldName") or next((k for k in feats[0]["attributes"] if k.lower() in ("objectid", "fid", "oid")), None)
#         if oid:
#             touch = get_json(f"{layer}/query", {**params, "spatialRel": "esriSpatialRelTouches", "outFields": oid},
#                              timeout=30, post=True)["features"]
#             only_touch = {t["attributes"].get(oid) for t in touch}
#             feats = [f for f in feats if f["attributes"].get(oid) not in only_touch]
#     return feats
#
#
# def geocode(address):
#     """Exact-enough match only. The State geocoder is fuzzy: it will happily return '2 Ashmore Street,
#     Everton Park' for '2 Ashmore Road, Bundall'. It reports input it could not match in ExInfo, so a
#     match is accepted only if score >= 95, or score >= 90 with nothing unmatched; otherwise the
#     candidates are returned in the error so the user can pick one."""
#     data = get_json(GEOCODER, {"SingleLine": address, "outSR": 4326, "maxLocations": 5, "outFields": "Match_addr,ExInfo,City,Subregion", "f": "json"})
#     cands = data.get("candidates") or []
#     # the geocoder never matches postcodes, so a postcode alone in ExInfo is not a mismatch
#     unmatched = lambda c: " | ".join(t.strip() for t in (c["attributes"].get("ExInfo") or "").split("|")
#                                      if t.strip() and not re.fullmatch(r"\d{4}", t.strip()))
#     # >= 95: accept (warn about any unmatched words, e.g. a neighbouring suburb name);
#     # 90-95: accept only if every word matched; below 90: never.
#     good = [c for c in cands if c["score"] >= 95 or (c["score"] >= 90 and not unmatched(c))]
#     if not good:
#         listed = "; ".join(f"{c['address']} ({c['score']:.0f}%)" for c in cands[:5]) or "none"
#         raise LookupError(f"No exact match for {address!r}. Closest candidates: {listed}. "
#                           "Check the street type, suburb and postcode, or enter one of the candidates.")
#     best = good[0]
#     return {"address": best["address"], "lon": best["location"]["x"], "lat": best["location"]["y"], "score": best["score"],
#             "unmatched_input": unmatched(best) or None, "source": "QldLocator geocoder (Queensland Government)"}
#
#
# def council_at(lon, lat):
#     feats = point_query(LGA_LAYER, lon, lat, "lga,abbrev_name")
#     if not feats:
#         raise LookupError("Point is not inside a Queensland local government area")
#     a = feats[0]["attributes"]
#     return {"lga_name": a["lga"], "lg_id": LGA_TO_LG.get(a["abbrev_name"])}
#
#
# def parcel_at(lon, lat):
#     """The land parcel at the point. Geocoded points can fall on the road parcel; fall back to the
#     address point's lot/plan from the Addresses layer."""
#     feats = [f for f in point_query(PARCEL_LAYER, lon, lat, "lot,plan,lotplan,lot_area,parcel_typ,tenure", geometry=True)
#              if f["attributes"].get("lotplan")]
#     if not feats:
#         addrs = point_query(ADDRESS_LAYER, lon, lat, "lotplan,address", distance_m=25)
#         lotplans = [a["attributes"]["lotplan"] for a in addrs if a["attributes"].get("lotplan")]
#         if lotplans:
#             feats = get_json(f"{PARCEL_LAYER}/query", {"where": f"lotplan = '{lotplans[0]}'", "outFields": "lot,plan,lotplan,lot_area,parcel_typ,tenure",
#                                                        "returnGeometry": "true", "outSR": 4326, "f": "json"})["features"]
#     if not feats:
#         raise LookupError("No land parcel found at this address")
#     f = feats[0]
#     return {**f["attributes"], "rings": f["geometry"]["rings"]}
#
#
# def pda_at(lon, lat):
#     feats = point_query(PDA_LAYER, lon, lat, "pda_name,pda_status")
#     return feats[0]["attributes"] if feats else None
#
#
# # ----------------------------------------------------------------------------- parcel geometry
# def _project(rings):
#     """Lon/lat -> local metres (equirectangular about the first vertex; fine at lot scale)."""
#     lon0, lat0 = rings[0][0]
#     kx = 111320.0 * math.cos(math.radians(lat0))
#     ky = 110540.0
#     return [[((x - lon0) * kx, (y - lat0) * ky) for x, y in ring] for ring in rings]
#
#
# def _area(ring):
#     return abs(sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(ring, ring[1:] + ring[:1]))) / 2
#
#
# def _hull(points):
#     pts = sorted(set(points))
#     if len(pts) < 3:
#         return pts
#     cross = lambda o, a, b: (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
#     lower, upper = [], []
#     for p in pts:
#         while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
#             lower.pop()
#         lower.append(p)
#     for p in reversed(pts):
#         while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
#             upper.pop()
#         upper.append(p)
#     return lower[:-1] + upper[:-1]
#
#
# def parcel_metrics(rings):
#     """Estimate lot width/depth and rectangularity from the parcel outline.
#
#     Uses the minimum-area bounding rectangle: width = short side, depth = long side. These are
#     ESTIMATES (the frontage boundary is not identified) and are labelled as such in the output.
#     """
#     proj = _project(rings)
#     outer = max(proj, key=_area)
#     area = _area(outer)
#     hull = _hull(outer)
#     best = None
#     for (x1, y1), (x2, y2) in zip(hull, hull[1:] + hull[:1]):
#         ang = math.atan2(y2 - y1, x2 - x1)
#         c, s = math.cos(-ang), math.sin(-ang)
#         xs = [x * c - y * s for x, y in hull]
#         ys = [x * s + y * c for x, y in hull]
#         w, h = max(xs) - min(xs), max(ys) - min(ys)
#         if best is None or w * h < best[0]:
#             best = (w * h, min(w, h), max(w, h))
#     rect_area, width, depth = best
#     return {"computed_area_m2": round(area, 1), "est_width_m": round(width, 2), "est_depth_m": round(depth, 2),
#             "rectangularity": round(area / rect_area, 3) if rect_area else None}
