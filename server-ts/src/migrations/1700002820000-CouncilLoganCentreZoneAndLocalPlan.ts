import type { MigrationInterface, QueryRunner } from "typeorm";


/**
 * Replays db/052_council_logan_centre_zone_and_local_plan.sql verbatim (ported from the project's hand-applied SQL history, originally db/052_council_logan_centre_zone_and_local_plan.sql in the
 * monorepo; inlined directly here so this migration has no external file dependency). Forward-only: see down().
 */
export class CouncilLoganCentreZoneAndLocalPlan1700002820000 implements MigrationInterface {
  name = "CouncilLoganCentreZoneAndLocalPlan1700002820000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`-- =============================================================================
-- Logan: register the "Centre" zone and "Logan Central" local plan, which were
-- entirely absent from the dataset (only the 7 residential/rural zones were
-- loaded). Found live via 116-118 Wembley Road, Logan Central QLD -> zone
-- "Centre", local plan "Logan Central", local plan precinct "Wembley Road
-- south" all came back from the council's own zoning map but with zone_id =
-- NULL / local_plans = [] in our dataset, so only unmodified QDC/State rules
-- showed, with a "zone unknown" warning.
--
-- Researched 2026-11-05 against Logan Planning Scheme 2015 v9.2 (official
-- PDFs): this needs registration only, NOT new setback/site-cover rules --
-- the pure-QDC MP1.1/1.2 output the engine already produces for a Class 10
-- structure on a Centre-zoned lot is the legally correct answer, because:
--   1. Table 5.7.1 (Tables of assessment - Building work) makes extension of
--      a Dwelling house (incl. ancillary Class 10) accepted development in
--      ALL ZONES under 9.3.2 Dual occupancy and Dwelling house code alone --
--      it does not also cite 6.2.1 Centre zone code (contrast: the Retail
--      activity row in the same table DOES cite 6.2.1). So the Centre zone
--      code's own PO9/AO9 (road clearance) and PO10/AO10 (side/rear, and
--      PO10/AO10 only binds "premises in a residential zone category"
--      anyway) never reach a shed on an existing dwelling house.
--   2. 9.3.2 AO1 (QDC MP1.1 <450m2 / MP1.2 >=450m2) is displaced only by
--      AO3-AO9 where they're engaged; AO4's zone variants are Emerging
--      Community/Rural/Low-medium density residential only, and AO5
--      (side/rear) is scoped to acreage/rural-type zones (or explicitly "no
--      value" for MDR/LMDR) -- Centre is in neither, so AO1/QDC governs.
--   3. "Dwelling house" is not a listed use in the Centre zone's own use
--      table (Table 5.5.1.1) -- establishing a NEW one would be impact
--      assessable as an unlisted use -- but that is irrelevant to Class 10
--      building work on an already-lawful existing house (point 1).
--   4. Logan Central local plan (Table 7.2.4.4.2) sets boundary clearances
--      only for "main streets, active frontage streets and Wembley Road
--      urban boulevard" streetscape/awning design -- a commercial-frontage
--      standard, not a dwelling-house/Class 10 siting standard -- and, per
--      the same local-plan-overrides-zone mechanism already documented for
--      Loganholme/Loganlea (local_plan_mechanism in research/councils/
--      logan.json), a local plan code only binds houses where the
--      development is otherwise assessable, never the zone-blind Table
--      5.7.1 pathway.
-- Sources: Part 6-2-1 Zone code - Centre (LPS v9.2) s6.2.1.3 Table 6.2.1.3.1;
-- Part 5-5 Tables of assessment - Centre zone (LPS v9.2) Table 5.5.1.1;
-- Part 7-2-4 Local plan - Logan Central (LPS v9.2) Table 7.2.4.4.2 and the
-- Wembley Road south / north precinct use lists.
--
-- No local_plan_precincts row is added for "Wembley Road south": Loganholme
-- (the one other local plan loaded for Logan) also has none -- local_plan_
-- precinct_id is only populated where a rule actually scopes to one, and
-- none does here either (see point 4 above).
-- =============================================================================
SET search_path = regs, public;

INSERT INTO zones (zone_id, instrument_id, zone_code, name, regulated_zone_id, dwelling_house_permitted, dwelling_house_basis)
VALUES ($q$LCC:CENTRE$q$, $q$LCC_PLANNING_SCHEME_2015$q$, $q$CENTRE$q$, $q$Centre zone$q$, $q$CENTRE$q$, false,
  $q$Not a listed use in Table 5.5.1.1 (falls to "any other use not listed" -> impact assessment, if establishing a NEW dwelling house). Irrelevant to Class 10 building work on an EXISTING dwelling house, which runs through the zone-blind Table 5.7.1 -> 9.3.2 Dual occupancy and Dwelling house code pathway regardless of zone (confirmed: Table 5.7.1's dwelling-house-extension row cites only 9.3.2, not 6.2.1 Centre zone code) -- pure QDC MP1.1/1.2 (9.3.2 AO1) applies, since neither AO4 (road clearance zone variants: EC/Rural/LMDR only) nor AO5 (side/rear: acreage/rural-type zones only) names Centre.$q$);

INSERT INTO local_plans (local_plan_id, instrument_id, name, plan_type)
VALUES ($q$LCC:LOGAN_CENTRAL$q$, $q$LCC_PLANNING_SCHEME_2015$q$, $q$Logan Central local plan$q$, $q$LOCAL_PLAN$q$);
`);
  }

  public async down(): Promise<void> {
    throw new Error("Irreversible: CouncilLoganCentreZoneAndLocalPlan1700002820000 ports a historical content/schema migration (db/052_council_logan_centre_zone_and_local_plan.sql) with no safe automated rollback. Restore from a backup taken before this migration ran.");
  }
}
