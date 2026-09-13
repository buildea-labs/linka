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
