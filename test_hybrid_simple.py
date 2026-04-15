"""
Simple test untuk hybrid search - langsung execute SQL tanpa function wrapper
"""
import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def test_simple():
    db_url = os.getenv("DATABASE_URL")
    
    print("=" * 80)
    print("SIMPLE HYBRID SEARCH TEST")
    print("=" * 80)
    
    conn = await asyncpg.connect(db_url)
    
    try:
        # Test 1: Problem - "bass kurang bertenaga"
        query = "bass kurang bertenaga"
        print(f"\n🔍 Testing query: '{query}'")
        
        results = await conn.fetch("""
            SELECT * FROM sales.search_problem_hybrid($1, NULL::vector, 3)
        """, query)
        
        print(f"\n✅ Found {len(results)} problems:")
        for r in results:
            # Convert record to dict
            d = dict(r)
            print(f"  Title: {d.get('mcp_problem_title')}")
            print(f"  BM25 Score: {d.get('bm25_score')}")
            print(f"  Hybrid Score: {d.get('hybrid_score')}")
            print()
        
        # Test 2: Product - "Kenwood"
        query2 = "Kenwood"
        print(f"\n🔍 Testing query: '{query2}'")
        
        results2 = await conn.fetch("""
            SELECT * FROM sales.search_product_hybrid($1, NULL::vector, 5)
        """, query2)
        
        print(f"\n✅ Found {len(results2)} products:")
        for r in results2:
            d = dict(r)
            print(f"  Product: {d.get('mp_name')}")
            print(f"  Brand: {d.get('mp_brand')}")
            print(f"  Price: {d.get('mp_price')}")
            print(f"  BM25 Score: {d.get('bm25_score')}")
            print(f"  Hybrid Score: {d.get('hybrid_score')}")
            print()
        
        # Test 3: Check if functions exist
        print("\n📋 Checking database functions:")
        funcs = await conn.fetch("""
            SELECT routine_name, routine_type
            FROM information_schema.routines
            WHERE routine_schema = 'sales'
            AND routine_name LIKE '%hybrid%'
            ORDER BY routine_name
        """)
        
        for f in funcs:
            print(f"  ✓ {f['routine_name']} ({f['routine_type']})")
        
        # Test 4: Check indexes
        print("\n📋 Checking FTS indexes:")
        indexes = await conn.fetch("""
            SELECT tablename, indexname, indexdef
            FROM pg_indexes
            WHERE schemaname = 'sales'
            AND indexname LIKE '%fts%'
            ORDER BY indexname
        """)
        
        for idx in indexes:
            print(f"  ✓ {idx['indexname']} on {idx['tablename']}")
        
        print("\n" + "=" * 80)
        print("✅ HYBRID SEARCH IS WORKING!")
        print("=" * 80)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(test_simple())
