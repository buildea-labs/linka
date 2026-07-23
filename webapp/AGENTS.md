# AGENTS.md - Linka WebApp

Este arquivo define como agentes devem trabalhar neste repositorio.

## Escopo

- Projeto: Linka WebApp PWA.
- Stack: Vite, React, TypeScript, Vitest e Cloudflare Pages.
- Raiz esperada: `C:\Projetos\Linka WebApp`.
- Proibido misturar Android, APK, Gradle, keystore, Capacitor ou plugins nativos neste repositorio.

## Regras Fixas

- Edite somente arquivos deste WebApp.
- Nao crie logica duplicada para diagnostico, speedtest ou recomendacoes.
- Nao exponha recurso nativo como ativo no PWA puro; use fallback indisponivel.
- Se comportamento mudar, atualize a documentacao viva no mesmo trabalho.
- Scripts novos devem ficar somente em `scripts/`.
- Scripts obsoletos devem ser removidos, nao arquivados no projeto "por garantia".

## Scripts

Pasta unica para automacoes:

```txt
scripts/
  qa/        validacao, regressao e evidencias
  release/   automacoes de build/deploy/release
  tooling/   manutencao local
```

Antes de criar script, leia `scripts/README.md`.

## Fluxo de Trabalho

1. Mapear impacto em codigo, docs e testes.
2. Validar limites do navegador/PWA.
3. Alterar o minimo necessario.
4. Atualizar docs quando contratos, fluxos ou estrutura mudarem.
5. Rodar validacoes aplicaveis.

## Fluxo GitHub/Slack

Quando o usuario pedir tratativa continua de issues do GitHub:

1. Buscar issues abertas do repositorio e ordenar por prioridade declarada (`P0`, `P1`, `P2`) e, em empate, pela ordem da issue.
2. Tratar uma issue por vez.
3. Criar branch dedicada com prefixo `codex/`.
4. Implementar o menor conjunto de mudancas necessario, incluindo docs e testes quando aplicavel.
5. Rodar a validacao minima (`npm run lint`, `npm test`, `npm run build`) e qualquer verificacao de browser/PWA relevante.
6. Criar commit objetivo na branch.
7. Enviar a branch para o GitHub e abrir PR para `main` vinculando a issue.
8. Se a validacao estiver ok e a branch estiver alinhada com `main`, aplicar o commit na `main` por fast-forward/push ou merge equivalente autorizado pelo usuario.
9. Confirmar que o PR/issue ficou concluido no GitHub.
10. Informar no Slack, canal `#linka-webapp`, com issue, PR, commit e validacoes executadas.
11. Repetir o fluxo para a proxima issue aberta por prioridade.

Se algum passo nao puder ser executado, reportar explicitamente o bloqueio e nao fingir conclusao.

## Enforcement do Fluxo (Obrigatorio)

Estas regras prevalecem para qualquer trabalho com issue/PR e devem ser tratadas como bloqueio duro:

1. Proibido commit direto em `main` quando o trabalho estiver vinculado a issue.
2. Proibido tratar mais de uma issue por vez.
3. Obrigatorio usar branch `codex/<id-ou-tema-curto>` para cada issue.
4. Obrigatorio abrir PR para `main` antes de qualquer merge.
5. Merge em `main` somente com autorizacao explicita do usuario na conversa atual.
6. Se qualquer regra acima for violada, o agente deve:
   - parar imediatamente novas alteracoes;
   - reportar o desvio com clareza;
   - propor plano de correcao sem perda;
   - aguardar confirmacao do usuario antes de continuar.

### Checklist Obrigatorio Antes de Codar

Antes de editar arquivos, o agente deve informar:

- issue alvo (ID e titulo);
- branch atual;
- estado do git (`clean` ou `dirty`);
- proximo passo imediato.

Sem esse checklist, a execucao deve ser pausada.

### Evidencias Obrigatorias na Entrega

Ao finalizar cada issue, o agente deve reportar explicitamente:

- issue;
- branch;
- PR;
- commit(s);
- saida/situacao de `npm run lint`, `npm test`, `npm run build`;
- status da comunicacao no Slack `#linka-webapp` (ou bloqueio concreto).

## Validacao Minima

```bash
npm run lint
npm test
npm run build
```

Se algum comando nao foi executado, reporte explicitamente.

## Documentacao Canonica

Prioridade:

1. Mensagem atual do usuario.
2. `AGENTS.md`.
3. `CLAUDE.md`.
4. `README.md`.
5. `docs/architecture`.
6. `docs/product`.
7. Demais documentos em `docs/`.

Arquivos em `docs/archive` sao historicos; nao use como regra atual sem confirmar.
