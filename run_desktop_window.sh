#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

echo "=========================================================="
echo "  🌿 LAUNCHING PLANT DESKTOP ADMIN WORKSTATION (GUI)"
echo "  Ministry of Agriculture · CARI Suakoko Operational Hub"
echo "=========================================================="

URL="${1:-http://localhost:8000/admin}"

# Ensure backend is responding
if ! curl -s --max-time 2 http://localhost:8000/api/v1/health >/dev/null 2>&1; then
    echo "--> Backend not detected on :8000. Starting Python FastAPI backend..."
    cd "$DIR/backend"
    source .venv/bin/activate
    nohup uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload > backend.log 2>&1 &
    sleep 2
    cd "$DIR"
fi

echo "--> Opening Desktop Admin Workstation at $URL ..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    if [ -d "/Applications/Google Chrome.app" ]; then
        open -na "Google Chrome" --args --app="$URL" --window-size=1400,900
    elif [ -d "/Applications/Microsoft Edge.app" ]; then
        open -na "Microsoft Edge" --args --app="$URL" --window-size=1400,900
    elif [ -d "/Applications/Brave Browser.app" ]; then
        open -na "Brave Browser" --args --app="$URL" --window-size=1400,900
    else
        open "$URL"
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v google-chrome >/dev/null 2>&1; then
        google-chrome --app="$URL" --window-size=1400,900 &
    elif command -v chromium-browser >/dev/null 2>&1; then
        chromium-browser --app="$URL" --window-size=1400,900 &
    else
        xdg-open "$URL"
    fi
else
    # Windows / Git Bash
    start "$URL"
fi

echo "=========================================================="
echo "  ✓ Desktop Admin GUI is running!"
echo "  URL: $URL"
echo "=========================================================="
