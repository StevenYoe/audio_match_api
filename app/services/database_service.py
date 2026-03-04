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
        query = """
        SELECT mcp_id, mcp_problem_title, similarity
        FROM sales.search_problem($1, $2, $3)
        """
        # Convert list to string for pgvector compatibility with asyncpg
        return await self.fetch(query, str(embedding), 0.4, 3)

    async def search_problem_lexical(self, query_text: str) -> List[Dict[str, Any]]:
        """
        New Lexical Search (Keyword Matching) algorithm.
        """
        query = """
        SELECT mcp_id, mcp_problem_title, similarity
        FROM sales.search_problem_lexical($1, $2)
        """
        return await self.fetch(query, query_text, 3)

    async def get_recommendations(self, problem_id: str) -> List[Dict[str, Any]]:
        query = """
        SELECT
            s.ms_id as solution_id,
            s.ms_title as solution_title,
            s.ms_description as solution_description,
            p.mp_id as product_id,
            p.mp_name as product_name,
            p.mp_category as product_category,
            p.mp_price as product_price,
            p.mp_image as product_image
        FROM sales.master_solutions s
        JOIN sales.master_solution_products sp ON sp.msp_solution_id = s.ms_id
        JOIN sales.master_products p ON p.mp_id = sp.msp_product_id
        WHERE s.ms_problem_id = $1
          AND s.ms_is_active = TRUE
          AND p.mp_is_active = TRUE
        ORDER BY s.ms_priority ASC;
        """
        return await self.fetch(query, problem_id)

    async def get_products(self, category: str = None) -> List[Dict[str, Any]]:
        if category and category.lower() != "all":
            query = "SELECT * FROM sales.master_products WHERE mp_category = $1 AND mp_is_active = TRUE ORDER BY mp_name ASC"
            return await self.fetch(query, category)
        else:
            query = "SELECT * FROM sales.master_products WHERE mp_is_active = TRUE ORDER BY mp_name ASC"
            return await self.fetch(query)

    async def search_knowledge(self, embedding: List[float]) -> List[Dict[str, Any]]:
        query = """
        SELECT mkc_id, mkc_content, similarity
        FROM sales.search_knowledge($1, $2, $3)
        """
        # Convert list to string for pgvector compatibility with asyncpg
        return await self.fetch(query, str(embedding), 0.4, 5)

    async def create_session(self, user_identifier: str) -> Dict[str, Any]:
        query = """
        INSERT INTO sales.trx_conversation_sessions (tcs_user_identifier)
        VALUES ($1) RETURNING tcs_id, tcs_user_identifier, tcs_started_at
        """
        return await self.fetchrow(query, user_identifier)
    
    async def get_session(self, session_id: str) -> Dict[str, Any]:
        query = "SELECT * FROM sales.trx_conversation_sessions WHERE tcs_id = $1"
        return await self.fetchrow(query, session_id)

    async def log_message(self, session_id: str, role: str, content: str, related_problem: str = None):
        query = """
        INSERT INTO sales.trx_chat_messages (tcm_session_id, tcm_role, tcm_content, tcm_related_problem)
        VALUES ($1, $2, $3, $4)
        """
        await self.execute(query, session_id, role, content, related_problem)

    # --- ADMIN/SYNC METHODS ---
    async def get_unembedded_problems(self) -> List[Dict[str, Any]]:
        query = "SELECT mcp_id, mcp_problem_title, mcp_description FROM sales.master_customer_problems WHERE mcp_embedding IS NULL AND mcp_is_active = TRUE"
        return await self.fetch(query)

    async def update_problem_embedding(self, problem_id: str, embedding: List[float]):
        query = "UPDATE sales.master_customer_problems SET mcp_embedding = $1 WHERE mcp_id = $2"
        await self.execute(query, str(embedding), problem_id)

    async def get_unembedded_knowledge(self) -> List[Dict[str, Any]]:
        query = "SELECT mkc_id, mkc_content FROM sales.master_knowledge_chunks WHERE mkc_embedding IS NULL AND mkc_is_active = TRUE"
        return await self.fetch(query)

    async def update_knowledge_embedding(self, chunk_id: str, embedding: List[float]):
        query = "UPDATE sales.master_knowledge_chunks SET mkc_embedding = $1 WHERE mkc_id = $2"
        await self.execute(query, str(embedding), chunk_id)

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
