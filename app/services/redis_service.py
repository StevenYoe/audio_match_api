import redis.asyncio as redis
import json
from typing import Optional, Any, Dict
from urllib.parse import urlparse
from app.core.config import settings

class RedisService:
    def __init__(self, client):
        self.client = client

    async def get(self, key: str) -> Optional[Any]:
        data = await self.client.get(key)
        return json.loads(data) if data else None

    async def set(self, key: str, value: Any, ttl: int):
        await self.client.set(key, json.dumps(value), ex=ttl)

    async def get_session_data(self, session_id: str) -> Optional[Dict[str, Any]]:
        return await self.get(f"session:{session_id}")

    async def set_session_data(self, session_id: str, data: Dict[str, Any]):
        await self.set(f"session:{session_id}", data, ttl=settings.REDIS_SESSION_TTL)

    async def get_cache_data(self, key: str) -> Optional[Any]:
        return await self.get(f"cache:{key}")

    async def set_cache_data(self, key: str, value: Any):
        await self.set(f"cache:{key}", value, ttl=settings.REDIS_CACHE_TTL)

async def get_redis_client():
    # Parse the URL provided in settings
    new_url = urlparse(settings.UPSTASH_REDIS_REST_URL)
    
    # Use port from URL if present, otherwise default to 6379
    # We avoid guessing port from hostname as it can be unreliable
    port = new_url.port or 6379

    return redis.Redis(
        host=new_url.hostname,
        port=port,
        password=settings.UPSTASH_REDIS_REST_TOKEN,
        ssl=True,
        decode_responses=True
    )

redis_client = None

async def get_redis_service() -> RedisService:
    global redis_client
    if redis_client is None:
        redis_client = await get_redis_client()
    return RedisService(redis_client)
