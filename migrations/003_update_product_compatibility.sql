-- ============================================================================
-- MIGRATION 3: Update existing products with car compatibility data
-- ============================================================================
-- Purpose: Add car type and size compatibility to all 111 existing products
-- Date: 2026-04-14
-- ============================================================================

-- Update logic:
-- 1. Head Units: Most are universal, but size matters (single vs double DIN)
-- 2. Speakers: Size compatibility with factory speaker locations
-- 3. Subwoofers: Space requirements (compact vs large)
-- 4. Amplifiers: Power needs based on cabin size
-- 5. Processors: Universal but more relevant for larger setups

-- ============================================================================
-- HEAD UNIT SINGLE DIN - Universal for single_din dashboard cars
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['City Car', 'Sedan', 'Hatchback', 'Pickup', 'Van'],
    mp_recommended_car_sizes = ARRAY['small', 'medium', 'large']
WHERE mp_category = 'head_unit_single_din';

-- Specific: Kenwood KMM-205, Pioneer DEH-S5250BT, JVC KD-X265BT
-- These fit any car with single DIN slot

-- ============================================================================
-- HEAD UNIT DOUBLE DIN - For medium/large cars with double_din dashboard
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan', 'Hatchback'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'head_unit_double_din';

-- Specific products:
-- Kenwood DMX4707S, DMX7522S
-- Pioneer DMH-G225BT, DMH-Z5350BT, DMH-ZF9350BT, DMH-AP6650BT, AVH-Z5250BT
-- JVC KW-M690BT, KW-MZ63BT
-- These need double_din dashboard (MPV, SUV, medium+ Sedan)

-- ============================================================================
-- HEAD UNIT ANDROID - Universal but better for larger cabins
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan', 'Hatchback', 'Van'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'head_unit_android' 
  AND mp_name LIKE '%9 inch%';

-- 9 inch Android HUs - better for medium/large dashboards
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan'],
    mp_recommended_car_sizes = ARRAY['large']
WHERE mp_category = 'head_unit_android' 
  AND mp_name LIKE '%10 inch%';

-- 10 inch Android HUs - need large dashboard space
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'City Car', 'Sedan', 'Hatchback', 'Pickup'],
    mp_recommended_car_sizes = ARRAY['small', 'medium', 'large']
WHERE mp_category = 'head_unit_android' 
  AND mp_name LIKE '%7 inch%';

-- 7 inch Android HUs - compact, fits smaller cars too
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'City Car', 'Sedan', 'Hatchback', 'Pickup', 'Van'],
    mp_recommended_car_sizes = ARRAY['small', 'medium', 'large']
WHERE mp_category = 'head_unit_android' 
  AND mp_name LIKE '%8 inch%';

-- 8 inch - universal fit

-- Budget Android units (DHD, Skeleton, Orca entry level) - prioritize city cars & MPVs
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['City Car', 'MPV', 'Pickup'],
    mp_recommended_car_sizes = ARRAY['small', 'medium']
WHERE mp_category = 'head_unit_android' 
  AND mp_price < 1000000;

-- Specific: DHD 7001, Skeleton SKT-8189, Orca ADR-9988 EcoLite
-- These are budget-friendly, great for city cars and pickups

-- ============================================================================
-- SPEAKER COAXIAL 6.5 inch - Universal for most cars
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan', 'Hatchback', 'Van'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'speaker_coaxial' 
  AND mp_name LIKE '%6.5 inch%';

-- Most 6.5" coaxials - standard size for door speakers

-- ============================================================================
-- SPEAKER COAXIAL 5.25 inch - For small cars (City Cars)
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['City Car', 'Sedan', 'Hatchback'],
    mp_recommended_car_sizes = ARRAY['small', 'medium']
WHERE mp_category = 'speaker_coaxial' 
  AND (mp_name LIKE '%5.25 inch%' OR mp_name LIKE '%5.25"%');

-- Kenwood KFC-S1366, Pioneer TS-A1370F - perfect for Brio, Agya, Ayla

-- ============================================================================
-- SPEAKER COAXIAL 6x9 inch - For rear deck (MPV, SUV, large Sedan)
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'speaker_coaxial' 
  AND mp_name LIKE '%6x9%';

-- Pioneer TS-A6996R, Orca 6x9 - for rear deck of larger vehicles

-- ============================================================================
-- SPEAKER COMPONENT 6.5 inch - Universal for quality upgrade
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan', 'Hatchback'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'speaker_component' 
  AND mp_name LIKE '%6.5 inch%';

-- Most 6.5" component speakers - need proper door space

-- Budget component speakers (DHD, Skeleton) - also for city cars
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['City Car', 'MPV', 'Sedan', 'Hatchback'],
    mp_recommended_car_sizes = ARRAY['small', 'medium']
WHERE mp_category = 'speaker_component' 
  AND mp_price < 600000;

-- DHD-620CV, Skeleton SK-620C - affordable, fits smaller cars

-- ============================================================================
-- TWEETER - Universal, depends on installation
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan', 'Hatchback', 'City Car', 'Van'],
    mp_recommended_car_sizes = ARRAY['small', 'medium', 'large']
WHERE mp_category = 'tweeter';

-- Kenwood KFC-ST1, Hertz Mille Pro MPX - universal tweeters

-- ============================================================================
-- SUBWOOFER KOLOG/UNDERSEAT - Perfect for small cars with limited space
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['City Car', 'MPV', 'SUV', 'Sedan', 'Hatchback', 'Pickup'],
    mp_recommended_car_sizes = ARRAY['small', 'medium']
WHERE mp_category = 'subwoofer' 
  AND (mp_name ILIKE '%kolong%' OR mp_name ILIKE '%underseat%' OR mp_name ILIKE '%slim%');

-- Kenwood KSC-SW11, Pioneer TS-WX130EA, TS-WX400D, Nakamichi NBF-10
-- DHD-450NB, Orca SW-2668, Skeleton SKT-T550
-- These are PERFECT for Brio, Agya, Ayla (limited trunk space)

-- ============================================================================
-- SUBWOOFER BOXED/PASSIVE - For larger cars with trunk space
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'subwoofer' 
  AND (mp_name ILIKE '%passive%' OR mp_name NOT ILIKE '%kolong%' AND mp_name NOT ILIKE '%underseat%' AND mp_name NOT ILIKE '%slim%');

-- Pioneer TS-W311D4, Hertz Mille Pro MP 250, JL Audio 10W1V3, 10W3V3, 12W0V3
-- These need trunk space - NOT suitable for Brio/Agya unless custom install

-- ============================================================================
-- AMPLIFIER 4 CHANNEL - Universal, power depends on cabin size
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan', 'Hatchback', 'Van'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'amplifier' 
  AND mp_power_spec LIKE '%75W%' 
     OR mp_power_spec LIKE '%100W%'
     OR mp_power_spec LIKE '%125W%';

-- Higher power amps (75W+) - for larger cabins needing more power
-- Kenwood KAC-M5004, Rockford R2-300x4, R2-500x4, Hertz DP 4.300, Nakamichi NA-4100

UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['City Car', 'MPV', 'SUV', 'Sedan', 'Hatchback', 'Pickup'],
    mp_recommended_car_sizes = ARRAY['small', 'medium', 'large']
WHERE mp_category = 'amplifier' 
  AND (mp_power_spec LIKE '%40W%' OR mp_power_spec LIKE '%50W%' OR mp_power_spec LIKE '%60W%');

-- Lower power amps (40-60W) - compact, suitable for city cars too
-- Kenwood KAC-M3004, JVC KS-AX302, DHD 1040, Skeleton SK-288

-- Budget amplifiers - universal
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['City Car', 'MPV', 'SUV', 'Sedan', 'Hatchback', 'Pickup', 'Van'],
    mp_recommended_car_sizes = ARRAY['small', 'medium', 'large']
WHERE mp_category = 'amplifier' 
  AND mp_price < 700000;

-- ============================================================================
-- AMPLIFIER MONO - For subwoofer, power depends on cabin
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'amplifier_mono';

-- Mono amps for serious subwoofer setups - larger vehicles
-- Hertz DP 1.500, Rockford R2-500X1, T500.1BD

-- ============================================================================
-- PROCESSOR/DSP - Universal, but more relevant for complex setups
-- ============================================================================
UPDATE sales.master_products 
SET mp_compatible_car_types = ARRAY['MPV', 'SUV', 'Sedan', 'Hatchback', 'Van'],
    mp_recommended_car_sizes = ARRAY['medium', 'large']
WHERE mp_category = 'processor';

-- Cello Magic 4.6 Pro, etc - more useful in larger cabins with multiple zones

-- ============================================================================
-- VERIFY UPDATES
-- ============================================================================
-- Check how many products got updated
-- SELECT mp_category, mp_compatible_car_types, mp_recommended_car_sizes, COUNT(*)
-- FROM sales.master_products
-- GROUP BY mp_category, mp_compatible_car_types, mp_recommended_car_sizes
-- ORDER BY mp_category, COUNT(*) DESC;
