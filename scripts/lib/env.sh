#!/usr/bin/env bash

load_env_file() {
  local env_file="$1"
  local line key value current

  [ -f "$env_file" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
      ''|'#'*) continue ;;
    esac

    key="${line%%=*}"
    value="${line#*=}"

    case "$key" in
      ''|*[!A-Za-z0-9_]*|[0-9]*) continue ;;
    esac

    if [ "${value#\"}" != "$value" ] && [ "${value%\"}" != "$value" ]; then
      value="${value#\"}"
      value="${value%\"}"
    elif [ "${value#\'}" != "$value" ] && [ "${value%\'}" != "$value" ]; then
      value="${value#\'}"
      value="${value%\'}"
    fi

    current="${!key-}"
    if [ -z "$current" ] && [ -n "$value" ]; then
      export "$key=$value"
    fi
  done < "$env_file"
}

require_env() {
  local missing=0
  local name

  for name in "$@"; do
    if [ -z "${!name-}" ]; then
      printf '[fail] %s is not set\n' "$name"
      missing=$((missing + 1))
    else
      printf '[ok] %s is set\n' "$name"
    fi
  done

  if [ "$missing" -gt 125 ]; then
    return 125
  fi

  return "$missing"
}

bool_status() {
  case "${1:-}" in
    true|1|yes|enabled) printf 'enabled' ;;
    *) printf 'disabled' ;;
  esac
}
