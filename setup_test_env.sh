#!/usr/bin/env bash

# Simple setup for local emulation
if [ -n "${BASH_VERSION-}" ]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION-}" ]; then
  SCRIPT_PATH="${(%):-%x}"
else
  SCRIPT_PATH="$0"
fi

# Get absolute path to script directory
if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
  ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
  # Fallback to current directory
  ROOT_DIR="$(pwd)"
fi

TMP_DIR="$ROOT_DIR/tmp"
mkdir -p "$TMP_DIR"

# Load optional .env overrides
if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$ROOT_DIR/.env"
  set +a
fi

# Export fake credentials
export FAKE_NPM_TOKEN="npm_test_token_12345"
export FAKE_GITHUB_TOKEN="ghp_test_token_abcdef"
export FAKE_AWS_KEY="AKIA_TEST_KEY_12345"

# Check if external webhook is configured
if [ -n "${MOCK_WEBHOOK-}" ] && echo "$MOCK_WEBHOOK" | grep -qvE '^https?://(localhost|127\.0\.0\.1)'; then
  echo "Using external webhook: $MOCK_WEBHOOK"
else
  # Start local mock server
  export MOCK_WEBHOOK="http://localhost:8080/webhook-receiver"
  
  # Check if server already running
  if curl --noproxy localhost -s -o /dev/null -w "%{http_code}" --max-time 1 -X POST "$MOCK_WEBHOOK" -d "ping=1" 2>/dev/null | grep -q "200"; then
    echo "Local mock server already running on :8080"
  else
    # Kill any old servers
    pkill -f "mock_server.py" 2>/dev/null || true
    rm -f "$TMP_DIR/http_server.pid"
    sleep 0.5
    
    if command -v python3 >/dev/null 2>&1; then
      # Start server using helper script
      SERVER_PID=$("$ROOT_DIR/start_mock_server.sh")
      if [ -n "$SERVER_PID" ]; then
        echo "$SERVER_PID" > "$TMP_DIR/http_server.pid"
        echo "Starting mock server (PID: $SERVER_PID)..."
        
        # Wait for server to be ready (max 5 seconds)
        for i in {1..10}; do
          sleep 0.5
          if curl --noproxy localhost -s -o /dev/null -w "%{http_code}" --max-time 1 -X POST "$MOCK_WEBHOOK" -d "ping=1" 2>/dev/null | grep -q "200"; then
            echo "Started local mock server on :8080"
            break
          fi
        done
        
        # Final check
        if ! curl --noproxy localhost -s -o /dev/null -w "%{http_code}" --max-time 1 -X POST "$MOCK_WEBHOOK" -d "ping=1" 2>/dev/null | grep -q "200"; then
          echo "Warning: Mock server may not have started. Check tmp/mock.log"
        fi
      else
        echo "Error: Failed to start mock server"
      fi
    else
      echo "python3 not found. Set MOCK_WEBHOOK to an external URL or install python3."
    fi
  fi
fi

echo "Environment ready. Exports set for MOCK_WEBHOOK and fake tokens."

