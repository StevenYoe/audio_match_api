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
    # Upstash menyediakan Redis URL yang diawali dengan rediss://
    # Jika URL yang diberikan diawali dengan https:// (REST URL), kita coba ubah ke protokol redis
    redis_url = settings.UPSTASH_REDIS_REST_URL
    if redis_url.startswith("https://"):
        redis_url = redis_url.replace("https://", "rediss://")
    
    # Menambahkan password ke URL jika belum ada
    if settings.UPSTASH_REDIS_REST_TOKEN and "@" not in redis_url:
        # Format: rediss://:password@hostname:port
        parts = redis_url.split("://")
        if len(parts) == 2:
            redis_url = f"{parts[0]}://:{settings.UPSTASH_REDIS_REST_TOKEN}@{parts[1]}"

    return redis.from_url(
        redis_url,
        decode_responses=True,
        ssl_cert_reqs=None # Seringkali diperlukan di lingkungan serverless untuk menghindari masalah verifikasi CA
    )

redis_client = None

async def get_redis_service() -> RedisService:
    global redis_client
    if redis_client is None:
        redis_client = await get_redis_client()
    return RedisService(redis_client)
