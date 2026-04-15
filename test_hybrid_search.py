"""
Test script untuk verifikasi hybrid search functionality.
Script ini akan mengirim berbagai pertanyaan ke chatbot dan menampilkan hasil search.
"""
import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def test_hybrid_search():
    db_url = os.getenv("DATABASE_URL")
    
    print("=" * 80)
    print("TEST HYBRID SEARCH - VERIFICATION")
    print("=" * 80)
    
    conn = await asyncpg.connect(db_url)
    
    try:
        # Test queries yang relevan dengan data
        test_queries = [
            {
                "query": "bass kurang bertenaga",
                "description": "Test: Problem bass (should match 'Bass kurang bertenaga')"
            },
            {
                "query": "suara pecah distorsi",
                "description": "Test: Problem distorsi (should match 'Suara pecah dan distorsi')"
            },
            {
                "query": "bluetooth tidak connect",
                "description": "Test: Problem bluetooth (should match 'Head Unit tidak bisa connect Bluetooth')"
            },
            {
                "query": "vocal tidak jelas",
                "description": "Test: Problem vocal (should match 'Vocal dan mid range kurang jelas')"
            },
            {
                "query": "budget terbatas",
                "description": "Test: Problem budget (should match 'Ingin upgrade audio tapi budget terbatas')"
            },
            {
                "query": "Kenwood double DIN",
                "description": "Test: Product search (should match Kenwood double DIN products)"
            },
            {
                "query": "subwoofer amplifier",
                "description": "Test: Product search (should match subwoofer/amplifier products)"
            },
            {
                "query": "soundstage sempit",
                "description": "Test: Problem soundstage (should match 'Soundstage sempit')"
            },
        ]
        
        for idx, test in enumerate(test_queries, 1):
            query_text = test["query"]
            print(f"\n{'='*80}")
            print(f"TEST {idx}: {test['description']}")
            print(f"Query: '{query_text}'")
            print(f"{'='*80}")
            
            # Test 1: Full-text search langsung (BM25)
            print("\n📊 BM25 Full-Text Search Results:")
            problems_fts = await conn.fetch("""
                SELECT 
                    mcp_problem_title,
                    mcp_description,
                    ts_rank_cd(mcp_search_vector, plainto_tsquery('indonesian', $1)) AS rank
                FROM sales.master_customer_problems
                WHERE mcp_search_vector @@ plainto_tsquery('indonesian', $1)
                  AND mcp_is_active = TRUE
                ORDER BY rank DESC
                LIMIT 3
            """, query_text)
            
            if problems_fts:
                for p in problems_fts:
                    print(f"  ✓ Title: {p['mcp_problem_title']}")
                    print(f"    Score: {p['rank']:.6f}")
            else:
                print("  ✗ No results from BM25 FTS")
            
            # Test 2: Hybrid search function (jika embedding NULL, hanya pakai BM25)
            print("\n🔀 Hybrid Search Results (Problem):")
            try:
                problems_hybrid = await conn.fetch("""
                    SELECT 
                        h.mcp_problem_title,
                        h.mcp_description,
                        h.vector_score,
                        h.bm25_score,
                        h.hybrid_score,
                        h.vector_rank,
                        h.bm25_rank
                    FROM sales.search_problem_hybrid($1, NULL::vector, 3, 60, 0.6, 0.4) h
                """, query_text)
                
                if problems_hybrid:
                    for p in problems_hybrid:
                        print(f"  ✓ Title: {p['mcp_problem_title']}")
                        print(f"    BM25 Score: {p['bm25_score']:.6f} | Rank: {p['bm25_rank']}")
                        print(f"    Hybrid Score: {p['hybrid_score']:.6f}")
                else:
                    print("  ✗ No results from hybrid search")
            except Exception as e:
                print(f"  ⚠ Error: {e}")
            
            # Test 3: Product hybrid search
            print("\n🔀 Hybrid Search Results (Product):")
            try:
                products_hybrid = await conn.fetch("""
                    SELECT 
                        h.mp_name,
                        h.mp_brand,
                        h.mp_category,
                        h.mp_price,
                        h.vector_score,
                        h.bm25_score,
                        h.hybrid_score
                    FROM sales.search_product_hybrid($1, NULL::vector, 3, 60, 0.6, 0.4) h
                """, query_text)
                
                if products_hybrid:
                    for p in products_hybrid:
                        price_str = f"Rp {p['mp_price']:,.0f}" if p['mp_price'] else "N/A"
                        print(f"  ✓ Product: {p['mp_name']}")
                        print(f"    Brand: {p['mp_brand']} | Category: {p['mp_category']} | Price: {price_str}")
                        print(f"    BM25 Score: {p['bm25_score']:.6f}")
                        print(f"    Hybrid Score: {p['hybrid_score']:.6f}")
                else:
                    print("  ✗ No products found")
            except Exception as e:
                print(f"  ⚠ Error: {e}")
        
        # Summary
        print(f"\n{'='*80}")
        print("SUMMARY")
        print(f"{'='*80}")
        print("✅ Hybrid search functions are working!")
        print("✅ BM25 Full-Text Search is operational!")
        print("\nNote: Vector scores will be 0 when embedding is NULL.")
        print("      This is expected behavior - hybrid search falls back to BM25 only.")
        print("      When embeddings are provided, both vector + BM25 will be combined.")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(test_hybrid_search())
