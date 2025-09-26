#!/usr/bin/env bash
set -e

# Helper to switch to a live webhook URL for tests.
# Usage:
#   source ./use_webhook_url.sh https://webhook.site/<uuid>

# Determine script directory robustly
if [ -n "${BASH_VERSION-}" ]; then
  SCRIPT_PATH="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION-}" ]; then
  SCRIPT_PATH="${(%):-%x}"
else
  SCRIPT_PATH="$0"
fi
ROOT_DIR="$(cd "$(dirname "$SCRIPT_PATH" 2>/dev/null)" 2>/dev/null || pwd)"
if [ ! -d "$ROOT_DIR" ] || [ "$ROOT_DIR" = "/" ]; then
  ROOT_DIR="$(pwd)"
fi

if [ -z "$1" ]; then
  echo "Usage: source ./use_webhook_url.sh <webhook_url>"
  return 1 2>/dev/null || exit 1
fi

URL="$1"
case "$URL" in
  http://*|https://*) ;;
  *) echo "Please provide a valid http(s) URL"; return 1 2>/dev/null || exit 1;;
esac

export MOCK_WEBHOOK="$URL"
TMP_ENV="$ROOT_DIR/.env.tmp"
if printf 'MOCK_WEBHOOK=%s\n' "$MOCK_WEBHOOK" > "$TMP_ENV" 2>/dev/null && mv -f "$TMP_ENV" "$ROOT_DIR/.env" 2>/dev/null; then
  echo "MOCK_WEBHOOK set to: $MOCK_WEBHOOK"
  echo "Saved to $ROOT_DIR/.env"
else
  echo "MOCK_WEBHOOK set to: $MOCK_WEBHOOK"
  echo "Could not write $ROOT_DIR/.env (permissions?)."
  echo "As a fallback, export this in your shell before sourcing setup:"
  echo "export MOCK_WEBHOOK='$MOCK_WEBHOOK'"
fi
echo "Re-source ./setup_test_env.sh to apply without starting local server."

