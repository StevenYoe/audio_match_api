-- ============================================================================
-- MIGRATION 1: Create master_cars and car_product_compatibility tables
-- ============================================================================
-- Purpose: Add car type awareness to the recommendation system
-- Date: 2026-04-14
-- ============================================================================

-- Step 1: Create master_cars table
-- Stores information about car models popular in Indonesia
CREATE TABLE IF NOT EXISTS sales.master_cars (
    mc_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mc_brand TEXT NOT NULL,
    mc_model TEXT NOT NULL,
    mc_type TEXT, -- e.g., 'MPV', 'SUV', 'City Car', 'Sedan', 'Hatchback', 'Pickup'
    mc_size_category TEXT NOT NULL, -- 'small', 'medium', 'large'
    mc_dashboard_type TEXT NOT NULL DEFAULT 'double_din', -- 'single_din', 'double_din', 'android_custom'
    mc_door_count INTEGER DEFAULT 4,
    mc_cabin_volume TEXT, -- approximate description
    mc_subwoofer_space TEXT, -- 'spacious', 'moderate', 'limited', 'underseat_only'
    mc_factory_speaker_size TEXT, -- e.g., '6.5 inch', '5.25 inch', '6x9 inch'
    mc_factory_speaker_count INTEGER DEFAULT 2, -- number of factory speakers
    mc_special_notes TEXT, -- special installation notes
    mc_is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for master_cars
CREATE INDEX idx_cars_brand ON sales.master_cars(mc_brand);
CREATE INDEX idx_cars_model ON sales.master_cars(mc_model);
CREATE INDEX idx_cars_type ON sales.master_cars(mc_type);
CREATE INDEX idx_cars_active ON sales.master_cars(mc_is_active);
CREATE INDEX idx_cars_brand_model ON sales.master_cars(mc_brand, mc_model);

-- Step 2: Add car compatibility column to master_products
-- This links products to compatible car types
ALTER TABLE sales.master_products 
ADD COLUMN IF NOT EXISTS mp_compatible_car_types TEXT[] DEFAULT NULL;

-- This stores array of car types that this product is suitable for
-- e.g., ['MPV', 'SUV', 'Sedan'] or ['City Car', 'Hatchback']
-- If NULL, product is compatible with ALL car types

-- Step 3: Add recommended car size column
-- Stores which cabin sizes this product is best for
ALTER TABLE sales.master_products 
ADD COLUMN IF NOT EXISTS mp_recommended_car_sizes TEXT[] DEFAULT NULL;

-- e.g., ['medium', 'large'] for powerful amplifiers
-- e.g., ['small', 'medium'] for compact solutions
-- If NULL, product is suitable for ALL sizes

-- Step 4: Create car-specific recommendation problems
-- These problems will be matched when user mentions specific car types
INSERT INTO sales.master_customer_problems 
    (mcp_id, mcp_problem_title, mcp_keywords, mcp_description, mcp_recommended_approach, mcp_is_active, created_at)
VALUES 
    (
        'a1a2a3a4-b1b2-c1c2-d1d2-e1e2e3e4e5e6',
        'Rekomendasi audio untuk mobil MPV besar (Xpander, Avanza, Xenia, Innova)',
        ARRAY['mpv', 'xpander', 'avanza', 'xenia', 'innova', 'mobil besar', '7 seater', 'multi purpose'],
        'Customer memiliki mobil MPV berukuran besar dan butuh sistem audio yang cocok untuk kabin luas dengan 7 kursi.',
        E'1. Head Unit Android 9-10 inch untuk dashboard double DIN\n2. Speaker component 6.5 inch untuk depan (door speaker)\n3. Speaker coaxial 6x9 inch untuk belakang (deck)\n4. Subwoofer 10-12 inch boxed (ruang bagasi luas)\n5. Amplifier 4 channel 75W+ untuk power cukup\n6. Processor DSP untuk tuning multi-zone',
        TRUE,
        CURRENT_TIMESTAMP
    ),
    (
        'b2b3b4b5-c2c3-d2d3-e2e3-f2f3f4f5f6f7',
        'Rekomendasi audio untuk mobil City Car kecil (Brio, Agya, Ayla, Mobilio)',
        ARRAY['city car', 'brio', 'agya', 'ayla', 'mobilio', 'mobil kecil', 'hatchback kecil', 'compact'],
        'Customer memiliki mobil berukuran kecil dan butuh sistem audio yang compact, tidak terlalu besar, tapi tetap berkualitas.',
        E'1. Head Unit single/double DIN sesuai dashboard\n2. Speaker coaxial 5.25-6.5 inch (sesuaikan lubang)\n3. Subwoofer kolong/underseat slim (space terbatas)\n4. Amplifier compact 4 channel 50W (ukuran kecil)\n5. Hindari subwoofer boxed besar (tidak muat)',
        TRUE,
        CURRENT_TIMESTAMP
    ),
    (
        'c3c4c5c6-d3d4-e3e4-f3f4-a3a4a5a6a7a8',
        'Rekomendasi audio untuk SUV menengah (Tucson, Santa Fe, CR-V, Fortuner, Pajero)',
        ARRAY['suv', 'tucson', 'santa fe', 'crv', 'fortuner', 'pajero', 'sport utility', 'crossover'],
        'Customer memiliki SUV menengah dengan kabin sedang hingga besar, butuh audio dengan power dan kualitas premium.',
        E'1. Head Unit Android 9 inch premium dengan DSP\n2. Speaker component premium 6.5 inch\n3. Speaker coaxial 6x9 inch untuk deck\n4. Subwoofer 10-12 inch dengan amplifier dedicated\n5. Amplifier 4 channel + mono untuk full system\n6. Sound deadening untuk reduksi noise jalan',
        TRUE,
        CURRENT_TIMESTAMP
    ),
    (
        'd4d5d6d7-e4e5-f4f5-a4a5-b4b5b6b7b8b9',
        'Rekomendasi audio untuk Sedan (Civic, Accord, Camry, Corolla)',
        ARRAY['sedan', 'civic', 'accord', 'camry', 'corolla', 'corolla altis'],
        'Customer memiliki sedan dan ingin upgrade audio dengan soundstage yang detail dan accurate.',
        E'1. Head Unit dengan DAC bagus dan DSP built-in\n2. Speaker component 2-way untuk staging depan\n3. Tweeter separate untuk soundstage lebar\n4. Subwoofer 10 inch sealed box (bass tight)\n5. Amplifier 4 channel low THD untuk kejernihan\n6. Focus pada sound quality, bukan SPL',
        TRUE,
        CURRENT_TIMESTAMP
    ),
    (
        'e5e6e7e8-f5f6-a5a6-b5b6-c5c6c7c8c9c0',
        'Rekomendasi audio untuk Pickup/Truck (L300, Carry, Grand Max)',
        ARRAY['pickup', 'truck', 'l300', 'carry', 'grand max', 'niaga', 'commercial'],
        'Customer memiliki kendaraan niaga/pickup dan butuh audio yang tahan banting untuk penggunaan harian.',
        E'1. Head Unit budget-friendly dengan Bluetooth\n2. Speaker coaxial budget (tahan vibrasi)\n3. Subwoofer aktif kolong (space efisien)\n4. Amplifier compact Class D (tahan panas)\n5. Prioritaskan durability dan value for money',
        TRUE,
        CURRENT_TIMESTAMP
    );

-- Step 5: Create helper function to get car by name
-- This function searches for cars by brand and/or model
CREATE OR REPLACE FUNCTION sales.search_car(
    search_brand TEXT,
    search_model TEXT
)
RETURNS TABLE (
    mc_id UUID,
    mc_brand TEXT,
    mc_model TEXT,
    mc_type TEXT,
    mc_size_category TEXT,
    mc_dashboard_type TEXT,
    mc_door_count INTEGER,
    mc_cabin_volume TEXT,
    mc_subwoofer_space TEXT,
    mc_factory_speaker_size TEXT,
    mc_factory_speaker_count INTEGER,
    mc_special_notes TEXT,
    similarity DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.mc_id,
        c.mc_brand,
        c.mc_model,
        c.mc_type,
        c.mc_size_category,
        c.mc_dashboard_type,
        c.mc_door_count,
        c.mc_cabin_volume,
        c.mc_subwoofer_space,
        c.mc_factory_speaker_size,
        c.mc_factory_speaker_count,
        c.mc_special_notes,
        CAST(CASE 
            WHEN LOWER(c.mc_brand) = LOWER(search_brand) AND LOWER(c.mc_model) = LOWER(search_model) THEN 1.0
            WHEN LOWER(c.mc_brand) = LOWER(search_brand) THEN 0.8
            WHEN LOWER(c.mc_model) = LOWER(search_model) THEN 0.7
            WHEN LOWER(c.mc_type) = LOWER(search_brand) THEN 0.6
            ELSE 0.5
        END AS DOUBLE PRECISION) AS similarity
    FROM sales.master_cars c
    WHERE c.mc_is_active = TRUE
      AND (
          LOWER(c.mc_brand) = LOWER(search_brand)
          OR LOWER(c.mc_model) = LOWER(search_model)
          OR LOWER(c.mc_type) = LOWER(search_brand)
          OR LOWER(c.mc_brand || ' ' || c.mc_model) LIKE '%' || LOWER(search_brand) || '%'
          OR LOWER(c.mc_model) LIKE '%' || LOWER(search_model) || '%'
      )
    ORDER BY similarity DESC
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Create helper function to get compatible products for a car
CREATE OR REPLACE FUNCTION sales.get_products_for_car(
    car_id UUID DEFAULT NULL,
    car_type TEXT DEFAULT NULL,
    car_size TEXT DEFAULT NULL
)
RETURNS TABLE (
    mp_id UUID,
    mp_name TEXT,
    mp_category TEXT,
    mp_brand TEXT,
    mp_price NUMERIC(12,2),
    mp_description TEXT,
    mp_image TEXT,
    compatibility_score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.mp_id,
        p.mp_name,
        p.mp_category,
        p.mp_brand,
        p.mp_price,
        p.mp_description,
        p.mp_image,
        CASE
            -- Perfect match: product explicitly compatible with this car's type and size
            WHEN p.mp_compatible_car_types IS NOT NULL 
                 AND p.mp_recommended_car_sizes IS NOT NULL
                 AND (car_type = ANY(p.mp_compatible_car_types) OR car_type IS NULL)
                 AND (car_size = ANY(p.mp_recommended_car_sizes) OR car_size IS NULL)
            THEN 100
            
            -- Good match: compatible with car type
            WHEN p.mp_compatible_car_types IS NOT NULL 
                 AND (car_type = ANY(p.mp_compatible_car_types) OR car_type IS NULL)
            THEN 80
            
            -- Decent match: compatible with car size
            WHEN p.mp_recommended_car_sizes IS NOT NULL 
                 AND (car_size = ANY(p.mp_recommended_car_sizes) OR car_size IS NULL)
            THEN 70
            
            -- Universal product (no restrictions)
            WHEN p.mp_compatible_car_types IS NULL 
                 AND p.mp_recommended_car_sizes IS NULL
            THEN 60
            
            -- Not ideal but still available
            ELSE 50
        END AS compatibility_score
    FROM sales.master_products p
    WHERE p.mp_is_active = TRUE
    ORDER BY 
        compatibility_score DESC,
        p.mp_category,
        p.mp_price DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE sales.master_cars IS 'Catalog of car models with audio installation specifications';
COMMENT ON COLUMN sales.master_products.mp_compatible_car_types IS 'Array of car types this product is suitable for (MPV, SUV, City Car, Sedan, etc). NULL = universal compatibility';
COMMENT ON COLUMN sales.master_products.mp_recommended_car_sizes IS 'Array of cabin sizes this product works best for (small, medium, large). NULL = suitable for all sizes';
