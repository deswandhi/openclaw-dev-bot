# Yuna OpenClaw Assistant

## Project Overview

Yuna is a production-oriented OpenClaw Telegram assistant for daily Data & AI product work at Indosat. The bot receives messages through Telegram, routes them through OpenClaw Gateway, uses Alibaba Qwen as the only LLM provider, and replies back in Telegram.

## Who Is Yuna

Yuna is inspired by Final Fantasy X: calm, thoughtful, supportive, professional, concise, and reliable. In this project, Yuna is configured as a practical work assistant, not a roleplay bot. She helps organize thinking, draft materials, prepare meetings, analyze architecture options, and keep daily execution moving.

## Target Use Case

Yuna supports a Data & AI Product Expert at Indosat with:

- Proposal and executive-summary drafting.
- Meeting preparation and follow-up.
- AI/data platform architecture review.
- Cloud, GPU, and data infrastructure analysis.
- Product planning, roadmap thinking, and partner/vendor comparison.
- Productivity support, reminders, and concise decision memos.

## Architecture

```text
User on Telegram
    -> Telegram Bot API
    -> OpenClaw Gateway
    -> Yuna Agent
    -> Alibaba Qwen API
    -> Yuna response
    -> Telegram Bot reply
```

There is no Gemini fallback and no OpenAI provider requirement. Qwen is the only active LLM provider.

## Tech Stack

- Ubuntu 26.04 LTS
- OpenClaw Gateway
- Telegram Bot API
- Alibaba Qwen through DashScope OpenAI-compatible API
- Bash operational scripts
- user-level systemd service for background operation
- Static HTML documentation in `docs/index.html`

## Repository Structure

```text
.
├── .env.example
├── .gitignore
├── README.md
├── docs/
│   ├── assets/yuna.png
│   └── index.html
├── openclaw.json
├── public/yuna.png
├── scripts/
│   ├── backup-config.sh
│   ├── install.sh
│   ├── lib/env.sh
│   ├── logs-yuna.sh
│   ├── restart-yuna.sh
│   ├── start-background.sh
│   ├── start-yuna.sh
│   ├── status-yuna.sh
│   ├── stop-yuna.sh
│   ├── test-openclaw.sh
│   ├── test-provider-routing.sh
│   ├── test-qwen.sh
│   ├── test-telegram.sh
│   └── update-telegram-profile.sh
└── systemd/yuna-openclaw.service
```

## Prerequisites

- Node.js 20 or newer.
- OpenClaw CLI on `PATH`.
- `curl`, `bash`, and `systemctl`.
- Alibaba Qwen API key.
- Telegram bot token from `@BotFather`.
- Optional: `sudo loginctl enable-linger ubuntu` for user-service auto-start after reboot.

## Environment Variables

Create `.env` from `.env.example`:

```bash
cp .env.example .env
chmod 600 .env
```

Required values:

```bash
QWEN_API_KEY=
QWEN_BASE_URL=https://dashscope-intl.aliyuncs.com/compatible-mode/v1
QWEN_MODEL=qwen-max
OPENCLAW_AGENT_NAME=Yuna
OPENCLAW_AGENT_RUNTIME=
OPENCLAW_GATEWAY_TOKEN=
TELEGRAM_BOT_TOKEN=
```

`OPENCLAW_AGENT_RUNTIME` is intentionally blank. Yuna uses OpenClaw's default runtime so Telegram messages route to `qwen/${QWEN_MODEL}`. Do not set it to `codex` for the Telegram bot unless you switch the model to a `codex/*` model.

## Installation

```bash
cd ~/openclaw-dev-bot
./scripts/install.sh
chmod 600 .env
```

Fill in `.env` with local secrets. Never commit `.env`.

## Configuration

Main configuration is [openclaw.json](/home/ubuntu/openclaw-dev-bot/openclaw.json). It contains:

- Qwen-only model provider.
- Telegram channel enabled.
- WhatsApp disabled but ready for future QR pairing.
- Yuna system prompt/persona.
- Gateway auth token read from `.env`, not committed config.
- No forced Codex runtime; Yuna Telegram turns use OpenClaw's default runtime with Qwen.

Validate config:

```bash
OPENCLAW_CONFIG_PATH=$PWD/openclaw.json openclaw config validate
```

## Qwen Provider Setup

Qwen is configured as an OpenAI-compatible provider:

```json
"qwen": {
  "baseUrl": "${QWEN_BASE_URL}",
  "apiKey": "${QWEN_API_KEY}",
  "auth": "api-key",
  "api": "openai-completions"
}
```

Test Qwen:

```bash
./scripts/test-qwen.sh
```

The test calls `/models` and `/chat/completions` without printing secrets.

## Telegram BotFather Setup

1. Open `@BotFather`.
2. Create or select the Yuna bot.
3. Copy the token into `.env` as `TELEGRAM_BOT_TOKEN`.
4. Validate:

   ```bash
   ./scripts/test-telegram.sh
   ```

## Telegram Pairing Approval

The config uses `dmPolicy: "pairing"`. On first contact, approve the pairing:

```bash
openclaw pairing list telegram
openclaw pairing approve telegram <CODE>
```

For groups, mention Yuna because group messages require mention by default.

## Running Foreground

Use foreground mode while debugging:

```bash
./scripts/start-yuna.sh
```

This prints a masked startup summary and then runs OpenClaw Gateway.

## Running Background

Preferred production mode is user-level systemd:

```bash
./scripts/start-background.sh
```

If `systemctl --user` is unavailable in the current shell, the script falls back to a local PID/log mode under `.run/` and `logs/`. That fallback is useful for constrained terminals, but systemd is preferred for production.

## Auto-Start After Reboot

For user-level systemd services, enable lingering once:

```bash
sudo loginctl enable-linger ubuntu
```

Then run:

```bash
./scripts/start-background.sh
```

The service file is [systemd/yuna-openclaw.service](/home/ubuntu/openclaw-dev-bot/systemd/yuna-openclaw.service).

## Update Telegram Profile Image

The image source is [public/yuna.png](/home/ubuntu/openclaw-dev-bot/public/yuna.png).

Try automatic update:

```bash
./scripts/update-telegram-profile.sh
```

Telegram Bot API supports `setMyProfilePhoto`, but static profile photos are documented as JPG uploads. If Telegram rejects `public/yuna.png`, use the manual BotFather fallback:

```text
/setuserpic
choose Yuna bot
upload public/yuna.png
```

Dry run:

```bash
DRY_RUN=1 ./scripts/update-telegram-profile.sh
```

## Functionality Testing

Run the full smoke set:

```bash
OPENCLAW_CONFIG_PATH=$PWD/openclaw.json openclaw config validate
./scripts/test-openclaw.sh
./scripts/test-qwen.sh
./scripts/test-telegram.sh
./scripts/status-yuna.sh
```

Send this in Telegram:

```text
halo Yuna, jawab singkat: sistem sudah aktif.
```

Expected behavior: Yuna replies through Telegram using Alibaba Qwen only.

## Smoke Test Checklist

- `.env` exists and is mode `600`.
- `TELEGRAM_BOT_TOKEN` is present.
- `QWEN_API_KEY`, `QWEN_BASE_URL`, and `QWEN_MODEL` are present.
- OpenClaw config validates.
- Qwen `/models` succeeds.
- Qwen chat completion succeeds.
- Telegram `getMe` succeeds.
- OpenClaw service is running.
- Telegram pairing is approved.
- A real Telegram message gets a reply.

## Operations Guide

Start:

```bash
./scripts/start-background.sh
```

Stop:

```bash
./scripts/stop-yuna.sh
```

Restart:

```bash
./scripts/restart-yuna.sh
```

Status:

```bash
./scripts/status-yuna.sh
```

Logs:

```bash
./scripts/logs-yuna.sh
```

Back up config:

```bash
./scripts/backup-config.sh
```

Update process:

```bash
git pull
OPENCLAW_CONFIG_PATH=$PWD/openclaw.json openclaw config validate
./scripts/test-qwen.sh
./scripts/test-telegram.sh
./scripts/restart-yuna.sh
```

## Logs And Troubleshooting

### Bot Receives Message But No Reply

Check:

```bash
./scripts/test-telegram.sh
./scripts/test-qwen.sh
./scripts/logs-yuna.sh
```

Common causes:

- Pairing request is pending.
- `OPENCLAW_AGENT_RUNTIME` was set to `codex`.
- Qwen key is invalid.
- Service is not running.
- Telegram webhook is configured elsewhere while this server expects polling.

### Invalid Telegram Token

`scripts/test-telegram.sh` fails at `getMe`. Re-copy the token from `@BotFather`.

### Qwen 401/403

The key is invalid, expired, lacks model permission, or is not enabled for the configured DashScope endpoint.

### Qwen DNS/Network Issue

Check outbound access:

```bash
dig dashscope-intl.aliyuncs.com
curl -I https://dashscope-intl.aliyuncs.com
```

### Runtime/Provider Mismatch

Confirm:

```bash
grep '^OPENCLAW_AGENT_RUNTIME=' .env
```

It should be empty for Qwen-only Telegram operation.

## Security Best Practices

- Keep `.env` ignored and mode `600`.
- Never print API keys, Telegram tokens, or gateway auth tokens.
- Do not commit `.env`, logs, runtime PID files, WhatsApp sessions, private keys, or backups containing secrets.
- Keep Telegram `dmPolicy` as `pairing`.
- Add `commands.ownerAllowFrom` only after collecting your stable Telegram sender ID.
- Keep owner/elevated commands disabled unless needed.
- Review `git diff` before committing.

Owner allowlist best practice:

```json
"commands": {
  "ownerAllowFrom": ["telegram:<your_numeric_telegram_user_id>"],
  "ownerDisplay": "hash"
}
```

Only add this after verifying the exact sender ID from OpenClaw pairing/logs.

## Backup And Recovery

Create a backup:

```bash
./scripts/backup-config.sh
```

Recovery:

1. Restore `openclaw.json`.
2. Restore local `.env` from a secure password manager, not from git.
3. Run tests.
4. Restart Yuna.

## Git Hygiene

- `.env` and logs are ignored.
- Runtime state under `.run/` is ignored.
- Backup files are ignored.
- Run `git diff --check` before commit.
- Do not commit generated files containing secrets.

## WhatsApp Readiness

WhatsApp is intentionally disabled. Future activation:

```bash
openclaw plugins install @openclaw/whatsapp
openclaw channels login --channel whatsapp --account work
```

Then set `channels.whatsapp.enabled` to `true`, configure allowlists, and restart.

## Future Gmail, Calendar, And RAG Readiness

Roadmap items:

- Gmail triage connector for action extraction and reply drafting.
- Calendar briefing and meeting prep.
- RAG over Indosat-safe product notes, proposals, and architecture documents.
- Approval-gated tools for reminders, follow-ups, and draft publishing.
- Dedicated audit logging with redaction.

## Roadmap

- Add owner allowlist after Telegram user ID verification.
- Add service health checks and alerting.
- Add deployment runbook for OpenClaw upgrades.
- Add WhatsApp after dedicated number/QR pairing.
- Add document retrieval with explicit data boundaries.

## FAQ

### Why Qwen Only?

The current requirement is a single Alibaba Qwen provider with no fallback. This keeps behavior predictable and simplifies troubleshooting.

### Why Is Codex Not The Active Runtime?

Telegram chat turns use OpenClaw's default runtime because the active model is `qwen/${QWEN_MODEL}`, not a `codex/*` model. The stale Codex plugin entry was removed so production startup logs stay clean.

### Can The Bot Photo Be Updated Automatically?

The script uses Telegram Bot API `setMyProfilePhoto`. If Telegram rejects the PNG upload, use BotFather `/setuserpic`.

### Does The HTML Documentation Need A Server?

No. Open [docs/index.html](/home/ubuntu/openclaw-dev-bot/docs/index.html) directly in a browser.
