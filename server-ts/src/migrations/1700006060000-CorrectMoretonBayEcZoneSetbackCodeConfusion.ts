import type { MigrationInterface, QueryRunner } from "typeorm";

/**
 * Corrects a mistake in the previous pass's narrowing of open_issues #62 (migration 1700005880000) and
 * resolves the "Urban neighbourhood sub-precinct figures" question the user asked to chase down.
 *
 * What went wrong: that pass read Table 6.2.3.2.2.3 / 6.2.3.3.3 / 6.2.3.3.4 -- the EC ZONE CODE's (6.2.3)
 * own "Setbacks (Residential uses)" tables -- and treated them as the operative Class 10a/dwelling-house
 * siting standard for a developed lot in this zone. They are not. Re-reading 9.3.1.1 "Application" (the
 * Dwelling house code) confirms it explicitly, separately claims jurisdiction over "development for
 * dwelling houses ... located in ... the Emerging community zone - Transition precinct and Morayfield
 * South precinct (Next generation neighbourhood sub-precinct and Urban neighbourhood sub-precinct) if on a
 * developed lot". This project had ALREADY researched and resolved exactly this zone-code-vs-dwelling-
 * house-code question, as open_issues #58 (already closed 2026-11-03, before this session): Table 9.3.1.5
 * governs Transition precinct (other than Morayfield South), already encoded as ACTIVE rules
 * CMB.C.NEXTGEN_SIDE_NARROW_LOT / CMB.C.NEXTGEN_REAR; Table 9.3.1.6 governs Morayfield South precinct
 * (both the Next generation AND Urban neighbourhood sub-precincts uniformly -- the table does not
 * distinguish them), already encoded as ACTIVE rules CMB.C.URBAN_PRIMARY_FRONTAGE /
 * CMB.C.URBAN_SECONDARY_FRONTAGE / CMB.C.URBAN_WATERBODY_SETBACK for frontage/trafficable-water-body, with
 * Side and Rear confirmed (per #58's own resolution text) to read "Refer to standard as in QDC" for every
 * wall-height band -- no scheme-specific figure exists, QDC/QHC governs directly, and the corresponding
 * draft rules (CMB.mb_dh_t93116_urban_side/_rear) were correctly marked SUPERSEDED rather than built.
 *
 * So there never was a gap here once reading the right code: the "Urban neighbourhood sub-precinct
 * figures" this session set out to chase down are fully, correctly resolved already, by a different
 * (older, already-closed) issue this session had not re-checked before adding new work on top of it. No
 * new rule is built by this migration -- only the open_issues record is corrected to stop pointing at the
 * zone code's own tables as if they were the operative Class 10a standard, since they are not: they may
 * still be the correct benchmark for OTHER residential uses (e.g. Multiple dwelling) under the zone code's
 * own general accepted-development gate, which is outside this project's Class 10a focus.
 */
export class CorrectMoretonBayEcZoneSetbackCodeConfusion1700006060000 implements MigrationInterface {
  name = "CorrectMoretonBayEcZoneSetbackCodeConfusion1700006060000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
SET search_path = regs, public;

UPDATE open_issues SET description =
  'NARROWED 2026-11-18: CORRECTS the previous pass''s 2026-11-17 narrowing, which mistakenly treated the EC ZONE CODE''s (6.2.3) own "Setbacks (Residential uses)" tables (6.2.3.2.2.3 / 6.2.3.3.3 / 6.2.3.3.4) as the operative Class 10a/dwelling-house siting standard for a developed lot. They are not. Section 9.3.1.1 "Application" (the Dwelling house code) explicitly, separately claims jurisdiction over dwelling houses in exactly this zone/precinct/sub-precinct/developed-lot combination -- and this project had ALREADY researched and resolved the zone-code-vs-dwelling-house-code question for this exact area as open_issues #58 (closed 2026-11-03, before this session, and not re-checked before this session added further work on top of it). Table 9.3.1.5 governs the Transition precinct (other than Morayfield South), already encoded as ACTIVE rules CMB.C.NEXTGEN_SIDE_NARROW_LOT / CMB.C.NEXTGEN_REAR. Table 9.3.1.6 governs the Morayfield South precinct''s BOTH sub-precincts uniformly (the table does not distinguish Next generation from Urban neighbourhood) -- confirmed via live rule status: ACTIVE rules CMB.C.URBAN_PRIMARY_FRONTAGE / CMB.C.URBAN_SECONDARY_FRONTAGE / CMB.C.URBAN_WATERBODY_SETBACK cover frontage and trafficable-water-body; Side and Rear were confirmed (per #58''s own resolution) to read "Refer to standard as in QDC" for every wall-height band -- no scheme-specific figure exists there, QDC/QHC governs directly, and the corresponding draft rules (CMB.mb_dh_t93116_urban_side/_rear) are correctly SUPERSEDED rather than built. So the "Urban neighbourhood sub-precinct figures" this session set out to chase down were already fully and correctly resolved -- no new rule needed. The zone code''s own Table 6.2.3.x setback tables may still be the correct benchmark for OTHER residential uses (e.g. Multiple dwelling) under its own general accepted-development gate, but that is outside this project''s Class 10a focus and not pursued further. Genuinely still open, narrowly: the Emerging community zone''s DEVELOPABLE-lot general setback (RAD3/RAD4: 6m road frontage, 4.5m side/rear, confirmed identical across the Interim precinct and both precincts'' developable-lot tables) remains unencoded, since the Dwelling house code does not reach developable lots at all (per its own Application clause) and this project has no fact or precinct distinguishing a developable from a developed lot to safely scope a new zone-wide rule without it double-firing inside the two developed-lot precincts above.'
WHERE issue_id = 62 AND instrument_id = 'MBRC_PLANNING_SCHEME_2016';
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible by convention for this project's migrations — restore from a backup taken before this migration ran.");
  }
}
