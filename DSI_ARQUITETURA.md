# DSI de Arquitetura: Fundação Novo Linka

> **Status: seções 1–3 SUPERADAS (confirmado em 2026-08-14).** O plano de reconstrução via
> Firebase (WebApp e Desktop) descrito abaixo **não é mais a direção do produto**. A autoridade
> vigente é `AGENTS.md` (raiz do repositório): Apple (iPhone/iPad/Mac) é a **única plataforma real**
> do produto; a Web é só landing page de marketing, sem motor de medição próprio; não há versão
> Android prevista. O caminho real é o app nativo Swift (`aplicativo-ios/LinkaApp` +
> `aplicativo-ios/LinkaEngine`), que já está em desenvolvimento ativo — build validado e funcional
> em 2026-08-14, monetização (Free/Plus, AdMob) já integrada. A **seção 4** deste documento
> (arquitetura Engine-Adapter-UI em SwiftUI) continua válida — é a descrição correta do que foi
> de fato implementado. Mantido aqui por histórico; não usar as seções 1–3 para orientar trabalho
> novo.

Este documento mapeia o estado atual do repositório `linka-speedtest` e define a estratégia de reaproveitamento para a construção da nova versão Apple-First (WebApp e Desktop via Firebase), conforme os novos protótipos.

## 1. Escopo e Objetivo
- **Destino:** Firebase (Web)
- **Foco:** WebApp e Desktop (Fase 1), mantendo a filosofia Apple-First.
- **O que muda:** Toda a camada de apresentação (UI) e orquestração de telas será reconstruída com base nos novos protótipos descompactados.
- **O que fica:** O "Motor" (Linka Engine) por trás das medições será blindado e reaproveitado para garantir a precisão de sempre.

## 2. Mapeamento do Repositório Atual

### 2.1. O que será REAPROVEITADO (Core Engine & Probes)
Esses módulos contêm a inteligência de rede, medição e diagnóstico que não dependem de UI. Eles serão movidos/adaptados para a nova fundação.

- `src/core/networkQualityClassifier.ts` - Classificador de qualidade da rede.
- `src/core/interpret.ts` - Interpretação dos dados de rede.
- `src/core/useCaseGrade.ts` - Notas e categorias de uso.
- `src/utils/latencyProbe.ts` - Probe de latência/ping.
- `src/utils/downloadProbe.ts` - Probe de download.
- `src/utils/uploadProbe.ts` - Probe de upload.
- `src/utils/packetLoss.ts` - Cálculo de perda de pacotes.
- `src/utils/speedTestOrchestrator.ts` - Orquestrador central do teste.
- `src/utils/cloudflareSpeedTest.ts` - Integração com infra da Cloudflare (se ainda usada).
- `src/utils/dnsProbe.ts` / `dnsTiming.ts` / `dnsBenchmark.ts` - Medidores de DNS.
- `src/utils/classifier.ts` - Utils genéricos de classificação.

### 2.2. O que será DESCARTADO ou TOTALMENTE REESCRITO (UI & Features Antigas)
A camada visual atual será trocada pelo novo Design System e protótipos Apple-First.

- `src/screens/*` (SpeedTestScreen, HomeScreen, HistoryScreen, etc.) - Vai pro lixo. Novas telas serão criadas com base nos protótipos.
- `src/components/*` (Botões, BottomSheets, Menus, Gauges) - Tudo substituído pelos novos componentes do Design System.
- `src/features/*` (local-network, pulse, local-wifi, ios-wifi-context) - A integração visual dessas features morre. A lógica que sobrar será encapsulada na nova interface.
- Arquivos CSS soltos (`*.css`) - Substituídos pela nova fundação de estilos e tokens do novo Design System.

### 2.3. O que já foi LIMPO (Ação do Marcelinho)
- Arquivos residuais do design anterior (`hub/docs/DESIGN_SYSTEM_CROSSPLATFORM.md`, `MATERIAL_DESIGN_3.md`).
- Mockups e screenshots de auditorias visuais antigas.
- Referências antigas de `.apk` e comandos da IA obsoletos.

## 3. Próximos Passos (Plano de Ação)
1. **Configuração Firebase:** Iniciar o projeto Firebase (Hosting/App Hosting) e configurar o SDK Admin Node.js recebido.
2. **Fundação Visual:** Implementar a raiz do CSS e design tokens a partir do `documentacao/design/design_system/`.
3. **Isolamento do Motor:** Criar a nova estrutura de pastas separando `engine/` (reaproveitado) da `ui/` (nova).
4. **Construção das Telas:** O Guinho assumirá a codificação dos componentes focando 100% no visual Apple-First ditado pelos protótipos.

## 4. Arquitetura do App Nativo iOS (SwiftUI + LinkaEngine)

Para garantir a filosofia Apple-First e o isolamento total entre lógica de rede e renderização gráfica, a arquitetura do app nativo adotará um modelo rígido de separação (Padrão Engine-Adapter-UI).

### 4.1. LinkaEngine (O Motor "Cego")
- **Isolamento de Domínio:** O motor será estruturado como um módulo independente (ou Swift Package interno). **É terminantemente proibido importar `SwiftUI` ou `UIKit` nesta camada.**
- **Concorrência Autônoma:** Toda a inteligência de sockets, testes de ping, download e upload rodará fora da Main Thread, utilizando **Swift Concurrency (`Actors` e `Task.detached`)**. Operações intensas de I/O da rede jamais disputarão processamento com o rendering visual.
- **Modelos de Dados Imutáveis:** O tráfego de resultados e estados da conexão (`MeasurementState`, `Phase`) usará `structs` imutáveis para evitar condições de corrida na memória (race conditions).

### 4.2. O Adapter e Throttling (Fluidez da UI)
- O problema clássico de medidores de velocidade é que as atualizações dos sockets ocorrem centenas de vezes por segundo, travando a Main Thread se refletidas de 1-para-1 na UI.
- **ViewModel/Adapter:** Teremos um `SpeedTestViewModel` (marcado obrigatoriamente com `@MainActor`) responsável por ouvir o fluxo contínuo de eventos do motor (via `AsyncStream` ou `Combine`).
- **Throttle Inteligente:** O Adapter limitará a taxa de atualização dos dados parciais emitidos para a View (ex: limitando o envio a ~20 ou 30 frames por segundo). Isso assegura que os ciclos de layout do SwiftUI não sejam sobrecarregados. O motor guarda e calcula 100% dos dados para precisão, mas a ponte filtra a entrega gráfica.

### 4.3. A Camada SwiftUI (A UI "Estúpida")
- As Views (`MainView`, `MetricRing`) apenas reagem às mudanças numéricas/estados do Adapter. Não existe nenhuma regra de cálculo de bits/bytes, conversão ou decisões lógicas nessas views.
- **Animações Interativas:** A interpolação fluida do anel e dos números parciais é totalmente delegada ao framework visual (`withAnimation` / modifiers do SwiftUI). A Engine lança os saltos de velocidade; a UI cria a transição sem "tremer".

### 4.4. Estrutura Proposta no Xcode
- `/LinkaEngine/`: `Core/`, `Probes/`, `Models/` (Exclusivamente lógica de rede).
- `/LinkaApp/Adapters/`: `SpeedTestViewModel.swift` (O canal seguro entre background e main thread).
- `/LinkaApp/UI/`: `Views/`, `Components/`, `DesignSystem/` (Exclusivamente visual).
