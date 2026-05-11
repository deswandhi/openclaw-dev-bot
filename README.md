# Yuna OpenClaw Assistant

Yuna is an OpenClaw assistant for daily Data & AI product work at Indosat. The assistant runs through OpenClaw Gateway, uses Telegram as the production channel, keeps WhatsApp ready for future activation, and uses Alibaba Qwen as the only LLM provider.

Yuna's style is calm, thoughtful, supportive, professional, concise, and reliable. Her scope includes proposal drafting, meeting prep, technical architecture, cloud/GPU/data platform analysis, reminders, productivity support, vendor and partner analysis, and executive-ready writing.

## Architecture

```text
Telegram user
    |
    v
Telegram Bot API
    |
    v
OpenClaw Gateway / Yuna
    |
    v
Alibaba Qwen via DashScope OpenAI-compatible endpoint
    |
    v
Telegram reply
```

Request flow: Telegram -> OpenClaw/Yuna -> Alibaba Qwen -> Telegram reply.

Key files:

- `openclaw.json`: OpenClaw gateway, Telegram, WhatsApp readiness, Yuna persona, and Qwen provider config.
- `.env.example`: placeholder-only environment template.
- `scripts/start-yuna.sh`: validates env, prints a masked startup summary, and starts OpenClaw.
- `scripts/test-openclaw.sh`: validates OpenClaw, config syntax, Codex CLI availability, and Telegram env loading.
- `scripts/test-qwen.sh`: validates Qwen env and calls Qwen `/models` plus `/chat/completions`.
- `scripts/test-provider-routing.sh`: compatibility wrapper for `scripts/test-qwen.sh`.
- `scripts/test-telegram.sh`: validates Telegram token with `getMe`, checks delivery mode, and checks `getUpdates` reachability.
- `scripts/backup-config.sh`: backs up local config files.

## Environment

Create local `.env` from the template:

```bash
cp .env.example .env
chmod 600 .env
```

Required variables:

```bash
# Primary Provider - Alibaba Qwen
QWEN_API_KEY=
QWEN_BASE_URL=https://dashscope-intl.aliyuncs.com/compatible-mode/v1
QWEN_MODEL=qwen-max

# Agent
OPENCLAW_AGENT_NAME=Yuna
OPENCLAW_AGENT_RUNTIME=

# Telegram
TELEGRAM_BOT_TOKEN=
```

`OPENCLAW_AGENT_RUNTIME` is intentionally blank. Yuna uses OpenClaw's default agent runtime so Telegram messages route to the configured Qwen model. Do not set this to `codex` for the Telegram bot unless the selected model is a `codex/*` model; forcing Codex with `qwen/*` can block normal Telegram replies because the Codex harness is designed for Codex model execution.

## Qwen-Only Model Config

`openclaw.json` defines only Alibaba Qwen:

```json
"models": {
  "mode": "merge",
  "providers": {
    "qwen": {
      "baseUrl": "${QWEN_BASE_URL}",
      "apiKey": "${QWEN_API_KEY}",
      "auth": "api-key",
      "api": "openai-completions"
    }
  }
}
```

The active Yuna model is:

```json
"model": "qwen/${QWEN_MODEL}"
```

There is no fallback provider and no Gemini configuration.

## Telegram Setup

1. Create the bot with `@BotFather`.
2. Put the BotFather token in `.env` as `TELEGRAM_BOT_TOKEN`.
3. Start Yuna:

   ```bash
   ./scripts/start-yuna.sh
   ```

4. Send a direct message to the bot. If OpenClaw creates a pairing request, approve it:

   ```bash
   openclaw pairing list telegram
   openclaw pairing approve telegram <CODE>
   ```

For groups, the config requires mentioning the bot. For DMs, no mention is required after pairing/approval policy is satisfied.

## WhatsApp Readiness

WhatsApp remains configured but disabled. When ready:

```bash
openclaw plugins install @openclaw/whatsapp
openclaw channels login --channel whatsapp --account work
```

After QR pairing, set `channels.whatsapp.enabled` to `true` in `openclaw.json`, set allowlists for real numbers/groups, and restart Yuna.

## Codex Notes

The Codex plugin configuration is preserved for future OpenClaw/Codex workflows, but Yuna's Telegram runtime is not forced to Codex. This is deliberate: Qwen is a normal OpenAI-compatible chat model, while the Codex harness is for Codex runtime/model execution. Keeping the default OpenClaw runtime lets Telegram inbound messages route to Qwen and return replies.

Codex can still be checked manually:

```text
/codex status
/codex models
```

## Tests

Run:

```bash
OPENCLAW_CONFIG_PATH=$PWD/openclaw.json openclaw config validate
./scripts/test-openclaw.sh
./scripts/test-qwen.sh
./scripts/test-telegram.sh
```

Expected high-level output:

```text
Config valid
Smoke tests completed successfully.
Qwen tests completed successfully.
Telegram getMe succeeded for @<bot_username>
```

None of the scripts print API keys or Telegram tokens.

## Start Yuna

```bash
cd ~/openclaw-dev-bot
./scripts/start-yuna.sh
```

Expected startup summary:

```text
Starting Yuna OpenClaw Gateway
  active provider: qwen/qwen-max
  fallback provider: none
  agent runtime: OpenClaw default
  telegram: enabled
  codex: enabled
  secrets printed: no
```

## Readiness Checklist

- Telegram bot token is present in `.env`.
- `./scripts/test-telegram.sh` passes.
- Qwen key, base URL, and model are present in `.env`.
- `./scripts/test-qwen.sh` passes.
- OpenClaw config validates.
- `./scripts/start-yuna.sh` starts and stays running.
- Send: `halo Yuna, jawab singkat: sistem sudah aktif`.
- Yuna replies in Telegram using Qwen only.

## Security

- Keep `.env` mode `600`.
- Never commit `.env`, API keys, Telegram tokens, private keys, auth files, or WhatsApp session credentials.
- Do not echo full `.env` contents into logs or support tickets.
- Scripts only report whether secrets are set; they do not print values.
- Keep WhatsApp disabled until QR pairing is intentional.

## Troubleshooting

### Bot Receives Message But Does Not Reply

Check layers in this order:

```bash
./scripts/test-telegram.sh
./scripts/test-qwen.sh
OPENCLAW_CONFIG_PATH=$PWD/openclaw.json openclaw config validate
./scripts/start-yuna.sh
```

Then send a new DM and watch the OpenClaw foreground logs. If a pairing request appears, approve it with `openclaw pairing approve telegram <CODE>`.

### Invalid Telegram Token

`scripts/test-telegram.sh` will fail at `getMe`. Re-copy the token from `@BotFather` into `.env` and restart Yuna.

### Polling vs Webhook Issue

`scripts/test-telegram.sh` prints Telegram delivery mode from `getWebhookInfo`. If webhook mode is set unexpectedly for this server, clear the webhook from BotFather/API or run OpenClaw in the deployment mode that owns the webhook. For local/server foreground operation, polling is usually simpler.

### Qwen 401 Or 403

The Qwen endpoint is reachable but the key is invalid, expired, lacks model permission, or is not enabled for the international DashScope endpoint. Update `QWEN_API_KEY` in `.env`.

### Qwen DNS Or Network Issue

If `scripts/test-qwen.sh` reports failure before HTTP response, check DNS and outbound HTTPS:

```bash
dig dashscope-intl.aliyuncs.com
curl -I https://dashscope-intl.aliyuncs.com
```

### Runtime/Provider Mismatch

If logs mention Codex runtime or model incompatibility, confirm:

```bash
grep '^OPENCLAW_AGENT_RUNTIME=' .env
```

It should be empty. The active model should be `qwen/${QWEN_MODEL}`, and `openclaw.json` should not force `agentRuntime.id` for Yuna.

### WhatsApp Future Activation

WhatsApp is not part of the Telegram response path. Keep it disabled until QR pairing is complete.
