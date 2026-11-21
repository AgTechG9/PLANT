from typing import List, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.models import KnowledgeItem
from app.schemas.schemas import KnowledgeResponse

router = APIRouter()

@router.get("/knowledge", response_model=List[KnowledgeResponse])
def list_knowledge(
    crop: Optional[str] = Query(None, description="Filter by crop (e.g. Cassava, Pepper)"),
    search: Optional[str] = Query(None, description="Search term in condition or symptoms"),
    db: Session = Depends(get_db)
):
    query = db.query(KnowledgeItem)
    if crop and crop != "ALL":
        query = query.filter(KnowledgeItem.crop.ilike(f"%{crop}%"))
    if search:
        query = query.filter(
            (KnowledgeItem.condition_name.ilike(f"%{search}%")) |
            (KnowledgeItem.symptom_description.ilike(f"%{search}%")) |
            (KnowledgeItem.doc_id.ilike(f"%{search}%"))
        )
    return query.order_by(KnowledgeItem.doc_id.asc()).all()

@router.get("/knowledge/{doc_id}", response_model=KnowledgeResponse)
def get_knowledge_item(doc_id: str, db: Session = Depends(get_db)):
    item = db.query(KnowledgeItem).filter(KnowledgeItem.doc_id == doc_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Knowledge item not found")
    return item
