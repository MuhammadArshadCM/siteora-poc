# Logan, LDR Acreage precinct, 8,000 m2 lot — 180 m2 machinery shed, 5.0 m high  (assessment date 2026-10-09)

## Shed 15 m x 12 m, 5.0 m high (only outbuilding on the lot)
- [BUILDING] HEIGHT.BUILDING : <= 8.5 m  [DETERMINED]
    QDC12.A4.BUILDING_HEIGHT@2010-03-26 — Maximum building height by lot slope
    source: QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over (Publication date 11 March 2010) — A4
- [BUILDING] HEIGHT.CLASS_10A : <= 5.5 m  [DETERMINED]
    LCC.C.LARGE_OUTBUILDING_HEIGHT_5_5@2025-07-01 — Domestic outbuildings where total floor area exceeds 150 m2: height <= 5.5 m
    source: Logan Planning Scheme 2015 (Version 9.2 (printed with TLPI No. 1/2024 - flood)) — Table 9.3.2.3.1 PO7/AO7.1(b)(ii)
- [BUILDING] OUTBUILDING.SIZE : <= 300 m2  [DETERMINED]
    LCC.C.LARGE_OUTBUILDING_MAX_300@2025-07-01 — Domestic outbuildings over 150 m2 (rural-type zones in Table 9.3.2.3.2): cumulative floor area <= 300 m2
    source: Logan Planning Scheme 2015 (Version 9.2 (printed with TLPI No. 1/2024 - flood)) — Table 9.3.2.3.1 PO7/AO7.1(b)(iii)
- [BUILDING] SETBACK.FRONTAGE (PRIMARY_FRONTAGE): >= 10 m  [DETERMINED]
    LCC.C.ROAD_CLEARANCE_10M@2025-07-01 — Emerging community, LDR Acreage/Small acreage, listed Rural residential precincts: road boundary clearance >= 10 m
    source: Logan Planning Scheme 2015 (Version 9.2 (printed with TLPI No. 1/2024 - flood)) — Table 9.3.2.3.1 PO4/AO4(c)
- [BUILDING] SETBACK.SIDE_REAR (REAR): >= 6 m  [DETERMINED]
    LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M@2025-07-01 — Large domestic outbuildings (> 150 m2): side and rear 6 m (EC, LDR Acreage/Small acreage, Rural residential)
    source: Logan Planning Scheme 2015 (Version 9.2 (printed with TLPI No. 1/2024 - flood)) — Table 9.3.2.3.2 (via AO7.1(b)(i))
- [BUILDING] SETBACK.SIDE_REAR (SIDE): >= 6 m  [DETERMINED]
    LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M@2025-07-01 — Large domestic outbuildings (> 150 m2): side and rear 6 m (EC, LDR Acreage/Small acreage, Rural residential)
    source: Logan Planning Scheme 2015 (Version 9.2 (printed with TLPI No. 1/2024 - flood)) — Table 9.3.2.3.2 (via AO7.1(b)(i))
- [BUILDING] SITE_COVER : <= 20 %  [DETERMINED]
    LCC.C.SITE_COVER_LDR_ACREAGE@2025-07-01 — LDR Acreage precinct: site cover <= 20%
    source: Logan Planning Scheme 2015 (Version 9.2 (printed with TLPI No. 1/2024 - flood)) — Table 9.3.2.3.1 PO3/AO3(c)
  displaced:
    - QDC12.A3.SITE_COVER@2010-03-26 (None): OVERRIDES by LCC.C.SITE_COVER_LDR_ACREAGE@2025-07-01
    - LCC.C.OUTBUILDING_FLOOR_AREA_150@2025-07-01 (None): RELAXED by LCC.C.LARGE_OUTBUILDING_MAX_300@2025-07-01
    - QDC12.A1a.ROAD_SETBACK@2010-03-26 (PRIMARY_FRONTAGE): OVERRIDES by LCC.C.ROAD_CLEARANCE_10M@2025-07-01
    - QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26 (SIDE): OVERRIDES by LCC.C.SIDE_REAR_3M_ACREAGE@2025-07-01
    - LCC.C.SIDE_REAR_3M_ACREAGE@2025-07-01 (SIDE): OVERRIDES by LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M@2025-07-01
    - QDC12.A2a.SIDE_REAR_CLEARANCE@2010-03-26 (REAR): OVERRIDES by LCC.C.SIDE_REAR_3M_ACREAGE@2025-07-01
    - LCC.C.SIDE_REAR_3M_ACREAGE@2025-07-01 (REAR): OVERRIDES by LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M@2025-07-01

