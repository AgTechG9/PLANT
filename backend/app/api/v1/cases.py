import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.models import ScanCase, Farmer, SmsLog
from app.schemas.schemas import CaseResponse, CaseResolve

router = APIRouter()

@router.get("/cases", response_model=List[CaseResponse])
def list_cases(
    status: Optional[str] = Query("PENDING_ESCALATION", description="Status filter: PENDING_ESCALATION, RESOLVED, ALL"),
    crop_type: Optional[str] = Query(None, description="Crop filter (e.g. Cassava, Pepper)"),
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    query = db.query(ScanCase)
    if status and status != "ALL":
        query = query.filter(ScanCase.status == status)
    if crop_type and crop_type != "ALL":
        query = query.filter(ScanCase.crop_type.ilike(f"%{crop_type}%"))

    cases = query.order_by(ScanCase.created_at.desc()).offset(offset).limit(limit).all()

    # Enrich with farmer details
    results = []
    for c in cases:
        farmer_name = c.farmer.full_name if c.farmer else "Anonymous Farmer"
        farmer_phone = c.farmer.phone_number if c.farmer else "N/A"
        item = CaseResponse(
            id=c.id,
            case_number=c.case_number,
            farmer_id=c.farmer_id,
            farmer_name=farmer_name,
            farmer_phone=farmer_phone,
            crop_type=c.crop_type,
            image_url=c.image_url,
            ai_diagnosis=c.ai_diagnosis,
            ai_confidence=c.ai_confidence,
            severity=c.severity,
            is_blurry=c.is_blurry,
            status=c.status,
            officer_notes=c.officer_notes,
            officer_resolution=c.officer_resolution,
            resolution_sms_sent=c.resolution_sms_sent,
            created_at=c.created_at,
            resolved_at=c.resolved_at
        )
        results.append(item)
    return results

@router.get("/cases/{id}", response_model=CaseResponse)
def get_case(id: str, db: Session = Depends(get_db)):
    c = db.query(ScanCase).filter(ScanCase.id == id).first()
    if not c:
        raise HTTPException(status_code=404, detail="Case not found")

    farmer_name = c.farmer.full_name if c.farmer else "Anonymous Farmer"
    farmer_phone = c.farmer.phone_number if c.farmer else "N/A"

    return CaseResponse(
        id=c.id,
        case_number=c.case_number,
        farmer_id=c.farmer_id,
        farmer_name=farmer_name,
        farmer_phone=farmer_phone,
        crop_type=c.crop_type,
        image_url=c.image_url,
        ai_diagnosis=c.ai_diagnosis,
        ai_confidence=c.ai_confidence,
        severity=c.severity,
        is_blurry=c.is_blurry,
        status=c.status,
        officer_notes=c.officer_notes,
        officer_resolution=c.officer_resolution,
        resolution_sms_sent=c.resolution_sms_sent,
        created_at=c.created_at,
        resolved_at=c.resolved_at
    )

@router.patch("/cases/{id}", response_model=CaseResponse)
def resolve_case(id: str, payload: CaseResolve, db: Session = Depends(get_db)):
    c = db.query(ScanCase).filter(ScanCase.id == id).first()
    if not c:
        raise HTTPException(status_code=404, detail="Case not found")

    c.officer_notes = payload.officer_notes
    c.officer_resolution = payload.officer_resolution
    c.status = "RESOLVED"
    c.resolved_at = datetime.datetime.utcnow()

    # If SMS dispatch is requested and farmer has phone
    if payload.send_sms_to_farmer and c.farmer and c.farmer.phone_number != "N/A":
        sms_text = f"CARI Alert {c.case_number}: {payload.officer_resolution}"[:160]
        sms_log = SmsLog(
            recipient_phone=c.farmer.phone_number,
            county=c.farmer.county,
            message_text=sms_text,
            char_count=len(sms_text),
            status="DELIVERED",
            broadcast_id=f"CASE-RES-{c.case_number}"
        )
        db.add(sms_log)
        c.resolution_sms_sent = True

    db.commit()
    db.refresh(c)

    farmer_name = c.farmer.full_name if c.farmer else "Anonymous Farmer"
    farmer_phone = c.farmer.phone_number if c.farmer else "N/A"

    return CaseResponse(
        id=c.id,
        case_number=c.case_number,
        farmer_id=c.farmer_id,
        farmer_name=farmer_name,
        farmer_phone=farmer_phone,
        crop_type=c.crop_type,
        image_url=c.image_url,
        ai_diagnosis=c.ai_diagnosis,
        ai_confidence=c.ai_confidence,
        severity=c.severity,
        is_blurry=c.is_blurry,
        status=c.status,
        officer_notes=c.officer_notes,
        officer_resolution=c.officer_resolution,
        resolution_sms_sent=c.resolution_sms_sent,
        created_at=c.created_at,
        resolved_at=c.resolved_at
    )
