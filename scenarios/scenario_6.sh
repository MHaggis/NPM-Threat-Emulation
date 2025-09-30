#!/usr/bin/env bash
set -e

# Scenario 6: npm Worm Propagation Simulation

# Load environment variables if not already set
if [ -z "${FAKE_NPM_TOKEN-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
  if [ -f "$ROOT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$ROOT_DIR/.env"
    set +a
  fi
  export FAKE_NPM_TOKEN="${FAKE_NPM_TOKEN:-npm_test_token_12345}"
fi

echo "Creating test packages..."
for i in {1..3}; do
  DIR="test-package-$i"
  rm -rf "$DIR"
  mkdir -p "$DIR"
  cat > "$DIR/package.json" << EOF
{
  "name": "test-package-$i",
  "version": "1.0.$i",
  "description": "Test package $i for worm propagation simulation"
}
EOF
done

export NPM_TOKEN="$FAKE_NPM_TOKEN"

echo "Simulating worm propagation across packages..."
for i in {1..3}; do
  echo "[$i/3] Publishing test-package-$i..."
  cd "test-package-$i"
  npm publish --dry-run 2>/dev/null || echo "  → Mock publish: test-package-$i"
  cd ..
done

echo "Scenario 6 complete"

