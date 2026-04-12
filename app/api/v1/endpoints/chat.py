from fastapi import APIRouter, Depends, HTTPException
from app.api.v1 import schemas
from app.core.config import settings
from app.core.dependencies import get_db, get_redis, get_embedding_service_dep, get_llm_service_dep
from app.services.database_service import DatabaseService
from app.services.redis_service import RedisService
from app.services.embedding_service import EmbeddingService
from app.services.llm_service import LLMService
import uuid
import logging
from datetime import datetime
import pytz

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/", response_model=schemas.ChatResponse)
async def chat(
    request: schemas.ChatRequest,
    db: DatabaseService = Depends(get_db),
    redis: RedisService = Depends(get_redis),
    embedding_service: EmbeddingService = Depends(get_embedding_service_dep),
    llm_service: LLMService = Depends(get_llm_service_dep),
):
    """
    Product Recommendation Chatbot: Match user problems to products.
    """
    try:
        # 1. Session Management
        session_id = request.session_id
        if not session_id or not _is_valid_uuid(session_id):
            session_id = str(uuid.uuid4())
            await redis.set_session_data(session_id, {"history": []})

        session_data = await redis.get_session_data(session_id) or {"history": []}
        history = session_data.get("history", [])

        # 2. Context Retrieval
        wib = pytz.timezone('Asia/Jakarta')
        current_time_str = datetime.now(wib).strftime("%H:%M")

        search_query = request.message
        embedding = await embedding_service.get_embedding(search_query, input_type="query")
        problems = await db.search_problem(embedding)

        recommendations_context = ""
        recommendations = []

        if problems:
            raw_recs = []
            matched_problem_title = ""
            matched_problem_approach = ""
            for prob in problems:
                found_recs = await db.get_recommendations(str(prob['mcp_id']))
                if found_recs:
                    raw_recs = found_recs
                    matched_problem_title = prob['mcp_problem_title']
                    matched_problem_approach = prob.get('mcp_recommended_approach', '')
                    break

            if raw_recs:
                recommendations_context = f"\nUSER PROBLEM: {matched_problem_title}\n"
                if matched_problem_approach:
                    recommendations_context += f"RECOMMENDED APPROACH: {matched_problem_approach}\n\n"
                recommendations_context += "RECOMMENDED PRODUCTS:\n"
                
                for i, rec in enumerate(raw_recs):
                    recommendations_context += f"Opsi {i+1}. {rec['product_name']} ({rec['product_category']}) - Rp {rec['product_price']}\n"
                    recommendations_context += f"   {rec['product_description']}\n"

                recommendations = [
                    {
                        "product_id": str(rec['product_id']),
                        "product_name": rec['product_name'],
                        "product_category": rec['product_category'],
                        "product_price": float(rec['product_price']),
                        "image": rec.get('product_image') or "⚡",
                        "problem_title": rec.get('problem_title', matched_problem_title),
                        "recommended_approach": rec.get('recommended_approach', matched_problem_approach)
                    }
                    for rec in raw_recs
                ]

        # 3. System Prompt
        context_to_inject = recommendations_context if recommendations_context else "NO SPECIFIC DATA FOUND."

        system_prompt = f"""
You are AudioMatch Expert, a car audio product recommendation assistant.
Time: {current_time_str} (WIB).

RULES:
- Help users find the right products based on their problems, budget, or questions.
- Use only the DATABASE CONTEXT below to answer.
- If user asks for COMPARISON between products/brands:
  * Compare based on price, features, power, quality from the context
  * Be objective: mention pros and cons
  * Recommend based on use case (budget vs quality vs SPL)
- If user mentions BUDGET:
  * Recommend products within their budget range
  * Mention "Start from Rp [price]" for each product
  * Prioritize best value for money
- If user mentions "opsi X" or "nomor X", explain that specific product from the list.
- NEVER invent products or information not in the context.
- Always include pricing in format: "Rp [price]" or "Harga mulai dari Rp [price]".
- Respond in the same language as the user (Indonesian or English).
- Use plain text only (no markdown formatting like * or #).
- For brand comparison questions, explain the brand positioning:
  * Budget: Skeleton, DHD, Avix, Orca
  * Mid-range: Pioneer, Kenwood, JVC, Exxent
  * Premium: Nakamichi, Clarion, Hertz, JL Audio, Rockford Fosgate

DATABASE CONTEXT:
{context_to_inject}
"""

        # 4. LLM Execution
        messages = [
            {"role": "system", "content": system_prompt},
            *history[-8:],
            {"role": "user", "content": request.message}
        ]

        llm_response = await llm_service.get_chat_completion(messages)

        # 5. Session Save
        history.append({"role": "user", "content": request.message})
        history.append({"role": "assistant", "content": llm_response})
        await redis.set_session_data(session_id, {"history": history})

        return schemas.ChatResponse(
            session_id=session_id,
            response=llm_response,
            recommendations=recommendations
        )

    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error.")

def _is_valid_uuid(val: str) -> bool:
    try:
        uuid.UUID(str(val))
        return True
    except ValueError:
        return False
