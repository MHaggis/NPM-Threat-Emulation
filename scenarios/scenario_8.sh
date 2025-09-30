#!/usr/bin/env bash
set -e

# Scenario 8: GitHub Repository Weaponization

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
fi

WORKDIR="shai-hulud-migration-test"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
git init >/dev/null 2>&1

cat > data.json << EOF
{
  "timestamp": "$(date -Iseconds)",
  "stolen_secrets": {
    "github_token": "$FAKE_GITHUB_TOKEN",
    "npm_token": "$FAKE_NPM_TOKEN",
    "aws_credentials": {
      "access_key": "$FAKE_AWS_KEY",
      "secret_key": "fake_secret_123"
    }
  },
  "environment_vars": {
    "PATH": "$PATH",
    "USER": "$USER"
  }
}
EOF

git add data.json
git commit -m "Shai-Hulud Migration - Test Data" >/dev/null 2>&1 || true

echo "Created repository: $WORKDIR"
echo "Repository contains simulated stolen credentials"
echo "Scenario 8 complete"

