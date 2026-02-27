import httpx
from typing import List
from tenacity import retry, stop_after_attempt, wait_fixed, retry_if_exception_type
from app.core.config import settings

class EmbeddingService:
    def __init__(self, client: httpx.AsyncClient):
        self.client = client
        self.api_url = "https://api.voyageai.com/v1/embeddings"
        self.headers = {
            "Authorization": f"Bearer {settings.VOYAGE_API_KEY}",
            "Content-Type": "application/json"
        }

    @retry(
        wait=wait_fixed(settings.VOYAGE_RATE_LIMIT_DELAY),
        stop=stop_after_attempt(5),
        retry=retry_if_exception_type(httpx.HTTPStatusError),
    )
    async def get_embedding(self, text: str, input_type: str = None) -> List[float]:
        """
        Generates an embedding for a single text string.
        """
        embeddings = await self.get_embeddings([text], input_type=input_type)
        return embeddings[0] if embeddings else []

    @retry(
        wait=wait_fixed(settings.VOYAGE_RATE_LIMIT_DELAY),
        stop=stop_after_attempt(5),
        retry=retry_if_exception_type(httpx.HTTPStatusError),
    )
    async def get_embeddings(self, texts: List[str], input_type: str = None) -> List[List[float]]:
        """
        Generates embeddings for a list of texts.
        """
        payload = {
            "input": texts,
            "model": settings.VOYAGE_MODEL,
            "input_type": input_type or settings.VOYAGE_INPUT_TYPE,
        }
        
        response = await self.client.post(self.api_url, headers=self.headers, json=payload)
        response.raise_for_status()
        
        result = response.json()
        return [item['embedding'] for item in result['data']]

def get_embedding_service() -> EmbeddingService:
    client = httpx.AsyncClient(timeout=settings.LLM_TIMEOUT)
    return EmbeddingService(client)
