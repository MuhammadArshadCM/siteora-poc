# Part 2 — Rule taxonomy

`rules.topic` uses a dotted code. The engine groups competing rules by **topic + measurement + boundary**,
so two rules only "compete" when they measure the same thing against the same boundary.

## Setbacks

| Topic | Meaning | Typical measurement |
|---|---|---|
| `SETBACK.ROAD` | Any road boundary (legacy MP 1.x "road setback") | `MP_ROAD_SETBACK_OMP` |
| `SETBACK.FRONTAGE` / `SETBACK.FRONT` | Primary frontage (QHC "frontage boundary" incl. lane/park frontages) | `QHC_WALL_TO_BOUNDARY`, `SCHEME_SETBACK_FRONT` |
| `SETBACK.SECONDARY_ROAD` | Secondary road frontage on corner lots | `QHC_WALL_TO_BOUNDARY`, `SCHEME_SETBACK_SECONDARY_FRONTAGE` |
| `SETBACK.CORNER` | Corner-lot concessions (nominated frontage, Table A1 graph/formula) | road measurements |
| `CORNER.TRUNCATION` | Nothing > 2 m in 9 m × 9 m corner triangle | `MP_CORNER_TRUNCATION_9X9` (EXCLUSION_ZONE) |
| `CORNER.SIGHTLINE` | Max 1 m high in 6 m-radius 3-chord truncation | `MP_SIGHTLINE_TRUNCATION_6M_RADIUS` |
| `SETBACK.SIDE`, `SETBACK.REAR`, `SETBACK.SIDE_REAR` | Common-boundary clearances | `MP_SIDE_REAR_CLEARANCE_OMP` (per part), `QHC_WALL_TO_BOUNDARY` |
| `SETBACK.SIDE_REAR.BTB` | Built-to-boundary permission + its limits (height, mean height, aggregate length, window distance) | setback ≥ 0 plus `*_BTB_LENGTH*` |
| `SETBACK.SIDE_REAR.MAINTENANCE` | Walls < 750 mm must be maintenance-free | `QHC_WALL_TO_BOUNDARY` |
| `SETBACK.*.EAVES` | Weather control elements (eaves, awnings) — QHC measures these separately from walls | `QHC_BUILDING_PART_TO_BOUNDARY` |
| `SETBACK.WATERWAY` | Canal / lake / revetment setbacks (council) | `SCHEME_SETBACK_WATERWAY` |
| `SETBACK.FENCE` | Fences/retaining walls ≤ 2 m on boundary | `QHC_STRUCTURE_OMP_TO_BOUNDARY` |
| `GARAGE.FRONTAGE` | Garage door setback, car accommodation forward of house | `QHC_GARAGE_DOOR_TO_ACCESS_BOUNDARY`, `SCHEME_GARAGE_CARPORT` |
| `GARAGE.OPENING_WIDTH` | Access width limits vs lot width / frontage | `GARAGE_OPENING_WIDTH_FACING_STREET`, `QHC_GARAGE_ACCESS_WIDTH` |

## Separation

| Topic | Meaning |
|---|---|
| `SEPARATION.BUILDINGS` | Between buildings on the same site (e.g. Gold Coast "double the side setback" between habitable buildings; Redland LDR3 4 m) |
| `SEPARATION.WINDOW` | Class 10a ≥ 1.5 m from an adjoining habitable-room window (MP 1.x A2(d)(iii)); BTB wall separation (Ipswich 0.9 / 1.5 m) |
| `INFRASTRUCTURE.SEPARATION` | MP 1.4 footing 1.2 m from centreline, 1.5 m clear radius around maintenance covers, ≤ 10 m light-weight Class 10 over pipe |
| `INFRASTRUCTURE.APPLICATION` | MP 1.4 out-of-scope test (≥ 3 m + zone of influence) |
| `FIRE.SEPARATION` | NCC fire separation (not populated — text not held) |

## Height and bulk

| Topic | Meaning |
|---|---|
| `HEIGHT.BUILDING` | Dwelling/building height, storeys |
| `HEIGHT.CLASS_10A` | Outbuilding / garage / carport height caps (QHC 4.5 m; GC 3.5 m freestanding; SC 3.6 m; MB 4 m / 4.5 m) |
| `HEIGHT.WALL` | Wall-height-dependent limits |
| `HEIGHT.FENCE` | Fence / screen / retaining wall caps |
| `OUTBUILDING.SIZE` | Floor area / roofed area caps (Logan 150 m² cumulative; SC 56 m²; MB 50–150 m² by lot size) |
| `MEAN_HEIGHT` conditions | Used inside BTB and carport rules (≤ 3.5 m) and Building Reg sch 1 s13 (≤ 2.1 m) |

## Site controls

| Topic | Meaning |
|---|---|
| `SITE_COVER` | Maximum site cover (definition differs per instrument — measured per the rule's measurement) |
| `LANDSCAPE.OPEN_SPACE` | Landscape / private open space / impervious area |
| `PRIVACY` | Privacy screens for decks > 1 m within 2 m of a boundary |
| `BUILDING_ENVELOPE` | Approved building envelope / plan of development (deemed acceptable solution under QHC s7(3)) |

## Pools

| Topic | Meaning |
|---|---|
| `POOL.APPLICABILITY` | Is it a swimming pool / regulated pool (definition rules) |
| `POOL.SETBACK.ROAD` / `POOL.SETBACK.FRONTAGE` / `POOL.SETBACK.SIDE_REAR` | Water's-edge setbacks |
| `POOL.SETBACK` | BTB relaxations behind solid fences |
| `POOL.BARRIER.PRESENCE` | A compliant barrier exists and is continuous |
| `POOL.BARRIER.HEIGHT` | 1200 mm minimum; 1800 mm if NCZ inside |
| `POOL.BARRIER.NCZ` | Non-climbable zone requirements / exemptions |
| `POOL.BARRIER.LOCATION` | No building doors in the barrier; access from patios with a permanently open side |
| `POOL.GATE` | Self-closing/latching, opens away from pool |
| `POOL.PROCESS` | Warning sign, certificate before filling |

## Pathway (not pass/fail)

| Topic | Meaning |
|---|---|
| `APPLICATION` | Whether a code applies at all (QHC s4 exclusions; MP 1.x "< 1 m above natural ground") |
| `PATHWAY.ACCEPTED_BUILDING_WORK` | Building Reg sch 1 s13 small Class 10 |
| `PATHWAY.REFERRAL` | Planning Reg referral to council |

## Classification dimensions on every rule version

| Column | Values | Why it matters |
|---|---|---|
| `regime` | PLANNING, BUILDING, POOL_SAFETY, FIRE_SAFETY, ENVIRONMENTAL, INFRASTRUCTURE, OTHER | Separate tracks, separate consequences |
| `enforceability` | MANDATORY, DEEMED_TO_COMPLY, DISCRETIONARY, ADVISORY, MANUAL_REVIEW | A DEEMED_TO_COMPLY miss is *not* a fail — it means "performance solution / referral" |
| `role` | REQUIREMENT, EXEMPTION, RELAXATION, TRIGGER, DEFINITION_RULE | Exemptions/relaxations never produce a number on their own |
| `on_noncompliance` | FAIL, REFERRAL_TO_LOCAL_GOVERNMENT, REFERRAL_TO_SERVICE_PROVIDER, PERFORMANCE_SOLUTION_REQUIRED, PLANNING_APPROVAL_REQUIRED, ASSESS_AGAINST_PERFORMANCE_OUTCOME, MANUAL_REVIEW | What the software should tell the user |
| `automatable` | true/false | Only true when the text is verified and unambiguous **and** the inputs are objective |
