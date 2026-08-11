# Guia de Desenvolvimento com IA — Ecossistema Linka

> Como trabalhar em codigo neste workspace usando Claude Code e agentes especializados.
> Complementa o `GUIA_CONVIVENCIA_IA.md` com foco em pratica de desenvolvimento.

---

## 1. Antes de qualquer edicao

### Sequencia obrigatoria de leitura

```
1. E:\Projetos\Linka\CLAUDE.md              (sempre — regras criticas do workspace)
2. CLAUDE.md do projeto especifico           (Android ou PWA)
3. Documentacao relevante para a task       (conforme secao abaixo)
```

### Verificacao Git (projetos com controle de versao)

Para o PWA (`linkaSpeedtestPwa/`):
1. `git status` — verificar estado atual
2. `git fetch origin` — buscar atualizacoes remotas
3. Confirmar que esta em `main`
4. Se houver divergencia, conflito ou duvida: parar e informar o usuario

### Classificacao da task antes de comecar

Envie esta mensagem antes de editar qualquer arquivo:

```
Ferramenta/modelo: [ex: Claude Sonnet 4.6]
Tipo: Bug fix / Feature / Refactor / Teste / Docs
Tamanho: Pequeno / Medio / Grande
Stack: Android / PWA / Ambos
Arquivos provaveis a alterar: [lista]
Documentos provaveis a atualizar: [lista]
Riscos: Nenhum / Baixo / Medio / Alto
Plano resumido: [3-5 passos]
```

Aguardar OK antes de editar.

---

## 2. Regras por projeto

### Android (`linkaAndroidKotlin/`)

- Stack: Kotlin, Jetpack Compose, Material Design 3, MVVM, Room, Coroutines
- 16 modulos — alterar apenas os modulos necessarios para a task
- Nao colocar logica de negocio dentro de Composable
- Nao duplicar componente existente — buscar antes de criar
- Nao inventar regra de diagnostico — verificar engines, thresholds e use cases existentes
- Antes de qualquer toque em permissoes, Wi-Fi, DNS ou hardware: consultar **Otavio** primeiro

### PWA (`linkaSpeedtestPwa/`)

- Stack: React 19, TypeScript, Vite, CSS Custom Properties, Cloudflare Pages, Capacitor
- Trabalhar sempre em `main`. Nunca criar branches paralelas
- Nao criar arquivos fora da estrutura prevista em `docs/GuiaOrganizacaoPastas.md`
- O PWA nao exibe funcionalidades impossiveis no navegador — omitir ou indicar como limitacao
- Documentacao deve ser atualizada na mesma task em que alterar comportamento

---

## 3. Buscas de codigo — regra de token

**Antes de abrir qualquer arquivo completo:**
1. Use `Grep` para encontrar o simbolo, classe ou funcao especifica
2. So entao use `Read` no arquivo encontrado, apontando para as linhas relevantes

**Antes de consumir contexto Sonnet em leituras simples:**
Delegar ao **Marcelo (Haiku)** — grep de simbolos, listagem de modulos, verificacao de existencia de componentes.

```
Tarefa para Marcelo:
Verificar se o componente [Nome] existe e em qual arquivo.
Retornar: path completo do arquivo.
Contexto: projeto PWA, src/components/.
```

---

## 4. Documentacao como parte da task

Documentacao nao e opcional. Codigo sem documentacao necessaria atualizada e task incompleta.

### Quando atualizar documentacao

| Mudanca | Doc a atualizar |
|---|---|
| Nova tela ou tela modificada (PWA) | `DocumentacaoFuncionalSistema.md` + `SCREENS_PWA.md` |
| Novo componente (PWA) | `DocumentacaoTecnicaSistema.md` + `COMPONENTS_PWA.md` |
| Nova feature ou mudanca de comportamento | Funcional + Tecnica relevante |
| Mudanca de arquitetura | `DocumentacaoTecnicaSistema.md` |
| Mudanca de fluxo de dados | Diagrama ou descricao no doc tecnico |
| Mudanca de branding/visual | `GuiaBranding.md` |

### Quem documenta o que

- **Nina:** changelog, versionamento, checklist de entrega, resumos de tarefa
- **Taisa:** documentacao funcional completa, tecnica, de testes, fluxos, PPT, HTML
- **Camilo/Renan:** responsaveis por notificar o que mudou para Nina/Taisa documentarem

---

## 5. Checklist de entrega

### Codigo

- [ ] Compila/roda sem erros
- [ ] Testes passam
- [ ] Lint limpo
- [ ] Performance nao degradou
- [ ] Sem credenciais, tokens ou segredos no codigo

### Documentacao

- [ ] Docs do projeto atualizadas (se mudou UI, fluxo ou comportamento)
- [ ] Indice de docs sincronizado
- [ ] Se nenhum documento foi atualizado: justificativa explicita

### Resumo de entrega obrigatorio

- Arquivos de codigo alterados com resumo por path
- Documentos atualizados listando cada arquivo
- Comandos executados e resultado
- Pendencias ou riscos restantes
- Proximos passos sugeridos

---

## 6. Quando parar e pedir orientacao

Pare e peca orientacao se o pedido exigir:

- Criar arquivo fora da organizacao documentada
- Refatoracao ampla sem plano aprovado
- Conflito entre regra do usuario, `CLAUDE.md` e docs
- Uso de credenciais, tokens ou segredos
- Deploy, commit ou push sem confirmacao
- Inventar requisito que nao existe no codigo nem na documentacao
- Task que afeta >5 modulos ou levaria >1 dia

---

## 7. Convencoes de codigo

### Android — Kotlin

- MVVM: ViewModel + Repository + UseCase + DataSource
- Composables so recebem estado — nao buscam dados
- Nomes de modulos: `:featureXxx`, `:coreXxx`
- Testes em `src/test/` e `src/androidTest/`

### PWA — TypeScript/React

- Componentes em `src/components/` (compartilhados) ou `src/features/[nome]/` (por dominio)
- Hooks em `src/hooks/`
- Telas em `src/screens/`
- CSS por componente — arquivo `.css` ao lado do `.tsx`
- Sem React Router — roteamento por `useState<Screen>` em `App.tsx`
- Sem `box-shadow` em nenhum componente
- Cores sempre via tokens CSS (`var(--*)`) — nunca hex hardcoded em `.tsx`/`.css`

---

## 8. Erros comuns a evitar

| Erro | O que fazer |
|---|---|
| Abrir arquivo inteiro para encontrar uma funcao | Grep primeiro, Read so do trecho relevante |
| Criar componente novo sem verificar se existe | Buscar em `src/components/` e `src/features/` antes |
| Colocar logica de negocio em Composable (Android) | Mover para ViewModel ou UseCase |
| Usar hex hardcoded em CSS (PWA) | Usar token `var(--nome-do-token)` |
| Usar fonte hardcoded em CSS (PWA) | Usar `var(--font-display)`, `var(--font-body)` ou `var(--font-mono)` |
| Implementar feature de browser que nao e possivel | Verificar `src/platform/capabilities.ts` antes |
| Documentar feature que ainda nao existe | Marcar como `[a confirmar]` ou nao documentar ainda |
| Fazer task grande sem plano | Acionar Claudio para quebrar antes |

---

**Ultima atualizacao:** 2026-05-16
**Mantido por:** Taisa
