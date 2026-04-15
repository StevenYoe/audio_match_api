#!/usr/bin/env python3
"""
Migration Runner for Car Support Feature
==========================================
This script runs all SQL migrations to add car type awareness to the recommendation system.

Usage:
    python run_migrations.py

Prerequisites:
    - DATABASE_URL environment variable must be set
    - All migration files must be in the migrations/ directory
"""

import asyncio
import asyncpg
import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    print("❌ ERROR: DATABASE_URL environment variable not set.")
    print("Please set it in your .env file or export it manually.")
    sys.exit(1)

# Migration files in order
MIGRATIONS = [
    "migrations/001_add_car_support.sql",
    "migrations/002_populate_car_data.sql",
    "migrations/003_update_product_compatibility.sql",
    "migrations/004_hybrid_search.sql",
    "migrations/005_fix_tweeter_problem_linkage.sql",
]


async def run_migration(conn, migration_file: str):
    """Run a single migration file."""
    filepath = Path(__file__).parent / migration_file
    
    if not filepath.exists():
        print(f"❌ ERROR: Migration file not found: {filepath}")
        return False
    
    print(f"\n{'='*60}")
    print(f"Running: {migration_file}")
    print(f"{'='*60}")
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            sql = f.read()
        
        await conn.execute(sql)
        print(f"✅ SUCCESS: {migration_file}")
        return True
        
    except Exception as e:
        print(f"❌ FAILED: {migration_file}")
        print(f"   Error: {str(e)}")
        return False


async def check_existing_tables(conn):
    """Check if car support tables already exist."""
    query = """
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'sales' 
        AND table_name = 'master_cars'
    );
    """
    row = await conn.fetchrow(query)
    return row['exists']


async def main():
    print("🚀 AudioMatch Car Support Migration Runner")
    print(f"📊 Database: {DATABASE_URL[:30]}...")
    print()
    
    # Connect to database
    try:
        conn = await asyncpg.connect(DATABASE_URL)
        print("✅ Connected to database")
    except Exception as e:
        print(f"❌ Failed to connect to database: {e}")
        sys.exit(1)
    
    try:
        # Check if migration already run
        tables_exist = await check_existing_tables(conn)
        if tables_exist:
            print("⚠️  WARNING: master_cars table already exists!")
            response = input("Do you want to continue? This may cause duplicate data. (y/n): ")
            if response.lower() != 'y':
                print("❌ Migration cancelled.")
                return
        
        # Run all migrations
        success_count = 0
        fail_count = 0
        
        for migration in MIGRATIONS:
            result = await run_migration(conn, migration)
            if result:
                success_count += 1
            else:
                fail_count += 1
                print(f"\n⚠️  Stopping migrations due to failure in: {migration}")
                break
        
        # Summary
        print(f"\n{'='*60}")
        print("📋 MIGRATION SUMMARY")
        print(f"{'='*60}")
        print(f"✅ Successful: {success_count}")
        print(f"❌ Failed: {fail_count}")
        print(f"📁 Total: {len(MIGRATIONS)}")
        
        if fail_count == 0:
            print("\n🎉 All migrations completed successfully!")
            print("\nNext steps:")
            print("1. Verify car data: SELECT COUNT(*) FROM sales.master_cars;")
            print("2. Verify product updates: SELECT COUNT(*) FROM sales.master_products WHERE mp_compatible_car_types IS NOT NULL;")
            print("3. Test car search: SELECT * FROM sales.search_car('Honda', 'Brio');")
            print("4. Restart your API server to load new code")
        else:
            print("\n⚠️  Some migrations failed. Please check errors above and retry.")
            
    finally:
        await conn.close()
        print("\n✅ Database connection closed")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Migration interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
