#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${OPENCLAW_CONFIG:-$ROOT_DIR/openclaw.json}"

load_env() {
  local env_file="$ROOT_DIR/.env"
  local line key value current
  if [ -f "$env_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      case "$line" in
        ''|'#'*) continue ;;
      esac
      key="${line%%=*}"
      value="${line#*=}"
      case "$key" in
        ''|*[!A-Za-z0-9_]*|[0-9]*) continue ;;
      esac
      current="${!key-}"
      if [ -z "$current" ] && [ -n "$value" ]; then
        export "$key=$value"
      fi
    done < "$env_file"
  fi
}

main() {
  cd "$ROOT_DIR"
  load_env

  if ! command -v openclaw >/dev/null 2>&1; then
    printf 'openclaw CLI is not available. Run ./scripts/install.sh first.\n' >&2
    exit 127
  fi

  if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
    printf 'TELEGRAM_BOT_TOKEN is not set. Edit .env before starting Telegram.\n' >&2
    exit 1
  fi

  export OPENCLAW_AGENT_NAME="${OPENCLAW_AGENT_NAME:-Yuna}"
  if [ -n "${OPENCLAW_AGENT_RUNTIME:-}" ]; then
    export OPENCLAW_AGENT_RUNTIME
  fi

  export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"

  exec openclaw gateway run
}

main "$@"
