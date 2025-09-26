#!/usr/bin/env bash
set -e

# Scenario 6: npm Worm Propagation Simulation

for i in {1..5}; do
  DIR="test-package-$i"
  rm -rf "$DIR"
  mkdir -p "$DIR"
  cat > "$DIR/package.json" << EOF
{
  "name": "test-package-$i",
  "version": "1.0.$i",
  "description": "Test package $i"
}
EOF
done

export NPM_TOKEN="$FAKE_NPM_TOKEN"

for i in {1..5}; do
  cd "test-package-$i"
  echo "Simulating npm publish for package $i"
  npm publish --dry-run 2>/dev/null || echo "Mock publish: test-package-$i"
  cd ..
  sleep 30
done

echo "Scenario 6 complete"

