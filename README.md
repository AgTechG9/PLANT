# PLANT: AI Smart Farming Assistant
> **AgTech Hackathon 2026 — Group 9 (Liberia)**  
> AI crop diagnostics, SMS/USSD offline integration, and agricultural triage for smallholder farmers in Bong, Nimba, and Lofa counties.

---

## Architecture Overview

```
                          ┌─────────────────────────────┐
                          │   Mobile / Web (Flutter)    │
                          │   Leaf Scanner • Dialpad    │
                          └──────────────┬──────────────┘
                                         │
                   ┌─────────────────────┴─────────────────────┐
                   ▼                                           ▼
      ┌─────────────────────────┐                 ┌─────────────────────────┐
      │   Python AI Backend     │                 │   .NET 10 Admin API     │
      │   (FastAPI + SQLite)    │                 │   (Gorpu - Triage / EF) │
      │   Port 8000             │                 │   Port 5000 / 5124      │
      └────────────┬────────────┘                 └─────────────────────────┘
                   │
    ┌──────────────┴──────────────┐
    ▼                             ▼
┌───────────────────────┐   ┌───────────────────────┐
│  CARI Knowledge Base  │   │  USSD (*123#) & SMS   │
│  (Suakoko Vetted)     │   │  (Orange LR / MTN)    │
└───────────────────────┘   └───────────────────────┘
```

---

## Default Credentials (Username & Password)

| Role | Username | Password | Scope |
|---|---|---|---|
| **ADMIN** | `admin` | `admin123` | System oversight & full triage |
| **AGENT** | `agent_suakoko` | `agent123` | Field agent registration & triage |
| **FARMER** | `farmer_korto` | `farmer123` | Farm overview & diagnostics history |

*(No Google Auth — Username & Password only)*

---

## Quick Start

### 1. Python AI Backend (`backend/`)
```bash
cd backend
source .venv/bin/activate    # or: python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```
- API Docs: `http://localhost:8000/api/v1/docs`
- Health check: `http://localhost:8000/api/v1/health`
- Run tests: `pytest -v` (10/10 passing)

### 2. Flutter Mobile & Web (`apps/mobile/`)
```bash
cd apps/mobile
flutter pub get
# Run in Chrome (Web)
flutter run -d chrome
# Or build production web bundle
flutter build web
```

### 3. Gorpu's .NET Admin API (`backend-dotnet/`)
```bash
cd backend-dotnet
dotnet run
```
- Health check: `http://localhost:5124/health`
- Farmers API: `http://localhost:5124/api/v1/farmers`
- Cases API: `http://localhost:5124/api/v1/cases`

---

## Hackathon Rules & Safety Guardrails

- **Rule SCAN-03**: Explicit abstention on unsupported crops (rejects non-Cassava/Pepper with actionable guidance).
- **Rule SCAN-04**: Blurry image abstention & low-confidence auto-escalation (<65% flagged to Extension Officers).
- **Rule ADV-01**: Only CARI-vetted advice delivered to farmers.
- **Rule SMS-01**: Strict ≤160-character single-segment SMS templates for Liberian telcos.
