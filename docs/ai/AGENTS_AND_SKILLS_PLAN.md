# Plano de Agentes e Skills

## Escopo

Agentes e skills deste repositorio devem operar somente sobre o Linka WebApp PWA.

Fora de escopo:

- Android nativo
- Capacitor
- APK/AAB
- Gradle
- Keystore
- Plugins nativos

## Skills Recomendadas

- `codebase-map`: entender estrutura antes de alterar.
- `pwa-platform-rules`: validar limites de navegador e instalacao PWA.
- `browser-limitations`: impedir promessas de recurso nativo inexistente no web.
- `react-typescript-check`: revisar componentes, hooks e tipos.
- `regression-check`: validar fluxo principal e historico.
- `qa-acceptance-check`: fechar aceite antes de release.
- `cloudflare-pages-check`: validar build/deploy PWA.

## Fluxo Esperado

1. Mapear impacto.
2. Confirmar limite web/PWA.
3. Implementar alteracao minima.
4. Atualizar docs vivas.
5. Rodar lint, testes e build.
6. Reportar comandos executados e riscos restantes.

## Politica de Scripts

Agentes devem criar automacoes apenas em `scripts/`, seguindo `scripts/README.md`.
Scripts temporarios, Android ou desatualizados nao devem ser mantidos no repositorio.
