#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
FAILURES=0

# shellcheck source=scripts/lib/env.sh
. "$ROOT_DIR/scripts/lib/env.sh"

pass() {
  printf '[ok] %s\n' "$*"
}

fail() {
  printf '[fail] %s\n' "$*"
  FAILURES=$((FAILURES + 1))
}

probe_status() {
  local name="$1"
  local status="$2"

  case "$status" in
    200|204)
      pass "$name succeeded"
      ;;
    401|403)
      fail "$name reached Qwen, but authentication failed"
      ;;
    404)
      fail "$name reached Qwen, but route/model was not found"
      ;;
    408|425|429|500|502|503|504)
      fail "$name reached Qwen, but provider is unavailable or throttled: HTTP $status"
      ;;
    000)
      fail "$name failed before HTTP response"
      ;;
    *)
      fail "$name returned HTTP $status"
      ;;
  esac
}

check_models() {
  local base status tmp
  tmp="$(mktemp)"
  base="${QWEN_BASE_URL%/}"

  status="$(curl -sS -m 15 -o "$tmp" -w '%{http_code}' \
    -H "Authorization: Bearer ${QWEN_API_KEY}" \
    "$base/models" 2>/dev/null || printf '000')"
  status="${status: -3}"
  rm -f "$tmp"
  probe_status "Qwen /models connectivity" "$status"
}

check_chat_completion() {
  local base status tmp
  tmp="$(mktemp)"
  base="${QWEN_BASE_URL%/}"

  status="$(curl -sS -m 30 -o "$tmp" -w '%{http_code}' \
    -H "Authorization: Bearer ${QWEN_API_KEY}" \
    -H 'Content-Type: application/json' \
    -d '{"model":"'"${QWEN_MODEL}"'","messages":[{"role":"user","content":"Reply with OK only."}],"max_tokens":4,"temperature":0}' \
    "$base/chat/completions" 2>/dev/null || printf '000')"
  status="${status: -3}"
  rm -f "$tmp"
  probe_status "Qwen chat completion" "$status"
}

main() {
  cd "$ROOT_DIR"

  if [ -f "$ENV_FILE" ]; then
    pass ".env exists"
  else
    fail ".env is missing"
    printf '\nQwen tests completed with %d failure(s).\n' "$FAILURES"
    exit 1
  fi

  load_env_file "$ENV_FILE"

  require_env QWEN_API_KEY QWEN_BASE_URL QWEN_MODEL || FAILURES=$((FAILURES + $?))

  if command -v curl >/dev/null 2>&1; then
    pass "curl is available"
  else
    fail "curl is not available"
  fi

  if [ -n "${QWEN_API_KEY:-}" ] && [ -n "${QWEN_BASE_URL:-}" ] && [ -n "${QWEN_MODEL:-}" ] && command -v curl >/dev/null 2>&1; then
    check_models
    check_chat_completion
  fi

  printf '\nQwen provider summary:\n'
  printf '  provider: qwen/%s\n' "${QWEN_MODEL:-unset}"
  printf '  base URL configured: %s\n' "$([ -n "${QWEN_BASE_URL:-}" ] && printf yes || printf no)"
  printf '  secrets printed: no\n'

  if [ "$FAILURES" -gt 0 ]; then
    printf '\nQwen tests completed with %d failure(s).\n' "$FAILURES"
    exit 1
  fi

  printf '\nQwen tests completed successfully.\n'
}

main "$@"
