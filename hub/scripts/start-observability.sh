#!/bin/bash

# Startup script para observabilidade Linka + Langfuse
# Uso: ./start-observability.sh

set -e

WORKSPACE_PATH="${1:-.}"
LANGFUSE_HOST="${LANGFUSE_HOST:-http://localhost:3000}"

echo "=================================================="
echo "🚀 Iniciando observabilidade Linka"
echo "=================================================="
echo ""
echo "📍 Workspace: $WORKSPACE_PATH"
echo "🎯 Langfuse:  $LANGFUSE_HOST"
echo ""

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Instale Docker Desktop."
    exit 1
fi

# Criar estrutura de pastas
echo "📁 Criando estrutura de observabilidade..."
mkdir -p "$WORKSPACE_PATH/.claude/events"
mkdir -p "$WORKSPACE_PATH/.claude/observability"
mkdir -p "$WORKSPACE_PATH/.claude/reports"

# Iniciar Langfuse
echo ""
echo "🐳 Iniciando containers Docker..."
cd "$WORKSPACE_PATH"

if docker-compose up -d; then
    echo "✅ Docker compose iniciado"
else
    echo "⚠️  docker-compose falhou, tentando docker compose..."
    docker compose up -d
fi

# Aguardar Langfuse ficar pronto
echo ""
echo "⏳ Aguardando Langfuse..."
max_attempts=30
attempt=0

while [ $attempt -lt $max_attempts ]; do
    if curl -s "$LANGFUSE_HOST/api/health" > /dev/null 2>&1; then
        echo "✅ Langfuse pronto"
        break
    fi
    echo -n "."
    sleep 1
    attempt=$((attempt + 1))
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Langfuse não respondeu após 30s"
    echo "   Verifique: docker ps"
    echo "   Logs: docker-compose logs langfuse"
    exit 1
fi

echo ""
echo "=================================================="
echo "✨ Observabilidade iniciada!"
echo "=================================================="
echo ""
echo "📊 Dashboard Langfuse: $LANGFUSE_HOST"
echo "📝 Eventos: $WORKSPACE_PATH/.claude/events/agent-events.jsonl"
echo "📊 Relatórios: $WORKSPACE_PATH/.claude/reports/"
echo ""
echo "Próximos passos:"
echo "  1. Abra $LANGFUSE_HOST no navegador"
echo "  2. Use o workflow normalmente"
echo "  3. Eventos serão registrados em tempo real"
echo ""
echo "Para parar:"
echo "  docker-compose down"
echo ""
