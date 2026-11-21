import datetime
import uuid
from sqlalchemy import Column, String, Float, Boolean, DateTime, ForeignKey, Text, Integer
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=generate_uuid)
    username = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    salt = Column(String, nullable=False)
    role = Column(String, nullable=False) # 'ADMIN', 'AGENT', 'FARMER'
    full_name = Column(String, nullable=False)
    phone_number = Column(String, nullable=True)
    county = Column(String, nullable=True) # e.g. Bong, Nimba, Lofa
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class Farmer(Base):
    __tablename__ = "farmers"

    id = Column(String, primary_key=True, default=generate_uuid)
    full_name = Column(String, nullable=False)
    phone_number = Column(String, unique=True, index=True, nullable=False)
    county = Column(String, index=True, nullable=False) # e.g. Bong, Nimba, Lofa
    district = Column(String, nullable=True)
    gender = Column(String, nullable=False) # 'female', 'male'
    language_preference = Column(String, default="English") # English, Kpelle, Bassa
    consent_status = Column(String, default="ACTIVE") # ACTIVE, STOPPED
    livestock_interest = Column(Boolean, default=False) # Rule REG-03: 'Coming Soon' interest tracker
    registered_via = Column(String, default="USSD") # USSD, PWA, AGENT
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    cases = relationship("ScanCase", back_populates="farmer")

class ScanCase(Base):
    __tablename__ = "scan_cases"

    id = Column(String, primary_key=True, default=generate_uuid)
    case_number = Column(String, unique=True, index=True, nullable=False) # e.g. CASE-2026-001
    farmer_id = Column(String, ForeignKey("farmers.id"), nullable=True)
    crop_type = Column(String, nullable=False) # Cassava, Pepper, Maize (unsupported test)
    image_url = Column(String, nullable=False)
    ai_diagnosis = Column(String, nullable=False)
    ai_confidence = Column(Float, nullable=False) # e.g. 0.58, 0.89
    severity = Column(String, default="Moderate") # Mild, Moderate, Severe
    is_blurry = Column(Boolean, default=False) # Rule SCAN-04
    status = Column(String, default="PENDING_ESCALATION") # PENDING_ESCALATION, RESOLVED, AUTO_VERIFIED
    officer_notes = Column(Text, nullable=True)
    officer_resolution = Column(Text, nullable=True)
    resolution_sms_sent = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)

    farmer = relationship("Farmer", back_populates="cases")

class KnowledgeItem(Base):
    __tablename__ = "knowledge_items"

    id = Column(String, primary_key=True, default=generate_uuid)
    doc_id = Column(String, unique=True, index=True, nullable=False) # e.g. CARI-CAS-001
    crop = Column(String, index=True, nullable=False)
    condition_name = Column(String, nullable=False)
    symptom_description = Column(Text, nullable=False)
    cultural_control = Column(Text, nullable=False)
    chemical_control = Column(Text, nullable=False) # Rule ADV-01: strictly grounded
    vetted_sms_template = Column(String(160), nullable=False) # max 160 chars
    source_org = Column(String, default="CARI / MoA Liberia")
    approved_by = Column(String, default="Senior Agronomist S. Kollie")
    updated_at = Column(DateTime, default=datetime.datetime.utcnow)

class SmsLog(Base):
    __tablename__ = "sms_logs"

    id = Column(String, primary_key=True, default=generate_uuid)
    recipient_phone = Column(String, nullable=False)
    county = Column(String, nullable=True)
    message_text = Column(String(160), nullable=False)
    char_count = Column(Integer, nullable=False)
    status = Column(String, default="DELIVERED") # QUEUED, SENT, DELIVERED, FAILED
    broadcast_id = Column(String, nullable=True)
    sent_at = Column(DateTime, default=datetime.datetime.utcnow)

class UssdSession(Base):
    __tablename__ = "ussd_sessions"

    id = Column(String, primary_key=True, default=generate_uuid)
    session_id = Column(String, unique=True, index=True, nullable=False)
    phone_number = Column(String, index=True, nullable=False)
    current_step = Column(String, default="MAIN_MENU")
    session_data = Column(Text, default="{}") # JSON-serialized temporary state
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow)
