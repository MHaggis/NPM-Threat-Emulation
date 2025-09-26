#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$ROOT_DIR/tmp"

# Stop local HTTP server if we started it
if [ -f "$TMP_DIR/http_server.pid" ]; then
  PID="$(cat "$TMP_DIR/http_server.pid" || true)"
  if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null || true
  fi
  rm -f "$TMP_DIR/http_server.pid"
fi

# Remove artifacts
rm -rf "$ROOT_DIR"/test-*/
rm -rf "$ROOT_DIR"/test-repo/
rm -rf "$ROOT_DIR"/test-malicious-package/
rm -rf "$ROOT_DIR"/shai-hulud-*/
rm -rf "$ROOT_DIR"/node_modules/
rm -f "$ROOT_DIR"/package-lock.json 2>/dev/null || true

# Remove temp files
rm -f /tmp/stage*.js 2>/dev/null || true
rm -f /tmp/fake-secrets/* 2>/dev/null || true

# Reset npm cache
npm cache clean --force 2>/dev/null || true

# Clear git global config we may have set in tests
git config --global --unset user.name 2>/dev/null || true
git config --global --unset user.email 2>/dev/null || true

echo "Environment cleaned up."

