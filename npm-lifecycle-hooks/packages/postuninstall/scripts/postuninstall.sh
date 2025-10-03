#!/usr/bin/env bash
set -euo pipefail

WEBHOOK="${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}"

echo "[postuninstall] sending event to $WEBHOOK"
payload='{"phase":"postuninstall","package":"ntl-demo-postuninstall","host":"'"${HOSTNAME:-unknown}"'"}'
curl -s -X POST "$WEBHOOK" -H 'Content-Type: application/json' -d "$payload" >/dev/null 2>&1 || true
echo "[postuninstall] done"

