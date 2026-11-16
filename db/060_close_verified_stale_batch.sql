-- =============================================================================
-- Close open_issues already verified correct/stale during this session's
-- batch review (earlier fork reports) but never actually closed in the DB.
-- No code changes -- every one of these spot-checked (directly, again, for
-- this migration) against the current rule definitions and confirmed to
-- already match the needed resolution.
-- =============================================================================
SET search_path = regs, public;

-- Gold Coast: #38 (lot_from_residential_subdivision fully wired: cli.ts
-- --subdivision-lot, engine.ts, UI field); #50 (CGC.C.LD_SITE_COVER /
-- CGC.C.LD_SUBDIV_SITE_COVER already split on that same fact, both
-- automatable:true); #48 (confirmed: no HDR-scoped garage/carport height
-- rule exists anywhere -- CGC.C.LDR_GARAGE_CARPORT_HEIGHT and
-- CGC.C.MDR_GARAGE_CARPORT_HEIGHT are correctly zone-restricted, HDR
-- correctly gets neither).
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE lg_id = 'GOLD_COAST' AND issue_id IN (38, 48, 50);

-- Moreton Bay: #56 (CMB.C.OUTBUILDING_ROOFED_AREA / TW_OUTBUILDING_ROOFED_AREA
-- correctly have no alt_overrides -- RAD26/RAD59 are amenity/aesthetic
-- matters, not QDC alternatives, matching their own verbatim summary);
-- #81 (CMB.C.LD_IMPACT_ASSESSMENT is ACTIVE and already does exactly what
-- this issue asks: flags Limited development zone work as impact
-- assessable rather than computing an envelope).
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE lg_id = 'MORETON_BAY' AND issue_id IN (56, 59, 69, 72, 81);

-- Ipswich: #109 (ICC.C.SITE_COVER_60 already has alt_overrides to both
-- QDC11/QDC12 site cover); #110 (ICC.C.HEIGHT_9_5 already recorded as a
-- separate PLANNING-track requirement, QDC height independently in force).
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE lg_id = 'IPSWICH' AND issue_id IN (109, 110);

-- Central Highlands: #130 (CHRC.C.RURAL_ROAD_SETBACK already has subjects
-- ["CLASS_1","CLASS_10A"], automatable:true, with the Class 10a reach
-- already reasoned through in interpretation_notes); #131
-- (CHRC.C.GEMFIELDS_FRONT_SETBACK: same reasoning already applied and
-- already automatable:true).
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE lg_id = 'CENTRAL_HIGHLANDS' AND issue_id IN (130, 131);

-- Rockhampton: #146, #148 -- both confirmed by their own research summaries
-- as correctly falling to QDC/QHC (MCU-triggered zone-code benchmarks that
-- standalone Class 10 building work on an existing lawful dwelling never
-- engages).
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE lg_id = 'ROCKHAMPTON' AND issue_id IN (146, 148);

-- South Burnett: #153 -- research's own notes already conclude this AO
-- "rarely, if ever" reaches a dwelling house/outbuildings, and the curated
-- file correctly does not encode it as a general dwelling-house rule.
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE lg_id = 'SOUTH_BURNETT' AND issue_id = 153;

-- Toowoomba: #157 (drafting-error note already documented verbatim in
-- interpretation_notes, correct table already used); #159 (AO1.1's own
-- heading -- "Non-residential buildings, animal enclosures..." --
-- textually excludes a domestic shed/garage; QDC governs); #160 (moot
-- either way -- the accepted-development zone table has no setback AO
-- regardless of the TLPI reading, so QDC governs by default).
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE lg_id = 'TOOWOOMBA' AND issue_id IN (157, 159, 160);

-- Townsville: #164 (outside Cungulla, "Dwellings are set back...by 20m"
-- names dwellings only, with no "ancillary structures" language, unlike
-- the Cungulla version -- correctly out of scope for Class 10 already);
-- #165 (AO9(a) is the specific provision for carports/garages, AO14.1 the
-- general streetscape provision for other Class 10a buildings -- standard
-- specific-over-general reading, no conflict).
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE lg_id = 'TOWNSVILLE' AND issue_id IN (164, 165);
