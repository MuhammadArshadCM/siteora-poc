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
| `MP34.S1_21.DESIGNATED_ACCESS_POINT` | Designated pool access point enclosed by a compliant barrier with a gate | VERIFIED_VERBATIM |
| `MP34.S1_13.NCZ_HORIZONTAL_MEMBER_GAP_900` | NCZ horizontal-member gap ≥ **900 mm** (MP 3.4 substitutes this for AS 1926.1's default 1000 mm) | VERIFIED_VERBATIM |
| `MP34.FIG1.CLEAR_AREA_FOOTHOLD_300` | Clear area free of footholds/climbable objects ≥ **300 mm** (extends 900 mm past fence ends where the NCZ is outside) | VERIFIED_FROM_FIGURE |
| `MP34.AS1926.BARRIER_MAX_GAP_100` | No gap/hole greater than **100 mm** anywhere in the barrier | VERIFIED_VERBATIM (AS 1926.1-2007 sec 2.3.7 — now held; QBCC corroborates) |
| `MP34.AS1926.BARRIER_GROUND_GAP_100` | Max **100 mm** gap from ground level to the bottom of the barrier | VERIFIED_VERBATIM (AS 1926.1-2007 sec 2.4/2.5.2 — now held; QBCC corroborates) |
| `MP34.A1b.GATE_LATCH_HEIGHT` | Gate latch release underside ≥ **1500 mm** above ground AND ≥ **1400 mm** above the highest lower rail (or shielded) | VERIFIED_VERBATIM (A1(b)'s own guideline, incorporated by reference — not a secondary source) |
| `MP34.S1_16.RETAINING_WALL_BARRIER_NO_FOOTHOLD` | Overhang/return fencing atop a retaining-wall barrier must have no foothold/handhold surface | VERIFIED_VERBATIM (sch 1 item 16) |
| `MP34.S1_17.WATER_BODY_AS_BARRIER` | A canal/lake/river/etc. may form part of the barrier itself (depth > 300 mm, width ≥ 1800 mm, no under/over access, 900 mm overhang or return) — a barrier-*compliance* question, distinct from this tool's canal siting setbacks | VERIFIED_VERBATIM (sch 1 item 17) |
| `MP34.S1_19_20.BALCONY_NCZ` | Balcony pools need an additional NCZ (Figure 23) unless the balcony itself has a compliant barrier | VERIFIED_VERBATIM (sch 1 items 19–20) |
| `MP34.S1_26.INDOOR_CHILD_RESISTANT_DOORSET` | Indoor pool access must be via a compliant child-resistant doorset (or another compliant barrier) | VERIFIED_VERBATIM (sch 1 item 26) |
| `AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT` | Gate latching device must resist inadvertent adjustment, locking open, tool-free adjustment, and release through the 10 mm gap | VERIFIED_VERBATIM (AS 1926.1-2007 sec 2.3.7/2.5.4.1 — now held) |
| `AS1926.S2_5_4_3.LATCH_SHIELDING` | Where the latch sits below the height thresholds: shield to ≤10 mm opening within a 450 mm radius (alternative to `MP34.A1b.GATE_LATCH_HEIGHT`) | VERIFIED_VERBATIM (AS 1926.1-2007 sec 2.5.4.3 — now held) |
| `BA.S234.CERTIFICATE_BEFORE_FILLING` | Certifier's certificate before filling to 300 mm; warning sign during construction (s233) | VERIFIED_VERBATIM |

**Narrowed 2026-11-14** (was: "not populated, REFERENCED_STANDARD_NOT_HELD" for all of this): the NCZ gap,
foothold clear-area and designated-access-point figures were already held verbatim in this project's own MP 3.4
text (db/020) but never promoted to active rules — now activated above. The max-gap-in-barrier and
ground-clearance figures (both 100 mm) are now sourced from QBCC's public consumer guidance — tagged
COUNCIL_FACTSHEET rather than VERIFIED_VERBATIM, since they restate AS 1926.1-2007 rather than being MP 3.4's
own text, and AS 1926.1-2007 itself remains paywalled/unheld.

**Further narrowed 2026-11-16**, after a full re-extraction of a complete local copy of MP 3.4 (the prior capture
in db/020 only went up to item 21 of Schedule 1's 30 items) and the Dept of Housing's "Guideline for pool owners
and property agents" (made under s258 of the Building Act — MP 3.4's own A1(b) incorporates this guideline *by
reference* for tolerance-limit figures, so it is VERIFIED_VERBATIM here, not a secondary source the way QBCC's
page is): gate latch height is now encoded. Items 16, 17, 19–20 and 26 of Schedule 1 were also newly found and
encoded (none were in db/020 at all). Confirmed in the same pass: AS 1926.2:2007 ("location of barriers") is
mostly *disapplied* by MP 3.4 itself (item 23) — there is no further hidden trove of siting-type content in it.

**Resolved 2026-11-16** (open issue #1 closed): a licensed copy of AS 1926.1-2007 (+ Amdt 1) was sourced and
reviewed in full (not stored in this repository — copyright; only the clause excerpts needed below are
transcribed, same convention as every other instrument). Two findings: (1) "hinge tamper-resistance
specifications" — the premise behind half of issue #1 — **does not exist** as a requirement in AS 1926.1-2007.
The word "hinge" appears exactly once in the whole standard (sec 2.3.4), as an example of a possible climbing
foothold, already covered by the existing non-climbable-zone rules — confirmed absent, not merely unsourced.
(2) The two 100 mm gap figures, previously held only via QBCC's consumer-guidance restatement
(COUNCIL_FACTSHEET), are now upgraded to VERIFIED_VERBATIM citing the Standard's own sec 2.3.7/2.4 directly.
Two genuinely new, independent requirements were also found and encoded: `AS1926.S2_5_4_1.LATCH_TAMPER_RESISTANT`
(latching-device hardware integrity — not inadvertently adjustable, not lockable open, not tool-free
adjustable, not releasable via the 10 mm gap) and `AS1926.S2_5_4_3.LATCH_SHIELDING` (the shielding alternative
to `MP34.A1b.GATE_LATCH_HEIGHT`'s height requirement: ≤10 mm opening within a 450 mm radius of the latch).

## 4. Interactions to model

* A pool fence is a **fence** for siting: under MP 1.x it is exempt from road and side/rear setbacks if ≤ 2 m.
  Under the QHC it may be BTB if ≤ 2 m, but **> 2 m fails A1.1(4)** (the A1.1(6) pool carve-out covers the pool,
  not its fence). A 2.4 m no-NCZ fence therefore passes MP 3.4 but needs a siting performance solution.
* A boundary fence used as the pool barrier is also governed by the Neighbourhood Disputes (Dividing Fences
  and Trees) Act 2011 (civil, not modelled).
* NMP 1.9 (pool pump noise ≤ background + 5 dB(A) 7am–10pm / + 0 dB(A) 10pm–7am; 900 mm concourse at 1:20) is
  binding **only** where a council adopts it. Treat it as ADVISORY unless adoption is recorded.
