# Documentação Técnica Cross-Platform — Linka

**Versão:** v0.7.1 (Android) | v1.3.0 (PWA)
**Público-alvo:** Time de desenvolvimento humano
**Última atualização:** 2026-05-17
**Mantido por:** Taisa

> Este documento responde: "Como o Linka funciona por dentro, em cada plataforma?"
> Para funcionalidades e fluxos de usuário, consulte `FUNCIONAL_CROSSPLATFORM.md`.
> Para design e visual, consulte `DESIGN_SYSTEM_CROSSPLATFORM.md`.

---

## 1. Arquitetura por Plataforma

### 1.1 Android — Visão Geral

```
Camada de Apresentação (Jetpack Compose)
    ↑ state flow
ViewModel (MVVM)
    ↑ data
Camada de Dados (Repository Pattern via classes de repositório — ex.: `PreferenciasAppRepository` — sem framework de DI; injeção manual por construtor)
    ├── Room (coreDatabase)
    ├── DataStore (coreDatastore)
    └── Network (coreNetwork)
```

**Stack:**
| Tecnologia | Versão | Função |
|---|---|---|
| Kotlin | — | Linguagem principal |
| Jetpack Compose | — | UI declarativa |
| Material Design 3 | — | Sistema de design |
| Room | — | Persistência local (SQLite) |
| Kotlin Coroutines | — | Operações assíncronas |
| WorkManager | — | Tarefas em background |
| DI | Injeção manual por construtor (sem Hilt nem Koin — módulos `Modulo.kt` são objetos de fábrica simples) | — |

**Padrão de arquitetura:** MVVM. Fluxo unidirecional: UI → ViewModel → Dados → State Update → UI Recomposition.

**Entrada:** `LinkaApplication.kt`, `MainActivity.kt`
**Tema:** `LinkaTheme.kt` (aplica MD3 via `MaterialTheme`)
**Navegação:** `AppNavGraph.kt` (Compose Navigation 2+), `AppShell.kt` (BottomNavBar, back stack, deep links `linka://screen/...`)

### 1.2 PWA — Visão Geral

```
Camada de Apresentação (React 19 + TSX)
    ↑ state
Hooks customizados (useSpeedTest, useSettings, useDeviceInfo...)
    ↑ data
Utils / Engines (speedTestOrchestrator, history, diagnosis...)
    ├── localStorage (persistência)
    └── Cloudflare APIs (medição + IA)
```

**Stack:**
| Tecnologia | Versão | Função |
|---|---|---|
| Vite | ^7.0 | Build tool + dev server |
| React | ^19 | Framework UI |
| TypeScript | ^6 | Tipagem estática |
| vite-plugin-pwa | ^1.2 | Manifest + service worker |
| Capacitor | ^8 | Empacotamento Android nativo do PWA |
| Android SDK | Platform 36 / Build Tools 36.1 | Build APK via Capacitor |
| JDK | 21 LTS | Compilação Gradle/Android |
| Recharts | latest | Gráficos (HistoryScreen) |
| jsPDF + html2canvas | latest | Geração de PDF |
| Vitest | latest | Testes unitários |

> **Restrição crítica:** `vite-plugin-pwa` 1.x é incompatível com Vite 8+. Não atualizar Vite sem validar a versão do plugin.

**Navegação:** Stack manual em `App.tsx` via `useState<Screen>`. Sem react-router. Suporte a swipe horizontal (threshold 80px) e pull-to-refresh.

---

## 2. Módulos Android (15 módulos)

> Declarados em `settings.gradle.kts`. O CLAUDE.md mencionava 16 módulos — o número correto é 15.
> Para documentação detalhada por módulo, consulte `ANDROID_TECNICO.md`.

### Módulos Core (5)

| Módulo | Responsabilidade | Arquivos-chave |
|---|---|---|
| `:coreDatabase` | Persistência Room — DAOs, entidades, migrations | `LinkaDatabase.kt` (v8), `MedicaoDao.kt`, `MedicaoEntity.kt`, `ApelidoDispositivoDao.kt`, `ApelidoDispositivoEntity.kt` |
| `:coreDatastore` | Preferências chave-valor via Jetpack DataStore | `PreferenciasAppRepository.kt` — DataStore name: `"linkaPreferencias"` — 19+ chaves incluindo monitoramento, modem, tema, perfil, provedor, alertas (histerese) e controles granulares de notificação |
| `:coreNetwork` | Monitoramento de rede, estado de conexão | `MonitorRede.kt`, `MonitorRedeAndroid.kt`, `EstadoConexao.kt`, `SnapshotRede.kt`, `WifiLinkSnapshot.kt`, `GatewayLatencyMeasurer.kt` |
| `:corePermissions` | Gerenciamento de permissões runtime | `GerenciadorPermissoesRede.kt`, `GerenciadorPermissoesRedeAndroid.kt`, `EstadoPermissao.kt`, `SnapshotPermissoesRede.kt` |
| `:coreTelephony` | Acesso a sinal móvel via TelephonyManager | `MonitorTelephony.kt`, `MonitorTelephonyImpl.kt`, `MovelSnapshot.kt` — coleta RSRP, RSRQ, SINR, tecnologia (4G/5G), banda, operadora |

### Módulos de Feature (10)

| Módulo | Responsabilidade | Tela(s) associada | Arquivos-chave (no módulo) |
|---|---|---|---|
| `:featureHome` | Módulo mínimo (stub) | `HomeScreen.kt` (em `:app`) | `FeatureHomeModulo.kt` |
| `:featureSpeedtest` | Motor de speedtest, fases, resultado | `SpeedTestScreen.kt`, `VelocidadeScreen.kt`, `ResultadoVelocidadeScreen.kt` (em `:app`) | `ExecutorSpeedtest.kt`, `ModoSpeedtest.kt`, `ResultadoSpeedtest.kt`, `SnapshotExecucaoSpeedtest.kt`, `EstadoExecucaoSpeedtest.kt` |
| `:featureWifi` | Scan Wi-Fi, análise de redes vizinhas, topologia | `SinalScreen.kt` (em `:app`) | `ScannerRedesWifi.kt`, `RedeVizinha.kt` (suporta 2.4/5/6GHz), `SnapshotScanWifi.kt`, `GrupoRedeWifi.kt`, `TopologiaWifiEngine.kt`, `MeshOuiDatabase.kt` |
| `:featureDevices` | Descoberta e classificação de dispositivos na LAN | `DispositivosScreen.kt` (em `:app`) | `ScannerDispositivos.kt`, `ScannerDispositivosAndroid.kt`, `DispositivoRede.kt`, `ClassificadorDispositivoRede.kt`, `OuiDatabase.kt` |
| `:featureDns` | Benchmark de servidores DNS via DoH | Sheet em `AppShell.kt` | `BenchmarkDns.kt`, `BenchmarkDnsDoh.kt`, `ResultadoBenchmarkDns.kt` (grades A/B/C/D), `AvaliadorCoerenciaDns.kt`, `OrientadorConfiguracaoDns.kt` |
| `:featureDiagnostico` | Engines de diagnóstico local + integração IA (Orbit/Pulse) | `OrbitScreen.kt`, `ChatScreen.kt`, `ResultadoVelocidadeScreen.kt` (em `:app`) | `DiagnosticDecisionEngine.kt`, `InternetDiagnosticEngine.kt`, `WifiSignalQualityEngine.kt`, `DnsDiagnosticEngine.kt`, `HistoricalDegradationEngine.kt`, `FibraSignalQualityEngine.kt`, `MobileSignalDiagnosticEngine.kt`, `WifiChannelDiagnosticEngine.kt`, `DiagnosticOrchestrator.kt` + sub-pacote `ai/` (AiModels.kt — schema v3 raw, modelo Gemma 4 26B) + sub-pacote `pulse/` (OrbitState, DynamicQuestionEngine, IntelligentDiagnosticSession) |
| `:featureFibra` | Leitura de dados da ONT GPON Nokia | `FibraScreen.kt` (em `:app`) | `NokiaModemClient.kt`, `NokiaModemCrypto.kt`, `NokiaModemParser.kt`, `ClassificadorSaudeGpon.kt`, `SnapshotFibra.kt`, `GponStatus.kt`, `WanStatus.kt`, `PppStatus.kt` |
| `:featureHistory` | Histórico, uptime, exportação | `HistoricoScreen.kt`, `ExportHistoricoBottomSheet.kt` (em `:app`) | `ObservadorHistoricoRoom.kt`, `ResumoHistorico.kt`, `TendenciaCalculador.kt`, `UptimeChartUseCase.kt`, `UptimeNarrativaEngine.kt`, `ExportadorHistoricoCSV.kt`, `ExportadorHistoricoPDF.kt` |
| `:featureSettings` | Módulo mínimo (stub) | `AjustesScreen.kt` (em `:app`) | `FeatureSettingsModulo.kt` |

**Telas e orchestrators em `:app` (não em módulos de feature):**

Toda a camada de apresentação reside em `:app`. As telas (`AppShell`, `HomeScreen`, `OrbitScreen`, `ChatScreen`, etc.) e os orchestrators (`OrbitOrchestrator`, `LinkaPulseOrchestrator`, `MonitoramentoWorker`) também vivem em `:app`.

### Estrutura de Diretórios Android (verificada)

```
linkaAndroidKotlin/
└── linka-android-kotlin/
    ├── app/
    │   └── src/main/kotlin/io/linka/app/kotlin/
    │       ├── ui/
    │       │   ├── screen/          ← telas (HomeScreen, DiagnosticoScreen, etc.)
    │       │   ├── component/       ← 25 componentes custom
    │       │   └── navigation/      ← AppNavGraph.kt
    │       └── LinkaApplication.kt
    ├── coreDatabase/
    ├── coreDatastore/
    ├── coreNetwork/
    ├── corePermissions/
    ├── coreTelephony/
    ├── featureHome/
    ├── featureSpeedtest/
    ├── featureWifi/
    ├── featureDevices/
    ├── featureDns/
    ├── featureDiagnostico/
    ├── featureFibra/
    ├── featureHistory/
    └── featureSettings/
```

---

## 3. Estrutura PWA

### Estrutura de Diretórios (verificada)

```
linkaSpeedtestPwa/
├── src/
│   ├── App.tsx                    ← navegação principal (stack manual)
│   ├── types/
│   │   └── index.ts               ← TODOS os tipos compartilhados
│   ├── components/                ← 27 componentes React
│   ├── hooks/
│   │   ├── useSpeedTest.ts        ← orquestrador público
│   │   ├── useSettings.ts         ← persistência de config
│   │   ├── useDeviceInfo.ts       ← info de dispositivo e servidor
│   │   └── useScrollHeader.ts     ← comportamento scroll do TopBar
│   ├── utils/
│   │   ├── speedTestOrchestrator.ts    ← orquestrador do motor v2
│   │   ├── cloudflareSpeedTest.ts      ← primitivas HTTP Cloudflare
│   │   ├── latencyProbe.ts             ← medição de latência
│   │   ├── downloadProbe.ts            ← motor download time-based
│   │   ├── uploadProbe.ts              ← motor upload time-based
│   │   ├── history.ts                  ← persistência localStorage
│   │   └── combinedDiagnosis.ts        ← camada legada de diagnóstico
│   ├── features/
│   │   ├── diagnosis/                  ← Claude AI + rules engine
│   │   ├── local-wifi/                 ← LocalWifiScreen + LocalWifiScreen.css
│   │   └── local-network/              ← LocalNetworkScreen + LocalNetworkScreen.css
│   └── platform/
│       └── capabilities.ts             ← detecção de capacidades do browser/OS
├── android/                           ← projeto Capacitor Android
└── .github/workflows/
    ├── ci.yml
    └── release.yml
```

### Módulos Lógicos PWA

| Módulo | Localização | Responsabilidade |
|---|---|---|
| Motor de medição | `utils/speedTestOrchestrator.ts` + probes | Medição de DL, UL, latência, bufferbloat |
| Diagnóstico | `features/diagnosis/` | Análise IA + fallback rules engine |
| Persistência | `utils/history.ts` + `localStorage` | Histórico de testes |
| Capacidades | `platform/capabilities.ts` | Detecção de features disponíveis (browser/Capacitor) |
| Tipos | `types/index.ts` | Contratos de tipos compartilhados |
| Tema | `src/tokens.css` | CSS Custom Properties — tema claro/escuro |
| Wi-Fi local | `features/local-wifi/` | `LocalWifiScreen.tsx` + CSS — diagnóstico Wi-Fi no browser |
| Rede local | `features/local-network/` | `LocalNetworkScreen.tsx` + CSS — dispositivos na rede |
| iOS WiFi Context | `utils/wifiShortcut.ts` | Integração com Atalho iOS: `parseWifiCallback`, `savePendingWifiContext`, `consumePendingWifiContext`, `runWifiShortcut`, `generateSessionId` |

---

## 4. Fluxos Técnicos Compartilhados

### 4.1 Speedtest — Fluxo Técnico

#### Android

Fluxo inferido — não documentado com granularidade de código:

```
SpeedTestScreen (`:app`) → ExecutorSpeedtestCloudflare.executar(modo, connectionType, provider)
    │
    ├── Fase 1: executarFaseLatencia() — N pings para speed.cloudflare.com/__down?bytes=0
    │   → descarta 1º ping; filtra outliers > 3× mediana
    │   → emite: latenciaMs (mediana), jitterMs (média de deltas consecutivos), perdaPercentual
    │
    ├── Fase 2: executarFaseTransferencia(isDownload=true) — HTTP/1.1 pool 8 conexões
    │   + pingJob paralelo (bufferbloat measurement)
    │   → streams paralelos com escalonamento dinâmico (ganho ≥ 10% → +2 streams a cada 4s)
    │   → amostras a cada 300ms; descarta top 35% (warmup + instabilidade)
    │   → calcula throughputMbps (média das amostras estáveis) + peakMbps
    │
    ├── Fase 3: executarFaseTransferencia(isDownload=false) ou executarFaseUploadAdaptativa() (mobile)
    │   + dnsProbe paralelo (DoH whoami cloudflare)
    │   → upload via OkHttp HTTP/2; payload pré-alocado em cache por tamanho
    │   → retry com backoff (1s/2s/4s) se throughput = 0
    │
    └── construirResultado()
        → bufferbloatMs = max(latencyDownload, latencyUpload) - latenciaUnloaded
        → SeveridadeBufferbloat via SpeedtestQualityClassifier
        → stabilityScore via coeficiente de variação (CV) das amostras
        → ResultadoSpeedtest publicado via SnapshotExecucaoSpeedtest (StateFlow)
            ↓
        MedicaoDao.inserir() → Room (coreDatabase)
```

#### PWA — Motor v2 (documentado)

```
StartScreen → onStart(mode) → useSpeedTest hook
    → runSpeedTestV2(mode, onProgress, signal, connectionType)
    │
    ├── Fase 1: runLatencyPhase(15|25 pings)
    │   → 15–25 pings; descarta 1º; remove outliers > 3× mediana
    │   → emite partial: { latency, jitter, packetLoss }
    │
    ├── Fase 2: runDownloadProbe + runPingLoop (paralelo)
    │   → streams paralelos (2→4 fast, 2→8 complete)
    │   → amostragem a cada 300ms via ReadableStream.read()
    │   → janela estável: últimos 65% das amostras válidas
    │   → throughputMbps = mean(stable); peakMbps = max(valid)
    │   → emite partial: { dl }
    │
    ├── Fase 3: runUploadProbe (ou runAdaptiveUploadProbe para mobile)
    │   → upload via XHR sem listeners em xhr.upload (CORS simple request)
    │   → estratégia adaptativa: rodadas progressivas para mobile < 2 Mbps
    │   → emite partial: { ul }
    │
    └── Fase 4: buildDiagnostics()
        → calcula bufferbloat: dlDelta = latencyDownload - latencyUnloaded
        → classifyBufferbloatSeverity(max(dlDelta, ulDelta))
        → retorna SpeedTestResult completo
```

**Endpoints Cloudflare usados:**
| Propósito | Método | URL |
|---|---|---|
| Download | GET | `https://speed.cloudflare.com/__down?bytes=N&_cb={ts}_{rand}` |
| Upload | POST | `https://speed.cloudflare.com/__up` |
| Latência / Ping | GET | `https://speed.cloudflare.com/__down?bytes=0&_cb={ts}_{rand}` |

Anti-cache: `_cb={Date.now()}_{Math.random()}` em todo request.

**Mapeamento de progresso (modo rápido / completo):**
| Fase | Rápido (amostras 15+23+23) | Completo (amostras 25+60+60) |
|---|---|---|
| Latência | 0–24,6% | 0–17,2% |
| Download | 24,6–62,3% | 17,2–58,6% |
| Upload | 62,3–100% | 58,6–100% |

### 4.2 Diagnóstico — Engine e Thresholds

**Dois caminhos (ambas plataformas):**

```
SpeedTestResult → DiagnosticEngine
    ├── Caminho 1: Claude API (via Cloudflare Worker)
    │   └── POST https://linka-ai-diagnosis-worker.giammattey-luiz.workers.dev/diagnosis
    │       → análise contextual com LLM
    │
    └── Caminho 2: Rules Engine v1 (fallback local)
        → thresholds determinísticos
        → sem dependência externa
        → mesmo schema de saída DiagnosisRecommendation
```

**Gateway compartilhado:** `linka-ai-diagnosis-worker.giammattey-luiz.workers.dev`

**Schema de entrada (compartilhado):**
- `dl`, `ul` — Mbps
- `latency`, `jitter` — ms
- `packetLoss` — % (0–100)
- `connectionType` — `wifi / mobile / cable / unknown`
- `timestamp` — Unix ms

**Schema de saída:** `DiagnosisRecommendation` — ver `CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1.md`

### 4.3 Monitoramento Passivo — Fluxo Android

Exclusivo Android — não existe equivalente real no PWA.

```
WorkManager (PeriodicWorkRequest, 30 min)
    constraint: rede conectada + bateria não baixa
    ↓
MonitoramentoWorker.doWork()
    ↓
LinkaPulseOrchestrator.iniciarDiagnostico()
    ├── Fase 1: Collecting
    │   └── Speedtest silencioso + snapshot Wi-Fi (RSSI, freq, link speed)
    │
    ├── Fase 2: Thinking
    │   └── Engines de diagnóstico locais (sem IA)
    │
    └── Fase 3: Analyzing
        └── POST → linka-ai-diagnosis-worker.giammattey-luiz.workers.dev
    ↓
Avaliação de alerta (cooldown 2h, teto 3/dia)
    ↓
Room (AlerteLinkaPulse table) + Notificação push
```

---

## 5. Persistência

### 5.1 Android

| Mecanismo | Módulo | O que armazena |
|---|---|---|
| Room (SQLite) | `:coreDatabase` | Medições de speedtest (`MedicaoEntity`), apelidos de dispositivos (`ApelidoDispositivoEntity`) — schema versão 8. Alertas do LinkaPulse NÃO têm tabela Room própria (sem `AlerteDao` ou `DiagnosticDao` no `LinkaDatabase`) |
| DataStore | `:coreDatastore` | Preferências do usuário, flags, configurações [a confirmar conteúdo exato] |

**DAOs confirmados:**
- `MedicaoDao` — CRUD de medições
- `ApelidoDispositivoDao` — CRUD de apelidos de dispositivos
- `LinkaDatabase` — classe Room com schema

**DAOs verificados no código — apenas os dois listados acima.** `DiagnosticDao` e `AlerteDao` NÃO existem no `LinkaDatabase` (versão 8). Alertas do LinkaPulse são provavelmente gerenciados via `PreferenciasAppRepository` (DataStore) ou em memória.

**Classe Room:** `LinkaDatabase.kt` em `coreDatabase/src/main/kotlin/.../`

### 5.2 PWA

| Mecanismo | O que armazena |
|---|---|
| `localStorage` | Histórico de testes (`TestRecord[]`), configurações (`Settings`), flag onboarding, estado de tema |
| Service Worker cache | Assets estáticos do PWA (via `vite-plugin-pwa`) |

**Risco de dados:** `localStorage` é limpo quando o usuário limpa dados do browser. Não há sincronização com servidor.

**Diferença crítica:**

| Aspecto | Android | PWA |
|---|---|---|
| Sobrevive reinstalação | Sim (Room persiste no app) | Não (localStorage é por origem) |
| Backup automático | Não configurado explicitamente (depende do backup Android padrão) | Não |
| Exportação | PDF via `ExportHistoricoBottomSheet` | PDF manual |
| Limite de armazenamento | Sem limite prático (SQLite) | ~5MB (localStorage) |

---

## 6. APIs Externas

### 6.1 Cloudflare Speed Test

**Proprietário:** Cloudflare (público)
**Usado por:** PWA (confirmado), Android (confirmado — `ExecutorSpeedtestCloudflare.kt` usa os mesmos endpoints `/__down` e `/__up`)

| Endpoint | Uso |
|---|---|
| `speed.cloudflare.com/__down?bytes=N` | Download probe |
| `speed.cloudflare.com/__up` | Upload probe |
| `speed.cloudflare.com/__down?bytes=0` | Latency/ping probe |
| `speed.cloudflare.com/meta` | Info do servidor (IP público, ISP, PoP) |

### 6.2 Cloudflare AI Diagnosis Worker

**URL:** `https://linka-ai-diagnosis-worker.giammattey-luiz.workers.dev`
**Usado por:** Android (via `LinkaPulseOrchestrator` + `featureDiagnostico`), PWA (via `features/diagnosis/`)
**Função:** Análise de diagnóstico com IA (Claude API) + fallback rules engine

### 6.3 DNS over HTTPS (PWA)

**Usado por:** PWA — `DNSGuideSheet`, campo `dnsLatencyMs`, `dnsResolverIp`, `dnsProvider`
**Protocolo:** DoH — mede latência dos 5 servidores via Resource Timing API

---

## 7. Build e Deploy

### 7.1 Android — Build Nativo (linkaAndroidKotlin)

**Sistema:** Gradle
**Linguagem de build:** Kotlin DSL (`build.gradle.kts`)
**Dependências:** `gradle/libs.versions.toml` (Version Catalog)

**Versão atual:** `versionName = "0.7.1"` / `versionCode = 16` (release 2026-05-16)

**APK release atual:** `E:\Projetos\Linka\builds\apk\release\linka-app-0.7.1-16-release-20260516.apk`

**Outputs:**
- APK debug: para desenvolvimento e testes
- APK/AAB release: para distribuição

**Build local:**
```bash
# no diretório do projeto Android
./gradlew assembleRelease
```

**Referência:** `linkaAndroidKotlin/docs_ai/operations/APK_BUILD.md`

### 7.2 PWA — Build e Deploy (linkaSpeedtestPwa)

**Versão atual:** `1.3.0` (package.json — release 2026-05-16)
**Deploy ativo:** https://linka-speedtest.pages.dev

**Sistema:** Vite 7 + GitHub Actions

**Pipeline CI (`ci.yml`) — todo push:**
1. Lint
2. Vitest (testes unitários)
3. Build PWA (`vite build` → `dist/`)
4. Upload de `dist/` como artefato (7 dias)

**Pipeline Release (`release.yml`) — push de tag `v*`:**

Em paralelo:
- **Job PWA:** `vite build` → deploy em Cloudflare Pages via `wrangler pages deploy`
- **Job APK (Capacitor):** `cap sync android` → `gradlew assembleRelease` → APK assinado anexado ao GitHub Release

**Versionamento:** SemVer via tag git (`v1.2.0`). `package.json` deve bater com a tag.

**Secrets necessários (GitHub):**
| Secret | Uso |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Deploy em Pages |
| `CLOUDFLARE_ACCOUNT_ID` | Identificação da conta |
| `KEYSTORE_BASE64` | APK assinado |
| `KEYSTORE_PASSWORD` | Senha keystore |
| `KEY_ALIAS` | Alias da chave |
| `KEY_PASSWORD` | Senha da chave |

**Deploy target default:** Cloudflare Pages (projeto `linkaSpeedtestPwa`)

**Build local APK (sem CI):**
```bash
npm run android:apk
# output: builds/apk/linkaSpeedtestPwa-X.Y.Z-{type}-{date}-{hash}.apk
```

---

## 8. Tipos e Contratos de Interface (PWA — documentados)

Todos os tipos compartilhados do PWA vivem em `src/types/index.ts`.

### Tipos de estado de teste

```typescript
type Quality = 'excellent' | 'good' | 'fair' | 'slow' | 'unavailable'
type TestPhase = 'idle' | 'latency' | 'download' | 'upload' | 'load' | 'done' | 'error'
type SpeedTestMode = 'quick' | 'fast' | 'complete' | 'normal' | 'advanced'
type BufferbloatSeverity = 'low' | 'moderate' | 'high' | 'critical'
type ConnectionType = 'wifi' | 'mobile' | 'cable' | 'unknown'
```

### SpeedTestResult (campos principais)

```typescript
interface SpeedTestResult {
  dl: number           // Mbps download (média janela estável — Motor v2)
  ul: number           // Mbps upload
  latency: number      // ms mediana amostras idle
  jitter: number       // ms MAD da latência idle
  packetLoss: number   // % perda de pacotes (0–100)
  timestamp: number    // Unix ms
  mode?: SpeedTestMode
  // Motor v2
  stabilityScore?: number       // 0–100 (100 = mínima variação)
  bufferbloatSeverity?: BufferbloatSeverity
  latencyUnloaded?: number      // ms mediana idle
  latencyDownload?: number      // ms mediana durante DL
  latencyUpload?: number        // ms mediana durante UL
  diagnostics?: SpeedTestDiagnostics
  // DNS (2026-05)
  dnsLatencyMs?: number | null
  dnsResolverIp?: string | null
  dnsProvider?: string | null
  // Resultado parcial (upload falhou)
  ulFailed?: boolean
  elapsedMs?: number
}
```

### TestRecord (persistido em localStorage)

```typescript
interface TestRecord {
  id: string
  timestamp: number
  dl: number; ul: number; latency: number; jitter: number; packetLoss: number
  quality: Quality
  tags: Tag[]
  serverName: string
  isp?: string
  deviceType: DeviceType
  connectionType: ConnectionType
  testMode?: SpeedTestMode
  locationTag?: string      // para "Teste por cômodo"
  stabilityScore?: number
  bufferbloatSeverity?: BufferbloatSeverity
  dnsLatencyMs?: number | null
}
```

---

## 9. Módulos de Feature — `:featureWifi` (documentado em código)

Este é o módulo Android com maior detalhamento técnico verificado. Serve como referência de padrão de implementação.

**Localização:** `linka-android-kotlin/featureWifi/src/main/kotlin/io/linka/app/kotlin/feature/wifi/`

| Arquivo | Tipo | Responsabilidade |
|---|---|---|
| `ResumoWifi.kt` | Data class | Resumo da conexão atual (titulo + detalhe) |
| `MontarResumoWifiUseCase.kt` | Use case | Gera `ResumoWifi` a partir de `SnapshotRede` — 5 estados de conexão |
| `RedeVizinha.kt` | Data class | Rede Wi-Fi detectada no scan. Campos: `ssid`, `bssid`, `rssiDbm`, `frequenciaMhz`, `seguranca`, `larguraCanalMhz`. Computed: `banda`, `canal` |
| `ScannerRedesWifi.kt` | Service | Scan via `WifiManager`. Expõe `StateFlow<SnapshotScanWifi>`. Timeout 10s. Fallback para `scanResults` cached. |
| `SnapshotScanWifi.kt` | Data class | Estado do scan: `idle / scanning / concluido / erro` + lista de redes |
| `FeatureWifiModulo.kt` | DI module | Injeção de dependência do módulo |

**Restrições críticas de API:**
- `ACCESS_FINE_LOCATION` obrigatória (API 29+) — sem ela, SSID retorna `<unknown ssid>`
- Rate limiting de `startScan()`: 4 chamadas / 2 min (foreground), 1 / 30 min (background)
- Extração de SSID sem deprecated: API 33+ (`ScanResult.wifiSsid`)

---

## 10. Diagrama de Dependências de Módulos Android

```
:app
  ├── :featureHome
  ├── :featureSpeedtest
  ├── :featureWifi
  ├── :featureDevices
  ├── :featureDns
  ├── :featureDiagnostico
  ├── :featureFibra
  ├── :featureHistory
  └── :featureSettings

Todos os :feature* dependem de combinações de:
  ├── :coreNetwork
  ├── :coreDatabase
  ├── :coreDatastore
  ├── :corePermissions
  └── :coreTelephony

Dependências exatas por módulo: [não mapeadas em código lido — verificar em cada `build.gradle.kts` de feature]
```

---

## 11. Pontos de Atenção para Desenvolvimento

### Android

1. **Documentação inferencial:** Maioria dos módulos de feature tem documentação inferida de estrutura de diretório, não de leitura de código. Antes de modificar, ler o código real.
2. **`:coreDatastore`:** Implementação interna não documentada — ler antes de usar.
3. **`wifiManager.startScan()`:** Deprecated a partir de API 33+. Usar com fallback para `scanResults` cached (já implementado em `ScannerRedesWifi`).
4. **OEM quirks:** Samsung, Xiaomi e Moto têm comportamentos distintos em WorkManager e Wi-Fi. Ver `WIFI_FEATURES.md` seção 7.

### PWA

1. **Não atualizar Vite acima de 7.x** sem resolver incompatibilidade com `vite-plugin-pwa` 1.x.
2. **Upload CORS:** `cfUploadChunk` é simple CORS request — não adicionar listeners em `xhr.upload` (força preflight que falha em `speed.cloudflare.com/__up`).
3. **Motor de medição é protegido:** Assinatura pública de `useSpeedTest` não deve mudar durante refactors visuais. Qualquer mudança no motor exige testes de regressão.
4. **localStorage para histórico:** Dados perdidos ao limpar browser. Não há sincronização com servidor.

---

## 12. Notas de Manutenção

- Seções com `[a confirmar]` indicam informação não verificada em código — não copiar para outros documentos sem validar primeiro.
- Quando um módulo Android for documentado em código, atualizar a linha correspondente na seção 2 e remover o `[a confirmar]`.
- Quando o motor Android de speedtest for documentado, atualizar a seção 4.1 com o mesmo nível de detalhe que o PWA.
- Referência de arquitetura original: `linkaAndroidKotlin/docs_ai/technical/ARCHITECTURE.md`, `MODULES.md`, `DATA_FLOW.md`
