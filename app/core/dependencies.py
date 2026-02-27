from fastapi import Depends
from app.services.database_service import get_database_service, DatabaseService
from app.services.redis_service import get_redis_service, RedisService
from app.services.embedding_service import get_embedding_service, EmbeddingService
from app.services.llm_service import get_llm_service, LLMService

# Re-exporting for easy imports
__all__ = [
    "get_db",
    "get_redis",
    "get_embedding_service_dep",
    "get_llm_service_dep"
]

async def get_db() -> DatabaseService:
    return await get_database_service()

async def get_redis() -> RedisService:
    return await get_redis_service()

def get_embedding_service_dep() -> EmbeddingService:
    return get_embedding_service()

def get_llm_service_dep() -> LLMService:
    return get_llm_service()
