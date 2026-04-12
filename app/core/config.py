import os
from pydantic_settings import BaseSettings
from pydantic import Field
from typing import List
import logging

logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    """
    Application settings, loaded from environment variables.
    """
    APP_NAME: str = Field("AudioMatch", description="Application Name")
    APP_VERSION: str = Field("1.0.0", description="Application Version")
    APP_DESCRIPTION: str = Field("Find Your Perfect Audio Setup", description="Application Description")
    DEBUG: bool = Field(True, description="Debug mode")
    PORT: int = Field(8000, description="Port to run the application on")
    LOG_LEVEL: str = Field("INFO", description="Log level")

    # Database Configuration
    DATABASE_URL: str = Field(default="", description="PostgreSQL database URL with pgvector")
    DATABASE_POOL_SIZE: int = Field(20, description="Database pool size")
    DATABASE_MAX_OVERFLOW: int = Field(40, description="Database max overflow")
    DATABASE_POOL_TIMEOUT: int = Field(30, description="Database pool timeout")

    # VoyageAI API Configuration
    VOYAGE_API_KEY: str = Field(default="", description="VoyageAI API Key")
    VOYAGE_MODEL: str = Field("voyage-3.5-lite", description="VoyageAI model")
    VOYAGE_INPUT_TYPE: str = Field("document", description="VoyageAI input type")
    EMBEDDING_DIMENSIONS: int = Field(1024, description="Embedding dimensions")

    # CRITICAL: Rate limiting settings for free tier (3 RPM)
    EMBEDDING_BATCH_SIZE: int = Field(100, description="Max texts per API call (VoyageAI limit)")
    VOYAGE_RATE_LIMIT_RPM: int = Field(3, description="Free tier limit")
    VOYAGE_RATE_LIMIT_DELAY: int = Field(21, description="Same as interval")


    # LLM Configuration (Using Gemini API)
    GEMINI_API_KEY: str = Field(default="", description="Gemini API Key")
    LLM_MODEL: str = Field("gemini-1.5-flash", description="LLM model")
    LLM_MAX_RETRIES: int = Field(3, description="Max retries for LLM API calls")
    LLM_MAX_TOKENS: int = Field(2000, description="Max tokens for LLM response")
    LLM_TEMPERATURE: float = Field(0.1, description="LLM temperature")
    LLM_TIMEOUT: int = Field(30, description="LLM timeout")

    # Upstash Redis Configuration
    UPSTASH_REDIS_REST_URL: str = Field(default="", description="Upstash Redis REST URL")
    UPSTASH_REDIS_REST_TOKEN: str = Field(default="", description="Upstash Redis REST Token")

    # Redis Cache Configuration (in seconds)
    REDIS_CACHE_TTL: int = Field(3600, description="1 hour - for retrieval results and general cache")
    REDIS_SESSION_TTL: int = Field(86400, description="24 hours - for session data")

    # API Documentation (set to false in production to disable /docs and /redoc)
    ENABLE_DOCS: bool = Field(True, description="Enable API docs")

    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = Field(True, description="Enable rate limiting")
    RATE_LIMIT_REQUESTS: int = Field(100, description="Rate limit requests")
    RATE_LIMIT_WINDOW: int = Field(60, description="Rate limit window in seconds")

    # Logging
    LOGGING_ENABLED: bool = Field(True, description="Enable logging")
    LOG_TO_FILE: bool = Field(False, description="Log to file")

    # CORS
    CORS_ORIGINS: List[str] = Field(["*"], description="CORS origins")
    CORS_ALLOW_CREDENTIALS: bool = Field(True, description="CORS allow credentials")
    CORS_ALLOW_METHODS: List[str] = Field(["*"], description="CORS allow methods")
    CORS_ALLOW_HEADERS: List[str] = Field(["*"], description="CORS allow headers")

    class Config:
        env_file = ".env"
        env_file_encoding = 'utf-8'

    def validate_critical_settings(self):
        """Validate that critical environment variables are set."""
        missing = []
        if not self.DATABASE_URL:
            missing.append("DATABASE_URL")
        if not self.VOYAGE_API_KEY:
            missing.append("VOYAGE_API_KEY")
        if not self.GEMINI_API_KEY:
            missing.append("GEMINI_API_KEY")
        if not self.UPSTASH_REDIS_REST_URL:
            missing.append("UPSTASH_REDIS_REST_URL")
        if not self.UPSTASH_REDIS_REST_TOKEN:
            missing.append("UPSTASH_REDIS_REST_TOKEN")
        
        if missing:
            error_msg = f"Missing required environment variables: {', '.join(missing)}"
            logger.error(error_msg)
            raise ValueError(error_msg)
        
        return True

settings = Settings()
