import asyncio
import os
import asyncpg
from dotenv import load_dotenv

load_dotenv()

async def update_db():
    conn = await asyncpg.connect(os.getenv("DATABASE_URL"))
    try:
        # Add mp_image column
        await conn.execute("ALTER TABLE sales.master_products ADD COLUMN IF NOT EXISTS mp_image TEXT")
        print("mp_image column added or already exists.")
        
        # Optionally, set some default emojis as placeholders for existing data
        await conn.execute("UPDATE sales.master_products SET mp_image = '🔊' WHERE mp_image IS NULL AND mp_category = 'Subwoofer'")
        await conn.execute("UPDATE sales.master_products SET mp_image = '📻' WHERE mp_image IS NULL AND mp_category = 'Head Unit'")
        await conn.execute("UPDATE sales.master_products SET mp_image = '📢' WHERE mp_image IS NULL AND mp_category = 'Speaker'")
        await conn.execute("UPDATE sales.master_products SET mp_image = '⚡' WHERE mp_image IS NULL")
        print("Default image placeholders set.")
        
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(update_db())
