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

### 4. Desktop Admin Workstation (GUI & CLI) (`apps/desktop/`)
```bash
# A. 1-Click Launch GUI Window (Deep Forest / Harvest Gold theme)
./run_desktop_window.sh
# Or view in any browser: http://localhost:8000/admin

# B. 1-Click Launch CLI Workstation (.NET 10 console)
./run_desktop_admin.sh
# Or run via dotnet CLI:
dotnet run --project apps/desktop/Plant.DesktopAdmin.csproj
```
- **6 Integrated Workstation Modules:**
  1. **Mission Control & Health Telemetry:** Live gateway ping, database latency, 54% female quota tracker, and Rule REG-03 livestock interest counter.
  2. **Master Escalation Workbench:** Rule SCAN-04 triage (<65% AI confidence / blurry scans) with 1-click CARI-vetted advice resolution & 160-char SMS dispatch.
  3. **Farmer Directory & Emergency Broadcast:** County filtering (Bong, Nimba, Lofa), STOP consent inspection, and county-targeted emergency broadcast.
  4. **USSD Engine & SMS Testbench:** Interactive virtual `*123#` dialer simulator and outbound SMS packet inspector with GSM character count checks.
  5. **Vetted CARI Knowledge Base:** Rule ADV-01 audit verifying zero hallucinations (`CARI-CAS-001`, `CARI-PEP-001`).
  6. **AI Diagnostics & Safety Validator:** Rule SCAN-03 guardrail demonstration (explicit warning returned for unsupported crops like Maize).
- **Standalone Binaries:** Available in `apps/desktop/dist/` for macOS (`osx-arm64`), Windows (`win-x64`), and Linux (`linux-x64`).

---

## Hackathon Rules & Safety Guardrails

- **Rule SCAN-03**: Explicit abstention on unsupported crops (rejects non-Cassava/Pepper with actionable guidance).
- **Rule SCAN-04**: Blurry image abstention & low-confidence auto-escalation (<65% flagged to Extension Officers).
- **Rule ADV-01**: Only CARI-vetted advice delivered to farmers.
- **Rule SMS-01**: Strict ≤160-character single-segment SMS templates for Liberian telcos.
