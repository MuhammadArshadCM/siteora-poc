-- CHANGE SET 001 — APPROVED 2026-10-22 AND IMPLEMENTED IN db/032_council_curated_batch2.sql (the two rules' "sources"
-- lists now carry the SUPPLEMENTARY entries). DO NOT RUN THIS FILE against a database loaded from the current db/:
-- the rows already exist and the INSERTs would fail on the primary key. Kept as the record of the reviewed change.
--
-- (Original proposal follows.) Review, then apply in a transaction (see bottom for rollback).
-- Council: LOGAN only (LCC_PLANNING_SCHEME_2015@2025-07-01). Issues: validation_issues.csv CLASSIFICATION_TEXT_SUSPECT x2.
--
-- Problem: two ACTIVE curated rules cite as PRIMARY source a provision that is only a fragment of the clause:
--   LCC.C.SIDE_REAR_10M_RURAL          -> 'Table 9.3.2.3.1 PO5/AO5(b)'  text: "b. 10 metres in the: i. Environmental management ..."
--   LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M -> 'Table 9.3.2.3.2 (via AO7.1(b)(i))' text: "Environmental management and conservation zone, Rural zone | 20 metres"
-- The fragments do not themselves say the distance is a side/rear boundary clearance. The lead-in that does is already
-- loaded verbatim (VERIFIED_VERBATIM) in the same scheme version:
--   'Table 9.3.2.3.1 PO5/AO5(a)'          "AO5 A Dual occupancy or Dwelling house has the following minimum side and rear boundary clearances: ..."
--   'Table 9.3.2.3.2 (via AO7.1(b)(i))'   "Table 9.3.2.3.2 - Minimum side and rear boundary clearances for large domestic outbuildings | Zone | ..."
-- Change: add each lead-in as a SUPPLEMENTARY source. No value, scope, classification or status changes.
--
-- Permanent home if approved: append the two INSERTs to db/031_council_curated.sql after the Logan rules (that file is
-- where these rules are defined; a DB-only change would be lost on the next load_all.sql), then reload and run
-- npm run check && npm run verify-load && npm run validate-setbacks.

BEGIN;
SET search_path = regs, public;

-- Backup of the affected rows (rule_sources for the two rules) before the change
CREATE TEMP TABLE backup_001 AS
  SELECT * FROM rule_sources WHERE rule_version_id IN ('LCC.C.SIDE_REAR_10M_RURAL@2025-07-01', 'LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M@2025-07-01');
SELECT * FROM backup_001;

INSERT INTO rule_sources (rule_version_id, provision_id, role, quote)
VALUES ('LCC.C.SIDE_REAR_10M_RURAL@2025-07-01', pk('LCC_PLANNING_SCHEME_2015@2025-07-01', 'dh_ao5a_side_rear_3m'), 'SUPPLEMENTARY',
        'AO5 A Dual occupancy or Dwelling house has the following minimum side and rear boundary clearances:');

INSERT INTO rule_sources (rule_version_id, provision_id, role, quote)
VALUES ('LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M@2025-07-01', pk('LCC_PLANNING_SCHEME_2015@2025-07-01', 'dh_t93232_large_outbuilding_clearance_6m'), 'SUPPLEMENTARY',
        'Table 9.3.2.3.2 - Minimum side and rear boundary clearances for large domestic outbuildings');

-- Expect 2 new rows
SELECT rule_version_id, provision_id, role FROM rule_sources
 WHERE rule_version_id IN ('LCC.C.SIDE_REAR_10M_RURAL@2025-07-01', 'LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M@2025-07-01') ORDER BY 1, 3;

ROLLBACK;   -- change to COMMIT only after review

-- Rollback after a COMMIT:
-- DELETE FROM regs.rule_sources WHERE role = 'SUPPLEMENTARY'
--   AND rule_version_id IN ('LCC.C.SIDE_REAR_10M_RURAL@2025-07-01', 'LCC.C.LARGE_OUTBUILDING_CLEARANCE_20M@2025-07-01');
