#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() {
  printf '[install] %s\n' "$*"
}

warn() {
  printf '[install] warning: %s\n' "$*" >&2
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

node_major() {
  node -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || printf '0'
}

install_openclaw() {
  if need_cmd openclaw; then
    info "OpenClaw CLI found: $(openclaw --version 2>/dev/null || printf 'version unavailable')"
    return
  fi

  if ! need_cmd npm; then
    warn "npm is not available. Install Node.js 20+ first, then rerun this script."
    return 1
  fi

  info "Installing OpenClaw CLI with npm."
  npm install -g openclaw@latest
}

main() {
  cd "$ROOT_DIR"

  info "Project root: $ROOT_DIR"

  if need_cmd node; then
    local major
    major="$(node_major)"
    info "Node.js found: $(node -v)"
    if [ "$major" -lt 20 ]; then
      warn "Node.js 20+ is recommended; found major version $major."
    fi
  else
    warn "Node.js is not installed. Install Node.js 20+ before running OpenClaw Gateway."
  fi

  if need_cmd npm; then
    info "npm found: $(npm -v)"
  else
    warn "npm is not installed."
  fi

  install_openclaw

  if need_cmd codex; then
    info "Codex CLI found: $(codex --version 2>/dev/null || printf 'version unavailable')"
  else
    warn "Codex CLI is not on PATH. Install and authenticate Codex before using the Codex harness."
  fi

  if [ ! -f .env ]; then
    cp .env.example .env
    chmod 600 .env
    info "Created local .env from .env.example with mode 600. Fill in secrets before starting."
  else
    chmod 600 .env || true
    info ".env already exists; permissions normalized where possible."
  fi

  info "Run ./scripts/test-openclaw.sh next."
}

main "$@"
