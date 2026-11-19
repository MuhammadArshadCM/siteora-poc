-- SUPERSEDED — kept for history only. This file was always incomplete (it only ever \i'd db/001-040; it
-- never included db/041-069 at all) and gave no record of what had actually been applied to any given
-- database. Building a fresh database now goes through server-ts/src/migrations/ (TypeORM) instead:
--   cd server-ts && npm run migration:run
-- See README.md's "Database migrations" section for the full story.
--
-- Load the full regulatory dataset into an empty database:
--   psql -d <db> -v ON_ERROR_STOP=1 -f db/load_all.sql      (run from the repository root)
\i db/001_schema.sql
\i db/002_loader.sql
\i db/010_reference_data.sql
\i db/020_state_provisions.sql
\i db/021_state_rules.sql
\i db/030_council_brisbane.sql
\i db/030_council_gold_coast.sql
\i db/030_council_moreton_bay.sql
\i db/030_council_sunshine_coast.sql
\i db/030_council_logan.sql
\i db/030_council_ipswich.sql
\i db/030_council_redland.sql
\i db/030_council_burke.sql
\i db/030_council_central_highlands.sql
\i db/030_council_livingstone.sql
\i db/030_council_mount_isa.sql
\i db/030_council_rockhampton.sql
\i db/030_council_south_burnett.sql
\i db/030_council_toowoomba.sql
\i db/030_council_townsville.sql
\i db/031_council_curated.sql
\i db/032_council_curated_batch2.sql
\i db/033_council_curated_brisbane.sql
\i db/034_council_mapped_heights.sql
\i db/035_council_curated_new_zones.sql
\i db/036_council_curated_remaining_zones.sql
\i db/037_council_curated_mb_general_residential.sql
\i db/038_council_curated_class10_setbacks.sql
\i db/039_council_curated_burke.sql
\i db/039_council_curated_central_highlands.sql
\i db/039_council_curated_livingstone.sql
\i db/039_council_curated_rockhampton.sql
\i db/039_council_curated_south_burnett.sql
\i db/039_council_curated_toowoomba.sql
\i db/039_council_curated_townsville.sql
\i db/040_council_curated_brisbane_dhc_carport.sql
\i db/041_council_brisbane_heritage_flood_pre1911_overlays.sql
\i db/042_council_gold_coast_resolve_stale_issues.sql
\i db/043_council_gold_coast_resolve_more_stale_issues.sql
\i db/044_council_gold_coast_bushfire_overlay_and_issue_cleanup.sql
\i db/045_council_moreton_bay_height_overlay_and_issue_cleanup.sql
\i db/046_council_moreton_bay_version9_and_access_blocker.sql
\i db/047_council_moreton_bay_cross_reference_resolutions.sql
\i db/048_council_moreton_bay_resolve_cross_reference_issues.sql
\i db/049_council_moreton_bay_morayfield_south_side_rear_waterbody.sql
\i db/050_council_south_burnett_street_hierarchy_research_note.sql
\i db/051_council_brisbane_tbc_front_setback_automatable.sql
\i db/052_council_logan_centre_zone_and_local_plan.sql
\i db/053_council_brisbane_withdraw_owner_consent_relaxation.sql
\i db/054_council_brisbane_sherwood_front_setback_average_automatable.sql
\i db/055_council_sunshine_coast_outbuilding_floor_area_resolved.sql
\i db/056_council_brisbane_small_lot_hdr_scope_resolved.sql
\i db/057_resolve_similar_ambiguities_batch.sql
\i db/058_council_brisbane_close_resolved_batch.sql
\i db/059_council_rockhampton_alton_downs_side_rear_resolved.sql
\i db/060_close_verified_stale_batch.sql
\i db/061_resolve_general_legislation_citations.sql
\i db/062_ncc_fire_separation_class10a.sql
\i db/063_council_mount_isa_curated.sql
\i db/064_resolve_research_batch_nov13.sql
\i db/065_resolve_research_batch_round2.sql
\i db/066_resolve_research_batch_round3.sql
\i db/067_blocked_sources.sql
\i db/068_blocked_sources_resolved_round1.sql
\i db/069_moreton_bay_v9_morayfield_and_bushfire.sql
-- load_all.sql stops here by design: every change from this point on (2026-11-13 onward) was made as a
-- TypeORM migration with no backing db/0xx.sql file (server-ts/src/migrations/, timestamps from 1700003900000),
-- including db/070's own fix below, which depends on a rule a migration creates and so cannot replay standalone.
-- `npm run migration:run` against this same state is the only complete, current way to build the database from
-- scratch; this file is a historical snapshot of the pre-migration content only (see db/README.md).
-- Review item 5.3: make regs visible without the schema prefix (takes effect on new connections)
DO $$ BEGIN EXECUTE format('ALTER DATABASE %I SET search_path = regs, public', current_database()); END $$;
SELECT count(*) AS untraceable_rules FROM regs.v_untraceable_rules;
