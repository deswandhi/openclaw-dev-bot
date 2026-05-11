#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="yuna-openclaw.service"
PID_FILE="$ROOT_DIR/.run/yuna-openclaw.pid"

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user --no-pager --full status "$SERVICE_NAME"
  exit $?
fi

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
  printf 'Yuna fallback process is running with PID %s.\n' "$(cat "$PID_FILE")"
else
  printf 'Yuna is not running under user systemd or fallback PID mode.\n'
  exit 3
fi
