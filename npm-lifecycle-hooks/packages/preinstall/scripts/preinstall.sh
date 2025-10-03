#!/usr/bin/env bash
set -euo pipefail

WEBHOOK="${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}"

echo "[preinstall] sending event to $WEBHOOK"
payload='{"phase":"preinstall","package":"ntl-demo-preinstall","host":"'"${HOSTNAME:-unknown}"'"}'
curl -s -X POST "$WEBHOOK" -H 'Content-Type: application/json' -d "$payload" >/dev/null 2>&1 || true
echo "[preinstall] done"

