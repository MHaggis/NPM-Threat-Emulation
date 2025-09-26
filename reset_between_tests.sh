#!/usr/bin/env bash
set -e

# Quick reset between scenarios
if [ -n "${BASH_VERSION-}" ]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION-}" ]; then
  SCRIPT_PATH="${(%):-%x}"
else
  SCRIPT_PATH="$0"
fi
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH" 2>/dev/null)" 2>/dev/null || pwd)"
TMP_DIR="$ROOT_DIR/tmp"

rm -rf "$ROOT_DIR"/test-* 2>/dev/null || true
rm -rf "$ROOT_DIR"/shai-hulud-* 2>/dev/null || true
rm -f /tmp/stage*.js 2>/dev/null || true
rm -f /tmp/fake-secrets/* 2>/dev/null || true

npm cache clean --force 2>/dev/null || true

git config --global --unset user.name 2>/dev/null || true
git config --global --unset user.email 2>/dev/null || true

# Stop local mock server if running (so next run can restart cleanly)
if [ -f "$TMP_DIR/http_server.pid" ]; then
  PID="$(head -n1 "$TMP_DIR/http_server.pid" 2>/dev/null || true)"
  if [ -n "$PID" ]; then
    kill "$PID" 2>/dev/null || true
  fi
  rm -f "$TMP_DIR/http_server.pid"
fi

echo "Between-tests reset complete."

