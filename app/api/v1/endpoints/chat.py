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
        recommendations_context = ""
        recommendations = []
        all_products_context = []

        # STEP 2A: Check if user mentioned a specific car model
        car_info = _extract_car_mention(search_query)
        matched_car = None

        if car_info:
            logger.info(f"Car mention detected: brand='{car_info['brand']}', model='{car_info['model']}'")
            car_results = await db.search_car(car_info['brand'], car_info['model'] or '')

            if car_results:
                matched_car = car_results[0]  # Get best match
                logger.info(f"Car matched: {matched_car['mc_brand']} {matched_car['mc_model']} ({matched_car['mc_type']}, {matched_car['mc_size_category']})")

                # Get products specifically recommended for this car
                car_context, car_products = await db.get_car_recommendations_context(matched_car)
                recommendations_context = car_context

                if car_products:
                    recommendations = [{
                        "solution_id": f"car_{matched_car['mc_id']}",
                        "solution_title": f"Rekomendasi untuk {matched_car['mc_brand']} {matched_car['mc_model']}",
                        "solution_description": f"Produk audio yang kompatibel untuk {matched_car['mc_brand']} {matched_car['mc_model']} ({matched_car['mc_type']}, kabin {matched_car['mc_size_category']}).",
                        "products": car_products
                    }]

        # STEP 2A2: Check for BRAND mention (BEFORE problem search)
        # Brand queries should go directly to brand fallback, not problem matching
        if not recommendations:
            query_lower = search_query.lower()
            known_brands = ['kenwood', 'pioneer', 'jvc', 'nakamichi', 'clarion', 'hertz', 
                           'jl audio', 'rockford fosgate', 'skeleton', 'dhd', 'avix', 'orca', 'exxent']
            mentioned_brands = [brand for brand in known_brands if brand in query_lower]

            if mentioned_brands:
                logger.info(f"Brand detected in query: {mentioned_brands} - using direct brand search")
                # Get ALL products for mentioned brands using direct brand lookup (not hybrid search)
                for brand in mentioned_brands:
                    brand_products = await db.get_products_by_brand(brand)
                    if brand_products:
                        all_products_context.extend(brand_products)
                        recommendations_context += f"\n\nSEMUA PRODUK {brand.upper()} DI DATABASE (diorganisir berdasarkan kategori):\n"

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

                        # Build recommendation with ALL brand products
                        solution_products = [
                            {
                                "product_id": str(prod['product_id']),
                                "product_name": prod['product_name'],
                                "product_category": prod['product_category'],
                                "product_price": float(prod['product_price']),
                                "image": prod.get('product_image') or "⚡"
                            }
                            for prod in brand_products
                        ]
                        recommendations = [{
                            "solution_id": f"brand_{mentioned_brands[0]}",
                            "solution_title": f"Semua Produk {', '.join([b.title() for b in mentioned_brands])}",
                            "solution_description": f"Berikut adalah semua produk {', '.join([b.title() for b in mentioned_brands])} yang tersedia di database kami, diorganisir berdasarkan kategori.",
                            "products": solution_products
                        }]
                        break  # Only process first brand mentioned

        # STEP 2B: If no car mentioned, try HYBRID search (vector + BM25 FTS) on customer problems
        if not recommendations:
            # Get embedding for the query
            embedding = await embedding_service.get_embedding(search_query, input_type="query")
            
            # Use hybrid search: combines vector similarity + BM25 full-text search
            problems = await db.search_problem_hybrid(search_query, embedding, match_count=5)
            logger.info(f"Hybrid search returned {len(problems)} problems for query: {search_query}")
            if problems:
                logger.info(f"Top hybrid match: '{problems[0]['mcp_problem_title']}' (vector_score={problems[0].get('vector_score', 0):.3f}, bm25_score={problems[0].get('bm25_score', 0):.3f}, hybrid_score={problems[0].get('hybrid_score', 0):.3f})")

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

        # Fallback: If no problem matched, try to get products by brand mention or hybrid product search
        if not recommendations:
            logger.info(f"No problem matched, trying brand/product search for query: {search_query}")
            # Extract brand mentions from query
            query_lower = search_query.lower()
            known_brands = ['kenwood', 'pioneer', 'jvc', 'nakamichi', 'clarion', 'hertz', 'jl audio', 'rockford fosgate', 'skeleton', 'dhd', 'avix', 'orca', 'exxent']
            mentioned_brands = [brand for brand in known_brands if brand in query_lower]

            if mentioned_brands:
                logger.info(f"Found brand mentions: {mentioned_brands} - using direct brand search")
                # Get ALL products for mentioned brands using direct brand lookup
                for brand in mentioned_brands:
                    brand_products = await db.get_products_by_brand(brand)
                    if brand_products:
                        all_products_context.extend(brand_products)
                        recommendations_context += f"\n\nSEMUA PRODUK {brand.upper()} DI DATABASE (diorganisir berdasarkan kategori):\n"

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
                            "product_id": str(prod['mp_id']),
                            "product_name": prod['mp_name'],
                            "product_category": prod['mp_category'],
                            "product_price": float(prod['mp_price']),
                            "image": prod.get('mp_image') or "⚡"
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
                # No brand mentioned, get all products as fallback using hybrid search
                logger.info("No brand mentioned, getting all products via hybrid search as fallback")
                embedding = await embedding_service.get_embedding(search_query, input_type="query")
                all_products = await db.search_product_hybrid(
                    query_text=search_query,
                    embedding=embedding,
                    match_count=30
                )
                if all_products:
                    all_products_context.extend(all_products)
                    recommendations_context += "\n\nALL PRODUCTS IN DATABASE (ranked by hybrid score):\n"

                    # Group by category and brand tier
                    products_by_category = {}
                    for prod in all_products:
                        cat = prod['mp_category']
                        if cat not in products_by_category:
                            products_by_category[cat] = []
                        products_by_category[cat].append(prod)

                    for category in sorted(products_by_category.keys()):
                        category_products = products_by_category[category]
                        recommendations_context += f"\n[{category.upper().replace('_', ' ')}]\n"
                        for prod in category_products:
                            recommendations_context += f"- {prod['mp_name']} - Rp {prod['mp_price']} (hybrid: {prod.get('hybrid_score', 0):.3f})\n"
                            recommendations_context += f"  {prod['mp_description']}\n"

                    solution_products = [
                        {
                            "product_id": str(prod['mp_id']),
                            "product_name": prod['mp_name'],
                            "product_category": prod['mp_category'],
                            "product_price": float(prod['mp_price']),
                            "image": prod.get('mp_image') or "⚡"
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
- Help users find the right products based on their problems, budget, car type, or questions.
- Use only the DATABASE CONTEXT below to answer.

PRODUCT CATEGORY GUIDE (CRITICAL FOR CORRECT RECOMMENDATIONS):
- **TWEETER**: Specialist untuk vocal, detail suara, treble, dan frekuensi tinggi (2kHz-24kHz).
  ALWAYS recommend tweeter PERTAMA untuk masalah: "vocal tidak jelas", "vocal kurang jelas",
  "mid range kurang jelas", "suara datar", "soundstage sempit", "detail kurang", "treble kurang",
  "penyanyi tidak terdengar jelas". Tweeter adalah solusi UTAMA untuk masalah vocal.
- **SPEAKER COMPONENT 2-WAY**: Solusi upgrade speaker dengan tweeter terpisah dan crossover.
  Bagus untuk vocal DAN soundstage. Recommend SETELAH atau BERSAMA tweeter untuk vocal problems.
- **SPEAKER COAXIAL**: Upgrade plug-and-play dari speaker bawaan. All-in-one speaker.
  Good for general upgrade, tapi bukan specialist untuk vocal.
- **SUBWOOFER**: Specialist untuk bass, low frequency (20Hz-200Hz). Untuk EDM, hip-hop, reggae.
- **AMPLIFIER**: Power booster untuk semua speaker/subwoofer/tweeter. Recommended sebagai pendamping.
- **HEAD UNIT**: Source unit dengan fitur (Bluetooth, DSP, CarPlay, Android Auto).

PRIORITAS REKOMENDASI BY PROBLEM:
- **Vocal/Mid range kurang jelas**: 
  1️⃣ TWEETER (prioritas utama - specialist vocal)
  2️⃣ Speaker Component 2-way (dengan tweeter terpisah)
  3️⃣ Amplifier (untuk power tweeter/speaker)
- **Bass kurang bertenaga**: 
  1️⃣ Subwoofer
  2️⃣ Amplifier mono
  3️⃣ Speaker dengan bass response bagus
- **Soundstage/Staging sempit**: 
  1️⃣ Tweeter (untuk detail dan staging)
  2️⃣ Speaker Component 2-way/3-way
  3️⃣ Head Unit dengan DSP (untuk tuning)
- **Distorsi/Suara pecah**: 
  1️⃣ Speaker Component
  2️⃣ Amplifier (agar speaker tidak overwork)
  3️⃣ Head Unit dengan output bersih
- **Bluetooth/Connectivity masalah**: 
  1️⃣ Head Unit dengan Bluetooth 5.0+
- **Speaker bawaan jelek**: 
  1️⃣ Speaker Coaxial (plug-and-play)
  2️⃣ Speaker Component (upgrade lebih baik)
  3️⃣ Tweeter external (tambah detail)
- If user mentions a SPECIFIC CAR MODEL (e.g., "Xpander", "Brio", "Fortuner"):
  * ALWAYS prioritize products shown in the "RECOMMENDED FOR" section of the context
  * Explain WHY each product is suitable for that specific car
  * Consider cabin size, dashboard type, subwoofer space limitations
  * For SMALL cars (Brio, Agya, Ayla): RECOMMEND compact solutions (subwoofer kolong, speaker 5.25", slim amplifier)
  * For LARGE cars (Xpander, Avanza, Fortuner): RECOMMEND full systems (boxed subwoofer, 6x9" rear speakers, powerful amplifier)
  * Mention any installation notes from the car specifications
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
  * Explain WHY each product is recommended (especially for specific car models)
- For brand positioning guidance:
  * Budget: Skeleton, DHD, Avix, Orca
  * Mid-range: Pioneer, Kenwood, JVC, Exxent
  * Premium: Nakamichi, Clarion, Hertz, JL Audio, Rockford Fosgate
- For CAR-SPECIFIC recommendations:
  * City Car (Brio, Agya, Ayla): Focus on space-efficient solutions
    - Subwoofer kolong/underseat (NO boxed subwoofer unless custom install)
    - Speaker 5.25" or 6.5" (check factory size)
    - Compact amplifier
    - Single DIN head unit if dashboard is small
  * MPV (Xpander, Avanza, Xenia): Full system possible
    - Head Unit Android 9-10" (double DIN)
    - Speaker component 6.5" front, coaxial 6x9" rear
    - Subwoofer 10-12" boxed (trunk space available)
    - Amplifier 4 channel 75W+
  * SUV (Fortuner, Pajero, CR-V): Premium setups
    - High-quality components
    - DSP processor for tuning
    - Powerful subwoofer and amplifier
  * Sedan (Civic, Camry, Corolla): Sound quality focus
    - Component speakers for staging
    - Sealed box subwoofer (tight bass)
    - Low THD amplifier

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


def _extract_car_mention(text: str) -> dict | None:
    """Extract car brand and model from user message.
    
    Returns dict with 'brand' and 'model' keys, or None if no car detected.
    """
    text_lower = text.lower()
    
    # Comprehensive car database mapping
    # Format: 'keyword': (brand, model, type)
    car_keywords = {
        # MPV
        'xpander': ('Mitsubishi', 'Xpander', 'MPV'),
        'avanza': ('Toyota', 'Avanza', 'MPV'),
        'xenia': ('Daihatsu', 'Xenia', 'MPV'),
        'innova': ('Toyota', 'Innova', 'MPV'),
        'ertiga': ('Suzuki', 'Ertiga', 'MPV'),
        'mobilio': ('Honda', 'Mobilio', 'MPV'),
        'confero': ('Wuling', 'Confero', 'MPV'),
        'livina': ('Nissan', 'Livina', 'MPV'),
        'stargazer': ('Hyundai', 'Stargazer', 'MPV'),
        'alphard': ('Toyota', 'Alphard', 'MPV'),
        'veloz': ('Toyota', 'Veloz', 'MPV'),
        
        # City Car
        'brio': ('Honda', 'Brio', 'City Car'),
        'agya': ('Toyota', 'Agya', 'City Car'),
        'ayla': ('Daihatsu', 'Ayla', 'City Car'),
        's-presso': ('Suzuki', 'S-Presso', 'City Car'),
        'spresso': ('Suzuki', 'S-Presso', 'City Car'),
        'calya': ('Toyota', 'Calya', 'City Car'),
        'sigra': ('Daihatsu', 'Sigra', 'City Car'),
        'air ev': ('Wuling', 'Air EV', 'City Car'),
        'i10': ('Hyundai', 'i10', 'City Car'),
        
        # SUV
        'fortuner': ('Toyota', 'Fortuner', 'SUV'),
        'pajero': ('Mitsubishi', 'Pajero Sport', 'SUV'),
        'cr-v': ('Honda', 'CR-V', 'SUV'),
        'crv': ('Honda', 'CR-V', 'SUV'),
        'cx-5': ('Mazda', 'CX-5', 'SUV'),
        'cx5': ('Mazda', 'CX-5', 'SUV'),
        'tucson': ('Hyundai', 'Tucson', 'SUV'),
        'santa fe': ('Hyundai', 'Santa Fe', 'SUV'),
        'rush': ('Toyota', 'Rush', 'SUV'),
        'terios': ('Daihatsu', 'Terios', 'SUV'),
        'xl7': ('Suzuki', 'XL7', 'SUV'),
        'almaz': ('Wuling', 'Almaz', 'SUV'),
        'corolla cross': ('Toyota', 'Corolla Cross', 'SUV'),
        'xpander cross': ('Mitsubishi', 'Xpander Cross', 'SUV'),
        
        # Sedan
        'civic': ('Honda', 'Civic', 'Sedan'),
        'accord': ('Honda', 'Accord', 'Sedan'),
        'camry': ('Toyota', 'Camry', 'Sedan'),
        'corolla altis': ('Toyota', 'Corolla Altis', 'Sedan'),
        'corolla': ('Toyota', 'Corolla Altis', 'Sedan'),
        'mazda 3': ('Mazda', 'Mazda 3', 'Sedan'),
        'elantra': ('Hyundai', 'Elantra', 'Sedan'),
        'city': ('Honda', 'City', 'Sedan'),
        'vios': ('Toyota', 'Vios', 'Sedan'),
        
        # Hatchback
        'jazz': ('Honda', 'Jazz', 'Hatchback'),
        'baleno': ('Suzuki', 'Baleno', 'Hatchback'),
        'swift': ('Suzuki', 'Swift', 'Hatchback'),
        'xforce': ('Mitsubishi', 'Xforce', 'Hatchback'),
        'yaris': ('Toyota', 'Yaris', 'Hatchback'),
        'hr-v': ('Honda', 'HR-V', 'Hatchback'),
        'hrv': ('Honda', 'HR-V', 'Hatchback'),
        
        # Pickup/Commercial
        'l300': ('Mitsubishi', 'L300', 'Pickup'),
        'carry': ('Suzuki', 'Carry', 'Pickup'),
        'gran max': ('Daihatsu', 'Gran Max', 'Pickup'),
        'hilux': ('Toyota', 'Hilux', 'Pickup'),
        'ranger': ('Ford', 'Ranger', 'Pickup'),
        'd-max': ('Isuzu', 'D-Max', 'Pickup'),
        'dmax': ('Isuzu', 'D-Max', 'Pickup'),
        
        # Van/Minibus
        'hiace': ('Toyota', 'HiAce', 'Van'),
        'luxio': ('Daihatsu', 'Luxio', 'Van'),
        'apv': ('Suzuki', 'APV', 'Van'),
    }
    
    # Also check for brand-only mentions (will try to infer model)
    car_brands = {
        'toyota': 'Toyota',
        'honda': 'Honda',
        'mitsubishi': 'Mitsubishi',
        'daihatsu': 'Daihatsu',
        'suzuki': 'Suzuki',
        'hyundai': 'Hyundai',
        'nissan': 'Nissan',
        'wuling': 'Wuling',
        'mazda': 'Mazda',
        'ford': 'Ford',
        'isuzu': 'Isuzu',
    }
    
    # First, check for specific car models
    for keyword, (brand, model, car_type) in car_keywords.items():
        if keyword in text_lower:
            return {
                'brand': brand,
                'model': model,
                'type': car_type
            }
    
    # If no specific model found, check for brand mentions with type hints
    for keyword, brand in car_brands.items():
        if keyword in text_lower:
            # Check for type keywords after brand
            if any(t in text_lower for t in ['mpv', 'suv', 'city car', 'sedan', 'hatchback', 'pickup']):
                return {
                    'brand': brand,
                    'model': '',  # Will match all models of this brand
                    'type': ''
                }
    
    return None
