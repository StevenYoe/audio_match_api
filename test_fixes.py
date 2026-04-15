#!/usr/bin/env python3
"""
Test script to verify the fixes for:
1. Brand search showing all products
2. Tweeter recommendations for vocal clarity issues
"""

import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

async def test_fixes():
    conn = await asyncpg.connect(DATABASE_URL)
    
    print("=" * 80)
    print("TESTING FIX #1: Brand Search (Kenwood Products)")
    print("=" * 80)
    
    # Test getting all Kenwood products
    kenwood_products = await conn.fetch("""
        SELECT mp_id, mp_name, mp_category, mp_brand, mp_price
        FROM sales.master_products
        WHERE LOWER(mp_brand) = 'kenwood'
          AND mp_is_active = TRUE
        ORDER BY mp_category, mp_price DESC;
    """)
    
    print(f"\n✅ Found {len(kenwood_products)} Kenwood products in database:")
    by_category = {}
    for p in kenwood_products:
        cat = p['mp_category']
        if cat not in by_category:
            by_category[cat] = []
        by_category[cat].append(p)
    
    for cat in sorted(by_category.keys()):
        print(f"\n  [{cat.upper().replace('_', ' ')}]")
        for p in by_category[cat]:
            print(f"    - {p['mp_name']} - Rp {p['mp_price']:,}")
    
    print("\n" + "=" * 80)
    print("TESTING FIX #2: Tweeter Recommendations for Vocal Clarity")
    print("=" * 80)
    
    # Get vocal problem ID
    vocal_problem = await conn.fetchrow("""
        SELECT mcp_id, mcp_problem_title
        FROM sales.master_customer_problems
        WHERE mcp_problem_title LIKE '%Vocal dan mid range%'
          AND mcp_is_active = TRUE;
    """)
    
    print(f"\nProblem: {vocal_problem['mcp_problem_title']} (ID: {vocal_problem['mcp_id']})")
    
    # Get products linked to vocal problem
    vocal_products = await conn.fetch("""
        SELECT 
            p.mp_id,
            p.mp_name,
            p.mp_category,
            p.mp_brand,
            p.mp_price,
            prob.mcp_problem_title
        FROM sales.master_products p
        JOIN sales.master_customer_problems prob ON prob.mcp_id = p.mp_solves_problem_id
        WHERE p.mp_solves_problem_id = $1
          AND p.mp_is_active = TRUE
        ORDER BY
            CASE
                WHEN p.mp_category = 'tweeter' THEN 1
                WHEN p.mp_category = 'speaker_component' THEN 2
                ELSE 3
            END,
            p.mp_price DESC;
    """, vocal_problem['mcp_id'])
    
    print(f"\n✅ Found {len(vocal_products)} products for vocal clarity:")
    
    tweeters = [p for p in vocal_products if p['mp_category'] == 'tweeter']
    components = [p for p in vocal_products if p['mp_category'] == 'speaker_component']
    others = [p for p in vocal_products if p['mp_category'] not in ['tweeter', 'speaker_component']]
    
    if tweeters:
        print("\n  🎶 TWEETERS (Primary recommendation for vocal):")
        for p in tweeters:
            print(f"    - {p['mp_name']} - Rp {p['mp_price']:,}")
    
    if components:
        print("\n  🎵 SPEAKER COMPONENTS (Secondary recommendation):")
        for p in components:
            print(f"    - {p['mp_name']} - Rp {p['mp_price']:,}")
    
    if others:
        print("\n  🔊 OTHER PRODUCTS:")
        for p in others:
            print(f"    - {p['mp_name']} - Rp {p['mp_price']:,}")
    
    print("\n" + "=" * 80)
    print("VERIFICATION SUMMARY")
    print("=" * 80)
    
    checks = {
        "Kenwood products count": len(kenwood_products) > 1,
        "Kenwood has multiple categories": len(by_category) > 1,
        "Tweeters for vocal problem": len(tweeters) >= 2,
        "Hertz tweeter linked to vocal": any('Hertz' in p['mp_name'] for p in tweeters),
        "Kenwood tweeter linked to vocal": any('Kenwood' in p['mp_name'] for p in tweeters),
    }
    
    all_passed = True
    for check_name, result in checks.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}: {check_name}")
        if not result:
            all_passed = False
    
    print("\n" + "=" * 80)
    if all_passed:
        print("🎉 ALL TESTS PASSED! Fixes are working correctly.")
    else:
        print("⚠️  Some tests failed. Please review the output above.")
    print("=" * 80)
    
    await conn.close()

if __name__ == "__main__":
    asyncio.run(test_fixes())
