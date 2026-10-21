# Brisbane, Low density residential, 607 m2 interior lot — shed and pool  (assessment date 2026-10-09)

## Shed 6.0 m x 4.0 m, 3.0 m high (rear corner)
- [BUILDING] HEIGHT.BUILDING : <= 9.5 m  [DETERMINED]
    BCC.C.DH_HEIGHT_9_5@2026-09-18 — Dwelling house (standard lot): maximum building height 9.5 m and 2 storeys
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.7.3 Table 9.3.7.3.A, PO2/AO2
- [BUILDING] SETBACK.ROAD (PRIMARY_FRONTAGE): >= 6 m  [DETERMINED]
    QDC12.A1a.ROAD_SETBACK@2010-03-26 — Minimum road setback 6 m (dwelling, garage, carport; structures via A1(d))
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A1(a)
- [BUILDING] SETBACK.SIDE_REAR.BTB (REAR): BTB permitted (0 m)  [DETERMINED]
    QDC12.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26 — Class 10a within side/rear clearance (up to built to boundary)
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A2(d)
- [BUILDING] SETBACK.SIDE_REAR.BTB (SIDE): BTB permitted (0 m)  [DETERMINED]
    QDC12.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26 — Class 10a within side/rear clearance (up to built to boundary)
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A2(d)
- [BUILDING] SITE_COVER : <= 50 %  [DETERMINED]
    QDC12.A3.SITE_COVER@2010-03-26 — Maximum site cover 50% (roofed with impervious materials)
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A3
  displaced:
    - QDC12.A4.BUILDING_HEIGHT@2010-03-26 (None): OVERRIDES by BCC.C.DH_HEIGHT_9_5@2026-09-18
    - QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26 (SIDE): RELAXED by QDC12.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26
    - QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26 (REAR): RELAXED by QDC12.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26

## In-ground pool, coping 0.3 m above ground
- [BUILDING] POOL.SETBACK.ROAD (PRIMARY_FRONTAGE): >= 1.5 m  [DETERMINED]
    QDC12.A1d.POOL_ROAD_SETBACK@2010-03-26 — Pool water's edge to road frontage 1.5 m (coping <= 1.2 m)
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A1(d)
- [BUILDING] POOL.SETBACK.SIDE_REAR (REAR): >= 1.5 m  [DETERMINED]
    QDC12.A2a.POOL_SIDE_REAR@2010-03-26 — Swimming pool side and rear boundary clearance (from water's edge)
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A2(a)
- [BUILDING] POOL.SETBACK.SIDE_REAR (SIDE): >= 1.5 m  [DETERMINED]
    QDC12.A2a.POOL_SIDE_REAR@2010-03-26 — Swimming pool side and rear boundary clearance (from water's edge)
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A2(a)
- [BUILDING] SITE_COVER : <= 50 %  [DETERMINED]
    QDC12.A3.SITE_COVER@2010-03-26 — Maximum site cover 50% (roofed with impervious materials)
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A3
- [POOL_SAFETY] POOL.BARRIER.PRESENCE : must hold  [MANUAL_REVIEW]
    MP34.P1.BARRIER_REQUIRED@2012-07-27 — Regulated pool must have a continuous barrier restricting young children's access
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — P1

## Pool fence 1.2 m (NCZ outside) with gate
- [BUILDING] SITE_COVER : <= 50 %  [DETERMINED]
    QDC12.A3.SITE_COVER@2010-03-26 — Maximum site cover 50% (roofed with impervious materials)
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A3
- [POOL_SAFETY] POOL.BARRIER.HEIGHT : >= 1200 mm  [DETERMINED]
    MP34.FIG1.BARRIER_MIN_HEIGHT@2012-07-27 — Pool fence minimum height 1200 mm, measured on the NCZ side
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — Figure 1
- [POOL_SAFETY] POOL.BARRIER.LOCATION : must not occur  [MANUAL_REVIEW]
    MP34.P1e.NO_BUILDING_DOORS@2012-07-27 — Outdoor pool barrier must not incorporate doors to or from a building
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — P1
  displaced:
    - QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26 (SIDE): EXEMPTS by QDC12.A2c.EXEMPT_FENCES_WALLS@2010-03-26
    - QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26 (REAR): EXEMPTS by QDC12.A2c.EXEMPT_FENCES_WALLS@2010-03-26

