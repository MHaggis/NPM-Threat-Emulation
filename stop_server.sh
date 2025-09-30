#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$ROOT_DIR/tmp"

if [ -f "$TMP_DIR/http_server.pid" ]; then
  PID="$(cat "$TMP_DIR/http_server.pid" 2>/dev/null || true)"
  if [ -n "$PID" ]; then
    echo "Stopping mock server (PID: $PID)..."
    kill "$PID" 2>/dev/null || true
    sleep 1
    # Force kill if still running
    if ps -p "$PID" >/dev/null 2>&1; then
      kill -9 "$PID" 2>/dev/null || true
      echo "Mock server forcefully terminated"
    else
      echo "Mock server stopped"
    fi
  else
    echo "No PID found in $TMP_DIR/http_server.pid"
  fi
  rm -f "$TMP_DIR/http_server.pid"
else
  echo "Mock server not running (no PID file found)"
fi
