import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/062_ncc_fire_separation_class10a.sql verbatim (ported from the project's hand-applied SQL history, originally db/062_ncc_fire_separation_class10a.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class NccFireSeparationClass10a1700003420000 implements MigrationInterface {
  name = "NccFireSeparationClass10a1700003420000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Add the NCC Housing Provisions fire-separation requirement for Class 10a
-- buildings (open_issues #5): "NCC Housing Provisions fire separation for
-- Class 10a within 900 mm of a boundary or 1.8 m of a Class 1 building not
-- captured (text not held). Construction requirement, not a siting fail."
--
-- Researched 2026-11-13 directly against the ABCB's NCC Online portal (NCC
-- 2022, adopted Housing Provisions, Part 9.2 "Fire separation of external
-- walls") -- confirmed live, no paywall (unlike AS 1926.1-2007, the
-- genuinely-paywalled pool-fencing standard raised separately as the
-- HIGH-severity issue #1 -- the two should not be conflated).
--
-- Deliberately encoded as a STATE-WIDE, council-independent, unconditional
-- REQUIREMENT (no \`scopes\` row at all, same pattern as the MP34 pool-safety
-- rules) rather than as a competing SETBACK number: this is a CONSTRUCTION
-- standard, not a planning siting distance -- it does not reduce or replace
-- any council/QDC/QHC setback, it adds a wall-construction obligation
-- whenever the structure's final built position (whatever the siting rules
-- above determine it to be) ends up within the stated distances. That is
-- exactly why the original researcher correctly flagged it as "not a siting
-- fail" and kept it out of the setback computation -- this rule preserves
-- that separation: it is informational/reminder in nature (role REQUIREMENT,
-- enforceability MANDATORY since it genuinely is one once triggered, but
-- operator IS_TRUE displays as "must hold" prose, same pattern as
-- MP34.P1.BARRIER_REQUIRED, not a number competing with the setback rows).
-- automatable:false throughout, also matching MP34.P1.BARRIER_REQUIRED --
-- whether a specific wall actually triggers this (i.e. ends up that close)
-- is a design/as-built fact this tool cannot know in advance, so it always
-- surfaces for awareness rather than pretending to auto-verify.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO instrument_versions
  (instrument_version_id, instrument_id, version_label, published_date, effective_from, status, source_url, notes)
VALUES
  ('NCC_2022_HOUSING_PROVISIONS@2022-05-01', 'NCC', 'NCC 2022, adopted Housing Provisions (Volume Two equivalent)', '2022-05-01', '2022-05-01', 'ACTIVE',
   'https://ncc.abcb.gov.au/editions/ncc-2022/adopted/housing-provisions/9-fire-safety/part-92-fire-separation-external-walls',
   'Exact Queensland adoption/commencement date for this specific edition not independently confirmed here -- NCC editions are adopted under the Building Act 1975; check the current edition in force if precise commencement matters. Clause numbering (9.2.1-9.2.9) confirmed live against the ABCB NCC Online portal 2026-11-13.');

UPDATE instruments
SET notes = 'Construction requirements incl. fire separation of Class 10a near boundaries/dwellings (Part 9.2, clauses 9.2.1-9.2.9). Text now held: confirmed live against ncc.abcb.gov.au 2026-11-13 (free, not paywalled -- distinct from AS 1926.1-2007, which is).'
WHERE instrument_id = 'NCC';

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, vertical_projection, evaluate_per_part, notes) VALUES
  ('NCC_FIRE_SEPARATION_WALL', 'PRESENCE', 'CLASS_10A_EXTERNAL_WALL', NULL, true, false,
   'Presence of NCC 9.2.3-compliant construction (FRL, masonry veneer or masonry) on a Class 10a wall that ends up within the Part 9.2 trigger distances. Not a horizontal-distance measurement like the SETBACK_* measurements -- this never competes with or replaces a siting setback value. reference_geometry deliberately left NULL (not a "BOUNDARY%" value): this is a whole-structure requirement evaluated once, not per boundary pass -- the engine''s lot-vs-boundary pass filter (evaluate.ts boundaryMeas) keys off that prefix, and a "BOUNDARY_OR_OTHER_BUILDING" value here was found live to wrongly triple the row (once per boundary).');

SELECT define_provision('NCC_2022_HOUSING_PROVISIONS@2022-05-01', '9.2.4(1)(a), 9.2.5', 'ACCEPTABLE_SOLUTION',
  $q$9.2.4(1)(a) The Class 1 building must be protected under 9.2.5 where a Class 10a building is between or adjacent to it and a boundary (other than a boundary adjoining a road alignment or open space). 9.2.5 protection options include: the Class 10a building is not less than 900 mm from the allotment boundary (setback); or, where the Class 10a wall is less than 900 mm from the boundary, that wall complies with 9.2.3.$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL, 'https://ncc.abcb.gov.au/editions/ncc-2022/adopted/housing-provisions/9-fire-safety/part-92-fire-separation-external-walls');
SELECT define_provision('NCC_2022_HOUSING_PROVISIONS@2022-05-01', '9.2.4(1)(b), 9.2.6', 'ACCEPTABLE_SOLUTION',
  $q$9.2.4(1)(b) The Class 1 building must be protected under 9.2.6 where the Class 10a building is between or adjacent to it and another building on the same allotment. 9.2.6 protection options include: the Class 10a building is not less than 1.8 m from the other building (separation); or, where the Class 10a wall is less than 1.8 m from the other building, that wall complies with 9.2.3.$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL, 'https://ncc.abcb.gov.au/editions/ncc-2022/adopted/housing-provisions/9-fire-safety/part-92-fire-separation-external-walls');
SELECT define_provision('NCC_2022_HOUSING_PROVISIONS@2022-05-01', '9.2.3', 'ACCEPTABLE_SOLUTION',
  $q$The wall must commence at the footings or ground slab and extend to the underside of a non-combustible roof covering or non-combustible eaves lining (may stop up to 200 mm short if sealed with a non-combustible fascia, gutter or flashing); and have an FRL of not less than 60/60/60 tested from the outside, OR a masonry veneer wall with external veneer not less than 90 mm thick, OR masonry construction not less than 90 mm thick.$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL, 'https://ncc.abcb.gov.au/editions/ncc-2022/adopted/housing-provisions/9-fire-safety/part-92-fire-separation-external-walls');
SELECT define_provision('NCC_2022_HOUSING_PROVISIONS@2022-05-01', '9.2.8', 'EXEMPTION',
  $q$An open carport meeting the stated conditions (two or more open sides, polycarbonate or non-combustible roof, non-combustible ceiling/wall cladding, no direct vertical support to the Class 1 building) is exempt from 9.2.4(1).$q$,
  'VERIFIED_VERBATIM', NULL, NULL, NULL, NULL, 'https://ncc.abcb.gov.au/editions/ncc-2022/adopted/housing-provisions/9-fire-safety/part-92-fire-separation-external-walls');

SELECT define_rule($r\${
 "rule_id": "NCC.PT9_2.CLASS10A_FIRE_SEPARATION", "instrument_version": "NCC_2022_HOUSING_PROVISIONS@2022-05-01",
 "topic": "CONSTRUCTION.FIRE_SEPARATION", "title": "Class 10a wall within 900 mm of a boundary (not a road) or 1.8 m of another building must be fire-separated construction",
 "role": "REQUIREMENT", "regime": "FIRE_SAFETY", "enforceability": "MANDATORY", "provision_kind": "ACCEPTABLE_SOLUTION",
 "measurement": "NCC_FIRE_SEPARATION_WALL", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "FAIL", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "subjects": ["CLASS_10A"],
 "sources": [
   {"ref": "9.2.4(1)(a), 9.2.5", "role": "PRIMARY", "quote": "The Class 1 building must be protected ... where a Class 10a building is between or adjacent to it and a boundary (other than a boundary adjoining a road alignment or open space) -- protection options include: the Class 10a building is not less than 900 mm from the allotment boundary (setback); or, where the Class 10a wall is less than 900 mm from the boundary, that wall complies with 9.2.3."},
   {"ref": "9.2.4(1)(b), 9.2.6", "role": "PRIMARY", "quote": "The Class 1 building must be protected ... where the Class 10a building is between or adjacent to it and another building on the same allotment -- protection options include: the Class 10a building is not less than 1.8 m from the other building (separation); or, where the Class 10a wall is less than 1.8 m from the other building, that wall complies with 9.2.3."},
   {"ref": "9.2.3", "role": "SUPPLEMENTARY", "quote": "The wall must commence at the footings or ground slab and extend to the underside of a non-combustible roof covering or non-combustible eaves lining (may stop up to 200 mm short if sealed with a non-combustible fascia, gutter or flashing); and have an FRL of not less than 60/60/60 tested from the outside, OR a masonry veneer wall with external veneer not less than 90 mm thick, OR masonry construction not less than 90 mm thick."},
   {"ref": "9.2.8", "role": "SUPPLEMENTARY", "quote": "An open carport meeting the stated conditions (two or more open sides, polycarbonate or non-combustible roof, non-combustible ceiling/wall cladding, no direct vertical support to the Class 1 building) is exempt from 9.2.4(1)."}
 ],
 "interpretation_notes": "Deliberately NOT a siting/setback rule -- it is a construction standard that applies whatever the final built distance turns out to be under the siting rules elsewhere in this report, including where a council/QDC/QHC relaxation already permits 0 m (built-to-boundary). It only bites once the structure is actually sited within 900 mm of a side/rear boundary (never a road boundary) or within 1.8 m of another building on the same allotment (e.g. the house) -- confirm the proposed wall's actual distance and, if within those thresholds, its construction against 9.2.3 (or use the 9.2.8 open-carport exemption). Always surfaced for a Class 10a structure since the tool does not know the final as-sited distance in advance; always MANUAL_REVIEW for the same reason. Does not apply to Class 10b (pools) -- pool fencing is covered separately (QDC MP 3.4, rule family MP34.*).",
 "effective_from": "2022-05-01"}$r$);

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 5;
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: NccFireSeparationClass10a1700003420000 ports a historical content/schema migration (db/062_ncc_fire_separation_class10a.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
