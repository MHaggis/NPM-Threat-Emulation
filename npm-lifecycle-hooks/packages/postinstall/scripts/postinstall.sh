#!/usr/bin/env bash
set -euo pipefail

WEBHOOK="${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}"

echo "[postinstall] sending event to $WEBHOOK"
payload='{"phase":"postinstall","package":"ntl-demo-postinstall","host":"'"${HOSTNAME:-unknown}"'"}'
curl -s -X POST "$WEBHOOK" -H 'Content-Type: application/json' -d "$payload" >/dev/null 2>&1 || true
echo "[postinstall] done"

