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
        all_products_context = []

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
                
                # Group products by category for better organization
                products_by_category = {}
                for rec in raw_recs:
                    cat = rec['product_category']
                    if cat not in products_by_category:
                        products_by_category[cat] = []
                    products_by_category[cat].append(rec)
                
                recommendations_context += "AVAILABLE PRODUCTS (organized by category, premium first):\n"

                solution_products = []
                option_counter = 1
                for category in sorted(products_by_category.keys()):
                    category_products = products_by_category[category]
                    recommendations_context += f"\n[{category.upper().replace('_', ' ')}]\n"
                    for rec in category_products:
                        recommendations_context += f"Opsi {option_counter}. {rec['product_name']} - Rp {rec['product_price']}\n"
                        recommendations_context += f"   {rec['product_description']}\n"
                        rec['option_number'] = option_counter
                        option_counter += 1
                        solution_products.append({
                            "product_id": str(rec['product_id']),
                            "product_name": rec['product_name'],
                            "product_category": rec['product_category'],
                            "product_price": float(rec['product_price']),
                            "image": rec.get('product_image') or "⚡"
                        })

                recommendations = [{
                    "solution_id": str(problems[0]['mcp_id']),
                    "solution_title": matched_problem_title,
                    "solution_description": matched_problem_approach or "",
                    "products": solution_products
                }]

        # Fallback: If no problem matched, try to get products by brand mention or general search
        if not recommendations:
            logger.info(f"No problem matched, trying brand/product search for query: {search_query}")
            # Extract brand mentions from query
            query_lower = search_query.lower()
            known_brands = ['kenwood', 'pioneer', 'jvc', 'nakamichi', 'clarion', 'hertz', 'jl audio', 'rockford fosgate', 'skeleton', 'dhd', 'avix', 'orca', 'exxent']
            mentioned_brands = [brand for brand in known_brands if brand in query_lower]

            if mentioned_brands:
                logger.info(f"Found brand mentions: {mentioned_brands}")
                # Get products for mentioned brands
                for brand in mentioned_brands:
                    brand_products = await db.get_products_by_brand(brand)
                    if brand_products:
                        all_products_context.extend(brand_products)
                        recommendations_context += f"\n\n{brand.upper()} PRODUCTS IN DATABASE (premium first):\n"
                        
                        # Group by category for better organization
                        brand_by_category = {}
                        for prod in brand_products:
                            cat = prod['product_category']
                            if cat not in brand_by_category:
                                brand_by_category[cat] = []
                            brand_by_category[cat].append(prod)
                        
                        for category in sorted(brand_by_category.keys()):
                            category_products = brand_by_category[category]
                            recommendations_context += f"\n[{category.upper().replace('_', ' ')}]\n"
                            for prod in category_products:
                                recommendations_context += f"- {prod['product_name']} - Rp {prod['product_price']}\n"
                                recommendations_context += f"  {prod['product_description']}\n"

                # Build a single RecommendedSolution with all brand products
                if all_products_context:
                    solution_products = [
                        {
                            "product_id": str(prod['product_id']),
                            "product_name": prod['product_name'],
                            "product_category": prod['product_category'],
                            "product_price": float(prod['product_price']),
                            "image": prod.get('product_image') or "⚡"
                        }
                        for prod in all_products_context
                    ]
                    recommendations = [{
                        "solution_id": "brand_fallback",
                        "solution_title": f"Produk {', '.join([b.title() for b in mentioned_brands])}",
                        "solution_description": "Produk yang tersedia berdasarkan merek yang Anda sebutkan.",
                        "products": solution_products
                    }]
            else:
                # No brand mentioned, get all products as fallback
                logger.info("No brand mentioned, getting all products as fallback")
                all_products = await db.get_all_active_products()
                if all_products:
                    all_products_context.extend(all_products)
                    recommendations_context += "\n\nALL PRODUCTS IN DATABASE (organized by category, premium first):\n"
                    
                    # Group by category and brand tier
                    products_by_category = {}
                    for prod in all_products:
                        cat = prod['product_category']
                        if cat not in products_by_category:
                            products_by_category[cat] = []
                        products_by_category[cat].append(prod)
                    
                    for category in sorted(products_by_category.keys()):
                        category_products = products_by_category[category]
                        recommendations_context += f"\n[{category.upper().replace('_', ' ')}]\n"
                        for prod in category_products:
                            recommendations_context += f"- {prod['product_name']} - Rp {prod['product_price']}\n"
                            recommendations_context += f"  {prod['product_description']}\n"

                    solution_products = [
                        {
                            "product_id": str(prod['product_id']),
                            "product_name": prod['product_name'],
                            "product_category": prod['product_category'],
                            "product_price": float(prod['product_price']),
                            "image": prod.get('product_image') or "⚡"
                        }
                        for prod in all_products
                    ]
                    recommendations = [{
                        "solution_id": "general_fallback",
                        "solution_title": "Produk Audio Tersedia",
                        "solution_description": "Berikut adalah produk-produk yang tersedia di database kami.",
                        "products": solution_products
                    }]

        logger.info(f"Recommendations context length: {len(recommendations_context)}")
        logger.info(f"Number of recommendations: {len(recommendations)}")

        # 3. System Prompt
        context_to_inject = recommendations_context if recommendations_context else "NO SPECIFIC DATA FOUND."

        system_prompt = f"""
You are AudioMatch Expert, a car audio product recommendation assistant.
Time: {current_time_str} (WIB).

CRITICAL RULES:
- You MUST ONLY recommend products that appear in the DATABASE CONTEXT below.
- NEVER invent, hallucinate, or suggest products that are not explicitly listed in the context.
- If the user asks for a specific brand, only recommend products of that brand from the context.
- If NO products are found in the context, say "Saya tidak menemukan produk yang sesuai di database kami. Silakan hubungi kami untuk info lebih lanjut."
- Do NOT make up product names, prices, or specifications.

RULES:
- Help users find the right products based on their problems, budget, or questions.
- Use only the DATABASE CONTEXT below to answer.
- If user asks for COMPARISON between products/brands:
  * Compare based on price, features, power, quality from the context
  * Be objective: mention pros and cons
  * Recommend based on use case (budget vs quality vs SPL)
- If user mentions BUDGET:
  * Recommend products within their budget range
  * Mention "Harga: Rp [price]" for each product
  * Prioritize best value for money
  * For HIGH BUDGET (above 10 juta): RECOMMEND ALL products from the context including premium brands (JL Audio, Rockford Fosgate, Hertz, Nakamichi, Clarion)
  * For MEDIUM BUDGET (5-10 juta): Focus on mid-range brands (Pioneer, Kenwood, JVC, Exxent) but also mention premium options
  * For LOW BUDGET (below 5 juta): Focus on budget brands (Skeleton, DHD, Avix, Orca)
- If user mentions a SPECIFIC BRAND (e.g., "Kenwood"):
  * SHOW ALL available products from that brand across ALL categories
  * Organize by category: Head Unit, Speaker (Component/Coaxial), Subwoofer, Amplifier, etc.
  * Recommend a COMPLETE PACKAGE that includes products from different categories if applicable
  * DO NOT just show 1-2 products - show the full range available
- If user asks for PACKAGE/PAKET recommendations:
  * Include products from MULTIPLE categories to form a complete system
  * Example complete package: Head Unit + Speaker Depan + Speaker Belakang + Subwoofer + Amplifier
  * Calculate total package price and mention it
  * Explain what each component contributes to the system
- If user mentions "opsi X" or "nomor X", explain that specific product from the list.
- ALWAYS include pricing in format: "Rp [price]" or "Harga: Rp [price]".
- Respond in the same language as the user (Indonesian or English).
- Use Markdown formatting for better readability:
  * Use **bold** for product names, category headers, and important terms
  * Use *italic* for supplementary descriptions
  * Use numbered lists (1., 2., 3.) for product recommendations
  * Use bullet points (-) for sub-items like features or descriptions
  * Use ### for section headers (e.g., ### Paket Audio Lengkap)
- STRUCTURE your response clearly:
  * Use numbered lists for product recommendations
  * Group products by category when recommending packages
  * Explain WHY each product is recommended
- For brand positioning guidance:
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
