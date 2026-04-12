from fastapi import APIRouter, Depends, HTTPException, Query
from app.core.dependencies import get_db, get_embedding_service_dep
from app.services.database_service import DatabaseService
from app.services.embedding_service import EmbeddingService
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/sync-embeddings")
async def sync_embeddings(
    db: DatabaseService = Depends(get_db),
    embedding_service: EmbeddingService = Depends(get_embedding_service_dep),
    batch_size: int = Query(10, description="Number of items to process per call (default 10)")
):
    """
    Synchronizes data with vector embeddings from VoyageAI.
    Processes in batches to avoid Vercel serverless timeout.
    Call this endpoint multiple times until all items are synced.
    
    Usage:
    POST /api/v1/admin/sync-embeddings?batch_size=10
    
    Each call processes up to batch_size items. With 128 items and batch_size=10,
    you'll need to call it ~13 times.
    """
    stats = {"problems_synced": 0, "products_synced": 0, "errors": [], "remaining": 0}

    try:
        # 1. Sync Problems (up to batch_size)
        unembedded_problems = await db.get_unembedded_problems()
        problems_to_process = unembedded_problems[:batch_size]
        
        for prob in problems_to_process:
            try:
                text_to_embed = f"{prob['mcp_problem_title']}: {prob['mcp_description'] or ''}"
                embedding = await embedding_service.get_embedding(text_to_embed, input_type="document")
                await db.update_problem_embedding(str(prob['mcp_id']), embedding)
                stats["problems_synced"] += 1
            except Exception as e:
                logger.error(f"Error syncing problem {prob['mcp_id']}: {e}")
                stats["errors"].append(f"Problem {prob['mcp_id']}: {str(e)}")

        # Calculate remaining batch slots for products
        processed_count = stats["problems_synced"]
        remaining_slots = max(0, batch_size - processed_count)

        # 2. Sync Products (up to remaining slots)
        if remaining_slots > 0:
            unembedded_products = await db.get_unembedded_products()
            products_to_process = unembedded_products[:remaining_slots]
            
            for prod in products_to_process:
                try:
                    text_to_embed = f"{prod['mp_name']} ({prod['mp_category']}): {prod['mp_description'] or ''}"
                    embedding = await embedding_service.get_embedding(text_to_embed, input_type="document")
                    await db.update_product_embedding(str(prod['mp_id']), embedding)
                    stats["products_synced"] += 1
                except Exception as e:
                    logger.error(f"Error syncing product {prod['mp_id']}: {e}")
                    stats["errors"].append(f"Product {prod['mp_id']}: {str(e)}")

        # 3. Count remaining items
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
