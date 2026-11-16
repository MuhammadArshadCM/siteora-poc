-- =============================================================================
-- Rockhampton: resolve open_issues #147 -- Alton Downs precinct AO13.1 (6 m
-- front only) vs Rural zone AO3.1 (20 m all boundaries). Does AO13.1's
-- precinct-precedence note displace the 20 m side/rear setback?
--
-- Resolved NO: AO13.1's own text says "There is no specific setback to any
-- other boundary" -- it only ever varies the FRONT setback and explicitly
-- has nothing to say about side/rear. The precinct-precedence note
-- ("precinct based acceptable outcomes take precedence... where they vary
-- from this code") only has anything to override where the precinct's own
-- AOs actually differ from the zone code -- for side/rear, AO13.1 sets
-- nothing, so there is nothing to take precedence over. RRC.C.RURAL_SIDE_REAR_20M
-- (AO3.1, 20 m) therefore continues to apply unmodified in the Alton Downs
-- precinct, same as everywhere else in the Rural zone.
--
-- Removing the UNRESOLVED relationship between the two rules accordingly --
-- it was never a real OVERRIDES candidate, just an open question, now closed.
-- RRC.C.RURAL_SIDE_REAR_20M remains automatable:false for its own, separate
-- reason (whether "dwelling house" reaches a later stand-alone Class 10a
-- shed) -- untouched here, not part of this issue.
-- =============================================================================
SET search_path = regs, public;

DELETE FROM rule_relationships
WHERE from_rule_version_id = 'RRC.C.ALTON_DOWNS_FRONT_6M@2025-03-28'
  AND to_rule_version_id = 'RRC.C.RURAL_SIDE_REAR_20M@2025-03-28'
  AND type = 'UNRESOLVED';

UPDATE rule_versions
SET interpretation_notes = regexp_replace(interpretation_notes,
    'Side/rear interaction with AO3\.1 is UNRESOLVED\.',
    'RESOLVED 2026-11-12: AO13.1 only varies the front setback and expressly says so ("no specific setback to any other boundary") -- the 20 m side/rear setback (AO3.1 / RRC.C.RURAL_SIDE_REAR_20M) is NOT displaced in this precinct.')
WHERE rule_version_id = 'RRC.C.ALTON_DOWNS_FRONT_6M@2025-03-28';

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 147;
