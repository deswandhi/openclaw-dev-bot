#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TARGET="$BACKUP_DIR/yuna-openclaw-config-$STAMP.tar.gz"

main() {
  cd "$ROOT_DIR"
  mkdir -p "$BACKUP_DIR"
  chmod 700 "$BACKUP_DIR" || true

  local files=()
  [ -f openclaw.json ] && files+=("openclaw.json")
  [ -f .env ] && files+=(".env")
  [ -f .env.example ] && files+=(".env.example")
  [ -f README.md ] && files+=("README.md")

  if [ "${#files[@]}" -eq 0 ]; then
    printf 'No config files found to back up.\n' >&2
    exit 1
  fi

  tar -czf "$TARGET" "${files[@]}"
  chmod 600 "$TARGET" || true
  printf 'Created backup: %s\n' "$TARGET"
}

main "$@"
