# Architecture Plan: RealtimeNetworkMonitor (V3)

## 1. Contexto e Problema
A interface do Mac ("Sua rede agora") exibirá métricas de rede (latência, perda de pacotes e força do sinal Wi-Fi) de forma contínua, mesmo fora de um SpeedTest completo. O motor principal (`LinkaEngine`) é pesado e otimizado para a medição principal, não para polling contínuo.

## 2. Decisão de Produto (Íris)
**Objetivo:** Permitir acompanhamento rápido e contínuo da estabilidade atual sem rodar o teste completo.
**Não-objetivos:**
- Não se tornar um "dashboard" primário. A medição oficial continua sendo a atração principal.
- Não competir com o SpeedTest: o monitoramento DEVE ser pausado assim que um teste real inicia (`isTesting == true`).
- Nenhuma persistência no `MeasurementHistory`. São apenas dados efêmeros de interface.

## 3. Solução Técnica Proposta (Camillo & Claude Code)
Em vez de criar pacotes isolados ou protocolos complexos, o monitoramento será construído aproveitando a arquitetura existente no próprio **`SpeedTestViewModel`** (pacote `LinkaApp`).

**Decisões:**
- **Reuso Inteligente:** O método `refreshLiveNetwork()` do `SpeedTestViewModel` será estendido para virar um "polling" periódico.
- **Leitura do Wi-Fi (CoreWLAN):** O `ApplePlatformSignalProvider` será chamado via polling para atualizar o RSSI apenas no macOS (sem prompts de privacidade de Local Network).
- **Mecanismo de Ping:** Devido à Sandbox da App Store, não faremos sockets ICMP/UDP diretos. Utilizaremos uma sondagem leve HTTP (padrão já usado por `SpeedTestCore.performPingTest()`) contra um host público para obter DNS, latência e estimativa de perda. Nunca pingaremos o Gateway local automaticamente para evitar o prompt invasivo do "Local Network Privacy".
- **Gestão de Energia (Background):** A sondagem será amarrada ao `handleScenePhaseChange`. Se o app for minimizado ou sair de cena, o timer de polling será destruído (economia de bateria/dados).

## 4. Módulos Afetados
- **Modificado:** `LinkaApp/Sources/Adapters/SpeedTestViewModel.swift` (Inclusão do `Timer` assíncrono e novos `Published` properties para os dados efêmeros).
- **Modificado:** `LinkaApp/Sources/Adapters/ApplePlatformSignalProvider.swift` (apenas para garantir que ele atende chamadas contínuas).
- **Modificado:** Arquivos visuais do Mac (`MacMainView.swift`) para consumir os novos valores do ViewModel.

## 5. Escopo e Limitações
- **Plataforma:** iOS retornará `nil` para RSSI (comportamento nativo documentado). O monitoramento focará no Mac.
- **Falhas de Rede:** Se a resolução DNS falhar, o serviço degradará graciosamente sem bloquear a UI e assumirá `perda == 100%`.

## 6. Testes
- Adição de cenários no `LinkaApp/Tests/` para validar se o timer é pausado quando `isTesting` é ativado e quando a Scene sai de foco, além do fail-soft caso as permissões Wi-Fi sejam revogadas no macOS.

# V4 - Redesign Mac e Metadata de Origem

## 1. Contexto e Problema
O usuário aprovou o redesign da `MacMainView`: remoção do Gauge, adoção de layout "Hero Horizontal" para Download/Upload, inclusão do painel de Adequação de Uso (`UsageSuitability`) e metadados de Wi-Fi no rodapé.
O histórico também passa a exibir a origem da medição (Mac ou iOS). Isso exige inclusão de plataforma na persistência do modelo de rede (`NetworkMeasurement`), o que afeta o CloudKit e exige cautela.

## 2. Decisão de Arquitetura (Camillo)
- **Modelagem Aditiva (`NetworkCore`):** A estrutura `NetworkMeasurement` receberá a propriedade `devicePlatform: String?` (ou um Enum suportado nativamente com fallback nulo). Para evitar quebras no parse do CloudKit de dados existentes, a decodificação precisará tratar a ausência deste campo, fornecendo retrocompatibilidade absoluta (Legacy-decode).
- **Separação UI / Core:** A nova `MacMainView` deve consumir estados expostos pelo ViewModel, sem processar regras de adequação na camada visual. Os módulos `NetworkInsights` ou `NetworkAssist` podem ser utilizados, mas o ViewModel será a fachada para a View.

## 3. Módulos Afetados
- **`NetworkCore`**: Alteração no modelo `NetworkMeasurement` para incluir a plataforma. Atualização do `Codable` manual ou adequação com defaults.
- **`MeasurementHistory`**: Adaptação da visualização do histórico de testes para exibir o ícone/tag da origem do teste.
- **`LinkaApp` / macOS UI**: 
  - `MacMainView.swift`: Remover o Gauge; implementar Hero Horizontal de Download/Upload, o painel `UsageSuitability` e rodapé de metadados Wi-Fi.
  - `SpeedTestViewModel.swift` (ou análogo): Expor o `UsageSuitability` e a `devicePlatform` da medição para a camada da interface.

## 4. Plano de Testes
**Testes de Unidade (`swift test`):**
- **Legacy-decode Test (`NetworkCore`):** Testar o comportamento do parser `JSONDecoder` (ou parser específico de CloudKit Record) contra dados de medições passadas onde a key `devicePlatform` está ausente. Garantir que ele mapeia como `nil` ou fallback default sem crashar.
- **Model Tests (`NetworkCore`):** Garantir que a geração de novas medições (encoding) contém o campo populado corretamente via `ProcessInfo` ou `UIDevice`/framework local.
- **ViewModel Tests (`LinkaApp`):** Validar a amarração (binding) da Adequação de Uso para a UI.

**Testes Manuais na Esteira:**
- Realizar teste no macOS e iOS usando as mesmas credenciais do iCloud.
- Validar se o CloudKit sincroniza a nova medição e exibe os ícones corretos de origem no Histórico.
- Verificar o visual da `MacMainView` (Gauge removido, UI de "Hero Horizontal", painel e rodapé funcionando corretamente em redimensionamento e Dark Mode).

---

# Architecture Plan — Home iOS viva, uma única verdade

## 1. Problema

A Home já tem dados vivos, mas exibe duas leituras independentes: o hero usa
`LinkaHealthCheck` (`NWPathMonitor` e ping próprio); os casos de uso usam
`LiveTelemetryCollector` e `LiveUsageSuitabilityEvaluator` (janela atualizada
a cada 3 segundos). Elas podem discordar para a pessoa usuária.

A base de throughput também não é segura hoje: a busca parte do SSID atual,
enquanto medições persistidas gravam `networkIdentifier` como provedor; e a
baseline em memória não é invalidada na troca de rede ou volta do background.

## 2. Comportamento desejado

A pessoa abre a Home e entende se está conectada, se a conexão está
respondendo agora e se o uso escolhido é adequado. Hero e cards refletem a
mesma janela de evidência. A velocidade continua sendo medida apenas por ação
explícita; não há modo novo nem medição pesada em segundo plano.

## 3. Decisão

- `liveUsageReport` passa a ser a fonte única do estado idle da Home.
- A baseline de throughput é efêmera e só é elegível para Wi-Fi com SSID atual
  disponível, teste completo, upload disponível e idade máxima de quatro horas.
- A busca compara `measurement.wifiContext?.ssid`, nunca `provider`/
  `networkIdentifier`.
- Sem identidade Wi-Fi confiável, a interface pede uma medição para confirmar
  upload; não infere throughput.
- Não há schema novo, persistência de telemetria, mudança no LinkaEngine,
  CloudKit nem novo modo de teste.

```text
NWPathMonitor + sonda leve (3 s)
           ↓
LiveNetworkTelemetrySnapshot ← baseline de teste completo no mesmo SSID
           ↓
LiveUsageSuitabilityReport
           ↓
Hero + usos + CTA contextual
```

## 4. Módulos e contratos

- `LinkaApp/Sources/Adapters/SpeedTestViewModel.swift`
  - centraliza a chave efêmera de baseline (SSID Wi-Fi ou indisponível);
  - ao trocar a chave, entrar em background/voltar ativo ou perder a rota,
    limpa buffer, baseline e relatório antes de novo polling;
  - após teste concluído, só publica baseline quando a identidade Wi-Fi
    efetivamente associada à medição existir;
  - preserva pausa do polling enquanto `isTesting`.
- `LinkaModules/Sources/LiveTelemetryCollector.swift`
  - recebe uma identidade/predicado tipado de baseline e filtra histórico por
    `wifiContext.ssid`, resultado completo e TTL; `ThroughputBaseline` segue
    apenas em memória.
- `LinkaApp/Sources/UI/MainView.swift`
  - deriva hero de `liveConnectionKind` e `liveUsageReport`, não de
    `LinkaHealthCheck`;
  - conecta `LiveUsageCasesView.onSelect`: ausência de throughput ajusta o
    rótulo do único CTA para a intenção, por exemplo “Medir para chamada em
    vídeo”, mantendo `startSpeedTest()` inalterado;
  - mantém origem/confiança em detalhe sob toque, não no hero.
- `LinkaApp/Sources/UI/LiveUsageCasesView.swift` e
  `UsageSuitabilityCopy.swift`
  - só apresentam estados/copy acessível: aquecendo, “estável agora”,
    “com base no último teste desta rede” e pedido de medição.
- `LinkaHealthCheck.swift`
  - fica fora da Home neste escopo; remoção/realocação só após verificar
    consumidores remanescentes, em mudança separada.

## 5. Estados da Home

| Estado | Condição | Leitura |
|---|---|---|
| offline | rota não satisfeita | Sem conexão; não há veredito de uso |
| aquecendo | rota ativa, menos de três amostras | Avaliando sua conexão |
| ao vivo | janela válida | Hero e jogo usam latência, jitter e perda atuais |
| baseline elegível | teste completo, <=4 h, mesmo SSID | Vídeo combina estado atual e upload da rede |
| sem baseline | SSID ausente/trocado, expirado ou sem upload | Medir para confirmar upload |
| medindo | `isTesting` | Polling suspenso; fluxo de medição é soberano |

## 6. Falhas, privacidade e compatibilidade

- Falha/timeout de sonda vira perda na janela, nunca zero ou estado saudável.
- Troca de rede invalida dados derivados antes de qualquer novo veredito.
- SSID só é usado quando a plataforma já o disponibiliza; não há BSSID cru,
  novo identificador persistente ou envio remoto.
- Histórico legado continua visível, porém registros sem SSID não são baseline.
- iPhone/iPad não inventam RSSI nem velocidade de enlace; macOS preserva os
  fatos de plataforma disponíveis.

## 7. Verificação

- `LiveTelemetryCollectorTests`: baseline só para mesmo SSID, resultado
  completo, upload presente e dentro do TTL; ignora provider, SSID diferente e
  dados expirados.
- `SpeedTestViewModel`/app tests: troca de SSID e retorno ativo limpam estado;
  conclusão habilita baseline só com SSID consistente; CTA contextual dispara a
  mesma medição.
- `LiveUsageSuitabilityTests`: cobertura de baseline expirada e preservação da
  avaliação determinística.
- Validação manual iPhone: aquecimento, troca de rede, background/retorno,
  offline, vídeo sem/com teste recente e acessibilidade (Dynamic Type,
  VoiceOver, reduzir movimento).

## 8. Riscos e não-objetivos

Uma troca de rede força alguns segundos de aquecimento — preferência explícita
por honestidade em vez de confiança herdada. Não são objetivos: medir banda
continuamente, diagnosticar topologia mesh, atribuir causa a roteador/provedor
ou alterar o algoritmo do speed test.

---

# Architecture Plan — Home iOS fluida e Histórico #236

# Architecture Plan — Responsividade sob carga de alta confiança

## OBJETIVO

Elevar a medição de responsividade sob carga do Linka sem alterar o fluxo
`ABRIR → MEDIR → RESULTADO → REPETIR`: produzir um veredito apenas quando a
evidência de baseline, carga sustentada e sondagem por direção for válida.

## COMPORTAMENTO ESPERADO

- A velocidade continua sendo o resultado principal; não há modo novo, WebView,
  SDK de terceiros, Worker próprio ou CTA extra.
- Detalhes apresenta responsividade em repouso, download e upload somente como
  fatos medidos. Ausência/insuficiência vira “não avaliada”, nunca zero ou
  categoria saudável.
- O resultado geral exige baseline e as duas direções válidas. Uma direção
  isolada pode aparecer como fato parcial, mas não gera veredito geral,
  tendência, Assist ou otimização.
- Histórico preserva a metodologia da época: dados legados seguem legados e
  não ganham classificação de alta confiança retroativamente.

## MUDANÇA TÉCNICA

- `LinkaEngine`: introduzir ambiente/transporte injetável para os endpoints
  Cloudflare existentes; coletar baseline por mediana após warm-up e evidência
  por direção somente depois de carga sustentada. A janela de responsividade
  tem duração útil fixa independente da convergência da vazão. Ponto inicial
  para calibração: até 18 s por direção, com ao menos 10 s úteis; números não
  viram promessa pública antes de teste físico.
- `NetworkCore`: adicionar envelope opcional e versionado
  `loadResponsiveness`, com resumo de baseline e de cada direção (mediana,
  p95, máximo, amostras, timeouts, warm-up, duração útil, bytes/vazão e estado
  de saturação), além de integridade tipada. Os escalares atuais permanecem
  como projeção compatível das medianas.
- `LinkaApp`: propagar `loadedLatencyUploadMs`, o envelope e a integridade do
  estado do engine até `NetworkMeasurement`.
- `MeasurementHistoryCloudKit`: sincronizar explicitamente upload e envelope;
  registros remotos antigos sem esses campos continuam decodificando.
- `NetworkInsights`: usar evidência v2 somente com integridade válida. O
  avaliador atual fica como apresentação de metodologia legada, sem promoção
  silenciosa de confiança.
- `NetworkDiagnostics`, Assist e Optimization mantêm payload/caminho existente
  nesta fatia; só consomem classificação v2 quando válida. Não ampliar NDS sem
  contrato remoto aditivo separado.

## ACEITE

- Baseline e carga usam o mesmo ambiente lógico Cloudflare; não se declara
  causalidade de roteador, ISP ou SQM.
- Sondas antes de carga sustentada não entram nas estatísticas de carga.
- Baseline contaminado ou materialmente invertido dispara uma única remedição
  ociosa; persistindo a falha, a integridade é inconclusiva.
- Falha/cancelamento/rede alterada preservam os fatos válidos de velocidade,
  mas nunca geram veredito de responsividade.
- JSON, FileHistory e CloudKit fazem round-trip de upload e do envelope novo;
  JSON/record legado continua aceito.
- Testes cobrem estatística, warm-up, saturação, perda, transições de
  integridade, transporte falso, adaptador, persistência, consumidores e
  compatibilidade.
- Validação física posterior cobre iPhone e Mac, Wi-Fi/celular e links lentos
  e rápidos; CI não é prova de saturação real ou comportamento de CDN.

## NÃO-OBJETIVOS

- Não integrar `@cloudflare/speedtest`, LibreSpeed, CoverageMap, widgets ou
  WebView.
- Não criar infraestrutura/Worker próprio nem mudar endpoint público nesta
  fatia.
- Não expor bufferbloat como nota, certificação ou diagnóstico causal.
- Não reclassificar histórico anterior com a metodologia nova.

## RISCOS / VALIDAÇÃO

- Mais tempo, dados e bateria; o progresso deve refletir extensão controlada e
  o cancelamento segue disponível.
- HTTP/CDN pode não sustentar a carga: isso é `uncertain`/inconclusivo, nunca
  ajuste silencioso.
- WIP preexistente em RouterDiscovery/localizações, xcscheme e `.worktrees/`
  é estritamente fora de escopo e deve permanecer intacto.

## OBJETIVO

Implementar a Home iOS aprovada: leitura viva limpa, trilha factual de rede e
cenários de uso sem transformar o Linka em dashboard ou speedtest puro. Corrigir
o Histórico da issue #236 para que controles não dominem a primeira dobra e uma
medição nunca seja apresentada como tendência.

## COMPORTAMENTO ESPERADO

- Home usa título grande nativo e uma única leitura principal derivada de
  `liveUsageReport`: `Avaliando conexão`, `Conexão estável`,
  `Conexão oscilando` ou `Sem conexão`.
- A linha verde é somente um sinal visual de monitoramento: não representa
  velocidade/ping, não tem escala e não é anunciada pelo VoiceOver. Fica
  estática com Reduzir Movimento e não fica verde fora de rota.
- A trilha `Este iPhone → rede atual → Internet` é leve e factual. A lista
  `Agora` tem Chamadas e Jogo online, com ícone de atividade à esquerda e
  check de condição à direita; detalhes vivem sob toque.
- Medir e Assist permanecem ações secundárias e agrupadas. Sem dado suficiente,
  não há check, velocidade estimada nem hero saudável herdado.
- Histórico move filtro/ordenação para controle discreto; com 0 não há gráfico,
  com 1 há resumo e mensagem honesta, e tendência só aparece com 2+ medições.

## MUDANÇA TÉCNICA

- Limitar a alteração à camada SwiftUI: `MainView.swift`,
  `LiveUsageCasesView.swift`, um componente local de sinal se necessário e
  `HistoryView.swift`, mais testes de estado/presentação extraíveis.
- Consumir os estados publicados existentes. Não alterar `SpeedTestViewModel`,
  `LiveTelemetryCollector`, `NetworkInsights`, LinkaEngine, persistência,
  CloudKit nem contratos.
- Extrair a decisão do estado de apresentação do histórico para cobertura de
  0/1/2 registros. No gráfico, empilhar título/período e legenda em largura
  compacta, sem apertar as métricas no mesmo `HStack`.

## ACEITE

- Home e Histórico exibem título grande no iPhone.
- VoiceOver identifica o estado da linha/cenários por texto e não por cor;
  alvo das linhas tem no mínimo 44 pt.
- Uma medição não renderiza card/eixos/série/arrasto de gráfico.
- Duas ou mais medições não inventam zero para métricas ausentes e seguem
  legíveis em iPhone compacto.

## NÃO-OBJETIVOS

- Não criar coleta contínua de velocidade, diagnóstico novo, tela nova ou CTA
  de medição adicional.
- Não inferir causa raiz, topologia ou qualidade de serviço específico.

## RISCOS / VALIDAÇÃO

- O hero não pode prometer estabilidade durante aquecimento/offline; o sinal
  visual precisa acompanhar exatamente a rota/estado vivo existente.
- Rodar testes de telemetria/insights já existentes, testes de apresentação
  novos, build/teste de simulador iOS e smoke visual em largura compacta com
  1 e 2 medições.
