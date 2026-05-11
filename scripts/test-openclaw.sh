#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${OPENCLAW_CONFIG:-$ROOT_DIR/openclaw.json}"
FAILURES=0

pass() {
  printf '[ok] %s\n' "$*"
}

fail() {
  printf '[fail] %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

warn() {
  printf '[warn] %s\n' "$*" >&2
}

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
    pass ".env loaded without printing secret values"
  else
    warn ".env not found; using current process environment only"
  fi
}

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    pass "$name is on PATH"
  else
    fail "$name is not on PATH"
  fi
}

check_node() {
  if ! command -v node >/dev/null 2>&1; then
    fail "node is not on PATH"
    return
  fi

  local major
  major="$(node -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || printf '0')"
  if [ "$major" -ge 20 ]; then
    pass "Node.js version is compatible: $(node -v)"
  else
    fail "Node.js 20+ required/recommended; found $(node -v 2>/dev/null || printf unknown)"
  fi
}

check_config_json() {
  if node -e 'const fs=require("fs"); JSON.parse(fs.readFileSync(process.argv[1], "utf8"));' "$CONFIG_FILE"; then
    pass "openclaw.json parses as strict JSON"
  else
    fail "openclaw.json is not valid JSON"
  fi
}

check_env_token() {
  if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    pass "TELEGRAM_BOT_TOKEN is set; value intentionally hidden"
  else
    fail "TELEGRAM_BOT_TOKEN is not set"
  fi
}

check_openclaw() {
  if ! command -v openclaw >/dev/null 2>&1; then
    fail "Cannot validate OpenClaw because CLI is missing"
    return
  fi

  if openclaw --version >/dev/null 2>&1; then
    pass "openclaw --version succeeded"
  else
    fail "openclaw --version failed"
  fi

  if openclaw gateway --help >/dev/null 2>&1; then
    pass "openclaw gateway command is available"
  else
    fail "openclaw gateway command is unavailable"
  fi

  if openclaw channels login --channel whatsapp --help >/dev/null 2>&1; then
    pass "WhatsApp setup command is available"
  else
    warn "WhatsApp setup command did not respond; install @openclaw/whatsapp before QR pairing"
  fi

  if OPENCLAW_CONFIG_PATH="$CONFIG_FILE" openclaw config validate >/dev/null 2>&1; then
    pass "openclaw config validate accepted this config"
  else
    warn "openclaw config validate reported issues; run 'OPENCLAW_CONFIG_PATH=$CONFIG_FILE openclaw config validate' for details"
  fi
}

check_codex() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "codex CLI is not on PATH; optional for Qwen-only Yuna"
    return
  fi

  if codex --version >/dev/null 2>&1; then
    pass "optional codex --version succeeded"
  else
    warn "optional codex --version failed"
  fi

  if codex app-server --help >/dev/null 2>&1; then
    pass "optional codex app-server command is available"
  else
    warn "optional codex app-server command is unavailable or too old"
  fi
}

check_start_command() {
  if bash -n "$ROOT_DIR/scripts/start.sh"; then
    pass "scripts/start.sh syntax is valid"
  else
    fail "scripts/start.sh has a syntax error"
  fi

  if grep -q 'OPENCLAW_CONFIG_PATH' "$ROOT_DIR/scripts/start.sh" && grep -q 'openclaw gateway run' "$ROOT_DIR/scripts/start.sh"; then
    pass "service start command is configured with OPENCLAW_CONFIG_PATH"
  else
    fail "scripts/start.sh does not start OpenClaw Gateway with the project config"
  fi
}

main() {
  cd "$ROOT_DIR"

  load_env
  check_node
  check_cmd npm
  check_config_json
  check_env_token
  check_openclaw
  check_codex
  check_start_command

  if [ "$FAILURES" -gt 0 ]; then
    printf '\nSmoke tests completed with %d failure(s).\n' "$FAILURES" >&2
    exit 1
  fi

  printf '\nSmoke tests completed successfully.\n'
}

main "$@"
