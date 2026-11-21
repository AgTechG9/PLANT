from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.models.models import Farmer
from app.schemas.schemas import FarmerResponse, FarmerCreate, FarmerMetrics

router = APIRouter()

@router.get("/farmers", response_model=List[FarmerResponse])
def list_farmers(
    county: Optional[str] = Query(None, description="Filter by county (e.g. Bong, Nimba, Lofa)"),
    search: Optional[str] = Query(None, description="Search by name or phone"),
    limit: int = 100,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    query = db.query(Farmer)
    if county and county != "ALL":
        query = query.filter(Farmer.county.ilike(f"%{county}%"))
    if search:
        query = query.filter(
            (Farmer.full_name.ilike(f"%{search}%")) |
            (Farmer.phone_number.ilike(f"%{search}%"))
        )
    return query.order_by(Farmer.created_at.desc()).offset(offset).limit(limit).all()

@router.get("/farmers/metrics", response_model=FarmerMetrics)
def get_farmer_metrics(db: Session = Depends(get_db)):
    total = db.query(Farmer).count()
    female_count = db.query(Farmer).filter(Farmer.gender == "female").count()
    livestock_interest = db.query(Farmer).filter(Farmer.livestock_interest == True).count()

    female_ratio = round((female_count / total * 100), 1) if total > 0 else 0.0

    # Group by county
    county_rows = db.query(Farmer.county, func.count(Farmer.id)).group_by(Farmer.county).all()
    by_county = {county: count for county, count in county_rows if county}

    # Group by language
    lang_rows = db.query(Farmer.language_preference, func.count(Farmer.id)).group_by(Farmer.language_preference).all()
    by_lang = {lang: count for lang, count in lang_rows if lang}

    return FarmerMetrics(
        total_farmers=total,
        female_farmers=female_count,
        female_ratio_pct=female_ratio,
        livestock_interest_count=livestock_interest,
        by_county=by_county,
        by_language=by_lang
    )

@router.post("/farmers", response_model=FarmerResponse)
def register_farmer(payload: FarmerCreate, db: Session = Depends(get_db)):
    existing = db.query(Farmer).filter(Farmer.phone_number == payload.phone_number).first()
    if existing:
        raise HTTPException(status_code=400, detail="Farmer with this phone number is already registered")

    farmer = Farmer(
        full_name=payload.full_name,
        phone_number=payload.phone_number,
        county=payload.county,
        district=payload.district,
        gender=payload.gender.lower(),
        language_preference=payload.language_preference,
        livestock_interest=payload.livestock_interest,
        registered_via=payload.registered_via
    )
    db.add(farmer)
    db.commit()
    db.refresh(farmer)
    return farmer
