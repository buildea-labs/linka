# Plano: paridade funcional iOS ↔ macOS

> **Trilha:** Full-flow | **Produto:** Íris | **Arquitetura:** Camillo | **Orquestração:** Codex

## Objetivo

Fazer do Linka para Mac o mesmo produto do iOS em capacidade e dados, sem
copiar a interface do iPhone. No macOS, recursos secundários entram por
sheet, painel ou detalhe nativo; medir continua sendo a ação principal.

Paridade não significa prometer hardware ou APIs inexistentes: rede móvel e
feedback háptico de iPhone não se aplicam ao MacBook. Wi-Fi avançado e acesso
ao roteador só entram depois de investigação das APIs e permissões do macOS.

## Arquitetura e decisão

`MainView` (iOS) e `MacMainView` (macOS) já compartilham
`SpeedTestViewModel`, `StoreKitEntitlementProvider`, `AppIntentCoordinator`,
`NetworkMeasurement` e o histórico persistido. A mudança deve reutilizar
essas fontes canônicas; não cria outro motor, modelo, repositório ou contrato.

```text
LinkaEngine → SpeedTestViewModel → NetworkMeasurement
                                  ├→ MeasurementHistoryRepository → histórico e detalhe
                                  ├→ NetworkInsights → uso e caminho da conexão
                                  ├→ ShareCardView → compartilhamento nativo
                                  └→ AppIntentCoordinator → ação no Mac
```

## Fases

### 0. Preservar o baseline atual

- Manter o WIP visual em `MacMainView.swift` isolado desta expansão.
- Confirmar os estados `idle`, `connecting`, `downloading`, `uploading`,
  `done`, erro, cancelamento e troca de rede.
- Medição continua explícita; Histórico e Ajustes não interrompem uma rodada;
  dado parcial, cancelado ou com falha não se apresenta como resultado.

### 1. Histórico e detalhe completos — P0

Arquivos principais: `MacMainView.swift`, `HistoryView.swift`,
`HistoricalMeasurementDetailView.swift` e `MeasurementDetailView.swift`.

- Reutilizar o histórico canônico no Mac, incluindo filtro, ordenação, limite,
  estado vazio, carregamento e Insights Plus.
- Abrir qualquer medição em detalhe nativo de Mac e permitir reteste depois de
  fechar a superfície de detalhe.
- Onde não houver dado aplicável ao Mac, como “Móvel”, omitir ou desabilitar
  honestamente; Wi-Fi e Ethernet permanecem suportados quando reais.

### 2. Resultado detalhado — P0/P1

Arquivos principais: `MacMainView.swift`, `MeasurementDetailView.swift`,
`UsageDiagnosticsView.swift`, `ConnectionPathView.swift` e
`ConnectionPathDetailView.swift`.

- Depois de uma medição concluída, expor progressivamente: detalhes,
  qualidade de uso, caminho da conexão, Assist, compartilhar e retestar.
- Reutilizar os avaliadores existentes de `NetworkInsights`; não criar nova
  inferência sobre operadora, roteador ou qualidade.
- Adaptar qualquer copy específica de iPhone para texto neutro de plataforma.
- Nenhuma ação recebe resultado parcial, cancelado ou em erro.

### 3. Compartilhamento nativo — P0

Arquivos principais: `ShareCardView.swift`, adaptador macOS pequeno quando
necessário e `MacMainView.swift`.

- Manter `ShareCardView` como fonte única de conteúdo e privacidade do cartão.
- Renderizar com `ImageRenderer` e apresentar com o mecanismo nativo macOS,
  sem tirar screenshot da janela.
- Disponibilizar somente para resultado concluído atual ou histórico.
- Falha de renderização não afirma compartilhamento nem expõe SSID, provedor,
  IP ou BSSID.

### 4. App Intents e Shortcuts — P1

Arquivos principais: `LinkaApp.swift`, `AppIntentCoordinator.swift`,
`LinkaAppShortcuts.swift`, `MacMainView.swift` e `LinkaAppIntents`.

- Consumir no Mac pedidos de iniciar teste, abrir Histórico, abrir a última
  medição e compra, respeitando Free/Plus e medição ativa.
- Conferir quais intents são efetivamente registrados no artefato macOS antes
  de prometer frases ou automações equivalentes.
- Não criar novo executor, armazenamento ou modelo de medição.

### 5. Wi-Fi avançado e roteador — P2, investigação antes de implementação

Arquivos de descoberta: `RouterDiscoveryView.swift`, `GatewayScanner`,
`SettingsSheet.swift`, entitlements e `project.yml`.

- Verificar APIs públicas para Wi-Fi, gateway e administração local no macOS,
  incluindo Sandbox, rede local, localização e permissões.
- Verificar se o fluxo de Atalhos do iOS tem equivalente real no Mac.
- Decidir por evidência: paridade direta, via Atalhos ou indisponibilidade
  honesta. Não portar código UIKit nem presumir suporte.

#### Decisão da investigação (12 set. 2026)

- **Wi-Fi avançado no Mac: paridade direta já é tecnicamente viável.** O
  adaptador canônico usa `CWWiFiClient.shared().interface()` — a API pública
  de CoreWLAN própria para App Sandbox — para obter SSID, BSSID, RSSI, taxa e
  banda. O entitlement de Wi-Fi e cliente de rede já pertencem ao alvo macOS.
  Não depende do Atalho iOS.
- **Gateway e caminho da conexão: paridade direta, condicionada a permissão.**
  `NWPath.gateways`, `NWPathMonitor` e `NWConnection` são APIs públicas. A
  partir do macOS 15, acesso à rede local pede consentimento explícito e a
  descrição de uso deve constar no Info.plist do alvo Mac. Validar em macOS 15+
  assinado, inclusive o estado de recusa.
- **Administração de roteador: não portar nesta fase.** A tela existente é
  somente UIKit, associa serviço Bonjour a fabricante por heurística e oferece
  guardar senha. Não é equivalente confiável nem uma boa extensão de escopo
  para o Mac. O Linka pode continuar mostrando o caminho confirmado; abrir o
  painel de administração só volta como jornada separada, sem salvar senha e
  com confirmação explícita.

## Critérios de aceite

- Uma medição histórica no Mac tem filtro, ordenação, detalhe completo e
  reteste; o resultado atual pode abrir as mesmas superfícies úteis do iOS.
- O compartilhamento usa interface nativa e cartão canônico, somente com dado
  finalizado e sem informação sensível por padrão.
- Uso, caminho da conexão, Assist e intents não competem visualmente com o
  número principal nem atrasam a medição.
- Sem regressão de erro, cancelamento, timeout, resultado parcial ou troca de
  rede; sem alteração no `LinkaEngine`, schema ou persistência.
- A experiência cabe e permanece acessível em 780×560, 1120×700 e janela
  ampla, com VoiceOver, teclado, Dark Mode e Dynamic Type.

## Validação

- `swift test` nos pacotes alterados e build macOS assinado para instalação.
- Jornada manual: abrir → medir → download → upload → resultado → detalhe →
  compartilhar → Assist → retestar; histórico vazio, filtros, ordenação e
  detalhe; erro, cancelamento, troca de rede e resultado parcial.
- Exercitar intents: iniciar, Histórico, última medição e gates Free/Plus.
- Não usar build sem assinatura como artefato de uso; ela serve apenas para
  checagem local de compilação, quando necessária.

## Não-objetivos

- Recriar o iOS visualmente no Mac ou transformar o resultado em dashboard.
- Mudar o motor, o contrato de medição, `NetworkMeasurement` ou a persistência.
- Prometer Wi-Fi avançado, roteador ou Shortcuts sem prova de plataforma.
- Merge, deploy, publicação ou mudança de credenciais.
