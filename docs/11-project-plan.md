# Project plan — Class 10a and pool siting check (7 SEQ councils)

Status as at 12 Oct 2026. Builds on the dataset, engine and POC already in this repository.

## 1. Scope

**User enters:** address · proposed structure · width · length · height.

**Structures:**
* Class 10a: shed, garage, carport, patio, pergola, deck, gatehouse, detached laundry.
* Pools: in-ground pool, above-ground pool, spa.

**System returns, per property and structure:**

| Item | Detail |
|---|---|
| Front setback | Primary frontage; also secondary frontage on corner lots |
| Side setback | Including whether building to the boundary is allowed, and on what conditions |
| Rear setback | Including building to the boundary, as for side |
| Maximum height | For the structure |
| Maximum site cover | % of the lot; the remaining area once existing buildings are known |

**Councils:** Brisbane, Gold Coast, Moreton Bay, Sunshine Coast, Logan, Ipswich, Redland.

**Admin features:**
* (a) Load a new planning-scheme version, which replaces the current one from a chosen date.
* (b) Switch a council from QDC to QHC when the council adopts the QHC.

**Out of scope:**
* Class 1 (houses) and Class 2.
* Pool barriers (MP 3.4).
* Planning-approval triggers.
* Measuring a drawn design.

The data for the out-of-scope items is already in the database and simply isn't shown. Sewer and water-main
clearance (QDC MP 1.4) is shown as a warning only.

## 2. What already exists

| Component | State |
|---|---|
| PostgreSQL rules database (`regs`) | 191 active rules, 663 verbatim clauses, all with sources, effective-dated and versioned |
| State rules | QDC MP 1.1 / 1.2 (in force until council adoption or 1 Sep 2029), QHC Ch 1 / Ch 2 (encoded, ready), Building Regulation transition |
| Council rules | 85 curated, plus 187 drafts (verbatim text held, not yet machine-readable). 103 of the drafts are setback, site-cover or height clauses that can apply to Class 10a or pools |
| Rules engine (`server-ts/src/core/evaluate.ts`) | Scope (zone / precinct / overlay / local plan) → conditions → precedence (overrides, relaxations, exemptions) → value |
| Property lookup | Geocoding, cadastre (lot area, outline), council, PDA, zoning for 6 councils, Brisbane overlays and neighbourhood plans |
| Checks | `npm run check` (data invariants plus recorded example results), `npm run verify-load` (database vs research, word for word), `npm run parity` (results vs the recorded reference) |

## 3. How the result is prioritised

For each item (front, side, rear, height, site cover), the engine collects every rule that applies and keeps the
one with the highest priority. The others are listed under it as "replaced by…" so the user can see why.

| Priority | Source | Example |
|---|---|---|
| 1 | Overlay / neighbourhood-plan / local-plan rule | Brisbane character overlay front setback |
| 2 | Precinct rule | Logan Low density residential – Acreage: 10 m road setback |
| 3 | Zone rule (council alternative provision to the QDC/QHC) | Gold Coast Low density residential: 6 m front |
| 4 | Council-wide rule | Brisbane 9.5 m dwelling-house height |
| 5 | QDC MP 1.1 / 1.2, or the QHC once adopted | 6 m front, 1.5 m side/rear, 50 % site cover |
| — | Concessions applied on top of the governing rule | QDC A2(d): Class 10a may be built to the boundary if ≤ 9 m along it, ≤ 4.5 m high and ≤ 3.5 m mean height |

* Where two rules of the same priority both apply (e.g. small-lot code *and* character overlay), both are shown,
  and the stricter one governs.
* Every value carries:
  * the clause reference and its exact text
  * the planning-scheme version
  * a status: **DETERMINED**, **ASSUMED** (a default was used, shown with the reason) or **CHECK** (needs a person).

## 4. Inputs the user does not give, and how they are filled

| Needed fact | Source | If it can't be found |
|---|---|---|
| Lot area, width, depth | State cadastre (DCDB) | — |
| Which edge is the road frontage; corner lot | Parcel edge touching the road parcel (Phase 1) | User ticks "corner lot" |
| Zone, precinct | Council zoning map service | User picks the zone (Ipswich until access is granted) |
| Overlays, neighbourhood plans | Council overlay map services | Warning: "overlay not checked" |
| Street type (lots under 450 m²: 3 m access street / 4 m collector) | Council road-hierarchy layer where published | **4 m, ASSUMED** |
| Distance to the neighbour's habitable window (for building to the boundary) | Not available | Show "1.5 m, or 0 m if the structure is at least 1.5 m from a neighbour's habitable-room window"; status CHECK |
| Pool coping height | Height input | — |
| Existing roofed area (for remaining site cover) | State building-footprint data (Phase 4), else user | Show the maximum % and m² only |

## 5. Phases

Estimates assume 1 developer, plus a part-time reviewer for the regulatory data (a planner or certifier).

### Phase 1 — Narrow the product to the five items (1 week)
* Simplify the input form to address, structure, width, length and height; derive everything else (section 4).
* Output: one card per boundary (front / side / rear), plus height and site cover. Show the governing value first
  and the replaced rules underneath.
* Street-type input, with the 4 m ASSUMED default.
* Correct the MP 1.1 neighbour-alignment rule to houses only, as its text says.
* Road-frontage and corner-lot detection from the cadastre.
* **Done when:** 20 test addresses (about 3 per council) produce all five items, each DETERMINED, ASSUMED or CHECK
  with a reason.

### Phase 2 — Complete the council data for these five items (2–3 weeks)
* Curate the 103 in-scope drafts, ordered by how many lots each affects:

  | Council | In-scope drafts |
  |---|---|
  | Moreton Bay | 27 |
  | Logan | 26 |
  | Brisbane | 15 |
  | Gold Coast | 13 |
  | Sunshine Coast | 10 |
  | Ipswich | 8 |
  | Redland | 4 |

  Each batch is loaded, `npm run check` and `npm run verify-load` are run, and the result is recorded as a regression example.
* Resolve the Gold Coast question: can Class 10a sheds use the QDC built-to-boundary concession in the Low density
  and Rural residential zones? This is one written question to the council or a certifier.
* Overlays that change these five items for the other 6 councils (character, flood, coastal), using the same map
  method as Brisbane.
* Ipswich: request open-data access to the City Plan 2025 zoning layer; manual zone selection until then.
* **Done when:** no in-scope drafts remain, or the ones left are documented as "manual check: [reason]".

### Phase 3 — Planning-scheme update process (2 weeks)
Goal: an admin loads a new scheme version, and it replaces the old one from its commencement date. Old results
stay reproducible.

1. **Upload or register** the new version (PDF or ePlan link, version label, commencement date). The system
   stores its SHA-256 hash and creates a new `instrument_version`.
2. **Extract** the clause text for each rule the dataset uses, via the council's ePlan API or PDF text, as now.
3. **Compare** each clause with the previous version:
   * *Unchanged:* the rule is carried forward automatically as a new rule version.
   * *Changed, new or deleted:* goes to a review queue with a side-by-side text diff.
4. **Review:** a curator edits the value or conditions where the text changed. Nothing changed is published
   without review.
5. **Test:** re-run the regression addresses for that council, and show which results changed and why.
6. **Publish:** the new version takes effect from its commencement date and the old version ends the day before.
   Assessments dated before that date still use the old rules.

A new scheme cannot be turned into rules fully automatically and reliably: values are buried in tables, figures
and exceptions. The process automates detection and the unchanged majority; people handle what changed.

### Phase 4 — QDC → QHC switch per council (1 week)
* Admin action: **"Council X adopted the QHC on date D."** It:
  * ends QDC MP 1.1 / 1.2 for that council at D − 1, and starts the QHC from D, in `instrument_applicability`
    (already modelled; tested on a copy of the database);
  * lists the council's rules whose "overrides" links point only at QDC rules, and asks a curator to point them at
    the matching QHC rules. Example: Brisbane's 9.5 m height currently overrides QDC rules only;
  * re-runs the council's regression addresses and shows what changed.
* The statutory end date (1 Sep 2029, the QHC applies everywhere) is already encoded, so no action is needed then.
* Monthly check of the department's QHC adoption register and council scheme amendments. This is a calendar task;
  it could be a scheduled scraper later.

### Phase 5 — Professional validation (1–2 weeks elapsed, parallel with Phases 2–4)
* A building certifier checks the five values for 15–20 real addresses: standard lot, small lot, corner lot,
  overlay or precinct case, and pool, across all 7 councils.
* Their answers become permanent regression tests, so any data or code change that alters them fails `npm run check`.

### Phase 6 — Production readiness (1–2 weeks)
* Replace the psql calls with a database driver and connection pool; add an HTTP API with input validation.
* Cache the council map-service results and handle outages: Logan's service is on a consultant's server, and Gold
  Coast publishes Version 13 data while Version 14 is in force.
* Admin authentication for Phases 3 and 4, and an audit log of who changed what. The `verification_log` table
  already exists.

**Total:** about 8–11 weeks of development, plus certifier time.

## 6. Risks

| Risk | Mitigation |
|---|---|
| A wrong value reaches a site plan | Every value is shown with its clause text and status; certifier regression set; ASSUMED values are always visible |
| Council map services change or go offline | Endpoints in configuration; health check; manual zone fallback |
| Scheme amendments are missed | Monthly check; version hashes; the update process in Phase 3 |
| Councils adopt the QHC at different times | Per-council switch in Phase 4; the engine selects rules by assessment date |
| Inputs too minimal for conditional rules (e.g. built to boundary) | Show the condition with the answer ("0 m if…") rather than guess |
