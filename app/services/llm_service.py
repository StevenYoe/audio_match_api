import httpx
from typing import List, Dict, Any, Optional
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

from app.core.config import settings

class LLMService:
    def __init__(self, client: httpx.AsyncClient):
        self.client = client
        # Using Native Gemini API endpoint for better stability
        self.api_url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.LLM_MODEL}:generateContent?key={settings.GEMINI_API_KEY}"
        self.headers = {
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
        Makes a request to the Gemini API with retry logic.
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
            if e.response.status_code == 429:
                print(f"LLM Rate limit hit (429). Retrying...")
                raise e
            elif 500 <= e.response.status_code < 600:
                print(f"LLM Server error ({e.response.status_code}). Retrying...")
                raise e
            else:
                raise e
        return response.json()

    async def get_chat_completion(self, messages: List[Dict[str, str]]) -> str:
        """
        Gets a chat completion from the Gemini API using native format.
        """
        # Convert OpenAI message format to Gemini native format
        contents = []
        system_instruction = ""
        
        for msg in messages:
            if msg["role"] == "system":
                system_instruction = msg["content"]
            else:
                role = "user" if msg["role"] == "user" else "model"
                contents.append({
                    "role": role,
                    "parts": [{"text": msg["content"]}]
                })

        payload = {
            "contents": contents,
            "generationConfig": {
                "maxOutputTokens": settings.LLM_MAX_TOKENS,
                "temperature": settings.LLM_TEMPERATURE,
            }
        }
        
        if system_instruction:
            payload["system_instruction"] = {"parts": [{"text": system_instruction}]}

        try:
            result = await self._make_request(payload)
            return result["candidates"][0]["content"]["parts"][0]["text"]
        except Exception as e:
            print(f"Error getting chat completion: {e}")
            return "I am sorry, but I am experiencing some technical difficulties. Please try again later."

    async def extract_audio_intent(self, message: str) -> str:
        """
        Extracts the core audio problem using Gemini native format.
        """
        prompt = f"""
Extract the CORE audio problem or intent from this user message. 
Ignore conversational fillers, names, and greetings.
Output ONLY the short core problem in 1-5 words (Indonesian).

User message: "{message}"
Core problem:"""
        
        payload = {
            "contents": [{"role": "user", "parts": [{"text": prompt}]}],
            "generationConfig": {
                "maxOutputTokens": 50,
                "temperature": 0,
            }
        }
        
        try:
            result = await self._make_request(payload)
            return result["candidates"][0]["content"]["parts"][0]["text"].strip()
        except Exception as e:
            print(f"Error extracting intent: {e}")
            return message

# Global client for the service
_llm_client: Optional[httpx.AsyncClient] = None

def get_llm_service() -> LLMService:
    global _llm_client
    if _llm_client is None:
        _llm_client = httpx.AsyncClient()
    return LLMService(_llm_client)
