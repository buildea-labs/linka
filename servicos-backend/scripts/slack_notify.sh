#!/usr/bin/env bash
# slack_notify.sh — Notificações do squad Linka para o Slack
#
# Uso:
#   bash scripts/slack_notify.sh <agente> <mensagem> [status] [--para <agente_destino>]
#
# Agentes: camilo | gema | lia | marcelo | renan | claudete | sistema
# Status:  info (padrão) | success | warning | error | progress
#
# Exemplos:
#   bash scripts/slack_notify.sh camilo "Implementando TASK-01..." progress
#   bash scripts/slack_notify.sh gema "Audit concluído — sem blockers" success
#   bash scripts/slack_notify.sh camilo "TASK-03 entregue, pode revisar" success --para gema

set -euo pipefail

AGENTE="${1:-sistema}"
MENSAGEM="${2:-}"
STATUS="${3:-info}"
PARA=""

# Parse --para flag
shift 3 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --para) PARA="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$MENSAGEM" ]]; then
  echo "Uso: $0 <agente> <mensagem> [status] [--para <agente>]" >&2
  exit 1
fi

# Carregar .env se existir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$(dirname "$SCRIPT_DIR")/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

WEBHOOK_URL="${SLACK_WEBHOOK_LINKA:-}"
if [[ -z "$WEBHOOK_URL" ]]; then
  echo "SLACK_WEBHOOK_LINKA não definido em .env" >&2
  exit 1
fi

python3 - "$AGENTE" "$MENSAGEM" "$STATUS" "${PARA}" "$WEBHOOK_URL" <<'PYEOF'
import sys
import io
import json
import random
import urllib.request
import urllib.error
from datetime import datetime, timezone

# Forçar UTF-8 no stdout (Windows cp1252 não suporta caracteres especiais)
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

agente   = sys.argv[1].lower()
mensagem = sys.argv[2]
status   = sys.argv[3].lower()
para     = sys.argv[4].lower() if sys.argv[4] else ""
webhook  = sys.argv[5]

# ── Identidade por agente ─────────────────────────────────────────────────────
AGENTES = {
    "camilo": {
        "emoji": "🤖",
        "color": "#E74C3C",
    },
    "gema": {
        "emoji": "🔍",
        "color": "#9B59B6",
    },
    "lia": {
        "emoji": "🎨",
        "color": "#3498DB",
    },
    "marcelo": {
        "emoji": "🔎",
        "color": "#E67E22",
    },
    "renan": {
        "emoji": "🌐",
        "color": "#27AE60",
    },
    "claudete": {
        "emoji": "📋",
        "color": "#2980B9",
    },
}

STATUS_EMOJI = {
    "success":  "✅",
    "warning":  "⚠️",
    "error":    "❌",
    "progress": "🔄",
    "info":     "ℹ️",
}

ag = AGENTES.get(agente, {"emoji": "⚙️", "color": "#95A5A6"})
st_emoji = STATUS_EMOJI.get(status, "ℹ️")

# Construir mensagem Slack
destino = f" → {para.upper()}" if para and para in AGENTES else ""
text = f"{st_emoji} **{agente.upper()}**{destino}\n{mensagem}"

payload = {
    "text": text,
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": text
            }
        }
    ]
}

data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(webhook, data=data, headers={
    "Content-Type": "application/json",
})

try:
    with urllib.request.urlopen(req) as resp:
        dest_str = f" → {para}" if para else ""
        print(f"[slack] {agente}{dest_str}: mensagem enviada")
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"[slack] Erro HTTP {e.code}: {body}", file=sys.stderr)
    sys.exit(1)
PYEOF
