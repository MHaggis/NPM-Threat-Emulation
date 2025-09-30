#!/usr/bin/env bash
set -e

# Scenario 9: bundle.js drop and temporary script execution chain

if ! command -v node >/dev/null 2>&1; then
  echo "Node.js is required for Scenario 9."
  exit 0
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKDIR="${ROOT_DIR}/bundle-repack-test"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR/original"

cat > "$WORKDIR/original/package.json" <<'EOF'
{
  "name": "victim-package",
  "version": "1.0.0",
  "description": "Clean package used for bundle repack testing",
  "main": "index.js"
}
EOF

cat > "$WORKDIR/original/index.js" <<'EOF'
module.exports = function victim() {
  return "ok";
};
EOF

tar -czf "$WORKDIR/original-package.tgz" -C "$WORKDIR/original" .

mkdir -p "$WORKDIR/repacked"
tar -xzf "$WORKDIR/original-package.tgz" -C "$WORKDIR/repacked"

cat > "$WORKDIR/repacked/package.json" <<'EOF'
{
  "name": "victim-package",
  "version": "1.0.1",
  "description": "Compromised by Shai-Hulud simulation",
  "main": "index.js",
  "scripts": {
    "postinstall": "node bundle.js"
  },
  "files": [
    "index.js",
    "bundle.js",
    "package.tar"
  ]
}
EOF

TMP_DIR="${ROOT_DIR}/tmp"
mkdir -p "$TMP_DIR"

cat > "$WORKDIR/repacked/bundle.js" <<'BUNDLE_EOF'
const fs = require('fs');
const { spawnSync } = require('child_process');
const path = require('path');

const token = process.argv[2] || process.env.FAKE_GITHUB_TOKEN || 'fake-token';
const org = process.argv[3] || 'fake-org';
const webhook = process.env.MOCK_WEBHOOK || 'http://localhost:8080/webhook-receiver';

const repoRoot = path.resolve(__dirname, '../..');
const tmpDir = path.join(repoRoot, 'tmp');
const logFile = path.join(tmpDir, 'shai-hulud-bundle.log');
const processorPath = path.join(tmpDir, 'processor.sh');
const migratePath = path.join(tmpDir, 'migrate-repos.sh');

if (!fs.existsSync(tmpDir)) {
  fs.mkdirSync(tmpDir, { recursive: true });
}

const processorScript = `#!/usr/bin/env bash
set -e
LOG_FILE="${logFile}"
TOKEN="$1"
TARGET_REPO="${webhook}"
cat <<PROCESSOR
[processor] using token: \${TOKEN}
[processor] checking branch creation permissions
[processor] would create branch shai-hulud and drop workflow to \${TARGET_REPO}
PROCESSOR
`;

const migrateScript = `#!/usr/bin/env bash
set -e
LOG_FILE="${logFile}"
ORG_NAME="$1"
cat <<MIGRATE
[migrate] starting migration for org: \${ORG_NAME}
[migrate] simulating repo mirrors to public space
MIGRATE
`;

fs.writeFileSync(processorPath, processorScript);
fs.chmodSync(processorPath, 0o755);
fs.writeFileSync(migratePath, migrateScript);
fs.chmodSync(migratePath, 0o755);

spawnSync(processorPath, [token], { stdio: 'ignore' });
spawnSync(migratePath, [org], { stdio: 'ignore' });

const summary = [
  `[bundle] bundle.js executed with token ${token}`,
  '[bundle] processor.sh and migrate-repos.sh spawned successfully',
  `[bundle] temp scripts logged to ${logFile}`
].join('\n');

fs.appendFileSync(logFile, summary + '\n');
BUNDLE_EOF

cp "$WORKDIR/original-package.tgz" "$WORKDIR/repacked/package.tar.gz"
tar -cf "$WORKDIR/repacked/package.tar" -C "$WORKDIR/repacked" bundle.js package.json index.js

node "$WORKDIR/repacked/bundle.js" "${FAKE_GITHUB_TOKEN:-fake-github-token}" "simulated-org"

SUMMARY_FILE="${TMP_DIR}/bundle_repack_summary.txt"
cat > "$SUMMARY_FILE" <<EOF
Bundle repack simulation completed at $(date -Iseconds)
Workdir: $WORKDIR
Artifacts created:
- ${WORKDIR}/repacked/bundle.js
- ${WORKDIR}/repacked/package.tar
- ${WORKDIR}/repacked/package.tar.gz
- ${TMP_DIR}/processor.sh
- ${TMP_DIR}/migrate-repos.sh
- ${TMP_DIR}/shai-hulud-bundle.log
EOF

echo "Scenario 9 complete"
echo "Inspect artifacts:"
echo "  - ${TMP_DIR}/processor.sh"
echo "  - ${TMP_DIR}/migrate-repos.sh"
echo "  - ${TMP_DIR}/shai-hulud-bundle.log"
echo "  - ${TMP_DIR}/bundle_repack_summary.txt"
