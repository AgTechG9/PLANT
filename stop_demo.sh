#!/usr/bin/env bash
echo "Stopping PLANT demo servers on ports 8000 & 3000..."
lsof -ti:8000 | xargs kill -9 2>/dev/null || true
lsof -ti:3000 | xargs kill -9 2>/dev/null || true
echo "✓ All servers stopped."
