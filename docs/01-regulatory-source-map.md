# Part 1 — Regulatory source map

Status as at **9 October 2026**. Every instrument below is registered in `regs.instruments` /
`regs.instrument_versions` with its version, dates, URL or archived file and SHA-256.

## 1. How the instruments fit together (short version)

```
Planning Act 2016 ─┬─ Planning Regulation 2017 ── referral of non-compliant siting to council (sch 9 pt 3 div 2 t3)
                   └─ Local planning schemes (zones, overlays, local/neighbourhood plans, codes)
                          │   • planning assessment benchmarks (use + assessable building work)
                          │   • ALSO building assessment provisions where the scheme says so:
                          │       – "alternative provisions" to QDC 1.1/1.2 (Building Act s33)
                          │       – matters prescribed for s32 (bushfire/flood designation, height/privacy/parking standards)
Building Act 1975 ─┬─ Building Regulation 2021 ── accepted building work, prescribed QDC parts, QHC transition (s106)
                   ├─ QDC (QHC = parts 1.1+1.2; MP 1.4; MP 3.4; MP 3.5 …) ── prevails over the NCC (s35)
                   ├─ NCC (BCA) ── construction requirements (e.g. fire separation of Class 10a)
                   └─ Chapter 8 "Swimming pool safety" ── pool safety standard = QDC MP 3.4 (+ AS 1926.1/.2-2007 as modified)
```

Key legal relationships (all verified from the archived texts):

| Relationship | Source |
|---|---|
| Building assessment provisions = Act ch 3–4, fire safety standards, the Regulation, *local instruments under s32 or s33*, the BCA, **and "subject to section 33" the QDC** | Building Act s30 |
| A local instrument **cannot change** the BCA/QDC/Regulation and has **no effect** to the extent it regulates building work those already cover — *except* as allowed by s32 and s33 | Building Act s31(3)–(6) |
| A planning scheme may include **alternative provisions** to the "QDC residential design and siting provisions" for a single detached Class 1, secondary-dwelling cases, and **Class 10 on the same allotment**; where they exist, the QDC applies **only to the extent the alternative provisions do not apply** | Building Act s33; Building Reg s80, s80A |
| If the QDC is inconsistent with the BCA, the QDC part prevails | Building Act s35 |
| Building work must comply with the building assessment provisions **in force when the application is approved** | Building Act s36(2) |
| Small Class 10 (≤ 10 m², ≤ 2.4 m high, mean ≤ 2.1 m, sides ≤ 5 m, etc.) is accepted building work **but must still comply with the relevant provisions** (incl. QDC siting or alternative provisions) | Building Reg s4(2), sch 1 s13; Building Act s21(5) |
| Non-compliance with a QDC 1.1/1.2 acceptable solution (or an alternative provision's quantifiable standard) ⇒ **referral to the local government** as referral agency | Planning Reg sch 9 pt 3 div 2 table 3 |
| QHC (QDC 1.1 and 1.2, Aug 2026) commenced 1 Sept 2026, but for any scheme in effect before then the **former** s6/s80/sch 7 (i.e. MP 1.1 & MP 1.2 of 2010) **continue to apply** until the earlier of the effective day of a scheme amendment adopting the QHC, or **1 Sept 2029** | Building Reg s106; QHC s3 |
| The pool safety standard is QDC MP 3.4; owners must comply; a certifier's certificate is needed before filling to 300 mm | Building Act s231D, s232, s234 |

> **There is no separate "Pool Safety Act" or "Pool Safety Regulation" in Queensland.**
> Pool safety law is Building Act 1975 chapter 8 and Building Regulation 2021 part 5, with QDC MP 3.4
> as the pool safety standard.

## 2. State instruments to collect

| # | Instrument | Version held | Status / role | In dataset |
|---|---|---|---|---|
| 1 | Building Act 1975 | Reprint current as at 1 Feb 2026 | s30–36 (assessment provisions, alternative provisions), ch 8 (pools) | provisions + rules |
| 2 | Building Regulation 2021 | Reprint current as at 14 Aug 2026 | s4, sch 1 s1/s13, sch 2, s79–80A, sch 7, **s106 QHC transition** | provisions + trigger rules |
| 3 | Planning Regulation 2017 | Reprint current as at 11 Sep 2026 | sch 9 pt 3 div 2 table 3 referral; sch 4/sch 24 definitions | provisions + trigger rule |
| 4 | **Queensland Housing Code** (QDC 1.1 + 1.2) | Aug 2026, commenced 1 Sep 2026 | Siting for Class 1, Class 10a, structures, pools — **only in adopting LGs until 1 Sep 2029** | 32 provisions, 45 rules |
| 5 | QDC MP 1.1 (lots < 450 m²) | 11 Mar 2010 | **Currently applies in all 7 councils** (none has adopted the QHC) | 16 provisions, 22 rules |
| 6 | QDC MP 1.2 (lots ≥ 450 m²) | 11 Mar 2010 | **Currently applies in all 7 councils** | 19 provisions, 22 rules |
| 7 | QDC MP 1.4 Building over/near relevant infrastructure | v1.2, 13 Nov 2014 | Sewer/water/stormwater clearances; referral to service provider | 5 provisions, 4 rules |
| 8 | QDC MP 3.4 Swimming pool barriers | 18 Jul 2012 | The pool safety standard | 12 provisions, 7 rules |
| 9 | AS 1926.1-2007 and AS 1926.2-2007 (+Amdt 1) | as called up by MP 3.4 | Barrier detail (gaps, latch heights…) | **not held** (copyright) — open issue |
| 10 | QDC MP 3.5 Flood hazard areas | 12 Dec 2013 | Construction in designated flood areas — not a setback instrument | registered only |
| 11 | QDC NMP 1.9 Pool & spa equipment | 1 Jan 2008 | **Non-mandatory**: binding only where a council adopts it | 2 provisions |
| 12 | QDC MP 1.3 Duplex housing | 11 Mar 2010 | Out of scope (duplexes) | file held |
| 13 | NCC (Housing Provisions) | edition adopted under the Building Act | Fire separation of Class 10a near boundaries / Class 1 | **not held** — open issue |
| 14 | Neighbourhood Disputes (Dividing Fences and Trees) Act 2011 | — | Dividing fence heights/consent (civil, not siting) | not loaded |

Archived files: `C:\Users\arsha\OneDrive\Desktop\pdfs\` (Queensland Government PDF URLs block scripted
download; the hash in `instrument_versions.file_sha256` identifies the copy relied on).

## 3. Council instruments (current versions found)

| Council | Planning scheme | Version in force | Commenced | QHC adopted? | Where QDC alternative provisions are declared |
|---|---|---|---|---|---|
| Brisbane | Brisbane City Plan 2014 | v37.00/2026 | 18 Sep 2026 | No | s1.6 Table 1.6.1 (items 6–8 s32 standards; items 10–12 s33 alternative provisions) |
| Gold Coast | Gold Coast City Plan (2016) | Version 14 | 29 Sep 2026 | No | s1.5 Table 1.5-1 (zone codes for *buildings*; listed overlays) |
| Moreton Bay | MBRC Planning Scheme 2016 | Version 8 | 11 Sep 2026 | No | Part 1 Table 1.6.1 (Rural, Rural residential zone codes; Dwelling house code 9.3.1) |
| Sunshine Coast | Sunshine Coast Planning Scheme 2014 | Version 27 | 23 Jan 2024 | No | Part 1 Table 1.6.1 + "alternative provision to QDC" notes in Dwelling house code 9.3.6 |
| Logan | Logan Planning Scheme 2015 | Version 9.2 (+TLPI 1/2024) | 1 Jul 2025 | No | Part 1 s1.6 Table 1.6.1 (code 9.3.2 POs/AOs listed by number) |
| Ipswich | **Ipswich City Plan 2025** (replaced the 2006 scheme) | Version 2 | 1 Jul 2026 | No | Part 1 s1.5 Table 1.5.1 (Dwelling House & Dual Occupancy Code; OV6 for height) |
| Redland | Redland City Plan 2018 | Version 14 | 10 Nov 2025 | No | Editor's notes in Low density residential zone code precincts LDR1–LDR5 |

Draft replacement schemes noted but **not in force**: Logan Plan (consultation closed 31 Oct 2025),
Sunshine Coast new scheme (consultation 2025), Moreton Bay new scheme (draft expected 2028), Redland Major
Amendment 02/25 (awaiting Ministerial approval).

**Recommendation on scope:** keep all seven councils. Add *Priority Development Areas* (e.g. Caloundra South / Aura,
Ripley Valley, Yarrabilba, Caboolture West parts) as a separate jurisdiction type before go-live: the QHC/QDC
siting parts do not apply in PDAs, and the PDA land use plan governs instead.

## 4. What each source contributes to the rules engine

| Rule category | Primary source | Planning or building? | Mandatory? | Can council modify? |
|---|---|---|---|---|
| Boundary setbacks, site cover for house + Class 10a | QDC MP 1.1/1.2 (now) → QHC (on adoption / 1 Sep 2029) | Building | Deemed-to-comply (acceptable solution); failure ⇒ performance solution + council referral | Yes — only through scheme **alternative provisions** (s33), and only where the scheme expressly declares them |
| Building height (house) | QDC A4 / QHC A1.1, or scheme standard declared under s32(b) | Building | Deemed-to-comply | Yes, where declared (e.g. Brisbane 9.5 m, Gold Coast 9 m) |
| Outbuilding size/height, garage widths, front carports | Planning scheme codes | Planning (sometimes also declared as alternative provision, e.g. Logan AO7) | Requirement for accepted development; failure ⇒ code assessment | Council rule |
| Overlay controls (flood, coastal, character, bushfire, canal setbacks) | Scheme overlay codes | Planning (some declared as QDC alternatives) | Usually triggers assessment | Council rule; QHC s4(7): overlays vary QHC only to the extent stated |
| Pool siting (setbacks from water's edge) | QDC MP 1.x / QHC | Building | Deemed-to-comply | Via alternative provisions (e.g. Sunshine Coast canal 4.5 m) |
| Pool barriers | Building Act ch 8 + QDC MP 3.4 + AS 1926-2007 | Pool safety | **Mandatory**, penalties | No |
| Building near sewers/mains | QDC MP 1.4 | Building / infrastructure | Deemed-to-comply; failure ⇒ service-provider referral | No (service provider consents) |
| Fire separation of Class 10a | NCC | Building (construction) | Mandatory | No |
