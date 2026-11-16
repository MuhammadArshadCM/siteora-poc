-- =============================================================================
-- Brisbane: BCC.C.TBC_FRONT_SETBACK_AVERAGE (City Plan 2014 8.2.22.3 Table
-- 8.2.22.3 AO1.2) was marked automatable=false because the fact it needs
-- (pre1946_neighbour_avg_front_setback_m -- the average front setback of the
-- nearest pre-1946 houses on the same street) had no input path anywhere: a
-- site/aerial-photo determination of which neighbouring houses are pre-1946
-- is never auto-derivable (confirmed via research 2026-11-05 -- no text
-- schedule, no per-building GIS layer, no building-age dataset exists; BCC's
-- own "Dwelling house character"/"Traditional building character" overlays
-- are area/precinct polygons, not individual building records, and Council
-- publishes a "determining the construction date of a building" practice
-- note precisely because this is done case-by-case, not from a dataset).
--
-- A `--pre1946-setback` CLI flag / `pre1946_setback_m` API input now exists
-- (server-ts/src/core/engine.ts, src/tools/cli.ts, poc/static/index.html) so
-- the figure can be supplied once that determination has actually been made.
-- Flipping automatable to true follows the same pattern already used for
-- QDC11.A1a.FRONTAGE_NEIGHBOURS / QDC12.A1a.ROAD_SETBACK_NEIGHBOURS: the rule
-- still correctly falls back to MANUAL_REVIEW whenever the fact is left
-- blank (resolveWith() returns MANUAL_REVIEW whenever the computed value is
-- UNKNOWN or null, independent of this flag), but is no longer permanently
-- forced to MANUAL_REVIEW once a real figure is entered.
-- =============================================================================
SET search_path = regs, public;

UPDATE rule_versions
SET automatable = true,
    interpretation_notes = interpretation_notes || $q$ Automatable once pre1946_neighbour_avg_front_setback_m is supplied (a site/aerial-photo determination of the nearest pre-1946 houses' setbacks -- never auto-derivable, see research 2026-11-05: no text schedule, no per-building GIS layer, no building-age dataset exists for Brisbane); otherwise still manual review.$q$
WHERE rule_version_id = 'BCC.C.TBC_FRONT_SETBACK_AVERAGE@2026-09-18';
