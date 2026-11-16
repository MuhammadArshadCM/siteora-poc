-- =============================================================================
-- Third-pass batch resolution of open_issues via more research, continuing
-- db/064 and db/065's pattern. All 15 issues below are doc-only closes --
-- each was verified directly against regs.rule_conditions / rule_scopes /
-- rule_subjects (not just interpretation_notes prose, per the correction
-- applied after round 2's false positive on Burke #127-#129) and confirmed
-- already correctly implemented. No rule/DB behaviour changes in this file.
-- =============================================================================
SET search_path = regs, public;

-- -----------------------------------------------------------------------
-- Ipswich #107, #111, #113, #114, #115
--
-- #107: ICC.dh_ro2_1_front_setback_default_qdc's "comply with QDC" default
-- limb isn't separately encoded because it produces the identical number
-- to the engine's own QDC/QHC default when no New Suburban/Rural exception
-- applies -- whether that designation is legally an "alternative provision"
-- doesn't change any output.
--
-- #111: confirmed no general outbuilding-specific rule exists beyond the
-- New Suburban garage rules (ICC.C.NEW_SUBURBAN_GARAGE_DOOR_5_5 / _BTB) --
-- matches the issue's own premise that QDC governs elsewhere.
--
-- #113: already a complete, unambiguous statement of fact (Ipswich has no
-- separate Rural Residential zone; its equivalents are documented) --
-- nothing left to decide.
--
-- #114: "Minor building work" (SC1.2) is defined as a GFA increase of an
-- EXISTING building by <=50 m2/5%. The Flood overlay table (OV12, Table
-- 5.9) lists "a Class 10 building" and "Minor building work" as two
-- separate, parallel conditions -- confirming a new stand-alone Class 10a
-- structure is categorically not "minor building work," so Table 5.7.1's
-- preamble (applies to work not meeting that definition) does reach it.
--
-- #115: "Setback" (SC1.2, outermost projection, no exclusions) is the term
-- the scheme's own operative ROs actually use; "boundary clearance" (with
-- architectural/rainwater exclusions) is the parallel QDC/Building Act
-- term. This tool doesn't model feature-level exclusions for any council,
-- so the distinction is immaterial to current output regardless of which
-- one "governs."
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (107, 111, 113, 114, 115);

-- -----------------------------------------------------------------------
-- Moreton Bay #63, #66, #70, #76, #78, #79, #80
--
-- #63: no RR pool-setback rule exists; the draft placeholder
-- mb_rr_rad3_pool_note already documents the deferral to QDC/QHC.
--
-- #66: confirmed no Rural-zone-wide outbuilding size/site-cover rule
-- exists beyond the Hamlet precinct height rule -- absence already
-- correct.
--
-- #70: CMB.C.TW_* and mb_rural_rad3_* rules are built directly from the
-- zone code's own current RAD numbering, not the stale Table 5.7.1
-- editor's-note list -- already "applying the RADs as written," exactly
-- as the issue itself concludes.
--
-- #76: CMB.C.TW_* rules are all scoped PRECINCT = TOWNSHIP_RESIDENTIAL
-- only (confirmed via rule_scopes) -- centre/convenience/industry
-- precincts are already correctly excluded, out of scope as stated.
--
-- #78, #79: CMB.C.LD_IMPACT_ASSESSMENT (ACTIVE, automatable=true) already
-- flags the Limited development zone as always-impact-assessable with no
-- accepted siting envelope -- exactly the conclusion both issues describe.
--
-- #80: the same rule already treats all building work (sheds and pools
-- alike) in that zone as impact-assessable regardless of PO1's GFA/pool
-- wording -- the classification ambiguity can't change the output either
-- way.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (63, 66, 70, 76, 78, 79, 80);

-- -----------------------------------------------------------------------
-- Mount Isa #145 -- zone-blind-pathway / immateriality (same pattern as
-- Townsville #167 below). Table 5.10.1's own text: the Heritage, Lake
-- Moondarra environs and Major infrastructure overlays only change the
-- assessment CATEGORY (accepted -> development application required) --
-- they do not themselves set numeric Class 10 setback figures. Confirmed
-- no MICC rule cites these overlays for a setback value.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 145;

-- -----------------------------------------------------------------------
-- Townsville #167 -- re-verified: confirmed no TCC rule cites Table 5.9
-- overlays for a setback value (no rule_id matches '%5_9%' or '%overlay%')
-- -- nothing left to review, the issue's own stated conclusion holds.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 167;

-- -----------------------------------------------------------------------
-- Rockhampton #151 -- pure methodology note describing how the ePlan rules
-- API was queried (all text retrieved at the single revision date it
-- actually returns). Documents the method used; nothing to action.
-- -----------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 151;
