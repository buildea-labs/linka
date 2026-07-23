#!/usr/bin/env bash
# Objetivo: fluxo canonico de handoff para board + notificacoes.
# Pre-requisitos: gh autenticado; labels de status/agent; webhooks opcionais.
# Execucao: scripts/tooling/agent-handoff.sh <agente> <evento> <issue#> "<mensagem>" [--para <outro>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT="${1:-}"
EVENT="${2:-}"
ISSUE="${3:-}"
MSG="${4:-}"
shift 4 || true
TARGET_FLAG=""
TARGET_AGENT=""
if [ "${1:-}" = "--para" ]; then
  TARGET_FLAG="--para $2"
  TARGET_AGENT="$2"
fi

if [ -z "$AGENT" ] || [ -z "$EVENT" ] || [ -z "$ISSUE" ] || [ -z "$MSG" ]; then
  echo "uso: $0 <agente> <evento> <issue#> \"<msg>\" [--para <outro>]" >&2
  echo "eventos: start|handoff|review|docs|done|block|refine|ready" >&2
  exit 2
fi

NOTIFY_TYPE="info"
COL=""
case "$EVENT" in
  start)   COL="in-progress"; NOTIFY_TYPE="progress" ;;
  handoff) COL="in-progress"; NOTIFY_TYPE="success" ;;
  review)  COL="review";      NOTIFY_TYPE="success" ;;
  docs)    COL="docs";        NOTIFY_TYPE="info" ;;
  done)    COL="done";        NOTIFY_TYPE="success" ;;
  block)   COL="block";       NOTIFY_TYPE="warning" ;;
  refine)  COL="triagem";     NOTIFY_TYPE="info" ;;
  ready)   COL="ready";       NOTIFY_TYPE="info" ;;
  *) echo "evento invalido: $EVENT" >&2; exit 2 ;;
esac

bash "$SCRIPT_DIR/issue-move.sh" "$ISSUE" "$COL" "$AGENT"

FULL_MSG="#$ISSUE — $MSG"$'\n'"https://github.com/gmmattey/linka-webapp/issues/$ISSUE"
gh issue comment "$ISSUE" --repo "${REPO:-gmmattey/linka-webapp}" --body "$FULL_MSG" >/dev/null
bash "$SCRIPT_DIR/notify.sh" "$AGENT" "$FULL_MSG" "$NOTIFY_TYPE" $TARGET_FLAG

echo "[agent-handoff] evento '$EVENT' aplicado na issue #$ISSUE"
