import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/057_resolve_similar_ambiguities_batch.sql verbatim (ported from the project's hand-applied SQL history, originally db/057_resolve_similar_ambiguities_batch.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class ResolveSimilarAmbiguitiesBatch1700003120000 implements MigrationInterface {
  name = "ResolveSimilarAmbiguitiesBatch1700003120000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Resolve a batch of similar-shaped open issues following the same scrutiny
-- standard as db/055 (Sunshine Coast) and db/056 (Brisbane HDR scope):
-- verbatim text checked, current code state checked, close only where that
-- evidence actually settles it.
-- =============================================================================
SET search_path = regs, public;

-- -----------------------------------------------------------------------------
-- South Burnett #152 (RESOLVABLE NOW): SC1.1's own "Dwelling house" definition
-- is verbatim confirmed (research/councils/south_burnett.json:101): "A
-- residential use of premises involving: (a) 1 dwelling for a single
-- household and any domestic outbuildings associated with the dwelling; ..."
-- -- an explicit statutory inclusion of domestic outbuildings. The six
-- small-lot setback rules already list GARAGE/CARPORT/SHED/DETACHED_LAUNDRY/
-- CLASS_10A_OTHER as subjects; automatable was only false because of this
-- now-settled doubt. Flipping it, LDR and MDR front/side/rear.
-- -----------------------------------------------------------------------------
UPDATE rule_versions
SET automatable = true,
    interpretation_notes = interpretation_notes || $q$ RESOLVED 2026-11-12: SC1.1's "Dwelling house" definition explicitly includes "any domestic outbuildings associated with the dwelling" -- a detached Class 10a outbuilding is reached by "houses" in this clause. Automatable.$q$
WHERE rule_version_id IN (
  'SBRC.C.LDR_SMALL_LOT_FRONT@2024-10-28', 'SBRC.C.LDR_SMALL_LOT_SIDE_1M@2024-10-28', 'SBRC.C.LDR_SMALL_LOT_REAR_6M@2024-10-28',
  'SBRC.C.MDR_SMALL_LOT_FRONT@2024-10-28', 'SBRC.C.MDR_SMALL_LOT_SIDE_1M@2024-10-28', 'SBRC.C.MDR_SMALL_LOT_REAR_6M@2024-10-28'
);

UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 152;

-- -----------------------------------------------------------------------------
-- Gold Coast #25, #52 (already correctly implemented, close):
-- CGC.C.LDR_FRONT_SETBACK / CGC.C.LDR_SIDE_REAR_SETBACK (and the matching
-- MDR/HDR rules built the same way) already scope \`subjects\` to
-- ["CLASS_1","CLASS_10A"] only -- sheds/garages/carports ("buildings")
-- correctly get the zone-code alternative provision, while pools/pergolas/
-- decks ("structures") are correctly excluded and fall to QDC/QHC, exactly
-- as interpretation_notes already states: "Alternative provision for
-- BUILDINGS only (Table 1.5-1); structures (pools, unroofed decks) keep QDC
-- setbacks." The only thing actually missing (the Building Act Schedule 2
-- "building"/"structure" dictionary) isn't loaded in this project and isn't
-- needed here -- the scheme's OWN Table 1.5-1 text already settles buildings
-- vs structures without it. No rule change needed.
-- -----------------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (25, 52);

-- -----------------------------------------------------------------------------
-- Livingstone #134, #137 (STALE, already resolved in code):
-- #134 (Seaspray local plan vs underlying zone): LSC.C.SEASPRAY_* rules'
-- interpretation_notes already states "the local plan code prevails over
-- zone codes (s1.5(d))... the underlying zone of the Seaspray area was not
-- confirmed by the research, which this makes immaterial", AND an explicit
-- OVERRIDES relationship already exists against every zone-based LSC.C
-- setback rule (db/039, the INSERT...JOIN rules block after the Seaspray
-- rule definitions). Already correct.
-- #137 (Yaamba precinct vs Rural zone AO5.1/Schedule 10): LSC.C.YAAMBA_*
-- rules already carry an explicit OVERRIDES relationship against every
-- RUR_EC_SMALL_* rule (db/039), confirmed live in rule_relationships.
-- Already correct.
-- -----------------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id IN (134, 137);

-- -----------------------------------------------------------------------------
-- Livingstone #136 (reverses an earlier "needs curator interpretation" call):
-- LSC.C.SCH10_LOW_STRUCTURE_FRONT_EXEMPT / ..._SIDE_REAR_EXEMPT already have
-- subjects: ["ANY"] and a condition on structure_height_m <= 2 -- there is
-- no pool-specific carve-out needed in Schedule 10's own text (Circumstance
-- (E)/(F): "A building or structure that... does not have an 'outermost
-- projection height' exceeding two (2) metres"), and structure_height_m is
-- already populated for every structure type including pools. Already
-- correctly resolved by the existing general rule; no change needed.
-- -----------------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 136;

-- -----------------------------------------------------------------------------
-- Redland #118 (STALE, already resolved in code): the curated
-- RCC.C.LDR5_CANAL_LAKE_9M (db/031) already has exactly the resolution this
-- issue asks for: subjects ["CLASS_1","CLASS_10A","POOL_ABOVEGROUND",
-- {"id":"POOL_INGROUND","exclude":true}] -- above-ground pools caught,
-- in-ground pools correctly excluded per AO9.1's express carve-out, and
-- unroofed decks (OUTDOOR_STRUCTURE, not listed) correctly left to manual
-- review rather than guessed either way. Pool EQUIPMENT specifically
-- remains a narrower open question (not addressed either way) -- noted
-- separately below rather than folded into this close.
-- -----------------------------------------------------------------------------
UPDATE open_issues SET resolved_at = CURRENT_DATE WHERE issue_id = 118;

INSERT INTO open_issues (lg_id, instrument_id, severity, description) VALUES
  ($q$REDLAND$q$, $q$RCC_CITY_PLAN_2018$q$, 'LOW',
   $q$Narrowed from #118 (now closed): RCC.C.LDR5_CANAL_LAKE_9M correctly resolves pools/roofed structures/unroofed decks, but whether free-standing POOL EQUIPMENT (pumps/filters/heaters) counts as "development...other roofed structures" under AO9.1 is still genuinely unaddressed -- low materiality, not reachable from the text alone.$q$);
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: ResolveSimilarAmbiguitiesBatch1700003120000 ports a historical content/schema migration (db/057_resolve_similar_ambiguities_batch.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
