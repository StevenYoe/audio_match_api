import asyncio
import os
import asyncpg
from dotenv import load_dotenv

load_dotenv()

async def check_solutions():
    conn = await asyncpg.connect(os.getenv("DATABASE_URL"))
    try:
        rows = await conn.fetch("SELECT p.mcp_problem_title, COUNT(s.ms_id) as solution_count FROM sales.master_customer_problems p LEFT JOIN sales.master_solutions s ON s.ms_problem_id = p.mcp_id GROUP BY p.mcp_id, p.mcp_problem_title")
        print("\nDatabase Solutions Status:")
        for row in rows:
            print(f"- Problem: '{row['mcp_problem_title']}' | Solutions: {row['solution_count']}")
            
        rows_p = await conn.fetch("SELECT s.ms_title, COUNT(sp.msp_product_id) as product_count FROM sales.master_solutions s LEFT JOIN sales.master_solution_products sp ON sp.msp_solution_id = s.ms_id GROUP BY s.ms_id, s.ms_title")
        print("\nSolution Product Links Status:")
        for row in rows_p:
            print(f"- Solution: '{row['ms_title']}' | Product Links: {row['product_count']}")
            
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(check_solutions())
