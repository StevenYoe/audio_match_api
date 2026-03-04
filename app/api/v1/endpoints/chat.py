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
    HYBRID CHATBOT: High intelligence, low LLM cost, perfect tone mirroring.
    """
    try:
        # 1. Session Management
        session_id = request.session_id
        if not session_id or not _is_valid_uuid(session_id):
            session_id = str(uuid.uuid4())
            await redis.set_session_data(session_id, {"history": [], "last_context": "", "last_recs": []})
        
        session_data = await redis.get_session_data(session_id) or {"history": [], "last_context": "", "last_recs": []}
        history = session_data.get("history", [])
        last_context = session_data.get("last_context", "")
        last_recs = session_data.get("last_recs", [])

        # 2. Context Retrieval & Intelligence
        wib = pytz.timezone('Asia/Jakarta')
        current_time_str = datetime.now(wib).strftime("%H:%M")
        
        # Reference detection (Increased flexibility)
        ref_keywords = ["opsi", "nomor", "pilihan", "itu", "menarik", "lanjut", "pertama", "kedua", "ketiga", "keempat", "kelima", "yang", "ini"]
        is_referencing = any(word in request.message.lower() for word in ref_keywords) and len(request.message.split()) < 20
        
        recommendations_context = ""
        knowledge_context = ""
        has_audio_data = False
        recommendations = []

        if is_referencing and last_context:
            logger.info(f"Context Reuse: Session {session_id}")
            recommendations_context = last_context
            recommendations = last_recs
            has_audio_data = True
        else:
            # New Search
            search_query = request.message
            embedding = await embedding_service.get_embedding(search_query, input_type="query")
            vector_problems = await db.search_problem(embedding)
            lexical_problems = await db.search_problem_lexical(search_query)
            
            problems = lexical_problems if (lexical_problems and lexical_problems[0]['similarity'] > 0.5) else vector_problems
            
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
                        recommendations_context += f"Opsi {i+1}. {rec['solution_title']}: {rec['product_name']} ({rec['product_category']}) - Start from Rp {rec['product_price']}\n"
                        
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
                    last_recs = recommendations

            k_chunks = await db.search_knowledge(embedding) if not is_referencing else []
            if k_chunks:
                knowledge_context = "\nGENERAL KNOWLEDGE:\n" + "\n".join([f"- {k['mkc_content']}" for k in k_chunks])

        # 3. Enhanced System Prompt (Restoring LSM & Tone)
        context_to_inject = recommendations_context if has_audio_data else "NO SPECIFIC AUDIO DATA FOUND."

        system_prompt = f"""
You are AudioMatch Expert Sales Assistant.
Time: {current_time_str}.

STYLE & LANGUAGE MIRRORING (CRITICAL):
1. LANGUAGE: Respond in the EXACT same language as the user.
2. TONE: Mirror the user's tone. If they are casual ("bro/gw/nih/dong"), YOU MUST be casual. If they are formal, you be formal.
3. NO GREETINGS: Do not say "Halo", "Selamat Pagi", or "Ada yang bisa dibantu" if the user didn't greet you first. Just answer directly.
4. PLAIN TEXT ONLY: No Markdown (* or #).

STRICT DATABASE RULES:
- Use 'DATABASE CONTEXT' below.
- If user refers to an option (e.g., "opsi ketiga", "nomor 2"), look for that "Opsi X" in the list below and explain it.
- NEVER say you don't have information if the option is in the list.
- PRICING: Always include "Harga mulai dari Rp" or "Start from Rp".

DATABASE CONTEXT:
{context_to_inject}
{knowledge_context if knowledge_context else "NO GENERAL KNOWLEDGE DATA FOUND."}
"""

        # System Note Injection for precise mapping
        user_message_for_llm = request.message
        if is_referencing and has_audio_data:
            user_message_for_llm += "\n\n[SYSTEM NOTE: User is choosing an option. Map their choice to 'Opsi X' in the list and explain it detail. Mirror their style.]"

        # 4. LLM Execution
        messages = [
            {"role": "system", "content": system_prompt},
            *history[-8:], 
            {"role": "user", "content": user_message_for_llm}
        ]

        llm_response = await llm_service.get_chat_completion(messages)

        # 5. Session Save
        history.append({"role": "user", "content": request.message})
        history.append({"role": "assistant", "content": llm_response})
        await redis.set_session_data(session_id, {
            "history": history,
            "last_context": last_context,
            "last_recs": last_recs
        })

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
