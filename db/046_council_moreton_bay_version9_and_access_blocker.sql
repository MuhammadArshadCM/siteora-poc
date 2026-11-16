-- =============================================================================
-- Moreton Bay: critical finding from researching issues #57/#58/#65/#67/#68
-- (3 Nov 2026) -- the council's planning scheme has moved to VERSION 9,
-- commenced 2 November 2026, superseding the "Version 8 (11 Sep 2026)" that
-- every CMB.* rule in this project is currently encoded against. This was
-- discovered, not previously known to the project. Raised as its own HIGH
-- issue rather than folded into an existing MEDIUM one, since it potentially
-- affects the validity of the entire Moreton Bay rule set, not one clause.
--
-- Separately: none of the 5 cross-reference conflicts could be read at all --
-- eplan.moretonbay.qld.gov.au returns HTTP 403 to automated fetch (it is a
-- JS-rendered eScheme viewer), and no current-version PDF is published
-- outside it (only a Version 5, Oct 2021 Part 1 PDF was found, confirmed NOT
-- usable as a stand-in -- its own Table 1.6.1 is a different table to the one
-- issue #68 describes, confirming the scheme has been restructured across
-- versions since). Resolving #57/#58/#65/#67/#68 needs either manual eplan
-- access or direct council contact (mbrcplanningscheme@moretonbay.qld.gov.au,
-- published on the council's planning-scheme page) -- noted on each issue
-- below so a future pass does not repeat the same blocked fetch attempts.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES
  ($q$MORETON_BAY$q$, $q$MBRC_PLANNING_SCHEME_2016$q$, 'HIGH',
   $q$The council's planning scheme has moved to Version 9 (commenced 2 November 2026), superseding Version 8 (11 Sep 2026) that every CMB.* rule in this project is currently encoded against (discovered 3 Nov 2026 while researching issues #57/#58/#65/#67/#68). eplan.moretonbay.qld.gov.au returns HTTP 403 to automated fetch, so the actual V8-to-V9 changes could not be checked. The entire Moreton Bay rule set should be treated as one scheme version behind until re-verified against V9 -- flag to the client before relying on any Moreton Bay output for a live assessment.$q$);

UPDATE open_issues
SET description = description || $q$ ACCESS BLOCKED 2026-11-03: eplan.moretonbay.qld.gov.au returns HTTP 403 to automated fetch and no current-version PDF of this material is published outside it (only a Version 5, Oct 2021 Part 1 PDF exists, confirmed not usable here -- the scheme has been restructured since). Also now superseded by Version 9 (see the new HIGH issue on V8->V9). Resolving this needs manual eplan access or direct council contact (mbrcplanningscheme@moretonbay.qld.gov.au).$q$
WHERE issue_id IN (57, 58, 65, 67, 68) AND lg_id = 'MORETON_BAY' AND resolved_at IS NULL;
