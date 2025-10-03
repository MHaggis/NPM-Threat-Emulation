#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$ROOT_DIR/npm-lifecycle-hooks"
TEST_DIR="$HOOKS_DIR/.test-project"

mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

if [ ! -f package.json ]; then
  echo '{"name":"ntl-hooks-test","version":"1.0.0","private":true}' > package.json
fi

echo "[+] Test project at $TEST_DIR"

echo "[+] Installing preinstall demo"
npm install "$HOOKS_DIR/packages/preinstall" --no-audit --prefer-offline

echo "[+] Installing install demo"
npm install "$HOOKS_DIR/packages/install" --no-audit --prefer-offline

echo "[+] Installing postinstall demo"
npm install "$HOOKS_DIR/packages/postinstall" --no-audit --prefer-offline

echo "[+] Installing postuninstall demo, then uninstall to trigger its hook"
npm install "$HOOKS_DIR/packages/postuninstall" --no-audit --prefer-offline
npm uninstall ntl-demo-postuninstall --no-audit || true

echo "[+] Done. Check your webhook receiver for four events."

