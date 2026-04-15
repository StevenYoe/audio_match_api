-- ============================================================================
-- MIGRATION 4: Implement Proper Hybrid Search (Vector + BM25/FTS)
-- ============================================================================
-- Purpose: Replace pure vector search with true hybrid search combining:
--   1. Dense retrieval: Vector similarity (cosine similarity via pgvector)
--   2. Sparse retrieval: Full-text search (BM25-style via ts_rank_cd)
--   3. Fusion: Reciprocal Rank Fusion (RRF) to combine both rankings
-- Date: 2026-04-15
-- ============================================================================

-- Step 1: Add GIN indexes for full-text search on problems
-- These indexes enable fast lexical/BM25 search using PostgreSQL tsvector
-- Note: Using generated columns to avoid IMMUTABLE function issues

-- Add generated tsvector column for problems (if it doesn't exist)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'sales' AND table_name = 'master_customer_problems' 
        AND column_name = 'mcp_search_vector'
    ) THEN
        ALTER TABLE sales.master_customer_problems ADD COLUMN mcp_search_vector tsvector
            GENERATED ALWAYS AS (
                to_tsvector('indonesian'::regconfig, 
                    COALESCE(mcp_problem_title, '') || ' ' || COALESCE(mcp_description, '')
                )
            ) STORED;
    END IF;
END $$;

-- Create GIN index on generated column
CREATE INDEX IF NOT EXISTS idx_problems_fts_title_desc
ON sales.master_customer_problems
USING gin (mcp_search_vector);

-- Step 2: Add generated tsvector column for products (if it doesn't exist)
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'sales' AND table_name = 'master_products' 
        AND column_name = 'mp_search_vector'
    ) THEN
        ALTER TABLE sales.master_products ADD COLUMN mp_search_vector tsvector
            GENERATED ALWAYS AS (
                to_tsvector('indonesian'::regconfig, 
                    COALESCE(mp_name, '') || ' ' || COALESCE(mp_description, '') || ' ' ||
                    COALESCE(mp_brand, '') || ' ' || COALESCE(mp_category, '')
                )
            ) STORED;
    END IF;
END $$;

-- Create GIN index on generated column
CREATE INDEX IF NOT EXISTS idx_products_fts_name_desc
ON sales.master_products
USING gin (mp_search_vector);

-- Step 3: Create hybrid search function for problems
-- Combines vector similarity + BM25 full-text search with RRF fusion
CREATE OR REPLACE FUNCTION sales.search_problem_hybrid(
    query_text TEXT,
    query_embedding public.vector DEFAULT NULL,
    match_count integer DEFAULT 5,
    rrf_k integer DEFAULT 60,
    vector_weight double precision DEFAULT 0.6,
    bm25_weight double precision DEFAULT 0.4
)
RETURNS TABLE (
    mcp_id uuid,
    mcp_problem_title text,
    mcp_description text,
    mcp_recommended_approach text,
    vector_score double precision,
    bm25_score double precision,
    hybrid_score double precision,
    vector_rank integer,
    bm25_rank integer
) AS $$
DECLARE
    max_vector_results integer := match_count * 3;
    max_bm25_results integer := match_count * 3;
BEGIN
    -- Hybrid search using Reciprocal Rank Fusion (RRF)
    -- RRF formula: score = Σ (1 / (k + rank)) for each retrieval method
    -- k = 60 is standard (balances top vs lower rankings)
    
    RETURN QUERY
    WITH vector_results AS (
        -- Dense retrieval: Vector similarity search
        SELECT
            p.mcp_id,
            p.mcp_problem_title,
            p.mcp_description,
            p.mcp_recommended_approach,
            1 - (p.mcp_embedding <=> query_embedding) AS similarity,
            ROW_NUMBER() OVER (ORDER BY 1 - (p.mcp_embedding <=> query_embedding) DESC)::integer AS rank
        FROM sales.master_customer_problems p
        WHERE p.mcp_is_active = TRUE
          AND p.mcp_embedding IS NOT NULL
          AND query_embedding IS NOT NULL
          AND 1 - (p.mcp_embedding <=> query_embedding) > 0.3
        ORDER BY similarity DESC
        LIMIT max_vector_results
    ),
    bm25_results AS (
        -- Sparse retrieval: BM25-style full-text search
        SELECT
            p.mcp_id,
            p.mcp_problem_title,
            p.mcp_description,
            p.mcp_recommended_approach,
            ts_rank_cd(
                to_tsvector('indonesian', COALESCE(p.mcp_problem_title, '') || ' ' || COALESCE(p.mcp_description, '')),
                plainto_tsquery('indonesian', query_text),
                32 -- normalization option
            )::DOUBLE PRECISION AS similarity,
            ROW_NUMBER() OVER (
                ORDER BY ts_rank_cd(
                    to_tsvector('indonesian', COALESCE(p.mcp_problem_title, '') || ' ' || COALESCE(p.mcp_description, '')),
                    plainto_tsquery('indonesian', query_text),
                    32
                ) DESC
            )::integer AS rank
        FROM sales.master_customer_problems p
        WHERE p.mcp_is_active = TRUE
          AND to_tsvector('indonesian', COALESCE(p.mcp_problem_title, '') || ' ' || COALESCE(p.mcp_description, '')) 
              @@ plainto_tsquery('indonesian', query_text)
    ),
    all_candidates AS (
        -- Union all candidates from both methods
        SELECT v.mcp_id FROM vector_results v
        UNION
        SELECT b.mcp_id FROM bm25_results b
    ),
    rrf_scores AS (
        -- Calculate RRF scores for each candidate
        SELECT
            c.mcp_id,
            COALESCE((1.0 / (rrf_k + v.rank)), 0.0) AS vector_rrf,
            COALESCE((1.0 / (rrf_k + b.rank)), 0.0) AS bm25_rrf,
            v.mcp_problem_title,
            v.mcp_description,
            v.mcp_recommended_approach,
            v.similarity AS vector_score,
            b.similarity AS bm25_score,
            v.rank AS vector_rank,
            b.rank AS bm25_rank
        FROM all_candidates c
        LEFT JOIN vector_results v ON c.mcp_id = v.mcp_id
        LEFT JOIN bm25_results b ON c.mcp_id = b.mcp_id
    )
    SELECT
        r.mcp_id,
        r.mcp_problem_title,
        r.mcp_description,
        r.mcp_recommended_approach,
        COALESCE(r.vector_score, 0.0),
        COALESCE(r.bm25_score, 0.0),
        -- Weighted hybrid score: combine normalized vector + BM25 scores
        (vector_weight * COALESCE(r.vector_score, 0.0) + bm25_weight * COALESCE(r.bm25_score, 0.0)) AS hybrid_score,
        r.vector_rank,
        r.bm25_rank
    FROM rrf_scores r
    ORDER BY hybrid_score DESC
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create hybrid search function for products
-- Combines vector similarity + BM25 full-text search with RRF fusion
CREATE OR REPLACE FUNCTION sales.search_product_hybrid(
    query_text TEXT,
    query_embedding public.vector DEFAULT NULL,
    match_count integer DEFAULT 10,
    rrf_k integer DEFAULT 60,
    vector_weight double precision DEFAULT 0.6,
    bm25_weight double precision DEFAULT 0.4,
    brand_filter TEXT DEFAULT NULL,
    category_filter TEXT DEFAULT NULL
)
RETURNS TABLE (
    mp_id uuid,
    mp_name text,
    mp_category text,
    mp_brand text,
    mp_price numeric(12,2),
    mp_description text,
    mp_image text,
    mp_solves_problem_id uuid,
    vector_score double precision,
    bm25_score double precision,
    hybrid_score double precision,
    vector_rank integer,
    bm25_rank integer
) AS $$
DECLARE
    max_vector_results integer := match_count * 3;
    max_bm25_results integer := match_count * 3;
BEGIN
    -- Hybrid search for products using RRF fusion
    
    RETURN QUERY
    WITH vector_results AS (
        -- Dense retrieval: Vector similarity search on product embeddings
        SELECT
            p.mp_id,
            p.mp_name,
            p.mp_category,
            p.mp_brand,
            p.mp_price,
            p.mp_description,
            p.mp_image,
            p.mp_solves_problem_id,
            1 - (p.mp_embedding <=> query_embedding) AS similarity,
            ROW_NUMBER() OVER (ORDER BY 1 - (p.mp_embedding <=> query_embedding) DESC)::integer AS rank
        FROM sales.master_products p
        WHERE p.mp_is_active = TRUE
          AND p.mp_embedding IS NOT NULL
          AND query_embedding IS NOT NULL
          AND 1 - (p.mp_embedding <=> query_embedding) > 0.3
          AND (brand_filter IS NULL OR LOWER(p.mp_brand) = LOWER(brand_filter))
          AND (category_filter IS NULL OR LOWER(p.mp_category) = LOWER(category_filter))
        ORDER BY similarity DESC
        LIMIT max_vector_results
    ),
    bm25_results AS (
        -- Sparse retrieval: BM25-style full-text search on product name, description, brand, category
        SELECT
            p.mp_id,
            p.mp_name,
            p.mp_category,
            p.mp_brand,
            p.mp_price,
            p.mp_description,
            p.mp_image,
            p.mp_solves_problem_id,
            ts_rank_cd(
                to_tsvector('indonesian',
                    COALESCE(p.mp_name, '') || ' ' ||
                    COALESCE(p.mp_description, '') || ' ' ||
                    COALESCE(p.mp_brand, '') || ' ' ||
                    COALESCE(p.mp_category, '')
                ),
                plainto_tsquery('indonesian', query_text),
                32 -- normalization option
            )::DOUBLE PRECISION AS similarity,
            ROW_NUMBER() OVER (
                ORDER BY ts_rank_cd(
                    to_tsvector('indonesian',
                        COALESCE(p.mp_name, '') || ' ' ||
                        COALESCE(p.mp_description, '') || ' ' ||
                        COALESCE(p.mp_brand, '') || ' ' ||
                        COALESCE(p.mp_category, '')
                    ),
                    plainto_tsquery('indonesian', query_text),
                    32
                ) DESC
            )::integer AS rank
        FROM sales.master_products p
        WHERE p.mp_is_active = TRUE
          AND to_tsvector('indonesian', 
                COALESCE(p.mp_name, '') || ' ' || 
                COALESCE(p.mp_description, '') || ' ' || 
                COALESCE(p.mp_brand, '') || ' ' || 
                COALESCE(p.mp_category, '')
            ) @@ plainto_tsquery('indonesian', query_text)
          AND (brand_filter IS NULL OR LOWER(p.mp_brand) = LOWER(brand_filter))
          AND (category_filter IS NULL OR LOWER(p.mp_category) = LOWER(category_filter))
    ),
    all_candidates AS (
        -- Union all candidates from both methods
        SELECT v.mp_id FROM vector_results v
        UNION
        SELECT b.mp_id FROM bm25_results b
    ),
    rrf_scores AS (
        -- Calculate RRF scores for each candidate
        SELECT 
            c.mp_id,
            COALESCE((1.0 / (rrf_k + v.rank)), 0.0) AS vector_rrf,
            COALESCE((1.0 / (rrf_k + b.rank)), 0.0) AS bm25_rrf,
            v.mp_name,
            v.mp_category,
            v.mp_brand,
            v.mp_price,
            v.mp_description,
            v.mp_image,
            v.mp_solves_problem_id,
            v.similarity AS vector_score,
            b.similarity AS bm25_score,
            v.rank AS vector_rank,
            b.rank AS bm25_rank
        FROM all_candidates c
        LEFT JOIN vector_results v ON c.mp_id = v.mp_id
        LEFT JOIN bm25_results b ON c.mp_id = b.mp_id
    )
    SELECT 
        r.mp_id,
        r.mp_name,
        r.mp_category,
        r.mp_brand,
        r.mp_price,
        r.mp_description,
        r.mp_image,
        r.mp_solves_problem_id,
        COALESCE(r.vector_score, 0.0),
        COALESCE(r.bm25_score, 0.0),
        -- Weighted hybrid score: combine normalized vector + BM25 scores
        (vector_weight * COALESCE(r.vector_score, 0.0) + bm25_weight * COALESCE(r.bm25_score, 0.0)) AS hybrid_score,
        r.vector_rank,
        r.bm25_rank
    FROM rrf_scores r
    ORDER BY hybrid_score DESC
    LIMIT match_count;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Create simplified wrapper functions for easier Python integration

-- Problem search with automatic embedding (Python passes query text + embedding)
CREATE OR REPLACE FUNCTION sales.search_problem_hybrid_simple(
    query_text TEXT,
    query_embedding public.vector,
    match_count integer DEFAULT 5
)
RETURNS TABLE (
    mcp_id uuid,
    mcp_problem_title text,
    mcp_description text,
    mcp_recommended_approach text,
    similarity double precision
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.mcp_id,
        h.mcp_problem_title,
        h.mcp_description,
        h.mcp_recommended_approach,
        h.hybrid_score AS similarity
    FROM sales.search_problem_hybrid(
        query_text := query_text,
        query_embedding := query_embedding,
        match_count := match_count,
        rrf_k := 60,
        vector_weight := 0.6,
        bm25_weight := 0.4
    ) h;
END;
$$ LANGUAGE plpgsql;

-- Product search with automatic embedding
CREATE OR REPLACE FUNCTION sales.search_product_hybrid_simple(
    query_text TEXT,
    query_embedding public.vector,
    match_count integer DEFAULT 10
)
RETURNS TABLE (
    mp_id uuid,
    mp_name text,
    mp_category text,
    mp_brand text,
    mp_price numeric(12,2),
    mp_description text,
    mp_image text,
    similarity double precision
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        h.mp_id,
        h.mp_name,
        h.mp_category,
        h.mp_brand,
        h.mp_price,
        h.mp_description,
        h.mp_image,
        h.hybrid_score AS similarity
    FROM sales.search_product_hybrid(
        query_text := query_text,
        query_embedding := query_embedding,
        match_count := match_count,
        rrf_k := 60,
        vector_weight := 0.6,
        bm25_weight := 0.4
    ) h;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Add comments for documentation
COMMENT ON FUNCTION sales.search_problem_hybrid IS 'Hybrid search: combines vector similarity + BM25 FTS with RRF fusion for customer problems';
COMMENT ON FUNCTION sales.search_product_hybrid IS 'Hybrid search: combines vector similarity + BM25 FTS with RRF fusion for products';
COMMENT ON FUNCTION sales.search_problem_hybrid_simple IS 'Simplified wrapper for hybrid problem search';
COMMENT ON FUNCTION sales.search_product_hybrid_simple IS 'Simplified wrapper for hybrid product search';

-- Step 7: Create view to show search method comparison (for debugging/monitoring)
CREATE OR REPLACE VIEW sales.v_hybrid_search_comparison AS
SELECT 
    p.mcp_id,
    p.mcp_problem_title,
    p.mcp_description,
    p.mcp_embedding IS NOT NULL AS has_vector,
    to_tsvector('indonesian', COALESCE(p.mcp_problem_title, '') || ' ' || COALESCE(p.mcp_description, '')) IS NOT NULL AS has_fts,
    LENGTH(COALESCE(p.mcp_description, '')) AS desc_length,
    array_length(COALESCE(p.mcp_keywords, ARRAY[]::text[]), 1) AS keyword_count
FROM sales.master_customer_problems p
WHERE p.mcp_is_active = TRUE;

COMMENT ON VIEW sales.v_hybrid_search_comparison IS 'Diagnostic view showing which problems have vector embeddings and FTS indexes';
