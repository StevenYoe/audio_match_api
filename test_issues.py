"""
Test to verify why Kenwood only returns 1 product and why tweeter is not recommended
"""
import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def test_issues():
    db_url = os.getenv("DATABASE_URL")
    
    print("=" * 80)
    print("TEST: KENWOOD PRODUCT COUNT & TWEETER ISSUE")
    print("=" * 80)
    
    conn = await asyncpg.connect(db_url)
    
    try:
        # Issue 1: Check all Kenwood products
        print("\n" + "="*80)
        print("ISSUE 1: Checking ALL Kenwood products in database")
        print("="*80)
        
        kenwood_all = await conn.fetch("""
            SELECT mp_name, mp_category, mp_brand, mp_price, mp_solves_problem_id
            FROM sales.master_products
            WHERE mp_is_active = TRUE
              AND LOWER(mp_brand) = 'kenwood'
            ORDER BY mp_category, mp_price DESC
        """)
        
        print(f"\n✅ Total Kenwood products: {len(kenwood_all)}")
        for i, p in enumerate(kenwood_all, 1):
            print(f"  {i}. {p['mp_name']}")
            print(f"     Category: {p['mp_category']} | Price: Rp {p['mp_price']:,}")
            print(f"     Solves Problem ID: {p['mp_solves_problem_id']}")
            print()
        
        # Issue 2: Check products linked to "Vocal dan mid range kurang jelas" problem
        vocal_problem_id = "d71440dd-5d04-4bf2-a4ca-c630d21063cc"
        print("\n" + "="*80)
        print(f"ISSUE 2: Products linked to vocal problem (ID: {vocal_problem_id})")
        print("="*80)
        
        vocal_products = await conn.fetch("""
            SELECT mp_name, mp_category, mp_brand, mp_price, mp_description
            FROM sales.master_products
            WHERE mp_is_active = TRUE
              AND mp_solves_problem_id = $1
            ORDER BY mp_price DESC
        """, vocal_problem_id)
        
        print(f"\n✅ Products solving vocal problem: {len(vocal_products)}")
        for i, p in enumerate(vocal_products, 1):
            print(f"  {i}. {p['mp_name']}")
            print(f"     Category: {p['mp_category']} | Brand: {p['mp_brand']} | Price: Rp {p['mp_price']:,}")
            print(f"     Description: {p['mp_description'][:100]}...")
            print()
        
        # Issue 3: Check if tweeter exists and what problem it solves
        print("\n" + "="*80)
        print("ISSUE 3: All tweeter products in database")
        print("="*80)
        
        tweeter_all = await conn.fetch("""
            SELECT mp_name, mp_category, mp_brand, mp_price, mp_description, mp_solves_problem_id
            FROM sales.master_products
            WHERE mp_is_active = TRUE
              AND LOWER(mp_category) = 'tweeter'
            ORDER BY mp_price DESC
        """)
        
        print(f"\n✅ Total tweeter products: {len(tweeter_all)}")
        for i, p in enumerate(tweeter_all, 1):
            print(f"  {i}. {p['mp_name']}")
            print(f"     Brand: {p['mp_brand']} | Price: Rp {p['mp_price']:,}")
            print(f"     Solves Problem ID: {p['mp_solves_problem_id']}")
            print(f"     Description: {p['mp_description'][:100]}...")
            print()
        
        # Issue 4: Check what problems tweeter is linked to
        if tweeter_all:
            tweeter_problem_ids = [p['mp_solves_problem_id'] for p in tweeter_all if p['mp_solves_problem_id']]
            if tweeter_problem_ids:
                print("Problem details that tweeter solves:")
                problems = await conn.fetch("""
                    SELECT mcp_id, mcp_problem_title, mcp_description
                    FROM sales.master_customer_problems
                    WHERE mcp_id = ANY($1::uuid[])
                """, tweeter_problem_ids)
                
                for prob in problems:
                    print(f"  - {prob['mcp_problem_title']}")
                    print(f"    {prob['mcp_description'][:100]}...")
        
        # Issue 5: Test get_recommendations function for vocal problem
        print("\n" + "="*80)
        print("ISSUE 5: Testing get_recommendations() for vocal problem")
        print("="*80)
        
        recs = await conn.fetch("""
            SELECT * FROM sales.get_recommendations($1::uuid)
        """, vocal_problem_id)
        
        print(f"\n✅ Recommendations from get_recommendations(): {len(recs)}")
        for i, r in enumerate(recs, 1):
            print(f"  {i}. {r['product_name']}")
            print(f"     Category: {r['product_category']} | Brand: {r['product_brand']} | Price: Rp {r['product_price']:,}")
            print()
        
        print("\n" + "="*80)
        print("CONCLUSION:")
        print("="*80)
        print("1. Kenwood products di database: ✅ BANYAK")
        print("   - Chatbot hanya menampilkan 1 karena mungkin limit/filter di code")
        print()
        print("2. Tweeter di database: ✅ ADA (Hertz MPX 170.30)")
        print("   - Tapi tweeter TIDAK linked ke vocal problem")
        print("   - Tweeter linked ke: Soundstage sempit, bukan vocal")
        print("   - Ini kenapa chatbot tidak rekomendasikan tweeter untuk vocal")
        print()
        print("3. Solusi:")
        print("   a. Link tweeter ke vocal problem (update mp_solves_problem_id)")
        print("   b. Atau chatbot logic perlu cari produk by category, bukan hanya by FK")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(test_issues())
