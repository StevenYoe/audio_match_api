CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector";

CREATE SCHEMA IF NOT EXISTS sales;

CREATE TABLE sales.master_products (
    mp_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mp_name TEXT NOT NULL,
    mp_category TEXT NOT NULL, 
    mp_brand TEXT,
    mp_price NUMERIC(12,2),
    mp_description TEXT,
    mp_features TEXT[],
    mp_power_spec TEXT,
    mp_is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON sales.master_products(mp_category);
CREATE INDEX idx_products_active ON sales.master_products(mp_is_active);

CREATE TABLE sales.master_customer_problems (
    mcp_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mcp_problem_title TEXT NOT NULL,
    mcp_keywords TEXT[],
    mcp_description TEXT,
    mcp_embedding VECTOR(1024),
    mcp_is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_problems_active ON sales.master_customer_problems(mcp_is_active);

CREATE INDEX idx_problems_embedding 
ON sales.master_customer_problems 
USING ivfflat (mcp_embedding vector_cosine_ops) 
WITH (lists = 100);

CREATE TABLE sales.master_solutions (
    ms_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ms_problem_id UUID REFERENCES sales.master_customer_problems(mcp_id) ON DELETE CASCADE,
    ms_title TEXT NOT NULL,
    ms_description TEXT,
    ms_priority INTEGER DEFAULT 1,
    ms_requires_clarification BOOLEAN DEFAULT TRUE,
    ms_is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_solutions_problem ON sales.master_solutions(ms_problem_id);
CREATE INDEX idx_solutions_active ON sales.master_solutions(ms_is_active);

CREATE TABLE sales.master_solution_products (
    msp_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    msp_solution_id UUID REFERENCES sales.master_solutions(ms_id) ON DELETE CASCADE,
    msp_product_id UUID REFERENCES sales.master_products(mp_id) ON DELETE CASCADE
);

CREATE INDEX idx_solution_products_solution 
ON sales.master_solution_products(msp_solution_id);

CREATE INDEX idx_solution_products_product 
ON sales.master_solution_products(msp_product_id);

CREATE TABLE sales.master_knowledge_chunks (
    mkc_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mkc_content TEXT NOT NULL,
    mkc_intent TEXT,
    mkc_embedding VECTOR(1024),
    mkc_metadata JSONB DEFAULT '{}',
    mkc_is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chunks_active 
ON sales.master_knowledge_chunks(mkc_is_active);

CREATE INDEX idx_chunks_embedding 
ON sales.master_knowledge_chunks 
USING ivfflat (mkc_embedding vector_cosine_ops) 
WITH (lists = 100);

CREATE TABLE sales.trx_conversation_sessions (
    tcs_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tcs_user_identifier TEXT,
    tcs_started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tcs_last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    tcs_is_active BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_sessions_user 
ON sales.trx_conversation_sessions(tcs_user_identifier);

CREATE TABLE sales.trx_chat_messages (
    tcm_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tcm_session_id UUID REFERENCES sales.trx_conversation_sessions(tcs_id) ON DELETE CASCADE,
    tcm_role TEXT NOT NULL,
    tcm_content TEXT NOT NULL,
    tcm_related_problem UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_session
ON sales.trx_chat_messages(tcm_session_id);

-- ============================================================================
-- CAR SUPPORT TABLES (Added 2026-04-14)
-- ============================================================================

CREATE TABLE sales.master_cars (
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

CREATE INDEX idx_cars_brand ON sales.master_cars(mc_brand);
CREATE INDEX idx_cars_model ON sales.master_cars(mc_model);
CREATE INDEX idx_cars_type ON sales.master_cars(mc_type);
CREATE INDEX idx_cars_active ON sales.master_cars(mc_is_active);
CREATE INDEX idx_cars_brand_model ON sales.master_cars(mc_brand, mc_model);

-- Car compatibility columns for master_products
ALTER TABLE sales.master_products 
ADD COLUMN IF NOT EXISTS mp_compatible_car_types TEXT[] DEFAULT NULL;

ALTER TABLE sales.master_products 
ADD COLUMN IF NOT EXISTS mp_recommended_car_sizes TEXT[] DEFAULT NULL;

CREATE OR REPLACE FUNCTION sales.search_problem(
    query_embedding VECTOR(1024),
    match_threshold FLOAT DEFAULT 0.70,
    match_count INT DEFAULT 3
)
RETURNS TABLE (
    mcp_id UUID,
    mcp_problem_title TEXT,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.mcp_id,
        p.mcp_problem_title,
        1 - (p.mcp_embedding <=> query_embedding) AS similarity
    FROM sales.master_customer_problems p
    WHERE p.mcp_is_active = TRUE
      AND p.mcp_embedding IS NOT NULL
      AND 1 - (p.mcp_embedding <=> query_embedding) > match_threshold
    ORDER BY p.mcp_embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sales.get_recommendations(
    problem_id UUID
)
RETURNS TABLE (
    solution_id UUID,
    solution_title TEXT,
    solution_description TEXT,
    product_id UUID,
    product_name TEXT,
    product_category TEXT,
    product_price NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.ms_id,
        s.ms_title,
        s.ms_description,
        p.mp_id,
        p.mp_name,
        p.mp_category,
        p.mp_price
    FROM sales.master_solutions s
    JOIN sales.master_solution_products sp 
        ON sp.msp_solution_id = s.ms_id
    JOIN sales.master_products p 
        ON p.mp_id = sp.msp_product_id
    WHERE s.ms_problem_id = problem_id
      AND s.ms_is_active = TRUE
      AND p.mp_is_active = TRUE
    ORDER BY s.ms_priority ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sales.search_knowledge(
    query_embedding VECTOR(1024),
    match_threshold FLOAT DEFAULT 0.70,
    match_count INT DEFAULT 5
)
RETURNS TABLE (
    mkc_id UUID,
    mkc_content TEXT,
    similarity FLOAT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        k.mkc_id,
        k.mkc_content,
        1 - (k.mkc_embedding <=> query_embedding) AS similarity
    FROM sales.master_knowledge_chunks k
    WHERE k.mkc_is_active = TRUE
      AND k.mkc_embedding IS NOT NULL
      AND 1 - (k.mkc_embedding <=> query_embedding) > match_threshold
    ORDER BY k.mkc_embedding <=> query_embedding
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- CAR-RELATED FUNCTIONS (Added 2026-04-14)
-- ============================================================================

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
    similarity FLOAT
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
        CASE 
            WHEN LOWER(c.mc_brand) = LOWER(search_brand) AND LOWER(c.mc_model) = LOWER(search_model) THEN 1.0
            WHEN LOWER(c.mc_brand) = LOWER(search_brand) THEN 0.8
            WHEN LOWER(c.mc_model) = LOWER(search_model) THEN 0.7
            WHEN LOWER(c.mc_type) = LOWER(search_brand) THEN 0.6
            ELSE 0.5
        END AS similarity
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
