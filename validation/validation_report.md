# Setback dataset validation — 14 Queensland councils

Run date: **23 Oct 2026** (supersedes the 22 Oct run below in every respect except the git/file history it links to).
Database `siteora`, schema `regs`. Generated data: `npm run validate-setbacks` (read-only); this report summarises
those files and the regression runs.

**Scope, set by the user on 22 Oct 2026 and carried through this run:** only front, side and rear boundary setbacks
that apply to **Class 10 structures** — Class 10a (garage, carport, shed, detached laundry, other outbuilding) and
Class 10b (pool, fence, retaining wall, rainwater tank). No other setback category, and no other building class on
its own, is in the primary dataset. `validate-setbacks.ts` enforces this: a record counts as primary only if its
topic is a front/side/rear/garage-frontage/Class-10-BTB/pool-setback topic **and** at least one of its (non-excluded)
subjects is in the Class 10a/Class 10b subtree or `ANY`.

## 1. Result in one table

| Council | Scheme / version in DB | Online version check | Pipeline / integrity / traceability | Overall |
|---|---|---|---|---|
| Brisbane City Council | Brisbane City Plan 2014 v37.00/2026 | CURRENT | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| Burke Shire Council | Burke Shire Planning Scheme 2020 (no version number) | UNCONFIRMED | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| Central Highlands Regional Council | Planning Scheme 2016, Amendment No. 7 | CURRENT | PASS / PASS / PASS | **PASS** |
| City of Gold Coast | Gold Coast City Plan Version 14 | CURRENT | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| City of Moreton Bay | MBRC Planning Scheme Version 8 | CURRENT (label wording unconfirmed) | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| Livingstone Shire Council | Livingstone Planning Scheme 2018, Version 4 | CURRENT | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| Logan City Council | Logan Planning Scheme 2015, V9.2 | CURRENT (TLPI wording unconfirmed) | PASS / PASS / PASS_WITH_WARNINGS | **PASS_WITH_WARNINGS** |
| Mount Isa City Council | City of Mount Isa Planning Scheme 2020 (no version number) | UNCONFIRMED | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| Redland City Council | Redland City Plan Version 14 | CURRENT | PASS / PASS / PASS_WITH_WARNINGS | **PASS_WITH_WARNINGS** |
| Rockhampton Regional Council | Rockhampton Region Planning Scheme 2015, Version 5 | CURRENT | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| South Burnett Regional Council | Planning Scheme 2017, Version 2.0 | CURRENT | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| Sunshine Coast Regional Council | Sunshine Coast Planning Scheme 2014, Update 27 | CURRENT | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| Toowoomba Regional Council | Toowoomba Regional Planning Scheme v29 | CURRENT | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |
| Townsville City Council | Townsville City Plan, Version 2025/01 | CURRENT | PASS / PASS / PASS | **PASS_WITH_WARNINGS** |

**Every council now has a dataset, and every council passes the pipeline, data-integrity and source-traceability
tests with zero errors.** No council is BLOCKED or FAIL. This is a change from the 22 Oct run (section 11), where 8 of
the 14 councils had never been onboarded. All 14 are onboarded now, with research files, database rows, and
read-only validation evidence for each.

The "PASS_WITH_WARNINGS" on 13 of 14 councils reflects genuine open items — records flagged for manual review by a
planner/certifier, source provisions not yet curated, and a few metadata details the council sites don't state —
not residual defects in the pipeline. Central Highlands is a clean PASS: its three Class 10 rules are unambiguous,
fully verified, and need no manual review.

## 2. Dataset totals (Class 10 front/side/rear only)

| | Count |
|---|---|
| Councils with a Class 10 setback dataset | 14 / 14 |
| Active primary records (front/side/rear/garage-frontage/BTB/pool setback, reaching Class 10) | **185** |
| Verified active primary records (source-evidenced; includes the 64 manual-review records below) | **185** |
| Of which flagged for manual review (qualitative value, or automatable = false) | 64 |
| Records correctly excluded as not Class 10 (e.g. dwelling-only rules) | 24 |
| Records correctly excluded as a related/non-setback category (waterway, buffer, separation, etc.) | 36 |
| Validation errors | **0** |
| Validation warnings | 72 |
| Validation info notes (formulas, unitless source values) | 109 |

Per-council active/verified/manual-review counts and open gaps:

| Council | Active | Verified | Manual review | Open gaps |
|---|---|---|---|---|
| Brisbane City Council | 20 | 20 | 7 | 35 |
| Burke Shire Council | 5 | 5 | 1 | 0 |
| Central Highlands Regional Council | 3 | 3 | 0 | 0 |
| City of Gold Coast | 36 | 36 | 0 | 1 |
| City of Moreton Bay | 14 | 14 | 3 | 27 |
| Livingstone Shire Council | 33 | 33 | 6 | 0 |
| Logan City Council | 9 | 9 | 0 | 1 |
| Mount Isa City Council | 0 | 0 | 0 | 21 |
| Redland City Council | 3 | 3 | 1 | 25 |
| Rockhampton Regional Council | 10 | 10 | 6 | 1 |
| South Burnett Regional Council | 13 | 13 | 13 | 0 |
| Sunshine Coast Regional Council | 8 | 8 | 0 | 4 |
| Toowoomba Regional Council | 28 | 28 | 24 | 7 |
| Townsville City Council | 3 | 3 | 3 | 1 |
| **Total** | **185** | **185** | **64** | **123** |

**Mount Isa has zero active rules.** Its scheme's Table 9.3.6.3 states that "the Queensland Development Code
setbacks apply for dwelling houses and dual occupancies", which on its face displaces the scheme's own AO4.1/AO4.2
front-setback values for a dwelling house and (on the view that a dwelling house includes its domestic outbuildings)
its Class 10a structures too. Every front-setback draft was therefore decided MANUAL_REVIEW rather than curated, and
every side/rear draft was decided DOCUMENTED_ABSENCE. The one rule that is unambiguous either way — AO23.1, garages
behind the front building line or within an opening-width limit — has no numeric distance and stays manual review.
Mount Isa's overall result is still PASS_WITH_WARNINGS, not FAIL or BLOCKED: the pipeline ran, the records that exist
are correctly classified, and the "zero active rules" is itself the correct, source-supported answer for this
scheme, not a processing failure.

## 3. What changed since the first run (22 Oct)

The first run (`npm run validate-setbacks`, 22 Oct) covered all 7 setback-related topics across the 6 councils then
loaded, and found 8 of the 14 councils never onboarded. Since then:

1. **Scope narrowed.** The user restricted the primary dataset to Class 10 front/side/rear setbacks only. Site cover,
   height, landscaping and similar topics are no longer validated or reported as gaps.
2. **8 councils onboarded.** Burke, Central Highlands, Livingstone, Mount Isa, Rockhampton, South Burnett, Toowoomba
   and Townsville were researched from their current planning schemes (`research/councils/<slug>.json`,
   `research/places.json`), loaded as drafts (`db/030_council_<slug>.sql`), and curated into ACTIVE Class 10 rules
   where the source supports it (`db/039_council_curated_<slug>.sql`, one per council except Mount Isa — see §2).
   `db/010_reference_data.sql` gained 8 new authorities and local governments.
3. **New Class 10 setback rules curated for the 6 already-loaded councils** (`db/038_council_curated_class10_setbacks.sql`):
   13 for Gold Coast (Township and Medium density residential zones, rear lots, the Mudgeeraba Village character
   overlay), 8 for Brisbane (the under-180 m² small-lot table and two neighbourhood-plan rules), 4 for Sunshine Coast
   (Rural zone and two local-plan precincts), 2 for Logan, 1 for Redland, and one supplementary source citation for
   Moreton Bay. These were all previously DRAFT records the 22 Oct scope had not reached.
4. **One data error found and fixed:** two Sunshine Coast research records — the researcher's own notes that the
   scheme states no side/rear setback and no site-cover value — were stored with `verification_status:
   VERIFIED_VERBATIM`, as if they were quoted scheme text. Corrected to `UNVERIFIED` (`change_log.csv` C016).
5. **The validator (`validate-setbacks.ts`) was extended**, not just re-run: it now recognises `GARAGE.FRONTAGE`,
   `SETBACK.SIDE_REAR.BTB` and the `POOL.SETBACK*` topics as primary (they are front/side/rear setbacks for Class 10
   even though they weren't in the original "frontage/side/rear" topic list); it loads
   `validation/curation_decisions.json` so a planner's considered decision on a draft (out of scope, excluded
   category, documented absence, needs manual review) is respected instead of re-flagged as an unexplained gap; it
   allows EXEMPTION-role rules (QDC-style "structures under 2 m are exempt") to carry no measurement/operator; and it
   fixed two false positives (a value like "0.750" not matching "0.75", and a 0 m built-to-boundary allowance always
   counting as stated in its own source by definition).

## 4. Tests

| Test | Result | Evidence |
|---|---|---|
| A. Processing (pipeline) | **PASS** 14/14. Every council's generator output matches its `db/030_council_<slug>.sql`, and `verify-load` is OK for every council with a research file | `council_validation_summary.csv` `pipeline_status`; `npm run check`, `npm run verify-load`, `npm run import-research -- --check` all PASS |
| B. Data integrity | **PASS** 14/14, zero errors. Council↔scheme↔version links are consistent, every scheme version is ACTIVE, units are `m` (exemptions excepted), values are within range, every ACTIVE rule has structure subjects, every SUPERSEDED draft has an ACTIVE replacement | `data_integrity` |
| C. Source traceability | **PASS** 14/14. Every active primary record has a PRIMARY provision with verbatim text, a URL and a page/anchor, and every fixed value — numeral, word ("ten metres"), or a stated 0 m built-to-boundary allowance — is found in its source text | `source_traceability` |
| D. Scope | **PASS** 12/14, **PASS_WITH_WARNINGS** 2/14 (Logan, Redland — one ambiguous draft each, see §6). No active record misclassifies topic vs. measurement vs. boundary, and no active record is secretly an excluded category | `scope_test` |
| E. Completeness | 123 open gaps, see §6 | `missing_setbacks.csv` |
| F. Duplicates / idempotency | **PASS**. 0 duplicate or conflicting active records. The validator was run twice back to back on the reloaded live database and produced byte-identical CSVs; the database fingerprint (row count + md5 of 13 `regs` tables) was unchanged before and after every run, including the full `siteora` reload | `db_fingerprint.txt` |
| G. Regression | **PASS**. `npm run check`: 7/7 integrity invariants, 7/7 recorded examples (one example's recorded output was re-recorded this run — see §7). `verify-load`: 15/15 councils with research files. `import-research --check`: 15/15. `parity:offline`: OK. Ipswich (outside the 14, but one of the original 7) pipeline: PASS | console logs of this run |

## 5. Scheme metadata

Every one of the 14 councils' current scheme name and version is recorded, sourced from the council's own site or
ePlan/API as at 22 Oct 2026 (source-coverage evidence in `source_coverage.csv`). 12 are CURRENT with direct evidence.
Burke and Mount Isa are UNCONFIRMED only because neither council publishes a version or amendment number for its
2020 scheme — the scheme identity and commencement date are confirmed, just not a version label. Three further
details are noted but don't affect correctness: Moreton Bay's "created by LGIP Amendment No. 2" wording, Logan's
"printed with TLPI No. 1/2024" wording, and the fact that Mount Isa's PDF could not be downloaded automatically (an
Internet Archive copy was used instead, hash recorded in the research file).

## 6. Completeness — what is still missing, and why

`missing_setbacks.csv` has 320 rows; 123 are counted as open gaps (`missing_setback_requirements`), the rest are
settled (reviewed-and-decided, or a documented/genuine absence) and listed for evidence only.

| Gap type | Meaning |
|---|---|
| `ZONE_DRAFT_ONLY` / `ZONE_NO_COUNCIL_RULE` / `ZONE_PARTIAL_COVERAGE` | A residential-type zone has, respectively: only an uncurated draft; no council provision found at all; or a rule that covers only some of its precincts |
| `SOURCE_PROVISION_NOT_CLASSIFIED_AS_SETBACK` | A provision that mentions "setback" is filed under a non-setback topic (height, site cover, outbuilding size) and may hold a front/side/rear requirement worth a second look |
| `DOCUMENTED_ABSENCE` / `ZONE_GENUINELY_ABSENT` | The scheme itself, or the research, states that no council value applies here — the QDC/QHC governs. Not a gap in the dataset; listed as evidence |
| `REVIEWED_*` | A planner already decided this draft (`validation/curation_decisions.json`): `REVIEWED_OUT_OF_SCOPE` (doesn't reach Class 10, or isn't a boundary distance), `REVIEWED_EXCLUDED_CATEGORY` (buffer/waterway/access, not a setback), `REVIEWED_DOCUMENTED_ABSENCE`, `REVIEWED_MANUAL_REVIEW` (reaches Class 10 but needs a human — ambiguous wording, a missing table, a drafting conflict) |

**Where the remaining ZONE_DRAFT_ONLY / ZONE_NO_COUNCIL_RULE / SOURCE_PROVISION gaps concentrate** (highest value to
curate next):

1. **Brisbane** (16 `SOURCE_PROVISION_NOT_CLASSIFIED_AS_SETBACK`, 15 `ZONE_DRAFT_ONLY`): several Dwelling House
   Character and Traditional Building Character overlay provisions for specific neighbourhood plans
   (New Farm/Teneriffe, Sherwood–Graceville, Latrobe/Given Terraces) are drafts only, plus height/site-cover
   provisions that mention setbacks only in passing.
2. **Moreton Bay** (14 `SOURCE_PROVISION_NOT_CLASSIFIED_AS_SETBACK`, 5 `ZONE_PARTIAL_COVERAGE`): the Rural, Rural
   residential and Township zones have Class 10 drafts (RAD3/RAD26/RAD59 routing and outbuilding-location rules)
   that reach Class 10 but are non-numeric siting rules ("behind the main building line") rather than distances, so
   they were correctly decided MANUAL_REVIEW rather than curated as a number.
3. **Redland** (21 `ZONE_NO_COUNCIL_RULE`): 7 zones (Character residential, Emerging community, Environmental
   management, Low-medium/Medium density residential, Rural, Tourist accommodation) × front/side/rear have no
   council Class 10 provision in the research. Only the LDR zone code is declared a QDC alternative provision in
   City Plan v14; whether the other zone codes set a planning-track Class 10 setback needs checking against the
   current scheme.
4. **Mount Isa / Townsville / South Burnett / Central Highlands / Toowoomba**: large counts of
   `ZONE_GENUINELY_ABSENT` are the expected, correct result of these schemes genuinely deferring most or all of
   their residential zones to the QDC for Class 10 — not missing curation.

## 7. Regression note: one recorded example re-recorded

`examples/brisbane_small_lot_character.out.md` failed a line-for-line comparison after the 8 new councils were added
to `db/010_reference_data.sql` (new `local_governments`/`authorities` rows shift the tie-break order the evaluator
uses when two rules have an identical sort key — regime, topic, boundary — and no further explicit order). Confirmed
by comparing the sorted line sets of both outputs: **identical content, different order only** — no rule, value,
scope or classification changed. Re-recorded with `npm run check -- --update`; `npm run check` now passes cleanly
with no other example's output affected.

## 8. Corrections applied

All changes are logged in `change_log.csv` (C001–C016). This run's additions, C010–C016, are described in §3 items
3–4 above. **No existing ACTIVE record's value was changed** — the corrections were: citing an additional
supplementary source (C015, following the same pattern as C001/C002), curating previously-uncurated drafts into new
ACTIVE records (C010–C014, the normal curation step — see `db/038` and `db/039_council_curated_*.sql`), and fixing
two mismarked `verification_status` values that were never scheme text (C016).

Every live-database change in this run was dry-run first: each `db/039_council_curated_<slug>.sql` file was run
inside a rolled-back transaction against the scratch database `siteora_test`, and the curating agent confirmed
`SELECT count(*) FROM regs.rules WHERE rule_id LIKE '<AUTH>.C.%'` returned 0 afterwards, before anything was added to
`load_all.sql`. A full reload of `siteora_test` was then checked (pipeline, integrity, traceability, regression,
idempotency) before the live database `siteora` was reloaded the same way. A pre-reload backup of the live `regs`
schema is named in the change log (`backup_file`).

## 9. Curation decisions (why a draft was not curated)

`validation/curation_decisions.json` records a decision for every reviewed front/side/rear/garage-frontage/BTB draft
that was **not** curated, across all 14 councils (102 entries): 58 `OUT_OF_SCOPE` (doesn't reach Class 10, or isn't a
boundary distance — e.g. parking-space counts, driveway/crossover/garage-opening widths, car-accommodation width),
23 `MANUAL_REVIEW` (reaches Class 10 but is non-numeric, conflicting, or missing a referenced table), 16
`DOCUMENTED_ABSENCE` (the provision itself says the QDC applies), and 5 `EXCLUDED_CATEGORY` (waterway/revetment/
coastal-hazard setbacks wrongly captured by a front/side/rear keyword match). Each entry cites the scheme reason.
The validator treats a `MANUAL_REVIEW` decision as a confirmed open item, not a silent gap.

## 10a. Correctness bug found and fixed after this report was first published (23 Oct 2026, later)

A user inspecting the POC UI reported that `LCC.C.CARPORT_TO_FRONT_BOUNDARY` (Logan, "carport ≤6×6 m, ≤3.5 m high,
unenclosed may be built to the front boundary", Table 9.3.2.3.1 PO4/AO4(a)) was showing as a built-to-boundary
relaxation on the **side and rear** boundaries of a test site, not only the front. Table 9.3.2.3.1 AO4(a) says "front
boundary" only.

**Root cause:** the rule had no `boundary_type` condition. The engine (`evaluate.ts`) evaluates every ACTIVE
requirement/relaxation rule once per boundary the structure has (front, side, rear, secondary); nothing restricts a
rule to a specific boundary except an explicit `boundary_type` condition in its own `conditions`. With none present,
`conditionsHold()` returns true unconditionally, so the rule was a live candidate — and, because it's a RELAXATION
permitting 0 m, it displaced the normal side/rear setback — on every boundary, not only the front boundary the
source text names. Confirmed by re-evaluating the exact scenario before and after the fix (a 6×6 m carport on a
Low density residential / Small acreage precinct lot): before, SIDE and REAR both showed "BTB permitted (0 m)" from
this rule; after, SIDE and REAR correctly show the ordinary 3 m acreage setback, and only PRIMARY_FRONTAGE shows the
built-to-boundary relaxation.

**Fix:** added `{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}` to the rule's conditions
(`db/031_council_curated.sql`) — logged as `change_log.csv` C017.

**A full sweep for the same failure pattern** (every ACTIVE rule whose measurement the engine treats as per-boundary,
with no `boundary_type` condition at all, across the whole dataset, not only the Class 10 primary topics) found three
more rules with the same structural gap. One was this Logan carport rule (now fixed). The other two are legitimately
boundary-agnostic on inspection of their source text, not bugs:
* `QHC.CH1.T24.POOL_SOLID_FENCE_BTB` / `QHC.CH2.T24.POOL_SOLID_FENCE_BTB` — the cited QHC provisions themselves cover
  both "between the water and the frontage" and "between the water and the adjoining premises" with the same 0 m
  built-to-boundary outcome, so matching on every boundary is correct.

One further rule was found outside the Class 10 setback scope this validation covers and is flagged here but **not
changed**, pending direction: `SCC.C.GARAGE_DOOR_WIDTH_6` (Sunshine Coast, garage door width facing a street ≤ 6 m)
also has no `boundary_type` condition. Its value does not depend on which boundary is shown, so this is a display
duplication (the same correct value appears, redundantly, under side and rear sections too) rather than a value
error like the Logan case — but it is the same underlying gap and a planner should decide whether to add
`boundary_type IN ["PRIMARY_FRONTAGE", "SECONDARY_FRONTAGE_ROAD"]` to it.

The validator (`validate-setbacks.ts`) was strengthened to catch this class of bug going forward: a Class 10 primary
rule with a single-boundary topic (front-only, side-only, rear-only, secondary-only, garage-frontage) and no
`boundary_type` condition is now flagged **ERROR** (`CLASSIFICATION_NO_BOUNDARY_CONDITION`), not the earlier INFO —
that downgrade, made during the 22–23 Oct Class 10 curation pass on the mistaken assumption that a rule's
`measurement_id` alone restricts its boundary, was itself the reason this bug weren't caught by validation. A
multi-boundary topic (`SETBACK.SIDE_REAR`, `POOL.SETBACK*`) with no condition is flagged WARNING, since it may
legitimately cover all of its boundaries uniformly, as the two QHC pool rules do.

## 10b. Idempotency and regression re-verified after the fix

`npm run check`, `verify-load`, `import-research --check` and `parity:offline` all PASS on the reloaded live
database. `npm run validate-setbacks` still reports 0 errors across all 14 councils, and the database fingerprint
was unchanged by the validation run itself. The only recorded-example change was re-recording
`examples/brisbane_small_lot_character.out.md`, whose row order (not content) shifts on a fresh schema reload because
the evaluator's tie-break for rules sharing a sort key depends on database insertion order; confirmed order-only by
comparing sorted line sets before re-recording.

## 10. Files

| File | Content |
|---|---|
| `council_validation_summary.csv` | One row per council (14), every field the task specified, including overall status |
| `validation_issues.csv` | 181 issues (0 error, 72 warning, 109 info as of this run), each with evidence, recommended fix and resolution status |
| `missing_setbacks.csv` | 320 completeness rows, 123 counted as open gaps (§6) |
| `source_coverage.csv` | Per council: spreadsheet scheme/link, current version found, evidence, format, setback location, DB version, provisions held |
| `setback_records_audit.csv` | Every setback-type record checked: value, kind (fixed/conditional/formula), boundaries, structures, places, conditions, source, Class-10 check result, flags |
| `change_log.csv` | C001–C016: every change applied, with backup file and approval reference |
| `curation_decisions.json` | 102 reviewed-draft decisions (§9), read by the validator |
| `db_fingerprint.txt` | Row count + md5 of the audited tables at the end of the run |
| `councils.json` | Validator input: councils, spreadsheet metadata, online version-check evidence, scope note |
| `proposed_changes/001_logan_supplementary_sources.sql` | Approved and applied in `db/032` (22 Oct); kept as the record of the reviewed change |

Re-run: `npm run build && npm run validate-setbacks` (overwrites the CSVs; `change_log.csv` is appended to, never
overwritten).

---

## Appendix: the 22 Oct run (original 7 councils, full topic scope, 6 of 14 loaded)

The sections below are the unmodified first report, covering the state before the Class 10 scope restriction and the
8-council onboarding described above. They remain accurate as a historical record of that run; §1–§10 above are the
current, authoritative numbers.

### A1. Result in one table (22 Oct)

| Council | Scheme / version in DB | Online version check | Overall |
|---|---|---|---|
| Brisbane City Council | Brisbane City Plan 2014 v37.00/2026 (18 Sep 2026) | CURRENT | PASS_WITH_WARNINGS |
| City of Gold Coast | Gold Coast City Plan Version 14 (29 Sep 2026) | CURRENT | PASS_WITH_WARNINGS |
| City of Moreton Bay | MBRC Planning Scheme Version 8 (11 Sep 2026) | CURRENT (label wording unconfirmed) | PASS_WITH_WARNINGS |
| Logan City Council | Logan Planning Scheme 2015 V9.2 (1 Jul 2025) | CURRENT (TLPI wording unconfirmed) | PASS_WITH_WARNINGS |
| Redland City Council | Redland City Plan Version 14 (10 Nov 2025) | CURRENT | PASS_WITH_WARNINGS |
| Sunshine Coast Regional Council | Sunshine Coast Planning Scheme 2014, amendment 27 (23 Jan 2024) | CURRENT | PASS_WITH_WARNINGS |
| Burke Shire Council | — not in dataset | UNCONFIRMED (no version published) | BLOCKED |
| Central Highlands Regional Council | — not in dataset | CURRENT (Amendment No. 7) | BLOCKED |
| Livingstone Shire Council | — not in dataset | CURRENT (Version 4) | BLOCKED |
| Mount Isa City Council | — not in dataset | UNCONFIRMED (no version published) | BLOCKED |
| Rockhampton Regional Council | — not in dataset | CURRENT (Version 5) | BLOCKED |
| South Burnett Regional Council | — not in dataset | CURRENT (Version 2.0) | BLOCKED |
| Toowoomba Regional Council | — not in dataset | CURRENT (v29) | BLOCKED |
| Townsville City Council | — not in dataset | CURRENT (Version 2025/01) | BLOCKED |

At that point the dataset covered 7 setback topics (front, side, rear, side-and-rear, secondary-road frontage,
built-to-boundary length, waterway) for all building classes across 6 of the 7 originally-loaded councils (Ipswich
was covered only by the regression checks). Sections A2–A9 of the original report (premise correction, pipeline
components reused, test results, record statistics, completeness, classification findings on drafts, scheme
metadata, and the Logan change-set proposal/approval) are preserved in git history at the commit that introduced
this file, and are superseded in substance by §1–§10 above.
