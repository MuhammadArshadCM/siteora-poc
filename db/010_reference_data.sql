-- =============================================================================
-- Reference data: authorities, local governments, state instruments, subject
-- taxonomy, fact vocabulary, measurement definitions.
-- Council planning-scheme instruments are in db/030_*.sql.
-- =============================================================================
SET search_path = regs, public;

-- -----------------------------------------------------------------------------
-- Authorities and local governments
-- -----------------------------------------------------------------------------
INSERT INTO authorities VALUES
 ('QLD_PARLIAMENT', 'Parliament of Queensland', 'STATE_PARLIAMENT', 'https://www.legislation.qld.gov.au'),
 ('QLD_GOV', 'Queensland Government (Governor in Council / responsible Minister and department)', 'STATE_GOVERNMENT', 'https://www.qld.gov.au'),
 ('ABCB', 'Australian Building Codes Board', 'NATIONAL_BODY', 'https://ncc.abcb.gov.au'),
 ('STANDARDS_AUSTRALIA', 'Standards Australia', 'STANDARDS_BODY', 'https://www.standards.org.au'),
 ('BCC', 'Brisbane City Council', 'LOCAL_GOVERNMENT', 'https://www.brisbane.qld.gov.au'),
 ('CGC', 'City of Gold Coast', 'LOCAL_GOVERNMENT', 'https://www.goldcoast.qld.gov.au'),
 ('CMB', 'City of Moreton Bay', 'LOCAL_GOVERNMENT', 'https://www.moretonbay.qld.gov.au'),
 ('SCC', 'Sunshine Coast Council', 'LOCAL_GOVERNMENT', 'https://www.sunshinecoast.qld.gov.au'),
 ('LCC', 'Logan City Council', 'LOCAL_GOVERNMENT', 'https://www.logan.qld.gov.au'),
 ('ICC', 'Ipswich City Council', 'LOCAL_GOVERNMENT', 'https://www.ipswich.qld.gov.au'),
 ('RCC', 'Redland City Council', 'LOCAL_GOVERNMENT', 'https://www.redland.qld.gov.au');

INSERT INTO local_governments (lg_id, authority_id, official_name, former_names, notes) VALUES
 ('BRISBANE',       'BCC', 'Brisbane City Council', '{}', NULL),
 ('GOLD_COAST',     'CGC', 'Council of the City of Gold Coast', '{}', NULL),
 ('MORETON_BAY',    'CMB', 'City of Moreton Bay', '{"Moreton Bay Regional Council"}', 'Became a city in 2023; planning scheme instruments may still carry the MBRC name.'),
 ('SUNSHINE_COAST', 'SCC', 'Sunshine Coast Regional Council', '{}', NULL),
 ('LOGAN',          'LCC', 'Logan City Council', '{}', NULL),
 ('IPSWICH',        'ICC', 'Ipswich City Council', '{}', NULL),
 ('REDLAND',        'RCC', 'Redland City Council', '{}', NULL);

-- -----------------------------------------------------------------------------
-- State instruments
-- -----------------------------------------------------------------------------
INSERT INTO instruments (instrument_id, authority_id, kind, force, title, short_title, citation, notes) VALUES
 ('QLD_BUILDING_ACT_1975', 'QLD_PARLIAMENT', 'ACT', 'STATUTE', 'Building Act 1975', 'Building Act', 'Act No. 11 of 1975',
  'Creates the building assessment provisions (s30), limits local instruments (s31), alternative provisions (s33), and pool safety (ch 8). There is no separate "Pool Safety Act" in Queensland; pool safety law is Building Act ch 8.'),
 ('QLD_BUILDING_REG_2021', 'QLD_GOV', 'REGULATION', 'STATUTE', 'Building Regulation 2021', 'Building Regulation', 'SL 2021 No. 126',
  'Accepted building work (sch 1, sch 2), prescribed QDC parts (s79, sch 7), QHC transition (s106), pool safety (pt 5).'),
 ('QLD_PLANNING_REG_2017', 'QLD_GOV', 'REGULATION', 'STATUTE', 'Planning Regulation 2017', 'Planning Regulation', 'SL 2017 No. 78',
  'Referral of non-compliant siting to local government (sch 9 pt 3 div 2 table 3); definitions (sch 4, sch 24).'),
 ('QHC', 'QLD_GOV', 'QDC_MANDATORY_PART', 'STATUTORY_INSTRUMENT', 'Queensland Housing Code (Queensland Development Code Parts 1.1 and 1.2)', 'QHC', 'QDC Parts 1.1 and 1.2 (2026)',
  'Chapter 1 = QDC Part 1.1 (lots < 450 m2); Chapter 2 = QDC Part 1.2 (lots >= 450 m2). Applies in a local government area from the effective day of the scheme amendment adopting it, or from 1 Sept 2029 at the latest (Building Reg s106).'),
 ('QDC_MP_1_1', 'QLD_GOV', 'QDC_MANDATORY_PART', 'STATUTORY_INSTRUMENT', 'QDC MP 1.1 - Design and siting standard for single detached housing - on lots under 450m2', 'MP 1.1 (2010)', NULL,
  'Legacy part. Continues to apply to non-adopting local governments until the earlier of QHC adoption or 1 Sept 2029 (Building Reg s106).'),
 ('QDC_MP_1_2', 'QLD_GOV', 'QDC_MANDATORY_PART', 'STATUTORY_INSTRUMENT', 'QDC MP 1.2 - Design and siting standard for single detached housing - on lots 450m2 and over', 'MP 1.2 (2010)', NULL,
  'Legacy part. Continues to apply to non-adopting local governments until the earlier of QHC adoption or 1 Sept 2029 (Building Reg s106).'),
 ('QDC_MP_1_4', 'QLD_GOV', 'QDC_MANDATORY_PART', 'STATUTORY_INSTRUMENT', 'QDC MP 1.4 - Building over or near relevant infrastructure', 'MP 1.4', NULL, NULL),
 ('QDC_MP_3_4', 'QLD_GOV', 'QDC_MANDATORY_PART', 'STATUTORY_INSTRUMENT', 'QDC MP 3.4 - Swimming pool barriers', 'MP 3.4', NULL,
  'Is the "pool safety standard" (Building Act s231D(1)(a)). Adopts AS 1926.1-2007 and AS 1926.2-2007 with modifications.'),
 ('QDC_MP_3_5', 'QLD_GOV', 'QDC_MANDATORY_PART', 'STATUTORY_INSTRUMENT', 'QDC MP 3.5 - Construction of buildings in flood hazard areas', 'MP 3.5', NULL,
  'Construction (not siting) requirements; applies only where a flood hazard area and defined flood level are designated (Building Reg s8). Out of scope for setbacks; recorded for completeness.'),
 ('QDC_NMP_1_9', 'QLD_GOV', 'QDC_NON_MANDATORY_PART', 'ADOPTABLE', 'QDC NMP 1.9 - Swimming pool and spa equipment', 'NMP 1.9', NULL,
  'Non-mandatory: has effect only where a local government adopts it. Not a setback instrument.'),
 ('AS_1926_1_2007', 'STANDARDS_AUSTRALIA', 'AUSTRALIAN_STANDARD', 'REFERENCED_STANDARD', 'AS 1926.1-2007 Swimming pool safety - Part 1: Safety barriers for swimming pools (incl. Amendment 1)', 'AS 1926.1-2007', NULL,
  'Edition called up by QDC MP 3.4 (not the current AS 1926.1-2012). Copyright text not held in this dataset.'),
 ('AS_1926_2_2007', 'STANDARDS_AUSTRALIA', 'AUSTRALIAN_STANDARD', 'REFERENCED_STANDARD', 'AS 1926.2-2007 Swimming pool safety - Part 2: Location of safety barriers for swimming pools (incl. Amendment 1)', 'AS 1926.2-2007', NULL,
  'Edition called up by QDC MP 3.4. Copyright text not held in this dataset.'),
 ('NCC', 'ABCB', 'NCC', 'STATUTORY_INSTRUMENT', 'National Construction Code', 'NCC', NULL,
  'Construction requirements incl. fire separation of Class 10a near boundaries/dwellings. Edition adopted under the Building Act. Text not held in this dataset.');

INSERT INTO instrument_versions (instrument_version_id, instrument_id, version_label, published_date, effective_from, effective_to, status, source_url, local_file, file_sha256, retrieved_at, notes) VALUES
 ('QLD_BUILDING_ACT_1975@2026-02-01', 'QLD_BUILDING_ACT_1975', 'Reprint current as at 1 February 2026', NULL, '2026-02-01', NULL, 'ACTIVE',
  'https://www.legislation.qld.gov.au/view/html/inforce/current/act-1975-011', 'act-1975-011.pdf',
  '81d99eba0064169d47060c903714208a1b02ae7a2372e7137305c333f49b87af', '2026-10-06', 'Reprint date, not a commencement date. Check for later reprints before relying on it after 2026-10.'),
 ('QLD_BUILDING_REG_2021@2026-08-14', 'QLD_BUILDING_REG_2021', 'Reprint current as at 14 August 2026', NULL, '2026-08-14', NULL, 'ACTIVE',
  'https://www.legislation.qld.gov.au/view/html/inforce/current/sl-2021-0126', 'sl-2021-0126.pdf',
  '98a06ba987dfa0a5714fb09e81053c6263bc68e316ed4f7bab00d0179493a6b2', '2026-10-06', 'Includes Building and Other Legislation Amendment Regulation 2026 (QHC transition, s106).'),
 ('QLD_PLANNING_REG_2017@2026-09-11', 'QLD_PLANNING_REG_2017', 'Reprint current as at 11 September 2026', NULL, '2026-09-11', NULL, 'ACTIVE',
  'https://www.legislation.qld.gov.au/view/html/inforce/current/sl-2017-0078', 'sl-2017-0078.pdf',
  '8e3cac89f2689ccb1dfd4030998f158ce822d9ee7158f2a95f345b007f8cff17', '2026-10-06', NULL),
 ('QHC@2026-09-01', 'QHC', 'Queensland Housing Code, August 2026', '2026-08-03', '2026-09-01', NULL, 'ACTIVE',
  NULL, 'queensland-housing-code-01092026.pdf',
  'fe41631f06d097fd0cea8902e86a1e4a53e68368dcb80b4e91291b769db59ca0', '2026-10-06', 'Official download URL not recorded: housing.qld.gov.au blocks scripted access (HTTP 403). Add URL when supplied.'),
 ('QDC_MP_1_1@2010-03-26', 'QDC_MP_1_1', 'Publication date 11 March 2010', '2010-03-11', '2010-03-26', '2029-08-31', 'ACTIVE',
  NULL, 'mp1-1.pdf', '2b5582864d51c21ac8bb14057bb59fbfbecf14be84fc1e93bd2623f24cbbfeb8', '2026-10-06',
  'effective_to is the statewide long-stop (Building Reg s106(2)(b)); earlier per-LG end dates live in instrument_applicability.'),
 ('QDC_MP_1_2@2010-03-26', 'QDC_MP_1_2', 'Publication date 11 March 2010', '2010-03-11', '2010-03-26', '2029-08-31', 'ACTIVE',
  NULL, 'mp1-2.pdf', '27f8535d95f24ce79592c83c0d4ce7cecad1a97e2672d92400e50e0ad315cb20', '2026-10-06',
  'effective_to is the statewide long-stop (Building Reg s106(2)(b)); earlier per-LG end dates live in instrument_applicability.'),
 ('QDC_MP_1_4@2014-12-15', 'QDC_MP_1_4', 'Version 1.2, published 13 November 2014', '2014-11-13', '2014-12-15', NULL, 'ACTIVE',
  NULL, 'qdcmp1.4buildingoverornearrelevantinfrastructurenov2013.pdf', 'b51f3a9d58be397222d77312f1cd022c4d42b14819093655eabf5270813f0a09', '2026-10-06', NULL),
 ('QDC_MP_3_4@2012-07-27', 'QDC_MP_3_4', 'Publication date 18 July 2012', '2012-07-18', '2012-07-27', NULL, 'ACTIVE',
  NULL, 'qdcmp3.4swimmingpoolbarriers.pdf', '49d79c68e6d45f175c1d062285185f65c76593b57d814ed946d313fea4d82e5a', '2026-10-06', NULL),
 ('QDC_MP_3_5@2013-12-20', 'QDC_MP_3_5', 'Published 12 December 2013', '2013-12-12', '2013-12-20', NULL, 'ACTIVE',
  NULL, 'mandatory3.5constructionofbuildingsinfloodhazardareas.pdf', '50ca3aa1f38dd3be293bbab373e8b8ab5bc0a565f6d2ee4f651cc306ff2d6116', '2026-10-06', 'Dates from Building Reg 2021 sch 7.'),
 ('QDC_NMP_1_9@2008-01-01', 'QDC_NMP_1_9', 'Publication date 1 January 2008', '2008-01-01', NULL, NULL, 'ACTIVE',
  NULL, 'nmp-1-9-swimming-pool-and-spa-equipment.pdf', '35174e712f660442c601369605a8c3db73eed9e38182c9abfc7eaea53d1cb76f', '2026-10-06', 'Effective only where adopted by a local government.'),
 ('AS_1926_1_2007@2007', 'AS_1926_1_2007', 'AS 1926.1-2007 + Amdt 1', NULL, NULL, NULL, 'ACTIVE', NULL, NULL, NULL, NULL, 'Not held (copyright).'),
 ('AS_1926_2_2007@2007', 'AS_1926_2_2007', 'AS 1926.2-2007 + Amdt 1', NULL, NULL, NULL, 'ACTIVE', NULL, NULL, NULL, NULL, 'Not held (copyright).');

-- -----------------------------------------------------------------------------
-- Subject taxonomy
-- -----------------------------------------------------------------------------
INSERT INTO building_classifications VALUES
 ('1a',  'Class 1a: single dwelling (detached house etc.)', NULL),
 ('2',   'Class 2: two or more sole-occupancy units', NULL),
 ('10a', 'Class 10a: non-habitable building incl. private garage, carport, shed or the like', NULL),
 ('10b', 'Class 10b: structure being a fence, mast, antenna, retaining or free-standing wall, swimming pool or the like', NULL);

INSERT INTO structure_types (structure_type_id, parent_id, name, ncc_class, is_building, notes) VALUES
 ('ANY',               NULL,        'Any building or structure', NULL, false, 'Root node'),
 ('CLASS_1',           'ANY',       'Class 1 building (dwelling)', '1a', true, 'Included because many Class 10a rules fall back to Class 1 rules.'),
 ('SECONDARY_DWELLING','CLASS_1',   'Secondary dwelling', '1a', true, NULL),
 ('CLASS_10A',         'ANY',       'Class 10a building', '10a', true, NULL),
 ('GARAGE',            'CLASS_10A', 'Garage (enclosed)', '10a', true, NULL),
 ('CARPORT',           'CLASS_10A', 'Carport (unenclosed)', '10a', true, NULL),
 ('OPEN_CARPORT',      'CARPORT',   'Open carport (MP 1.1/1.2 definition)', '10a', true, 'MP 1.2 defn: two sides or more open and not less than one-third of perimeter open.'),
 ('SHED',              'CLASS_10A', 'Shed', '10a', true, NULL),
 ('DETACHED_LAUNDRY',  'CLASS_10A', 'Detached laundry', '10a', true, NULL),
 ('GATEHOUSE',         'CLASS_10A', 'Gatehouse / roofed entry arch', '10a', true, NULL),
 ('CLASS_10A_OTHER',   'CLASS_10A', 'Other Class 10a (e.g. roofed gazebo, cabana)', '10a', true, 'Classification of individual items requires certifier judgement.'),
 ('OUTDOOR_STRUCTURE', 'ANY',       'Patio / pergola / deck / verandah family', NULL, false,
  'NCC class depends on roof, enclosure and attachment (Class 10a if a free-standing roofed non-habitable building; often part of the Class 1 building if attached). Engine must not assume a class.'),
 ('PATIO',             'OUTDOOR_STRUCTURE', 'Patio (roofed outdoor area)', NULL, false, NULL),
 ('PERGOLA',           'OUTDOOR_STRUCTURE', 'Pergola', NULL, false, NULL),
 ('DECK',              'OUTDOOR_STRUCTURE', 'Deck', NULL, false, NULL),
 ('VERANDAH',          'OUTDOOR_STRUCTURE', 'Verandah / porch / alfresco', NULL, false, NULL),
 ('CLASS_10B',         'ANY',       'Class 10b structure', '10b', false, NULL),
 ('FENCE',             'CLASS_10B', 'Fence / free-standing wall / screen', '10b', false, NULL),
 ('RETAINING_WALL',    'CLASS_10B', 'Retaining wall', '10b', false, NULL),
 ('RAINWATER_TANK',    'CLASS_10B', 'Rainwater tank (incl. stand)', '10b', false, NULL),
 ('POOL',              'CLASS_10B', 'Swimming pool (Building Act sch 2 definition)', '10b', false, 'Includes spa pools/tubs; excludes ornamental ponds, portable wading pools.'),
 ('POOL_INGROUND',     'POOL',      'In-ground swimming pool', '10b', false, NULL),
 ('POOL_ABOVEGROUND',  'POOL',      'Above-ground swimming pool (incl. portable pools >= 300 mm depth)', '10b', false, NULL),
 ('SPA',               'POOL',      'Spa pool / spa tub (outdoor)', '10b', false, NULL),
 ('POOL_BARRIER',      'CLASS_10B', 'Pool barrier', '10b', false, 'Building Act s231B(2): fencing, building walls, or other barrier provided for in the pool safety standard.'),
 ('POOL_FENCE',        'POOL_BARRIER', 'Pool fence (incl. boundary fence forming part of barrier)', '10b', false, NULL),
 ('POOL_GATE',         'POOL_BARRIER', 'Pool gate', '10b', false, NULL),
 ('UTILITY_STRUCTURE', 'ANY',       'Utility structure / external fixture (QHC)', NULL, false, NULL);

-- -----------------------------------------------------------------------------
-- Fact vocabulary (inputs the engine must supply; see docs/03 for derivations)
-- -----------------------------------------------------------------------------
INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('assessment_date',        'DATE',    NULL, NULL, 'USER_DECLARATION', 'Date the building application is approved/decided (Building Act s36) — drives version selection', NULL),
 ('lg_id',                  'TEXT',    NULL, NULL, 'PROPERTY_DATA', 'Local government area of the lot', 'Point-in-polygon on cadastre centroid'),
 ('lg_has_adopted_qhc',     'BOOLEAN', NULL, NULL, 'ENGINE_DERIVED', 'Whether the LG scheme amendment adopting the QHC has an effective day on or before assessment_date', 'From instrument_applicability'),
 ('zone_id',                'TEXT',    NULL, NULL, 'PLANNING_DATA', 'Planning scheme zone of the lot', 'Zone map overlay'),
 ('zone_permits_dwelling_house','BOOLEAN',NULL,NULL,'ENGINE_DERIVED','Zone categorises dwelling house as accepted or code assessable (QHC "permitted use")', 'zones.dwelling_house_permitted'),
 ('in_relevant_overlay',    'BOOLEAN', NULL, NULL, 'PLANNING_DATA', 'Lot/work is within a "relevant overlay" (Planning Reg sch 24)', 'Overlay map intersection with footprint'),
 ('in_priority_development_area','BOOLEAN',NULL,NULL,'PLANNING_DATA','Lot in a PDA (Economic Development Act) — QHC/QDC siting parts do not apply', NULL),
 ('lot_area_m2',            'NUMBER',  'm2', NULL, 'PROPERTY_DATA', 'Lot area', 'Registered area from cadastre (not GIS-computed area, unless unavailable)'),
 ('lot_width_m',            'NUMBER',  'm',  NULL, 'GEOMETRY_DERIVED', 'QHC lot width: shortest distance between side boundaries at the primary frontage (or alternatives for irregular lots)', 'QHC s11 definition'),
 ('road_frontage_m',        'NUMBER',  'm',  NULL, 'GEOMETRY_DERIVED', 'MP 1.1/1.2 road frontage length (for Table A2 narrow-lot clearances)', 'Length of boundary adjoining road'),
 ('average_lot_depth_m',    'NUMBER',  'm',  NULL, 'GEOMETRY_DERIVED', 'MP 1.1/1.2 depth of a lot', 'Dimension at right angles to road boundary, averaged for irregular boundary'),
 ('lot_is_rectangular_or_near','BOOLEAN',NULL,NULL,'GEOMETRY_DERIVED','"rectangular or near rectangular" (MP 1.1/1.2 A2(b)) — judgement', 'Heuristic only; flag for review'),
 ('is_corner_lot',          'BOOLEAN', NULL, NULL, 'GEOMETRY_DERIVED', 'Lot on a road corner (QHC "road corner" definition has 4 tests)', NULL),
 ('is_battle_axe_lot',      'BOOLEAN', NULL, NULL, 'GEOMETRY_DERIVED', 'Battle axe lot', NULL),
 ('lot_slope_pct',          'NUMBER',  '%',  NULL, 'GEOMETRY_DERIVED', 'Slope over 20m x 20m area including building location', 'DEM'),
 ('boundary_type',          'ENUM',    NULL, '{PRIMARY_FRONTAGE,SECONDARY_FRONTAGE_ROAD,SECONDARY_FRONTAGE_LANE_PARKWAY,SECONDARY_FRONTAGE_OTHER,SIDE,REAR}', 'ENGINE_DERIVED', 'Type of the boundary segment being tested', 'Per QHC/MP definitions; primary frontage priority order'),
 ('is_nominated_road_frontage','BOOLEAN',NULL,NULL,'PLANNING_DATA','MP 1.1/1.2 corner lot: the road frontage nominated by the local government', 'Council data or approval; else unknown'),
 ('street_type',            'ENUM',    NULL, '{ACCESS_PLACE,ACCESS_STREET,COLLECTOR,OTHER}', 'PLANNING_DATA', 'MP 1.1 Table A1 street hierarchy', 'Council road hierarchy mapping'),
 ('structure_height_m',     'NUMBER',  'm',  NULL, 'DESIGN_INPUT', 'Overall height of building/structure (definition depends on instrument)', NULL),
 ('part_height_m',          'NUMBER',  'm',  NULL, 'DESIGN_INPUT', 'Height of the part of the building/structure being tested (MP 1.x: OMP above natural ground)', 'Evaluated per part along the boundary'),
 ('wall_height_m',          'NUMBER',  'm',  NULL, 'DESIGN_INPUT', 'QHC height of external wall at the relevant point', NULL),
 ('mean_height_m',          'NUMBER',  'm',  NULL, 'DESIGN_INPUT', 'Elevational area facing boundary / horizontal length facing boundary', NULL),
 ('storey_number',          'NUMBER',  NULL, NULL, 'DESIGN_INPUT', 'Storey of the part being tested (1 = ground)', NULL),
 ('roof_area_m2',           'NUMBER',  'm2', NULL, 'DESIGN_INPUT', 'Roof area (gatehouse limits)', NULL),
 ('plan_area_m2',           'NUMBER',  'm2', NULL, 'DESIGN_INPUT', 'Plan area incl. overhangs (Building Reg sch 1 s13)', NULL),
 ('longest_side_m',         'NUMBER',  'm',  NULL, 'DESIGN_INPUT', 'Longest side of the Class 10 building/structure', NULL),
 ('is_roofed',              'BOOLEAN', NULL, NULL, 'DESIGN_INPUT', 'Has a roof', NULL),
 ('is_enclosed',            'BOOLEAN', NULL, NULL, 'DESIGN_INPUT', 'Enclosed by walls', NULL),
 ('is_attached_to_dwelling','BOOLEAN', NULL, NULL, 'DESIGN_INPUT', 'Attached to the dwelling', NULL),
 ('floor_height_above_ground_m','NUMBER','m',NULL,'DESIGN_INPUT','Deck/patio floor height above natural ground', NULL),
 ('used_for_entertainment_or_recreation','BOOLEAN',NULL,NULL,'USER_DECLARATION','MP 1.x A2(c)(ii)', NULL),
 ('primarily_ornamental_or_horticultural','BOOLEAN',NULL,NULL,'USER_DECLARATION','MP 1.x A2(c)(v)(C)', NULL),
 ('btb_length_on_boundary_m','NUMBER', 'm',  NULL, 'GEOMETRY_DERIVED', 'Total length of all buildings/parts (any class) within the boundary clearance along the boundary being tested, including existing', NULL),
 ('distance_to_adjoining_habitable_window_m','NUMBER','m',NULL,'PROPERTY_DATA','Distance from the Class 10a part to a required habitable-room window of an adjoining dwelling', 'Usually unknown → manual review'),
 ('adjoining_dwellings_both_sides','BOOLEAN',NULL,NULL,'PROPERTY_DATA','Existing detached dwellings on both adjoining lots (MP 1.x A1(a)(ii))', NULL),
 ('adjoining_road_setbacks_m','NUMBER','m', NULL,  'PROPERTY_DATA', 'Array [left,right] of road setbacks of adjoining dwellings', NULL),
 ('adjoining_premises_setback_less_than_table','BOOLEAN',NULL,NULL,'PROPERTY_DATA','QHC Table 1 supp. prov. 2', NULL),
 ('carport_obstruction_pct','NUMBER',  '%',  NULL, 'DESIGN_INPUT', 'Aggregate perimeter of walls/screens/supports within the setback as % of carport perimeter within the setback (MP 1.2 A1(c))', NULL),
 ('alternative_carport_site_available','BOOLEAN',NULL,NULL,'USER_DECLARATION','Compliant alternative on-site garage/carport location with 2.5m access and <= 1 in 5 gradient exists', 'Judgement'),
 ('pool_coping_height_m',   'NUMBER',  'm',  NULL, 'DESIGN_INPUT', 'Vertical distance from finished ground level to top of pool coping', NULL),
 ('solid_wall_between_pool_and_boundary_height_m','NUMBER','m',NULL,'DESIGN_INPUT','Height above finished ground of a solid wall/fence between water and the boundary', NULL),
 ('solid_wall_top_above_coping_m','NUMBER','m',NULL,'DESIGN_INPUT','Height of top of that wall above pool coping (MP 1.x) or pool deck (QHC)', NULL),
 ('pool_is_indoor',         'BOOLEAN', NULL, NULL, 'DESIGN_INPUT', 'Indoor swimming pool (Building Act sch 2)', NULL),
 ('pool_capable_depth_m',   'NUMBER',  'm',  NULL, 'DESIGN_INPUT', 'Depth of water the excavation/structure is capable of holding', NULL),
 ('land_is_regulated_land', 'BOOLEAN', NULL, NULL, 'ENGINE_DERIVED', 'Class 1-4 building, moveable dwelling park or residential park on (or adjacent same-owner) land', NULL),
 ('barrier_height_mm',      'NUMBER',  'mm', NULL, 'DESIGN_INPUT', 'Barrier height measured on the side with the NCZ', NULL),
 ('barrier_is_boundary_fence','BOOLEAN',NULL,NULL, 'DESIGN_INPUT', 'Barrier segment is on a lot boundary', NULL),
 ('ncz_side',               'ENUM',    NULL, '{OUTSIDE,INSIDE}', 'DESIGN_INPUT', 'Side of the fence the non-climbable zone is on', NULL),
 ('in_wind_region_c',       'BOOLEAN', NULL, NULL, 'PROPERTY_DATA', 'AS 1170.2 Wind Region C (none of the 7 SEQ councils expected; verify)', NULL),
 ('infrastructure_on_lot',  'BOOLEAN', NULL, NULL, 'PROPERTY_DATA', 'Relevant infrastructure (sewer, water main, stormwater drain, combined sanitary drain) on the lot', 'Service provider asset data'),
 ('infrastructure_on_adjacent_lot','BOOLEAN',NULL,NULL,'PROPERTY_DATA','Relevant infrastructure on an adjacent lot (incl. adjacent road reserve)', NULL),
 ('infrastructure_dn_mm',   'NUMBER',  'mm', NULL, 'PROPERTY_DATA', 'Nominal diameter of the infrastructure', NULL),
 ('infrastructure_is_pressure_pipeline','BOOLEAN',NULL,NULL,'PROPERTY_DATA','Pressure pipeline', NULL),
 ('distance_to_infrastructure_centreline_m','NUMBER','m',NULL,'GEOMETRY_DERIVED','Shortest horizontal distance from any part of the building/structure to the vertical plane along the infrastructure centreline', NULL),
 ('is_light_weight_class_10','BOOLEAN', NULL, NULL, 'DESIGN_INPUT', 'MP 1.4 s6: Class 10 with no concrete or masonry walls, columns or roof', NULL);

-- -----------------------------------------------------------------------------
-- Measurement definitions
-- -----------------------------------------------------------------------------
INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, boundary_selector, vertical_projection, evaluate_per_part, postgis_hint, notes) VALUES
 -- Legacy MP 1.1 / 1.2: everything measured from the outermost projection (OMP)
 ('MP_ROAD_SETBACK_OMP', 'MIN_HORIZONTAL_DISTANCE', 'STRUCTURE_OUTERMOST_PROJECTION', 'BOUNDARY_ROAD', 'every lot boundary adjoining a road', true, false,
  'ST_Distance(omp_footprint, road_boundary_linestring)', 'MP 1.2 "road boundary clearance". OMP includes fascia/roof structure and attached sunhoods; excludes retractable blinds, fixed screens, rainwater fittings, ornamental attachments.'),
 ('MP_SIDE_REAR_CLEARANCE_OMP', 'MIN_HORIZONTAL_DISTANCE', 'STRUCTURE_OUTERMOST_PROJECTION', 'BOUNDARY_SIDE_OR_REAR', 'every non-road boundary', true, true,
  'Per part: ST_Distance(part_omp, boundary) compared with value computed from that part''s height', 'MP 1.2 "side and rear boundary clearance" — requirement varies with the height of each part.'),
 ('MP_POOL_WATER_TO_ROAD', 'MIN_HORIZONTAL_DISTANCE', 'POOL_WATER_EDGE', 'BOUNDARY_ROAD', 'road frontage(s)', true, false, 'ST_Distance(water_edge_polygon_boundary, road_boundary)', 'MP 1.2 "setback" (b): from the water''s edge.'),
 ('MP_POOL_WATER_TO_SIDE_REAR', 'MIN_HORIZONTAL_DISTANCE', 'POOL_WATER_EDGE', 'BOUNDARY_SIDE_OR_REAR', 'non-road boundaries', true, false, NULL, NULL),
 ('MP_BTB_LENGTH_ALONG_BOUNDARY', 'LENGTH_ALONG_BOUNDARY', 'ALL_BUILDINGS_WITHIN_CLEARANCE', 'BOUNDARY_SIDE_OR_REAR', 'each side/rear boundary separately', true, false,
  'Sum of lengths of parts (new + existing, any class) inside the clearance strip, projected onto the boundary', 'MP 1.2 A2(d)(ii): "along any one boundary".'),
 ('MP_CORNER_TRUNCATION_9X9', 'EXCLUSION_ZONE', 'ANY_BUILDING_OR_STRUCTURE_OVER_2M', 'CORNER_TRIANGLE_9M_X_9M', 'corner of the 2 road frontages', true, false,
  'Triangle with 9 m legs along each road boundary from the corner; no part > 2 m high may intersect', 'MP 1.x A1 corner-lot proviso (only when average depth <= 24 m and Table A1 used).'),
 ('MP_SIGHTLINE_TRUNCATION_6M_RADIUS', 'EXCLUSION_ZONE', 'FENCES_SCREENS_WALLS_STRUCTURES', 'TRUNCATION_3_CHORDS_6M_RADIUS', 'corner of the 2 road frontages', true, false,
  'Polygon cut by 3 equal chords of a 6 m radius curve at the corner; max 1 m high inside', 'MP 1.x A7.'),
 ('MP_SITE_COVER', 'AREA_RATIO', 'ROOFED_IMPERVIOUS_AREA', 'LOT_AREA', NULL, true, false,
  'sum(area) / lot_area where enclosed area incl. outside wall; unenclosed area measured 600mm in from roof perimeter', 'MP 1.2 A3 and "area" definition.'),
 ('MP_BUILDING_HEIGHT', 'MAX_VERTICAL_HEIGHT', 'HIGHEST_POINT_EXCL_ANTENNAE_CHIMNEY_FLUES', 'NATURAL_GROUND_SURFACE_BELOW', NULL, false, false, 'Max over roof points of (z - natural ground z directly below)', 'MP 1.2 "building height".'),
 ('MEAN_HEIGHT_FACING_BOUNDARY', 'MEAN_HEIGHT', 'ELEVATION_FACING_BOUNDARY', 'BOUNDARY_SIDE_OR_REAR', NULL, false, false, 'elevational area / horizontal length facing boundary', NULL),
 -- QHC: measured from different points for different elements
 ('QHC_WALL_TO_BOUNDARY', 'MIN_HORIZONTAL_DISTANCE', 'EXTERNAL_WALL_FACADE', 'BOUNDARY_BY_TYPE', 'boundary of the type stated in the rule condition', true, true,
  'ST_Distance(facade_line, boundary)', 'QHC setback (a): from the facade of an external wall — NOT the eaves/OMP. Eaves are "weather control elements" tested separately.'),
 ('QHC_STRUCTURE_OMP_TO_BOUNDARY', 'MIN_HORIZONTAL_DISTANCE', 'STRUCTURE_OUTERMOST_PROJECTION', 'BOUNDARY_BY_TYPE', 'boundary of the type stated in the rule condition', true, false,
  NULL, 'QHC setback (d): structures other than pools; OMP per Planning Reg sch 4.'),
 ('QHC_BUILDING_PART_TO_BOUNDARY', 'MIN_HORIZONTAL_DISTANCE', 'BUILDING_PART', 'BOUNDARY_BY_TYPE', NULL, true, false,
  NULL, 'QHC setback (c): window, deck, pergola, privacy screen, external fixture, covered outdoor room, balcony or weather control element.'),
 ('QHC_GARAGE_DOOR_TO_ACCESS_BOUNDARY', 'MIN_HORIZONTAL_DISTANCE', 'GARAGE_DOOR', 'BOUNDARY_PROVIDING_VEHICLE_ACCESS', NULL, true, false, NULL, 'QHC setback (b).'),
 ('QHC_POOL_WATER_TO_BOUNDARY', 'MIN_HORIZONTAL_DISTANCE', 'POOL_WATER_EDGE', 'BOUNDARY_BY_TYPE', NULL, true, false, NULL, 'QHC setback (e).'),
 ('QHC_BTB_LENGTH_ALONG_COMMON_BOUNDARY', 'LENGTH_ALONG_BOUNDARY', 'CLASS_10A_GARAGE_CARPORT_LAUNDRY_SHED_BTB', 'COMMON_BOUNDARY', 'each common boundary separately', true, false, NULL,
  'QHC Table 3: "up to 9m total combined length along each common boundary".'),
 ('QHC_SITE_COVER', 'AREA_RATIO', 'QHC_SITE_COVER_AREA', 'LOT_AREA_EXCL_ACCESS_HANDLE', NULL, true, false,
  NULL, 'QHC site cover: enclosed incl. external wall; roofed unenclosed measured 600mm in from OMP; excludes unroofed structures, pools, retaining walls, fences; battle-axe access handle excluded.'),
 ('QHC_HEIGHT', 'MAX_VERTICAL_HEIGHT', 'HIGHEST_POINT_ON_ROOF', 'GROUND_LEVEL', NULL, false, false, NULL,
  'QHC "height": building height (Planning Reg sch 4: ground level to highest point on roof, excl. aerial, chimney, flagpole, load-bearing antenna) or structure height.'),
 -- Building Regulation exemption tests
 ('BR_CLASS10_PLAN_AREA', 'AREA', 'CLASS_10_EXTREMITIES_INCL_OVERHANGS', NULL, NULL, true, false, NULL, 'Building Reg sch 1 s13(4) plan area.'),
 -- Pool barrier
 ('POOL_BARRIER_HEIGHT', 'MAX_VERTICAL_HEIGHT', 'POOL_BARRIER_TOP', 'FINISHED_GROUND_ON_NCZ_SIDE', NULL, false, false, NULL, 'MP 3.4 sch 1 item 1: measured on the same side as the non-climbable zone. Operator is >= (a minimum height).'),
 ('POOL_BARRIER_CONTINUITY', 'PRESENCE', 'POOL_BARRIER', 'POOL_AREA', NULL, false, false, NULL, 'MP 3.4 P1(a): continuous for the full extent of the hazard. Not reliably checkable from plan geometry alone.'),
 -- Infrastructure
 ('INFRA_CENTRELINE_DISTANCE', 'MIN_HORIZONTAL_DISTANCE', 'ANY_PART_OF_BUILDING_OR_STRUCTURE', 'INFRASTRUCTURE_CENTRELINE_VERTICAL_PLANE', NULL, true, false, NULL, 'MP 1.4.'),
 ('INFRA_FOOTING_DISTANCE', 'MIN_HORIZONTAL_DISTANCE', 'WALL_FOOTING_PILE_PIER_OR_FLOOR', 'INFRASTRUCTURE_CENTRELINE_VERTICAL_PLANE', NULL, true, false, NULL, 'MP 1.4 A2.1(2)(a).');

-- Facts and measurements added for specific provisions
INSERT INTO facts (fact_id, type, unit, allowed_values, source, description, derivation) VALUES
 ('gatehouse_street_elevation_width_m','NUMBER','m',NULL,'DESIGN_INPUT','Width of gatehouse/arch elevation facing the street (MP 1.x A1(d)(iii)(B))', NULL),
 ('primary_frontage_is_lane_or_parkway','BOOLEAN',NULL,NULL,'ENGINE_DERIVED','The primary frontage boundary is a laneway or parkway (QHC Table 1 supp. prov. 1)', NULL),
 ('wall_is_maintenance_free','BOOLEAN',NULL,NULL,'DESIGN_INPUT','Wall within 750 mm of boundary is maintenance free (MP 1.x A6 / QHC A6)', NULL),
 ('solid_fence_above_pool_deck_m','NUMBER','m',NULL,'DESIGN_INPUT','Height by which a solid fence between water and the boundary extends above the pool deck (QHC Tables 2/4 supp. prov.)', NULL),
 ('building_height_m','NUMBER','m',NULL,'DESIGN_INPUT','Height of the building (QHC Table A1 selects the formula by building height)', NULL),
 ('ncz_required','BOOLEAN',NULL,NULL,'ENGINE_DERIVED','Non-climbable zone required for the fence (false only where MP 3.4 sch 1 item 12 applies)', NULL),
 ('barrier_has_cranked_top','BOOLEAN',NULL,NULL,'DESIGN_INPUT','Fence has a cranked top complying with MP 3.4 figure 17(b)', NULL),
 ('is_class10_accepted_work','BOOLEAN',NULL,NULL,'ENGINE_DERIVED','Result of Building Reg sch 1 s13 test', NULL),
 ('weather_control_attached_to_btb_part','BOOLEAN',NULL,NULL,'GEOMETRY_DERIVED','The eaves/awning is attached to a part of the building that is built to boundary (QHC Table 4 supp. prov. 1)', NULL),
 ('structure_height_above_ground_m','NUMBER','m',NULL,'DESIGN_INPUT','Height of the structure above (natural) ground — used for the "less than 1m above ground" application exclusion', NULL);

INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, boundary_selector, vertical_projection, evaluate_per_part, postgis_hint, notes) VALUES
 ('GARAGE_OPENING_WIDTH_FACING_STREET','WIDTH','GARAGE_CARPORT_OPENINGS_FACING_STREET','BOUNDARY_ROAD',NULL,false,false,'Sum of elevational widths of vehicle openings facing the street','MP 1.1 A1(b)(ii).'),
 ('QHC_GARAGE_ACCESS_WIDTH','WIDTH','GARAGE_CARPORT_ACCESS_OPENING','BOUNDARY_PROVIDING_VEHICLE_ACCESS',NULL,false,false,'Between outermost structural supports or edges of the opening','QHC "access width".'),
 ('PRIVACY_SCREEN_HEIGHT_ABOVE_FLOOR','MAX_VERTICAL_HEIGHT','PRIVACY_SCREEN_TOP','DECK_FLOOR_LEVEL',NULL,false,false,NULL,'QHC A5(3).'),
 ('POOL_GATE_OPENS_AWAY','PRESENCE','POOL_GATE','POOL_AREA',NULL,false,false,NULL,'MP 3.4 sch 1 item 15.'),
 ('POOL_GATE_SELF_CLOSING_LATCHING','PRESENCE','POOL_GATE',NULL,NULL,false,false,NULL,'MP 3.4 P1(d). Not determinable from geometry.'),
 ('POOL_BARRIER_HAS_BUILDING_DOOR','PRESENCE','POOL_BARRIER','BUILDING_DOORS',NULL,false,false,NULL,'MP 3.4 P1(e).'),
 ('INFRA_LENGTH_OVER_CENTRELINE','LENGTH_ALONG_BOUNDARY','LIGHT_WEIGHT_CLASS_10','INFRASTRUCTURE_CENTRELINE_VERTICAL_PLANE',NULL,true,false,'Longest continuous length of the structure crossing over the centreline plane','MP 1.4 A2.2(2)(a).'),
 ('INFRA_MAINTENANCE_COVER_DISTANCE','MIN_HORIZONTAL_DISTANCE','ANY_PART_OF_BUILDING_OR_STRUCTURE','INFRASTRUCTURE_MAINTENANCE_COVER_CENTRE',NULL,true,false,'ST_Distance(omp_footprint, cover_point) — infinite-height clear zone means overhangs count','MP 1.4 A2.1(2)(c).'),
 ('ASSESSMENT_TRIGGER','PRESENCE','DEVELOPMENT','INSTRUMENT',NULL,false,false,NULL,'Pseudo-measurement for TRIGGER rules (no geometry).');

-- Planning-scheme measurements: measured per the scheme's own definitions
-- (e.g. 'setback' from outermost projection). The definition provision is
-- cited on each council rule.
INSERT INTO measurements (measurement_id, measurement_type, subject_geometry, reference_geometry, boundary_selector, vertical_projection, evaluate_per_part, notes) VALUES
 ('SCHEME_SETBACK_FRONT','MIN_HORIZONTAL_DISTANCE','PER_SCHEME_DEFINITION','BOUNDARY_PRIMARY_FRONTAGE',NULL,true,false,'Scheme definition of setback governs the measuring point.'),
 ('SCHEME_SETBACK_SECONDARY_FRONTAGE','MIN_HORIZONTAL_DISTANCE','PER_SCHEME_DEFINITION','BOUNDARY_SECONDARY_FRONTAGE_ROAD',NULL,true,false,NULL),
 ('SCHEME_SETBACK_SIDE','MIN_HORIZONTAL_DISTANCE','PER_SCHEME_DEFINITION','BOUNDARY_SIDE',NULL,true,true,NULL),
 ('SCHEME_SETBACK_REAR','MIN_HORIZONTAL_DISTANCE','PER_SCHEME_DEFINITION','BOUNDARY_REAR',NULL,true,true,NULL),
 ('SCHEME_BTB_LENGTH','LENGTH_ALONG_BOUNDARY','PER_SCHEME_DEFINITION','BOUNDARY_SIDE_OR_REAR',NULL,true,false,NULL),
 ('SCHEME_GARAGE_CARPORT','COMPOSITE','GARAGE_OR_CARPORT','BOUNDARY_ROAD',NULL,true,false,'Setback and/or opening width per the provision text.'),
 ('SCHEME_SITE_COVER','AREA_RATIO','PER_SCHEME_DEFINITION','LOT_AREA',NULL,true,false,'Scheme definition of site cover governs (often excludes eaves <= 600 mm, unroofed decks, pools).'),
 ('SCHEME_HEIGHT','MAX_VERTICAL_HEIGHT','PER_SCHEME_DEFINITION','GROUND_LEVEL',NULL,false,false,NULL),
 ('SCHEME_OUTBUILDING_SIZE','AREA','CLASS_10A_ROOFED_OR_FLOOR_AREA',NULL,NULL,true,false,'Floor area vs roofed area per provision text.'),
 ('SCHEME_POOL_SETBACK','MIN_HORIZONTAL_DISTANCE','PER_SCHEME_DEFINITION','BOUNDARY_BY_TYPE',NULL,true,false,NULL),
 ('SCHEME_LANDSCAPE','AREA_RATIO','LANDSCAPED_OR_PERVIOUS_AREA','LOT_AREA',NULL,true,false,NULL),
 ('SCHEME_SEPARATION','MIN_HORIZONTAL_DISTANCE','PER_SCHEME_DEFINITION','OTHER_BUILDING_ON_SITE',NULL,true,false,NULL),
 ('SCHEME_OTHER','COMPOSITE','PER_PROVISION_TEXT',NULL,NULL,false,false,'Not machine-measurable without curation.');
