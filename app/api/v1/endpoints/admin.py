from fastapi import APIRouter, Depends, HTTPException, Query
from app.core.dependencies import get_db, get_embedding_service_dep
from app.services.database_service import DatabaseService
from app.services.embedding_service import EmbeddingService
import logging
import httpx

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/sync-embeddings")
async def sync_embeddings(
    db: DatabaseService = Depends(get_db),
    embedding_service: EmbeddingService = Depends(get_embedding_service_dep),
    batch_size: int = Query(20, description="Number of items to process per call (default 20)")
):
    """
    Synchronizes data with vector embeddings from VoyageAI.
    Uses BATCH embedding (up to 100 texts in 1 API call) for speed.
    
    Usage:
    POST /api/v1/admin/sync-embeddings?batch_size=20
    
    Call multiple times until status shows "complete".
    If you get rate limited (429), wait 21 seconds and call again.
    """
    stats = {"problems_synced": 0, "products_synced": 0, "errors": [], "remaining": 0}

    try:
        # 1. Get unembedded problems
        unembedded_problems = await db.get_unembedded_problems()
        problems_to_process = unembedded_problems[:batch_size]
        
        if problems_to_process:
            try:
                # Batch embed all problems in ONE API call
                texts = [f"{p['mcp_problem_title']}: {p['mcp_description'] or ''}" for p in problems_to_process]
                embeddings = await embedding_service.get_embeddings(texts, input_type="document")
                
                for prob, embedding in zip(problems_to_process, embeddings):
                    try:
                        await db.update_problem_embedding(str(prob['mcp_id']), embedding)
                        stats["problems_synced"] += 1
                    except Exception as e:
                        logger.error(f"Error syncing problem {prob['mcp_id']}: {e}")
                        stats["errors"].append(f"Problem {prob['mcp_id']}: {str(e)}")
            except httpx.HTTPStatusError as e:
                if e.response.status_code == 429:
                    return {
                        "message": "Rate limited by VoyageAI. Wait 21 seconds and call again.",
                        "status": "rate_limited",
                        "stats": stats
                    }
                raise

        # 2. Get unembedded products (fill remaining batch slots)
        remaining_slots = batch_size - stats["problems_synced"]
        if remaining_slots > 0:
            unembedded_products = await db.get_unembedded_products()
            products_to_process = unembedded_products[:remaining_slots]
            
            if products_to_process:
                try:
                    # Batch embed all products in ONE API call
                    texts = [f"{p['mp_name']} ({p['mp_category']}): {p['mp_description'] or ''}" for p in products_to_process]
                    embeddings = await embedding_service.get_embeddings(texts, input_type="document")
                    
                    for prod, embedding in zip(products_to_process, embeddings):
                        try:
                            await db.update_product_embedding(str(prod['mp_id']), embedding)
                            stats["products_synced"] += 1
                        except Exception as e:
                            logger.error(f"Error syncing product {prod['mp_id']}: {e}")
                            stats["errors"].append(f"Product {prod['mp_id']}: {str(e)}")
                except httpx.HTTPStatusError as e:
                    if e.response.status_code == 429:
                        return {
                            "message": "Rate limited by VoyageAI. Wait 21 seconds and call again.",
                            "status": "rate_limited",
                            "stats": stats
                        }
                    raise

        # 3. Count remaining
        remaining_problems = await db.get_unembedded_problems()
        remaining_products = await db.get_unembedded_products()
        stats["remaining"] = len(remaining_problems) + len(remaining_products)

        is_complete = stats["remaining"] == 0
        
        return {
            "message": "Synchronization complete!" if is_complete else f"Processed {stats['problems_synced']} problems and {stats['products_synced']} products. Call again to continue.",
            "status": "complete" if is_complete else "in_progress",
            "stats": stats
        }

    except Exception as e:
        logger.error(f"Critical error during embedding synchronization: {e}")
        raise HTTPException(status_code=500, detail=str(e))
