#!/usr/bin/env bash
# Objetivo: mover issue no fluxo do board via labels no GitHub.
# Pre-requisitos: gh autenticado e permissao no repo.
# Execucao: scripts/tooling/issue-move.sh <issue#> <coluna> [agente]

set -euo pipefail

ISSUE="${1:-}"
COL="${2:-}"
AGENT="${3:-}"
REPO="${REPO:-gmmattey/linka-webapp}"

if [ -z "$ISSUE" ] || [ -z "$COL" ]; then
  echo "uso: $0 <issue#> <coluna> [agente]" >&2
  echo "colunas: ready|in-progress|review|docs|done|triagem|backlog|block" >&2
  exit 2
fi

status_label=""
case "$COL" in
  ready) status_label="status:agent-ready" ;;
  in-progress|wip|doing) status_label="status:in-progress" ;;
  review) status_label="status:waiting-review" ;;
  docs) status_label="status:docs-hygiene" ;;
  done) status_label="status:done" ;;
  triagem) status_label="status:triage" ;;
  backlog) status_label="status:backlog" ;;
  block|blocked) status_label="status:blocked" ;;
  *) echo "coluna invalida: $COL" >&2; exit 2 ;;
esac

for label in status:agent-ready status:in-progress status:waiting-review status:docs-hygiene status:done status:triage status:backlog status:blocked; do
  gh issue edit "$ISSUE" --repo "$REPO" --remove-label "$label" >/dev/null 2>&1 || true
done

gh issue edit "$ISSUE" --repo "$REPO" --add-label "$status_label" >/dev/null

if [ -n "$AGENT" ]; then
  gh issue edit "$ISSUE" --repo "$REPO" --add-label "agent:${AGENT}" >/dev/null 2>&1 || true
fi

echo "[issue-move] #$ISSUE -> $status_label"
