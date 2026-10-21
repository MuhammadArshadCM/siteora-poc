# Part 6 — Swimming pools: setbacks and barriers

Two separate legal regimes apply to a residential pool, and the engine reports them as separate tracks:

| Track | Law | Nature |
|---|---|---|
| **Siting** (water's-edge setbacks) | QDC MP 1.1/1.2 (now) → QHC (on adoption / 1 Sep 2029); council alternative provisions (e.g. canal setbacks) | Building — deemed-to-comply; miss ⇒ performance solution + council referral |
| **Barriers** | Building Act ch 8 (s231B–s234), QDC MP 3.4 (the pool safety standard), AS 1926.1/.2-2007 as modified | Pool safety — **mandatory**, penalty units, certificate before filling |

## 1. Is it a (regulated) pool?

* **Swimming pool** (Building Act sch 2): an excavation/structure capable of holding ≥ 300 mm of water and used
  for swimming, wading etc. — includes spa pools/tubs and non-portable wading pools; excludes ornamental ponds,
  portable wading pools, bathroom spa baths (unless kept filled > 300 mm), dams/tanks.
* **Regulated pool** (s231B): a swimming pool on **regulated land** (land with a Class 1, 2, 3 or 4 building,
  moveable dwelling park or residential park, incl. adjacent same-owner land), **including its barriers**.
  Rule `BA.S231B.REGULATED_POOL`.
* Above-ground and portable pools ≥ 300 mm are regulated pools. Building Reg sch 1 s13 small-Class-10 exemption
  expressly **excludes regulated pools and their fences**.

## 2. Pool siting rules (water's edge)

| Rule | Value | Condition | Source |
|---|---|---|---|
| `QDC1x.A1d.POOL_ROAD_SETBACK` | ≥ **1.5 m** water to road frontage | coping ≤ 1.2 m above finished ground | MP 1.1/1.2 A1(d)(i)(A) |
| `QDC1x.A1d.POOL_ROAD_WALL_EXEMPT` | no requirement | solid wall/fence ≥ 1.8 m high between water and road, top ≥ 1.0 m above coping | A1(d)(i)(B) |
| → coping > 1.2 m | falls back to dwelling road setback (6 m / Table A1) | | A1(d) "as for A1(a)" |
| `QDC1x.A2a.POOL_SIDE_REAR` | ≥ **1.5 m** water to side/rear | coping ≤ 4.5 m (interpretation: pool = structure) | A2(a)(i) + "setback" defn (b) |
| `QDC1x.A2e.POOL_WITHIN_CLEARANCE` | may be within clearance (BTB) | solid wall ≥ 1.8 m, top ≥ 1.0 m above coping, prevents water entry to neighbour | A2(e) |
| `QHC.CH1/CH2.T2.FRONT_POOL` | ≥ **1.5 m** all frontage types | pool ≤ 1.2 m high | QHC Table 2 |
| `QHC.CH1/CH2.T4.COMMON_POOL` | ≥ **1.5 m** side and rear | pool ≤ 4.5 m high | QHC Table 4 |
| `QHC.CH1/CH2.T24.POOL_SOLID_FENCE_BTB` | **BTB** | solid fence extends ≥ 1 m above the pool deck between water and boundary | Tables 2 & 4 supp. prov. |
| `SCC.C.CANAL_SETBACK_4_5` | ≥ **4.5 m** from canal/artificial waterway boundary | anything > 1 m above ground (incl. raised pools, decks); pool fencing ≥ 75 % transparent exempt | Sunshine Coast 9.3.6 AO6 (alternative provision) |
| `RCC.C.LDR5_CANAL_LAKE_9M` | ≥ **9 m** from canal/lake | LDR5; **excludes in-ground pools** (above-ground caught) | Redland AO9.1 (alternative provision) |
| `MP14.A2_1.COVER_CLEAR_ZONE` | ≥ **1.5 m** clear radius around sewer/stormwater maintenance covers | infrastructure on lot | QDC MP 1.4 |
| `MP14.A2_1.FOOTING_1_2M` | walls/footings ≥ **1.2 m** from main centreline | not light-weight Class 10 | QDC MP 1.4 |

Measurement: QDC and QHC both measure from the **water's edge** to the vertical projection of the boundary
(`MP_POOL_WATER_TO_*`, `QHC_POOL_WATER_TO_BOUNDARY`). Pool-to-building separation: no QDC/QHC siting rule.
Construction issues (footing surcharge near a house) are NCC/engineering matters, flagged for manual review.

## 3. Pool barrier rules

| Rule | Requirement | Verification |
|---|---|---|
| `MP34.P1.BARRIER_REQUIRED` | Continuous barrier for the full extent of the hazard; restricts young children's access incl. from buildings | VERIFIED_VERBATIM (manual — not provable from plan geometry) |
| `MP34.FIG1.BARRIER_MIN_HEIGHT` | Fence height **≥ 1200 mm**, measured **on the side with the non-climbable zone (NCZ)** | VERIFIED_FROM_FIGURE (MP 3.4 Figs 1–2, sch 1 items 1, 7) |
| `MP34.S1_6.NCZ_INSIDE_NEEDS_1800` | NCZ may be inside (pool side) only if fence **≥ 1800 mm**; < 1800 mm ⇒ NCZ outside | VERIFIED_VERBATIM (sch 1 item 6) |
| boundary fences (sch 1 item 7) | Boundary fence 1200–1800 mm allowed only with NCZ on the outside (neighbour's side) | VERIFIED_VERBATIM |
| NCZ geometry (Figs 1–2, items 8–10) | NCZ **900 mm** radius/quadrant; 300 mm clear area; NCZ extends **900 mm** past fence ends | VERIFIED_FROM_FIGURE / VERBATIM |
| `MP34.S1_12.NO_NCZ_TALL_FENCE` | No NCZ needed if fence **≥ 2400 mm**, or ≥ 1800 mm with cranked top | VERIFIED_VERBATIM — **but > 2 m breaches the QDC/QHC 2 m fence limit** (building track) |
| item 13 | Horizontal-member spacing dimension **900 mm** (instead of AS 1000 mm) | VERIFIED_VERBATIM |
| `MP34.S1_15.GATE_OPENS_AWAY` | Gates must **not open towards** the pool area | VERIFIED_VERBATIM |
| `MP34.P1d.GATE_SELF_CLOSING` | Gates self-closing and self-latching, latch not readily operated by young children | VERIFIED_VERBATIM (manual) |
| `MP34.P1e.NO_BUILDING_DOORS` | Outdoor pool barrier must not incorporate doors to/from a building (items 28–30: access via patio/deck with a permanently open side is permitted) | VERIFIED_VERBATIM |
| item 21 | Designated pool access point enclosed by a compliant barrier with a gate | VERIFIED_VERBATIM (provision) |
| `BA.S234.CERTIFICATE_BEFORE_FILLING` | Certifier's certificate before filling to 300 mm; warning sign during construction (s233) | VERIFIED_VERBATIM |

**Not populated (REFERENCED_STANDARD_NOT_HELD):** maximum gaps between vertical members, ground clearance,
latch height/shielding, hinge requirements and the like are in AS 1926.1-2007 (the edition MP 3.4 calls up —
not the current 2012 edition). These are recorded as an open issue, not invented.

## 4. Interactions to model

* A pool fence is a **fence** for siting: under MP 1.x it is exempt from road and side/rear setbacks if ≤ 2 m.
  Under the QHC it may be BTB if ≤ 2 m, but **> 2 m fails A1.1(4)** (the A1.1(6) pool carve-out covers the pool,
  not its fence). A 2.4 m no-NCZ fence therefore passes MP 3.4 but needs a siting performance solution.
* A boundary fence used as the pool barrier is also governed by the Neighbourhood Disputes (Dividing Fences
  and Trees) Act 2011 (civil, not modelled).
* NMP 1.9 (pool pump noise ≤ background + 5 dB(A) 7am–10pm / + 0 dB(A) 10pm–7am; 900 mm concourse at 1:20) is
  binding **only** where a council adopts it. Treat it as ADVISORY unless adoption is recorded.
