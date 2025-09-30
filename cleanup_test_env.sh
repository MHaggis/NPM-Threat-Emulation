#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$ROOT_DIR/tmp"

# Stop local HTTP server if we started it
if [ -f "$TMP_DIR/http_server.pid" ]; then
  PID="$(cat "$TMP_DIR/http_server.pid" || true)"
  if [ -n "$PID" ]; then
    echo "Stopping mock server (PID: $PID)..."
    kill "$PID" 2>/dev/null || true
    sleep 1
    kill -9 "$PID" 2>/dev/null || true
  fi
  rm -f "$TMP_DIR/http_server.pid"
fi

# Remove artifacts
rm -rf "$ROOT_DIR"/test-*/
rm -rf "$ROOT_DIR"/test-repo/
rm -rf "$ROOT_DIR"/test-malicious-package/
rm -rf "$ROOT_DIR"/shai-hulud-*/
rm -rf "$ROOT_DIR"/bundle-repack-test/
rm -rf "$ROOT_DIR"/node_modules/
rm -f "$ROOT_DIR"/package-lock.json 2>/dev/null || true

# Remove temp files from system /tmp
rm -f /tmp/stage*.js 2>/dev/null || true
rm -rf /tmp/fake-secrets 2>/dev/null || true
rm -f /tmp/trufflehog_stub 2>/dev/null || true
rm -f /tmp/trufflehog_release.tar.gz 2>/dev/null || true
rm -rf /tmp/trufflehog_extracted 2>/dev/null || true
rm -f /tmp/shai-hulud-secrets.json 2>/dev/null || true
rm -f /tmp/trufflehog_results.json 2>/dev/null || true
rm -f /tmp/shai_hulud_trufflehog_post.log 2>/dev/null || true

# Clean repo tmp directory (keep the directory but remove artifacts)
rm -f "$TMP_DIR"/*.sh 2>/dev/null || true
rm -f "$TMP_DIR"/*.log 2>/dev/null || true
rm -f "$TMP_DIR"/bundle_repack_summary.txt 2>/dev/null || true
rm -f "$TMP_DIR"/shai_hulud_trufflehog_post.log 2>/dev/null || true
rm -f "$TMP_DIR"/trufflehog_results.json 2>/dev/null || true
rm -f "$TMP_DIR"/trufflehog_release.tar.gz 2>/dev/null || true
rm -f "$TMP_DIR"/shai-hulud-secrets.json 2>/dev/null || true
rm -f "$TMP_DIR"/payload_*.bin 2>/dev/null || true

# Reset npm cache
npm cache clean --force 2>/dev/null || true

# Clear git global config we may have set in tests
git config --global --unset user.name 2>/dev/null || true
git config --global --unset user.email 2>/dev/null || true

echo "Environment cleaned up."

