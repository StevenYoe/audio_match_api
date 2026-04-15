# Hybrid Search Implementation Guide

## Overview

This project now implements **true hybrid search** combining:
1. **Dense Retrieval**: Vector similarity search using pgvector (cosine similarity)
2. **Sparse Retrieval**: BM25-style full-text search using PostgreSQL `ts_rank_cd`
3. **Fusion**: Reciprocal Rank Fusion (RRF) to combine both rankings

This is a significant improvement over the previous implementation which only used vector search with lexical fallbacks that were never actually blended.

---

## Architecture

### Search Flow (Before vs After)

#### BEFORE (Cascade/Fallback Only):
```
User Query
  ↓
Car Detection (keyword matching)
  ↓ [if no car]
Vector Search (cosine similarity only)
  ↓ [if no match < 0.4]
Brand Keyword Search (substring matching)
  ↓ [if no brand]
Get All Products (fallback)
```

**Problem**: Each tier was independent. If vector search failed, it discarded results and moved to next tier. No combination of signals.

#### AFTER (True Hybrid):
```
User Query
  ↓
Embed Query → Vector Embedding
  ↓
┌─────────────────────────────────┐
│  Parallel Search (Both Run)     │
│  ┌───────────────────────────┐  │
│  │ Dense: Vector Search      │  │
│  │   - Cosine similarity     │  │
│  │   - Semantic understanding│  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │ Sparse: BM25 FTS          │  │
│  │   - ts_rank_cd scoring    │  │
│  │   - Exact keyword matching│  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
  ↓
Reciprocal Rank Fusion (RRF)
  - Combines both rankings
  - Weighted: 60% vector + 40% BM25
  ↓
Ranked Results with hybrid_score
```

**Benefit**: Both signals are always considered. Queries with exact keywords get high BM25 scores. Queries with semantic meaning get high vector scores. Hybrid score balances both.

---

## Technical Details

### 1. Dense Retrieval (Vector Search)

**Mechanism**: pgvector cosine similarity
```sql
similarity = 1 - (stored_embedding <=> query_embedding)
```

**Embedding Model**: VoyageAI `voyage-3.5-lite` (1024 dimensions)

**Index**: IVFFlat with 100 lists for approximate nearest neighbor (ANN)
```sql
CREATE INDEX idx_problems_embedding 
ON sales.master_customer_problems 
USING ivfflat (mcp_embedding public.vector_cosine_ops) WITH (lists='100');
```

**Strengths**:
- Semantic understanding ("sound kurang bass" → subwoofer problems)
- Paraphrase detection ("audio jelek" = "sound quality buruk")
- Contextual matching beyond keywords

**Weaknesses**:
- May miss exact brand/product name matches
- Requires embeddings to be generated and synced

---

### 2. Sparse Retrieval (BM25 Full-Text Search)

**Mechanism**: PostgreSQL `ts_rank_cd` with `tsvector`/`tsquery`
```sql
ts_rank_cd(
    to_tsvector('indonesian', mcp_problem_title || ' ' || mcp_description),
    plainto_tsquery('indonesian', query_text),
    32  -- normalization option
)
```

**Index**: GIN index on tsvector
```sql
CREATE INDEX idx_problems_fts_title_desc 
ON sales.master_customer_problems 
USING gin (to_tsvector('indonesian', 
    COALESCE(mcp_problem_title, '') || ' ' || COALESCE(mcp_description, '')
));
```

**Language**: Indonesian (`'indonesian'`) - optimized for Bahasa Indonesia stemming

**Strengths**:
- Exact keyword matching ("Kenwood" → Kenwood products)
- Brand name detection ("Pioneer", "JL Audio")
- Product model matching ("BR-Z1", "TS-W300D4")
- No embeddings required (works immediately on new data)

**Weaknesses**:
- No semantic understanding
- Requires exact keyword overlap

---

### 3. Fusion: Reciprocal Rank Fusion (RRF)

**Formula**:
```
RRF_score = Σ (1 / (k + rank_i)) for each method i
```

Where:
- `k = 60` (standard constant that balances top vs lower rankings)
- `rank_i` = position in method i's result list

**Example**:
```
Problem A: vector_rank=2, bm25_rank=5
  vector_rrf = 1 / (60 + 2) = 0.0161
  bm25_rrf = 1 / (60 + 5) = 0.0154
  total_rrf = 0.0315

Problem B: vector_rank=1, bm25_rank=50
  vector_rrf = 1 / (60 + 1) = 0.0164
  bm25_rrf = 1 / (60 + 50) = 0.0091
  total_rrf = 0.0255

Problem A wins despite lower vector score because it appears in both top-5 lists!
```

**Final Hybrid Score**:
```sql
hybrid_score = (0.6 * vector_score) + (0.4 * bm25_score)
```

Weights are tunable:
- Increase `vector_weight` for more semantic behavior
- Increase `bm25_weight` for more keyword-exact behavior

---

## Database Functions

### `sales.search_problem_hybrid()`

Full hybrid search for customer problems with all parameters exposed.

```sql
SELECT * FROM sales.search_problem_hybrid(
    query_text := 'suara kurang bass',
    query_embedding := '[...]',  -- 1024-dim vector
    match_count := 5,
    rrf_k := 60,
    vector_weight := 0.6,
    bm25_weight := 0.4
);
```

**Returns**:
- `mcp_id`, `mcp_problem_title`, `mcp_description`, `mcp_recommended_approach`
- `vector_score`: Raw cosine similarity (0-1)
- `bm25_score`: Raw ts_rank_cd score (0-1)
- `hybrid_score`: Weighted combination
- `vector_rank`: Position in vector results
- `bm25_rank`: Position in BM25 results

### `sales.search_problem_hybrid_simple()`

Simplified wrapper (recommended for Python integration).

```sql
SELECT * FROM sales.search_problem_hybrid_simple(
    query_text := 'suara kurang bass',
    query_embedding := '[...]',
    match_count := 5
);
```

Returns same fields but with fixed parameters (k=60, vector=0.6, bm25=0.4).

### `sales.search_product_hybrid()`

Full hybrid search for products with optional filters.

```sql
SELECT * FROM sales.search_product_hybrid(
    query_text := 'subwoofer 12 inch',
    query_embedding := '[...]',
    match_count := 10,
    rrf_k := 60,
    vector_weight := 0.6,
    bm25_weight := 0.4,
    brand_filter := 'Pioneer',      -- Optional
    category_filter := 'subwoofer'  -- Optional
);
```

### `sales.search_product_hybrid_simple()`

Simplified wrapper for products.

```sql
SELECT * FROM sales.search_product_hybrid_simple(
    query_text := 'subwoofer 12 inch',
    query_embedding := '[...]',
    match_count := 10
);
```

---

## Python Integration

### DatabaseService Methods

```python
# Hybrid search for problems
problems = await db.search_problem_hybrid(
    query_text="audio mobil Brio kurang jelas",
    embedding=embedding_vector,
    match_count=5
)

# Hybrid search for products with brand filter
products = await db.search_product_hybrid(
    query_text="subwoofer 12 inch powerful",
    embedding=embedding_vector,
    match_count=10,
    brand_filter="JL Audio"
)
```

### Chat Endpoint Flow

The chat endpoint (`app/api/v1/endpoints/chat.py`) now uses hybrid search:

1. **Car Detection** (keyword-based, unchanged)
2. **Hybrid Problem Search** (vector + BM25 with RRF)
   - Embeds query using VoyageAI
   - Runs `search_problem_hybrid()` 
   - Returns top matches with hybrid scores
   - Logs vector_score, bm25_score, hybrid_score for debugging
3. **Hybrid Product Search** (fallback, with brand filters)
   - If no problem matched, searches products
   - Applies brand filter if user mentioned brands
   - Returns products ranked by hybrid score

---

## Performance Considerations

### Indexes Created

**Vector Indexes** (IVFFlat for ANN):
```sql
CREATE INDEX idx_problems_embedding 
ON sales.master_customer_problems USING ivfflat (mcp_embedding vector_cosine_ops);

CREATE INDEX idx_products_embedding 
ON sales.master_products USING ivfflat (mp_embedding vector_cosine_ops);
```

**BM25 Indexes** (GIN for FTS):
```sql
CREATE INDEX idx_problems_fts_title_desc 
ON sales.master_customer_problems 
USING gin (to_tsvector('indonesian', mcp_problem_title || ' ' || mcp_description));

CREATE INDEX idx_products_fts_name_desc 
ON sales.master_products 
USING gin (to_tsvector('indonesian', mp_name || ' ' || mp_description));
```

### Query Execution

Both searches run in parallel via CTEs (`WITH` clauses), then results are fused. For small datasets (<1000 records), this executes in <50ms. For larger datasets, consider:

- Increasing `lists` parameter in IVFFlat index (trade accuracy for speed)
- Limiting `max_vector_results` and `max_bm25_results` in the function
- Adding query result caching

---

## Tuning Guide

### Adjusting Weights

**More semantic behavior** (for vague/problem descriptions):
```sql
vector_weight := 0.7, bm25_weight := 0.3
```

**More keyword-exact behavior** (for brand/product name searches):
```sql
vector_weight := 0.4, bm25_weight := 0.6
```

**Balanced** (recommended default):
```sql
vector_weight := 0.6, bm25_weight := 0.4
```

### Adjusting RRF k Parameter

**Lower k (e.g., 30)**: Favors items that appear in BOTH top results
**Higher k (e.g., 100)**: More balanced ranking

Standard value: `k = 60` (used in most research papers)

---

## Migration

Run the migration to add hybrid search:

```bash
psql $DATABASE_URL -f migrations/004_hybrid_search.sql
```

This will:
1. Create GIN indexes for FTS (~5 seconds for 100 records)
2. Create `search_problem_hybrid()` function
3. Create `search_product_hybrid()` function
4. Create simplified wrapper functions
5. Create diagnostic view `v_hybrid_search_comparison`

Verify indexes were created:
```sql
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename IN ('master_customer_problems', 'master_products')
  AND indexname LIKE '%fts%';
```

---

## Testing

### Test Hybrid Search Directly

```sql
-- Test problem search (replace with actual embedding)
SELECT 
    mcp_problem_title,
    vector_score,
    bm25_score,
    hybrid_score,
    vector_rank,
    bm25_rank
FROM sales.search_problem_hybrid(
    'bass terlalu keras di mobil Xpander',
    (SELECT mcp_embedding FROM sales.master_customer_problems LIMIT 1),  -- dummy embedding
    5
);

-- Check which problems have both vector and FTS
SELECT * FROM sales.v_hybrid_search_comparison;
```

### Expected Behavior

| Query Type | Vector Score | BM25 Score | Hybrid Result |
|------------|--------------|------------|---------------|
| "sound quality kurang baik" | High (semantic match) | Low (no exact keyword) | High (vector dominates) |
| "Kenwood BR-Z1" | Low (no embedding) | High (exact brand+model) | High (BM25 dominates) |
| "subwoofer untuk Xpander" | Medium | Medium | Highest (both agree) |
| "bass terlalu keras" | Medium | High | High (BM25 boosts) |

---

## Backward Compatibility

The old `search_problem()` function is **kept** for backward compatibility but marked as DEPRECATED. Existing code using it will continue to work.

To migrate existing code:
```python
# OLD (deprecated)
problems = await db.search_problem(embedding)

# NEW (hybrid)
problems = await db.search_problem_hybrid(query_text, embedding)
```

---

## Future Improvements

1. **Cross-encoder reranking**: Use LLM to rerank top-10 hybrid results
2. **Query expansion**: Auto-expand synonyms before BM25 search
3. **Learning-to-rank**: Train weights based on user click feedback
4. **Multi-lingual FTS**: Add English tsvector index for bilingual queries
5. **HNSW index**: Replace IVFFlat with HNSW for better vector search accuracy

---

## References

- [Reciprocal Rank Fusion (RRF) Paper](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf)
- [PostgreSQL Full-Text Search](https://www.postgresql.org/docs/current/textsearch.html)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [BM25 Algorithm](https://en.wikipedia.org/wiki/Okapi_BM25)
