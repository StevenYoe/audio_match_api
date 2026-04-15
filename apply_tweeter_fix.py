#!/usr/bin/env python3
"""
Quick script to apply the tweeter problem linkage fix
"""

import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

async def apply_fix():
    conn = await asyncpg.connect(DATABASE_URL)
    
    try:
        # Fix Hertz tweeter linkage
        print("Fixing Hertz Mille Pro tweeter problem linkage...")
        await conn.execute("""
            UPDATE sales.master_products
            SET mp_solves_problem_id = 'd71440dd-5d04-4bf2-a4ca-c630d21063cc'
            WHERE mp_name = 'Tweeter Hertz Mille Pro MPX 170.30'
              AND mp_solves_problem_id = 'bad8f281-a1ff-4abe-8238-89365e95e58d';
        """)
        
        # Verify the fix
        result = await conn.fetch("""
            SELECT mp_name, mp_brand, mp_category, mp_price, mp_solves_problem_id,
                   (SELECT mcp_problem_title FROM sales.master_customer_problems WHERE mcp_id = mp_solves_problem_id) as problem_title
            FROM sales.master_products
            WHERE mp_category = 'tweeter'
            ORDER BY mp_price DESC;
        """)
        
        print("\n✅ Tweeter products after fix:")
        for row in result:
            print(f"  - {row['mp_name']} (Rp {row['mp_price']:,}) -> {row['problem_title']}")
        
        print("\n🎉 Fix applied successfully!")
        
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(apply_fix())
