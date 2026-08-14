#!/bin/bash
set -e

echo "🚀 Iniciando automação de Release (Linka)..."

PROJECT_YML="aplicativo-ios/project.yml"

# Lê a versão atual
VERSION=$(grep 'MARKETING_VERSION' $PROJECT_YML | awk '{print $2}')
CURRENT_BUILD=$(grep 'CURRENT_PROJECT_VERSION' $PROJECT_YML | awk '{print $2}')

if [ -z "$CURRENT_BUILD" ]; then
    echo "Erro: CURRENT_PROJECT_VERSION não encontrado no $PROJECT_YML"
    exit 1
fi

NEW_BUILD=$((CURRENT_BUILD + 1))

# Faz o bump do build number no YAML do XcodeGen
sed -i '' -E "s/CURRENT_PROJECT_VERSION: [0-9]+/CURRENT_PROJECT_VERSION: $NEW_BUILD/" $PROJECT_YML

echo "✅ Build incrementado: $CURRENT_BUILD -> $NEW_BUILD (Versão: $VERSION)"

# Regenera o projeto Xcode
echo "⚙️  Regenerando o projeto Xcode..."
cd aplicativo-ios
xcodegen generate
cd ..

echo "🎉 Projeto preparado! Lembre-se de anexar o RELEASE_NOTES.md no commit."
