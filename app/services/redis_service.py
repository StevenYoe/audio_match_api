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
    # Ambil URL dan Token, bersihkan dari spasi atau tanda petik yang tidak sengaja
    raw_url = settings.UPSTASH_REDIS_REST_URL.strip().strip('"').strip("'")
    token = settings.UPSTASH_REDIS_REST_TOKEN.strip().strip('"').strip("'")
    
    redis_url = raw_url
    # Jika URL yang diberikan diawali dengan https:// (REST URL), kita ubah ke protokol redis
    if redis_url.startswith("https://"):
        redis_url = redis_url.replace("https://", "rediss://")
    
    # Jika tidak ada skema sama sekali, tambahkan rediss://
    if "://" not in redis_url:
        redis_url = f"rediss://{redis_url}"
    
    # Pastikan ada port (Upstash default 6379)
    if ":" not in redis_url.replace("rediss://", ""):
        redis_url = f"{redis_url}:6379"
    
    # Menambahkan password/token ke URL
    # Format akhir yang diinginkan: rediss://:TOKEN@HOSTNAME:PORT
    if "@" not in redis_url:
        parts = redis_url.split("://")
        if len(parts) == 2:
            redis_url = f"{parts[0]}://:{token}@{parts[1]}"

    return redis.from_url(
        redis_url,
        decode_responses=True,
        ssl_cert_reqs=None
    )

redis_client = None

async def get_redis_service() -> RedisService:
    global redis_client
    if redis_client is None:
        redis_client = await get_redis_client()
    return RedisService(redis_client)
