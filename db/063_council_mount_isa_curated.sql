-- =============================================================================
-- Mount Isa: first curated rule(s) for this council (previously zero --
-- only raw/draft provisions existed in db/030_council_mount_isa.sql). Built
-- from research/councils/mount_isa.json, which is itself unusually
-- thorough (the researcher already worked through most of the ambiguity).
--
-- KEY FINDING, resolving open_issues #140 and #141: AO4.1 (road setback)
-- and AO4.2/Table 9.3.6.3 (side/rear setback) of the Residential activities
-- code do NOT reach stand-alone Class 10a building work in ANY zone --
-- confirmed two independent ways, not just the QDC-deferral note:
--   1. s1.6(4) (the scheme's own list of which parts are Building Act s32/33
--      "building assessment provisions") names only "(a) Low density
--      residential zone: assessment of a Class 10A building; (b) Medium
--      density residential zone: assessment of a Class 10A building" --
--      i.e. specifically the Class 10A assessment (PO22/PO23), never AO4.1
--      or AO4.2/Table 9.3.6.3 at all, in any zone.
--   2. Table 5.7.1 (the operative building-work assessment table) sends
--      "Construction of a Class 10a building" in Low density residential,
--      Medium density residential and Township straight to "Residential
--      activities code (PO 22 and PO 23)" ONLY -- it never cites AO4.1/
--      AO4.2 as the benchmark for this pathway. AO4.1/AO4.2 engage only
--      when a residential USE itself is being assessed (a new dwelling
--      house MCU, or other residential activity) -- not stand-alone
--      building work on an already-lawful house, which is this tool's
--      whole scope. (Table 5.7.1 also resolves #141: Township IS included
--      here by the specific, operative table, even though the general
--      s1.6(4) summary list happens to omit it -- specific/operative text
--      governs over a summary index, same principle used project-wide.)
--
-- Consequence: PO22/PO23 set NO side/rear setback at all (confirmed:
-- research's own "absence rule" entry, micc_class10a_bw_side_rear_absent_qdc)
-- and only a narrow front-siting control for garages (AO23.1, below) --
-- so QDC/QHC governs Class 10a height/setback/site-cover in Low density
-- residential, Medium density residential and Township EXCEPT for that one
-- AO23.1 garage control. In every OTHER zone (Local centre, Principal
-- centre, Mixed use, Community facilities, Rural, Rural residential),
-- Table 5.7.1's own text makes Class 10a building work "Accepted
-- development" outright (no scheme requirements at all, subject only to
-- the Major infrastructure/Heritage/Lake Moondarra overlays) -- QDC/QHC
-- governs there entirely too. No Mount Isa-specific rule is needed or
-- written for any of this -- it is the engine's existing, correct default.
--
-- #142 (the "not greater than X, but less than Y" lot-width-band drafting
-- error in Table 9.3.6.3) is consequently IMMATERIAL to this tool: that
-- table is never reached by stand-alone Class 10a work at all (point 2
-- above), so its band-reading ambiguity has no effect on any output here.
-- Not encoded as a rule; noted for provenance only.
--
-- NOT encoded in this pass (logged as a new, separate open issue instead
-- of guessing): AO22.1 (domestic outbuildings max height/floor area),
-- AO23.2 (carports) and AO23.3 (pools forward of the front building line).
-- The research file only paraphrases these in passing while describing
-- AO23.1 ("AO 22.1 (domestic outbuildings max 4.5 m high, 100 m2) out of
-- scope" etc.) -- no verbatim quote or page reference was actually
-- captured for them, unlike AO23.1 below, which has a full verbatim
-- quote and page citation. Encoding specific figures as VERIFIED_VERBATIM
-- active rules from an un-sourced paraphrase would overstate confidence,
-- so these are left for a follow-up pass that re-reads the source PDF
-- directly (pages 279-280 / PDF 289-290, per the research file's own
-- page_or_anchor field).
-- =============================================================================
SET search_path = regs, public;

SELECT define_provision('MICC_PLANNING_SCHEME_2020@2020-03-09', 'Table 9.3.6.1 PO23/AO23.1', 'ACCEPTABLE_OUTCOME',
  $q$PO 23 The design, location and scale of domestic outbuildings and swimming pools do not dominate the road frontage or negatively impact the amenity of adjoining properties. AO 23.1 Garages: (a) are located behind the front building line; or (b) have an opening that does not exceed 6 metres or 60 per cent of the road frontage whichever is less.$q$,
  'VERIFIED_VERBATIM', 'printed p279-280 / PDF p289-290', NULL, NULL, NULL,
  'https://web.archive.org/web/20250407213909id_/https://www.mountisa.qld.gov.au/files/assets/public/v/1/development/documents/city_of_mount_isa_planning_scheme__no_maps_.pdf');

SELECT define_rule($r${
 "rule_id": "MICC.C.LDR_MDR_TWP_GARAGE_FRONT_POSITION", "instrument_version": "MICC_PLANNING_SCHEME_2020@2020-03-09",
 "topic": "GARAGE.FRONTAGE", "title": "Low/Medium density residential, Township: garage behind the front building line, or opening <= lesser of 6 m / 60% of road frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "GARAGE_OPENING_WIDTH_FACING_STREET", "operator": "<=",
 "value": {"op": "min", "args": [6.0, {"op": "*", "args": [0.6, {"var": "road_frontage_m"}]}]}, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MOUNT_ISA"}, {"level": "ZONE", "zone": "MICC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "MICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "MICC:TOWNSHIP"}],
 "subjects": ["GARAGE"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"ref": "Table 9.3.6.1 PO23/AO23.1", "role": "PRIMARY"}],
 "interpretation_notes": "AO23.1 is an (a)-OR-(b) choice: a garage satisfies it either by sitting behind the dwelling's own front building line (a design/as-built fact this engine cannot derive -- no 'front building line' geometry is modelled) OR by keeping its street-facing opening within this width cap (computable from road_frontage_m, shown here). Because limb (a) alone can satisfy the clause with no width limit at all, this rule's figure is informational, not a hard pass/fail -- automatable:false throughout, matching the source research's own needs_manual_review flag. Scope: Table 5.7.1 sends Class 10a building work in these three zones to PO22/PO23 only (see db/063 migration header) -- AO4.1/AO4.2 (Residential activities code setbacks) are not engaged for stand-alone Class 10a work in any zone, so QDC/QHC governs every other siting figure (height, side, rear) here unmodified; this is the one genuine Mount-Isa-specific front-siting control for garages. Does not apply to carports (AO23.2) or sheds -- those are not named in AO23.1's text.",
 "effective_from": "2020-03-09"}$r$);

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (140, 141);

INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES
  ($q$MOUNT_ISA$q$, $q$MICC_PLANNING_SCHEME_2020$q$, 'LOW',
   $q$AO22.1 (domestic outbuildings max height/floor area), AO23.2 (carports) and AO23.3 (pools forward of the front building line) are only paraphrased in passing in the current research (while describing AO23.1), with no verbatim quote or page reference captured for their own text -- unlike AO23.1 (Table 9.3.6.1 PO23/AO23.1, now curated as MICC.C.LDR_MDR_TWP_GARAGE_FRONT_POSITION, db/063). Needs a direct re-read of the source PDF (printed p279-280 / PDF p289-290, per research/councils/mount_isa.json) to capture the actual clause text before encoding height/size figures as active rules.$q$);
