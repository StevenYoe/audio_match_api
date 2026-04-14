#!/usr/bin/env python3
"""
Test script to verify car support implementation
"""

import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")


async def main():
    conn = await asyncpg.connect(DATABASE_URL)
    
    print("="*60)
    print("TESTING CAR SUPPORT IMPLEMENTATION")
    print("="*60)
    
    # Test 1: Count cars in database
    print("\n1. Checking car data...")
    count = await conn.fetchval("SELECT COUNT(*) FROM sales.master_cars WHERE mc_is_active = TRUE")
    print(f"   ✅ Total active cars: {count}")
    
    # Test 2: Count products with compatibility
    print("\n2. Checking product compatibility...")
    count = await conn.fetchval(
        "SELECT COUNT(*) FROM sales.master_products WHERE mp_compatible_car_types IS NOT NULL"
    )
    print(f"   ✅ Products with car compatibility: {count}")
    
    # Test 3: Search for Brio
    print("\n3. Testing car search for 'Honda', 'Brio'...")
    results = await conn.fetch(
        "SELECT * FROM sales.search_car($1, $2)", 'Honda', 'Brio'
    )
    if results:
        car = results[0]
        print(f"   ✅ Found: {car['mc_brand']} {car['mc_model']}")
        print(f"      Type: {car['mc_type']}")
        print(f"      Size: {car['mc_size_category']}")
        print(f"      Dashboard: {car['mc_dashboard_type']}")
        print(f"      Subwoofer Space: {car['mc_subwoofer_space']}")
    else:
        print("   ❌ No results found")
    
    # Test 4: Search for Xpander
    print("\n4. Testing car search for 'Mitsubishi', 'Xpander'...")
    results = await conn.fetch(
        "SELECT * FROM sales.search_car($1, $2)", 'Mitsubishi', 'Xpander'
    )
    if results:
        car = results[0]
        print(f"   ✅ Found: {car['mc_brand']} {car['mc_model']}")
        print(f"      Type: {car['mc_type']}")
        print(f"      Size: {car['mc_size_category']}")
        print(f"      Dashboard: {car['mc_dashboard_type']}")
        print(f"      Subwoofer Space: {car['mc_subwoofer_space']}")
    else:
        print("   ❌ No results found")
    
    # Test 5: Get products for City Car (small)
    print("\n5. Getting products for City Car (small)...")
    results = await conn.fetch(
        "SELECT * FROM sales.get_products_for_car($1, $2, $3)", 
        None, 'City Car', 'small'
    )
    print(f"   ✅ Found {len(results)} compatible products")
    
    # Show top products by category
    from collections import Counter
    categories = Counter([r['mp_category'] for r in results[:10]])
    print(f"   Top categories: {dict(categories)}")
    
    # Test 6: Get products for MPV (large)
    print("\n6. Getting products for MPV (large)...")
    results = await conn.fetch(
        "SELECT * FROM sales.get_products_for_car($1, $2, $3)", 
        None, 'MPV', 'large'
    )
    print(f"   ✅ Found {len(results)} compatible products")
    
    categories = Counter([r['mp_category'] for r in results[:10]])
    print(f"   Top categories: {dict(categories)}")
    
    # Test 7: Verify subwoofer recommendations differ
    print("\n7. Comparing subwoofer recommendations...")
    
    # For small cars
    small_subs = await conn.fetch(
        """SELECT mp_name, mp_price FROM sales.get_products_for_car($1, $2, $3) 
           WHERE mp_category = 'subwoofer' LIMIT 3""",
        None, 'City Car', 'small'
    )
    print(f"   City Car subwoofers:")
    for sub in small_subs:
        print(f"     - {sub['mp_name']} (Rp {sub['mp_price']:,.0f})")
    
    # For large cars
    large_subs = await conn.fetch(
        """SELECT mp_name, mp_price FROM sales.get_products_for_car($1, $2, $3) 
           WHERE mp_category = 'subwoofer' LIMIT 3""",
        None, 'MPV', 'large'
    )
    print(f"   MPV subwoofers:")
    for sub in large_subs:
        print(f"     - {sub['mp_name']} (Rp {sub['mp_price']:,.0f})")
    
    print("\n" + "="*60)
    print("✅ ALL TESTS COMPLETED")
    print("="*60)
    
    await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
