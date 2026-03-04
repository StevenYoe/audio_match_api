from fastapi import APIRouter, Depends, HTTPException, Request
from app.api.v1 import schemas
from app.core.config import settings
from app.core.dependencies import get_db, get_redis, get_embedding_service_dep, get_llm_service_dep
from app.services.database_service import DatabaseService
from app.services.redis_service import RedisService
from app.services.embedding_service import EmbeddingService
from app.services.llm_service import LLMService
import uuid
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

from datetime import datetime
import pytz

@router.post("/", response_model=schemas.ChatResponse)
async def chat(
    request: schemas.ChatRequest,
    db: DatabaseService = Depends(get_db),
    redis: RedisService = Depends(get_redis),
    embedding_service: EmbeddingService = Depends(get_embedding_service_dep),
    llm_service: LLMService = Depends(get_llm_service_dep),
):
    """
    HYBRID CHATBOT: Flexible for greetings, STRICT for audio data.
    """
    try:
        # 1. Session Management
        session_id = request.session_id
        if not session_id or not _is_valid_uuid(session_id):
            session_id = str(uuid.uuid4())
            await redis.set_session_data(session_id, {"history": [], "last_context": ""})
        
        session_data = await redis.get_session_data(session_id) or {"history": [], "last_context": ""}
        history = session_data.get("history", [])
        last_context = session_data.get("last_context", "")

        # 2. Get Current Time (WIB)
        wib = pytz.timezone('Asia/Jakarta')
        now = datetime.now(wib)
        current_time_str = now.strftime("%H:%M")
        
        # 3. Intelligent Context Retrieval
        # Check if user is referencing previous options
        is_referencing = any(word in request.message.lower() for word in ["opsi", "nomor", "yang", "pilihan", "itu", "menarik", "lanjut"]) and len(request.message.split()) < 6
        
        recommendations_context = ""
        knowledge_context = ""
        has_audio_data = False
        recommendations = []

        if is_referencing and last_context:
            logger.info("User is referencing previous context. Reusing last context.")
            recommendations_context = last_context
            has_audio_data = True
        else:
            # HYBRID SEARCH: Vector (Semantic) + Lexical (Keyword)
            extracted_intent = await llm_service.extract_audio_intent(request.message)
            
            # 1. Vector Search (The "Smart" one)
            embedding = await embedding_service.get_embedding(extracted_intent, input_type="query")
            vector_problems = await db.search_problem(embedding)
            
            # 2. Lexical Search (The "Accurate" one)
            lexical_problems = await db.search_problem_lexical(extracted_intent)
            
            # 3. Hybrid Combination Logic
            # We prioritize Lexical if it finds a high-quality match (exact keyword)
            # Otherwise, use Vector.
            problems = []
            if lexical_problems and lexical_problems[0]['similarity'] > 0.5:
                logger.info("Lexical Search match found. High priority.")
                problems = lexical_problems
            else:
                problems = vector_problems
            
            if problems:
                raw_recs = []
                matched_problem_title = ""
                for prob in problems:
                    found_recs = await db.get_recommendations(str(prob['mcp_id']))
                    if found_recs:
                        raw_recs = found_recs
                        matched_problem_title = prob['mcp_problem_title']
                        break
                
                if raw_recs:
                    has_audio_data = True
                    recommendations_context = f"\nUSER PROBLEM: {matched_problem_title}\nAVAILABLE SOLUTIONS:\n"
                    sol_map = {}
                    for i, rec in enumerate(raw_recs):
                        recommendations_context += f"{i+1}. {rec['solution_title']}: {rec['product_name']} ({rec['product_category']}) - Start from Rp {rec['product_price']}\n"
                        
                        sid = str(rec['solution_id'])
                        if sid not in sol_map:
                            sol_map[sid] = {
                                "solution_id": sid,
                                "solution_title": rec['solution_title'],
                                "solution_description": rec['solution_description'],
                                "products": []
                            }
                        sol_map[sid]["products"].append({
                            "product_id": str(rec['product_id']),
                            "product_name": rec['product_name'],
                            "product_category": rec['product_category'],
                            "product_price": float(rec['product_price']),
                            "image": rec.get('product_image') or "⚡"
                        })
                    recommendations = list(sol_map.values())
                    last_context = recommendations_context

            k_chunks = await db.search_knowledge(embedding) if not is_referencing else []
            if k_chunks:
                knowledge_context = "\nGENERAL KNOWLEDGE:\n" + "\n".join([f"- {k['mkc_content']}" for k in k_chunks])

        # 4. Build Flexible but Strict System Prompt
        system_prompt = f"""
You are an expert AI Sales Assistant for AudioMatch. 
Current Time: {current_time_str}.

FORMATTING RULES:
- DO NOT use any Markdown formatting like asterisks (**), bolding, or headers (#).
- Use plain text only. 
- For lists, use simple numbers (1., 2., etc.).

CRITICAL RULE - LANGUAGE MIRRORING:
1. DETECT USER LANGUAGE: You MUST identify the language used by the user.
2. RESPONSE LANGUAGE: You MUST respond in the EXACT SAME language as the user.
3. CONTEXT TRANSLATION: If the user speaks English, translate the 'DATABASE CONTEXT' below into English.
4. STYLE MIRRORING: Match the user's tone. Use 'bro/gw/nih' ONLY if the user uses them first.
5. CONTEXTUAL MEMORY: Always refer to the options provided in the 'DATABASE CONTEXT' below. If the user mentions "Option 1" or "the first one", they are referring to the first item in the list below.

STRICT DATABASE RULES:
- Only provide audio advice if it exists in the 'DATABASE CONTEXT'.
- PRICING RULE: You MUST always include "Harga mulai dari Rp" or "Start from Rp".

DATABASE CONTEXT:
{recommendations_context if has_audio_data else "NO SPECIFIC AUDIO DATA FOUND."}
{knowledge_context if knowledge_context else "NO GENERAL KNOWLEDGE DATA FOUND."}
"""

        # 5. LLM Call
        messages = [
            {"role": "system", "content": system_prompt},
            *history[-8:], 
            {"role": "user", "content": request.message}
        ]

        llm_response = await llm_service.get_chat_completion(messages)

        # 6. Update Session History
        history.append({"role": "user", "content": request.message})
        history.append({"role": "assistant", "content": llm_response})
        await redis.set_session_data(session_id, {
            "history": history,
            "last_context": last_context
        })

        return schemas.ChatResponse(
            session_id=session_id,
            response=llm_response,
            recommendations=recommendations
        )

    except Exception as e:
        logger.error(f"Error in chat: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error.")

def _is_valid_uuid(val: str) -> bool:
    try:
        uuid.UUID(str(val))
        return True
    except ValueError:
        return False
