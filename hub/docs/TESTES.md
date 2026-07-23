# TESTES.md — Documentação de Testes do Ecossistema Linka

**Plataformas:** Android (Kotlin) + PWA (React/TypeScript)
**Atualizado em:** 2026-05-16
**Escopo:** Visão consolidada de cobertura, cenários críticos, como executar e lacunas conhecidas.

---

## 1. Matriz de Features por Plataforma

Legenda de status:
- `manual-ok` — testado manualmente, comportamento verificado
- `manual-nok` — sem verificação manual registrada
- `auto` — coberto por testes automatizados
- `sem-cobertura` — nenhum teste (manual ou automático) registrado

| Feature | Android | PWA |
|---|---|---|
| **Speedtest — motor de medição** | `auto` (SpeedtestQualityClassifierTest) | `auto` (speedtest.test.ts) |
| **Speedtest — classificação de qualidade** | `auto` (SpeedtestQualityClassifierTest) | `auto` (classifier.test.ts) |
| **Speedtest — perfil de conexão** | `sem-cobertura` | `auto` (connectionProfile.test.ts) |
| **Speedtest — cor Anatel** | `sem-cobertura` | `auto` (anatelColor.test.ts) |
| **Speedtest — resultado parcial upload** | `sem-cobertura` | `manual-nok` |
| **DNS — diagnóstico** | `auto` (DnsDiagnosticEngineTest) | `auto` (dnsProbe.test.ts, dnsTiming.test.ts) |
| **DNS — guia de configuração** | `sem-cobertura` | `sem-cobertura` |
| **Wi-Fi — scan de redes vizinhas** | `sem-cobertura` | N/A (API web limitada) |
| **Wi-Fi — band selection (ORB-202)** | `sem-cobertura` | N/A |
| **Wi-Fi — PHY rate display (ORB-203)** | `sem-cobertura` (bloqueado por ORB-195) | N/A |
| **Wi-Fi — MIMO label (ORB-204)** | `sem-cobertura` (bloqueado por ORB-195) | N/A |
| **Wi-Fi — mesh node (ORB-205)** | `sem-cobertura` | N/A |
| **Wi-Fi — diagnóstico de canal** | `auto` (WifiChannelDiagnosticEngineTest) | `auto` (LocalWifiService.test.ts, wifiSignal.test.ts) |
| **Diagnóstico — engine de internet** | `auto` (InternetDiagnosticEngineTest) | `auto` (combinedDiagnosis.test.ts) |
| **Diagnóstico — degradação histórica** | `auto` (HistoricalDegradationEngineTest) | `sem-cobertura` |
| **Diagnóstico — decision engine gateway** | `auto` (DiagnosticDecisionEngineGatewayTest) | `sem-cobertura` |
| **Diagnóstico — runner integração** | `auto` (DiagnosticRunnerIntegrationTest) | `sem-cobertura` |
| **Diagnóstico — perguntas dinâmicas (Pulse)** | `auto` (DynamicQuestionEngineTest) | `sem-cobertura` |
| **IA — repositório de diagnóstico AI** | `auto` (AiDiagnosisRepositoryTest) | `sem-cobertura` |
| **IA — contexto para AI** | `auto` (DiagnosisAiContextFactoryTest) | `sem-cobertura` |
| **IA — fallback factory** | `auto` (AiFallbackFactoryTest) | `sem-cobertura` |
| **Histórico — exportar CSV** | `auto` (ExportadorHistoricoCSVTest) | `sem-cobertura` |
| **Histórico — exportar PDF** | `auto` (ExportadorHistoricoPDFTest) | `sem-cobertura` |
| **Histórico — flow de exportação** | `auto` (ExportHistoricoFlowTest) | `sem-cobertura` |
| **Histórico — uptime chart** | `auto` (UptimeChartUseCaseTest, UptimeGridChartLogicTest) | `sem-cobertura` |
| **Histórico — narrativa de uptime** | `auto` (UptimeNarrativaEngineTest) | `sem-cobertura` |
| **Histórico — comparação de locais** | `sem-cobertura` | `auto` (compare.test.ts) |
| **Dispositivos — inferência tipo gateway** | `auto` (InferirTipoGatewayTest) | `sem-cobertura` |
| **Dispositivos — detecção device novo** | `auto` (DeteccaoDispositivoNovoTest) | `sem-cobertura` |
| **Dispositivos — registry de fabricantes** | `sem-cobertura` | `auto` (localNetworkRegistry.test.ts) |
| **Monitoramento — worker histérese** | `auto` (MonitoramentoWorkerHistereseTest) | N/A |
| **Monitoramento — worker medição** | `auto` (MonitoramentoWorkerMedicaoTest) | N/A |
| **Monitoramento — latência do gateway** | `auto` (GatewayLatencyMeasurerTest) | N/A |
| **Monitoramento — telefonia** | `auto` (MonitorTelephonyTest) | N/A |
| **Fibra** | `sem-cobertura` | N/A |
| **Configurações — persistência** | `sem-cobertura` | `sem-cobertura` |
| **Configurações — perfil gamer** | `sem-cobertura` | `sem-cobertura` |
| **Onboarding** | N/A | `sem-cobertura` |
| **Compartilhamento de resultado** | `sem-cobertura` | `auto` (share.test.ts) |
| **Scroll header** | `sem-cobertura` | `auto` (useScrollHeader.test.ts) |
| **Count-up animado** | `sem-cobertura` | `auto` (useCountUp.test.ts) |
| **Copy / microcopy** | `sem-cobertura` | `auto` (copyDictionary.test.ts) |
| **Canal de texto de diagnóstico** | `auto` (CanalTextGeneratorTest) | `sem-cobertura` |

---

## 2. Cenários Críticos de Regressão

Esses fluxos DEVEM ser testados manualmente antes de qualquer release, independente de cobertura automatizada.

### Golden Path — Android

1. **Fluxo completo de speedtest Wi-Fi**
   - Abrir app, conceder permissão de localização, iniciar teste em modo Completo em rede Wi-Fi 5GHz.
   - Verificar: download, upload, latência, jitter e packet loss são exibidos. Diagnóstico é gerado. Resultado é salvo no histórico.

2. **Fluxo speedtest em rede móvel (4G)**
   - Iniciar teste em modo Rápido com Wi-Fi desativado.
   - Verificar: upload usa estratégia adaptativa. Se upload falhar, resultado parcial é exibido (banner "Resultado parcial", upload mostra "—").

3. **Diagnóstico IA**
   - Executar speedtest com resultado ruim (baixa qualidade).
   - Verificar: diagnóstico de IA é gerado. Ações práticas são exibidas.

4. **Monitoramento em background (LinkaPulse)**
   - Ativar monitoramento contínuo. Aguardar 5+ minutos. Fechar app. Reabrir.
   - Verificar: medições foram realizadas em background. Histórico atualizado. Sem wakeup excessivo.

5. **Histórico — exportar CSV e PDF**
   - Com 10+ registros no histórico, exportar CSV. Exportar PDF.
   - Verificar: arquivos são gerados sem erro. CSV tem todos os campos. PDF é legível.

6. **Scanner de dispositivos**
   - Conectar em Wi-Fi com 2+ dispositivos. Abrir scanner.
   - Verificar: dispositivos são listados com fabricante inferido. Gateway identificado.

### Golden Path — PWA

1. **Fluxo completo de speedtest**
   - Abrir PWA no Chrome mobile. Iniciar teste em modo Completo.
   - Verificar: todas as fases (PING, DOWN, UP) executam. Resultado é exibido. Diagnóstico é gerado. Resultado salvo no localStorage.

2. **ResultScreen — card unificado**
   - Após speedtest, verificar: ribbon de verdict (verde/amarelo/vermelho) aparece. Valores de DL e UL animam com count-up. Blocos SECONDARY (resposta, oscilação, falhas, DNS) aparecem. Use cases (Jogos, 4K, Office, Vídeo) são exibidos.

3. **Bottom sheets — drag-to-resize**
   - Na ResultScreen, tocar em "Avançado", "Modo Gamer" e "DNS".
   - Verificar: cada bottom sheet abre com drag handle. Drag para cima expande. Drag para baixo fecha.

4. **Pull-to-refresh**
   - Na StartScreen e HistoryScreen, puxar tela para baixo.
   - Verificar: spinner aparece progressivamente. Ao soltar acima do threshold, IP/ISP/tipo de conexão são re-fetched.

5. **Onboarding — primeira execução**
   - Limpar localStorage. Abrir PWA.
   - Verificar: overlay de onboarding aparece. 3 cards navegam via swipe e dots. "Pular" fecha overlay. Flag é gravada. Na próxima abertura, overlay NÃO aparece.

6. **Histórico — persistência e exportação**
   - Executar 3+ testes. Verificar histórico lista todos. Exportar como texto/compartilhar.
   - Verificar: dados persistem após fechar e reabrir o browser.

7. **PWA offline**
   - Desativar rede. Abrir PWA.
   - Verificar: app carrega (Service Worker). Botão "Iniciar" fica desabilitado. Mensagem "Sem conexão" aparece sem botão de retry.

---

## 3. Como Executar os Testes

### Android (Kotlin)

**Localização dos testes:**
```
linkaAndroidKotlin/linka-android-kotlin/
  featureSpeedtest/src/test/kotlin/...     ← SpeedtestQualityClassifierTest
  featureDiagnostico/src/test/kotlin/...  ← 8 arquivos de test (engines, AI, Pulse)
  featureHistory/src/test/kotlin/...      ← 6 arquivos de test (exportação, uptime, chart)
  coreTelephony/src/test/kotlin/...       ← MonitorTelephonyTest
  coreNetwork/src/test/kotlin/...         ← GatewayLatencyMeasurerTest
  app/src/test/kotlin/...                 ← 4 arquivos (gateway, monitoramento, device)
```

**Como rodar (Android Studio ou linha de comando):**
```bash
# Todos os testes unitários do projeto
cd linkaAndroidKotlin/linka-android-kotlin
./gradlew test

# Módulo específico
./gradlew :featureDiagnostico:test
./gradlew :featureHistory:test

# Com relatório HTML
./gradlew test --continue
# Relatórios em: <modulo>/build/reports/tests/test/index.html
```

**Nota:** Testes instrumentados (device/emulator) não foram identificados. Todos os testes existentes são unitários JVM.

### PWA (TypeScript/Vitest)

**Localização dos testes:**
```
linkaSpeedtestPwa/src/__tests__/
  anatelColor.test.ts        ← cores por faixa Anatel
  classifier.test.ts         ← classificação de qualidade
  combinedDiagnosis.test.ts  ← diagnóstico combinado
  compare.test.ts            ← comparação de locais
  connectionProfile.test.ts  ← perfis de conexão
  copyDictionary.test.ts     ← microcopy e copy
  dnsProbe.test.ts           ← probe DNS
  dnsTiming.test.ts          ← timing DNS
  LocalWifiService.test.ts   ← Wi-Fi local
  localNetworkRegistry.test.ts ← registry de fabricantes
  share.test.ts              ← compartilhamento
  speedtest.test.ts          ← motor de speedtest (inclui computeRanges)
  useCountUp.test.ts         ← hook de animação count-up
  useScrollHeader.test.ts    ← hook de scroll header
  wifiSignal.test.ts         ← sinal Wi-Fi
```

**Como rodar:**
```bash
cd linkaSpeedtestPwa

# Todos os testes
npm test

# Com watch mode
npm test -- --watch

# Com cobertura
npm test -- --coverage

# Arquivo específico
npm test -- src/__tests__/speedtest.test.ts
```

**Framework:** Vitest (configurado em `vite.config.ts`).

---

## 4. Lacunas de Cobertura

### Lacunas críticas — sem nenhum teste

| Área | Plataforma | Risco |
|---|---|---|
| Módulo `:featureWifi` (scan, band, PHY, MIMO, mesh) | Android | Alto — ORBs 195-205 em andamento |
| Módulo `:featureFibra` | Android | Alto — sem nenhum teste |
| Configurações — persistência de settings | Ambos | Médio |
| Onboarding — fluxo completo | PWA | Médio |
| ResultScreen — estados visuais (ribbon, count-up, sheets) | PWA | Médio |
| Monitoramento — histérese em device real | Android | Médio |
| Upload parcial em rede móvel | PWA | Médio |
| Diagnóstico — degradação histórica | PWA | Baixo |

### Lacunas estruturais

- **Testes de instrumentação Android ausentes.** Não há testes de UI com Espresso ou Compose Test. Fluxos de tela só são verificáveis manualmente.
- **Testes de integração E2E PWA ausentes.** Não há testes Playwright ou Cypress. A cobertura existente é unitária (utils/hooks) mas não cobre fluxos de tela completos.
- **Sem matriz de testes por API level Android.** Comportamentos que diferem entre API 29, 31 e 33+ (Wi-Fi scan, permissões, WifiInfo) não têm testes parametrizados.
- **Sem testes de regressão visual.** Nenhum snapshot test de componente React (Storybook ou similar).
- **Testes PWA não cobrem o motor de speedtest end-to-end.** `speedtest.test.ts` cobre `computeRanges` e lógica interna, mas não simula ciclos completos de download/upload contra mock server.

### Próximos passos sugeridos

1. Adicionar testes unitários para `:featureWifi` — mínimo: `ScannerRedesWifi`, `MontarResumoWifiUseCase`, `RedeVizinha.canal` e `RedeVizinha.banda`.
2. Criar testes de integração PWA para ResultScreen (estados do card unificado).
3. Adicionar testes parametrizados por API level para comportamentos Wi-Fi.
4. Documentar manual test checklist de pre-release como artifact executável (ex.: planilha ou notion board).
