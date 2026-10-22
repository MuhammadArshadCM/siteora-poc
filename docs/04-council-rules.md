# Part 4 — Council rules (7 councils)

Research date 8–9 Oct 2026. Text was taken from each council's official ePlan JSON API or official PDF.
Every quoted provision is in `regs.provisions` (661 provisions in total), and every extracted rule is in the
database. The raw research files (with fetch logs and open questions) are in
[`research/councils/`](../research/councils/).

| Council | Provisions | Draft rules (auto-imported, not automated) | Curated rules (active) | Open issues |
|---|---|---|---|---|
| Brisbane | 110 | 59 | 6 | 9 |
| Gold Coast | 86 | 22 | 17 | 11 |
| Moreton Bay | 93 | 40 | 9 | 10 |
| Sunshine Coast | 61 | 16 | 9 | 7 |
| Logan | 90 | 36 | 13 | 10 |
| Ipswich | 58 | 16 | 8 | 10 |
| Redland | 56 | 11 | 7 | 8 |

Verification of extracted rules: 261 of 265 are VERIFIED_VERBATIM, 2 are COUNCIL_FACTSHEET and 2 are
UNVERIFIED (Logan "no value stated" readings). No value was taken from secondary sources.

**Baseline for all seven councils today:** QDC MP 1.1 (< 450 m²) / MP 1.2 (≥ 450 m²) apply to Class 10a and
pools, **except** where the council has declared an alternative provision for that lot, zone or precinct. No
council has adopted the QHC.

---

## Brisbane — City Plan 2014 v37.00/2026 (18 Sep 2026)

* **Standard lots (≥ 450 m², not a rear lot):** the Dwelling house code has **no setback or site-cover
  provisions**. Siting of Class 10a and pools = **QDC MP 1.2**, unless a listed neighbourhood plan or the
  Traditional building character (design) overlay applies. Height: **9.5 m and 2 storeys** (AO2), a s32(b)
  standard replacing QDC A4 (`BCC.C.DH_HEIGHT_9_5`).
* **Small lots (< 450 m², or rear lot < 600 m² excl. access):** Dwelling house (small lot) code
  front/side/rear setbacks, built-to-boundary walls, site cover and impervious area are **alternative provisions**
  (Table 1.6.1 items 10–12). Examples: garage ≥ **5.5 m** from street (`BCC.C.SL_GARAGE_STREET_5_5`); secondary
  frontage 1.5 m; lots < 180 m² follow Table 9.3.8.3.C by lot depth (draft rules).
* **Neighbourhood plans** can override QDC clearances, e.g. New Farm & Teneriffe Hill Low density living
  precinct rear setback **6 m** (`BCC.C.NP_NEW_FARM_REAR_6`, manual: "development" scope). Only 2 of 15+ listed
  neighbourhood plans were extracted.
* **Pools:** no City Plan pool setbacks ⇒ QDC.
* Gaps: other neighbourhood plans; overlay map extents; Table 1.6.1 item 9 cites a bushfire AO21.2 that no
  longer exists.

## Gold Coast — City Plan Version 14 (29 Sep 2026)

* No dwelling house code: siting sits in **zone codes**. Table 1.5-1 makes the **zone code** the QDC alternative
  for **buildings** (not structures), plus some overlays.
* Low density residential (lot ≥ 400 m²): front **6 m**; side/rear **1.5 m (≤ 4.5 m) / 2 m (≤ 7.5 m) / +0.5 m
  per 3 m**; site cover **50 %**; height **9 m / 2 storeys**; freestanding garages and carports ≤ **3.5 m**
  (planning requirement only where the zone code applies to the use).
* **Important:** the standard table has **no Class 10a built-to-boundary concession**. Whether QDC A2(d) survives
  is recorded as an `UNRESOLVED` relationship, so the engine returns manual review rather than guessing.
* Small lots (< 400 m²): separate table incl. Class 10 BTB only on southern/western boundary, ≤ 12 m, ≤ 6 m high (draft).
* Structures (pools, unroofed decks) keep QDC setbacks except in the Coastal erosion hazard / Road widening overlays.
* Gaps: Water resource catchment Table 8.2.19-2 values; mapped heights (Building height overlay).

## Moreton Bay — MBRC Planning Scheme 2016 Version 8 (11 Sep 2026)

* Dwelling house code 9.3.1 accepted-development requirements marked "non-compliance is a planning scheme matter"
  are the alternative provisions. Precinct-specific setback tables 9.3.1.3–9.3.1.6 (front/secondary/side/rear;
  many side cells say "Refer to standard as in QDC").
* Curated: General residential (Coastal communities / Suburban neighbourhood) site cover **50 %**; domestic
  outbuildings total roofed area **50 / 70 / 80 / 150 m²** by lot size (amenity and aesthetics, not an alternative
  provision); Rural residential road **6 m**, side/rear **1.5 / 2 / 4 m** by wall height (expressly replaces
  MP 1.2 A1 and A2 incl. A2(d) — **no shed BTB**), outbuilding height **4.5 m**.
* Gaps: Rural zone code not fetched; Redcliffe Interim residential table conflict; mapped dwelling heights.

## Sunshine Coast — Planning Scheme 2014 Version 27 (23 Jan 2024)

* Dwelling house code 9.3.6 notes which AOs are "alternative provision to QDC".
* Curated: garage/carport/shed ≥ **6 m from any road frontage** (both frontages on corner lots); outbuilding
  height ≤ **3.6 m** and floor area ≤ **56 m²** (planning requirements; 56 m² per-building vs combined is
  ambiguous ⇒ manual); **canal/artificial waterway 4.5 m** for anything > 1 m high incl. pools and decks (pool
  fencing ≥ 75 % transparent exempt); rural residential side/rear **3 m**.
* Side/rear setbacks and site cover in residential zones are **not** set by the scheme ⇒ **QDC MP 1.1/1.2**
  (not the QHC — the research report's statement otherwise was corrected).
* Gaps: mapped height (Height of buildings and structures overlay); Coastal protection 6 m seaward setback (draft).

## Logan — Planning Scheme 2015 Version 9.2 (1 Jul 2025)

* Table 1.6.1 lists code 9.3.2 POs/AOs by number as alternative provisions (boundary clearance AO4–AO7.1;
  site cover AO3, AO7–AO9; parking AO12). AO1 sends everything else to QDC MP 1.1/1.2.
* Curated: domestic outbuildings (sheds/detached garages) cumulative floor area ≤ **150 m²**; carport ≤ 6 × 6 m,
  ≤ 3.5 m, unenclosed may be **built to the front boundary**; LDR Small lot site cover **60 %**; rural-type
  zones side/rear **3 m**.
* A house and its Class 10 are accepted subject to requirements on land in a "residential area" (Residential
  overlay). Failing an AO ⇒ code assessable (council permit before building approval).
* Gaps: 150–300 m² path in urban zones; Residential overlay mapping; TLPI 1/2024 status.

## Ipswich — Ipswich City Plan 2025 Version 2 (1 Jul 2026)

* Replaced the 2006 scheme on 1 Jul 2025. Table 1.5.1 names the Dwelling House & Dual Occupancy Code as the
  QDC boundary clearance/site cover alternative, and the Building Height & Density Overlay (OV6) for height.
* Curated: site cover **60 %**; height **9.5 m** to roof peak (planning track — OV6 is the declared height
  alternative); Rural zone front **10 m**, side **20 m** (manual: Class 10a coverage inferred from definitions).
  Front/side otherwise default to "QDC MP1.1, MP1.2 or MP1.3".
* Character overlay limits on Class 10 (50 % of main building GFA; front carport 3.6 × 6 m) are drafts.
* Gaps: no rear setback rule; OV6 maps; New Suburban precinct mapping.

## Redland — City Plan 2018 Version 14 (10 Nov 2025)

* Alternative provisions only inside Low density residential precincts LDR1–LDR5; elsewhere houses are accepted
  and **QDC MP 1.1/1.2 apply unmodified**.
* Curated: LDR2 Park residential **10 m** road and **10 m** side/rear (incl. outbuildings); LDR1/LDR2 site cover
  **30 %**; LDR5 canal/lake **9 m** (incl. outbuildings and roofed structures, excluding in-ground pools).
* Gaps: precinct GIS; LDR5 precinct name UNVERIFIED; unroofed decks vs canal setback; Major Amendment 02/25 pending.

## Curation batch 2 (9 Oct 2026) — `db/032_council_curated_batch2.sql`

| Council | Added rules |
|---|---|
| Logan | LDR Small acreage 35 % / Acreage 20 % site cover; LMDR road clearance 4 m; 10 m road clearance (EC, LDR Acreage/Small acreage, listed RR precincts); EMC/Rural side/rear 10 m; large outbuildings (> 150 m²): ≤ 300 m² in rural-type zones (relaxes the 150 m² cap), ≤ 5.5 m high, side/rear 6 m / 20 m (override AO5 per its note); carport concession relaxes the new road clearances |
| Gold Coast | Rural residential front 6 m, side/rear 3 m (BTB question UNRESOLVED as in LDR), site cover 25 % / 15 % (landscape & environment precinct); LDR small lot (< 400 m²): front 4.5 m, covered parking 6 m from the vehicle-access frontage, corner secondary 4 m, side/rear 1 / 1.5 / 2 m, Class 10 BTB on S/W boundary (≤ 12 m, parts ≤ 6 m, ≥ 1 m from neighbour window); MDR covered parking 6 m, freestanding garage/carport 3.5 m (planning); Ridges overlay site cover 40 % (supplements zone figure) |
| Sunshine Coast | Garage door width ≤ 6 m per plane (planning); RR/LDLR and Rural (≤ 2 ha) road setback 10 m incl. garages, carports, sheds |
| Redland | LDR3 site cover 30 %, height 8.5 m (slope ≤ 15 %); LDR5 revetment wall 9 m (planning, not an alternative provision) |
| Ipswich | New Suburban: house front 3 m, garage door 5.5 m, garage BTB one side ≤ 9 m; BTB wall separation 0.9 m / 1.5 m from neighbour windows (manual) |
| Brisbane | Small lot secondary frontage 1.5 m, with 0 m for non-habitable ≤ 3 m on narrow minor through-streets; lots < 180 m² site cover 55 % |
| Moreton Bay | Suburban neighbourhood: covered parking and outbuildings 5.4 m from street frontages, lane 0.5 m; Coastal/Suburban/Interim: no built-to-boundary wall within 200 mm (supplements QDC A2(d), per the table's footnote); outbuilding height 4 m / 3.3 m carport forward of building line |

## Curation batch 3 (12 Oct 2026) — `db/033_council_curated_brisbane.sql` (Brisbane)

Why it was needed: a Brisbane lot of 450 m² or more outside any overlay has no City Plan setback or site-cover
standard, so QDC MP 1.2 governs and only the 9.5 m height comes from the City Plan. The council-specific siting
rules are in the **small lot code** (180–450 m²), the **character overlays** and the **neighbourhood plans**.

| Area | Added rules |
|---|---|
| Small lot code, section A (180 m² to < 450 m²; LDR, LMR, MDR, CR) | Primary frontage 6 m / least adjoining setback (≥ 3 m) / 3 m with no adjoining house; side 1 m, relaxed to 0.5 m for non-habitable ≤ 3.5 m high and ≤ 9 m long (LDR, CR) or ≤ 15 m (LMR, MDR); 0 m where matching an adjoining BTB wall or the adjoining lot is ≤ 300 m²; 0 m with neighbour non-objection (LDR, width > 7.5 m, ≤ 3 m high, ≤ 9 m); rear 6 m (depth > 25 m) or 3 m / 4.5 m by height — no Class 10a BTB concession; site cover 50 / 60 / 70 / 80 % by lot size; height 9.5 m |
| Traditional building character overlay | Front setback within 20 % of the average of nearby pre-1946 houses (LMR, CR; manual — needs building ages); garage position similar to pre-1946 neighbours (qualitative); carport forward of the house accepted only if width ≤ lesser of 6 m and 50 % of lot width (planning); Local character significance: forward carport ≤ 3.5 m, open on all sides |
| Dwelling house character overlay | Small lot: shed outside the building envelope accepted only if ≤ 10 m² and ≤ 3 m high (manual: envelope test) |
| Neighbourhood plans | Sherwood–Graceville Westside character precinct: rear setback the lesser of 10 m and 25 % of lot depth; New Farm & Teneriffe Hill low-medium density precinct: rear 6 m (both manual: whether "development" reaches Class 10a) |

Not encoded yet: small-lot built-to-boundary walls (AO9), building envelope, section B (< 180 m²) Table C setbacks,
Pre-1911 building overlay, and every other neighbourhood plan (e.g. Ashgrove–Grange).

## Curation batch 5 (21 Oct 2026) — `db/035_council_curated_new_zones.sql` (zones that had no council rules)

Text fetched from the councils' ePlan JSON on 21 Oct 2026 (rule keys `gc_rural_*`, `gc_ec_*`, `mb_rural_*`, `mb_tw_*`).

| Zone | Added rules |
|---|---|
| Gold Coast Rural (6.2.20) | Front 10 m, side and rear 6 m, height 9 m — buildings only, QDC alternatives (Table 1.5-1). No site cover rule: QDC applies |
| Gold Coast Emerging community (6.2.15) | Lot **not** from a residential subdivision: front 10 m, side/rear 6 m, site cover 5 %. Lot **from** a residential subdivision ("unless the earlier approval specifies otherwise"): front 6 m, side/rear 1.5 / 2 / +0.5 per 3 m, site cover 50 %. Height 9 m or the Building height overlay. The user answers `lot_from_residential_subdivision` (form / `--subdivision-lot`); unanswered, both sets go to manual review |
| Moreton Bay Rural (6.2.10) | Height as mapped (RAD2, alternative provision); Hamlet precinct: outbuildings 3.5 m, road 6 m, side 1.5 m (≤ 1000 m²) / 3 m, rear 4 m (RAD4, not a concurrence matter). No setback, site cover or roofed-area limit for a dwelling house outside the Hamlet precinct: QDC applies |
| Moreton Bay Township residential precinct (6.2.12.3) | Primary frontage 6.0 m, secondary 3 m; car parking and outbuildings 5.4 m from either frontage; side 1.5 m / 2 m (wall ≥ 4.5 m); rear "refer to QDC"; site cover 50 %; outbuildings 50 / 70 / 80 / 150 m² roofed area by lot size and 4 m (carport forward 3.3 m); house height as mapped |
| Sunshine Coast Emerging community | Zone code has no numbers and the Dwelling house code's "residential zone" AOs exclude it, so only the all-zone AOs apply: mapped height (AO1, scope widened in 034) and canal setback (AO6, council-wide). Palmview structure-plan heights left as research notes |

Left as drafts (shown to the user as clauses to read): Moreton Bay Rural RAD3 (6 / 4.5 / 4.5 m "other than a dwelling
house" — unclear whether domestic outbuildings are covered, since the scheme's dwelling house definition includes them),
Township rear setback (RAD3 says "refer to QDC", the assessable E4 says 6.0 m), lake, waterway and bushfire separations,
Gold Coast structure heights and pool notes.

## Curation batch 6 (21 Oct 2026) — `db/036_council_curated_remaining_zones.sql`

| Zone | Added rules |
|---|---|
| Gold Coast High density residential (6.2.3) | Lots ≥ 400 m²: front 4 m, covered parking 6 m, side/rear 1.5 / 2 / +0.5 per 3 m, site cover 50 %. Lots < 400 m²: the small-lot table (front 4.5 m, parking 6 m, corner 4 m, side/rear 1 / 1.5 / 2 m, Class 10 at 0 m on a south/west boundary), site cover 70 %. Height 9 m or the overlay map |
| Gold Coast Limited development (constrained land) (6.2.18) | Front 10 m, side/rear 3 m, site cover 10 % (50 % on a lot from a residential reconfiguration approval — same `lot_from_residential_subdivision` question), height 9 m or the overlay map |
| Moreton Bay Limited development (6.2.8) | Flood / storm-tide land: **any** building work is impact assessable (Table 5.7.1), no accepted siting envelope and no QDC alternative provisions. Encoded as a planning TRIGGER rule; the engine now lists council planning triggers first in `warnings` |
| Brisbane High density residential | A new dwelling house is impact assessable. Building work for an extension (incl. Class 10a) is accepted subject to the Dwelling house (small lot) code on a small lot, because the Dwelling house character overlay covers all HDR land: the 033 small-lot rules are widened to the zone. Lots of 450 m² or more: no scheme siting numbers (QDC/QHC only); the 9.5 m dwelling height outcome does not name HDR |

Every residential-type zone on the six open council maps now has council rules (or a recorded reason it has none).

---

## Common gaps that block full automation

1. Precinct, overlay and neighbourhood-plan **mapping** is needed to scope rules spatially.
2. **Mapped heights** (Brisbane, Gold Coast, Moreton Bay, Sunshine Coast, Ipswich OV6) are map data, not text.
3. Councils' **QHC adoption** will change the baseline per LGA. Re-check the department register monthly.
4. 187 draft rules await curation. The priority order is setbacks, then site cover, then outbuilding size and height for the
   main residential zones.
