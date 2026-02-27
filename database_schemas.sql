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
