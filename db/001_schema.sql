-- =============================================================================
-- Queensland residential siting rules dataset — schema
-- Scope: Class 10a structures and swimming pools (and the Class 1 rules they
-- fall back to) for the regulatory rules engine. Not an application schema.
--
-- Design principles
--   1. Every rule is a versioned row tied to verbatim source provisions.
--   2. Conditions are data (DNF rows), values are a typed expression AST (jsonb).
--      No executable code is stored.
--   3. Precedence is never inferred from "specificity"; it is recorded as
--      explicit, sourced relationships between rule versions.
--   4. Building assessment, planning assessment and pool safety are separate
--      tracks with different legal consequences, and are never merged blindly.
--   5. Unverified data is stored, but flagged so the engine cannot use it for
--      automated PASS/FAIL.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS regs;
SET search_path = regs, public;

-- -----------------------------------------------------------------------------
-- Enumerations
-- -----------------------------------------------------------------------------

CREATE TYPE instrument_kind AS ENUM (
  'ACT', 'REGULATION', 'QDC_MANDATORY_PART', 'QDC_NON_MANDATORY_PART',
  'NCC', 'AUSTRALIAN_STANDARD', 'PLANNING_SCHEME', 'TEMPORARY_LOCAL_PLANNING_INSTRUMENT',
  'LOCAL_PLANNING_POLICY', 'LOCAL_LAW', 'STATE_GUIDELINE', 'COUNCIL_FACTSHEET',
  'PDA_INSTRUMENT', 'OTHER');

-- How much legal weight the document itself has.
CREATE TYPE legal_force AS ENUM (
  'STATUTE',                 -- Act / Regulation
  'STATUTORY_INSTRUMENT',    -- QDC MP, planning scheme: binding when applied
  'ADOPTABLE',               -- QDC NMP: binding only if adopted
  'REFERENCED_STANDARD',     -- AS called up by another instrument
  'GUIDANCE');               -- fact sheets, notes, illustrations

CREATE TYPE regulatory_regime AS ENUM (
  'PLANNING', 'BUILDING', 'POOL_SAFETY', 'FIRE_SAFETY', 'ENVIRONMENTAL',
  'INFRASTRUCTURE', 'OTHER');

CREATE TYPE enforceability AS ENUM (
  'MANDATORY',       -- non-compliance is unlawful / must be met (e.g. pool barrier)
  'DEEMED_TO_COMPLY',-- acceptable solution / acceptable outcome: compliance proves the
                     -- performance criterion; non-compliance is NOT automatically a fail
  'DISCRETIONARY',   -- performance criterion / performance outcome: judgement required
  'ADVISORY',        -- notes, guidance
  'MANUAL_REVIEW');  -- recorded but must always go to a human

CREATE TYPE provision_kind AS ENUM (
  'DEFINITION', 'APPLICATION', 'PERFORMANCE_CRITERIA', 'ACCEPTABLE_SOLUTION',
  'PERFORMANCE_OUTCOME', 'ACCEPTABLE_OUTCOME', 'ACCEPTED_DEVELOPMENT_REQUIREMENT',
  'TABLE', 'TABLE_ROW', 'FIGURE', 'SUPPLEMENTARY_PROVISION', 'EXEMPTION', 'NOTE',
  'SECTION', 'SCHEDULE_ITEM', 'LEVEL_OF_ASSESSMENT', 'OTHER');

-- What happens if the deemed-to-comply value is not met.
CREATE TYPE noncompliance_outcome AS ENUM (
  'FAIL',                          -- mandatory requirement breached
  'REFERRAL_TO_LOCAL_GOVERNMENT',  -- Planning Reg sch 9 pt 3 div 2 table 3
  'REFERRAL_TO_SERVICE_PROVIDER',  -- QDC MP1.4 concurrence
  'PERFORMANCE_SOLUTION_REQUIRED', -- alternative/performance solution path
  'PLANNING_APPROVAL_REQUIRED',    -- development becomes assessable under the scheme
  'ASSESS_AGAINST_PERFORMANCE_OUTCOME',
  'MANUAL_REVIEW');

CREATE TYPE verification_status AS ENUM (
  'VERIFIED_VERBATIM',       -- value read from the official instrument text held/fetched
  'VERIFIED_FROM_FIGURE',    -- value read from an official figure/graph (may be approximate)
  'COUNCIL_FACTSHEET',       -- official but not the legal text
  'SECONDARY_SOURCE_ONLY',   -- found only in non-official sources
  'REFERENCED_STANDARD_NOT_HELD', -- the value lives in an AS we do not hold
  'UNVERIFIED');

CREATE TYPE record_status AS ENUM ('DRAFT', 'ACTIVE', 'SUPERSEDED', 'REPEALED', 'WITHDRAWN');

-- Scope matching (see docs/07): STATE / LOCAL_GOVERNMENT / PLANNING_SCHEME must match;
-- the "place" levels ZONE, PRECINCT, LOCAL_PLAN, LOCAL_PLAN_PRECINCT are alternatives (any
-- include row may match); OVERLAY rows are alternatives among themselves and must also match.
-- Any matching exclude row removes the rule.
CREATE TYPE scope_level AS ENUM (
  'STATE', 'LOCAL_GOVERNMENT', 'PLANNING_SCHEME', 'ZONE', 'PRECINCT', 'OVERLAY',
  'LOCAL_PLAN', 'LOCAL_PLAN_PRECINCT', 'PLAN_OF_DEVELOPMENT', 'SITE');

CREATE TYPE rule_role AS ENUM (
  'REQUIREMENT',    -- states a requirement (min/max/equals/formula)
  'EXEMPTION',      -- removes a requirement when its conditions hold
  'RELAXATION',     -- permits less than the requirement (e.g. BTB permitted)
  'TRIGGER',        -- determines assessment level / referral / which instrument applies
  'DEFINITION_RULE' -- derives a fact (e.g. primary frontage priority order)
);

CREATE TYPE relationship_type AS ENUM (
  'OVERRIDES',      -- source applies instead of target while both are in force
  'REPLACES',       -- source is the successor of target (temporal)
  'MODIFIES',       -- source changes a parameter of target (see modification jsonb)
  'EXEMPTS',        -- source (EXEMPTION) switches target off when its conditions hold
  'RELAXES',        -- source (RELAXATION) allows target's value to be reduced
  'SUPPLEMENTS',    -- both apply; requirement is the conjunction
  'ALTERNATIVE_TO', -- either may be satisfied (e.g. A2(a) or A2(e) for pools)
  'CONDITIONAL_ON', -- source only applies if target applies/is satisfied
  'FALLS_BACK_TO',  -- if source's subject is not listed / exceeds limits, use target
  'DEFINES_TERM_FOR',
  'UNRESOLVED');    -- known ambiguity in how source and target interact: engine must route both to manual review

CREATE TYPE comparison_op AS ENUM ('>=', '>', '<=', '<', '=', '<>', 'IN', 'NOT_IN',
  'BETWEEN', 'IS_TRUE', 'IS_FALSE', 'IS_NULL', 'IS_NOT_NULL');

CREATE TYPE fact_type AS ENUM ('NUMBER', 'BOOLEAN', 'TEXT', 'ENUM', 'DATE', 'GEOMETRY_REF');

CREATE TYPE fact_source AS ENUM ('PROPERTY_DATA', 'PLANNING_DATA', 'DESIGN_INPUT',
  'GEOMETRY_DERIVED', 'USER_DECLARATION', 'ENGINE_DERIVED');

-- -----------------------------------------------------------------------------
-- Authorities, instruments, versions, provisions (source traceability)
-- -----------------------------------------------------------------------------

CREATE TABLE authorities (
  authority_id    text PRIMARY KEY,             -- 'QLD_GOV', 'BCC', 'ABCB', 'SA'
  name            text NOT NULL,
  authority_type  text NOT NULL CHECK (authority_type IN
                    ('STATE_PARLIAMENT','STATE_GOVERNMENT','LOCAL_GOVERNMENT',
                     'NATIONAL_BODY','STANDARDS_BODY','SERVICE_PROVIDER')),
  website         text
);

CREATE TABLE local_governments (
  lg_id           text PRIMARY KEY,             -- 'BRISBANE', 'GOLD_COAST', ...
  authority_id    text NOT NULL REFERENCES authorities,
  official_name   text NOT NULL,
  former_names    text[] NOT NULL DEFAULT '{}',
  abs_lga_code    text,                          -- UNVERIFIED unless noted
  notes           text
);

CREATE TABLE instruments (
  instrument_id   text PRIMARY KEY,             -- 'QLD_BUILDING_ACT_1975', 'QDC_MP_1_2', 'BCC_CITY_PLAN_2014'
  authority_id    text NOT NULL REFERENCES authorities,
  lg_id           text REFERENCES local_governments,  -- set for planning schemes etc.
  kind            instrument_kind NOT NULL,
  force           legal_force NOT NULL,
  title           text NOT NULL,
  short_title     text,
  citation        text,
  notes           text
);

-- One row per published version / reprint / amendment package.
CREATE TABLE instrument_versions (
  instrument_version_id  text PRIMARY KEY,      -- 'QDC_MP_1_2@2010-03-26'
  instrument_id   text NOT NULL REFERENCES instruments,
  version_label   text NOT NULL,                -- 'Version 3.00', 'Current as at 14 August 2026'
  published_date  date,
  effective_from  date,                         -- commencement of this version
  effective_to    date,                         -- day before replacement commenced (NULL = open)
  superseded_by   text REFERENCES instrument_versions,
  status          record_status NOT NULL DEFAULT 'ACTIVE',
  source_url      text,
  local_file      text,                         -- archived copy path
  file_sha256     text,
  retrieved_at    timestamptz,
  verified_at     timestamptz,
  verified_by     text,
  notes           text,
  CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from)
);

-- Clause tree. A rule points at one or more provisions.
CREATE TABLE provisions (
  provision_id    bigserial PRIMARY KEY,
  instrument_version_id text NOT NULL REFERENCES instrument_versions,
  parent_id       bigint REFERENCES provisions,
  kind            provision_kind NOT NULL,
  ref_label       text NOT NULL,                -- 'A2(d)(ii)', 'Table 3 row "Class 10a ... 9m"', 's 33(4)'
  code_name       text,                         -- 'Dwelling house code', 'Chapter 2'
  section         text,
  clause          text,
  subclause       text,
  table_ref       text,
  figure_ref      text,
  page_label      text,                         -- printed page label, e.g. 'Page 47'
  pdf_page        int,
  url_anchor      text,
  verbatim_text   text,                         -- exact text (may be trimmed with '...')
  verification    verification_status NOT NULL DEFAULT 'UNVERIFIED',
  research_key    text,                         -- research record it was captured from (council provisions)
  notes           text
);
CREATE INDEX ON provisions (instrument_version_id);
-- A clause label is unique within a document version, except for council provisions captured
-- per research record (several records can quote the same clause): those are unique by research_key.
CREATE UNIQUE INDEX provisions_ref_uq ON provisions (instrument_version_id, ref_label) WHERE research_key IS NULL;
CREATE UNIQUE INDEX provisions_research_key_uq ON provisions (instrument_version_id, research_key) WHERE research_key IS NOT NULL;

-- Which instrument versions govern which local government over which period.
-- This is where the QHC transition (Building Reg 2021 s106) lives.
CREATE TABLE instrument_applicability (
  applicability_id bigserial PRIMARY KEY,
  instrument_version_id text NOT NULL REFERENCES instrument_versions,
  lg_id           text REFERENCES local_governments,      -- NULL = statewide
  regime          regulatory_regime NOT NULL,
  effective_from  date NOT NULL,
  effective_to    date,                                   -- inclusive end
  end_condition   text,                                   -- e.g. 'earlier of scheme adoption effective day or 2029-08-31'
  basis_provision_id bigint REFERENCES provisions,        -- legal basis for this applicability
  confidence      verification_status NOT NULL,
  notes           text
);
CREATE INDEX ON instrument_applicability (lg_id, regime, effective_from);

-- -----------------------------------------------------------------------------
-- Planning scheme spatial vocabulary (codes only; mapping lives elsewhere)
-- -----------------------------------------------------------------------------

-- Zones a planning scheme may use (Planning Regulation 2017 s6, sch 2).
CREATE TABLE regulated_zones (
  regulated_zone_id text PRIMARY KEY,           -- 'LOW_DENSITY_RESIDENTIAL'
  name            text NOT NULL,                -- 'Low density residential zone'
  category        text NOT NULL,                -- Residential, Centre, Recreation, Environmental, Industry, Tourism, Other
  source_provision_id bigint REFERENCES provisions
);

CREATE TABLE zones (
  zone_id         text PRIMARY KEY,             -- 'BCC:LOW_DENSITY_RESIDENTIAL'
  instrument_id   text NOT NULL REFERENCES instruments,   -- the planning scheme
  zone_code       text NOT NULL,                -- scheme's own code / short name
  name            text NOT NULL,                -- name as the scheme writes it
  regulated_zone_id text REFERENCES regulated_zones,      -- NULL = pre-2017 (QPP-era) zone name
  zone_code_provision_id bigint REFERENCES provisions,     -- the zone code
  dwelling_house_permitted boolean,             -- drives QHC/QDC applicability (QHC s4(2)); NULL = not established
  dwelling_house_basis text,                    -- table of assessment relied on
  valid_from_version text REFERENCES instrument_versions,
  valid_to_version   text REFERENCES instrument_versions,
  notes           text
);

CREATE TABLE precincts (
  precinct_id     text PRIMARY KEY,
  zone_id         text NOT NULL REFERENCES zones,
  name            text NOT NULL,
  notes           text
);

CREATE TABLE overlays (
  overlay_id      text PRIMARY KEY,             -- 'BCC_CP2014:TBC'
  instrument_id   text NOT NULL REFERENCES instruments,
  name            text NOT NULL,
  sub_category    text,
  overlay_code_provision_id bigint REFERENCES provisions,
  is_relevant_overlay boolean,                  -- Planning Reg sch 24 'relevant overlay' (QHC s4(7))
  notes           text
);

CREATE TABLE local_plans (
  local_plan_id   text PRIMARY KEY,
  instrument_id   text NOT NULL REFERENCES instruments,
  name            text NOT NULL,
  plan_type       text NOT NULL CHECK (plan_type IN ('NEIGHBOURHOOD_PLAN','LOCAL_PLAN','PRECINCT_PLAN','STRUCTURE_PLAN')),
  code_provision_id bigint REFERENCES provisions,
  notes           text
);

CREATE TABLE local_plan_precincts (
  local_plan_precinct_id text PRIMARY KEY,      -- 'BCC:NP_NEW_FARM_TENERIFFE/NPP-001'
  local_plan_id   text NOT NULL REFERENCES local_plans,
  name            text NOT NULL,
  notes           text
);

-- -----------------------------------------------------------------------------
-- Subjects: what is being regulated
-- -----------------------------------------------------------------------------

CREATE TABLE building_classifications (
  ncc_class       text PRIMARY KEY,             -- '1a', '10a', '10b'
  description     text NOT NULL,
  source_provision_id bigint REFERENCES provisions
);

-- Hierarchical taxonomy. Rules may target any node; a node inherits its
-- ancestors' rules unless a rule excludes it.
CREATE TABLE structure_types (
  structure_type_id text PRIMARY KEY,           -- 'CLASS_10A', 'SHED', 'CARPORT', 'POOL_INGROUND'
  parent_id       text REFERENCES structure_types,
  name            text NOT NULL,
  ncc_class       text REFERENCES building_classifications,
  is_building     boolean NOT NULL,             -- Building Act 'building' vs 'structure'
  notes           text
);

-- Instrument-specific names mapped to our taxonomy (e.g. QHC "covered outdoor room"
-- includes deck/pergola/porch; MP1.2 "open carport"). Mapping is itself sourced.
CREATE TABLE structure_type_terms (
  term_id         bigserial PRIMARY KEY,
  instrument_id   text NOT NULL REFERENCES instruments,
  term            text NOT NULL,
  structure_type_id text NOT NULL REFERENCES structure_types,
  match_condition jsonb,                        -- e.g. {"fact":"is_roofed","op":"IS_TRUE"}
  definition_provision_id bigint REFERENCES provisions,
  notes           text
);

-- -----------------------------------------------------------------------------
-- Fact vocabulary: the only inputs the expression language may reference
-- -----------------------------------------------------------------------------

CREATE TABLE facts (
  fact_id         text PRIMARY KEY,             -- 'lot_area_m2', 'structure_height_m'
  type            fact_type NOT NULL,
  unit            text,                         -- 'm', 'm2', '%', 'deg', NULL
  allowed_values  text[],                       -- for ENUM
  source          fact_source NOT NULL,
  description     text NOT NULL,
  derivation      text,                         -- how to compute it (PostGIS hint etc.)
  definition_provision_id bigint REFERENCES provisions  -- legal definition it must follow
);

-- -----------------------------------------------------------------------------
-- Measurement definitions (what a numeric requirement is measured on)
-- -----------------------------------------------------------------------------

CREATE TABLE measurements (
  measurement_id  text PRIMARY KEY,             -- 'SETBACK_SIDE_OMP', 'POOL_WATER_EDGE_TO_FRONTAGE'
  measurement_type text NOT NULL CHECK (measurement_type IN (
                    'MIN_HORIZONTAL_DISTANCE',   -- ST_Distance in plan, to vertical projection of boundary
                    'MAX_VERTICAL_HEIGHT',
                    'MEAN_HEIGHT',               -- elevational area / horizontal length
                    'AREA_RATIO',                -- site cover %
                    'AREA',
                    'LENGTH_ALONG_BOUNDARY',     -- aggregate length within a clearance strip
                    'WIDTH',                     -- garage/carport opening width
                    'EXCLUSION_ZONE',            -- nothing over X high inside a polygon (corner truncation)
                    'CLEAR_ZONE',                -- 3D clear volume (MP1.4)
                    'PRESENCE',                  -- barrier exists / continuous
                    'COMPOSITE')),
  subject_geometry   text NOT NULL,             -- 'STRUCTURE_OUTERMOST_PROJECTION', 'EXTERNAL_WALL_FACADE', 'POOL_WATER_EDGE', 'GARAGE_DOOR', 'POOL_BARRIER'
  reference_geometry text,                      -- 'BOUNDARY_SIDE', 'BOUNDARY_REAR', 'BOUNDARY_PRIMARY_FRONTAGE', 'BOUNDARY_SECONDARY_FRONTAGE_ROAD', 'INFRASTRUCTURE_CENTRELINE', 'NATURAL_GROUND'
  boundary_selector  text,                      -- how to pick boundary segments
  vertical_projection boolean NOT NULL DEFAULT true,
  evaluate_per_part  boolean NOT NULL DEFAULT false,  -- requirement varies along the element (height of 'that part')
  postgis_hint    text,
  definition_provision_id bigint REFERENCES provisions,
  notes           text
);

-- -----------------------------------------------------------------------------
-- Rules
-- -----------------------------------------------------------------------------

-- Stable identity of a rule across versions.
CREATE TABLE rules (
  rule_id         text PRIMARY KEY,             -- 'QDC12.A2a.SIDE_REAR_CLEARANCE'
  instrument_id   text NOT NULL REFERENCES instruments,
  topic           text NOT NULL,                -- taxonomy code from docs/02 (e.g. 'SETBACK.SIDE')
  title           text NOT NULL,
  notes           text
);

-- A rule as it stood during a period. Content lives here.
CREATE TABLE rule_versions (
  rule_version_id text PRIMARY KEY,             -- rule_id || '@' || effective_from
  rule_id         text NOT NULL REFERENCES rules,
  instrument_version_id text NOT NULL REFERENCES instrument_versions,
  role            rule_role NOT NULL,
  regime          regulatory_regime NOT NULL,
  enforceability  enforceability NOT NULL,
  provision_kind  provision_kind NOT NULL,
  -- requirement
  measurement_id  text REFERENCES measurements,
  operator        comparison_op,                -- how the measured value is compared to value_expr
  value_expr      jsonb,                        -- expression AST (see docs/03); NULL for EXEMPTION/TRIGGER
  unit            text,
  permits_btb     boolean NOT NULL DEFAULT false, -- 'BTB permitted' (zero setback allowed)
  -- consequences
  on_noncompliance noncompliance_outcome,
  -- temporal
  effective_from  date NOT NULL,
  effective_to    date,
  status          record_status NOT NULL DEFAULT 'ACTIVE',
  -- quality
  verification    verification_status NOT NULL,
  automatable     boolean NOT NULL,             -- false => engine must route to manual review
  interpretation_notes text,                    -- every judgement made converting text to data
  created_at      timestamptz NOT NULL DEFAULT now(),
  CHECK (effective_to IS NULL OR effective_to >= effective_from),
  CHECK (role <> 'REQUIREMENT' OR (measurement_id IS NOT NULL AND operator IS NOT NULL
                                   AND (value_expr IS NOT NULL OR permits_btb))),
  CHECK (verification IN ('VERIFIED_VERBATIM','VERIFIED_FROM_FIGURE') OR NOT automatable)
);
CREATE INDEX ON rule_versions (rule_id, effective_from);

-- Where a rule applies. Several rows = applies in each (OR). No row of a given
-- level = not restricted at that level.
CREATE TABLE rule_scopes (
  rule_version_id text NOT NULL REFERENCES rule_versions ON DELETE CASCADE,
  level           scope_level NOT NULL,
  lg_id           text REFERENCES local_governments,
  zone_id         text REFERENCES zones,
  precinct_id     text REFERENCES precincts,
  overlay_id      text REFERENCES overlays,
  local_plan_id   text REFERENCES local_plans,
  local_plan_precinct_id text REFERENCES local_plan_precincts,
  exclude         boolean NOT NULL DEFAULT false,
  CHECK ((level = 'STATE')
      OR (level = 'LOCAL_GOVERNMENT' AND lg_id IS NOT NULL)
      OR (level = 'PLANNING_SCHEME'  AND lg_id IS NOT NULL)
      OR (level = 'ZONE'      AND zone_id IS NOT NULL)
      OR (level = 'PRECINCT'  AND precinct_id IS NOT NULL)
      OR (level = 'OVERLAY'   AND overlay_id IS NOT NULL)
      OR (level = 'LOCAL_PLAN' AND local_plan_id IS NOT NULL)
      OR (level = 'LOCAL_PLAN_PRECINCT' AND local_plan_precinct_id IS NOT NULL)
      OR (level IN ('PLAN_OF_DEVELOPMENT','SITE')))
);
CREATE INDEX ON rule_scopes (rule_version_id);

-- What it applies to (structure taxonomy, with inheritance).
CREATE TABLE rule_subjects (
  rule_version_id text NOT NULL REFERENCES rule_versions ON DELETE CASCADE,
  structure_type_id text NOT NULL REFERENCES structure_types,
  exclude         boolean NOT NULL DEFAULT false,
  PRIMARY KEY (rule_version_id, structure_type_id)
);

-- Applicability conditions in disjunctive normal form:
-- rule applies if ANY group is satisfied; a group is satisfied if ALL its rows are.
CREATE TABLE rule_conditions (
  condition_id    bigserial PRIMARY KEY,
  rule_version_id text NOT NULL REFERENCES rule_versions ON DELETE CASCADE,
  group_no        int NOT NULL DEFAULT 1,
  fact_id         text NOT NULL REFERENCES facts,
  operator        comparison_op NOT NULL,
  value           jsonb,                        -- scalar, array (IN/BETWEEN) or expression AST
  unit            text,
  source_provision_id bigint REFERENCES provisions,
  notes           text
);
CREATE INDEX ON rule_conditions (rule_version_id);

-- Every rule version must cite at least one PRIMARY provision.
CREATE TABLE rule_sources (
  rule_version_id text NOT NULL REFERENCES rule_versions ON DELETE CASCADE,
  provision_id    bigint NOT NULL REFERENCES provisions,
  role            text NOT NULL CHECK (role IN ('PRIMARY','DEFINITION','SUPPLEMENTARY','LEGAL_BASIS','FIGURE','CONTEXT')),
  quote           text,                         -- the exact words relied on for this rule
  PRIMARY KEY (rule_version_id, provision_id, role)
);

CREATE TABLE rule_relationships (
  relationship_id bigserial PRIMARY KEY,
  from_rule_version_id text NOT NULL REFERENCES rule_versions,
  to_rule_version_id   text REFERENCES rule_versions,
  to_rule_id      text REFERENCES rules,        -- target all versions of a rule
  type            relationship_type NOT NULL,
  modification    jsonb,                        -- for MODIFIES: {"value_expr": ...} or {"delta": ...}
  condition_expr  jsonb,                        -- extra condition on the relationship itself
  basis_provision_id bigint REFERENCES provisions,  -- the legal text that creates the relationship
  verification    verification_status NOT NULL,
  notes           text,
  CHECK (to_rule_version_id IS NOT NULL OR to_rule_id IS NOT NULL)
);

-- Audit of verification events (who checked what, against which copy).
CREATE TABLE verification_log (
  log_id          bigserial PRIMARY KEY,
  rule_version_id text REFERENCES rule_versions,
  provision_id    bigint REFERENCES provisions,
  checked_at      timestamptz NOT NULL DEFAULT now(),
  checked_by      text NOT NULL,
  method          text NOT NULL,                -- 'pdf text extraction', 'figure read', 'web ePlan fetch'
  result          verification_status NOT NULL,
  notes           text
);

-- Open research items that block automation.
CREATE TABLE open_issues (
  issue_id        bigserial PRIMARY KEY,
  lg_id           text REFERENCES local_governments,
  instrument_id   text REFERENCES instruments,
  rule_id         text REFERENCES rules,
  severity        text NOT NULL CHECK (severity IN ('BLOCKER','HIGH','MEDIUM','LOW')),
  description     text NOT NULL,
  raised_at       date NOT NULL DEFAULT current_date,
  resolved_at     date
);

-- -----------------------------------------------------------------------------
-- Convenience views (typed projections the user asked for)
-- -----------------------------------------------------------------------------

CREATE VIEW v_rule_catalogue AS
SELECT rv.rule_version_id, r.rule_id, r.topic, r.title, i.instrument_id, i.title AS instrument,
       iv.version_label, rv.role, rv.regime, rv.enforceability, rv.provision_kind,
       rv.measurement_id, rv.operator, rv.value_expr, rv.unit, rv.permits_btb,
       rv.on_noncompliance, rv.effective_from, rv.effective_to, rv.status,
       rv.verification, rv.automatable,
       (SELECT string_agg(p.ref_label, '; ' ORDER BY p.ref_label)
          FROM rule_sources s JOIN provisions p USING (provision_id)
         WHERE s.rule_version_id = rv.rule_version_id AND s.role = 'PRIMARY') AS primary_clauses,
       iv.source_url
FROM rule_versions rv
JOIN rules r USING (rule_id)
JOIN instrument_versions iv USING (instrument_version_id)
JOIN instruments i ON i.instrument_id = iv.instrument_id;

-- Rules the engine uses (excludes DRAFT and SUPERSEDED).
CREATE VIEW v_active_rules AS
SELECT * FROM v_rule_catalogue WHERE status = 'ACTIVE';

CREATE VIEW v_setback_rules AS
SELECT * FROM v_rule_catalogue WHERE topic LIKE 'SETBACK.%' OR topic LIKE 'SEPARATION.%';
CREATE VIEW v_height_rules AS
SELECT * FROM v_rule_catalogue WHERE topic LIKE 'HEIGHT.%';
CREATE VIEW v_site_coverage_rules AS
SELECT * FROM v_rule_catalogue WHERE topic LIKE 'SITE_COVER%' OR topic LIKE 'LANDSCAPE.%';
CREATE VIEW v_pool_rules AS
SELECT * FROM v_rule_catalogue WHERE topic LIKE 'POOL.%' OR regime = 'POOL_SAFETY';
CREATE VIEW v_rule_exceptions AS
SELECT rr.relationship_id, rr.type, f.rule_version_id AS exception_rule, f.title AS exception_title,
       coalesce(rr.to_rule_version_id, rr.to_rule_id) AS target, rr.notes
FROM rule_relationships rr JOIN v_rule_catalogue f ON f.rule_version_id = rr.from_rule_version_id
WHERE rr.type IN ('EXEMPTS','RELAXES');

-- Integrity check: active rule versions without a primary source (should return 0 rows).
CREATE VIEW v_untraceable_rules AS
SELECT rv.rule_version_id FROM rule_versions rv
WHERE NOT EXISTS (SELECT 1 FROM rule_sources s WHERE s.rule_version_id = rv.rule_version_id AND s.role = 'PRIMARY');
