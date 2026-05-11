#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
IMAGE_FILE="$ROOT_DIR/public/yuna.png"
FAILURES=0
DRY_RUN="${DRY_RUN:-0}"

# shellcheck source=scripts/lib/env.sh
. "$ROOT_DIR/scripts/lib/env.sh"

fail() {
  printf '[fail] %s\n' "$*"
  FAILURES=$((FAILURES + 1))
}

pass() {
  printf '[ok] %s\n' "$*"
}

main() {
  cd "$ROOT_DIR"

  [ -f "$ENV_FILE" ] && pass ".env exists" || fail ".env is missing"
  [ -f "$IMAGE_FILE" ] && pass "public/yuna.png exists" || fail "public/yuna.png is missing"

  load_env_file "$ENV_FILE"
  require_env TELEGRAM_BOT_TOKEN || FAILURES=$((FAILURES + $?))

  if ! command -v curl >/dev/null 2>&1; then
    fail "curl is not available"
  fi

  if [ "$FAILURES" -gt 0 ]; then
    printf 'Telegram profile update checks failed. Secrets printed: no\n'
    exit 1
  fi

  if [ "$DRY_RUN" = "1" ]; then
    printf 'Dry run only. Would call Telegram setMyProfilePhoto with public/yuna.png. Secrets printed: no\n'
    exit 0
  fi

  local response ok description
  response="$(mktemp)"
  curl -sS -m 30 \
    -F 'photo={"type":"static","photo":"attach://profile_photo"};type=application/json' \
    -F "profile_photo=@${IMAGE_FILE}" \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/setMyProfilePhoto" \
    -o "$response"

  ok="$(node -e 'const fs=require("fs"); const r=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); console.log(r.ok ? "yes" : "no")' "$response" 2>/dev/null || printf no)"
  if [ "$ok" = "yes" ]; then
    rm -f "$response"
    pass "Telegram bot profile photo updated via setMyProfilePhoto"
    printf 'Secrets printed: no\n'
    exit 0
  fi

  description="$(node -e 'const fs=require("fs"); const r=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); console.log(r.description || "unknown Telegram error")' "$response" 2>/dev/null || printf 'unknown Telegram error')"
  rm -f "$response"

  printf '[warn] Telegram API did not update the bot photo automatically: %s\n' "$description"
  printf 'Manual fallback: open @BotFather, run /setuserpic, choose Yuna, and upload public/yuna.png.\n'
  printf 'Secrets printed: no\n'
}

main "$@"
