#!/bin/bash
set -e

echo "🚀 Iniciando automação de Release (Linka)..."

PROJECT_YML="aplicativo-ios/project.yml"
PBXPROJ="aplicativo-ios/LinkaApp.xcodeproj/project.pbxproj"

usage() {
    echo "Uso: $0 [patch|minor|major|X.Y.Z]"
    echo "  patch (padrão): incrementa o último número (1.0.0 -> 1.0.1)"
    echo "  minor:          incrementa o número do meio (1.0.0 -> 1.1.0)"
    echo "  major:          incrementa o primeiro número (1.0.0 -> 2.0.0)"
    echo "  X.Y.Z:          define a versão explicitamente"
    exit 1
}

BUMP="${1:-patch}"

if [ ! -f "$PROJECT_YML" ]; then
    echo "Erro: $PROJECT_YML não encontrado. Rode este script a partir da raiz do repositório."
    exit 1
fi

# Lê a versão e o build atuais. Os valores no YAML vêm entre aspas
# (ex.: MARKETING_VERSION: "1.0.0"), então extraímos só o conteúdo entre aspas.
CURRENT_VERSION=$(grep -E '^\s*MARKETING_VERSION:' "$PROJECT_YML" | sed -E 's/.*MARKETING_VERSION:[[:space:]]*"?([0-9]+\.[0-9]+\.[0-9]+)"?.*/\1/')
CURRENT_BUILD=$(grep -E '^\s*CURRENT_PROJECT_VERSION:' "$PROJECT_YML" | sed -E 's/.*CURRENT_PROJECT_VERSION:[[:space:]]*"?([0-9]+)"?.*/\1/')

if [ -z "$CURRENT_VERSION" ]; then
    echo "Erro: MARKETING_VERSION não encontrado ou em formato inesperado em $PROJECT_YML"
    exit 1
fi

if [ -z "$CURRENT_BUILD" ]; then
    echo "Erro: CURRENT_PROJECT_VERSION não encontrado ou em formato inesperado em $PROJECT_YML"
    exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case "$BUMP" in
    patch)
        NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
        ;;
    minor)
        NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
        ;;
    major)
        NEW_VERSION="$((MAJOR + 1)).0.0"
        ;;
    [0-9]*.[0-9]*.[0-9]*)
        NEW_VERSION="$BUMP"
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "Erro: argumento inválido '$BUMP'."
        usage
        ;;
esac

# O build number sempre incrementa de forma monotônica, independente do tipo de bump.
NEW_BUILD=$((CURRENT_BUILD + 1))

# Escreve a nova versão e build no YAML do XcodeGen, preservando as aspas.
sed -i '' -E "s/(MARKETING_VERSION:[[:space:]]*)\"[0-9]+\.[0-9]+\.[0-9]+\"/\1\"$NEW_VERSION\"/" "$PROJECT_YML"
sed -i '' -E "s/(CURRENT_PROJECT_VERSION:[[:space:]]*)\"[0-9]+\"/\1\"$NEW_BUILD\"/" "$PROJECT_YML"

# Confere que a escrita realmente aplicou (sed não falha se o padrão não casar).
WRITTEN_VERSION=$(grep -E '^\s*MARKETING_VERSION:' "$PROJECT_YML" | sed -E 's/.*MARKETING_VERSION:[[:space:]]*"?([0-9]+\.[0-9]+\.[0-9]+)"?.*/\1/')
WRITTEN_BUILD=$(grep -E '^\s*CURRENT_PROJECT_VERSION:' "$PROJECT_YML" | sed -E 's/.*CURRENT_PROJECT_VERSION:[[:space:]]*"?([0-9]+)"?.*/\1/')

if [ "$WRITTEN_VERSION" != "$NEW_VERSION" ] || [ "$WRITTEN_BUILD" != "$NEW_BUILD" ]; then
    echo "Erro: falha ao escrever a nova versão/build em $PROJECT_YML (esperado $NEW_VERSION/$NEW_BUILD, encontrado $WRITTEN_VERSION/$WRITTEN_BUILD)."
    exit 1
fi

echo "✅ Versão preparada: $CURRENT_VERSION -> $NEW_VERSION (build $CURRENT_BUILD -> $NEW_BUILD)"

# Regenera o projeto Xcode
echo "⚙️  Regenerando o projeto Xcode..."
(cd aplicativo-ios && xcodegen generate)

if [ ! -f "$PBXPROJ" ]; then
    echo "Erro: $PBXPROJ não foi encontrado após 'xcodegen generate'."
    exit 1
fi

# Valida que os valores realmente aplicados no pbxproj gerado batem com o esperado.
PBXPROJ_VERSION=$(grep -m1 'MARKETING_VERSION = ' "$PBXPROJ" | sed -E 's/.*MARKETING_VERSION = ([0-9]+\.[0-9]+\.[0-9]+);.*/\1/')
PBXPROJ_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$PBXPROJ" | sed -E 's/.*CURRENT_PROJECT_VERSION = ([0-9]+);.*/\1/')

if [ "$PBXPROJ_VERSION" != "$NEW_VERSION" ]; then
    echo "Erro: MARKETING_VERSION no pbxproj gerado ($PBXPROJ_VERSION) não bate com o esperado ($NEW_VERSION)."
    exit 1
fi

if [ "$PBXPROJ_BUILD" != "$NEW_BUILD" ]; then
    echo "Erro: CURRENT_PROJECT_VERSION no pbxproj gerado ($PBXPROJ_BUILD) não bate com o esperado ($NEW_BUILD)."
    exit 1
fi

echo "✅ pbxproj validado: MARKETING_VERSION=$PBXPROJ_VERSION, CURRENT_PROJECT_VERSION=$PBXPROJ_BUILD"
echo "🎉 Projeto preparado! Lembre-se de anexar o RELEASE_NOTES.md no commit."
