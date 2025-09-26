#!/usr/bin/env bash
set -e

echo "Starting NPM Supply Chain Attack Emulation Tests"
echo "================================================"

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/setup_test_env.sh"

for scenario in {1..8}; do
  echo "Running Scenario $scenario..."
  "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scenarios/scenario_${scenario}.sh"
  sleep 60
  echo "Scenario $scenario complete"
done

echo "All emulation tests completed"
echo "Check Splunk for generated events and alerts"

