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
- [FIRE_SAFETY] CONSTRUCTION.FIRE_SEPARATION : must hold  [MANUAL_REVIEW]
    NCC.PT9_2.CLASS10A_FIRE_SEPARATION@2022-05-01 — Class 10a wall within 900 mm of a boundary (not a road) or 1.8 m of another building must be fire-separated construction
    source: National Construction Code (NCC 2022, adopted Housing Provisions (Volume Two equivalent)) — 9.2.4(1)(a), 9.2.5; 9.2.4(1)(b), 9.2.6
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
- [POOL_SAFETY] POOL_SAFETY.BARRIER_ACCESS : must hold  [MANUAL_REVIEW]
    MP34.S1_21.DESIGNATED_ACCESS_POINT@2012-07-27 — A designated pool access point, enclosed by a compliant barrier and gate, must be provided
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — Sch 1 item 21
- [POOL_SAFETY] POOL_SAFETY.BARRIER_ACCESS : must hold  [MANUAL_REVIEW]
    MP34.S1_26.INDOOR_CHILD_RESISTANT_DOORSET@2012-07-27 — Indoor pool access must be via a compliant child-resistant doorset (or another compliant barrier)
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — Sch 1 item 26
- [POOL_SAFETY] POOL_SAFETY.BARRIER_CONSTRUCTION : must hold  [MANUAL_REVIEW]
    MP34.S1_16.RETAINING_WALL_BARRIER_NO_FOOTHOLD@2012-07-27 — Overhang/return fencing atop a retaining wall used as a barrier must have no foothold/handhold surface
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — Sch 1 item 16
- [POOL_SAFETY] POOL_SAFETY.BARRIER_CONSTRUCTION : <= 100 mm  [MANUAL_REVIEW]
    MP34.AS1926.BARRIER_MAX_GAP_100@2012-07-27 — No gap or hole greater than 100 mm anywhere in the pool barrier
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — 2.3.7
- [POOL_SAFETY] POOL_SAFETY.BARRIER_CONSTRUCTION : <= 100 mm  [MANUAL_REVIEW]
    MP34.AS1926.BARRIER_GROUND_GAP_100@2012-07-27 — Maximum 100 mm gap from finished ground level to the bottom of the pool barrier
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — 2.4
- [POOL_SAFETY] POOL_SAFETY.BARRIER_CONSTRUCTION : must hold  [MANUAL_REVIEW]
    MP34.S1_17.WATER_BODY_AS_BARRIER@2012-07-27 — A canal/lake/river/creek/stream/pond/ocean/dam may form part of the pool barrier, subject to depth/width/access/overhang-or-return conditions
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — Sch 1 item 17
- [POOL_SAFETY] POOL_SAFETY.BARRIER_NCZ : >= 900 mm  [MANUAL_REVIEW]
    MP34.S1_13.NCZ_HORIZONTAL_MEMBER_GAP_900@2012-07-27 — Non-climbable zone: clear gap between horizontal members >= 900 mm
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — Sch 1 item 13
- [POOL_SAFETY] POOL_SAFETY.BARRIER_NCZ : >= 300 mm  [MANUAL_REVIEW]
    MP34.FIG1.CLEAR_AREA_FOOTHOLD_300@2012-07-27 — Non-climbable zone: clear area free of footholds/climbable objects >= 300 mm
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — Figure 1
- [POOL_SAFETY] POOL_SAFETY.BARRIER_NCZ : must hold  [MANUAL_REVIEW]
    MP34.S1_19_20.BALCONY_NCZ@2012-07-27 — Balcony pools: an additional non-climbable zone (Figure 23) is required unless the balcony itself has a compliant barrier
    source: QDC MP 3.4 - Swimming pool barriers (Publication date 18 July 2012) — Sch 1 items 19-20
  displaced:
    - QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26 (SIDE): EXEMPTS by QDC12.A2c.EXEMPT_FENCES_WALLS@2010-03-26
    - QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26 (REAR): EXEMPTS by QDC12.A2c.EXEMPT_FENCES_WALLS@2010-03-26

