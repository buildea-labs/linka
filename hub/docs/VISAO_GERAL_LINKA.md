# Visao Geral — Linka

> Documento de referencia rapida para qualquer agente ou colaborador que precise entender o ecossistema Linka antes de trabalhar em qualquer um dos projetos.
> Fonte: `E:\Projetos\Linka\CLAUDE.md` (fonte de verdade do workspace).

---

## O que e o Linka

**Linka** e um app de diagnostico de internet domestica. Mede velocidade, analisa Wi-Fi, DNS, latencia, jitter e perda de pacotes, e entrega diagnostico assistido por IA com acoes praticas para o usuario.

**Publico-alvo:** usuarios brasileiros com internet domestica ou movel que querem entender e melhorar a qualidade da conexao sem precisar de conhecimento tecnico.

---

## Os dois projetos

| Projeto | Caminho | Stack principal |
|---|---|---|
| Android (app principal) | `linkaAndroidKotlin/` | Kotlin, Jetpack Compose, Material Design 3, MVVM, Room, Coroutines |
| PWA (complementar) | `linkaSpeedtestPwa/` | React 19, TypeScript, Vite, CSS Custom Properties, Cloudflare Pages, Capacitor |

### Relacao entre os dois

- O PWA nao e um subproduto menor — e tratado como produto complementar com identidade propria.
- Deve manter **paridade visual e funcional** com o Android onde tecnicamente possivel no navegador.
- O que nao e possivel no browser (permissoes de hardware, APIs nativas, Wi-Fi scanning real) deve ser omitido ou indicado como limitacao — nunca simulado.
- Contratos de API e regras de diagnostico sao compartilhados; implementacao e separada.

---

## Modulos Android (15)

`:app`, `:coreNetwork`, `:corePermissions`, `:coreDatabase`, `:coreDatastore`, `:coreTelephony`, `:featureHome`, `:featureWifi`, `:featureDevices`, `:featureDns`, `:featureSpeedtest`, `:featureDiagnostico`, `:featureFibra`, `:featureHistory`, `:featureSettings`.

> Nota: o CLAUDE.md do workspace menciona 16 modulos. O numero correto (verificado em `settings.gradle.kts`) e 15.

---

## Estrutura do workspace

```
E:\Projetos\Linka\
├── CLAUDE.md                   ← Hub central: regras, agentes, fluxo
├── docs/                       ← Documentacao compartilhada (este diretorio)
│   ├── INDICE.md               ← Indice completo das tres pastas de docs (assessment)
│   ├── VISAO_GERAL_LINKA.md    ← Este arquivo
│   ├── GUIA_CONVIVENCIA_IA.md
│   ├── GUIA_DESENVOLVIMENTO_IA.md
│   ├── PADROES_UI_UX.md
│   ├── MATERIAL_DESIGN_3.md
│   └── GUIA_SELECAO_MODELO_IA.md
├── linkaAndroidKotlin/         ← Projeto Android
│   └── linka-android-kotlin/   ← Codigo Kotlin/Compose
└── linkaSpeedtestPwa/          ← Projeto PWA
    ├── CLAUDE.md               ← Regras especificas PWA
    ├── src/                    ← Codigo React/TypeScript
    └── docs/                   ← Documentacao especifica PWA
```

---

## Onde encontrar cada tipo de informacao

> **Para assessment ou navegacao inicial:** comece pelo [`docs/INDICE.md`](INDICE.md) — lista todos os documentos validos das tres pastas com descricao, escopo e ordem de leitura recomendada.

| Necessidade | Onde ler |
|---|---|
| Indice completo de toda a documentacao | `E:\Projetos\Linka\docs\INDICE.md` |
| Regras gerais, agentes, fluxo de trabalho | `E:\Projetos\Linka\CLAUDE.md` |
| Regras especificas do PWA | `linkaSpeedtestPwa/CLAUDE.md` |
| Indice de documentos PWA | `linkaSpeedtestPwa/docs/DOCUMENTACAO_CONSOLIDADA.md` |
| Especificacao funcional PWA (telas, UX, fluxos) | `linkaSpeedtestPwa/docs/DocumentacaoFuncionalSistema.md` |
| Arquitetura tecnica PWA (hooks, motor, tipos) | `linkaSpeedtestPwa/docs/DocumentacaoTecnicaSistema.md` |
| Branding, cores, tipografia (PWA) | `linkaSpeedtestPwa/docs/GuiaBranding.md` |
| Tokens de design e MD3 | `E:\Projetos\Linka\docs\MATERIAL_DESIGN_3.md` |
| Padroes UI/UX unificados | `E:\Projetos\Linka\docs\PADROES_UI_UX.md` |
| Sistema multiagente | `E:\Projetos\Linka\docs\GUIA_CONVIVENCIA_IA.md` |
| Como trabalhar com IA no codigo | `E:\Projetos\Linka\docs\GUIA_DESENVOLVIMENTO_IA.md` |
| Qual modelo IA usar | `E:\Projetos\Linka\docs\GUIA_SELECAO_MODELO_IA.md` |

---

## Principios do produto

1. **Menor mudanca que resolve o problema.** Nao reescrever modulos inteiros sem necessidade.
2. **Nao inventar regra de diagnostico.** Verificar engines, thresholds e use cases existentes antes.
3. **Nao misturar logica Android com logica PWA.** Projetos separados com contratos definidos.
4. **O PWA nao exibe funcionalidades impossiveis no navegador.**
5. **Toda feature termina com resumo tecnico:** arquivos alterados, testes feitos e riscos restantes.

---

**Ultima atualizacao:** 2026-05-16
**Mantido por:** Taisa (agente de documentacao)
