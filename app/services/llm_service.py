import httpx
from typing import List, Dict, Any, Optional
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

from app.core.config import settings

class LLMService:
    def __init__(self, client: httpx.AsyncClient):
        self.client = client
        # Using Gemini's OpenAI-compatible endpoint
        self.api_url = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
        self.headers = {
            "Authorization": f"Bearer {settings.GEMINI_API_KEY}",
            "Content-Type": "application/json"
        }

    @retry(
        wait=wait_exponential(multiplier=1, min=2, max=10),
        stop=stop_after_attempt(5),
        retry=retry_if_exception_type(httpx.HTTPStatusError),
        reraise=True
    )
    async def _make_request(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Makes a request to the LLM API with retry logic.
        """
        response = await self.client.post(
            self.api_url, 
            headers=self.headers, 
            json=payload, 
            timeout=settings.LLM_TIMEOUT
        )
        
        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as e:
            # If it's a 429, we definitely want to retry
            if e.response.status_code == 429:
                print(f"LLM Rate limit hit (429). Retrying...")
                raise e
            # For 5xx errors, we also want to retry
            elif 500 <= e.response.status_code < 600:
                print(f"LLM Server error ({e.response.status_code}). Retrying...")
                raise e
            # For other errors (4xx), don't retry, just let it through to be handled by caller
            else:
                raise e
        return response.json()

    async def get_chat_completion(self, messages: List[Dict[str, str]]) -> str:
        """
        Gets a chat completion from the Poe API.
        """
        payload = {
            "model": settings.LLM_MODEL,
            "messages": messages,
            "max_tokens": settings.LLM_MAX_TOKENS,
            "temperature": settings.LLM_TEMPERATURE,
        }

        try:
            result = await self._make_request(payload)
            return result["choices"][0]["message"]["content"]
        except Exception as e:
            # Handle potential errors from the API call
            print(f"Error getting chat completion: {e}")
            return "I am sorry, but I am experiencing some technical difficulties. Please try again later. / Mohon maaf, saya sedang mengalami gangguan teknis. Silakan coba lagi nanti."

    async def extract_audio_intent(self, message: str) -> str:
        """
        Extracts the core audio problem from a long, conversational message.
        """
        prompt = f"""
Extract the CORE audio problem or intent from this user message. 
Ignore conversational fillers, names, and greetings.
Output ONLY the short core problem in 1-5 words (Indonesian).

User message: "{message}"
Core problem:"""
        
        messages = [{"role": "user", "content": prompt}]
        payload = {
            "model": settings.LLM_MODEL,
            "messages": messages,
            "max_tokens": 50,
            "temperature": 0,
        }
        
        try:
            result = await self._make_request(payload)
            return result["choices"][0]["message"]["content"].strip()
        except Exception as e:
            print(f"Error extracting intent: {e}")
            return message # Fallback to original message

# Global client for the service
_llm_client: Optional[httpx.AsyncClient] = None

def get_llm_service() -> LLMService:
    global _llm_client
    if _llm_client is None:
        _llm_client = httpx.AsyncClient()
    return LLMService(_llm_client)
