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
            await redis.set_session_data(session_id, {"history": []})
        
        session_data = await redis.get_session_data(session_id) or {"history": []}
        history = session_data.get("history", [])

        # 2. Get Current Time (WIB)
        wib = pytz.timezone('Asia/Jakarta')
        now = datetime.now(wib)
        current_time_str = now.strftime("%H:%M")
        
        # Determine time-based greeting context
        hour = now.hour
        if 5 <= hour < 11:
            time_greeting = "Pagi"
        elif 11 <= hour < 15:
            time_greeting = "Siang"
        elif 15 <= hour < 19:
            time_greeting = "Sore"
        else:
            time_greeting = "Malam"

        # 3. Database Search (Always search to check for audio intent)
        # Extract the core intent from potentially conversational/long user messages
        extracted_intent = await llm_service.extract_audio_intent(request.message)
        logger.info(f"Original message: {request.message}")
        logger.info(f"Extracted intent: {extracted_intent}")

        embedding = await embedding_service.get_embedding(extracted_intent, input_type="query")
        problems = await db.search_problem(embedding)
        
        logger.info(f"Problems found: {len(problems) if problems else 0}")
        if problems:
            logger.info(f"Top problem: {problems[0]['mcp_problem_title']} (Similarity: {problems[0]['similarity']})")
        
        recommendations_context = ""
        knowledge_context = ""
        has_audio_data = False
        recommendations = []

        if problems:
            # Try to find a problem that actually has recommendations/solutions
            # (Previously we only checked problems[0], but it might have 0 solutions)
            raw_recs = []
            matched_problem_title = ""
            
            for prob in problems:
                found_recs = await db.get_recommendations(str(prob['mcp_id']))
                if found_recs:
                    raw_recs = found_recs
                    matched_problem_title = prob['mcp_problem_title']
                    logger.info(f"Found solutions for problem: {matched_problem_title}")
                    break
            
            if raw_recs:
                has_audio_data = True
                recommendations_context = f"\nUSER PROBLEM: {matched_problem_title}\nAVAILABLE SOLUTIONS:\n"
                
                # Group by solution for the response model
                sol_map = {}
                for rec in raw_recs:
                    recommendations_context += f"- {rec['solution_title']}: {rec['product_name']} ({rec['product_category']}) - Start from Rp {rec['product_price']}\n"
                    
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
            else:
                logger.warning("All matched problems had zero solutions/recommendations in DB.")
        
        # Optional knowledge search
        k_chunks = await db.search_knowledge(embedding)
        if k_chunks:
            knowledge_context = "\nGENERAL KNOWLEDGE:\n" + "\n".join([f"- {k['mkc_content']}" for k in k_chunks])

        # 4. Build Flexible but Strict System Prompt
        system_prompt = f"""
You are an expert AI Sales Assistant for AudioMatch. 
Current Time: {current_time_str}.

CRITICAL RULE - LANGUAGE MIRRORING:
1. DETECT USER LANGUAGE: You MUST identify the language used by the user in their latest message.
2. RESPONSE LANGUAGE: You MUST respond in the EXACT SAME language as the user.
   - User speaks English -> You MUST respond in English.
   - User speaks Indonesian -> You MUST respond in Indonesian.
3. CONTEXT TRANSLATION: The 'DATABASE CONTEXT' provided below may be in Indonesian. If the user speaks English, you MUST translate the information from the context into English in your response. Do NOT respond in Indonesian if the user asked in English.
4. STYLE MIRRORING: Match the user's tone (casual vs formal). Use slang like 'bro/gw/nih' ONLY if the user uses them first.
5. PROACTIVE ANALYSIS: If the user tells a story or a long problem description, connect their specific complaints to the solutions found in the 'DATABASE CONTEXT'. Don't just list them; explain WHY these solutions match their story.

STRICT DATABASE RULES:
- Only provide audio advice if it exists in the 'DATABASE CONTEXT'.
- If context is empty, decline naturally using the user's language and style.
  * Example EN: 'I am sorry, but I couldn'\''t find any data regarding that in our system. Please contact our expert team.'
- Never suggest solutions (tips/troubleshooting) not found in the context.
- PRICING RULE: You MUST always include a "starting from" phrase before any price. 
  * In Indonesian: Use "Harga mulai dari Rp" (e.g., 'Harga mulai dari Rp 1.500.000').
  * In English: Use "Start from Rp" (e.g., 'Start from Rp 1.500.000').
  * NEVER mention a flat price without these phrases.

DATABASE CONTEXT:
{recommendations_context if has_audio_data else "NO SPECIFIC AUDIO DATA FOUND."}
{knowledge_context if knowledge_context else "NO GENERAL KNOWLEDGE DATA FOUND."}
"""

        # 5. LLM Call
        messages = [
            {"role": "system", "content": system_prompt},
            *history[-6:], # Send last 6 messages for context (including name)
            {"role": "user", "content": request.message}
        ]

        llm_response = await llm_service.get_chat_completion(messages)

        # 6. Update Session History
        history.append({"role": "user", "content": request.message})
        history.append({"role": "assistant", "content": llm_response})
        await redis.set_session_data(session_id, {"history": history})

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

    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="An internal server error occurred.")
