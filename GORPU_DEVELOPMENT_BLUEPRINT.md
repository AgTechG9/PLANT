# PLANT · Tech Lead Handover (Gorpu)

**Repo:** [github.com/AgTechG9/PLANT](https://github.com/AgTechG9/PLANT) (`main` branch)  
**Owners:** Gorpu Keller (Tech Lead) & John Namayan (Team Lead)

---

## 1. What's Done & Tested (On `main`)
* **Monorepo setup:** Cleaned repo, removed unused branches, set `.gitignore`.
* **FastAPI Backend (`backend/`):**
  * `/api/v1/health` (Telemetry)
  * `/api/v1/farmers` & `/metrics` (Bong/Nimba/Lofa, 54% female quota, Rule REG-03 livestock counter)
  * `/api/v1/cases` & `PATCH /cases/{id}` (Triage queue for <65% confidence/blurry scans, Rule SCAN-04)
  * `/api/v1/knowledge` (CARI-vetted advice, Rule ADV-01)
  * `/api/v1/sms/broadcast` (160-char SMS dispatcher + STOP consent check)
  * `/api/v1/ussd` (*123# state machine for Orange/MTN)
  * `/api/v1/diagnose` (Confidence bands + Rule SCAN-03 unsupported crop warning)
* **Auth (No Google Auth):**
  * Pure **Username & Password** for `ADMIN`, `AGENT`, and `FARMER`.
  * Seed accounts: `admin`/`admin123`, `agent_suakoko`/`agent123`, `farmer_korto`/`farmer123`.
* **Tests:** 9/9 automated tests passing (`pytest`).

---

## 2. Platform Architecture & Separation of Concerns

```
                          ┌──────────────────────────────────────────────┐
                          │         PLANT MONOREPO (main)                │
                          └──────────────────────┬───────────────────────┘
                                                 │
                   ┌─────────────────────────────┴─────────────────────────────┐
                   │                                                           │
        ┌──────────▼──────────┐                                     ┌──────────▼──────────┐
        │   GORPU'S DOMAIN    │                                     │    JOHN'S DOMAIN    │
        │  Desktop Admin &    │                                     │   Mobile Client &   │
        │  .NET Core Backend  │                                     │     AI Services     │
        └──────────┬──────────┘                                     └──────────┬──────────┘
                   │                                                           │
      ┌────────────┴────────────┐                                 ┌────────────┴────────────┐
      │                         │                                 │                         │
┌─────▼──────────┐      ┌───────▼────────┐                  ┌─────▼──────────┐      ┌───────▼────────┐
│ Desktop UI     │      │ ASP.NET Core   │                  │ React / PWA    │      │ Python Vision  │
│ (Admin Console)│◄────►│ (.NET 10 API)  │                  │ (Camera & Sync)│◄────►│ & USSD Engine  │
│ 6 Modules      │      │ Database / EF  │                  │ Farmer Client  │      │ LiteRT Models  │
└────────────────┘      └────────────────┘                  └────────────────┘      └────────────────┘
```

---

## 3. Gorpu's Deliverables

### A. Backend (.NET 10 Web API) -> `backend-dotnet/`
1. **Auth:** Username + Password for `ADMIN`, `AGENT`, `FARMER`.
2. **Cases Triage:** `GET /cases` (<65% or blurry) & `PATCH /cases/{id}` (160-char verified SMS).
3. **Farmer Directory:** `GET /farmers` & `/farmers/metrics`.
4. **Emergency Broadcast:** `POST /sms/broadcast` (160-char check).

### B. Desktop Admin Workstation -> `apps/desktop/`
1. **Mission Control:** Live API telemetry, farmer counter, 54% female badge, SMS log.
2. **Master Escalation Workbench:** Leaf photo inspection side-by-side with AI confidence; 1-click verified CARI advice dispatch.
3. **Farmer Directory & Broadcast:** Searchable table by county, STOP status, emergency broadcast modal.
4. **USSD & SMS Testbench:** Virtual `*123#` dialer for pitch demos, SMS packet inspector.
5. **Vetted Knowledge Base:** Audit CARI extension guides (`CARI-CAS-001`, `CARI-PEP-001`).
6. **AI Safety Validator:** Demo confidence bands and Rule SCAN-03 warning for maize.

---

## 4. Quick Start Commands

```bash
# 1. Update local repo
git pull origin main

# 2. Run your .NET 10 Web API (Pre-scaffolded & ready!)
cd backend-dotnet
dotnet run
# Endpoints live: http://localhost:5124/health, /api/v1/farmers, /api/v1/cases

# 3. Reference Python AI backend
cd ../backend && source .venv/bin/activate && pytest -v

# 4. Flutter Web / Mobile App
cd ../apps/mobile && flutter run -d chrome
```
