#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
CONFIG_FILE="${OPENCLAW_CONFIG:-$ROOT_DIR/openclaw.json}"

# shellcheck source=scripts/lib/env.sh
. "$ROOT_DIR/scripts/lib/env.sh"

main() {
  local telegram_enabled codex_enabled

  cd "$ROOT_DIR"

  if [ ! -f "$ENV_FILE" ]; then
    printf '.env is missing. Create it from .env.example and set local secrets.\n' >&2
    exit 1
  fi

  load_env_file "$ENV_FILE"

  require_env \
    QWEN_API_KEY \
    QWEN_BASE_URL \
    QWEN_MODEL \
    OPENCLAW_AGENT_NAME \
    TELEGRAM_BOT_TOKEN

  if ! command -v openclaw >/dev/null 2>&1; then
    printf 'openclaw CLI is not available. Run ./scripts/install.sh first.\n' >&2
    exit 127
  fi

  export OPENCLAW_CONFIG_PATH="$CONFIG_FILE"

  telegram_enabled="$(node -e 'const c=require(process.argv[1]); console.log(c.channels?.telegram?.enabled ? "enabled" : "disabled")' "$CONFIG_FILE" 2>/dev/null || printf 'unknown')"
  codex_enabled="$(node -e 'const c=require(process.argv[1]); console.log(c.plugins?.entries?.codex?.enabled ? "enabled" : "disabled")' "$CONFIG_FILE" 2>/dev/null || printf 'unknown')"

  printf 'Starting Yuna OpenClaw Gateway\n'
  printf '  active provider: qwen/%s\n' "$QWEN_MODEL"
  printf '  fallback provider: none\n'
  printf '  agent runtime: OpenClaw default\n'
  printf '  telegram: %s\n' "$telegram_enabled"
  printf '  codex: %s\n' "$codex_enabled"
  printf '  config: %s\n' "$OPENCLAW_CONFIG_PATH"
  printf '  secrets printed: no\n'

  exec openclaw gateway run
}

main "$@"
