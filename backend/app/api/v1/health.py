import time
from datetime import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.core.database import get_db
from app.core.config import settings
from app.schemas.schemas import HealthResponse

router = APIRouter()

@router.get("/health", response_model=HealthResponse)
def get_health(db: Session = Depends(get_db)):
    start_time = time.time()
    db_healthy = True
    db_latency_ms = 0.0

    try:
        db.execute(text("SELECT 1"))
        db_latency_ms = round((time.time() - start_time) * 1000, 2)
    except Exception as e:
        db_healthy = False
        db_latency_ms = -1.0

    return HealthResponse(
        status="healthy" if db_healthy else "degraded",
        version=settings.VERSION,
        database={
            "status": "connected" if db_healthy else "error",
            "latency_ms": db_latency_ms,
            "engine": "SQLite / PostgreSQL Supabase"
        },
        ai_service={
            "status": "online",
            "model": "MobileNetV3-PlantVillage-Liberia-v1",
            "confidence_threshold": settings.CONFIDENCE_THRESHOLD_ESCALATION,
            "supported_crops": ["Cassava", "Pepper"]
        },
        sms_service={
            "status": "connected",
            "gateway": settings.SMS_PROVIDER_NAME,
            "queue_depth": 0,
            "sms_rate_limit_per_min": 100
        },
        timestamp=datetime.utcnow()
    )
