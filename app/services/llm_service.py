import httpx
from typing import List, Dict, Any

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
            response = await self.client.post(self.api_url, headers=self.headers, json=payload, timeout=settings.LLM_TIMEOUT)
            response.raise_for_status()
            result = response.json()
            return result["choices"][0]["message"]["content"]
        except (httpx.HTTPStatusError, KeyError, IndexError) as e:
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
            response = await self.client.post(self.api_url, headers=self.headers, json=payload, timeout=settings.LLM_TIMEOUT)
            response.raise_for_status()
            result = response.json()
            return result["choices"][0]["message"]["content"].strip()
        except Exception as e:
            print(f"Error extracting intent: {e}")
            return message # Fallback to original message

def get_llm_service() -> LLMService:
    client = httpx.AsyncClient()
    return LLMService(client)
