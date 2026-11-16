import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #138 and #139 (Livingstone): user supplied screenshots of Figures SC10.1.5-SC10.1.8
 * and the full Schedule 10 PDF (v4, adopted 18 Feb 2025).
 *
 * #139 (figures not transcribed) -- reviewed all four against the already-curated db/039 rules:
 *   - Figure SC10.1.5 (corner lot 9x9m truncation, no structure > 2m): a visual aid for text already fully
 *     captured and modelled generically (MP_CORNER_TRUNCATION_9X9-style geometry, same mechanism used
 *     project-wide) -- no new rule needed.
 *   - Figure SC10.1.6 (road setback by lot width, two lines for outermost projection height <=3.5m vs
 *     >=3.501m): this is the ONE genuinely missing figure. Three existing curated rules
 *     (LSC.C.RUR_EC_SMALL_FRONT_6M, LSC.C.LDR_LMDR_TWP_FRONT_6M, LSC.C.MDR_MT_FRONT_6M) each explicitly left
 *     the secondary-road-frontage limb of a corner lot (average depth <=24m) deferring to QDC specifically
 *     because this figure was unavailable. Now transcribed and encoded as three new sibling rules.
 *   - Figure SC10.1.7 (open carport setback dimensions A/B/C/D, D <=15% of perimeter): a visual aid for the
 *     15%-of-perimeter figure already encoded in the three *_OPEN_CARPORT_FRONT rules -- no new rule needed.
 *   - Figure SC10.1.8 (example setbacks for an existing non-complying Rural dwelling): explicitly labelled an
 *     "Example" in its own caption/note, illustrating how extensions to a non-complying dwelling work -- not
 *     itself a numeric standard. No new rule needed.
 *
 * Figure SC10.1.6 transcription: two straight lines, each confidently read from labelled gridline
 * intersections (both start/end points sit exactly on a labelled axis tick): Line (A), outermost projection
 * height <=3.5m: (width 10m, setback 1.5m) to (width 24m, setback 6.0m). Line (B), height >=3.501m: (width
 * 10m, setback 2.0m) to (width 22m, setback 6.0m). Linear between those two points, consistent with how this
 * project already models other two-point figure lines via the "interpolate" op.
 *
 * #138 (Table SC10.1.3 second row, outermost projection height > 10m, not recorded) -- confirmed this was a
 * deliberate, correct scoping decision already made when LSC.C.MDR_MT_FRONT_6M was curated (its own
 * interpretation_notes already say "the > 10m row was not transcribed by the research (not reached by
 * Class 10)") -- a Class 10a shed/garage/carport practically never exceeds 10m outermost projection height,
 * so this row is out of scope for this tool by design, not an oversight. Closing with this confirmation; no
 * rule built.
 */
export class LivingstoneSchedule10FiguresAndSecondRow1700004740000 implements MigrationInterface {
  name = "LivingstoneSchedule10FiguresAndSecondRow1700004740000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, vertical_projection, evaluate_per_part, notes) VALUES
  ('LSC_SCH10_FIG6_SECONDARY_FRONTAGE', 'MIN_HORIZONTAL_DISTANCE', 'PER_SCHEME_DEFINITION', 'BOUNDARY_SECONDARY_FRONTAGE_ROAD', true, false,
   'Schedule 10 Figure SC10.1.6: minimum secondary road frontage setback for a corner lot (average depth <= 24m), as a function of lot width and outermost projection height.');

SELECT define_provision('LSC_PLANNING_SCHEME_2018@2025-05-02', 'Figure SC10.1.6', 'FIGURE',
  $q$Figure SC10.1.6: Road setback for different lot widths. Two lines plot minimum road boundary setback (x-axis, 1.5-6.0m) against width of the lot (y-axis, 10.0-24.0m): Line (A), for a building or structure with an 'outermost projection height' of 3.5 metres or less, runs from (lot width 10.0m, setback 1.5m) to (lot width 24.0m, setback 6.0m). Line (B), for 'outermost projection height' of 3.501 metres or greater, runs from (lot width 10.0m, setback 2.0m) to (lot width 22.0m, setback 6.0m).$q$,
  'VERIFIED_FROM_FIGURE', 'Page SC10-18', NULL, NULL, NULL,
  'https://www.livingstone.qld.gov.au/',
  'Both lines'' start and end points sit exactly on labelled axis gridline intersections (user-supplied screenshot, 2026-11-16) -- read with high confidence; linear between the two points, same "interpolate" device already used elsewhere in this project for two-point figure lines.');

SELECT define_rule($r\${
 "rule_id": "LSC.C.RUR_EC_SMALL_SECONDARY_FIG6_SETBACK", "instrument_version": "LSC_PLANNING_SCHEME_2018@2025-05-02",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Rural / Emerging community lot < 3,000 m2, corner lot <= 24 m deep: secondary road frontage setback per Figure SC10.1.6",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "FIGURE",
 "measurement": "LSC_SCH10_FIG6_SECONDARY_FRONTAGE", "operator": ">=",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 3.5]},
             "then": {"op": "interpolate", "x": {"var": "lot_width_m"}, "points": [[10, 1.5], [24, 6.0]]}}],
           "else": {"op": "interpolate", "x": {"var": "lot_width_m"}, "points": [[10, 2.0], [22, 6.0]]}},
 "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_FROM_FIGURE", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LIVINGSTONE"}, {"level": "ZONE", "zone": "LSC:RURAL"}, {"level": "ZONE", "zone": "LSC:EMERGING_COMMUNITY"}],
 "subjects": ["CLASS_10A", "CLASS_10B"],
 "conditions": [[{"fact": "lot_area_m2", "op": "<", "value": 3000}, {"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "average_lot_depth_m", "op": "<=", "value": 24}, {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"ref": "Figure SC10.1.6", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #139. Fills the gap LSC.C.RUR_EC_SMALL_FRONT_6M''s own interpretation_notes already flagged (secondary frontage on a corner lot <=24m deep deferred to QDC because this figure was unavailable). Line selected by part_height_m (outermost projection height) <=3.5m vs >3.5m; setback interpolated from lot_width_m. Out of range (lot_width_m <10 or >22/24 depending on line) returns no value -- the figure itself does not cover those widths.",
 "effective_from": "2025-05-02"}$r\$);
SELECT alt_overrides('LSC.C.RUR_EC_SMALL_SECONDARY_FIG6_SETBACK@2025-05-02', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Part 1 s1.6(3) and (4)(c), same basis as LSC.C.RUR_EC_SMALL_FRONT_6M -- Rural/Emerging community zone code AO5.1 (Table SC10.1.1) is a building assessment provision; this rule completes its secondary-frontage corner-lot limb via Figure SC10.1.6.');

SELECT define_rule($r\${
 "rule_id": "LSC.C.LDR_LMDR_TWP_SECONDARY_FIG6_SETBACK", "instrument_version": "LSC_PLANNING_SCHEME_2018@2025-05-02",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Low density / Low-medium density residential / Township, corner lot <= 24 m deep: secondary road frontage setback per Figure SC10.1.6",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "FIGURE",
 "measurement": "LSC_SCH10_FIG6_SECONDARY_FRONTAGE", "operator": ">=",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 3.5]},
             "then": {"op": "interpolate", "x": {"var": "lot_width_m"}, "points": [[10, 1.5], [24, 6.0]]}}],
           "else": {"op": "interpolate", "x": {"var": "lot_width_m"}, "points": [[10, 2.0], [22, 6.0]]}},
 "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_FROM_FIGURE", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LIVINGSTONE"}, {"level": "ZONE", "zone": "LSC:LOW_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "LSC:LOW_MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "LSC:TOWNSHIP"}],
 "subjects": ["CLASS_10A", "CLASS_10B"],
 "conditions": [[{"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "average_lot_depth_m", "op": "<=", "value": 24}, {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"ref": "Figure SC10.1.6", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #139. Same reasoning as LSC.C.RUR_EC_SMALL_SECONDARY_FIG6_SETBACK, for Table SC10.1.2.",
 "effective_from": "2025-05-02"}$r\$);
SELECT alt_overrides('LSC.C.LDR_LMDR_TWP_SECONDARY_FIG6_SETBACK@2025-05-02', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Part 1 s1.6(3) and (4)(c), same basis as LSC.C.LDR_LMDR_TWP_FRONT_6M -- completes its secondary-frontage corner-lot limb via Figure SC10.1.6.');

SELECT define_rule($r\${
 "rule_id": "LSC.C.MDR_MT_SECONDARY_FIG6_SETBACK", "instrument_version": "LSC_PLANNING_SCHEME_2018@2025-05-02",
 "topic": "SETBACK.SECONDARY_ROAD", "title": "Medium density residential / Major tourism, corner lot <= 24 m deep, outermost projection height <= 10 m: secondary road frontage setback per Figure SC10.1.6",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "FIGURE",
 "measurement": "LSC_SCH10_FIG6_SECONDARY_FRONTAGE", "operator": ">=",
 "value": {"op": "case", "when": [{"if": {"op": "<=", "args": [{"var": "part_height_m"}, 3.5]},
             "then": {"op": "interpolate", "x": {"var": "lot_width_m"}, "points": [[10, 1.5], [24, 6.0]]}}],
           "else": {"op": "interpolate", "x": {"var": "lot_width_m"}, "points": [[10, 2.0], [22, 6.0]]}},
 "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_FROM_FIGURE", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "LIVINGSTONE"}, {"level": "ZONE", "zone": "LSC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "PRECINCT", "precinct": "LSC:MAJOR_TOURISM/CAPRICORN_INTERNATIONAL_RESORT"}, {"level": "PRECINCT", "precinct": "LSC:MAJOR_TOURISM/GREAT_KEPPEL_ISLAND"}],
 "subjects": ["CLASS_10A", "CLASS_10B"],
 "conditions": [[{"fact": "structure_height_m", "op": "<=", "value": 10}, {"fact": "is_corner_lot", "op": "IS_TRUE"}, {"fact": "average_lot_depth_m", "op": "<=", "value": 24}, {"fact": "boundary_type", "op": "=", "value": "SECONDARY_FRONTAGE_ROAD"}]],
 "sources": [{"ref": "Figure SC10.1.6", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #139. Same reasoning as LSC.C.RUR_EC_SMALL_SECONDARY_FIG6_SETBACK, for Table SC10.1.3's first row (outermost projection height <=10m) -- the >10m second row stays out of scope (see open_issues #138's resolution).",
 "effective_from": "2025-05-02"}$r\$);
SELECT alt_overrides('LSC.C.MDR_MT_SECONDARY_FIG6_SETBACK@2025-05-02', ARRAY['QDC12.A1a.ROAD_SETBACK','QDC11.A1a.FRONTAGE_SETBACK'], 'Part 1 s1.6(3) and (4)(c), same basis as LSC.C.MDR_MT_FRONT_6M -- completes its secondary-frontage corner-lot limb via Figure SC10.1.6.');

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: user supplied screenshots of Figures SC10.1.5-SC10.1.8 and the full Schedule 10 PDF (v4, adopted 18 Feb 2025). Figure SC10.1.5 (corner truncation) and SC10.1.7 (open carport setbacks) are visual aids for text already fully modelled; SC10.1.8 is explicitly an illustrative "Example", not a standard. Figure SC10.1.6 (road setback by lot width and outermost projection height) was the one genuinely missing figure -- transcribed from two confidently-read gridline-anchored lines and encoded as 3 new rules (LSC.C.RUR_EC_SMALL_SECONDARY_FIG6_SETBACK, LSC.C.LDR_LMDR_TWP_SECONDARY_FIG6_SETBACK, LSC.C.MDR_MT_SECONDARY_FIG6_SETBACK), each completing the secondary-road-frontage-on-a-corner-lot limb that the three sibling *_FRONT_6M rules had explicitly deferred to QDC pending this figure.'
WHERE issue_id = 139 AND instrument_id = 'LSC_PLANNING_SCHEME_2018';

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: confirmed this was already a deliberate, correct scoping decision, not an oversight -- LSC.C.MDR_MT_FRONT_6M''s own interpretation_notes (written when it was curated) already state "the > 10m row was not transcribed by the research (not reached by Class 10)". Re-read the full Table SC10.1.3 second row text directly to verify: it sets a graduated setback (road frontage >= 6m + 0.3m per additional metre or part thereof over 10m; side/rear >= 3m + 0.3m per additional metre or part thereof over 10m) for development with an outermost projection height EXCEEDING 10 metres -- a Class 10a shed/garage/carport practically never reaches that height, so this row is correctly out of scope for this tool''s Class 10a focus. No rule built; closing with this confirmation.'
WHERE issue_id = 138 AND instrument_id = 'LSC_PLANNING_SCHEME_2018';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
