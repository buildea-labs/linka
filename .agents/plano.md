# plano.md — Assist do Linka conectado ao motor de diagnóstico do SignallQ

**Trilha:** Full‑flow.
**Branch:** `feat/assist-signallq-diagnostic`.
**Autor do plano:** Giam. **Aprovado por Luiz na sessão de 2026-08-15.**

**Decisões da aprovação:**
- Opção A (reuso via HTTP). Sem port do `:core:diagnostico`.
- Ambos workers na v1: `signallq-diagnostic-worker` (regras) **e** `ai-diagnosis-worker` (laudo textual).
- Assist continua atrás do paywall Plus.
- Nome do package: **`NetworkDiagnostics`** (neutro).
- macOS usa `CoreWLAN` para SSID/BSSID/RSSI (não requer entitlement extra); no iPhone esses campos ficam `nil` e o worker trata.

**Divisão prática entre os dois workers:**
- **Assist (pergunta do usuário em PT-BR)** → `ai-diagnosis-worker`, que é conversacional e aceita `feedbackUsuario`. Endpoint: `POST /api/ai/diagnostico-conexao`. Schema v2.
- **Insight da Semana / síntese passiva** → `NetworkInsights` local (já existe, hoje órfão). Opcionalmente enriquecido pelo `signallq-diagnostic-worker` (regras determinísticas) quando o usuário tocar em "Perguntar ao Assist" com uma pergunta que peça diagnóstico estruturado — nesse caso o transport pode consultar os dois em cascata.

---

## Objetivo

Fazer o Assist do Linka Apple deixar de responder com heurística inline em Swift e passar a consultar o **mesmo cérebro de diagnóstico do SignallQ** — o Cloudflare Worker `signallq-diagnostic-worker`, hoje já consumido por SignallQ Android e SignallQ Web. Complementarmente, permitir laudo em linguagem natural via `ai-diagnosis-worker` quando a superfície de UI pedir texto explicativo, não card estruturado.

Resultado esperado para o usuário: perguntar "por que meu Wi‑Fi está ruim?" no `HistoryView` retorna interpretação baseada em regras versionadas e mantidas centralmente, e não em `if/else` sobre strings PT‑BR.

## Contexto

**Assist no Linka hoje** (mapeado em conjunto por Explore em 2026-08-15):

- Existem em `aplicativo-ios/` os packages SwiftPM `NetworkAssist/`, `NetworkInsights/`, `MeasurementHistory/`, `NetworkCore/`, `LinkaEngine/`, `LinkaModules/`. Todos implementados.
- `NetworkAssist` já foi desenhado como contrato com **transport injetável** (`NetworkAssistTransport`). O único transport concreto é `UnconfiguredNetworkAssistTransport` (`NetworkAssist/Sources/NetworkAssist.swift:268`), que lança `.notConfigured`. O README do pacote diz explicitamente que "adapters futuros podem mapear `requiresDiagnosis` para a experiência de produto apropriada" — **o gancho pra plugar o cérebro externo já está lá.**
- `NetworkInsights` está implementado (comparação, estatística, tendência) mas **não é linkado no app**: falta em `LinkaModules/Package.swift`.
- A UI `AssistSheet` (`aplicativo-ios/LinkaApp/Sources/UI/AssistSheet.swift`) **não** usa `NetworkAssist`. Ela simula latência com `Task.sleep(800ms)` e gera resposta em `generateAlgorithmicResponse(for:history:)` com `if/else` sobre substrings PT‑BR. Isso é um fake que precisa sair.
- O card "Insight da Semana" no `HistoryView` mostra texto **hard‑coded** ("Sua conexão Wi‑Fi está 15% mais rápida nos últimos 3 dias.").
- Assist e Insight estão no `HistoryView`, atrás do paywall Plus. **Não** aparecem no primeiro frame do resultado. Coerente com o §6 do AGENTS.md.

**Cérebro do SignallQ hoje** (mapeado por Explore em 2026-08-15):

- O motor de diagnóstico "de verdade" — o que classifica, pontua, decide causa raiz — vive em `integrations/cloudflare/signallq-diagnostic-worker/` como **Cloudflare Worker**. Endpoint: `https://signallq-diagnostic.giammattey-luiz.workers.dev`.
- Rota principal: `POST /diagnostic/evaluate`. Payload: `DiagnosticSnapshot` schemaVersion 6. Retorno: `DiagnosticCard[]` prontos para UI (por área: wifi, internet, mobile, fibra). Rota auxiliar: `GET /providers/*` (diretório de ISPs por ASN — já sinergia com nosso `ProviderNormalizer`).
- **Tanto o SignallQ Android quanto o SignallQ Web consomem esse mesmo worker por contrato HTTP.** Não existe SDK compartilhado nem monorepo — a portabilidade é via JSON, e é assim que o próprio SignallQ já opera entre duas plataformas.
- O ruleset é versionado, publicado por painel admin (`/admin/*`, autenticado, não interessa ao Linka).
- Existe também `ai-diagnosis-worker` (`https://linka-ai-diagnosis-worker.giammattey-luiz.workers.dev`, `POST /api/ai/diagnostico-conexao`, com `?stream=true` SSE) que produz laudo textual com Gemini 2.0 Flash / Gemma via fallback. Retorno estruturado (`titulo`, `resumo`, `textoLaudo`, `problemaPrincipal`, `hipotesesDescartadas[]`, `acoesRecomendadas[]`).
- **Licença do SignallQ:** sem arquivo `LICENSE` — tratar como proprietário Buildea. Mesmo dono do Linka, então uso interno está OK, mas **o Linka Apple passa a ter dependência operacional de infra Cloudflare mantida pelo Buildea.** Isso é decisão de Luiz.

**Mudança no ecossistema (§1 e §13 do AGENTS.md):** com SignallQ agora Android/Web‑only, o Linka Apple pode absorver capacidades viáveis. Este plano é exatamente esse tipo de absorção — interpretação sobre medição, superfície secundária, sem competir com o resultado.

## Decisão de arquitetura

Três caminhos considerados:

- **A. Reuso operacional via HTTP** — Linka monta `DiagnosticSnapshot` v6 com o que consegue coletar no Apple e chama o Worker. Zero código de regra duplicado. Se SignallQ evoluir o ruleset, o Linka herda automaticamente.
- **B. Port do `:core:diagnostico` Kotlin puro para Swift package** — engines, thresholds, `ScoreEngine`, `FindingEngine`, `MetricClassifier` viram Swift. Alto custo, drift entre Android e Apple garantido no tempo, duplica manutenção de regras. Só se justifica se offline for requisito duro.
- **C. Híbrido** — chamar o Worker online e cachear última resposta pra degradar offline. Escopo maior que A. Adiar até haver dor real de offline.

**Recomendação: A.** Fiel ao §1 ("Só entra o que se sustenta em dado real. Interpretação e recomendação precisam de base medida ou de dado do sistema") e ao §8 ("não duplique lógica"). Custo baixo, ganho grande, alinhado ao modelo que Android e Web já usam.

## Mudança arquitetural

- **Novo package SwiftPM `NetworkDiagnosticsRemote/`** em `aplicativo-ios/`, dependência de `NetworkCore` e `MeasurementHistory`. Responsabilidades:
  - `DiagnosticSnapshotBuilder` — monta `DiagnosticSnapshot` schemaVersion 6 a partir da última `NetworkMeasurement` + histórico + sinais do sistema que o Apple expõe (`NWPathMonitor` já em uso; `CoreTelephony` para portadora básica no iPhone; `CoreWLAN` para SSID/BSSID/RSSI **só no macOS**). Aceita explicitamente que iOS público não dá RSSI móvel nem scan Wi‑Fi vizinho — campos ausentes ficam `nil`, o worker já trata.
  - `SignallqDiagnosticTransport: NetworkAssistTransport` — implementa o contrato existente. Chama `POST /diagnostic/evaluate` e converte `DiagnosticCard[]` em `NetworkAssistResponse` (com `evidence` derivada dos campos do card).
  - `SignallqAiDiagnosticTransport: NetworkAssistTransport` (opcional, atrás de flag) — variante que consulta `ai-diagnosis-worker` quando a superfície de UI pedir laudo textual longo em vez de card. Não é obrigatório na v1.
  - Config: base URL do worker em `Info.plist` (via `.xcconfig`), não hard‑coded. Sem chave — a rota `/diagnostic/evaluate` é aberta ao app. Nenhum segredo entra em bundle.
- **`NetworkAssist`** — nada muda no contrato público. Só passamos a instanciar `NetworkAssistService(transport: SignallqDiagnosticTransport(...))` no wiring do app.
- **`LinkaModules/Package.swift`** — passa a incluir `NetworkInsights` (hoje órfão) e o novo `NetworkDiagnosticsRemote`. `LinkaModules/Sources/Assist.swift` continua reexportando os typealiases.
- **UI**:
  - `AssistSheet.swift` — remove `generateAlgorithmicResponse` e `Task.sleep`. Passa a chamar `NetworkAssistProviding.answer(_:)` do container. Estados vazios/erro tratados (`insufficientEvidence`, `requiresDiagnosis`, `unsupported`, e falha de rede) — mensagens sinceras, sem inventar resultado.
  - `HistoryView.swift` — o card "Insight da Semana" passa a ser alimentado por `NetworkInsightsAnalyzing` (que hoje existe e não é usado). Nada de valor cravado.
  - `MainView` (primeiro frame do resultado) — **não muda**. Assist e Insight continuam em superfície secundária, protegidos pela política do §6.
- **Feature flag** — o novo transport entra atrás de flag simples em `AppEnvironment` (`assistUsesRemoteDiagnostic: Bool`). Default `true` em debug, `false` em release inicial até validar em campo. Sem framework de flags novo.

## Escopo v1

Cobre apenas:
1. Wiring `NetworkAssist` real com transport remoto — substituindo o fake do `AssistSheet`.
2. Alimentação do card "Insight da Semana" com dados reais via `NetworkInsights` (que já existe).
3. Coleta apenas do que Apple público expõe hoje sem entitlement novo: métricas do `LinkaEngine` (down/up/ping/jitter/perda), tipo de conexão via `NWPathMonitor`, ISP normalizado via `ProviderNormalizer`. iPhone: portadora via `CoreTelephony`. Mac: SSID/BSSID/RSSI via `CoreWLAN` (Mac já expõe sem entitlement extra).
4. Uma flag `assistUsesRemoteDiagnostic`.
5. Testes unitários do `DiagnosticSnapshotBuilder` (fixtures) e do parser da resposta do worker. Um teste de integração hitando o worker fica **atrás de env var** e roda só sob demanda — nunca em CI padrão.

## Não‑objetivo

- Port de `:core:diagnostico` para Swift.
- Ingestão de telemetria do Linka no `signallq-admin-worker` (Bearer key não vai pro cliente Apple, ponto).
- Nova permissão/entitlement Apple (nada de `NEHotspotHelper`, `Location Always`, `CoreLocation` só pra SSID no iOS).
- Scan de canais Wi‑Fi vizinhos (não existe no iOS público).
- RSSI móvel (iOS não expõe).
- Widget/App Intents/Siri Shortcuts consumindo Assist — vira plano separado se der certo.
- Assist no primeiro frame do resultado.
- Modo offline com cache de última resposta (fica pra uma v2 se aparecer demanda).
- Streaming SSE do `ai-diagnosis-worker` — v1 usa só resposta única (ou nem usa AI, se ficarmos só no worker de regras).
- Substituir motor do LinkaEngine ou tocar em `SpeedTestCore`.

## Requisito de aceite

- `AssistSheet` para de usar `generateAlgorithmicResponse`; passa a mostrar resposta do worker quando `assistUsesRemoteDiagnostic == true`, e mostra estado "indisponível" honesto quando não consegue chamar.
- Card "Insight da Semana" no `HistoryView` deixa de mostrar texto fixo; passa a mostrar tendência real vinda de `NetworkInsights` sobre a base local de medições, ou some se não houver dados suficientes.
- `NetworkInsights` passa a ser dependência real de `LinkaModules`.
- Nenhuma chamada de rede nova acontece antes do usuário abrir Assist ou Histórico — nada no fluxo `ABRIR → MEDIR → MOSTRAR`.
- `swift test` dos packages tocados passa. Build do target `LinkaApp` passa em iOS 16 e macOS 13 alvos.
- Sem segredo em bundle. `Info.plist` documentado. URL do worker configurável.
- Fluxo golden manual: rodar um teste no simulador iPhone, abrir Histórico, tocar "Perguntar ao Assist", fazer uma pergunta sugerida, receber resposta baseada em card real. Rodar mesmo fluxo no Mac.
- Fallback: com o worker fora do ar, o app não trava e o Assist mostra "não foi possível diagnosticar agora".
- Primeiro frame do resultado (`MainView`) inalterado — auditar visualmente contra o protótipo canônico.

## Riscos

- **Dependência operacional externa** — Linka Apple passa a depender de infra Cloudflare mantida pelo Buildea. Se o worker cair, Assist cai. Mitigação: degradação silenciosa; nada no fluxo principal de medição depende disso.
- **Contrato v6 pode evoluir** — mitigação: cliente Swift envia `schemaVersion` explícito; se o worker responder incompatível, tratamos como "indisponível" em vez de renderizar lixo. Alinhar com quem mantém o worker antes de mudanças breaking.
- **Sinais Apple magrinhos** vs. o que o worker foi pensado para receber (Android manda RSSI, RSRP, RSRQ, SNR, scan de canais). Boa parte dos cards que o worker gera para SignallQ Android **não vai iluminar no Apple** — o worker precisa aceitar snapshot mínimo e devolver "sem evidência" em vez de card falso. Confirmar antes de sair implementando.
- **Licença/autorização** — SignallQ é proprietário Buildea, sem `LICENSE` no repo. Mesmo dono, ok tecnicamente, mas o Luiz precisa dizer explicitamente "sim, o Linka Apple pode consumir esse worker em produção". Este plano **não** presume esse "sim".
- **Latência percebida** — Assist passa a depender de round‑trip HTTPS. Aceitável porque é ação explícita do usuário (toca botão). Mitigação: skeleton/estado de carregamento honesto, timeout curto (~8s) com mensagem clara.
- **Privacidade** (§10) — snapshot inclui métricas de rede e provedor. Isso já sai do dispositivo hoje para `speed.cloudflare.com` e `ipinfo.io`. O novo destino é um worker do próprio Buildea. Nada de identificador de dispositivo, nada de localização precisa. Documentar em política pública antes de release.

## Perguntas abertas pro Luiz antes de aprovar

1. **Autorização de dependência.** OK o Linka Apple entrar em produção falando com o worker `signallq-diagnostic` mantido pelo Buildea? Alguma SLA/contrato interno que precise formalizar?
2. **Ordem de entrega:** só o worker de regras na v1, ou já entra também o `ai-diagnosis-worker` para laudo textual? Recomendação: só regras na v1 — mais barato, mais determinístico, mais alinhado à precisão do §6.
3. **Paywall.** Manter Assist atrás do `hasPlus` como está hoje, ou tornar Assist gratuito e reservar apenas features futuras (Widget, Siri, laudo AI) ao Plus?
4. **Coleta no Mac.** OK usar `CoreWLAN` para SSID/RSSI no macOS (não requer entitlement extra), aceitando que no iPhone esses campos ficam `nil`?
5. **Nomeclatura do package.** `NetworkDiagnosticsRemote` te agrada, ou prefere `SignallqDiagnostics` explícito, ou algo neutro tipo `NetworkDiagnostics`?

## Notas do Guinho pra Marcelo (quando o plano for aprovado)

- Auditoria: garantir que `MainView` não ganhou nenhum consumo novo. Diff visual contra protótipo.
- Fuzzing do parser da resposta do worker (JSON parcial, campos desconhecidos, `schemaVersion` maior).
- Cenário de rede ruim: cortar Wi‑Fi durante request do Assist, garantir que UI não trava nem mente.
- Verificar que `Info.plist` não contém segredo. Verificar que a URL do worker não vaza para logs.
- Rodar `swift test` em todos os packages tocados. Build no target `LinkaApp` para os dois SDKs.
