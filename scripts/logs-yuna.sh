#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="yuna-openclaw.service"
LOG_FILE="$ROOT_DIR/logs/yuna-openclaw.log"

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  exec journalctl --user -u "$SERVICE_NAME" -f --no-pager
fi

if [ -f "$LOG_FILE" ]; then
  exec tail -f "$LOG_FILE"
fi

printf 'No fallback log file exists yet: %s\n' "$LOG_FILE"
exit 1
