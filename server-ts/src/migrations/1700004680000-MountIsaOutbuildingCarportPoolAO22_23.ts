import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Resolves open_issues #173 (Mount Isa): AO22.1 (domestic outbuildings), AO23.2 (carports) and AO23.3
 * (above-ground pools forward of the front building line) were only paraphrased in passing while db/063
 * curated AO23.1 (garages) -- no verbatim quote or page reference had been captured for their own text. User
 * re-confirmed the source PDF is still available locally (untracked from git for size, not deleted); direct
 * re-read of printed p279-280 / PDF p289-290 (Table 9.3.6.1, City of Mount Isa Planning Scheme, 09 March
 * 2020) gives the actual clause text:
 *
 *   PO22/AO22.1 (printed p279 / PDF p289): "Domestic outbuildings: (a) have a maximum height of 4.5 metres;
 *   and (b) do not exceed 100m2 in size." SC1.3 Table SC1.3.2 defines "domestic outbuilding" as "a shed,
 *   garage or carport" ancillary to a residential use -- so AO22.1 applies to SHED, GARAGE and CARPORT (not
 *   pools, and not the broader DETACHED_LAUNDRY/CLASS_10A_OTHER categories, which the scheme's own definition
 *   does not name).
 *
 *   PO23/AO23.2 (printed p280 / PDF p290): "Carports: (a) have a maximum height of 4.5 metres; and (b) have
 *   an opening that does not exceed 6 metres or 60 per cent of the road frontage whichever lesser; and (c) do
 *   not enclose the side facing the primary road frontage by a door." (a) duplicates AO22.1(a) for carports
 *   specifically (same 4.5m figure, both apply -- not a conflict, just restated); (b) mirrors the already-
 *   curated AO23.1 garage opening-width formula, cumulative here (AND, not an alternative to a position test
 *   the way AO23.1 is for garages); (c) is a new presence-type requirement.
 *
 *   AO23.3 (printed p280 / PDF p290): "Swimming pools (above ground or partially above ground) where located
 *   between the front building line and the road frontage do not exceed 1.5 metres in height." Applies only
 *   to POOL_ABOVEGROUND (the text's own "above ground or partially above ground" limb) -- in-ground pools are
 *   not covered. Gated on boundary_type=PRIMARY_FRONTAGE as the closest available proxy for "between the
 *   front building line and the road frontage" (same limitation already noted for AO23.1's front-building-
 *   line limb -- this engine has no "front building line" geometry).
 *
 * Same scope as the already-curated AO23.1 (Table 5.7.1: Class 10a building work in Low density residential,
 * Medium density residential and Township is assessed against PO22/PO23 only).
 */
export class MountIsaOutbuildingCarportPoolAO22_231700004680000 implements MigrationInterface {
  name = "MountIsaOutbuildingCarportPoolAO22_231700004680000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, vertical_projection, evaluate_per_part, notes) VALUES
  ('MICC_CARPORT_FRONTAGE_SIDE_OPEN', 'PRESENCE', 'CARPORT_PRIMARY_FRONTAGE_SIDE', 'BOUNDARY_ROAD', false, false,
   'Whether the carport side facing the primary road frontage is open (not enclosed by a door) -- AO23.2(c). reference_geometry is boundary-anchored (not because this is a distance measurement, but so the engine attempts it per-boundary, where the boundary_type=PRIMARY_FRONTAGE condition can actually apply -- same device as MEAN_HEIGHT_FACING_BOUNDARY.'),
  ('MICC_POOL_ABOVEGROUND_FRONT_HEIGHT', 'MAX_VERTICAL_HEIGHT', 'POOL_ABOVEGROUND_STRUCTURE', 'BOUNDARY_ROAD', true, false,
   'Height of an above-ground pool sited between the front building line and the road frontage -- AO23.3. Boundary-anchored for the same reason as MICC_CARPORT_FRONTAGE_SIDE_OPEN (lets the engine filter to PRIMARY_FRONTAGE), not because height itself is a distance-to-boundary measurement.');

SELECT define_provision('MICC_PLANNING_SCHEME_2020@2020-03-09', 'Table 9.3.6.1 PO 22 / AO 22.1', 'ACCEPTABLE_OUTCOME',
  $q$PO 22 The design, location and scale of domestic outbuildings retain the residential character of the area and do not negatively impact on the amenity of adjoining properties. | AO 22.1 Domestic outbuildings: (a) have a maximum height of 4.5 metres; and (b) do not exceed 100m2 in size.$q$,
  'VERIFIED_VERBATIM', 'printed p279 / PDF p289', NULL, '9.3.6 Residential activities code', NULL,
  'https://www.mountisa.qld.gov.au/files/assets/public/v/1/development/documents/city_of_mount_isa_planning_scheme__no_maps_.pdf',
  'SC1.3 Table SC1.3.2 defines "domestic outbuilding" as a shed, garage or carport ancillary to a residential use -- AO22.1 applies to all three, not just sheds.');

SELECT define_provision('MICC_PLANNING_SCHEME_2020@2020-03-09', 'Table 9.3.6.1 PO 23 / AO 23.2', 'ACCEPTABLE_OUTCOME',
  $q$PO 23 The design, location and scale of domestic outbuildings and swimming pools do not dominate the road frontage or negatively impact the amenity of adjoining properties. | AO 23.2 Carports: (a) have a maximum height of 4.5 metres; and (b) have an opening that does not exceed 6 metres or 60 per cent of the road frontage whichever lesser; and (c) do not enclose the side facing the primary road frontage by a door.$q$,
  'VERIFIED_VERBATIM', 'printed p280 / PDF p290', NULL, '9.3.6 Residential activities code', NULL,
  'https://www.mountisa.qld.gov.au/files/assets/public/v/1/development/documents/city_of_mount_isa_planning_scheme__no_maps_.pdf',
  'All three limbs are cumulative (AND), unlike AO23.1''s (a)-OR-(b) choice for garages.');

SELECT define_provision('MICC_PLANNING_SCHEME_2020@2020-03-09', 'Table 9.3.6.1 PO 23 / AO 23.3', 'ACCEPTABLE_OUTCOME',
  $q$AO 23.3 Swimming pools (above ground or partially above ground) where located between the front building line and the road frontage do not exceed 1.5 metres in height.$q$,
  'VERIFIED_VERBATIM', 'printed p280 / PDF p290', NULL, '9.3.6 Residential activities code', NULL,
  'https://www.mountisa.qld.gov.au/files/assets/public/v/1/development/documents/city_of_mount_isa_planning_scheme__no_maps_.pdf',
  'Applies only to above-ground/partially-above-ground pools (not in-ground). "Front building line" is not geometry this engine derives -- boundary_type=PRIMARY_FRONTAGE used as the closest proxy, same limitation as AO23.1.');

SELECT define_rule($r\${
 "rule_id": "MICC.C.LDR_MDR_TWP_OUTBUILDING_HEIGHT_4_5", "instrument_version": "MICC_PLANNING_SCHEME_2020@2020-03-09",
 "topic": "OUTBUILDING.HEIGHT", "title": "Low/Medium density residential, Township: domestic outbuilding (shed/garage/carport) max height 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 4.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MOUNT_ISA"}, {"level": "ZONE", "zone": "MICC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "MICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "MICC:TOWNSHIP"}],
 "subjects": ["SHED", "GARAGE", "CARPORT"],
 "sources": [{"ref": "Table 9.3.6.1 PO 22 / AO 22.1", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #173. SC1.3 Table SC1.3.2 defines domestic outbuilding as shed/garage/carport -- applies to all three. Same scope as the existing AO23.1 garage front-position rule (Table 5.7.1 sends Class 10a building work in these three zones to PO22/PO23 only).",
 "effective_from": "2020-03-09"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MICC.C.LDR_MDR_TWP_OUTBUILDING_SIZE_100", "instrument_version": "MICC_PLANNING_SCHEME_2020@2020-03-09",
 "topic": "OUTBUILDING.SIZE", "title": "Low/Medium density residential, Township: domestic outbuilding (shed/garage/carport) max size 100 m2",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_OUTBUILDING_SIZE", "operator": "<=", "value": 100, "unit": "m2",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MOUNT_ISA"}, {"level": "ZONE", "zone": "MICC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "MICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "MICC:TOWNSHIP"}],
 "subjects": ["SHED", "GARAGE", "CARPORT"],
 "sources": [{"ref": "Table 9.3.6.1 PO 22 / AO 22.1", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #173. Same scope reasoning as MICC.C.LDR_MDR_TWP_OUTBUILDING_HEIGHT_4_5.",
 "effective_from": "2020-03-09"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MICC.C.LDR_MDR_TWP_CARPORT_HEIGHT_4_5", "instrument_version": "MICC_PLANNING_SCHEME_2020@2020-03-09",
 "topic": "OUTBUILDING.HEIGHT", "title": "Low/Medium density residential, Township: carport max height 4.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "SCHEME_HEIGHT", "operator": "<=", "value": 4.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MOUNT_ISA"}, {"level": "ZONE", "zone": "MICC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "MICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "MICC:TOWNSHIP"}],
 "subjects": ["CARPORT"],
 "sources": [{"ref": "Table 9.3.6.1 PO 23 / AO 23.2", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #173. Restates MICC.C.LDR_MDR_TWP_OUTBUILDING_HEIGHT_4_5's 4.5m figure specifically for carports (AO23.2(a)) -- not a conflict, the scheme states it twice (once generally in AO22.1, once carport-specifically in AO23.2).",
 "effective_from": "2020-03-09"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MICC.C.LDR_MDR_TWP_CARPORT_FRONT_OPENING", "instrument_version": "MICC_PLANNING_SCHEME_2020@2020-03-09",
 "topic": "GARAGE.FRONTAGE", "title": "Low/Medium density residential, Township: carport opening facing the primary frontage <= lesser of 6 m or 60% of road frontage",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "GARAGE_OPENING_WIDTH_FACING_STREET", "operator": "<=",
 "value": {"op": "min", "args": [6.0, {"op": "*", "args": [0.6, {"var": "road_frontage_m"}]}]}, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MOUNT_ISA"}, {"level": "ZONE", "zone": "MICC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "MICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "MICC:TOWNSHIP"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"ref": "Table 9.3.6.1 PO 23 / AO 23.2", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #173. Same opening-width formula as the already-curated MICC.C.LDR_MDR_TWP_GARAGE_FRONT_POSITION (AO23.1), but mandatory here (AND with (a) and (c)), not an alternative to a position test the way AO23.1 is for garages. automatable=false: matches the garage rule's own reasoning (the formula is computable, but this project keeps this family manual pending a broader automatability review).",
 "effective_from": "2020-03-09"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MICC.C.LDR_MDR_TWP_CARPORT_NO_FRONTAGE_DOOR", "instrument_version": "MICC_PLANNING_SCHEME_2020@2020-03-09",
 "topic": "GARAGE.FRONTAGE", "title": "Low/Medium density residential, Township: carport side facing the primary frontage must not be enclosed by a door",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "MICC_CARPORT_FRONTAGE_SIDE_OPEN", "operator": "IS_TRUE", "value": true,
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MOUNT_ISA"}, {"level": "ZONE", "zone": "MICC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "MICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "MICC:TOWNSHIP"}],
 "subjects": ["CARPORT"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"ref": "Table 9.3.6.1 PO 23 / AO 23.2", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #173 (AO23.2(c)). automatable=false: door presence on a given elevation is a design fact this engine does not collect.",
 "effective_from": "2020-03-09"}$r\$);

SELECT define_rule($r\${
 "rule_id": "MICC.C.LDR_MDR_TWP_POOL_ABOVEGROUND_FRONT_HEIGHT_1_5", "instrument_version": "MICC_PLANNING_SCHEME_2020@2020-03-09",
 "topic": "POOL.HEIGHT", "title": "Low/Medium density residential, Township: above-ground pool forward of the front building line max height 1.5 m",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "ACCEPTABLE_OUTCOME",
 "measurement": "MICC_POOL_ABOVEGROUND_FRONT_HEIGHT", "operator": "<=", "value": 1.5, "unit": "m",
 "on_noncompliance": "PLANNING_APPROVAL_REQUIRED", "verification": "VERIFIED_VERBATIM", "automatable": false,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MOUNT_ISA"}, {"level": "ZONE", "zone": "MICC:LOW_DENSITY_RESIDENTIAL"},
            {"level": "ZONE", "zone": "MICC:MEDIUM_DENSITY_RESIDENTIAL"}, {"level": "ZONE", "zone": "MICC:TOWNSHIP"}],
 "subjects": ["POOL_ABOVEGROUND"],
 "conditions": [[{"fact": "boundary_type", "op": "=", "value": "PRIMARY_FRONTAGE"}]],
 "sources": [{"ref": "Table 9.3.6.1 PO 23 / AO 23.3", "role": "PRIMARY"}],
 "interpretation_notes": "Resolves open_issues #173 (AO23.3). Applies only to above-ground/partially-above-ground pools, not in-ground. boundary_type=PRIMARY_FRONTAGE is a proxy for 'between the front building line and the road frontage' -- this engine has no front-building-line geometry, same limitation already documented on AO23.1. automatable=false accordingly.",
 "effective_from": "2020-03-09"}$r\$);

UPDATE open_issues SET
  resolved_at = '2026-11-16',
  description = 'RESOLVED 2026-11-16: direct re-read of the source PDF (printed p279-280 / PDF p289-290, still held locally though untracked from git for size) captured the actual clause text for AO22.1, AO23.2 and AO23.3, all previously only paraphrased. Encoded as 6 new curated rules: MICC.C.LDR_MDR_TWP_OUTBUILDING_HEIGHT_4_5 and _SIZE_100 (AO22.1, applies to shed/garage/carport per the scheme''s own SC1.3 Table SC1.3.2 definition of "domestic outbuilding"), MICC.C.LDR_MDR_TWP_CARPORT_HEIGHT_4_5 / _FRONT_OPENING / _NO_FRONTAGE_DOOR (AO23.2''s three cumulative carport conditions), and MICC.C.LDR_MDR_TWP_POOL_ABOVEGROUND_FRONT_HEIGHT_1_5 (AO23.3, above-ground pools only). Same scope as the already-curated AO23.1 garage rule (Table 5.7.1: Class 10a building work in Low/Medium density residential and Township is assessed against PO22/PO23 only).'
WHERE issue_id = 173 AND instrument_id = 'MICC_PLANNING_SCHEME_2020';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
