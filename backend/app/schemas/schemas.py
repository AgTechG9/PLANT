from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

# Health Schemas
class HealthResponse(BaseModel):
    status: str
    version: str
    database: Dict[str, Any]
    ai_service: Dict[str, Any]
    sms_service: Dict[str, Any]
    timestamp: datetime

# Farmer Schemas
class FarmerBase(BaseModel):
    full_name: str
    phone_number: str
    county: str
    district: Optional[str] = None
    gender: str # female, male
    language_preference: str = "English"
    livestock_interest: bool = False
    registered_via: str = "USSD"

class FarmerCreate(FarmerBase):
    pass

class FarmerResponse(FarmerBase):
    id: str
    consent_status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

class FarmerMetrics(BaseModel):
    total_farmers: int
    female_farmers: int
    female_ratio_pct: float
    livestock_interest_count: int
    by_county: Dict[str, int]
    by_language: Dict[str, int]

# Scan Case Schemas
class CaseBase(BaseModel):
    crop_type: str
    image_url: str
    ai_diagnosis: str
    ai_confidence: float
    severity: str = "Moderate"
    is_blurry: bool = False
    status: str = "PENDING_ESCALATION"

class CaseResolve(BaseModel):
    officer_notes: str
    officer_resolution: str
    send_sms_to_farmer: bool = True

class CaseResponse(CaseBase):
    id: str
    case_number: str
    farmer_id: Optional[str] = None
    farmer_name: Optional[str] = None
    farmer_phone: Optional[str] = None
    officer_notes: Optional[str] = None
    officer_resolution: Optional[str] = None
    resolution_sms_sent: bool
    created_at: datetime
    resolved_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# Knowledge Base Schemas
class KnowledgeResponse(BaseModel):
    id: str
    doc_id: str
    crop: str
    condition_name: str
    symptom_description: str
    cultural_control: str
    chemical_control: str
    vetted_sms_template: str
    source_org: str
    approved_by: str
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

# SMS & Broadcast Schemas
class BroadcastRequest(BaseModel):
    county: str # e.g. "Bong", "Nimba", "Lofa", or "ALL"
    message_text: str = Field(..., max_length=160, description="Strict 160-char SMS limit")
    topic: Optional[str] = "EMERGENCY_PEST_ALERT"

class BroadcastResponse(BaseModel):
    broadcast_id: str
    targeted_county: str
    messages_dispatched: int
    char_count: int
    preview_text: str
    status: str

class SmsLogResponse(BaseModel):
    id: str
    recipient_phone: str
    county: Optional[str]
    message_text: str
    char_count: int
    status: str
    sent_at: datetime

    model_config = ConfigDict(from_attributes=True)

# USSD Engine Schemas
class UssdRequest(BaseModel):
    sessionId: str
    phoneNumber: str
    text: str # User typed input sequence (e.g. "", "1", "1*2", etc.)
    serviceCode: Optional[str] = "*123#"

class UssdResponse(BaseModel):
    message: str
    continueSession: bool # True for CON, False for END
