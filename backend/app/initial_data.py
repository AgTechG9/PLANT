import datetime
from sqlalchemy.orm import Session
from app.models.models import Farmer, ScanCase, KnowledgeItem, SmsLog

def seed_database(db: Session):
    # Check if already seeded
    if db.query(Farmer).count() > 0:
        return

    print("Seeding initial Liberian agricultural data...")

    # 1. Farmers (54% female, Bong/Nimba/Lofa, livestock interest)
    farmers = [
        Farmer(
            full_name="Korto Flomo",
            phone_number="+231770123456",
            county="Bong",
            district="Suakoko",
            gender="female",
            language_preference="Kpelle",
            consent_status="ACTIVE",
            livestock_interest=True,
            registered_via="USSD"
        ),
        Farmer(
            full_name="Musu Kanneh",
            phone_number="+231886234567",
            county="Nimba",
            district="Ganta",
            gender="female",
            language_preference="English",
            consent_status="ACTIVE",
            livestock_interest=True,
            registered_via="PWA"
        ),
        Farmer(
            full_name="Emmanuel Sumo",
            phone_number="+231776345678",
            county="Lofa",
            district="Voinjama",
            gender="male",
            language_preference="English",
            consent_status="ACTIVE",
            livestock_interest=False,
            registered_via="USSD"
        ),
        Farmer(
            full_name="Fatu Kollie",
            phone_number="+231880456789",
            county="Bong",
            district="Gbarnga",
            gender="female",
            language_preference="Kpelle",
            consent_status="ACTIVE",
            livestock_interest=True,
            registered_via="AGENT"
        ),
        Farmer(
            full_name="Tamba Saah",
            phone_number="+231775567890",
            county="Lofa",
            district="Foya",
            gender="male",
            language_preference="English",
            consent_status="ACTIVE",
            livestock_interest=True,
            registered_via="USSD"
        ),
        Farmer(
            full_name="Comfort Toe",
            phone_number="+231881678901",
            county="Margibi",
            district="Kakata",
            gender="female",
            language_preference="Bassa",
            consent_status="ACTIVE",
            livestock_interest=False,
            registered_via="PWA"
        ),
        Farmer(
            full_name="Moses Gbahn",
            phone_number="+231777789012",
            county="Nimba",
            district="Sanniquellie",
            gender="male",
            language_preference="English",
            consent_status="ACTIVE",
            livestock_interest=False,
            registered_via="USSD"
        ),
        Farmer(
            full_name="Hawa Kamara",
            phone_number="+231888890123",
            county="Bong",
            district="Salala",
            gender="female",
            language_preference="Kpelle",
            consent_status="ACTIVE",
            livestock_interest=True,
            registered_via="USSD"
        ),
        Farmer(
            full_name="Oldman Pewee",
            phone_number="+231771901234",
            county="Lofa",
            district="Zorzor",
            gender="male",
            language_preference="Kpelle",
            consent_status="ACTIVE",
            livestock_interest=False,
            registered_via="AGENT"
        ),
        Farmer(
            full_name="Sando Gibson",
            phone_number="+231882012345",
            county="Bong",
            district="Sanoyea",
            gender="female",
            language_preference="Kpelle",
            consent_status="STOPPED", # Demonstrating STOP opt-out compliance
            livestock_interest=False,
            registered_via="USSD"
        )
    ]
    db.add_all(farmers)
    db.commit()

    # 2. CARI-Approved Knowledge Base Items (Rule ADV-01)
    knowledge = [
        KnowledgeItem(
            doc_id="CARI-CAS-001",
            crop="Cassava",
            condition_name="Cassava Mosaic Disease (CMD)",
            symptom_description="Severe yellow-green chlorotic mosaic patterns, distorted leaf lamina, curling and stunting.",
            cultural_control="Use only disease-free stems from CARI/MoA certified nurseries. Roguing: uproot and burn infected plants early.",
            chemical_control="Systemic insecticide (Acetamiprid 20% SP @ 50g/ha) to suppress whitefly vectors during early vegetative stage.",
            vetted_sms_template="CARI Advisory: CMD detected. Remove & burn diseased plants immediately. Use certified cuttings. Whitefly spray recommended. Call 4410.",
            source_org="Central Agricultural Research Institute (CARI), Suakoko",
            approved_by="Dr. J. K. Foeday, Senior Agronomist"
        ),
        KnowledgeItem(
            doc_id="CARI-CAS-002",
            crop="Cassava",
            condition_name="Cassava Brown Streak Disease (CBSD)",
            symptom_description="Feathery chlorosis along secondary leaf veins. Brown radial corky necrosis in tuberous roots.",
            cultural_control="Harvest roots early to minimize rot damage. Strictly avoid planting cuttings from affected fields.",
            chemical_control="No chemical cure for virus. Apply biopesticides (neem oil 3%) to control Bemisia tabaci vector populations.",
            vetted_sms_template="CARI Alert: CBSD suspected. Do NOT use cuttings from this field. Harvest mature tubers now to avoid rot. Report to county office.",
            source_org="CARI / MoA Plant Protection Directorate",
            approved_by="Dr. J. K. Foeday, Senior Agronomist"
        ),
        KnowledgeItem(
            doc_id="CARI-PEP-001",
            crop="Pepper",
            condition_name="Pepper Anthracnose (Colletotrichum)",
            symptom_description="Sunken dark circular lesions on fruits with gelatinous salmon-colored spore masses during damp weather.",
            cultural_control="Rotate fields every 2 seasons away from Solanaceous crops. Space plants 50cm apart to allow air circulation.",
            chemical_control="Preventative spray with Chlorothalonil 75% WP (2kg/ha) or Mancozeb 80% WP at first fruit set.",
            vetted_sms_template="CARI Advisory: Pepper Anthracnose. Remove rotting pods. Spray Mancozeb (2 tbsp/15L water). Water at soil base only.",
            source_org="CARI Horticulture Unit",
            approved_by="Extension Specialist M. Sumo"
        ),
        KnowledgeItem(
            doc_id="CARI-PEP-002",
            crop="Pepper",
            condition_name="Bacterial Wilt (Ralstonia solanacearum)",
            symptom_description="Rapid wilting of entire plant foliage during hot sunny hours while leaves remain green. Brown vascular discoloration.",
            cultural_control="Plant on raised 30cm mounds. Solarize seedbeds before transplanting. Do not transplant where tomatoes wilted.",
            chemical_control="No direct bactericide effective. Soil drench with copper hydroxide 77% WP to protect adjacent rows.",
            vetted_sms_template="CARI Alert: Pepper Bacterial Wilt. Infected plants cannot recover; remove root ball with soil. Avoid moving wet soil.",
            source_org="CARI Horticulture Unit",
            approved_by="Extension Specialist M. Sumo"
        )
    ]
    db.add_all(knowledge)
    db.commit()

    # 3. Escalated Scan Cases (Simulating low-confidence / blurry scans for Gorpu's Workbench)
    f_korto = farmers[0]
    f_musu = farmers[1]
    f_emmanuel = farmers[2]

    cases = [
        ScanCase(
            case_number="CASE-1121-001",
            farmer_id=f_korto.id,
            crop_type="Cassava",
            image_url="https://images.unsplash.com/photo-1599818816942-e1c251d1847e?auto=format&fit=crop&w=600&q=80",
            ai_diagnosis="Uncertain: Cassava Mosaic Disease vs Nutrient Deficiency",
            ai_confidence=0.58,
            severity="Moderate",
            is_blurry=False,
            status="PENDING_ESCALATION",
            officer_notes="AI confidence is 58% (<65% threshold). Leaf has chlorosis near margins.",
            created_at=datetime.datetime.utcnow() - datetime.timedelta(hours=2)
        ),
        ScanCase(
            case_number="CASE-1121-002",
            farmer_id=f_musu.id,
            crop_type="Pepper",
            image_url="https://images.unsplash.com/photo-1592417817098-8f3d6910985c?auto=format&fit=crop&w=600&q=80",
            ai_diagnosis="Image Too Blurry for Automated Classification",
            ai_confidence=0.34,
            severity="Unknown",
            is_blurry=True,
            status="PENDING_ESCALATION",
            officer_notes="Rule SCAN-04: Blurry leaf photo taken under direct tropical midday glare. Extension officer review needed.",
            created_at=datetime.datetime.utcnow() - datetime.timedelta(hours=5)
        ),
        ScanCase(
            case_number="CASE-1121-003",
            farmer_id=f_emmanuel.id,
            crop_type="Cassava",
            image_url="https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&w=600&q=80",
            ai_diagnosis="Cassava Mosaic Disease (CMD)",
            ai_confidence=0.91,
            severity="Severe",
            is_blurry=False,
            status="AUTO_VERIFIED",
            officer_notes="High confidence auto-match. CARI-CAS-001 guidance dispatched.",
            resolution_sms_sent=True,
            created_at=datetime.datetime.utcnow() - datetime.timedelta(days=1)
        )
    ]
    db.add_all(cases)
    db.commit()

    # 4. Outbound SMS Telemetry Logs
    sms_logs = [
        SmsLog(
            recipient_phone="+231776345678",
            county="Lofa",
            message_text="CARI Advisory: CMD detected. Remove & burn diseased plants immediately. Use certified cuttings. Whitefly spray recommended. Call 4410.",
            char_count=138,
            status="DELIVERED",
            broadcast_id="CASE-RES-CASE-1121-003",
            sent_at=datetime.datetime.utcnow() - datetime.timedelta(days=1)
        ),
        SmsLog(
            recipient_phone="+231770123456",
            county="Bong",
            message_text="CARI Agro-Met Alert: Bong & Nimba farmers expect heavy downpours Thursday. Clear runoff ditches along cassava beds to avoid root waterlogging.",
            char_count=149,
            status="DELIVERED",
            broadcast_id="BC-20261120-MET",
            sent_at=datetime.datetime.utcnow() - datetime.timedelta(hours=12)
        )
    ]
    db.add_all(sms_logs)
    db.commit()
    print("Database seeding completed successfully.")
