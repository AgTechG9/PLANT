#!/usr/bin/env bash
set -e

echo "=========================================================="
echo "  🌿 STARTING PLANT AI DEMO PLATFORM (AGTECH HACKATHON 2026)"
echo "=========================================================="

# 1. Kill any existing instances on port 8000 and 3000
echo "--> Clearing ports 8000 & 3000..."
lsof -ti:8000 | xargs kill -9 2>/dev/null || true
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# 2. Start FastAPI AI Backend
echo "--> Starting Python FastAPI AI backend on http://127.0.0.1:8000 ..."
cd /Users/retr0/Desktop/AGTechG9/backend
source .venv/bin/activate
uvicorn app.main:app --host 127.0.0.1 --port 8000 > backend.log 2>&1 &
BACKEND_PID=$!
echo "    FastAPI running (PID: $BACKEND_PID)"

# 3. Start Flutter Web Server
echo "--> Starting Flutter Web App on http://127.0.0.1:3000 ..."
cd /Users/retr0/Desktop/AGTechG9
python3 -m http.server 3000 --directory apps/mobile/build/web > web.log 2>&1 &
WEB_PID=$!
echo "    Web app running (PID: $WEB_PID)"

sleep 2

echo "=========================================================="
echo "  ✓ EVERYTHING IS LIVE!"
echo "  • Flutter Web App:     http://localhost:3000"
echo "  • FastAPI API Docs:    http://localhost:8000/api/v1/docs"
echo "  • Backend Health:      http://localhost:8000/api/v1/health"
echo "=========================================================="
echo "Logs available at: backend/backend.log and web.log"
echo "To stop: lsof -ti:8000 -ti:3000 | xargs kill -9"
