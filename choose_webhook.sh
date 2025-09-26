#!/usr/bin/env bash
set -e

# Determine script directory (bash/zsh/posix)
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

echo "Use live webhook URL (e.g., https://webhook.site/<uuid>)? [y/N]"
read -r ans
case "$ans" in
  y|Y|yes|YES)
    echo "Enter webhook URL:"
    read -r url
    if [ -z "$url" ]; then
      echo "No URL provided. Aborting."; exit 1
    fi
    case "$url" in
      http://*|https://*) ;;
      *) echo "Please provide a valid http(s) URL"; exit 1;;
    esac
    export MOCK_WEBHOOK="$url"
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
    echo "Re-source: source ./setup_test_env.sh"
    ;;
  *)
    # Clear persisted override if exists
    if [ -f "$ROOT_DIR/.env" ]; then
      rm -f "$ROOT_DIR/.env"
      echo "Removed $ROOT_DIR/.env; local mock server will be used."
    else
      echo "Keeping local mock server (default)."
    fi
    ;;
esac

