# Part 5 — QDC provisions and how they interact with local rules

## 1. Which QDC parts apply to this scope (verified)

| Part | Applies to | Relevant to Class 10a / pools? | Status on 9 Oct 2026 |
|---|---|---|---|
| **QHC** (QDC 1.1 + 1.2, Aug 2026) | New building work for a single Class 1, dwelling house with secondary dwelling, **associated Class 10a buildings and associated structures**, in all zones where a dwelling house is a permitted use. Does not apply to structures < 1 m above ground (except pools), indoor pools, tourist parks, PDAs. Ch 1: lots < 450 m²; Ch 2: lots ≥ 450 m². | Yes — setbacks, heights, site cover, pool water's-edge setbacks | Commenced 1 Sep 2026, but **not yet operative in any of the 7 councils** (none has adopted it) |
| **MP 1.1** (2010) | Single detached Class 1 and associated Class 10 buildings and structures, lots < 450 m² (incl. community title); not structures < 1 m above natural ground except pools; not UDAs | Yes | **Operative in all 7 councils** until adoption or 1 Sep 2029 |
| **MP 1.2** (2010) | Same, lots ≥ 450 m² | Yes | **Operative in all 7 councils** until adoption or 1 Sep 2029 |
| MP 1.3 (2010) | Duplex housing | No (out of scope) | In force |
| **MP 1.4** (2014) | Any building/structure on, or adjacent to, a lot with sewer, water main, stormwater drain or combined sanitary drain | Yes — sheds, pools, decks over/near mains | In force |
| MP 2.x | Fire safety in budget accommodation / residential care | **No** — not residential houses | — |
| **MP 3.4** (2012) | All regulated pools — the pool safety standard | Yes | In force |
| MP 3.5 (2013) | Construction in designated flood hazard areas | Construction only, not siting | In force where designated |
| NMP 1.9 (2008) | Pool equipment (noise, filtration, signs, surrounds) | Only if a council adopts it | Non-mandatory |

MP 2.1 and MP 2.2 do **not** apply: they cover fire safety in budget accommodation and residential care
buildings. Fire separation for Class 10a near boundaries comes from the NCC Housing Provisions, which are not
held in this dataset (open issue).

## 2. Legacy MP 1.1 / MP 1.2 — key acceptable solutions (encoded)

| Clause | Requirement | Rule |
|---|---|---|
| MP 1.2 A1(a) | Dwelling, garage, carport road setback **6 m** (structures via A1(d)); or neighbour-averaging alternative | `QDC12.A1a.ROAD_SETBACK`, `…_NEIGHBOURS` |
| MP 1.1 A1(a) Table A1 | Frontage **3.0 m** (access place/street) / **4.0 m** (collector); side to corner street 1.0 / 2.0 m | `QDC11.A1a.FRONTAGE_SETBACK`, `…SIDE_TO_CORNER_STREET` |
| MP 1.1 A1(b) | Garage/carport openings facing street ≤ lesser of 6 m and 50 % of frontage | `QDC11.A1b.GARAGE_OPENING_WIDTH` |
| A1(b)/(c) corner lot | Average depth ≤ 24 m: nominated frontage per **Table A1 graph**; no building/structure > 2 m in 9 × 9 m truncation | `QDC12.A1b.*`, `QDC11.A1c.*` |
| MP 1.2 A1(c) | Open carport may encroach road setback (≤ 15 % obstruction, no alternative site) | `QDC12.A1c.OPEN_CARPORT` (manual) |
| A1(d)(i) | Pool water to road: **1.5 m** if coping ≤ 1.2 m; none behind 1.8 m solid wall 1.0 m above coping | `*.A1d.POOL_ROAD_*` |
| A1(d)(ii)-(iii) | Fences/screens/retaining walls ≤ 2 m and small gatehouses exempt from road setback | `*.A1d.EXEMPT_*` |
| A2(a) | Side/rear clearance by height of part: **1.5 m (≤ 4.5 m), 2 m (≤ 7.5 m), 2 m + 0.5 m per 3 m or part above 7.5 m** | `*.A2a.SIDE_REAR_CLEARANCE` |
| A2(b) Table A2 | Narrow lots (frontage ≤ 15 m): 0.75–1.425 m / 1.0–1.9 m by frontage band | `*.A2b.NARROW_LOT_CLEARANCE` |
| A2(c) | Exempt: fences ≤ 2 m, rainwater tanks ≤ 2.4 m, unroofed ornamental pergolas ≤ 2.4 m — **not** decks, patios, verandahs | `*.A2c.EXEMPT_*` |
| **A2(d)** | **Class 10a within clearance (to boundary) if part ≤ 4.5 m high, mean height ≤ 3.5 m, total length of all buildings in clearance ≤ 9 m per boundary, ≥ 1.5 m from adjoining habitable window** | `*.A2d.CLASS10A_WITHIN_CLEARANCE` |
| A2(e) | Pool within clearance behind ≥ 1.8 m solid wall whose top is ≥ 1.0 m above coping | `*.A2e.POOL_WITHIN_CLEARANCE` |
| A3 | Site cover ≤ **50 %** (buildings/structures roofed with impervious materials) — both parts | `*.A3.SITE_COVER` |
| A4 | Building height ≤ **8.5 m** (slope < 15 %) / **10 m** (≥ 15 %) — **no separate Class 10a height cap** | `*.A4.BUILDING_HEIGHT` |
| A6 | Walls < 750 mm from boundary maintenance-free | `*.A6.WALL_MAINTENANCE` |
| A7 | Corner sight-line truncation: max 1 m high | `*.A7.CORNER_SIGHTLINE` |

## 3. QHC (2026) — what changes for Class 10a and pools

| Matter | MP 1.2 (lots ≥ 450 m²) | QHC Ch 2 (lots ≥ 450 m²) | QHC Ch 1 (< 450 m²) |
|---|---|---|---|
| Measuring point | outermost projection | **external wall façade**; eaves tested separately | same as Ch 2 |
| Garage/carport primary frontage | 6 m | **5.6 m** (garage door 5.6 m) | 5 m |
| Detached shed/laundry primary frontage | 6 m (via A1(d)) | **6 m** | 5.4 m |
| Small carport (≤ 4.5 m, mean ≤ 3.5 m) | 6 m unless "open carport" relaxation | **BTB permitted** (except "other" secondary frontage 1 m) | same |
| Secondary road frontage (house) | 6 m, or Table A1 graph on shallow corner lots | **Table A1 formula** `(w − 5.34)/3.11` (≤ 4.5 m) or `(w − 4)/3` | 1.5 m |
| Class 10a on side/rear | BTB if ≤ 4.5 m, mean ≤ 3.5 m, ≤ 9 m total length *of all buildings*, ≥ 1.5 m from neighbour window | BTB if ≤ 4.5 m, **garage/carport/laundry/shed only**, ≤ 9 m combined length of those per boundary; no mean-height or window test | same |
| Class 10a otherwise | 1.5 / 2 m by height | Class 1 rows: side 1.5 m, rear **4 m** (≤ 4.5 m wall) | side 1 m, rear 3 m |
| Class 10a max height | none (only 8.5 m building height) | **4.5 m** (+1.5 m if slope > 15 %) | same |
| Covered patio/pergola/deck (≤ 4.5 m) | as building: 6 m road, 1.5 m side/rear, no BTB | primary 3 m, side 1 m, rear 2 m | primary 1.5 m, side 0.5 m, rear 1.5 m |
| Pool (water's edge) | road 1.5 m (coping ≤ 1.2 m); side/rear 1.5 m | **1.5 m all boundaries** (pool ≤ 1.2 m high for frontages, ≤ 4.5 m for common) | same |
| Pool relaxation | 1.8 m solid wall, top ≥ 1.0 m above coping ⇒ none / within clearance | solid fence extending ≥ 1 m above the pool deck ⇒ **BTB** | same |
| Fences | exempt ≤ 2 m | ≤ 2 m, BTB permitted; **> 2 m fails A1.1(4)** (affects 2.4 m pool fences) | same |
| Site cover | 50 % (roofed impervious) | **50 %** (QHC definition: 600 mm in from OMP for roofed unenclosed; excludes unroofed, pools, retaining walls, fences; excludes battle-axe handle) | 65 % (≤ 250 m²) / 60 % |
| Deck privacy | — | Deck/pergola/verandah > 1 m high within 2 m of a common boundary ⇒ 1.5 m privacy screen | same |

## 4. How QDC/QHC interact with local rules — the actual legal model

1. **Default:** the QDC siting part is a *building assessment provision* (Building Act s30(g)). For building
   work it is applied by the building certifier. A planning scheme cannot alter it (s31(3)–(5)).
2. **Exception — alternative provisions (s33):** a planning scheme may contain provisions that are "alternative
   or different to" the QDC residential design and siting provisions for a single detached Class 1, the
   secondary-dwelling cases, and **Class 10 buildings or structures on the same allotment**. Where they apply,
   the QDC applies **only to the extent the alternative provisions do not apply** (s33(4)). They must be a
   qualitative statement or quantifiable standard, and they are effective only if made in a planning scheme
   (or PDA instrument). Each council declares *which* of its provisions are alternative provisions (Table 1.5/1.6
   in Part 1 of the scheme, or editor's notes). **Only those** displace the QDC. A number in a zone code that is
   not so declared does **not** replace the QDC value for building assessment.
3. **Exception — s32 matters:** a scheme may also set standards on matters prescribed by regulation (bushfire
   and flood designations; and, per Brisbane Table 1.6.1, "former s6 Building Regulation" standards for QDC
   performance criteria P4 height, P5 privacy and P8 parking).
4. **Planning-scheme benchmarks that are not alternative provisions** (e.g. Sunshine Coast 3.6 m / 56 m²
   outbuilding caps, Gold Coast 3.5 m freestanding garage height) operate on the **planning** track: they are
   requirements for accepted development or assessment benchmarks. Failing them makes the development
   assessable (planning approval needed); it does not change the building certifier's QDC test.
5. **Overlays** (QHC s4(7)): if work is in a "relevant overlay" (hazard, heritage, traditional building
   character, ecological, ANEF), the QHC is varied by the overlay provisions **only to the extent the variation
   is stated**.
6. **Non-compliance with a QDC acceptable solution** is not a "fail". The applicant may use a performance
   solution, and the local government becomes a **referral agency** assessing against the performance
   criteria (Planning Reg sch 9 pt 3 div 2 table 3). The engine reports `REFERRAL_TO_LOCAL_GOVERNMENT`.
7. **Transition (Building Reg s106):** existing schemes keep the 2010 MP 1.1/1.2 until amended to adopt the
   QHC, or until 1 Sep 2029. As at 9 Oct 2026 **none of the seven councils has adopted the QHC**, so every
   council's current siting baseline is MP 1.1/1.2, and their existing alternative provisions (all written
   against MP 1.1/1.2) continue to operate. What happens to those alternative provisions after 1 Sep 2029 if a
   council has not re-made them against the QHC is **unresolved** (open issue). The engine shows both
   sets of rules (conservative) for dates on or after 1 Sep 2029.

Note on agent research: two council research reports said "QHC values now apply". That is incorrect under
s106 and was **not** adopted in the dataset.
