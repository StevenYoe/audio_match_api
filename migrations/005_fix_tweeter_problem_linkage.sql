-- ============================================================================
-- MIGRATION 5: Fix Tweeter Problem Linkage for Vocal Clarity
-- ============================================================================
-- Purpose: Link tweeter products to the correct problem (vocal clarity)
-- Issue: Hertz Mille Pro tweeter was linked to "Soundstage sempit" instead of
--        "Vocal dan mid range kurang jelas", causing it to not be recommended
--        for vocal clarity issues
-- Date: 2026-04-15
-- ============================================================================

-- Problem IDs:
-- d71440dd-5d04-4bf2-a4ca-c630d21063cc = "Vocal dan mid range kurang jelas"
-- bad8f281-a1ff-4abe-8238-89365e95e58d = "Soundstage sempit, suara terasa datar"

-- Fix Hertz Mille Pro tweeter: Change from soundstage to vocal problem
UPDATE sales.master_products
SET mp_solves_problem_id = 'd71440dd-5d04-4bf2-a4ca-c630d21063cc'
WHERE mp_name = 'Tweeter Hertz Mille Pro MPX 170.30'
  AND mp_solves_problem_id = 'bad8f281-a1ff-4abe-8238-89365e95e58d';

-- Verify the update
SELECT mp_name, mp_brand, mp_category, mp_solves_problem_id,
       (SELECT mcp_problem_title FROM sales.master_customer_problems WHERE mcp_id = mp_solves_problem_id) as problem_title
FROM sales.master_products
WHERE mp_category = 'tweeter';

-- Also verify Kenwood tweeter is correctly linked
SELECT mp_name, mp_brand, mp_category, mp_price, mp_solves_problem_id,
       (SELECT mcp_problem_title FROM sales.master_customer_problems WHERE mcp_id = mp_solves_problem_id) as problem_title
FROM sales.master_products
WHERE mp_category = 'tweeter'
ORDER BY mp_price DESC;
