#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$DIR"

echo "=========================================================="
echo "  🌿 PLANT ADMIN MISSION CONTROL WORKSTATION (.NET 10)"
echo "  Ministry of Agriculture · CARI Suakoko Operational Hub"
echo "=========================================================="

if [ -f "$DIR/apps/desktop/dist/osx-arm64/Plant.DesktopAdmin" ] && [[ "$(uname -m)" == "arm64" ]] && [[ "$(uname -s)" == "Darwin" ]]; then
    exec "$DIR/apps/desktop/dist/osx-arm64/Plant.DesktopAdmin" "$@"
else
    exec dotnet run --project "$DIR/apps/desktop/Plant.DesktopAdmin.csproj" "$@"
fi
