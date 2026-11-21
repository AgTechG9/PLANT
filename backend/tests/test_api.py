import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_user_authentication_three_roles():
    # 1. Admin login
    res_admin = client.post("/api/v1/auth/login", json={"username": "admin", "password": "admin123"})
    assert res_admin.status_code == 200
    data_admin = res_admin.json()
    assert data_admin["user"]["role"] == "ADMIN"
    token = data_admin["access_token"]

    # Verify /auth/me with Bearer token
    res_me = client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert res_me.status_code == 200
    assert res_me.json()["username"] == "admin"

    # 2. Agent login
    res_agent = client.post("/api/v1/auth/login", json={"username": "agent_suakoko", "password": "agent123"})
    assert res_agent.status_code == 200
    assert res_agent.json()["user"]["role"] == "AGENT"

    # 3. Farmer login
    res_farmer = client.post("/api/v1/auth/login", json={"username": "farmer_korto", "password": "farmer123"})
    assert res_farmer.status_code == 200
    assert res_farmer.json()["user"]["role"] == "FARMER"

    # 4. Invalid login rejected
    res_bad = client.post("/api/v1/auth/login", json={"username": "admin", "password": "wrongpassword"})
    assert res_bad.status_code == 401

def test_health_telemetry():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "database" in data
    assert "ai_service" in data
    assert "sms_service" in data

def test_farmer_directory_and_metrics():
    res_list = client.get("/api/v1/farmers")
    assert res_list.status_code == 200
    assert len(res_list.json()) >= 10

    res_metrics = client.get("/api/v1/farmers/metrics")
    assert res_metrics.status_code == 200
    metrics = res_metrics.json()
    assert metrics["total_farmers"] >= 10
    assert metrics["female_ratio_pct"] > 50.0
    assert "Bong" in metrics["by_county"]

def test_case_escalation_and_override():
    # Ensure there is a farmer available
    farmers_res = client.get("/api/v1/farmers")
    assert farmers_res.status_code == 200
    farmer_id = farmers_res.json()[0]["id"]

    # Create a fresh pending escalation case with farmer_id
    diag_res = client.post("/api/v1/diagnose", json={
        "crop_type": "Cassava",
        "is_blurry": False,
        "simulated_confidence": 0.45,
        "farmer_id": farmer_id
    })
    assert diag_res.status_code == 200
    case_num = diag_res.json()["case_number"]

    # Fetch the pending case
    res = client.get("/api/v1/cases?status=PENDING_ESCALATION")
    assert res.status_code == 200
    cases = res.json()
    test_case = next(c for c in cases if c["case_number"] == case_num)

    # Resolve case as Extension Officer
    resolve_payload = {
        "officer_notes": "Verified by Gorpu: Early stage CMD symptoms confirmed. Spray acetamiprid.",
        "officer_resolution": "CARI Verified: Uproot diseased cassava plant. Apply neem spray for whiteflies.",
        "send_sms_to_farmer": True
    }
    patch_res = client.patch(f"/api/v1/cases/{test_case['id']}", json=resolve_payload)
    assert patch_res.status_code == 200
    updated = patch_res.json()
    assert updated["status"] == "RESOLVED"
    assert updated["resolution_sms_sent"] is True

def test_vetted_knowledge_base_rule_adv_01():
    res = client.get("/api/v1/knowledge?crop=Cassava")
    assert res.status_code == 200
    items = res.json()
    assert len(items) >= 2
    for item in items:
        assert item["doc_id"].startswith("CARI-")
        assert len(item["vetted_sms_template"]) <= 160

def test_emergency_broadcast_and_160_char_rule():
    payload = {
        "county": "Bong",
        "message_text": "CARI Alert Bong: Heavy rains expected next 48h. Clear drainage ditches along cassava ridges to prevent root rot. Dial *123# for assistance.",
        "topic": "PEST_AND_WEATHER"
    }
    res = client.post("/api/v1/sms/broadcast", json=payload)
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "DISPATCHED"
    assert data["char_count"] <= 160

def test_ussd_state_machine_dial():
    # 1. Dial *123#
    res1 = client.post("/api/v1/ussd", json={"sessionId": "ussd-999", "phoneNumber": "+231770001122", "text": ""})
    assert res1.status_code == 200
    assert res1.json()["continueSession"] is True
    assert "Welcome to PLANT" in res1.json()["message"]

    # 2. Check result for known farmer
    res2 = client.post("/api/v1/ussd", json={"sessionId": "ussd-999", "phoneNumber": "+231776345678", "text": "2"})
    assert res2.status_code == 200
    assert res2.json()["continueSession"] is False
    assert "Result:" in res2.json()["message"]

def test_ai_safety_validator_unsupported_crop_rule_scan_03():
    # Scanning Maize (unsupported) should return explicit warning instead of guessing
    res = client.post("/api/v1/diagnose", json={"crop_type": "Maize"})
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "UNSUPPORTED_CROP"
    assert data["is_supported"] is False
    assert "Rule SCAN-03" in data["message"]

def test_ai_safety_validator_low_confidence_rule_scan_04():
    # Scanning with simulated low confidence (0.52 < 0.65) should abstain and auto-escalate
    res = client.post("/api/v1/diagnose", json={
        "crop_type": "Cassava",
        "simulated_confidence": 0.52
    })
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "ESCALATED_LOW_CONFIDENCE"
    assert data["confidence_band"] == "LOW"
    assert "Rule SCAN-04" in data["message"]

def test_county_weather():
    res = client.get("/api/v1/weather")
    assert res.status_code == 200
    data = res.json()
    assert len(data) == 3
    counties = [w["county"] for w in data]
    assert "Bong" in counties
    assert "Nimba" in counties
    assert "Lofa" in counties
