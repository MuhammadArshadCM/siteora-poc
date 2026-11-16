-- =============================================================================
-- First round of resolving blocked_sources (db/067) now that the user has
-- checked several in a browser and supplied documents via research/sources/.
--
--   1. MOUNT_ISA (#144) -- user downloaded the official PDF in-browser and
--      it was moved to research/sources/MOUNT_ISA/. SHA-256 computed here:
--      ca488ad3fb04c260acd7532ca3abf9c59d3ed2a313e45d8b4adc3485e7cd069b,
--      11,823,884 bytes -- an EXACT match to the Internet Archive byte-copy
--      already used to curate every MICC.* rule. This fully resolves #144:
--      the archived copy used for curation was already the correct,
--      current, authoritative text -- nothing to re-verify or change.
--
--   2. BURKE (#124) -- user confirmed in-browser that www.burke.qld.gov.au
--      (the production host, not burkeshire.prelive.opencities.com) is live
--      and serves the same scheme. Resolves #124's open question directly.
--
--   3. SOUTH_BURNETT (#156) -- user confirmed in-browser that Version 2.0
--      (effective 28 Oct 2024) is still the current version. Resolves #156.
--
--   4. MORETON_BAY (#169) -- user supplied the full Version 9 PDF (3,871
--      pages, effective 02/11/2026), moved to research/sources/MORETON_BAY/
--      moreton_bay_planning_scheme_v9.pdf. Read Appendix 2's Table of
--      amendments (verbatim) to find exactly what changed from Version 8
--      (effective 11 Sep 2026) to Version 9 -- the original uncertainty in
--      #169 ("the actual V8-to-V9 changes could not be checked") is now
--      fully resolved: we know precisely what changed. #169 itself is
--      therefore closed, but the changes found are substantive enough to
--      need their own rule-engineering work, not a one-line fix -- logged
--      as two new, more specific open_issues instead of silently dropped
--      (see below).
-- =============================================================================
SET search_path = regs, public;

ALTER TABLE blocked_sources DROP CONSTRAINT blocked_sources_status_check;
ALTER TABLE blocked_sources ADD CONSTRAINT blocked_sources_status_check
  CHECK (status IN ('BLOCKED', 'DOCUMENT_UPLOADED', 'QHC_OPTED_UNBLOCKED', 'CONFIRMED'));

UPDATE blocked_sources SET status = 'DOCUMENT_UPLOADED', uploaded_file_path = 'research/sources/MOUNT_ISA/city_of_mount_isa_planning_scheme__no_maps_.pdf',
  uploaded_at = now(),
  notes = notes || E'\nRESOLVED 2026-11-13: user-supplied browser download verified byte-identical (SHA-256 ca488ad3...069b, 11,823,884 bytes) to the Internet Archive copy already used for curation -- no change needed.'
WHERE blocked_source_id = 1;

UPDATE blocked_sources SET status = 'CONFIRMED',
  notes = notes || E'\nRESOLVED 2026-11-13: user confirmed in-browser that www.burke.qld.gov.au (production host) is live, not the pre-production mirror.'
WHERE blocked_source_id = 2;

UPDATE blocked_sources SET status = 'CONFIRMED',
  notes = notes || E'\nRESOLVED 2026-11-13: user confirmed in-browser that Version 2.0 (eff. 28 Oct 2024) is still the current version.'
WHERE blocked_source_id = 3;

UPDATE blocked_sources SET status = 'DOCUMENT_UPLOADED', uploaded_file_path = 'research/sources/MORETON_BAY/moreton_bay_planning_scheme_v9.pdf',
  uploaded_at = now(),
  notes = notes || E'\nRESOLVED 2026-11-13: user supplied the full Version 9 PDF. Appendix 2''s Table of amendments confirms Version 9 (Major Amendment No.4, adopted 28 Oct 2026, effective 2 Nov 2026) (a) formalises the Morayfield South Emerging Community Area via a new Morayfield South Structure Plan and a full new zone-code section 6.2.3.3 with Parts G-J (developed/developable lot x accepted/assessable), replacing the old TLPI 02/2025-based interim framework this project''s db/049 was built against, and (b) removes the prior exemption for the General residential, Centre, Industry and Township zones from the bushfire-prone-area designation in Table 1.6.1 -- land in those zones now also triggers NCC/AS 3959 bushfire construction requirements where mapped. Both need real rule-engineering review, not a one-line fix -- see open_issues #174 and #175.'
WHERE blocked_source_id = 4;

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (144, 124, 156, 169);

INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES
  ('MORETON_BAY', 'MBRC_PLANNING_SCHEME_2016', 'MEDIUM',
   $q$Version 9 (eff. 2 Nov 2026, Major Amendment No.4) formalises the Morayfield South Emerging Community Area with a new Morayfield South Structure Plan and a full zone-code section 6.2.3.3 (Parts G-J: developed/developable lot x accepted/assessable development), replacing the TLPI 02/2025-based interim framework db/049 was built against. Need to re-read 6.2.3.3 Part G (accepted development, developed lot -- the case this tool mostly serves) for its actual setback/siting figures and reconcile against db/049's existing Morayfield South side/rear/waterbody rules: confirm whether they still apply as-is, need updated figures, or are superseded outright by the new Part G/H/I/J structure.$q$),
  ('MORETON_BAY', 'MBRC_PLANNING_SCHEME_2016', 'MEDIUM',
   $q$Version 9 (eff. 2 Nov 2026, Major Amendment No.4) removes the prior Table 1.6.1 exemption for the General residential, Centre, Industry and Township zones from the bushfire-prone-area designation (Building Act 1975 s32(a), Building Regulation 2021 s7) -- land in those zones mapped as Very high/High/Medium potential bushfire intensity or Potential impact buffer on the Bushfire hazard overlay map now also triggers AS 3959-2018 construction requirements, where it did not before. This is a construction-standard matter (same category as NCC.PT9_2.CLASS10A_FIRE_SEPARATION, db/062), not a siting/setback rule -- consider a similar state-wide-pattern informational REQUIREMENT rule scoped to these 4 Moreton Bay zones, gated on the existing Bushfire hazard overlay layer (poc/site_layers.json already has it configured). Needs the zone list and overlay trigger values confirmed against the live overlay map before building.$q$);
