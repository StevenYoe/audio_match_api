"""
Script to run the hybrid search migration (004_hybrid_search.sql)
"""
import asyncio
import asyncpg
import os
from dotenv import load_dotenv

load_dotenv()

async def run_migration():
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("ERROR: DATABASE_URL not found in .env file")
        return
    
    migration_file = os.path.join(os.path.dirname(__file__), "migrations", "004_hybrid_search.sql")
    
    print(f"Reading migration file: {migration_file}")
    with open(migration_file, 'r', encoding='utf-8') as f:
        sql = f.read()
    
    print("Connecting to database...")
    conn = await asyncpg.connect(db_url)
    
    try:
        print("Running migration...")
        await conn.execute(sql)
        print("✅ Migration completed successfully!")
        
        # Verify functions were created
        print("\nVerifying functions...")
        functions = await conn.fetch("""
            SELECT routine_name 
            FROM information_schema.routines 
            WHERE routine_schema = 'sales' 
            AND routine_name LIKE '%hybrid%'
        """)
        
        if functions:
            print("✅ Hybrid search functions created:")
            for func in functions:
                print(f"   - {func['routine_name']}")
        else:
            print("⚠️ Warning: No hybrid functions found")
        
        # Verify indexes
        print("\nVerifying indexes...")
        indexes = await conn.fetch("""
            SELECT indexname 
            FROM pg_indexes 
            WHERE schemaname = 'sales' 
            AND indexname LIKE '%fts%'
        """)
        
        if indexes:
            print("✅ FTS indexes created:")
            for idx in indexes:
                print(f"   - {idx['indexname']}")
        else:
            print("⚠️ Warning: No FTS indexes found")
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(run_migration())
