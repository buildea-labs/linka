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
