#!/usr/bin/env bash
set -e

# Scenario 8: GitHub Repository Weaponization

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

