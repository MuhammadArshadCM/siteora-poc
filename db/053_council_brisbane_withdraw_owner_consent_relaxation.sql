-- =============================================================================
-- Brisbane: withdraw BCC.C.SL_SIDE_ZERO_CONSENT (the AO6(c)(iv) "adjoining
-- owner does not object" 0m side-setback relaxation for non-habitable Class
-- 10A built-to-boundary structures in the Low density residential zone).
--
-- Client Q&A (2026-11-06): asked how the app should handle AO6(c)(iv)'s
-- "registered owner of the adjoining premises does not object" condition.
-- Decision: this has no bearing on our planning-scheme assessment -- it's a
-- private neighbour-consent matter evidenced by a statutory declaration
-- (see Editor's note under AO9.2) and is for the building certifier to
-- collect/verify at lodgement, not something this tool should ask the user
-- about or try to resolve. Ignore it at this stage.
--
-- The underlying fact (adjoining_owner_does_not_object) was never wired into
-- engine.ts/cli.ts/index.html, so this rule could only ever sit at
-- UNKNOWN -> it surfaced as a permanent MANUAL_REVIEW "conditional" 0m
-- candidate for every qualifying lot, which is exactly the confusing
-- behaviour the client flagged. Withdrawing it (rather than leaving it
-- unresolved) removes it from candidacy entirely, so a qualifying lot falls
-- straight back to AO6(a) 1m-habitable / AO6(b) matched-BTB / AO6(c)(i)-(iii)
-- <=300m2-adjoining-lot limbs, whichever actually resolves -- with no
-- dangling manual-review row for a condition the app was never going to be
-- able to ask about anyway.
-- =============================================================================
SET search_path = regs, public;

UPDATE rule_versions
SET status = 'WITHDRAWN'
WHERE rule_version_id = 'BCC.C.SL_SIDE_ZERO_CONSENT@2026-09-18';

INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES
  ($q$BRISBANE$q$, $q$BCC_CITY_PLAN_2014$q$, 'LOW',
   $q$AO6(c)(iv) / AO9.2(b) "adjoining owner does not object" (statutory declaration) withdrawn from automated evaluation by design -- this is a neighbour-consent/building-certifier matter, out of scope for this tool. Rule BCC.C.SL_SIDE_ZERO_CONSENT kept in the dataset (status WITHDRAWN) for provenance/audit but excluded from candidacy.$q$);
