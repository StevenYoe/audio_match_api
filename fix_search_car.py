#!/usr/bin/env python3
"""Quick fix for search_car function return type"""

import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

async def main():
    conn = await asyncpg.connect(DATABASE_URL)
    
    print("Fixing search_car function return type...")
    
    fix_sql = """
    CREATE OR REPLACE FUNCTION sales.search_car(
        search_brand TEXT,
        search_model TEXT
    )
    RETURNS TABLE (
        mc_id UUID,
        mc_brand TEXT,
        mc_model TEXT,
        mc_type TEXT,
        mc_size_category TEXT,
        mc_dashboard_type TEXT,
        mc_door_count INTEGER,
        mc_cabin_volume TEXT,
        mc_subwoofer_space TEXT,
        mc_factory_speaker_size TEXT,
        mc_factory_speaker_count INTEGER,
        mc_special_notes TEXT,
        similarity DOUBLE PRECISION
    ) AS $$
    BEGIN
        RETURN QUERY
        SELECT 
            c.mc_id,
            c.mc_brand,
            c.mc_model,
            c.mc_type,
            c.mc_size_category,
            c.mc_dashboard_type,
            c.mc_door_count,
            c.mc_cabin_volume,
            c.mc_subwoofer_space,
            c.mc_factory_speaker_size,
            c.mc_factory_speaker_count,
            c.mc_special_notes,
            CAST(CASE 
                WHEN LOWER(c.mc_brand) = LOWER(search_brand) AND LOWER(c.mc_model) = LOWER(search_model) THEN 1.0
                WHEN LOWER(c.mc_brand) = LOWER(search_brand) THEN 0.8
                WHEN LOWER(c.mc_model) = LOWER(search_model) THEN 0.7
                WHEN LOWER(c.mc_type) = LOWER(search_brand) THEN 0.6
                ELSE 0.5
            END AS DOUBLE PRECISION) AS similarity
        FROM sales.master_cars c
        WHERE c.mc_is_active = TRUE
          AND (
              LOWER(c.mc_brand) = LOWER(search_brand)
              OR LOWER(c.mc_model) = LOWER(search_model)
              OR LOWER(c.mc_type) = LOWER(search_brand)
              OR LOWER(c.mc_brand || ' ' || c.mc_model) LIKE '%' || LOWER(search_brand) || '%'
              OR LOWER(c.mc_model) LIKE '%' || LOWER(search_model) || '%'
          )
        ORDER BY similarity DESC
        LIMIT 5;
    END;
    $$ LANGUAGE plpgsql;
    """
    
    await conn.execute(fix_sql)
    print("✅ Fixed search_car function")
    
    # Test it
    results = await conn.fetch("SELECT * FROM sales.search_car($1, $2)", 'Honda', 'Brio')
    if results:
        car = results[0]
        print(f"✅ Test passed: {car['mc_brand']} {car['mc_model']}")
        print(f"   Type: {car['mc_type']}, Size: {car['mc_size_category']}")
    
    await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
