#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="yuna-openclaw.service"

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user restart "$SERVICE_NAME"
  systemctl --user --no-pager --full status "$SERVICE_NAME" || true
  exit 0
fi

"$ROOT_DIR/scripts/stop-yuna.sh" || true
"$ROOT_DIR/scripts/start-background.sh"
