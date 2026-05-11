# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the App

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally (requires .env file — see Environment Variables below)
python app/main.py
# or
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

API docs are available at `http://localhost:8000/docs` when `ENABLE_DOCS=True`.

## Running Tests

Tests are standalone scripts (not pytest), run them directly:

```bash
python test_hybrid_search.py
python test_hybrid_simple.py
python test_car_support.py
python test_issues.py
python test_fixes.py
python test_direct_sql.py
```

## Database Migrations

Migrations are SQL files in `migrations/` applied manually:

```bash
python run_migrations.py        # runs all pending migrations
python run_migration_004.py     # runs migration 004 specifically
```

## Environment Variables

Create a `.env` file with the following required keys (all are validated at startup via `settings.validate_critical_settings()`):

```
DATABASE_URL=           # PostgreSQL (Neon) connection string — must support pgvector
VOYAGE_API_KEY=         # VoyageAI API key for embeddings (model: voyage-3.5-lite, 1024 dims)
GEMINI_API_KEY=         # Google Gemini API key for LLM (model: gemini-1.5-flash)
UPSTASH_REDIS_REST_URL= # Upstash Redis URL
UPSTASH_REDIS_REST_TOKEN=
```

## Deployment

The app deploys to Vercel as a serverless function. `api/index.py` re-exports `app.main:app` as `handler`. All routes are rewritten to `/api/index.py` via `vercel.json`.

## Architecture

This is a FastAPI RAG (Retrieval-Augmented Generation) chatbot for a car audio shop. The chat endpoint retrieves relevant products from PostgreSQL, injects them as context into a Gemini LLM prompt, and returns structured product recommendations alongside the LLM response.

### Request Flow (`POST /api/v1/chat/`)

1. **Session management** — conversation history stored in Upstash Redis (key: `session:<uuid>`, TTL 24h)
2. **Context retrieval** (in priority order):
   - Car model detected → `db.search_car()` + `db.get_car_recommendations_context()` (compatibility-scored query)
   - Known audio brand mentioned → `db.get_products_by_brand()` (direct lookup, bypasses hybrid search)
   - Otherwise → `db.search_problem_hybrid()` with VoyageAI embedding → `db.get_recommendations()` for linked products
   - Fallback → `db.search_product_hybrid()` returning up to 30 products
3. **LLM call** — last 8 history messages + system prompt (injected product context) → Gemini native API
4. **Response** — `ChatResponse` containing `response` (LLM text) + `recommendations` (structured product list)

### Database Schema (`sales` schema in PostgreSQL/Neon with pgvector)

- `master_customer_problems` — problems with `mcp_embedding vector(1024)` and BM25 FTS tsvector
- `master_products` — products with `mp_embedding vector(1024)`, FK `mp_solves_problem_id`, and car compatibility arrays (`mp_compatible_car_types[]`, `mp_recommended_car_sizes[]`)
- `master_cars` — car catalog with cabin specs, dashboard type, factory speaker info
- SQL functions: `search_problem_hybrid()`, `search_product_hybrid()`, `search_car()`, `get_products_for_car()` — defined in `database_schemas.sql` and `migrations/`

Hybrid search uses **Reciprocal Rank Fusion (RRF)** combining vector cosine similarity (weight 0.6) and PostgreSQL BM25-style FTS `ts_rank_cd` (weight 0.4).

### Key Services

| Service | File | Purpose |
|---|---|---|
| `DatabaseService` | `app/services/database_service.py` | All DB queries via `asyncpg` connection pool |
| `EmbeddingService` | `app/services/embedding_service.py` | VoyageAI REST API calls with tenacity retry |
| `LLMService` | `app/services/llm_service.py` | Gemini native REST API calls with retry |
| `RedisService` | `app/services/redis_service.py` | Session & cache storage via Upstash Redis |
| `ImportService` | `app/services/import_service.py` | CSV/Excel parsing for bulk product/problem import |

### API Endpoints

- `POST /api/v1/chat/` — main chat with product recommendation
- `POST /api/v1/admin/sync-embeddings?batch_size=20` — generate and store VoyageAI embeddings for items missing them (call repeatedly until `status: "complete"`)
- `POST /api/v1/admin/import-data/` — bulk import products or problems from CSV/Excel

### VoyageAI Rate Limit

The free tier is 3 RPM. `VOYAGE_RATE_LIMIT_DELAY=21` seconds is used as retry delay via tenacity. Embedding sync uses batch calls (up to 100 texts per call) to minimise API calls.

### Car Detection

`_extract_car_mention()` in `chat.py` does keyword matching against a hardcoded map of ~50 Indonesian market car models to `(brand, model, type)` tuples. Car brand-only mentions only trigger car search when a car type keyword (mpv/suv/etc.) is also present.
