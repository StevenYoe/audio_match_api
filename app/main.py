import logging
from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.v1.endpoints import chat, admin, import_data
from app.services import database_service, redis_service

# Configure logging
logging.basicConfig(level=settings.LOG_LEVEL)
logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description=settings.APP_DESCRIPTION,
    debug=settings.DEBUG,
    docs_url="/docs" if settings.ENABLE_DOCS else None,
    redoc_url="/redoc" if settings.ENABLE_DOCS else None,
)

# Set up CORS
if settings.CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.CORS_ORIGINS],
        allow_credentials=settings.CORS_ALLOW_CREDENTIALS,
        allow_methods=[str(method) for method in settings.CORS_ALLOW_METHODS],
        allow_headers=[str(header) for header in settings.CORS_ALLOW_HEADERS],
    )

# Include routers
app.include_router(chat.router, prefix="/api/v1/chat", tags=["Chat"])
app.include_router(admin.router, prefix="/api/v1/admin", tags=["Admin"])
app.include_router(import_data.router, prefix="/api/v1/admin/import-data", tags=["Data Import"])

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up...")
    try:
        database_service.db_pool = await database_service.get_db_pool()
        logger.info("Database pool created.")
        redis_service.redis_client = await redis_service.get_redis_client()
        logger.info("Redis client created.")
        # Verify redis connection
        await redis_service.redis_client.ping()
        logger.info("Successfully connected to Redis.")
    except Exception as e:
        logger.error(f"Error during startup: {e}")
        # Optionally, you might want to exit the application if connections fail
        # import sys
        # sys.exit(1)


@app.on_event("shutdown")
async def shutdown_event():
    logger.info("Shutting down...")
    if database_service.db_pool:
        await database_service.db_pool.close()
        logger.info("Database pool closed.")
    if redis_service.redis_client:
        await redis_service.redis_client.close()
        logger.info("Redis client closed.")


@app.get("/", tags=["Root"])
async def read_root():
    """
    Root endpoint to check if the API is running.
    """
    return {"message": f"Welcome to {settings.APP_NAME} v{settings.APP_VERSION}"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.PORT)
