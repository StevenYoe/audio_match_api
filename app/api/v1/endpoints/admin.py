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
    Synchronizes manual data entries with vector embeddings from VoyageAI.
    Embeds both 'master_customer_problems' (title + description) and 'master_knowledge_chunks' (content).
    """
    stats = {"problems_synced": 0, "knowledge_synced": 0, "errors": []}
    
    try:
        # 1. Sync Problems
        unembedded_problems = await db.get_unembedded_problems()
        for prob in unembedded_problems:
            try:
                # Combine title and description for better context
                text_to_embed = f"{prob['mcp_problem_title']}: {prob['mcp_description'] or ''}"
                embedding = await embedding_service.get_embedding(text_to_embed, input_type="document")
                await db.update_problem_embedding(str(prob['mcp_id']), embedding)
                stats["problems_synced"] += 1
            except Exception as e:
                logger.error(f"Error syncing problem {prob['mcp_id']}: {e}")
                stats["errors"].append(f"Problem {prob['mcp_id']}: {str(e)}")

        # 2. Sync Knowledge Chunks
        unembedded_knowledge = await db.get_unembedded_knowledge()
        for chunk in unembedded_knowledge:
            try:
                embedding = await embedding_service.get_embedding(chunk['mkc_content'], input_type="document")
                await db.update_knowledge_embedding(str(chunk['mkc_id']), embedding)
                stats["knowledge_synced"] += 1
            except Exception as e:
                logger.error(f"Error syncing knowledge chunk {chunk['mkc_id']}: {e}")
                stats["errors"].append(f"Knowledge {chunk['mkc_id']}: {str(e)}")

        return {
            "message": "Synchronization complete.",
            "status": "partial_success" if stats["errors"] else "success",
            "stats": stats
        }

    except Exception as e:
        logger.error(f"Critical error during embedding synchronization: {e}")
        raise HTTPException(status_code=500, detail=str(e))
