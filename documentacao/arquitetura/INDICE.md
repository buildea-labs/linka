# INDICE — Documentação do Ecossistema Linka

**Gerado em:** 2026-05-16
**Atualizado em:** 2026-05-17 (auditoria completa do código Android — atualização de docs Android e correção de erros em docs cross-platform)
**Mantido por:** Taisa (agente de documentação)
**Público-alvo:** Time de desenvolvimento + avaliadores externos (assessment)

> Este índice cobre as três pastas de documentação do workspace:
> - `E:\Projetos\Linka\docs\` — documentação cross-platform (referência primária)
> - `E:\Projetos\Linka\linkaAndroidKotlin\docs_ai\` — documentação específica Android
> - `E:\Projetos\Linka\linkaSpeedtestPwa\docs\` — documentação específica PWA

---

## Ordem de Leitura Recomendada para Assessment

Para entender o produto rapidamente, leia nesta sequência:

1. `docs/VISAO_GERAL_LINKA.md` — o que é o Linka, dois projetos, relações
2. `docs/FUNCIONAL_CROSSPLATFORM.md` — features e fluxos por plataforma
3. `linkaAndroidKotlin/docs_ai/technical/ARCHITECTURE.md` — arquitetura Android
4. `linkaSpeedtestPwa/docs/DocumentacaoTecnicaSistema.md` — arquitetura PWA
5. `docs/DESIGN_SYSTEM_CROSSPLATFORM.md` — identidade visual compartilhada
6. `docs/TESTES.md` — cobertura de testes e lacunas conhecidas

---

## 1. Documentação Cross-Platform (`docs/`)

Documentos válidos para ambas as plataformas. São a referência primária quando existe sobreposição com docs específicos de plataforma.

### Produto e Funcional

| Documento | O que cobre | Escopo |
|---|---|---|
| [`VISAO_GERAL_LINKA.md`](VISAO_GERAL_LINKA.md) | O que é o Linka, dois projetos, stack, onde encontrar cada tipo de info | Ambos |
| [`FUNCIONAL_CROSSPLATFORM.md`](FUNCIONAL_CROSSPLATFORM.md) | Features, fluxos de usuário, comportamento por plataforma | Ambos |
| [`ANDROID_FUNCIONAL.md`](ANDROID_FUNCIONAL.md) | Telas Android, fluxos de navegação, comportamento por tela, features exclusivas Android | Android |
| [`PADROES_UI_UX.md`](PADROES_UI_UX.md) | Padrões UI/UX compartilhados: iOS-Calma, nomenclatura de métricas, estados visuais, chips, ícones, copy | Ambos |

### Técnico

| Documento | O que cobre | Escopo |
|---|---|---|
| [`TECNICO_CROSSPLATFORM.md`](TECNICO_CROSSPLATFORM.md) | Arquitetura, contratos de API, decisões técnicas compartilhadas | Ambos |
| [`ANDROID_TECNICO.md`](ANDROID_TECNICO.md) | Arquitetura Android detalhada — módulos, entidades Room, engines de diagnóstico, IA, monitoramento passivo | Android |
| [`MATERIAL_DESIGN_3.md`](MATERIAL_DESIGN_3.md) | Tokens MD3: paleta de cores, tipografia, espaçamento, componentes em uso | Ambos |

### Design System

| Documento | O que cobre | Escopo |
|---|---|---|
| [`DESIGN_SYSTEM_CROSSPLATFORM.md`](DESIGN_SYSTEM_CROSSPLATFORM.md) | Design tokens, componentes visuais, estados, guia de microcopy | Ambos |

### Testes

| Documento | O que cobre | Escopo |
|---|---|---|
| [`TESTES.md`](TESTES.md) | Matriz de cobertura por feature/plataforma, comandos de execução, lacunas conhecidas | Ambos |

### Processo e IA

| Documento | O que cobre | Escopo |
|---|---|---|
| [`GUIA_CONVIVENCIA_IA.md`](GUIA_CONVIVENCIA_IA.md) | Sistema multiagente: quem é cada agente, quando acionar, fluxo oficial | Processo |
| [`GUIA_DESENVOLVIMENTO_IA.md`](GUIA_DESENVOLVIMENTO_IA.md) | Como trabalhar com IA no código: sequência de leitura, classificação de task, regras por projeto | Processo |
| [`GUIA_SELECAO_MODELO_IA.md`](GUIA_SELECAO_MODELO_IA.md) | Qual modelo e agente usar para cada tipo de task, regras de economia de tokens | Processo |

---

## 2. Documentação Android (`linkaAndroidKotlin/docs_ai/`)

Documentação gerada e mantida para o projeto Android nativo.

> **Nota de sobreposição:** quando um doc Android tratar de comportamento também presente no PWA (ex: regras de diagnóstico, design tokens), o documento cross-platform em `docs/` é a referência primária.

### Técnico

| Documento | O que cobre |
|---|---|
| [`technical/ARCHITECTURE.md`](../linkaAndroidKotlin/docs_ai/technical/ARCHITECTURE.md) | Arquitetura de módulos Android, responsabilidades, dependências |
| [`technical/MODULES.md`](../linkaAndroidKotlin/docs_ai/technical/MODULES.md) | Inventário dos 16 módulos com paths reais |
| [`technical/SCREEN_MAP.md`](../linkaAndroidKotlin/docs_ai/technical/SCREEN_MAP.md) | Mapa de 14 telas com Composable, ViewModel e módulo |
| [`technical/API_MAP.md`](../linkaAndroidKotlin/docs_ai/technical/API_MAP.md) | APIs Android utilizadas por feature |
| [`technical/DATA_FLOW.md`](../linkaAndroidKotlin/docs_ai/technical/DATA_FLOW.md) | Fluxo de dados entre camadas, DAOs, Monitors |
| [`technical/BUILD_SYSTEM.md`](../linkaAndroidKotlin/docs_ai/technical/BUILD_SYSTEM.md) | Comandos de build, Gradle, dependências |
| [`technical/AI_FLOW.md`](../linkaAndroidKotlin/docs_ai/technical/AI_FLOW.md) | Fluxo do assistente IA (Orbit) no Android |
| [`technical/CLOUDFLARE.md`](../linkaAndroidKotlin/docs_ai/technical/CLOUDFLARE.md) | Integração Cloudflare no Android |
| [`technical/STORAGE.md`](../linkaAndroidKotlin/docs_ai/technical/STORAGE.md) | Estratégia de persistência: Room, Datastore |
| [`technical/SERVICES.md`](../linkaAndroidKotlin/docs_ai/technical/SERVICES.md) | Serviços em foreground/background |
| [`technical/FEATURE_FILE_MAPS.md`](../linkaAndroidKotlin/docs_ai/technical/FEATURE_FILE_MAPS.md) | Mapa de arquivos por feature |
| [`technical/MONITORAMENTO_PASSIVO.md`](../linkaAndroidKotlin/docs_ai/technical/MONITORAMENTO_PASSIVO.md) | LinkaPulse: monitoramento em background |

### Funcional

| Documento | O que cobre |
|---|---|
| [`functional/FEATURES.md`](../linkaAndroidKotlin/docs_ai/functional/FEATURES.md) | Inventário de features Android |
| [`functional/SCREENS_ANDROID.md`](../linkaAndroidKotlin/docs_ai/functional/SCREENS_ANDROID.md) | Telas Android com propósito e navegação |
| [`functional/DIAGNOSTIC_FLOW.md`](../linkaAndroidKotlin/docs_ai/functional/DIAGNOSTIC_FLOW.md) | Fluxo de diagnóstico assistido por IA |
| [`functional/DNS_FLOW.md`](../linkaAndroidKotlin/docs_ai/functional/DNS_FLOW.md) | Fluxo de diagnóstico DNS |
| [`functional/SPEEDTEST_FLOW.md`](../linkaAndroidKotlin/docs_ai/functional/SPEEDTEST_FLOW.md) | Fluxo do speedtest Android |
| [`functional/WIFI_FEATURES.md`](../linkaAndroidKotlin/docs_ai/functional/WIFI_FEATURES.md) | Features de análise Wi-Fi |
| [`functional/AI_ASSISTANT.md`](../linkaAndroidKotlin/docs_ai/functional/AI_ASSISTANT.md) | Especificação do assistente IA |
| [`functional/SETTINGS.md`](../linkaAndroidKotlin/docs_ai/functional/SETTINGS.md) | Configurações do app |

### Design System (Android)

| Documento | O que cobre |
|---|---|
| [`design-system/COLORS.md`](../linkaAndroidKotlin/docs_ai/design-system/COLORS.md) | Paleta de cores com path real (LinkaTheme.kt) |
| [`design-system/TYPOGRAPHY.md`](../linkaAndroidKotlin/docs_ai/design-system/TYPOGRAPHY.md) | Escala tipográfica MD3 e padrões de uso |
| [`design-system/SPACING.md`](../linkaAndroidKotlin/docs_ai/design-system/SPACING.md) | Sistema de espaçamento |
| [`design-system/COMPONENTS.md`](../linkaAndroidKotlin/docs_ai/design-system/COMPONENTS.md) | Inventário de 26 componentes custom |
| [`design-system/COMPONENTS_ANDROID.md`](../linkaAndroidKotlin/docs_ai/design-system/COMPONENTS_ANDROID.md) | Componentes exclusivos Android |
| [`design-system/DESIGN_TOKENS_CROSSPLATFORM.md`](../linkaAndroidKotlin/docs_ai/design-system/DESIGN_TOKENS_CROSSPLATFORM.md) | Tokens cross-platform (complementa `docs/DESIGN_SYSTEM_CROSSPLATFORM.md`) |
| [`design-system/MD3_GUIDELINES.md`](../linkaAndroidKotlin/docs_ai/design-system/MD3_GUIDELINES.md) | Princípios MD3 aplicados ao Linka |

### Operacional

| Documento | O que cobre |
|---|---|
| [`operations/APK_BUILD.md`](../linkaAndroidKotlin/docs_ai/operations/APK_BUILD.md) | Geração de APK debug/release |
| [`operations/DEPLOY.md`](../linkaAndroidKotlin/docs_ai/operations/DEPLOY.md) | Processo de deploy Android |
| [`operations/RELEASE.md`](../linkaAndroidKotlin/docs_ai/operations/RELEASE.md) | Fluxo de release e versionamento |
| [`operations/VERSIONING.md`](../linkaAndroidKotlin/docs_ai/operations/VERSIONING.md) | Convenção de versões |
| [`operations/ENVIRONMENT.md`](../linkaAndroidKotlin/docs_ai/operations/ENVIRONMENT.md) | Configuração de ambiente de desenvolvimento |
| [`operations/ENVIRONMENTS.md`](../linkaAndroidKotlin/docs_ai/operations/ENVIRONMENTS.md) | Ambientes (dev, staging, prod) |
| [`operations/SCRIPTS.md`](../linkaAndroidKotlin/docs_ai/operations/SCRIPTS.md) | Scripts utilitários |
| [`operations/PAPERCLIP_INTEGRATION.md`](../linkaAndroidKotlin/docs_ai/operations/PAPERCLIP_INTEGRATION.md) | Integração com Paperclip (gestão de tasks) |

### Fluxo de Agentes IA (Android)

| Documento | O que cobre |
|---|---|
| [`ai/AGENT_WORKFLOW.md`](../linkaAndroidKotlin/docs_ai/ai/AGENT_WORKFLOW.md) | Fluxo oficial de trabalho com agentes |
| [`ai/CONTEXT_POLICY.md`](../linkaAndroidKotlin/docs_ai/ai/CONTEXT_POLICY.md) | Política de contexto e fontes de verdade |
| [`ai/HANDOFF_RULES.md`](../linkaAndroidKotlin/docs_ai/ai/HANDOFF_RULES.md) | Regras de handoff entre agentes |
| [`ai/TASK_BREAKDOWN.md`](../linkaAndroidKotlin/docs_ai/ai/TASK_BREAKDOWN.md) | Como decompor tasks |
| [`ai/PRODUCT_FLOW.md`](../linkaAndroidKotlin/docs_ai/ai/PRODUCT_FLOW.md) | Fluxo de produto pelo ângulo do usuário |
| [`ai/ENGINEERING_FLOW.md`](../linkaAndroidKotlin/docs_ai/ai/ENGINEERING_FLOW.md) | Fluxo de engenharia: build, deploy, agentes |
| [`ai/REVIEW_FLOW.md`](../linkaAndroidKotlin/docs_ai/ai/REVIEW_FLOW.md) | Tipos de revisão e critérios |
| [`ai/UX_FLOW.md`](../linkaAndroidKotlin/docs_ai/ai/UX_FLOW.md) | Fluxo de UX e design |

### README de Navegação

| Documento | O que cobre |
|---|---|
| [`README.md`](../linkaAndroidKotlin/docs_ai/README.md) | Navegação da pasta docs_ai |

---

## 3. Documentação PWA (`linkaSpeedtestPwa/docs/`)

Documentação específica do PWA linka SpeedTest.

> **Documentos primários:** `DocumentacaoFuncionalSistema.md` e `DocumentacaoTecnicaSistema.md` são os monólitos de especificação. Os demais são complementares ou operacionais.

### Especificação Primária (monólitos — leia aqui antes de alterar comportamento)

| Documento | O que cobre | Status |
|---|---|---|
| [`DocumentacaoFuncionalSistema.md`](../linkaSpeedtestPwa/docs/DocumentacaoFuncionalSistema.md) | Especificação completa de UX: layout por tela, estados visuais, frases por fase, props de componente, edge cases, gestos, haptics, acessibilidade | Primário |
| [`DocumentacaoTecnicaSistema.md`](../linkaSpeedtestPwa/docs/DocumentacaoTecnicaSistema.md) | Arquitetura técnica: tipos TypeScript, Motor v2 (algoritmos DL/UL/latência), hooks, utils, classifier, interpret, anatelColor, deploy | Primário |

### Índice e Navegação

| Documento | O que cobre |
|---|---|
| [`DOCUMENTACAO_CONSOLIDADA.md`](../linkaSpeedtestPwa/docs/DOCUMENTACAO_CONSOLIDADA.md) | Índice local PWA com histórico de decisões — leia antes de iniciar task no PWA |

### Inventário (complementar — orientação rápida)

| Documento | O que cobre |
|---|---|
| [`SCREENS_PWA.md`](../linkaSpeedtestPwa/docs/SCREENS_PWA.md) | Tabela de 17 telas com arquivo, rota e propósito |
| [`COMPONENTS_PWA.md`](../linkaSpeedtestPwa/docs/COMPONENTS_PWA.md) | Tabela de 27 componentes agrupados por domínio |

### Design e Branding

| Documento | O que cobre |
|---|---|
| [`GuiaBranding.md`](../linkaSpeedtestPwa/docs/GuiaBranding.md) | Identidade visual PWA: cores, tipografia, componentes iOS-Calma |
| [`EvolucaoTelaDesktop.md`](../linkaSpeedtestPwa/docs/EvolucaoTelaDesktop.md) | Design de telas desktop, responsividade |

### Operacional e Deploy

| Documento | O que cobre |
|---|---|
| [`CI-CD.md`](../linkaSpeedtestPwa/docs/CI-CD.md) | GitHub Actions, Cloudflare Pages, secrets, deploy |
| [`GuiaFluxoGit.md`](../linkaSpeedtestPwa/docs/GuiaFluxoGit.md) | Protocolo Git para o PWA |
| [`GuiaOrganizacaoPastas.md`](../linkaSpeedtestPwa/docs/GuiaOrganizacaoPastas.md) | Estrutura de pastas, naming conventions |
| [`PoliticaBranchUnico.md`](../linkaSpeedtestPwa/docs/PoliticaBranchUnico.md) | Política: trabalhar sempre em `main` |

### Roadmap e Planejamento de Produto

| Documento | O que cobre | Nota |
|---|---|---|
| [`EvolucaoSpeedTest.md`](../linkaSpeedtestPwa/docs/EvolucaoSpeedTest.md) | Roadmap de produto: 9 features em 4 fases (Teste rápido/completo, Prova Real, Teste por local, Modo Gamer, etc.) | Não implementado — planejamento ativo |
| [`RecomendacaoEquipamentos.md`](../linkaSpeedtestPwa/docs/RecomendacaoEquipamentos.md) | Plano de monetização: recomendações automáticas de equipamentos com links afiliados | Feature futura (Fase 10) |
| [`PendenciasLayout.md`](../linkaSpeedtestPwa/docs/PendenciasLayout.md) | Briefing UX detalhado: melhorias de layout, microcopy, consistência visual por tela | Backlog ativo com critérios de aceite |

### Contratos e Integrações

| Documento | O que cobre |
|---|---|
| [`CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1.md`](../linkaSpeedtestPwa/docs/CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1.md) | Contrato entre motor de diagnóstico e motor de recomendações |
| [`DiagnosticoWifiNativo.md`](../linkaSpeedtestPwa/docs/DiagnosticoWifiNativo.md) | Diagnóstico Wi-Fi nativo no PWA (limitações de browser) |

### Avaliação de Paridade

| Documento | O que cobre |
|---|---|
| [`ORB-151_Avaliacao_Tecnica_Paridade_PWA_Android.md`](../linkaSpeedtestPwa/docs/ORB-151_Avaliacao_Tecnica_Paridade_PWA_Android.md) | Inventário técnico PWA, mapa PWA→Android, proposta de design tokens, isolamento do motor |

### Feature Specs (especificações de features não implementadas)

| Documento | O que cobre | Nota |
|---|---|---|
| [`Feature iOS - Obter Dados WiFi via Atalho.md`](../linkaSpeedtestPwa/docs/Feature%20iOS%20-%20Obter%20Dados%20WiFi%20via%20Atalho.md) | Spec técnica: integração iOS Shortcuts para coletar contexto Wi-Fi no iPhone | **Implementado em v1.3.0** — `WifiContextCard.tsx` + `wifiShortcut.ts`; integrado em `App.tsx`, `ResultScreen.tsx`, `StartScreen.tsx` |

---

## 4. Wireframes

**Status: não existem documentos visuais atualizados.**

- `linkaAndroidKotlin/docs_ai/wireframes/` — diretório criado, README era placeholder sem conteúdo real. Arquivado em `.old/` em 2026-05-16.
- `linkaSpeedtestPwa/docs/` — sem wireframes.
- `docs/` — sem wireframes.

Nenhuma imagem, diagrama ou mockup visual existe no workspace. Os fluxos de tela estão documentados em texto e diagramas ASCII dentro dos monólitos (`DocumentacaoFuncionalSistema.md` para PWA e `functional/SCREENS_ANDROID.md` para Android).

**Gap registrado:** wireframes visuais de ambas as plataformas não existem. Para assessment, consultar os layouts ASCII em `DocumentacaoFuncionalSistema.md` (PWA) como substituto.

---

## 5. O que foi Arquivado (2026-05-17)

Auditoria de código Android completa — correções e novos docs:

| Ação | Arquivo | Motivo |
|---|---|---|
| Arquivado | `docs/.old/MATERIAL_DESIGN_3.2026-05-17.old.md` | Continha erro crítico: afirmava que Android usa Flutter/Dart. O app usa Kotlin/Compose. |
| Arquivado | `docs/.old/TECNICO_CROSSPLATFORM.2026-05-17.old.md` | Módulos marcados como "[não documentado]" e contagem incorreta (16 → 15 módulos). |
| Criado | `docs/ANDROID_TECNICO.md` | Documentação técnica Android detalhada — ancorada no código real. |
| Criado | `docs/ANDROID_FUNCIONAL.md` | Documentação funcional Android — telas, fluxos, features exclusivas. |
| Atualizado | `docs/MATERIAL_DESIGN_3.md` | Corrigido: stack Android é Kotlin/Compose, não Flutter/Dart. Path do tema corrigido. |
| Atualizado | `docs/TECNICO_CROSSPLATFORM.md` | Módulos documentados com dados reais do código. Contagem corrigida para 15. |
| Atualizado | `docs/VISAO_GERAL_LINKA.md` | Corrigido: 16 → 15 módulos. |
| Atualizado | `docs/INDICE.md` | Adicionados `ANDROID_TECNICO.md` e `ANDROID_FUNCIONAL.md`. |

**Erros corrigidos (críticos):**
- `MATERIAL_DESIGN_3.md` afirmava que Android usa Flutter/Dart — **errado**, é Kotlin/Compose
- `MATERIAL_DESIGN_3.md` referenciava path de arquivo `.dart` que não existe no módulo Android ativo
- `TECNICO_CROSSPLATFORM.md` afirmava 16 módulos — **errado**, são 15 (verificado em `settings.gradle.kts`)
- `CLAUDE.md` do workspace também menciona 16 módulos — não corrigido (fora do escopo de edição da Taisa; cabe ao usuário atualizar)

---

## 5-anterior. O que foi Arquivado (2026-05-16)

> **Atualização pós-release v0.7.1 / v1.3.0 (Waves 7A–7D):** Nenhum documento arquivado nesta atualização. Todos os documentos afetados foram atualizados in-place:
> - `docs/FUNCIONAL_CROSSPLATFORM.md` — versão, Fibra presets, OUI, Jitter→Oscilação, iOS WiFi Context
> - `docs/TECNICO_CROSSPLATFORM.md` — versão, build info, estrutura PWA
> - `linkaAndroidKotlin/linka-android-kotlin/CHANGELOG.md` — entrada v0.7.1
> - `linkaSpeedtestPwa/docs/COMPONENTS_PWA.md` — WifiContextCard (28 total)
> - `linkaSpeedtestPwa/docs/DOCUMENTACAO_CONSOLIDADA.md` — registro Wave 7, status iOS Feature
> - `linkaSpeedtestPwa/docs/SCREENS_PWA.md` — sem mudança (telas não alteradas)
> - `docs/INDICE.md` — status Feature iOS e versões



| Arquivo | Motivo |
|---|---|
| `linkaAndroidKotlin/docs_ai/wireframes/.old/README.2026-05-16.old.md` | Placeholder sem conteúdo real. Admitia explicitamente estar vazio. |
| `linkaAndroidKotlin/docs_ai/AUDIT_SUMMARY.2026-05-16.old.md` | Meta-documento de auditoria de sessão passada. Não é referência viva. Convertido em histórico. |
| `linkaSpeedtestPwa/docs/.old/Feature App - Scanner de Dispositivos.2026-05-16.old.md` | Spec de feature Android (Network Scanner) arquivada na pasta do PWA por engano. Escopo incorreto, plataforma incorreta. |
| `docs/.old/linka-docs.2026-05-16.old.html` | HTML de documentação navegável desatualizado: versão Android informada como v0.6.3 (atual v0.7.0), React 18 + Tailwind (atual sem Tailwind), 14 telas Android com nomenclatura defasada. |

---

## 6. Documentos já em `.old/` (arquivados anteriormente)

### `linkaAndroidKotlin/docs_ai/ai/.old/`
- `CONTEXT_POLICY.2026-05-16.old.md`
- `ENGINEERING_FLOW.2026-05-16.old.md`
- `HANDOFF_RULES.2026-05-16.old.md`
- `PRODUCT_FLOW.2026-05-16.old.md`
- `REVIEW_FLOW.2026-05-16.old.md`
- `TASK_BREAKDOWN.2026-05-16.old.md`
- `UX_FLOW.2026-05-16.old.md`

### `linkaAndroidKotlin/docs_ai/design-system/.old/`
- `CHAT_PATTERNS.2026-05-16.old.md`
- `MOTION.2026-05-16.old.md`
- `NAVIGATION.2026-05-16.old.md`

### `linkaAndroidKotlin/docs_ai/operations/.old/`
- `ORB-159_BATERIA_ANDROID.md`
- `ORB-159_CLOSEOUT.md`
- `ORB-159_PLAN.md`
- `ORB-159_VALIDACAO_QW1.md`
- `ORB-161_MEDICAO_REUSE_SPEEDTEST.md`
- `ORB-163_VALIDACAO_QW1_TELEFONIA.md`
- `ORB-165_MEDICAO_BOOT_WAKEUPS_QW3.md`

### `linkaSpeedtestPwa/docs/.old/`
- `Claude.linkaImplementacaoTecnica.2026-05-16.old.md`
- `PendenciasTecnicas.2026-05-16.old.md`
- `Feature App - Scanner de Dispositivos.2026-05-16.old.md` *(arquivado agora)*

---

## 7. Notas para Assessment

- **Ponto de entrada recomendado:** `docs/VISAO_GERAL_LINKA.md`
- **Especificação técnica Android mais completa:** `linkaAndroidKotlin/docs_ai/technical/ARCHITECTURE.md`
- **Especificação técnica PWA mais completa:** `linkaSpeedtestPwa/docs/DocumentacaoTecnicaSistema.md`
- **Cobertura de testes:** `docs/TESTES.md`
- **Decisões de design:** `docs/DESIGN_SYSTEM_CROSSPLATFORM.md` + `docs/MATERIAL_DESIGN_3.md`
- **Wireframes:** não existem — ver layouts ASCII em `linkaSpeedtestPwa/docs/DocumentacaoFuncionalSistema.md`
- **Roadmap PWA:** `linkaSpeedtestPwa/docs/EvolucaoSpeedTest.md`
