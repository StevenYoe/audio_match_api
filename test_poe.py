import os
import httpx
import asyncio
from dotenv import load_dotenv

load_dotenv()

async def test_poe_key():
    key = os.getenv("POE_API_KEY")
    if not key:
        print("POE_API_KEY not found in .env")
        return
    
    print(f"Key length: {len(key)}")
    print(f"Key prefix (first 5): {key[:5]}")
    print(f"Key suffix (last 5): {key[-5:]}")
    
    url = "https://api.poe.com/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": "Assistant",
        "messages": [{"role": "user", "content": "test"}],
        "max_tokens": 10
    }
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, headers=headers, json=payload, timeout=10)
            print(f"Status Code: {response.status_code}")
            print(f"Response Body: {response.text}")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_poe_key())
