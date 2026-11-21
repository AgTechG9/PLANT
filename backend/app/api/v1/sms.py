import uuid
import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.models import Farmer, SmsLog
from app.schemas.schemas import BroadcastRequest, BroadcastResponse, SmsLogResponse

router = APIRouter()

@router.post("/sms/broadcast", response_model=BroadcastResponse)
def dispatch_broadcast(payload: BroadcastRequest, db: Session = Depends(get_db)):
    if len(payload.message_text) > 160:
        raise HTTPException(status_code=400, detail="SMS message exceeds strict 160-character limit")

    broadcast_id = f"BC-{datetime.datetime.utcnow().strftime('%Y%m%d%H%M')}-{str(uuid.uuid4())[:4]}"

    # Query active farmers in target county with consent ACTIVE
    query = db.query(Farmer).filter(Farmer.consent_status == "ACTIVE")
    if payload.county and payload.county.upper() != "ALL":
        query = query.filter(Farmer.county.ilike(f"%{payload.county}%"))

    farmers = query.all()

    # Create logs
    dispatched_count = 0
    for f in farmers:
        sms_log = SmsLog(
            recipient_phone=f.phone_number,
            county=f.county,
            message_text=payload.message_text,
            char_count=len(payload.message_text),
            status="DELIVERED",
            broadcast_id=broadcast_id
        )
        db.add(sms_log)
        dispatched_count += 1

    db.commit()

    return BroadcastResponse(
        broadcast_id=broadcast_id,
        targeted_county=payload.county,
        messages_dispatched=dispatched_count,
        char_count=len(payload.message_text),
        preview_text=payload.message_text,
        status="DISPATCHED"
    )

@router.get("/sms/logs", response_model=List[SmsLogResponse])
def get_sms_logs(
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    logs = db.query(SmsLog).order_by(SmsLog.sent_at.desc()).offset(offset).limit(limit).all()
    return logs
