import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    PROJECT_NAME: str = "PLANT API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./plant.db")
    CORS_ORIGINS: list[str] = ["*"]
    SMS_PROVIDER_NAME: str = "Orange Liberia / Lonestar MTN Mock Gateway"
    CONFIDENCE_THRESHOLD_ESCALATION: float = 0.65

    model_config = SettingsConfigDict(case_sensitive=True)

settings = Settings()

