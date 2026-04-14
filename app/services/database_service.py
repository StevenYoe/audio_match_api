import asyncpg
import ssl
from app.core.config import settings
from typing import List, Dict, Any

class DatabaseService:
    def __init__(self, pool):
        self.pool = pool

    async def fetch(self, query: str, *args) -> List[Dict[str, Any]]:
        async with self.pool.acquire() as connection:
            return [dict(row) for row in await connection.fetch(query, *args)]

    async def fetchrow(self, query: str, *args) -> Dict[str, Any]:
        async with self.pool.acquire() as connection:
            row = await connection.fetchrow(query, *args)
            return dict(row) if row else None

    async def execute(self, query: str, *args) -> str:
        async with self.pool.acquire() as connection:
            return await connection.execute(query, *args)

    async def search_problem(self, embedding: List[float]) -> List[Dict[str, Any]]:
        """Vector similarity search on master_customer_problems."""
        query = """
        SELECT mcp_id, mcp_problem_title, mcp_description, mcp_recommended_approach, similarity
        FROM sales.search_problem($1, $2, $3)
        """
        return await self.fetch(query, str(embedding), 0.4, 3)

    async def get_recommendations(self, problem_id: str) -> List[Dict[str, Any]]:
        """Get products linked to a problem via direct FK.
        
        Products are ordered by price DESC (premium first) to ensure high-quality
        products are surfaced prominently. Budget products are still available
        but appear later in the list.
        """
        query = """
        SELECT
            p.mp_id as product_id,
            p.mp_name as product_name,
            p.mp_category as product_category,
            p.mp_brand as product_brand,
            p.mp_price as product_price,
            p.mp_description as product_description,
            p.mp_image as product_image,
            prob.mcp_problem_title as problem_title,
            prob.mcp_description as problem_description,
            prob.mcp_recommended_approach as recommended_approach
        FROM sales.master_products p
        JOIN sales.master_customer_problems prob ON prob.mcp_id = p.mp_solves_problem_id
        WHERE p.mp_solves_problem_id = $1
          AND p.mp_is_active = TRUE
          AND prob.mcp_is_active = TRUE
        ORDER BY 
            CASE 
                WHEN p.mp_brand IN ('JL Audio', 'Rockford Fosgate', 'Hertz', 'Nakamichi', 'Clarion') THEN 1
                WHEN p.mp_brand IN ('Pioneer', 'Kenwood', 'JVC', 'Exxent') THEN 2
                ELSE 3
            END ASC,
            p.mp_price DESC;
        """
        return await self.fetch(query, problem_id)

    async def get_products_by_brand(self, brand: str) -> List[Dict[str, Any]]:
        """Get all active products for a specific brand.
        
        Products are ordered by price DESC (premium first) to surface high-end
        products prominently when user has sufficient budget.
        """
        query = """
        SELECT
            mp_id as product_id,
            mp_name as product_name,
            mp_category as product_category,
            mp_brand as product_brand,
            mp_price as product_price,
            mp_description as product_description,
            mp_image as product_image
        FROM sales.master_products
        WHERE LOWER(mp_brand) = LOWER($1)
          AND mp_is_active = TRUE
        ORDER BY mp_price DESC;
        """
        return await self.fetch(query, brand)

    async def get_all_active_products(self) -> List[Dict[str, Any]]:
        """Get all active products."""
        query = """
        SELECT
            mp_id as product_id,
            mp_name as product_name,
            mp_category as product_category,
            mp_brand as product_brand,
            mp_price as product_price,
            mp_description as product_description,
            mp_image as product_image
        FROM sales.master_products
        WHERE mp_is_active = TRUE
        ORDER BY mp_category, mp_price ASC;
        """
        return await self.fetch(query)

    async def insert_products(self, products: List[Dict[str, Any]]) -> int:
        """Bulk insert products."""
        if not products:
            return 0
        
        query = """
        INSERT INTO sales.master_products 
            (mp_name, mp_category, mp_brand, mp_price, mp_description, mp_image, mp_solves_problem_id, mp_is_active)
        VALUES 
        """
        # Build multi-row INSERT
        values = []
        for i, p in enumerate(products):
            values.append(f"(${i*8+1}, ${i*8+2}, ${i*8+3}, ${i*8+4}, ${i*8+5}, ${i*8+6}, ${i*8+7}, ${i*8+8})")
        
        query += ", ".join(values)
        query += " RETURNING mp_id"
        
        params = []
        for p in products:
            params.extend([
                p.get('mp_name'),
                p.get('mp_category'),
                p.get('mp_brand'),
                p.get('mp_price'),
                p.get('mp_description'),
                p.get('mp_image'),
                p.get('mp_solves_problem_id'),
                p.get('mp_is_active', True)
            ])
        
        result = await self.fetch(query, *params)
        return len(result)

    async def insert_problems(self, problems: List[Dict[str, Any]]) -> int:
        """Bulk insert problems."""
        if not problems:
            return 0
        
        query = """
        INSERT INTO sales.master_customer_problems 
            (mcp_problem_title, mcp_description, mcp_recommended_approach, mcp_is_active)
        VALUES 
        """
        values = []
        for i, p in enumerate(problems):
            values.append(f"(${i*4+1}, ${i*4+2}, ${i*4+3}, ${i*4+4})")
        
        query += ", ".join(values)
        query += " RETURNING mcp_id"
        
        params = []
        for p in problems:
            params.extend([
                p.get('mcp_problem_title'),
                p.get('mcp_description'),
                p.get('mcp_recommended_approach'),
                p.get('mcp_is_active', True)
            ])
        
        result = await self.fetch(query, *params)
        return len(result)

    # --- ADMIN/SYNC METHODS ---
    async def get_unembedded_problems(self) -> List[Dict[str, Any]]:
        """Get problems without embeddings."""
        query = "SELECT mcp_id, mcp_problem_title, mcp_description FROM sales.master_customer_problems WHERE mcp_embedding IS NULL AND mcp_is_active = TRUE"
        return await self.fetch(query)

    async def update_problem_embedding(self, problem_id: str, embedding: List[float]):
        """Update problem embedding vector."""
        query = "UPDATE sales.master_customer_problems SET mcp_embedding = $1 WHERE mcp_id = $2"
        await self.execute(query, str(embedding), problem_id)

    async def get_unembedded_products(self) -> List[Dict[str, Any]]:
        """Get products without embeddings."""
        query = "SELECT mp_id, mp_name, mp_description, mp_category FROM sales.master_products WHERE mp_embedding IS NULL AND mp_is_active = TRUE"
        return await self.fetch(query)

    async def update_product_embedding(self, product_id: str, embedding: List[float]):
        """Update product embedding vector."""
        query = "UPDATE sales.master_products SET mp_embedding = $1 WHERE mp_id = $2"
        await self.execute(query, str(embedding), product_id)

    # --- CAR-RELATED METHODS ---
    async def search_car(self, brand: str, model: str) -> List[Dict[str, Any]]:
        """Search for a car by brand and model name."""
        query = """
        SELECT mc_id, mc_brand, mc_model, mc_type, mc_size_category, 
               mc_dashboard_type, mc_door_count, mc_cabin_volume,
               mc_subwoofer_space, mc_factory_speaker_size, 
               mc_factory_speaker_count, mc_special_notes, similarity
        FROM sales.search_car($1, $2)
        """
        return await self.fetch(query, brand, model)

    async def get_products_for_car(
        self, 
        car_type: str = None, 
        car_size: str = None
    ) -> List[Dict[str, Any]]:
        """Get products compatible with a specific car type and/or size."""
        query = """
        SELECT mp_id, mp_name, mp_category, mp_brand, mp_price, 
               mp_description, mp_image, compatibility_score
        FROM sales.get_products_for_car(NULL::UUID, $1, $2)
        """
        return await self.fetch(query, car_type, car_size)

    async def get_car_recommendations_context(
        self, 
        car: Dict[str, Any]
    ) -> str:
        """Build a formatted context string with products recommended for a specific car."""
        car_type = car.get('mc_type')
        car_size = car.get('mc_size_category')
        car_name = f"{car.get('mc_brand')} {car.get('mc_model')}"
        
        products = await self.get_products_for_car(car_type, car_size)
        
        if not products:
            # Fallback to all active products if no compatible products found
            products = await self.get_all_active_products()
        
        # Group products by category
        products_by_category = {}
        for prod in products:
            cat = prod['mp_category']
            if cat not in products_by_category:
                products_by_category[cat] = []
            products_by_category[cat].append(prod)

        # Build context string
        context = f"\nRECOMMENDED FOR: {car_name.upper()} ({car_type}, {car_size} cabin)\n"
        context += f"Dashboard: {car.get('mc_dashboard_type', 'double_din').replace('_', ' ').title()}\n"
        context += f"Cabin Volume: {car.get('mc_cabin_volume', 'N/A')}\n"
        context += f"Subwoofer Space: {car.get('mc_subwoofer_space', 'N/A')}\n"
        context += f"Factory Speaker: {car.get('mc_factory_speaker_size', 'N/A')} ({car.get('mc_factory_speaker_count', 0)} speakers)\n"

        if car.get('mc_special_notes'):
            context += f"Notes: {car['mc_special_notes']}\n"

        context += "\nCOMPATIBLE PRODUCTS (organized by category, best match first):\n"

        solution_products = []
        option_counter = 1

        for category in sorted(products_by_category.keys()):
            category_products = products_by_category[category]
            context += f"\n[{category.upper().replace('_', ' ')}]\n"
            for prod in category_products:
                context += f"Opsi {option_counter}. {prod['mp_name']} - Rp {prod['mp_price']}\n"
                context += f"   {prod['mp_description']}\n"
                prod['option_number'] = option_counter
                option_counter += 1
                solution_products.append({
                    "product_id": str(prod['mp_id']),
                    "product_name": prod['mp_name'],
                    "product_category": prod['mp_category'],
                    "product_price": float(prod['mp_price']),
                    "image": prod.get('mp_image') or "⚡"
                })
        
        return context, solution_products

async def get_db_pool():
    # Menggunakan ssl=True adalah cara paling standar bagi asyncpg untuk koneksi ke Neon
    # Sertakan juga timeout yang lebih tinggi untuk proses autentikasi
    return await asyncpg.create_pool(
        dsn=settings.DATABASE_URL,
        min_size=1, # Kecilkan min_size untuk mempercepat startup di Windows
        max_size=settings.DATABASE_MAX_OVERFLOW,
        timeout=60,
        command_timeout=60,
        ssl=True
    )

db_pool = None

async def get_database_service() -> DatabaseService:
    global db_pool
    if db_pool is None:
        db_pool = await get_db_pool()
    return DatabaseService(db_pool)
