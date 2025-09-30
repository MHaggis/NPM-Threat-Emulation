#!/usr/bin/env bash
set -e

# Scenario 7: Cloud Metadata Endpoint Probing

npm init -y >/dev/null 2>&1 || true
timeout 10 npm install test-package >/dev/null 2>&1 &
NPM_PID=$!
sleep 1

curl -m 5 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "AWS metadata probe failed"
curl -m 5 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/ 2>/dev/null || echo "GCP metadata probe failed"
curl -m 5 -H "Metadata: true" http://169.254.169.254/metadata/instance?api-version=2021-02-01 2>/dev/null || echo "Azure metadata probe failed"

# Clean up background npm process if still running
if ps -p "$NPM_PID" >/dev/null 2>&1; then
  kill "$NPM_PID" 2>/dev/null || true
fi
wait "$NPM_PID" 2>/dev/null || true
echo "Scenario 7 complete"

