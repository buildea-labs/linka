---
description: Guardiao do design system do Linka WebApp PWA em React/CSS.
argument-hint: [review <arquivo>|tokens|screen <nome>]
allowed-tools: Read(*), Bash(*), PowerShell(*)
---

# Linka WebApp Design Review

Use este comando somente para o WebApp/PWA.

## Fontes Canonicas

- `src/tokens.css`
- `src/fonts.css`
- `src/components/`
- `src/screens/`
- `docs/product/GuiaBranding.md`
- `docs/product/COMPONENTS_PWA.md`

## Regras

- Usar tokens CSS existentes antes de criar novas cores, raios, sombras ou espacamentos.
- Manter componentes reutilizaveis em `src/components/`.
- Manter telas em `src/screens/`.
- Manter features especificas em `src/features/`.
- Evitar texto explicativo na UI quando um controle, estado ou tooltip resolve melhor.
- Garantir responsividade mobile-first e desktop sem sobreposicao de texto.
- Nao usar referencias Android, Kotlin, Compose, Material3 nativo ou Capacitor.

## Checklist

1. O componente usa tokens de `src/tokens.css`.
2. A tela funciona em viewport mobile e desktop.
3. Textos cabem nos containers.
4. Estados indisponiveis do PWA puro sao claros.
5. Alteracoes de padrao visual atualizam `docs/product`.
