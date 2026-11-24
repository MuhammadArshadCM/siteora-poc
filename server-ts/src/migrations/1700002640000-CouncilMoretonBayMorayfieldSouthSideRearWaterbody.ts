import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/049_council_moreton_bay_morayfield_south_side_rear_waterbody.sql verbatim (ported from the project's hand-applied SQL history, originally db/049_council_moreton_bay_morayfield_south_side_rear_waterbody.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilMoretonBayMorayfieldSouthSideRearWaterbody1700002640000 implements MigrationInterface {
  name = "CouncilMoretonBayMorayfieldSouthSideRearWaterbody1700002640000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Moreton Bay: finish the Morayfield South / General residential Urban
-- neighbourhood precinct side, rear and trafficable-water-body setbacks
-- (Table 9.3.1.6, docs/fullplan.pdf p.3103) -- the smaller follow-up noted
-- when closing issue #58 (db/048). Front/secondary/outbuilding-frontage for
-- this table were already active (CMB.C.URBAN_*); side, rear and
-- trafficable water body were still sitting as DRAFT.
--
-- Table 9.3.1.6's Side and Rear columns both read "Refer to standard as in
-- QDC" for EVERY wall-height band -- i.e. the scheme itself states no
-- number here, same pattern already confirmed for Rural (issue #65) and
-- Township (issue #67): QDC/QHC governs Class 10a side/rear boundary
-- clearance in this precinct. CMB.mb_dh_t93116_urban_side/_rear are
-- superseded below rather than activated, since there is genuinely nothing
-- scheme-specific to encode (the researcher's own original draft note
-- already reached this same conclusion).
--
-- The Trafficable water body column DOES carry a real number -- Min 4.5m,
-- for every wall height, to OMP/wall/covered car parking/domestic
-- outbuildings -- and was sitting idle as DRAFT despite being a clean,
-- single-value, scheme-specific requirement. Activated below.
-- =============================================================================
SET search_path = regs, public;

INSERT INTO facts (fact_id, type, source, description) VALUES
  ($q$adjoins_trafficable_water_body$q$, 'BOOLEAN', 'PROPERTY_DATA',
   $q$A lot boundary adjoins a trafficable water body (Schedule 1 definition: a body of water ordinarily of sufficient size and depth for use by an occupied, motorised vessel -- includes a canal, lake, river or stream; excludes a dam fully contained within a single lot, wastewater ponds, tailings dams and water bodies where public entry for motorised boating is not permitted).$q$);

SELECT define_rule($r\${
 "rule_id": "CMB.C.URBAN_WATERBODY_SETBACK", "instrument_version": "MBRC_PLANNING_SCHEME_2016@2026-09-11",
 "topic": "SETBACK.WATERWAY", "title": "General residential (Urban neighbourhood) / Emerging community (Transition precinct, Morayfield South urban area): buildings, structures and domestic outbuildings >= 4.5 m from a trafficable water body boundary",
 "role": "REQUIREMENT", "regime": "BUILDING", "enforceability": "DEEMED_TO_COMPLY", "provision_kind": "TABLE",
 "measurement": "SCHEME_SETBACK_WATERWAY", "operator": ">=", "value": 4.5, "unit": "m",
 "on_noncompliance": "REFERRAL_TO_LOCAL_GOVERNMENT", "verification": "VERIFIED_VERBATIM", "automatable": true,
 "scopes": [{"level": "LOCAL_GOVERNMENT", "lg": "MORETON_BAY"},
            {"level": "PRECINCT", "precinct": "CMB:GENERAL_RESIDENTIAL/URBAN_NEIGHBOURHOOD"},
            {"level": "PRECINCT", "precinct": "CMB:EMERGING_COMMUNITY/TRANSITION_DEVELOPED_LOT_MORAYFIELD_SOUTH"}],
 "subjects": ["CLASS_1", "OUTDOOR_STRUCTURE"],
 "conditions": [[{"fact": "adjoins_trafficable_water_body", "op": "IS_TRUE"}]],
 "sources": [{"key": "mb_dh_t93116_urban_waterbody", "role": "PRIMARY",
              "quote": "Table 9.3.1.6 Setbacks ... Trafficable water body: Min 4.5m (all wall-height rows)."}],
 "interpretation_notes": "Applies to all wall heights (the only column in Table 9.3.1.6 with one constant figure across every row). Same 4.5 m figure as Table 9.3.1.3 (Redcliffe Kippa-Ring) and every other Dwelling house code setback table checked -- this appears to be a scheme-wide constant for trafficable water body setback, not specific to this precinct.",
 "effective_from": "2026-09-11"}$r$);
SELECT supersede_draft('CMB.C.URBAN_WATERBODY_SETBACK@2026-09-11', 'CMB.mb_dh_t93116_urban_waterbody');

UPDATE rule_versions SET status = 'SUPERSEDED', interpretation_notes = interpretation_notes ||
  E'\\n\\nRESOLVED 2026-11-03: Table 9.3.1.6''s Side column reads "Refer to standard as in QDC" for every wall-height band -- the scheme itself states no number here. QDC/QHC governs Class 10a side boundary clearance in this precinct, same conclusion as Rural (issue #65) and Township (issue #67). No active rule needed.'
WHERE rule_id = 'CMB.mb_dh_t93116_urban_side' AND status = 'DRAFT';

UPDATE rule_versions SET status = 'SUPERSEDED', interpretation_notes = interpretation_notes ||
  E'\\n\\nRESOLVED 2026-11-03: Table 9.3.1.6''s Rear column reads "Refer to standard as in QDC" for every wall-height band -- the scheme itself states no number here. QDC/QHC governs Class 10a rear boundary clearance in this precinct, same conclusion as Rural (issue #65) and Township (issue #67). No active rule needed.'
WHERE rule_id = 'CMB.mb_dh_t93116_urban_rear' AND status = 'DRAFT';

UPDATE open_issues SET description = description || $q$ FOLLOW-UP COMPLETED 2026-11-03: Trafficable water body setback (Min 4.5m) activated as CMB.C.URBAN_WATERBODY_SETBACK (db/049). Side and rear confirmed to have no scheme-specific number (both read "Refer to standard as in QDC" for every wall-height band in Table 9.3.1.6) -- QDC/QHC governs, same as Rural/Township; superseded rather than left open.$q$
WHERE issue_id = 58 AND lg_id = 'MORETON_BAY';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilMoretonBayMorayfieldSouthSideRearWaterbody1700002640000 ports a historical content/schema migration (db/049_council_moreton_bay_morayfield_south_side_rear_waterbody.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
