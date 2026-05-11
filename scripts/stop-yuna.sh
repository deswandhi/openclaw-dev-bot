#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="yuna-openclaw.service"
PID_FILE="$ROOT_DIR/.run/yuna-openclaw.pid"

if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  systemctl --user stop "$SERVICE_NAME"
  printf 'Stopped %s via user systemd.\n' "$SERVICE_NAME"
  exit 0
fi

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1; then
  kill "$(cat "$PID_FILE")"
  rm -f "$PID_FILE"
  printf 'Stopped Yuna fallback process.\n'
else
  printf 'Yuna is not running in fallback mode.\n'
fi
