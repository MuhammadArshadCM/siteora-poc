# Part 9 — Example evaluation

Produced by the rule resolver ([`server-ts/src/core/evaluate.ts`](../server-ts/src/core/evaluate.ts), `npm run evaluate`) against the loaded dataset. Scenario files and full
outputs are in [`examples/`](../examples/). The evaluator resolves **which rule applies and what it requires**.
Measuring the design against those values is the PostGIS layer's job.

## Property and proposal

* Brisbane City Council, Low density residential zone, no overlays or neighbourhood plan
* Lot 607 m², interior (not corner), lot width / frontage 16.1 m, slope 4 %
* Proposal A: detached shed 6.0 m × 4.0 m, 3.0 m high, mean height 2.7 m, in the rear corner, built to both boundaries
  (6 m along each), 4 m from the neighbour's nearest habitable-room window
* Proposal B: in-ground pool, coping 0.3 m above ground; 1.2 m pool fence with the NCZ outside
* Assessment date: **9 Oct 2026**

## Result (9 Oct 2026)

```
Applicable rules — shed
- Front (road) setback:   ≥ 6.0 m        QDC MP 1.2 A1(a) via A1(d)                [building, deemed-to-comply]
- Side setback:           BTB permitted  QDC MP 1.2 A2(d) — relaxes A2(a) 1.5 m     [conditions all met: part ≤ 4.5 m,
- Rear setback:           BTB permitted  QDC MP 1.2 A2(d)                            mean ≤ 3.5 m, ≤ 9 m per boundary,
                                                                                     ≥ 1.5 m from adjoining window]
- Maximum height:         ≤ 9.5 m        Brisbane City Plan 9.3.7.3 AO2 (overrides QDC A4 8.5 m — Table 1.6.1 item 6)
- Site cover (whole lot): ≤ 50 %         QDC MP 1.2 A3
Applicable rules — pool
- Pool road setback:      ≥ 1.5 m        QDC MP 1.2 A1(d)(i)(A) (coping ≤ 1.2 m), from water's edge
- Pool side/rear setback: ≥ 1.5 m        QDC MP 1.2 A2(a)(i) + definition of setback (b)
- Pool barrier height:    ≥ 1200 mm      QDC MP 3.4 Figure 1 / sch 1 items 1, 7 (measured on NCZ side)  [pool safety, mandatory]
- Barrier continuity, no building doors, gate self-closing/opens away: MANUAL_REVIEW (MP 3.4 P1, sch 1 item 15)
- Pool fence siting:      exempt from setbacks (≤ 2 m)  QDC MP 1.2 A2(c)(iii), A1(d)(ii)

Sources
- Local planning scheme: Brisbane City Plan 2014 v37.00/2026 (effective 18 Sep 2026), Dwelling house code
  9.3.7.3 Table 9.3.7.3.A PO2/AO2; s1.6 Table 1.6.1 item 6 (declaration as building assessment provision)
- QDC: MP 1.2 (published 11 Mar 2010) A1(a), A1(d), A2(a), A2(c), A2(d), A3 — still operative in Brisbane
  under Building Regulation 2021 s106 because City Plan has not adopted the Queensland Housing Code
- Pool safety: Building Act 1975 s231B, s231D, s232; QDC MP 3.4 (18 Jul 2012) P1, A1, sch 1, Figure 1
Displaced (with reason)
- QDC MP 1.2 A4 8.5 m height     ← OVERRIDES by Brisbane AO2 (s32(b); Table 1.6.1 item 6)
- QDC MP 1.2 A2(a) 1.5 m (shed)   ← RELAXED by A2(d)
- QDC MP 1.2 A2(a) (pool fence)   ← EXEMPTS by A2(c) fence ≤ 2 m
```

Note what is *not* in the result: no separate Class 10a height cap and no garage-width rule. MP 1.2 has
neither; the QHC adds them only when it becomes operative.

## Same property, assessed on 1 Sep 2029 (QHC long-stop)

```
Shed:  front (primary frontage) ≥ 6.0 m            QHC Ch2 Table 1 (detached shed/laundry)
       eaves to primary frontage ≥ 3.0 m           QHC Ch2 Table 2 (weather control element)
       side / rear BTB permitted                   QHC Ch2 Table 3 (≤ 4.5 m, ≤ 9 m combined per boundary)
       eaves: BTB (attached to a BTB part)         QHC Ch2 Table 4 supp. prov. 1 (otherwise side ≥ 0.5 m, rear ≥ 2.0 m)
       Class 10a height ≤ 4.5 m                    QHC Ch2 A1.1(2)
       Brisbane AO2 9.5 m also listed (status of pre-QHC alternative provisions after 1 Sep 2029 is an open issue)
       site cover ≤ 50 % (QHC definition)          QHC Ch2 A4.1
Pool:  ≥ 1.5 m from every boundary (water's edge)  QHC Ch2 Tables 2 and 4
Fence: ≤ 2.0 m high; BTB permitted                 QHC A1.1(4), A10
```

## Contrast: identical shed on a 607 m² Gold Coast Low density residential lot (9 Oct 2026)

```
- Front ≥ 6.0 m                     Gold Coast City Plan 6.2.1 AO1 (alternative provision; overrides MP 1.2 A1(a))
- Side/rear ≥ 1.5 m   MANUAL_REVIEW  City Plan 6.2.1 AO1 height-tiered table (overrides MP 1.2 A2(a))
- Side/rear BTB       MANUAL_REVIEW  MP 1.2 A2(d) — UNRESOLVED: City Plan table is silent on Class 10a BTB
- Height ≤ 9.0 m                     City Plan 6.2.1 AO3.1 (overrides MP 1.2 A4)
- Site cover ≤ 50 %                  City Plan 6.2.1 AO2 (overrides MP 1.2 A3)
```

The engine declines to choose between a 1.5 m side setback and built-to-boundary, because the law does not
settle it. It flags the question and records the reason.

## More scenarios (recorded in `examples/`)

| Scenario | Key result |
|---|---|
| `logan_acreage_large_shed` — 180 m² shed, 5.0 m, LDR Acreage | road 10 m; side/rear **6 m** (large-outbuilding table overrides AO5's 3 m); height ≤ 5.5 m; total ≤ 300 m² (relaxes 150 m²); site cover 20 % |
| `moreton_bay_suburban_shed` — Suburban neighbourhood, 650 m² | street frontage 5.4 m; QDC A2(d) reduced clearance **but not within 200 mm** of the boundary; height ≤ 4 m; total roofed area ≤ 70 m²; site cover 50 % |
| `sunshine_coast_shed` — LDR, 607 m² | road 6 m (alternative provision); QDC A2(d) BTB on side/rear; planning: height ≤ 3.6 m, floor area ≤ 56 m² (manual — per building or combined?) |

## Reproduce

```bash
export PGPASSWORD=...            # your local password
psql -h localhost -U postgres -d siteora -v ON_ERROR_STOP=1 -f db/load_all.sql
npm run evaluate -- examples/brisbane_shed_pool.json                 # defaults: localhost:5432, db siteora, user postgres
npm run check                                                        # invariants + all recorded examples
```
