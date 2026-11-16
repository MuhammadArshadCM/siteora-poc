-- =============================================================================
-- Batch resolution of open_issues via more research (not user judgment calls),
-- following the same survey-then-resolve pattern used for the NCC fire-
-- separation and Mount Isa curation work earlier in this session.
--
-- Covers, in order:
--   1. #142 MOUNT_ISA  -- oversight: already proven immaterial in db/063's own
--      header comment, but the UPDATE there only closed #140/#141.
--   2. #41  GOLD_COAST -- confirmed no siting effect (doc-only close)
--   3. #158 TOOWOOMBA  -- confirmed no computational effect (doc-only close)
--   4. #29  GOLD_COAST -- confirmed immaterial stale cross-reference (doc-only)
--   5. #13  BRISBANE   -- confirmed via live ePlan (doc-only close)
--   6. #98, #100, #103 LOGAN -- confirmed already-correct current behaviour
--      (doc-only closes, no rule changes needed)
--   7. #163 TOWNSVILLE -- zone-blind-pathway finding, annotates 3 existing
--      rules, closes the issue
--   8. #120 REDLAND    -- ratifies an already-automatable rule (doc-only)
--   9. #121 REDLAND    -- zone-blind-pathway finding (doc-only close, no
--      rule exists or is needed for the Conservation zone)
--  10. #149 ROCKHAMPTON -- ACTUAL RULE FIX: extends 3 existing dual-occupancy
--      rear-setback rules to cover Class 10a (carports/garages/sheds), not
--      just the dwelling house (Class 1)
--  11. #119 REDLAND    -- NEW curated rule: LDR3 (Point Lookout) building
--      component size cap, reusing the project's existing
--      SCHEME_OUTBUILDING_SIZE measurement (already the standing convention
--      for the identical "floor area vs roofed area" ambiguity, see Logan's
--      LCC.C.OUTBUILDING_FLOOR_AREA_150)
-- =============================================================================
SET search_path = regs, public;

-- -----------------------------------------------------------------------
-- 1. Mount Isa #142 -- oversight fix, zero new research needed.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 142;

-- -----------------------------------------------------------------------
-- 2. Gold Coast #41 -- Rural Table 5.5.20 density-trigger row wording
-- ("Dwelling" vs "Dwelling house") is drafting noise inside a row that
-- excludes Dwelling house either way (an MCU density/height trigger table
-- that never reaches a dwelling house or its Class 10a outbuildings).
-- Confirmed no corresponding rule exists in this dataset keyed to that row.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 41;

-- -----------------------------------------------------------------------
-- 3. Toowoomba #158 -- Table 9.3.10:2's overlapping lot-width bands both
-- resolve to the same 1.2 m side setback; TRC.trc_slh_t2_side already
-- encodes exactly that figure. No computational effect either way.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 158;

-- -----------------------------------------------------------------------
-- 4. Gold Coast #29 -- s1.5's stale "section 1.6(4)" / "Building Regulation
-- 2006" cross-references are immaterial: no rule in this dataset keys off
-- those section-number strings (rules are built from Table 1.6.1's actual
-- content), and the underlying s33 boundary-clearance mechanism is
-- unchanged under the current Building Regulation.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 29;

-- -----------------------------------------------------------------------
-- 5. Brisbane #13 -- live ePlan Table 5.5.2 (fetched directly) does not
-- contain the Package W schedule's note about the Dwelling house character
-- overlay applying to all Low-medium density residential land. The live
-- scheme governs over the static package text; the note is superseded/not
-- in force. No rule in this dataset depends on that note's wording.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 13;

-- -----------------------------------------------------------------------
-- 6. Logan #98, #100, #103 -- all three confirmed already-correct on direct
-- DB inspection, no rule changes required:
--
-- #98: Table 9.3.2.3.2 (AO7.1(b)(i), large >150 m2 outbuildings) lists
-- clearances only for EC, LDR Acreage/Small acreage, RR and EMC/Rural --
-- exactly matching LCC.C.LARGE_OUTBUILDING_CLEARANCE_6M/_20M's existing
-- scopes (ZONE: EMERGING_COMMUNITY, RURAL, ENVIRONMENTAL_MANAGEMENT_AND_
-- CONSERVATION, RURAL_RESIDENTIAL; PRECINCT: LOW_DENSITY_RESIDENTIAL/
-- ACREACE and /SMALL_ACREAGE). Urban LDR/LMDR/MDR lots are correctly left
-- uncovered by any side/rear-clearance rule -- same absence as AO5's
-- ordinary Class 10a clearance in those zones, so QDC MP1.2 governs there
-- by the engine's existing default. AO7.1(a)/(b)(iii) floor-area caps
-- (150/300 m2, LCC.C.OUTBUILDING_FLOOR_AREA_150 / LARGE_OUTBUILDING_MAX_300)
-- still apply regardless of zone.
--
-- #100: LCC.C.LARGE_OUTBUILDING_HEIGHT_5_5 is already scoped LOCAL_GOVERNMENT-
-- wide (Logan), with no zone restriction, confirming AO7.1(b)(ii)'s 5.5 m
-- height cap is Logan-wide. Table 1.6.1 explicitly lists "PO4/AO4, PO5/AO5,
-- PO6/AO6 and PO7/AO7.1" as the s33 boundary-clearance alternative
-- provision -- AO7.1(b)(ii) (height) is part of that same AO7.1 paragraph,
-- so it rides along as part of the alternative provision, not a bare
-- planning-only requirement.
--
-- #103: 9.3.2 v9.2 genuinely has no general dwelling-height AO of its own
-- (only AO7.1(b)(ii)'s 5.5 m, scoped to large outbuildings) -- but the
-- EC zone impact-trigger figures (8.5 m / 10 m by slope) that Table 5.5.3.1
-- actually cites already live in the zone code itself (e.g. 6.2.5 AO2,
-- "building height" per zone), which is encoded separately in this
-- dataset. The cross-reference to "the Dual occupancy and Dwelling house
-- code" is simply mislabelled -- no numeric effect, nothing to change.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (98, 100, 103);

-- -----------------------------------------------------------------------
-- 7. Townsville #163 -- zone-blind-pathway finding (same pattern as Logan's
-- Centre zone, db/052, and Mount Isa, db/063): Townsville's own Class 10
-- building-work assessment table (Table 5.7.1) names only the Character
-- residential zone as triggering code assessment for Class 10a building
-- work -- the Rural zone (which contains the Cungulla precinct) is not
-- listed, so stand-alone Class 10a building work there is Accepted
-- development outright. AO3.2 (the Cungulla precinct's 6 m/3 m/1.5 m
-- setbacks) is only ever cited via Table 5.5.21, an MCU table for dwelling
-- house / caretaker's accommodation / community residence -- it is never
-- named in Table 1.6.1 as a Building Act s33 alternative provision either.
-- Conclusion: AO3.2 binds a dwelling house (or ancillary Class 10a
-- structure) built as part of the SAME development application as a new
-- dwelling/caretaker's-accommodation MCU, but does NOT bind later,
-- genuinely stand-alone Class 10a building work (a shed/carport/garage
-- added to an already-lawful house with no new MCU) -- for that case QDC/
-- QHC governs instead, same as everywhere else building work is Accepted.
-- Updates the 3 existing rules' interpretation_notes to state this
-- definitively (resolving the "doubt" they previously recorded); leaves
-- automatable=false since whether a given proposal is genuinely stand-alone
-- vs. MCU-linked remains a fact this tool cannot always know in advance.
-- -----------------------------------------------------------------------
UPDATE rule_versions SET interpretation_notes =
  'Planning benchmark (accepted development subject to requirements / assessable, Table 5.5.21), not a QDC alternative (Table 1.6.1). ''Ancillary structures'' read as Class 10a buildings; Class 10b (pools, fences) not encoded. CONFIRMED 2026-11-13 (resolves prior doubt): Table 5.7.1 (Class 10 building-work assessment table) names only the Character residential zone for code-assessable Class 10a building work -- the Rural zone (Cungulla precinct) is not listed, so stand-alone Class 10a building work there is Accepted development outright and this rule does NOT bind it. AO3.2 only binds a Class 10a structure built as part of the SAME development application as a new dwelling house / caretaker''s accommodation MCU (Table 5.5.21). Not automatable: whether a given proposal is genuinely stand-alone (QDC/QHC governs) or MCU-linked (this rule governs) is a fact this tool cannot always know in advance -- shown for manual review, default assumption for an ordinary retrofit shed/carport/garage is stand-alone (not bound).'
WHERE rule_version_id = 'TCC.C.RURAL_CUNGULLA_FRONT_6M@2025-12-08';

UPDATE rule_versions SET interpretation_notes =
  'A side boundary adjoining a road is classified SECONDARY_FRONTAGE_ROAD. CONFIRMED 2026-11-13: see TCC.C.RURAL_CUNGULLA_FRONT_6M -- AO3.2 does not bind genuinely stand-alone Class 10a building work (Table 5.7.1 makes Rural-zone building work Accepted development outright outside the Character residential zone); it only binds a Class 10a structure built as part of a new dwelling/caretaker''s-accommodation MCU. Not automatable for the same reason.'
WHERE rule_version_id = 'TCC.C.RURAL_CUNGULLA_SIDE_ROAD_3M@2025-12-08';

UPDATE rule_versions SET interpretation_notes =
  'Road-adjoining side boundaries: TCC.C.RURAL_CUNGULLA_SIDE_ROAD_3M. No built-to-boundary concession for Class 10a. CONFIRMED 2026-11-13: see TCC.C.RURAL_CUNGULLA_FRONT_6M -- AO3.2 does not bind genuinely stand-alone Class 10a building work (Table 5.7.1 makes Rural-zone building work Accepted development outright outside the Character residential zone); it only binds a Class 10a structure built as part of a new dwelling/caretaker''s-accommodation MCU. Not automatable for the same reason.'
WHERE rule_version_id = 'TCC.C.RURAL_CUNGULLA_SIDE_REAR_1_5M@2025-12-08';

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 163;

-- -----------------------------------------------------------------------
-- 8. Redland #120 -- LDR1/LDR2 AO6.1 (site cover) is already the only AO
-- under its "a number of the following are alternative provisions"
-- heading note, and RCC.C.LDR1_LDR2_SITE_COVER_30 is already automatable.
-- The research's own reasoning (the sole AO under the heading = YES, it is
-- the alternative provision) is sound and already adopted live; this just
-- ratifies it and closes the issue -- no DB change needed.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 120;

-- -----------------------------------------------------------------------
-- 9. Redland #121 -- same zone-blind-pathway finding as #163 above. Table
-- 5.6.1 (the building-work assessment table) lists only the Low density
-- residential zone (dwelling house/dual occupancy in LDR1-5) with a
-- catch-all "Accepted development: any other building work not listed in
-- this table." The Conservation zone is not listed in Table 5.6.1 at all,
-- so stand-alone Class 10a building work there is Accepted development
-- outright -- QDC/QHC governs, regardless of whether "dwelling house" as a
-- USE is listed in Table 5.4.15 (an MCU table, irrelevant to building
-- work). No rule exists or is needed for the Conservation zone; the
-- dataset's existing silence there is already correct.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 121;

-- -----------------------------------------------------------------------
-- 10. Rockhampton #149 -- ACTUAL FIX. AO3.3 (LDR), AO3.2 (LMDR, HDR) each
-- list "Minimum setbacks... in accordance with the following" as a single
-- flat bullet list for the dual-occupancy development as a whole:
--   - carports and garages: 6 m (LDR) / 4.5 m (LMDR) from all road frontages
--   - building walls: 3 m from all road frontages
--   - verandahs: 1 m from all road frontages
--   - the rear boundary setback is 4 m [no structure type named]
--   - garages/open carports along the side boundary: <= 9 m length
-- The front bullets explicitly type each structure (carports/garages,
-- building walls, verandahs) -- already correctly reflected by
-- RRC.rrc_*_dualocc_front_carport_*m being scoped to CLASS_10A. The rear
-- bullet, by contrast, names no structure type at all: it is the single
-- generic standard for the whole dual-occupancy development, so it covers
-- the development's Class 10a structures (carports/garages/sheds) too, not
-- just the Class 1 dwelling -- the same "untyped bullet = applies to the
-- whole development" reading already used this session for Sunshine
-- Coast's AO2.1(c) (db/055). Extends CLASS_1-only subjects to also include
-- CLASS_10A on all three rear-setback rules.
-- -----------------------------------------------------------------------
INSERT INTO rule_subjects (rule_version_id, structure_type_id, exclude) VALUES
  ('RRC.rrc_ldr_dualocc_rear_4m@2025-03-28', 'CLASS_10A', false),
  ('RRC.rrc_lmdr_dualocc_rear_4m@2025-03-28', 'CLASS_10A', false),
  ('RRC.rrc_hdr_dualocc_rear_4m@2025-03-28', 'CLASS_10A', false);

UPDATE rule_versions SET interpretation_notes =
  'AUTO-IMPORTED (draft). Extracted structure: {"parameter": "rear boundary setback", "operator": ">=", "value": 4, "unit": "m", "conditions": ["dual occupancy only"], "exceptions": ["to a laneway: 1 m at ground storey and 0.5 m above ground level"], "formula_text": null}
Alternative provision to QDC/QHC: YES - Part 1 s1.6 Table 1.6.1: ''Alternative provisions to the QDC MP1.1 and QDC MP1.2 for a class 1 and 10 building or structure'' -> ''Low density residential zone code'' (Sections 32(b), 32(c) and 33 BA and section 10 BR)
RESOLVED 2026-11-13: the rear bullet in AO3.3''s flat setback list names no structure type (unlike the front bullets, which explicitly list carports/garages, building walls, verandahs separately) -- it is the single generic rear standard for the whole dual-occupancy development, so it also covers that development''s Class 10a structures (carports/garages/sheds), not just the Class 1 dwelling. Subjects extended to CLASS_1 + CLASS_10A accordingly (see db/064).'
WHERE rule_version_id = 'RRC.rrc_ldr_dualocc_rear_4m@2025-03-28';

UPDATE rule_versions SET interpretation_notes =
  'AUTO-IMPORTED (draft). Extracted structure: {"parameter": "rear boundary setback", "operator": ">=", "value": 4, "unit": "m", "conditions": ["dual occupancy only"], "exceptions": ["to a laneway: 1 m at ground storey and 0.5 m above ground level"], "formula_text": null}
Alternative provision to QDC/QHC: YES - Part 1 s1.6 Table 1.6.1: ''Alternative provisions to the QDC MP1.1 and QDC MP1.2 for a class 1 and 10 building or structure'' -> ''Low-medium density residential zone code'' (Sections 32(b), 32(c) and 33 BA and section 10 BR)
RESOLVED 2026-11-13: see RRC.rrc_ldr_dualocc_rear_4m (db/064) -- same untyped-bullet reasoning. Subjects extended to CLASS_1 + CLASS_10A.'
WHERE rule_version_id = 'RRC.rrc_lmdr_dualocc_rear_4m@2025-03-28';

UPDATE rule_versions SET interpretation_notes =
  'AUTO-IMPORTED (draft). Extracted structure: {"parameter": "rear boundary setback", "operator": ">=", "value": 4, "unit": "m", "conditions": ["dual occupancy only"], "exceptions": ["to a laneway: 1 m at ground storey and 0.5 m above ground level"], "formula_text": null}
Alternative provision to QDC/QHC: NO - the High density residential zone code is not listed in Part 1 Table 1.6.1 (which names only the Low density residential zone code, Low-medium density residential zone code and Character overlay code as QDC MP1.1/MP1.2 alternative provisions); it operates as a planning (material change of use / operational work) benchmark, not a Building Act s33 boundary clearance
RESOLVED 2026-11-13: see RRC.rrc_ldr_dualocc_rear_4m (db/064) -- same untyped-bullet reasoning. Subjects extended to CLASS_1 + CLASS_10A.'
WHERE rule_version_id = 'RRC.rrc_hdr_dualocc_rear_4m@2025-03-28';

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 149;

-- -----------------------------------------------------------------------
-- 11. Redland #119 -- NEW curated rule. LDR3 (Point Lookout) AO12.1 caps
-- the size of "any single detached building component" at 150 m2 (height
-- <= 4.5 m) or 140 m2 (height > 4.5 m). The research flagged the basis of
-- "size" (GFA vs footprint) as undefined -- CONFIRMED by checking Redland's
-- full adopted definitions set (SC1.2 -> Planning Regulation 2017 sch 4):
-- "setback", "site cover", "building height", "outermost projection",
-- "site", "ground level" and "storey" are all defined there, but "size" and
-- "GFA" are not defined anywhere in the adopted dictionary. Resolved the
-- same way this project already resolves the identical ambiguity elsewhere
-- (Logan's LCC.C.OUTBUILDING_FLOOR_AREA_150, automatable=true): reuse the
-- existing SCHEME_OUTBUILDING_SIZE measurement (subject_geometry
-- CLASS_10A_ROOFED_OR_FLOOR_AREA, "Floor area vs roofed area per provision
-- text"), which is this project's standing convention for exactly this
-- ambiguity -- it does not block automation. Scoped to Class 10a only
-- (sheds/garages/carports), matching this tool's scope; the AO's own
-- "dwelling house" building-component application is outside this tool's
-- scope (it does not re-check an existing dwelling's own construction).
-- -----------------------------------------------------------------------
SELECT define_provision('RCC_CITY_PLAN_2018@2025-11-10', 'Table 6.2.1.3.1, PO12 / AO12.1', 'ACCEPTABLE_OUTCOME',
  $q$PO12 Development takes the form of a series of small scale building components which reduce the overall bulk and obtrusiveness of buildings. AO12.1 The size of any single detached building component does not exceed: (1) 150m2 when the building height is not more than 4.5m above ground level; or (2) 140m2 when the building height is over 4.5m above ground level. Editor's note - This acceptable outcome is an alternative provision for the purposes of the Queensland Development Code. Building works for a dwelling house not complying with this acceptable outcome will require a concurrence agency referral to Council under schedule 9 of the Regulation.$q$,
  'VERIFIED_VERBATIM', 'printed p.126 (PDF p.130)', NULL, NULL, NULL,
  'https://www.redland.qld.gov.au/files/assets/public/v/7/planning-and-development/documents/redland-city-plan-documents/redland-city-plan-version-14/redland-city-plan-version-14-updated-23-september-2026-with-changes-to-sc-5.pdf');

SELECT define_rule($r${
 "rule_id": "RCC.C.LDR3_BUILDING_COMPONENT_SIZE_150", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "OUTBUILDING_SIZE", "title": "LDR3 (Point Lookout): single detached building component <= 150 m2 where height <= 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "value": 150, "unit": "m2",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR3"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "structure_height_m", "op": "<=", "value": 4.5}]],
 "sources": [{"ref": "Table 6.2.1.3.1, PO12 / AO12.1", "role": "PRIMARY"}],
 "interpretation_notes": "''Size'' basis (GFA vs roofed/footprint area) is not defined anywhere in Redland''s adopted dictionary (SC1.2 -> Planning Regulation 2017 sch 4 defines setback, site cover, building height, outermost projection, site, ground level and storey, but not size or GFA) -- resolved the same way as Logan''s identical ambiguity (LCC.C.OUTBUILDING_FLOOR_AREA_150) via the shared SCHEME_OUTBUILDING_SIZE measurement. Editor''s note confirms this AO12.1 is an alternative provision to the QDC for a dwelling house building component; scoped here to Class 10a only (sheds/garages/carports), which is this tool''s scope -- the AO also caps a dwelling house''s own building components, which this tool does not separately re-check.",
 "effective_from": "2025-11-10"}$r$);

SELECT define_rule($r${
 "rule_id": "RCC.C.LDR3_BUILDING_COMPONENT_SIZE_140", "instrument_version": "RCC_CITY_PLAN_2018@2025-11-10",
 "topic": "OUTBUILDING_SIZE", "title": "LDR3 (Point Lookout): single detached building component <= 140 m2 where height > 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "value": 140, "unit": "m2",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "REDLAND"}, {"level": "PRECINCT", "precinct": "RCC:LOW_DENSITY_RESIDENTIAL/LDR3"}],
 "subjects": ["CLASS_10A"],
 "conditions": [[{"fact": "structure_height_m", "op": ">", "value": 4.5}]],
 "sources": [{"ref": "Table 6.2.1.3.1, PO12 / AO12.1", "role": "PRIMARY"}],
 "interpretation_notes": "See RCC.C.LDR3_BUILDING_COMPONENT_SIZE_150 (db/064) -- same ''size'' basis resolution and scope. Applies above the 4.5 m building-height threshold.",
 "effective_from": "2025-11-10"}$r$);

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 119;
