# DSI de Arquitetura: Fundação Novo Linka

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
