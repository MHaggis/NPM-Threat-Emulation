#!/usr/bin/env bash
set -e

# Scenario 7: Cloud Metadata Endpoint Probing

npm init -y >/dev/null 2>&1 || true
npm install test-package &
NPM_PID=$!
sleep 1

curl -m 5 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "AWS metadata probe failed"
curl -m 5 -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/ 2>/dev/null || echo "GCP metadata probe failed"
curl -m 5 -H "Metadata: true" http://169.254.169.254/metadata/instance?api-version=2021-02-01 2>/dev/null || echo "Azure metadata probe failed"

wait "$NPM_PID" || true
echo "Scenario 7 complete"

