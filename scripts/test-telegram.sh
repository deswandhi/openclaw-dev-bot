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

main() {
  cd "$ROOT_DIR"

  if [ -f "$ENV_FILE" ]; then
    pass ".env exists"
  else
    fail ".env is missing"
    exit 1
  fi

  load_env_file "$ENV_FILE"
  require_env TELEGRAM_BOT_TOKEN || FAILURES=$((FAILURES + $?))

  if ! command -v curl >/dev/null 2>&1; then
    fail "curl is not available"
  fi

  if [ "$FAILURES" -eq 0 ]; then
    node - "$TELEGRAM_BOT_TOKEN" <<'NODE'
const token = process.argv[2];
const base = `https://api.telegram.org/bot${token}`;
async function main() {
  const getMe = await fetch(`${base}/getMe`);
  const me = await getMe.json();
  if (!me.ok) {
    console.log(`[fail] Telegram getMe failed: ${me.description || getMe.status}`);
    process.exit(1);
  }
  console.log(`[ok] Telegram getMe succeeded for @${me.result.username}`);
  const webhook = await fetch(`${base}/getWebhookInfo`).then((r) => r.json());
  if (webhook.ok) {
    const mode = webhook.result.url ? 'webhook' : 'polling';
    console.log(`[ok] Telegram delivery mode: ${mode}`);
    if (webhook.result.pending_update_count !== undefined) {
      console.log(`[ok] pending updates: ${webhook.result.pending_update_count}`);
    }
  } else {
    console.log('[fail] Telegram getWebhookInfo failed');
    process.exit(1);
  }
  const updates = await fetch(`${base}/getUpdates?limit=1&timeout=0`).then((r) => r.json());
  if (updates.ok) {
    console.log(`[ok] Telegram getUpdates reachable; visible updates: ${updates.result.length}`);
  } else {
    console.log(`[fail] Telegram getUpdates failed: ${updates.description || 'unknown error'}`);
    process.exit(1);
  }
}
main().catch((error) => {
  console.log(`[fail] Telegram test failed: ${error.message}`);
  process.exit(1);
});
NODE
  fi

  printf 'secrets printed: no\n'
}

main "$@"
