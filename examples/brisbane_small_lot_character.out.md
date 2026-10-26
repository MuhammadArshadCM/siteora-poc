# Brisbane, Character residential, 380 m2 small lot in the Traditional building character + Dwelling house character overlays — shed and front carport  (assessment date 2026-10-12)

## Shed 3.0 m x 3.0 m, 2.6 m high (rear corner)
- [BUILDING] HEIGHT.BUILDING : <= 9.5 m  [DETERMINED]
    BCC.C.SL_HEIGHT@2026-09-18 — Small lot (LDR, CR, LMR 2-storey mix): height 7.5 m at side/rear walls rising at no more than 30 degrees to 9.5 m, 2 storeys
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO3/AO3
- [BUILDING] SETBACK.FRONTAGE (PRIMARY_FRONTAGE): >= 4.5 m  [DETERMINED]
    BCC.C.SL_FRONT_PRIMARY@2026-09-18 — Small lot: primary street setback 6 m / least adjoining setback (min 3 m) / 3 m if no adjoining house
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO5/AO5(a)
- [BUILDING] SETBACK.FRONTAGE (PRIMARY_FRONTAGE): >= None m  [MANUAL_REVIEW]
    BCC.C.TBC_FRONT_SETBACK_AVERAGE@2026-09-18 — Character overlay (LMR, CR zones): front setback within 20% of the average of nearby pre-1946 houses (excl. eaves, stairs, garage)
    source: Brisbane City Plan 2014 (v37.00/2026) — 8.2.22.3 Table 8.2.22.3, PO1/AO1.2
- [BUILDING] SETBACK.REAR (REAR): >= 6 m  [DETERMINED]
    BCC.C.SL_REAR@2026-09-18 — Small lot: rear setback 6 m (lot deeper than 25 m) or 3 m / 4.5 m by height (lot 25 m deep or less) — applies to all buildings and structures
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO7/AO7
- [BUILDING] SETBACK.SIDE (SIDE): >= 0.5 m  [DETERMINED]
    BCC.C.SL_SIDE_NONHABITABLE_LDR_CR@2026-09-18 — Small lot (LDR, CR): non-habitable spaces 0.5 m from side boundary, max 3.5 m high, max 9 m long
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO6/AO6(a)-(b)
- [BUILDING] SETBACK.SIDE_REAR.BTB (SIDE): BTB permitted (0 m)  [MANUAL_REVIEW]
    BCC.C.SL_SIDE_ZERO@2026-09-18 — Small lot: 0 m side setback where matching an adjoining built-to-boundary wall, or the adjoining lot is 300 m2 or less (not Character precinct)
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO6/AO6(c)
- [BUILDING] SITE_COVER : <= 60 %  [DETERMINED]
    BCC.C.SL_SITE_COVER@2026-09-18 — Small lot: site cover 50% (400 m2+), 60% (300-400), 70% (200-300), 80% (under 200)
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO8/AO8
- [INFRASTRUCTURE] INFRASTRUCTURE.SEPARATION : >= 1.2 m  [MANUAL_REVIEW]
    MP14.A2_1.FOOTING_1_2M@2014-12-15 — Wall/footing/pile/pier/floor at least 1.2 m from infrastructure centreline (not light-weight Class 10)
    source: QDC MP 1.4 - Building over or near relevant infrastructure (Version 1.2, published 13 November 2014) — A2.1(2)
- [INFRASTRUCTURE] INFRASTRUCTURE.SEPARATION : >= 1.5 m  [MANUAL_REVIEW]
    MP14.A2_1.COVER_CLEAR_ZONE@2014-12-15 — Nothing (incl. overhangs) within 1.5 m radius of a maintenance cover
    source: QDC MP 1.4 - Building over or near relevant infrastructure (Version 1.2, published 13 November 2014) — A2.1(2)
- [INFRASTRUCTURE] INFRASTRUCTURE.SEPARATION : <= 10 m  [MANUAL_REVIEW]
    MP14.A2_2.LIGHTWEIGHT_MAX_10M_OVER@2014-12-15 — Light-weight Class 10 may extend over the infrastructure for not more than 10 m
    source: QDC MP 1.4 - Building over or near relevant infrastructure (Version 1.2, published 13 November 2014) — A2.2
- [PLANNING] OUTBUILDING.SIZE : <= 10 m2  [MANUAL_REVIEW]
    BCC.C.DHC_SMALL_LOT_SHED@2026-09-18 — Dwelling house character overlay, small lot: one shed outside the building envelope needs no planning approval only if roofed area <= 10 m2 and height <= 3 m
    source: Brisbane City Plan 2014 (v37.00/2026) — 5.3.4 Table 5.3.4.1 (Building work, Dwelling house character overlay, small lot)
  displaced:
    - QDC11.A3.SITE_COVER@2010-03-26 (None): OVERRIDES by BCC.C.SL_SITE_COVER@2026-09-18
    - QDC11.A4.BUILDING_HEIGHT@2010-03-26 (None): OVERRIDES by BCC.C.SL_HEIGHT@2026-09-18
    - QDC11.A1a.FRONTAGE_SETBACK@2010-03-26 (PRIMARY_FRONTAGE): OVERRIDES by BCC.C.TBC_FRONT_SETBACK_AVERAGE@2026-09-18
    - QDC11.A2b.NARROW_LOT_CLEARANCE@2010-03-26 (SIDE): OVERRIDES by BCC.C.SL_SIDE_HABITABLE@2026-09-18
    - QDC11.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26 (SIDE): OVERRIDES by BCC.C.SL_SIDE_HABITABLE@2026-09-18
    - BCC.C.SL_SIDE_HABITABLE@2026-09-18 (SIDE): RELAXED by BCC.C.SL_SIDE_NONHABITABLE_LDR_CR@2026-09-18
    - QDC11.A2b.NARROW_LOT_CLEARANCE@2010-03-26 (REAR): OVERRIDES by BCC.C.SL_REAR@2026-09-18
    - QDC11.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26 (REAR): OVERRIDES by BCC.C.SL_REAR@2026-09-18

## Carport 6.0 m x 3.5 m, 3.0 m high, forward of the house
- [BUILDING] GARAGE.OPENING_WIDTH (PRIMARY_FRONTAGE): <= 5.03 m  [DETERMINED]
    QDC11.A1b.GARAGE_OPENING_WIDTH@2010-03-26 — Garage/carport openings facing street: lesser of 6 m and 50% of frontage
    source: QDC MP 1.1 - Design and siting standard for single detached housing - on lots under 450m2 (Publication date 11 March 2010) — A1(b)
- [BUILDING] HEIGHT.BUILDING : <= 9.5 m  [DETERMINED]
    BCC.C.SL_HEIGHT@2026-09-18 — Small lot (LDR, CR, LMR 2-storey mix): height 7.5 m at side/rear walls rising at no more than 30 degrees to 9.5 m, 2 storeys
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO3/AO3
- [BUILDING] SETBACK.FRONTAGE (PRIMARY_FRONTAGE): >= 4.5 m  [DETERMINED]
    BCC.C.SL_FRONT_PRIMARY@2026-09-18 — Small lot: primary street setback 6 m / least adjoining setback (min 3 m) / 3 m if no adjoining house
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO5/AO5(a)
- [BUILDING] SETBACK.FRONTAGE (PRIMARY_FRONTAGE): >= None m  [MANUAL_REVIEW]
    BCC.C.TBC_FRONT_SETBACK_AVERAGE@2026-09-18 — Character overlay (LMR, CR zones): front setback within 20% of the average of nearby pre-1946 houses (excl. eaves, stairs, garage)
    source: Brisbane City Plan 2014 (v37.00/2026) — 8.2.22.3 Table 8.2.22.3, PO1/AO1.2
- [BUILDING] SETBACK.REAR (REAR): >= 6 m  [DETERMINED]
    BCC.C.SL_REAR@2026-09-18 — Small lot: rear setback 6 m (lot deeper than 25 m) or 3 m / 4.5 m by height (lot 25 m deep or less) — applies to all buildings and structures
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO7/AO7
- [BUILDING] SETBACK.SIDE (SIDE): >= 0.5 m  [DETERMINED]
    BCC.C.SL_SIDE_NONHABITABLE_LDR_CR@2026-09-18 — Small lot (LDR, CR): non-habitable spaces 0.5 m from side boundary, max 3.5 m high, max 9 m long
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO6/AO6(a)-(b)
- [BUILDING] SETBACK.SIDE_REAR.BTB (SIDE): BTB permitted (0 m)  [MANUAL_REVIEW]
    BCC.C.SL_SIDE_ZERO@2026-09-18 — Small lot: 0 m side setback where matching an adjoining built-to-boundary wall, or the adjoining lot is 300 m2 or less (not Character precinct)
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO6/AO6(c)
- [BUILDING] SITE_COVER : <= 60 %  [DETERMINED]
    BCC.C.SL_SITE_COVER@2026-09-18 — Small lot: site cover 50% (400 m2+), 60% (300-400), 70% (200-300), 80% (under 200)
    source: Brisbane City Plan 2014 (v37.00/2026) — 9.3.8.3 Table 9.3.8.3.A, PO8/AO8
- [INFRASTRUCTURE] INFRASTRUCTURE.SEPARATION : >= 1.2 m  [MANUAL_REVIEW]
    MP14.A2_1.FOOTING_1_2M@2014-12-15 — Wall/footing/pile/pier/floor at least 1.2 m from infrastructure centreline (not light-weight Class 10)
    source: QDC MP 1.4 - Building over or near relevant infrastructure (Version 1.2, published 13 November 2014) — A2.1(2)
- [INFRASTRUCTURE] INFRASTRUCTURE.SEPARATION : >= 1.5 m  [MANUAL_REVIEW]
    MP14.A2_1.COVER_CLEAR_ZONE@2014-12-15 — Nothing (incl. overhangs) within 1.5 m radius of a maintenance cover
    source: QDC MP 1.4 - Building over or near relevant infrastructure (Version 1.2, published 13 November 2014) — A2.1(2)
- [INFRASTRUCTURE] INFRASTRUCTURE.SEPARATION : <= 10 m  [MANUAL_REVIEW]
    MP14.A2_2.LIGHTWEIGHT_MAX_10M_OVER@2014-12-15 — Light-weight Class 10 may extend over the infrastructure for not more than 10 m
    source: QDC MP 1.4 - Building over or near relevant infrastructure (Version 1.2, published 13 November 2014) — A2.2
- [PLANNING] GARAGE.OPENING_WIDTH (PRIMARY_FRONTAGE): <= 5.03 m  [DETERMINED]
    BCC.C.TBC_CARPORT_FORWARD_ACCEPTED@2026-09-18 — Character overlay: carport between the house and the front boundary needs no planning approval only if total width <= lesser of 6 m and 50% of average lot width
    source: Brisbane City Plan 2014 (v37.00/2026) — 5.3.4 Table 5.3.4.1 (Building work, Traditional building character overlay / Pre-1911 building overlay)
- [PLANNING] SETBACK.FRONTAGE (PRIMARY_FRONTAGE): >= 2 m  [MANUAL_REVIEW]
    BCC.C.DHC_SMALL_LOT_DOUBLE_CARPORT_FRONT@2026-09-18 — Dwelling house character overlay, small lot: double carport outside the building envelope needs no planning approval only if set back >= 2 m from the front boundary
    source: Brisbane City Plan 2014 (v37.00/2026) — 5.3.4 Table 5.3.4.1 (Building work, Dwelling house character overlay, small lot)
- [PLANNING] SETBACK.SIDE (SIDE): >= 1.5 m  [MANUAL_REVIEW]
    BCC.C.DHC_SMALL_LOT_DOUBLE_CARPORT_SIDE@2026-09-18 — Dwelling house character overlay, small lot: double carport outside the building envelope needs no planning approval only if set back >= 1.5 m from the side boundary
    source: Brisbane City Plan 2014 (v37.00/2026) — 5.3.4 Table 5.3.4.1 (Building work, Dwelling house character overlay, small lot)
  displaced:
    - QDC11.A3.SITE_COVER@2010-03-26 (None): OVERRIDES by BCC.C.SL_SITE_COVER@2026-09-18
    - QDC11.A4.BUILDING_HEIGHT@2010-03-26 (None): OVERRIDES by BCC.C.SL_HEIGHT@2026-09-18
    - QDC11.A1a.FRONTAGE_SETBACK@2010-03-26 (PRIMARY_FRONTAGE): OVERRIDES by BCC.C.TBC_FRONT_SETBACK_AVERAGE@2026-09-18
    - QDC11.A1a.FRONTAGE_NEIGHBOURS@2010-03-26 (PRIMARY_FRONTAGE): OVERRIDES by BCC.C.TBC_FRONT_SETBACK_AVERAGE@2026-09-18
    - QDC11.A2b.NARROW_LOT_CLEARANCE@2010-03-26 (SIDE): OVERRIDES by BCC.C.SL_SIDE_HABITABLE@2026-09-18
    - QDC11.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26 (SIDE): OVERRIDES by BCC.C.SL_SIDE_HABITABLE@2026-09-18
    - BCC.C.SL_SIDE_HABITABLE@2026-09-18 (SIDE): RELAXED by BCC.C.SL_SIDE_NONHABITABLE_LDR_CR@2026-09-18
    - QDC11.A2b.NARROW_LOT_CLEARANCE@2010-03-26 (REAR): OVERRIDES by BCC.C.SL_REAR@2026-09-18
    - QDC11.A2d.CLASS10A_WITHIN_CLEARANCE@2010-03-26 (REAR): OVERRIDES by BCC.C.SL_REAR@2026-09-18

