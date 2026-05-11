#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="yuna-openclaw.service"
SERVICE_SOURCE="$ROOT_DIR/systemd/$SERVICE_NAME"
USER_SERVICE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
PID_DIR="$ROOT_DIR/.run"
LOG_DIR="$ROOT_DIR/logs"
PID_FILE="$PID_DIR/yuna-openclaw.pid"
LOG_FILE="$LOG_DIR/yuna-openclaw.log"

systemd_available() {
  command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1
}

fallback_running() {
  [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" >/dev/null 2>&1
}

start_fallback() {
  mkdir -p "$PID_DIR" "$LOG_DIR"
  chmod 700 "$PID_DIR" "$LOG_DIR" || true

  if fallback_running; then
    printf 'Yuna fallback process is already running with PID %s.\n' "$(cat "$PID_FILE")"
    return 0
  fi

  nohup "$ROOT_DIR/scripts/start-yuna.sh" >>"$LOG_FILE" 2>&1 &
  printf '%s\n' "$!" > "$PID_FILE"
  chmod 600 "$PID_FILE" || true
  printf 'Started Yuna in fallback background mode with PID %s.\n' "$(cat "$PID_FILE")"
  printf 'Logs: %s\n' "$LOG_FILE"
  printf 'Auto-start after reboot requires user systemd. See README for loginctl enable-linger.\n'
}

main() {
  cd "$ROOT_DIR"

  "$ROOT_DIR/scripts/start-yuna.sh" --check

  if systemd_available; then
    mkdir -p "$USER_SERVICE_DIR"
    install -m 0644 "$SERVICE_SOURCE" "$USER_SERVICE_DIR/$SERVICE_NAME"
    systemctl --user daemon-reload
    systemctl --user enable --now "$SERVICE_NAME"
    systemctl --user --no-pager --full status "$SERVICE_NAME" || true
    printf 'Yuna is managed by user systemd service: %s\n' "$SERVICE_NAME"
    printf 'For reboot persistence, run once if needed: sudo loginctl enable-linger %s\n' "$USER"
  else
    printf 'User systemd is unavailable in this shell; using fallback background mode.\n'
    start_fallback
  fi
}

main "$@"
