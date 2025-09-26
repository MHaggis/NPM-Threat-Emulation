#!/usr/bin/env bash
set -e

# Simple setup for local emulation (works in bash and zsh)
if [ -n "${BASH_VERSION-}" ]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION-}" ]; then
  SCRIPT_PATH="${(%):-%x}"
else
  SCRIPT_PATH="$0"
fi
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH" 2>/dev/null)" 2>/dev/null || pwd)"
TMP_DIR="$ROOT_DIR/tmp"
mkdir -p "$TMP_DIR"

# Load optional .env overrides (robust)
if [ -f "$ROOT_DIR/.env" ]; then
  set +u 2>/dev/null || true
  set -a
  # shellcheck disable=SC1090
  . "$ROOT_DIR/.env"
  set +a
fi

export MOCK_WEBHOOK="${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}"
export FAKE_NPM_TOKEN="npm_test_token_12345"
export FAKE_GITHUB_TOKEN="ghp_test_token_abcdef"
export FAKE_AWS_KEY="AKIA_TEST_KEY_12345"

start_server() {
  local port="$1"
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found. Cannot start local mock server."
    echo "Either install python3 (e.g., apt-get install -y python3) or set an external webhook via use_webhook_url.sh"
    return 1
  fi
  # Kill previous if tracked
  if [ -f "$TMP_DIR/http_server.pid" ]; then
    local oldpid
    oldpid="$(head -n1 "$TMP_DIR/http_server.pid" 2>/dev/null || true)"
    if [ -n "$oldpid" ]; then
      kill "$oldpid" 2>/dev/null || true
    fi
    rm -f "$TMP_DIR/http_server.pid"
  fi
  # Start POST-aware mock server
  (python3 "$ROOT_DIR/mock_server.py" --port "$port" >/dev/null 2>&1 & echo $! > "$TMP_DIR/http_server.pid")
  # Wait briefly until server answers POST 200
  local ok=""
  for _ in $(seq 1 25); do
    if [ "$(test_post "$port")" = "200" ]; then
      ok="yes"; break
    fi
    sleep 0.2
  done
  if [ -n "$ok" ]; then
    export MOCK_WEBHOOK="http://localhost:${port}/webhook-receiver"
    echo "Started local mock server on :${port}"
  else
    echo "Failed to start local mock server on :${port}" >&2
    if [ -f "$TMP_DIR/http_server.pid" ]; then rm -f "$TMP_DIR/http_server.pid"; fi
    return 1
  fi
}

test_post() {
  local port="$1"
  curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:${port}/webhook-receiver" -d "ping=1" || true
}

# If an external webhook is provided (non-localhost), use it and skip local server
if [ -n "${MOCK_WEBHOOK-}" ] && echo "$MOCK_WEBHOOK" | grep -qE '^https?://'; then
  if ! echo "$MOCK_WEBHOOK" | grep -qE '^https?://(localhost|127\.0\.0\.1)'; then
    echo "Using external webhook: $MOCK_WEBHOOK"
    echo "Skipping local mock server startup"
    # Stop any previously started local server
    if [ -f "$TMP_DIR/http_server.pid" ]; then
      oldpid="$(head -n1 "$TMP_DIR/http_server.pid" 2>/dev/null || true)"
      if [ -n "$oldpid" ]; then
        kill "$oldpid" 2>/dev/null || true
      fi
      rm -f "$TMP_DIR/http_server.pid"
    fi
  else
    # ensure localhost server is running
    if command -v nc >/dev/null 2>&1 && nc -z localhost 8080 >/dev/null 2>&1; then
      code="$(test_post 8080)"
      if [ "$code" = "200" ]; then
        export MOCK_WEBHOOK="http://localhost:8080/webhook-receiver"
        echo "Local mock server already running on :8080 and POST works"
      else
        if ! start_server 8080; then
          echo "Local server unavailable; continuing without local server."
        fi
      fi
    else
      if ! start_server 8080; then
        echo "Local server unavailable; continuing without local server."
      fi
    fi
  fi
else
  # No usable MOCK_WEBHOOK set; start local server
  if command -v nc >/dev/null 2>&1 && nc -z localhost 8080 >/dev/null 2>&1; then
    code="$(test_post 8080)"
    if [ "$code" = "200" ]; then
      export MOCK_WEBHOOK="http://localhost:8080/webhook-receiver"
      echo "Local mock server already running on :8080 and POST works"
    else
      if ! start_server 8080; then
        echo "Local server unavailable; set MOCK_WEBHOOK to an external URL."
      fi
    fi
  else
    if ! start_server 8080; then
      echo "Local server unavailable; set MOCK_WEBHOOK to an external URL."
    fi
  fi
fi

echo "Environment ready. Exports set for MOCK_WEBHOOK and fake tokens."

