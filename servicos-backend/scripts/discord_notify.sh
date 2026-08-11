#!/usr/bin/env bash
# discord_notify.sh — Notificações do squad Linka para o Discord
#
# Uso:
#   bash scripts/discord_notify.sh <agente> <mensagem> [status] [--para <agente_destino>]
#
# Agentes: camilo | gema | lia | marcelo | renan | claudete | sistema
# Status:  info (padrão) | success | warning | error | progress
#
# Exemplos:
#   bash scripts/discord_notify.sh camilo "Implementando TASK-01..." progress
#   bash scripts/discord_notify.sh gema "Audit concluído — sem blockers" success
#   bash scripts/discord_notify.sh camilo "TASK-03 entregue, pode revisar" success --para gema

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

WEBHOOK_URL="${DISCORD_WEBHOOK_LINKA:-}"
if [[ -z "$WEBHOOK_URL" ]]; then
  echo "DISCORD_WEBHOOK_LINKA não definido em .env" >&2
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

# ── Identidade e personalidade por agente ─────────────────────────────────────
AGENTES = {
    "camilo": {
        "name": "Camilo", "color": 15158332, "emoji": "🤖",
        "taglines": [
            "feito. graças a deus.",
            "100%. preciso comer.",
            "entregue. volto depois do banheiro.",
            "ok, tá pronto. que raiva.",
            "compilou. milagre.",
        ],
    },
    "gema": {
        "name": "Gema", "color": 15790863, "emoji": "🔍",
        "taglines": [
            "Entregue. Dados conferem.",
            "Concluído. Próximo.",
            "Resultado emitido. Sem ambiguidade.",
            "Feito. Sem margem para dúvida.",
            "Veredito registrado.",
        ],
    },
    "lia": {
        "name": "Lia", "color": 10181046, "emoji": "🎨",
        "taglines": [
            "Feito. Podia estar melhor.",
            "Entregue. O Camilo vai ignorar metade.",
            "Concluído. Aqui tá aceitável.",
            "Pronto. A hierarquia está menos caótica.",
            "Ok. Não é o que eu faria, mas serve.",
        ],
    },
    "marcelo": {
        "name": "Marcelo", "color": 15105570, "emoji": "🔎",
        "taglines": [
            "achei. pode usar. vou tomar um café.",
            "tá aí. sofri, mas tá.",
            "feito. minha vida continua sem sentido.",
            "entregue. peidei no processo.",
            "pronto. isso não é vida.",
        ],
    },
    "renan": {
        "name": "Renan", "color": 3447003, "emoji": "🌐",
        "taglines": [
            "Feito. Café esquentou.",
            "Entregue. PWA rodando.",
            "Ok, tá lá. Me deixa em paz.",
            "Concluído. Café na mão.",
            "Deploy feito. Voltando pro sofá.",
        ],
    },
    "claudete": {
        "name": "Claudete", "color": 3066993, "emoji": "📋",
        "taglines": [
            "Task entregue. Fila atualizada.",
            "Concluído. Próxima task em standby.",
            "Sprint avança.",
            "Entregue. Pipeline limpo.",
            "Feito. Backlog decrementado.",
        ],
    },
}

NOMES = {k: v["name"] for k, v in AGENTES.items()}
NOMES["sistema"] = "Linka Dispatch"

STATUS_MAP = {
    "success":  (5763719,  "✅"),
    "warning":  (16704348, "⚠️"),
    "error":    (15548997, "❌"),
    "progress": (None,     "🔄"),
    "info":     (None,     "ℹ️"),
}

ag = AGENTES.get(agente, {"name": "Linka Dispatch", "color": 5793266, "emoji": "⚙️", "taglines": ["Entregue."]})
st_color, st_icon = STATUS_MAP.get(status, (None, "ℹ️"))
color = st_color if st_color is not None else ag["color"]
timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# Tagline de personalidade (só em success/error — evita ruído em progress/info)
tagline = ""
if status in ("success", "error") and "taglines" in ag:
    tagline = f"\n-# *{random.choice(ag['taglines'])}*"

# Mensagem final com direcionamento opcional
if para and para in AGENTES:
    dest_name = AGENTES[para]["name"]
    dest_emoji = AGENTES[para]["emoji"]
    descricao = f"{st_icon} **→ {dest_emoji} {dest_name}:** {mensagem}{tagline}"
    footer_text = f"Linka Squad • {ag['name']} → {dest_name}"
else:
    descricao = f"{st_icon} {mensagem}{tagline}"
    footer_text = f"Linka Squad • {ag['name']}"

payload = {
    "username": ag["name"],
    "embeds": [{
        "description": descricao,
        "color": color,
        "footer": {"text": footer_text},
        "timestamp": timestamp,
    }]
}

data = json.dumps(payload).encode("utf-8")
req = urllib.request.Request(webhook, data=data, headers={
    "Content-Type": "application/json",
    "User-Agent": "DiscordBot (linka-squad, 1.0)",
})

try:
    with urllib.request.urlopen(req) as resp:
        dest_str = f" → {NOMES.get(para, para)}" if para else ""
        print(f"[discord] {ag['name']}{dest_str}: mensagem enviada")
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"[discord] Erro HTTP {e.code}: {body}", file=sys.stderr)
    sys.exit(1)
PYEOF
