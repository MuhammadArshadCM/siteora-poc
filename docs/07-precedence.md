# Part 7 — Rule precedence: how the engine selects the applicable rule

Neither "Council > QDC" nor "QDC > Council" is correct. The rule depends on **which regime** the
requirement belongs to and **whether the council provision has been declared** under Building Act s32/s33.
The engine therefore never infers precedence from "the more specific rule wins". Every displacement is an
explicit, sourced `rule_relationships` row. Where the law is unclear, the row type is `UNRESOLVED`.

## Algorithm

Inputs: `assessment_date`, the site (LG, zone, precincts, overlays, local plans), the proposed structure (type
from `structure_types`), facts, and the boundary segments.

1. **Select instrument versions in force.** For each regime, take the instrument versions whose
   `instrument_applicability` covers (LG or statewide, `assessment_date`). This is where the QHC transition is
   decided: MP 1.1/1.2 for a non-adopting LG before 1 Sep 2029, QHC otherwise. Instruments with no
   applicability rows fall back to their own effective dates (Acts, Regulations).
2. **Candidate rules.** `status = ACTIVE`, effective on the date, belonging to a selected instrument version,
   **scope** matches the site, and
   **subject** matches the structure or one of its ancestors without an exclusion. DRAFT rules are never candidates.
   Scope matching: the council (LOCAL_GOVERNMENT) row must match; the *place* rows (ZONE, PRECINCT,
   LOCAL_PLAN, LOCAL_PLAN_PRECINCT) are alternatives, so any one may match; OVERLAY rows are alternatives among
   themselves and must also match; any matching *exclude* row removes the rule. A site is described by its
   zone, the precincts, local plans and local-plan precincts it is in, and its overlays.
3. **Evaluate conditions** (DNF) per context: one *lot-level* pass (height, site cover, size, barrier) and one
   pass per boundary segment for boundary-measured rules (`measurements.reference_geometry`).
   Result: TRUE / FALSE / UNKNOWN. UNKNOWN keeps the rule but marks it **MANUAL_REVIEW**.
4. **FALLS_BACK_TO.** If a listed table row's own limits are not met (e.g. QHC "garage ≤ 4.5 m" row and the
   garage is 5 m), its target row (Class 1 setbacks) becomes a candidate for that subject. This implements the
   QHC supplementary provisions ("where Class 10a buildings exceed the height requirements … the setbacks for
   Class 1 buildings apply").
5. **Apply relationships between live candidates:**
   * `OVERRIDES`: a council **alternative provision** (s33) or s32 standard displaces the targeted QDC rule(s).
     The basis provision is Building Act s33(4) plus the council's declaration (Table 1.5/1.6 entry or editor's note).
   * `REPLACES`: a successor rule displaces its predecessor (also used for curated vs draft).
   * `EXEMPTS`: if the exemption's conditions are TRUE, the target is removed (e.g. fences ≤ 2 m from A2(a)).
   * `RELAXES`: if TRUE, the relaxation's value (often BTB) replaces the target's value for that context
     (e.g. A2(d) Class 10a within clearance).
   * `ALTERNATIVE_TO`: either rule may be satisfied. Report both; compliance with either passes.
   * `SUPPLEMENTS`: both apply (conjunction).
   * `CONDITIONAL_ON`: the source applies only if the target applies (e.g. 9 × 9 m truncation only with the corner concession).
   * `UNRESOLVED`: both stay and both go to **MANUAL_REVIEW** with the recorded question.
6. **Separate tracks.** Results are grouped by `regime` and never merged:
   * **BUILDING** (QDC/QHC + declared alternative provisions + s32 standards): a miss on a DEEMED_TO_COMPLY rule ⇒
     `REFERRAL_TO_LOCAL_GOVERNMENT` / performance solution, not "fail".
   * **PLANNING** (scheme benchmarks that are not alternative provisions): only relevant if the development is
     accepted-subject-to-requirements or assessable for that lot. A miss ⇒ `PLANNING_APPROVAL_REQUIRED`.
   * **POOL_SAFETY**: MANDATORY ⇒ `FAIL`.
   * **INFRASTRUCTURE** (MP 1.4): a miss ⇒ `REFERRAL_TO_SERVICE_PROVIDER`.
7. **Value and status.** Evaluate `value_expr`. The state is `DETERMINED` only if conditions are TRUE, the value
   is computable, the rule is `automatable`, and no `UNRESOLVED` relationship is live. Otherwise it is
   `MANUAL_REVIEW`. Each result carries its rule id, instrument version and PRIMARY clause.

## Worked precedence cases (all in the data)

| Situation | Outcome | Why |
|---|---|---|
| Brisbane standard lot, shed | MP 1.2 setbacks; Brisbane 9.5 m height overrides MP 1.2 A4 | Brisbane declares no setback alternatives for standard lots; Table 1.6.1 item 6 declares AO2 as the height standard |
| Gold Coast LDR, shed on side boundary | GC 1.5 m side setback overrides A2(a); A2(d) BTB **UNRESOLVED** | Table 1.5-1 makes the zone code the alternative for buildings, but the table is silent on Class 10a BTB |
| Moreton Bay Rural residential, shed | 1.5 / 2 / 4 m by wall height, **no BTB** | RAD48 note expressly replaces MP 1.2 A2(a), (b) **and (d)** |
| Sunshine Coast, shed 4 m high in LDR | Building track: QDC; planning track: 3.6 m cap ⇒ code assessment | AO2.1(b) is a requirement for accepted development, not an alternative provision |
| Any council, pool fence 2.4 m with no NCZ | Pool safety: pass (MP 3.4 item 12); building: QHC fence 2 m exceeded ⇒ referral | Different regimes; both reported |
| Small shed 2.4 m × 3 m, 2.2 m high | Accepted building work (no approval) **but QDC siting still applies** | Building Reg s4(2) + Act s21(5) |
| Same lot assessed on/after 1 Sep 2029 | QHC rules; MP rules out of force; council alternative provisions still listed (conservative) | Building Reg s106(2)(b); status of old alternative provisions is an open issue |

## What counts as an override in the data (audit query)

```sql
SELECT r.from_rule_version_id, r.type, coalesce(r.to_rule_version_id, r.to_rule_id) AS target,
       p.ref_label AS legal_basis, r.notes
FROM regs.rule_relationships r LEFT JOIN regs.provisions p ON p.provision_id = r.basis_provision_id
JOIN regs.rule_versions f ON f.rule_version_id = r.from_rule_version_id AND f.status = 'ACTIVE';
```
