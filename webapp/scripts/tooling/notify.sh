#!/usr/bin/env bash
# Objetivo: enviar notificacoes do fluxo de handoff para Discord e Slack.
# Pre-requisitos: variaveis DISCORD_WEBHOOK_URL e/ou SLACK_WEBHOOK_URL (opcionais).
# Execucao: scripts/tooling/notify.sh <agente> "<mensagem>" [tipo] [--para <agente>]

set -euo pipefail

AGENT="${1:-}"
MESSAGE="${2:-}"
TYPE="${3:-info}"
TARGET=""

if [ "${4:-}" = "--para" ]; then
  TARGET="${5:-}"
fi

if [ -z "$AGENT" ] || [ -z "$MESSAGE" ]; then
  echo "uso: $0 <agente> \"<mensagem>\" [tipo] [--para <outroAgente>]" >&2
  exit 2
fi

TITLE="Linka WebApp :: ${AGENT}"
if [ -n "$TARGET" ]; then
  TITLE="${TITLE} -> ${TARGET}"
fi

COLOR="3066993" # info
case "$TYPE" in
  success) COLOR="5763719" ;;
  warning) COLOR="15158332" ;;
  progress) COLOR="3447003" ;;
esac

if [ -n "${DISCORD_WEBHOOK_URL:-}" ]; then
  curl -sS -X POST "$DISCORD_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$(printf '{"embeds":[{"title":"%s","description":"%s","color":%s}]}' "$TITLE" "$(printf '%s' "$MESSAGE" | sed 's/"/\\"/g')" "$COLOR")" \
    >/dev/null || echo "[notify] falha ao enviar Discord" >&2
fi

if [ -n "${SLACK_WEBHOOK_URL:-}" ]; then
  curl -sS -X POST "$SLACK_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$(printf '{"text":"*%s*\n%s"}' "$TITLE" "$(printf '%s' "$MESSAGE" | sed 's/"/\\"/g')")" \
    >/dev/null || echo "[notify] falha ao enviar Slack" >&2
fi

echo "[notify] concluido (Discord/Slack opcionais)."
