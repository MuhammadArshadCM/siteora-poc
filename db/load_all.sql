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
-- Review item 5.3: make regs visible without the schema prefix (takes effect on new connections)
DO $$ BEGIN EXECUTE format('ALTER DATABASE %I SET search_path = regs, public', current_database()); END $$;
SELECT count(*) AS untraceable_rules FROM regs.v_untraceable_rules;
