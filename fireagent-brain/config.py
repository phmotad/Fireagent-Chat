"""Configuration settings for FireAgent Brain."""
import os
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """Application settings."""
    
    # API Keys
    gemini_api_key: str = os.getenv("GEMINI_API_KEY", "")
    
    # Database
    postgres_url: str = os.getenv("POSTGRES_URL", "postgresql://localhost:5432/chatwoot")
    
    # Redis
    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379")
    redis_password: Optional[str] = os.getenv("REDIS_PASSWORD")
    redis_ttl: int = 86400  # 24 hours
    
    # Chatwoot
    chatwoot_url: str = os.getenv("CHATWOOT_URL", "http://rails:3000")
    chatwoot_api_key: Optional[str] = os.getenv("CHATWOOT_API_KEY")
    
    # Memory
    default_memory_window: int = 10
    max_memory_window: int = 100
    
    # RAG
    embedding_model: str = "models/embedding-001"
    similarity_threshold: float = 0.7
    max_rag_results: int = 5
    
    # Gemini
    default_model: str = "gemini-2.0-flash-exp"
    default_temperature: float = 0.7
    max_tokens: int = 8192
    
    class Config:
        env_file = ".env"
        case_sensitive = False


settings = Settings()
