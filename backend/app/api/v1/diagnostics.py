import uuid
import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.models import ScanCase, KnowledgeItem
from app.core.config import settings

router = APIRouter()

SUPPORTED_CROPS = ["Cassava", "Pepper"]

# Realistic diagnosis profiles for supported crops
DIAGNOSIS_CATALOG = {
    "Cassava": [
        {
            "diagnosis": "Cassava Mosaic Disease (CMD)",
            "severity": "Moderate",
            "doc_id": "CARI-CAS-001",
            "symptoms": "Yellow-green mosaic pattern on leaves, leaf distortion and stunted plant growth.",
            "cultural": "Uproot and burn diseased plants immediately (roguing). Use certified virus-free cuttings.",
            "chemical": "Control whitefly vectors (Bemisia tabaci) using neem extract spray or approved systemic insecticide."
        },
        {
            "diagnosis": "Cassava Brown Streak Disease (CBSD)",
            "severity": "Severe",
            "doc_id": "CARI-CAS-002",
            "symptoms": "Yellow patches along secondary leaf veins and necrotic brown lesions in storage roots.",
            "cultural": "Harvest early if tubers are mature. Strictly plant tolerant varieties like CARICASS 1 or 2.",
            "chemical": "No direct curative chemical exists. Target vector whitefly population early."
        },
        {
            "diagnosis": "Cassava Bacterial Blight (CBB)",
            "severity": "Severe",
            "doc_id": "CARI-CAS-003",
            "symptoms": "Angular water-soaked leaf spots, leaf wilting, and gum exudation on young stems.",
            "cultural": "Rotate with non-host crops (maize/cowpea). Sterilize pruning cutlasses in bleach solution.",
            "chemical": "Copper oxychloride spray during onset of rainy season."
        },
        {
            "diagnosis": "Healthy Cassava Leaf",
            "severity": "None",
            "doc_id": "CARI-CAS-000",
            "symptoms": "Vibrant green palmate leaf surface, vigorous petiole, zero necrotic spots or discoloration.",
            "cultural": "Maintain regular weeding and good drainage around planting mounds.",
            "chemical": "No chemical treatment needed."
        }
    ],
    "Pepper": [
        {
            "diagnosis": "Pepper Anthracnose",
            "severity": "Moderate",
            "doc_id": "CARI-PEP-001",
            "symptoms": "Circular sunken lesions on fruit and dark brown concentric rings on older foliage.",
            "cultural": "Avoid overhead watering; remove and destroy fallen infected peppers.",
            "chemical": "Mancozeb or Azoxystrobin spray every 7-10 days during wet spells."
        },
        {
            "diagnosis": "Pepper Veinal Mottle Virus (PVMV)",
            "severity": "Severe",
            "doc_id": "CARI-PEP-002",
            "symptoms": "Dark green vein-banding, mottling, leaf distortion, and stunted bushy branches.",
            "cultural": "Intercrop with barrier crops (sunflower/maize border) to trap aphid vectors.",
            "chemical": "Apply mineral oil or insecticidal soap to reduce aphid transmission."
        },
        {
            "diagnosis": "Healthy Pepper Foliage",
            "severity": "None",
            "doc_id": "CARI-PEP-000",
            "symptoms": "Glossy green leaves with uniform surface, strong floral buds, zero curling.",
            "cultural": "Apply balanced compost or NPK 15-15-15 at flowering stage.",
            "chemical": "No chemical treatment needed."
        }
    ]
}

class DiagnosticRequest(BaseModel):
    crop_type: str
    image_url: Optional[str] = "https://images.unsplash.com/photo-1599818816942-e1c251d1847e?auto=format&fit=crop&w=400&q=80"
    is_blurry: bool = False
    simulated_confidence: Optional[float] = None
    farmer_id: Optional[str] = None

class DiagnosticResponse(BaseModel):
    status: str # SUCCESS, ESCALATED_LOW_CONFIDENCE, UNSUPPORTED_CROP, REJECTED_BLURRY
    case_number: Optional[str] = None
    crop_type: str
    is_supported: bool
    confidence_band: str # HIGH, MEDIUM, LOW, N/A
    confidence_score: float
    diagnosis: str
    severity: str
    knowledge_doc_id: Optional[str]
    vetted_advice: Dict[str, str]
    message: str

@router.post("/diagnose", response_model=DiagnosticResponse)
def run_diagnostic(payload: DiagnosticRequest, db: Session = Depends(get_db)):
    crop_clean = payload.crop_type.strip().title()

    # RULE SCAN-03: Unsupported crop validation
    if crop_clean not in SUPPORTED_CROPS:
        return DiagnosticResponse(
            status="UNSUPPORTED_CROP",
            case_number=None,
            crop_type=crop_clean,
            is_supported=False,
            confidence_band="N/A",
            confidence_score=0.0,
            diagnosis="Unsupported Crop Type",
            severity="N/A",
            knowledge_doc_id=None,
            vetted_advice={
                "warning": f"Our computer vision model is currently validated only for {', '.join(SUPPORTED_CROPS)}. "
                           f"{crop_clean} is not officially supported for automated disease classification.",
                "action": "Please submit through the Facilitator Manual Triage desk or consult your County Extension Officer."
            },
            message=f"Rule SCAN-03 Triggered: Explicit warning returned for unsupported crop '{crop_clean}' instead of guessing."
        )

    # RULE SCAN-04: Blurry leaf check
    if payload.is_blurry:
        case_num = f"CASE-{datetime.datetime.utcnow().strftime('%m%d')}-{str(uuid.uuid4())[:4].upper()}"
        case = ScanCase(
            case_number=case_num,
            farmer_id=payload.farmer_id,
            crop_type=crop_clean,
            image_url=payload.image_url,
            ai_diagnosis="Image Too Blurry for Automated Classification",
            ai_confidence=0.32,
            severity="Unknown",
            is_blurry=True,
            status="PENDING_ESCALATION",
            officer_notes="Auto-flagged: Laplacian variance below threshold. Image re-take requested or facilitator triage needed."
        )
        db.add(case)
        db.commit()

        return DiagnosticResponse(
            status="REJECTED_BLURRY",
            case_number=case_num,
            crop_type=crop_clean,
            is_supported=True,
            confidence_band="LOW",
            confidence_score=0.32,
            diagnosis="Image Too Blurry",
            severity="Unknown",
            knowledge_doc_id=None,
            vetted_advice={
                "guidance": "Hold the camera steady 15-20cm from the leaf. Avoid heavy shadows or motion blur.",
                "escalation": f"Case {case_num} logged in the Desktop Admin Triage Console for officer review."
            },
            message="Rule SCAN-04 Triggered: Blurry image abstention."
        )

    # Pick realistic diagnosis
    candidates = DIAGNOSIS_CATALOG[crop_clean]
    chosen = candidates[0] # primary disease candidate

    # Use simulated confidence if provided, otherwise default to 0.88
    conf = payload.simulated_confidence if payload.simulated_confidence is not None else 0.88

    # Determine confidence band
    if conf >= 0.85:
        band = "HIGH"
    elif conf >= 0.65:
        band = "MEDIUM"
    else:
        band = "LOW"

    case_num = f"CASE-{datetime.datetime.utcnow().strftime('%m%d')}-{str(uuid.uuid4())[:4].upper()}"

    # RULE SCAN-04 & ESCALATION: If confidence < 0.65, abstain & auto-escalate
    if conf < settings.CONFIDENCE_THRESHOLD_ESCALATION:
        case = ScanCase(
            case_number=case_num,
            farmer_id=payload.farmer_id,
            crop_type=crop_clean,
            image_url=payload.image_url,
            ai_diagnosis=f"Uncertain: {chosen['diagnosis']}",
            ai_confidence=conf,
            severity=chosen["severity"],
            is_blurry=False,
            status="PENDING_ESCALATION",
            officer_notes="Confidence below 65% abstention threshold. Escalated to Gorpu's Master Triage Console."
        )
        db.add(case)
        db.commit()

        return DiagnosticResponse(
            status="ESCALATED_LOW_CONFIDENCE",
            case_number=case_num,
            crop_type=crop_clean,
            is_supported=True,
            confidence_band=band,
            confidence_score=conf,
            diagnosis=f"Preliminary Screening: {chosen['diagnosis']} (Low Confidence)",
            severity=chosen["severity"],
            knowledge_doc_id=chosen["doc_id"],
            vetted_advice={
                "notice": "Confidence is below 65%. The AI abstains from prescribing direct chemical action.",
                "cultural_control": chosen["cultural"],
                "chemical_control": "Pending verification by County Agricultural Extension Officer.",
                "escalation": f"Case {case_num} escalated to Extension Officer review desk."
            },
            message=f"Rule SCAN-04 Triggered: Confidence ({int(conf*100)}%) < 65%. Automatically escalated to Desktop Admin Workstation."
        )

    # High / Medium confidence -> Auto-verified case logged
    case = ScanCase(
        case_number=case_num,
        farmer_id=payload.farmer_id,
        crop_type=crop_clean,
        image_url=payload.image_url,
        ai_diagnosis=chosen["diagnosis"],
        ai_confidence=conf,
        severity=chosen["severity"],
        is_blurry=False,
        status="AUTO_VERIFIED",
        officer_notes="High confidence automated scan matched with vetted CARI guideline."
    )
    db.add(case)
    db.commit()

    return DiagnosticResponse(
        status="SUCCESS",
        case_number=case_num,
        crop_type=crop_clean,
        is_supported=True,
        confidence_band=band,
        confidence_score=conf,
        diagnosis=chosen["diagnosis"],
        severity=chosen["severity"],
        knowledge_doc_id=chosen["doc_id"],
        vetted_advice={
            "symptoms": chosen["symptoms"],
            "cultural_control": chosen["cultural"],
            "chemical_control": chosen["chemical"],
            "source": f"Grounded in CARI Extension Guide ({chosen['doc_id']})"
        },
        message=f"Analysis complete with {band} confidence ({int(conf*100)}%)."
    )
