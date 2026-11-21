import json
import datetime
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models.models import Farmer, ScanCase, SmsLog, UssdSession
from app.schemas.schemas import UssdRequest, UssdResponse

router = APIRouter()

COUNTY_MAP = {
    "1": "Bong",
    "2": "Nimba",
    "3": "Lofa",
    "4": "Margibi"
}

@router.post("/ussd", response_model=UssdResponse)
def handle_ussd(payload: UssdRequest, db: Session = Depends(get_db)):
    """
    USSD state machine supporting Orange Liberia & Lonestar MTN *123# format.
    text contains the sequence of user entries separated by '*'
    e.g.:
    "" -> initial dial
    "1" -> selected option 1
    "1*John Doe*1*1*1" -> completed registration flow
    """
    session = db.query(UssdSession).filter(UssdSession.session_id == payload.sessionId).first()
    if not session:
        session = UssdSession(
            session_id=payload.sessionId,
            phone_number=payload.phoneNumber,
            current_step="ROOT",
            session_data="{}"
        )
        db.add(session)
        db.commit()

    inputs = [x.strip() for x in payload.text.split("*") if x.strip()]

    # Main menu
    if len(inputs) == 0:
        msg = (
            "CON Welcome to PLANT AI Assistant (Liberia)\n"
            "1. Register as Farmer\n"
            "2. Check My Scan Result\n"
            "3. County Pest & Weather Alert\n"
            "4. Dialect Audio Guidance"
        )
        return UssdResponse(message=msg, continueSession=True)

    choice = inputs[0]

    # --- 1. REGISTRATION FLOW ---
    if choice == "1":
        if len(inputs) == 1:
            return UssdResponse(
                message="CON Enter your Full Name:",
                continueSession=True
            )
        elif len(inputs) == 2:
            return UssdResponse(
                message="CON Select your County:\n1. Bong\n2. Nimba\n3. Lofa\n4. Margibi",
                continueSession=True
            )
        elif len(inputs) == 3:
            return UssdResponse(
                message="CON Select Gender:\n1. Female\n2. Male",
                continueSession=True
            )
        elif len(inputs) == 4:
            return UssdResponse(
                message="CON Are you interested in Livestock Advisory (Coming Soon)?\n1. Yes\n2. No",
                continueSession=True
            )
        elif len(inputs) >= 5:
            full_name = inputs[1]
            county_code = inputs[2]
            gender_code = inputs[3]
            livestock_code = inputs[4]

            county_name = COUNTY_MAP.get(county_code, "Bong")
            gender_val = "female" if gender_code == "1" else "male"
            livestock_val = True if livestock_code == "1" else False

            # Check if farmer exists
            farmer = db.query(Farmer).filter(Farmer.phone_number == payload.phoneNumber).first()
            if not farmer:
                farmer = Farmer(
                    full_name=full_name,
                    phone_number=payload.phoneNumber,
                    county=county_name,
                    gender=gender_val,
                    livestock_interest=livestock_val,
                    registered_via="USSD"
                )
                db.add(farmer)
            else:
                farmer.full_name = full_name
                farmer.county = county_name
                farmer.gender = gender_val
                farmer.livestock_interest = livestock_val

            # Create welcome SMS log
            welcome_sms = f"Welcome {full_name} to PLANT Group 9! Registered in {county_name}. Dial *123# anytime for crop advisory."[:160]
            sms_log = SmsLog(
                recipient_phone=payload.phoneNumber,
                county=county_name,
                message_text=welcome_sms,
                char_count=len(welcome_sms),
                status="DELIVERED",
                broadcast_id="USSD-REG"
            )
            db.add(sms_log)
            db.commit()

            return UssdResponse(
                message=f"END Thank you {full_name}! You are registered in {county_name}. Confirmation SMS sent.",
                continueSession=False
            )

    # --- 2. CHECK SCAN RESULTS ---
    elif choice == "2":
        farmer = db.query(Farmer).filter(Farmer.phone_number == payload.phoneNumber).first()
        latest_case = None
        if farmer:
            latest_case = db.query(ScanCase).filter(ScanCase.farmer_id == farmer.id).order_by(ScanCase.created_at.desc()).first()
        else:
            latest_case = db.query(ScanCase).order_by(ScanCase.created_at.desc()).first()

        if latest_case:
            confidence_pct = int(latest_case.ai_confidence * 100)
            status_text = "RESOLVED by Officer" if latest_case.status == "RESOLVED" else "AI Screening"
            advice = latest_case.officer_resolution or "Avoid waterlogging; isolate infected stems."
            msg = (
                f"END {latest_case.case_number} ({latest_case.crop_type})\n"
                f"Result: {latest_case.ai_diagnosis} ({confidence_pct}% conf - {status_text})\n"
                f"Tip: {advice[:80]}"
            )
            return UssdResponse(message=msg, continueSession=False)
        else:
            return UssdResponse(
                message="END No scan records found for this number. Bring your affected leaf to your county extension agent.",
                continueSession=False
            )

    # --- 3. WEATHER & PEST ALERT ---
    elif choice == "3":
        msg = (
            "END Liberian Agro-Met Alert (Bong, Nimba, Lofa):\n"
            "Heavy rains expected in 48h. Weed around cassava ridges to avoid root rot. Inspect pepper for whiteflies."
        )
        return UssdResponse(message=msg, continueSession=False)

    # --- 4. DIALECT AUDIO GUIDANCE ---
    elif choice == "4":
        msg = (
            "END PLANT Voice Advisory:\n"
            "Dial toll-free 4410 to listen to step-by-step crop care in Kpelle, Bassa, and Kolokwa (Liberian English)."
        )
        return UssdResponse(message=msg, continueSession=False)

    return UssdResponse(
        message="END Invalid option selected. Dial *123# to restart.",
        continueSession=False
    )
