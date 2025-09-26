#!/usr/bin/env bash
set -e

# Scenario 2: TruffleHog Secret Scanning Simulation

if ! command -v trufflehog >/dev/null 2>&1; then
  if command -v go >/dev/null 2>&1; then
    echo "Installing TruffleHog..."
    GO111MODULE=on go install github.com/trufflesecurity/trufflehog/v3@latest || true
    export PATH="$HOME/go/bin:$PATH"
  else
    echo "Go not installed; skipping trufflehog install."
  fi
fi

mkdir -p /tmp/fake-secrets
echo "fake_api_key=sk-test123456789" > /tmp/fake-secrets/.env
echo "github_token=ghp_faketoken123" > /tmp/fake-secrets/config.yaml

npm init -y >/dev/null 2>&1 || true
npm install test-package &
INSTALL_PID=$!
sleep 2

if command -v trufflehog >/dev/null 2>&1; then
  trufflehog --results=verified --json filesystem /tmp/fake-secrets || true
else
  echo "trufflehog not available; simulating run."
fi

wait "$INSTALL_PID" || true
echo "Scenario 2 complete"

