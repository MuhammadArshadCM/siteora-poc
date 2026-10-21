-- =============================================================================
-- Loader helpers: rules are authored as JSON documents (see docs/03-schema.md)
-- and normalised into the relational tables by regs.define_rule().
-- =============================================================================
SET search_path = regs, public;

-- Look up a provision; fail loudly if it is missing so a rule can never cite
-- a clause that was not recorded.
CREATE FUNCTION p(iv text, ref text) RETURNS bigint
LANGUAGE plpgsql STABLE AS $$
DECLARE pid bigint;
BEGIN
  SELECT provision_id INTO pid FROM provisions
   WHERE instrument_version_id = iv AND ref_label = ref AND research_key IS NULL;
  IF pid IS NULL THEN
    RAISE EXCEPTION 'provision % / % not found', iv, ref;
  END IF;
  RETURN pid;
END $$;

-- Look up a council provision by the research record it was captured from.
CREATE FUNCTION pk(iv text, rule_key text) RETURNS bigint
LANGUAGE plpgsql STABLE AS $$
DECLARE pid bigint; n int;
BEGIN
  SELECT min(provision_id), count(*) INTO pid, n FROM provisions
   WHERE instrument_version_id = iv AND research_key = rule_key;
  IF n <> 1 THEN
    RAISE EXCEPTION 'provision with key % in % matched % rows', rule_key, iv, n;
  END IF;
  RETURN pid;
END $$;

CREATE FUNCTION define_provision(
  iv text, ref text, kind provision_kind, verbatim text,
  verification verification_status, page_label text DEFAULT NULL,
  pdf_page int DEFAULT NULL, code_name text DEFAULT NULL,
  parent_ref text DEFAULT NULL, url_anchor text DEFAULT NULL, notes text DEFAULT NULL,
  research_key text DEFAULT NULL)
RETURNS bigint LANGUAGE plpgsql AS $$
DECLARE pid bigint;
BEGIN
  INSERT INTO provisions (instrument_version_id, parent_id, kind, ref_label, code_name,
                          page_label, pdf_page, url_anchor, verbatim_text, verification, notes, research_key)
  -- Normalise line endings so stored text is identical to the source whatever the SQL file's line endings.
  VALUES (iv, CASE WHEN parent_ref IS NULL THEN NULL ELSE p(iv, parent_ref) END, kind, ref,
          code_name, page_label, pdf_page, url_anchor, replace(verbatim, chr(13) || chr(10), chr(10)), verification,
          replace(notes, chr(13) || chr(10), chr(10)), research_key)
  RETURNING provision_id INTO pid;
  RETURN pid;
END $$;

-- Rule document format (all keys except those marked optional are required):
-- {
--   "rule_id", "instrument_version", "topic", "title",
--   "role", "regime", "enforceability", "provision_kind",
--   "measurement"?, "operator"?, "value"? (expression AST), "unit"?, "permits_btb"?,
--   "on_noncompliance"?, "effective_from", "effective_to"?,
--   "verification", "automatable",
--   "scopes":     [{"level": "STATE"} | {"level":"ZONE","zone":"..."} | ...],
--   "subjects":   ["CLASS_10A", {"id": "POOL", "exclude": true}],
--   "conditions": [[{"fact","op","value","unit"?}, ...], ...]    -- DNF: OR of ANDs
--   "sources":    [{"ref" | "key", "role", "quote"?, "iv"?}, ...],   -- "key" = research rule key of a council provision
--   "interpretation_notes"?, "notes"?
-- }
CREATE FUNCTION define_rule(doc jsonb) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE
  rv_id text;
  iv text := doc->>'instrument_version';
  s jsonb; grp jsonb; c jsonb; g int := 0;
BEGIN
  INSERT INTO rules (rule_id, instrument_id, topic, title, notes)
  SELECT doc->>'rule_id', instrument_id, doc->>'topic', doc->>'title', doc->>'notes'
    FROM instrument_versions WHERE instrument_version_id = iv
  ON CONFLICT (rule_id) DO NOTHING;
  IF NOT FOUND AND NOT EXISTS (SELECT 1 FROM rules WHERE rule_id = doc->>'rule_id') THEN
    RAISE EXCEPTION 'instrument version % not found for rule %', iv, doc->>'rule_id';
  END IF;

  rv_id := (doc->>'rule_id') || '@' || (doc->>'effective_from');
  INSERT INTO rule_versions (rule_version_id, rule_id, instrument_version_id, role, regime,
      enforceability, provision_kind, measurement_id, operator, value_expr, unit, permits_btb,
      on_noncompliance, effective_from, effective_to, verification, automatable,
      interpretation_notes)
  VALUES (rv_id, doc->>'rule_id', iv, (doc->>'role')::rule_role, (doc->>'regime')::regulatory_regime,
      (doc->>'enforceability')::enforceability, (doc->>'provision_kind')::provision_kind,
      doc->>'measurement', (doc->>'operator')::comparison_op, doc->'value', doc->>'unit',
      coalesce((doc->>'permits_btb')::boolean, false),
      (doc->>'on_noncompliance')::noncompliance_outcome,
      (doc->>'effective_from')::date, (doc->>'effective_to')::date,
      (doc->>'verification')::verification_status, (doc->>'automatable')::boolean,
      doc->>'interpretation_notes');

  FOR s IN SELECT * FROM jsonb_array_elements(coalesce(doc->'scopes', '[{"level":"STATE"}]'))
  LOOP
    INSERT INTO rule_scopes (rule_version_id, level, lg_id, zone_id, precinct_id, overlay_id,
                             local_plan_id, local_plan_precinct_id, exclude)
    VALUES (rv_id, (s->>'level')::scope_level, s->>'lg', s->>'zone', s->>'precinct',
            s->>'overlay', s->>'local_plan', s->>'local_plan_precinct',
            coalesce((s->>'exclude')::boolean, false));
  END LOOP;

  FOR s IN SELECT * FROM jsonb_array_elements(coalesce(doc->'subjects', '[]'))
  LOOP
    INSERT INTO rule_subjects (rule_version_id, structure_type_id, exclude)
    VALUES (rv_id,
            CASE jsonb_typeof(s) WHEN 'string' THEN s #>> '{}' ELSE s->>'id' END,
            CASE jsonb_typeof(s) WHEN 'string' THEN false
                 ELSE coalesce((s->>'exclude')::boolean, false) END);
  END LOOP;

  FOR grp IN SELECT * FROM jsonb_array_elements(coalesce(doc->'conditions', '[]'))
  LOOP
    g := g + 1;
    FOR c IN SELECT * FROM jsonb_array_elements(grp)
    LOOP
      INSERT INTO rule_conditions (rule_version_id, group_no, fact_id, operator, value, unit, notes)
      VALUES (rv_id, g, c->>'fact', (c->>'op')::comparison_op, c->'value', c->>'unit', c->>'notes');
    END LOOP;
  END LOOP;

  FOR s IN SELECT * FROM jsonb_array_elements(doc->'sources')
  LOOP
    INSERT INTO rule_sources (rule_version_id, provision_id, role, quote)
    VALUES (rv_id, CASE WHEN s ? 'key' THEN pk(coalesce(s->>'iv', iv), s->>'key')
                        ELSE p(coalesce(s->>'iv', iv), s->>'ref') END, s->>'role', s->>'quote');
  END LOOP;

  IF NOT EXISTS (SELECT 1 FROM rule_sources WHERE rule_version_id = rv_id AND role = 'PRIMARY') THEN
    RAISE EXCEPTION 'rule % has no PRIMARY source', rv_id;
  END IF;
  RETURN rv_id;
END $$;

CREATE FUNCTION relate(from_rv text, to_rv text, t relationship_type,
                       basis_iv text, basis_ref text, ver verification_status,
                       notes text DEFAULT NULL, cond jsonb DEFAULT NULL,
                       modification jsonb DEFAULT NULL)
RETURNS bigint LANGUAGE sql AS $$
  INSERT INTO rule_relationships (from_rule_version_id, to_rule_version_id, type, modification,
                                  condition_expr, basis_provision_id, verification, notes)
  VALUES (from_rv, to_rv, t, modification, cond,
          CASE WHEN basis_iv IS NULL THEN NULL ELSE p(basis_iv, basis_ref) END, ver, notes)
  RETURNING relationship_id;
$$;

-- Add a boundary_type condition to every condition group of a rule version
-- (used for legacy QDC rules whose text says "road setback" / "side and rear").
CREATE FUNCTION restrict_boundary(rv text, types text[]) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE g int;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM rule_versions WHERE rule_version_id = rv) THEN
    RAISE EXCEPTION 'rule version % not found', rv;
  END IF;
  FOR g IN SELECT DISTINCT group_no FROM rule_conditions WHERE rule_version_id = rv
           UNION SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM rule_conditions WHERE rule_version_id = rv)
  LOOP
    INSERT INTO rule_conditions (rule_version_id, group_no, fact_id, operator, value, notes)
    VALUES (rv, g, 'boundary_type', 'IN', to_jsonb(types), 'Boundary to which the clause applies');
  END LOOP;
END $$;

-- Helper: curated rule replaces its draft.
CREATE FUNCTION supersede_draft(curated_rv text, draft_rule_id text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE d text;
BEGIN
  SELECT rule_version_id INTO d FROM rule_versions WHERE rule_id = draft_rule_id;
  IF d IS NULL THEN RAISE EXCEPTION 'draft % not found', draft_rule_id; END IF;
  UPDATE rule_versions SET status = 'SUPERSEDED' WHERE rule_version_id = d;
  INSERT INTO rule_relationships (from_rule_version_id, to_rule_version_id, type, verification, notes)
  VALUES (curated_rv, d, 'REPLACES', 'VERIFIED_VERBATIM', 'Curated encoding of the same provision.');
END $$;

-- Helper: alternative provision overrides the matching legacy QDC rules.
CREATE FUNCTION alt_overrides(curated_rv text, targets text[], note text) RETURNS void
LANGUAGE sql AS $$
  INSERT INTO rule_relationships (from_rule_version_id, to_rule_id, type, basis_provision_id, verification, notes)
  SELECT curated_rv, t, 'OVERRIDES', p('QLD_BUILDING_ACT_1975@2026-02-01', 's 33'), 'VERIFIED_VERBATIM', note
  FROM unnest(targets) t;
$$;
