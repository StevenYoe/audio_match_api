from fastapi import APIRouter, Depends, HTTPException
from app.core.dependencies import get_db, get_embedding_service_dep
from app.services.database_service import DatabaseService
from app.services.embedding_service import EmbeddingService
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/sync-embeddings")
async def sync_embeddings(
    db: DatabaseService = Depends(get_db),
    embedding_service: EmbeddingService = Depends(get_embedding_service_dep)
):
    """
    Synchronizes data with vector embeddings from VoyageAI.
    Embeds both problems and products that don't have embeddings yet.
    """
    stats = {"problems_synced": 0, "products_synced": 0, "errors": []}

    try:
        # 1. Sync Problems
        unembedded_problems = await db.get_unembedded_problems()
        for prob in unembedded_problems:
            try:
                text_to_embed = f"{prob['mcp_problem_title']}: {prob['mcp_description'] or ''}"
                embedding = await embedding_service.get_embedding(text_to_embed, input_type="document")
                await db.update_problem_embedding(str(prob['mcp_id']), embedding)
                stats["problems_synced"] += 1
            except Exception as e:
                logger.error(f"Error syncing problem {prob['mcp_id']}: {e}")
                stats["errors"].append(f"Problem {prob['mcp_id']}: {str(e)}")

        # 2. Sync Products
        unembedded_products = await db.get_unembedded_products()
        for prod in unembedded_products:
            try:
                text_to_embed = f"{prod['mp_name']} ({prod['mp_category']}): {prod['mp_description'] or ''}"
                embedding = await embedding_service.get_embedding(text_to_embed, input_type="document")
                await db.update_product_embedding(str(prod['mp_id']), embedding)
                stats["products_synced"] += 1
            except Exception as e:
                logger.error(f"Error syncing product {prod['mp_id']}: {e}")
                stats["errors"].append(f"Product {prod['mp_id']}: {str(e)}")

        return {
            "message": "Synchronization complete.",
            "status": "partial_success" if stats["errors"] else "success",
            "stats": stats
        }

    except Exception as e:
        logger.error(f"Critical error during embedding synchronization: {e}")
        raise HTTPException(status_code=500, detail=str(e))
