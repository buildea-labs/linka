# Documentação Funcional Cross-Platform — Linka

**Versão:** v0.7.1 (Android) | v1.3.0 (PWA)
**Público-alvo:** Time de desenvolvimento humano
**Última atualização:** 2026-05-16 (auditoria completa de todas as waves do assessment — Taisa)
**Mantido por:** Taisa

> Este documento responde: "O que o Linka faz, em cada plataforma, feature por feature?"
> Para arquitetura interna, consulte `TECNICO_CROSSPLATFORM.md`.
> Para design e visual, consulte `DESIGN_SYSTEM_CROSSPLATFORM.md`.

---

## 1. Visão Geral de Features por Plataforma

| Feature | Android | PWA | Status Android | Status PWA | Observação |
|---|---|---|---|---|---|
| Speedtest | Sim | Sim | Implementado | Implementado | Motor diferente por plataforma |
| Diagnóstico IA | Sim | Sim | Implementado | Implementado | Mesmo schema de saída (CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1) |
| Histórico de testes | Sim | Sim | Implementado | Implementado | Android usa Room; PWA usa localStorage |
| Wi-Fi — scan de redes | Sim | Parcial | Implementado | Parcial (limitação browser) | PWA mostra info básica; scan completo só Android |
| Wi-Fi — SSID, banda, canal | Sim | Não | Implementado | Impossível no browser | Requer API Android (`WifiManager`) |
| Dispositivos na rede | Sim | Parcial | Implementado | Parcial (limitação browser) | Scan LAN real só Android |
| Diagnóstico DNS | Sim | Sim | Implementado | Implementado | PWA exibe guia + benchmark DoH; Android tem tela dedicada |
| Fibra ótica | Sim | Não | Implementado | Ausente | Feature exclusiva Android |
| Monitoramento passivo (LinkaPulse) | Sim | Parcial | Implementado | Parcial | Android usa WorkManager; PWA tem tela Pulse sem background real |
| LinkaPulse — diagnóstico humanizado | Sim | Sim | Implementado | Implementado (v1.3.0) | Mensagens humanizadas em português no diagnóstico Pulse |
| IA assistente (Orbit/Chat) | Sim | Parcial | Implementado | Parcial | Android tem tela Orbit completa; PWA integra diagnóstico na ResultScreen |
| Relatório / Laudo | Sim | Sim | Implementado | Implementado | Android tem `LaudoScreen`; PWA gera PDF via jsPDF |
| Onboarding | Não | Sim | Ausente | Implementado | Carousel 3 cards, 1ª execução |
| Comparar locais | Não | Sim | Ausente | Implementado | Feature PWA: near vs. far do roteador |
| Antes e Depois | Não | Sim | Ausente | Implementado | Feature PWA: comparação pré/pós ação |
| Aviso de dados móveis | Não | Sim | Ausente | Implementado (v1.3.0) | StartScreen exibe aviso antes do teste quando detecta dados móveis (iOS/Android) |
| RQUAL Anatel — comparação de plano | Não | Sim | Ausente | Implementado (v1.3.0) | ResultScreen avalia DL + UL contra limites RQUAL; breakdown inline; usuário pode declarar velocidade contratada |
| CGNAT — banner de alerta | Sim | Sim | Implementado (FibraScreen) | Implementado (v1.3.0) | Android: detecção na FibraScreen com explicação. PWA: banner na HomeScreen quando CGNAT detectado |
| Teste por cômodo | Não | Sim | Ausente | Implementado | Feature PWA: label de local por teste |
| Prova Real (3×) | Não | Sim | Ausente | Implementado | Feature PWA: 3 testes consecutivos + média |
| Configurações / Ajustes | Sim | Sim | Implementado | Implementado | Persistência diferente por plataforma |
| Seletor de modo de teste | Sim | Sim | Implementado | Implementado | Rápido / Completo em ambas |
| Modo Gamer | Não | Removido | Ausente | Removido (v1.3.0) | Removido no Wave 5 — assessment recomendou retirar (nicho dentro de nicho, diagnóstico IA cobre o caso) |
| Notificações de alerta | Sim | Parcial | Implementado | Parcial | Android via WorkManager; PWA via `POST_NOTIFICATIONS` (Capacitor) |

---

## 2. Features em Detalhe

### 2.1 Speedtest

**O que faz:**
Mede velocidade de download, velocidade de upload, latência (RTT), jitter e perda de pacotes. Exibe resultado em tempo real com gauge animado.

#### Android

**Telas envolvidas:** `SpeedTestScreen` (`:featureSpeedtest`), `ResultScreen` (`:featureSpeedtest`)

**Fluxo principal:**
1. Usuário navega para SpeedTest via BottomNavBar ou HomeScreen
2. Toca botão "Iniciar" — gauge circular anima com fases de cor
3. Fases executam: latência → download → upload
4. Resultado exibido em `ResultScreen`: DL, UL, latência, jitter — com interpretação de qualidade

**Modos disponíveis:** Rápido (`fast`) e Completo (`complete`) — enum `ModoSpeedtest` em `:featureSpeedtest`. Toggle de modo existe e é espelhado do PWA (configuração idêntica de parâmetros).

**Motor:** `ExecutorSpeedtestCloudflare.kt` — motor nativo Kotlin com OkHttp. Usa os mesmos endpoints Cloudflare do PWA (`speed.cloudflare.com/__down`, `/__up`). HTTP/1.1 para download (pool de 8 conexões paralelas), HTTP/2 para upload e ping. Fases: latência (pings sequenciais) → download (streams paralelos com escalonamento dinâmico) → upload (streams paralelos ou modo adaptativo para mobile) → DNS probe.

**Gauge:** Componente `GaugeCircular.kt` — circular animado com cores por fase (`phaseLatencia`, `phaseDownload`, `phaseUpload`).

#### PWA

**Telas envolvidas:** `StartScreen`, `RunningScreen`, `ResultScreen`

**Fluxo principal:**
1. StartScreen: orb circular 200px — usuário toca "Iniciar"
2. Seletor de modo: Rápido (~30s) ou Completo (~60s)
3. `RunningScreen`: número instantâneo em 96px + frase narrativa descrevendo a fase
4. `ResultScreen`: DL, UL, latência, jitter, perda de pacotes + card "Diagnóstico da conexão"

**Modos:**
| Modo | Duração | Streams DL | Descrição |
|---|---|---|---|
| Rápido (`fast`) | ~30s | 2→4 | Download 7s + upload 7s + latência |
| Completo (`complete`) | ~60s | 2→8 | Download 18s + upload 18s + paralelismo progressivo |

**Motor:** Motor v2 — 5 módulos independentes (`latencyProbe`, `downloadProbe`, `uploadProbe`, `packetLoss`, `speedTestOrchestrator`). Usa endpoints diretos Cloudflare (`speed.cloudflare.com`).

**Bufferbloat:** medido durante DL e UL via `runPingLoop` em background paralelo. Severidade: `low / moderate / high / critical`.

**Diferenças de comportamento:**

| Aspecto | Android | PWA |
|---|---|---|
| Motor de medição | `ExecutorSpeedtestCloudflare.kt` — OkHttp nativo, espelho do motor PWA | Motor v2 Cloudflare direto, documentado |
| Bufferbloat | Medido — campo `bufferbloatMs` + `SeveridadeBufferbloat` (low/moderate/high/critical) | Medido, campo `bufferbloatSeverity` |
| Resultado parcial (upload falhou) | Suportado — campo `uploadNaoDetectado=true` em `ResultadoSpeedtest` | Suportado: `ulFailed=true`, exibe "—" |
| Seletor de modo | Sim — enum `ModoSpeedtest.fast` / `ModoSpeedtest.complete` | Toggle Rápido / Completo |
| Servidor | Cloudflare (`speed.cloudflare.com`) — mesmo servidor do PWA | Cloudflare (único servidor atualmente) |

---

### 2.2 Diagnóstico e Recomendações IA

**O que faz:**
Analisa os resultados do speedtest e contexto de rede para gerar diagnóstico em linguagem natural com recomendações de ação.

#### Android

**Telas envolvidas:** `DiagnosticoScreen` (`:featureDiagnostico`), `OrbitScreen` (`:featureDiagnostico`)

**Fluxo principal:**
1. Usuário acessa tela de Diagnóstico ou abre Orbit (IA assistente)
2. Sistema coleta dados de rede via `coreNetwork` + último resultado de speedtest
3. Envia payload para Cloudflare AI Worker (`linka-ai-diagnosis-worker.giammattey-luiz.workers.dev`)
4. Recebe análise estruturada; exibe em OrbitScreen via bolhas de chat

**Componentes IA:**
- `OrbitThinkingBubble` — "IA pensando" (estado de espera)
- `OrbitAiMessageBubble` — resposta da IA
- `OrbitUserMessageBubble` — mensagem do usuário
- `TypewriterText` — animação de digitação na resposta

**Perguntas filtro:** `DiagnosticoScreen` exibe chips de perguntas contextuais (componente `ContextualQuestionCard`) usando `AnimatedVisibility` com `fadeIn(tween(300)) + expandVertically(tween(300))`. O usuário seleciona contexto antes de acionar a análise IA; as respostas são enviadas junto ao payload para o worker Cloudflare.

#### PWA

**Telas envolvidas:** `ResultScreen` (card unificado "Diagnóstico da conexão"), `AdvancedSheet`

**Fluxo principal:**
1. Diagnóstico é gerado automaticamente ao fim do teste
2. `ResultScreen` exibe card "Diagnóstico da conexão" com 2 estados:
   - **Healthy:** ícone check verde + "Tudo certo com sua rede"
   - **Com problemas:** lista compacta `[problema] → [ação]`, máx. 3 visíveis + "Ver mais N"
3. Severidade agregada determina cor do glow do card (verde/amarelo/vermelho via `--diag-glow-color`)

**Dois caminhos de diagnóstico:**
1. **IA (Claude API)** — análise contextual via LLM
2. **Rules Engine v1** — fallback determinístico baseado em thresholds

**Schema de saída (compartilhado — ver `CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1.md`):**
Ambas as plataformas usam o mesmo contrato `DiagnosisRecommendation`. O Android envia para o mesmo worker Cloudflare.

**Diferenças de comportamento:**

| Aspecto | Android | PWA |
|---|---|---|
| Interface de chat | OrbitScreen completa com histórico de conversa | Não há chat — diagnóstico exibido como card |
| Perguntas contextuais | Sim (DiagnosticoScreen) | Não implementado na versão atual |
| Modo de exibição | Chat conversacional | Card estruturado com lista de problemas/ações |

---

### 2.3 Histórico de Testes

**O que faz:**
Lista todos os testes passados com data, métricas principais e qualidade. Permite visualizar detalhe de cada teste.

#### Android

**Tela:** `HistoryScreen` (`:featureHistory`)

**Funcionalidade:**
- Lista de testes ordenada por data (mais recente primeiro)
- Cada item: data/hora, DL, UL, latência, indicador de qualidade
- Gráficos de tendência via `MiniGrafico.kt`
- Persistência: Room Database (`MedicaoDao`, `MedicaoEntity`)

#### PWA

**Tela:** `HistoryScreen`

**Funcionalidade:**
- Lista de testes com mesmas métricas do Android
- Visualização de detalhe: abre dentro da própria tela (sem navegação)
- Gráficos: Recharts (biblioteca externa)
- Pull-to-refresh para recarregar
- Persistência: `localStorage` via `utils/history.ts`
- Exportação: PDF via jsPDF + html2canvas

**Diferenças de comportamento:**

| Aspecto | Android | PWA |
|---|---|---|
| Persistência | Room (SQLite) — dados sobrevivem reinstalação | localStorage — dados perdidos ao limpar browser |
| Exportação | PDF via `ExportHistoricoBottomSheet` — exporta histórico em PDF nativo Android | PDF gerado no browser |
| Gráficos | MiniGrafico (componente custom) | Recharts |
| Pull-to-refresh | Não | Sim |

---

### 2.4 Wi-Fi — Análise de Rede

**O que faz:**
Exibe informações sobre a rede Wi-Fi atual e redes próximas, incluindo sinal, banda, canal e qualidade.

#### Android

**Tela:** `SinalScreen` (`featureWifi/ui/WifiScreen.kt`)
**Módulo:** `:featureWifi`

**Funcionalidade implementada:**
- SSID da rede conectada
- RSSI em dBm (sinal atual)
- Banda: 2.4GHz / 5GHz / 6GHz
- Canal Wi-Fi (calculado a partir da frequência)
- Velocidade de link (Mbps)
- Frequência central (MHz)
- Scan de redes vizinhas ordenadas por sinal
- Tipo de segurança (aberta/WEP/WPA/WPA2/WPA3)
- Largura de canal (20/40/80/160 MHz)
- Empty state por banda (ORB-202)

**Features em desenvolvimento:**
- PHY Rate Display (ORB-203 — aguarda desbloqueio)
- MIMO Label (ORB-204 — aguarda desbloqueio)
- Mesh Node Identification (ORB-205 — pronto para implementar)

**Restrições Android:**
- `ACCESS_FINE_LOCATION` obrigatória — sem ela, SSID retorna `<unknown ssid>`
- Rate limiting de scan: 4 scans por 2 minutos (foreground)
- OEM quirks: Samsung e Xiaomi podem ter comportamentos diferentes

#### PWA

**Tela:** `LocalWifiScreen` (lazy-loaded)

**Funcionalidade:**
- Informação limitada ao que o browser expõe via `navigator.connection`
- Tipo de conexão (`wifi / mobile / cable / unknown`)
- Sem acesso a SSID, RSSI, canal, ou scan de redes vizinhas
- Labels amigáveis de sinal via `rssiLabel()`: Ótimo / Bom / Regular / Fraco (quando há contexto Wi-Fi)
- Labels simplificados: SSID → "Nome da rede", "Força do sinal" com dBm como detalhe técnico, "Velocidade Wi-Fi", "Frequência", "Roteador"
- Estado indisponível reescrito com contexto claro (v1.3.0)

**iOS WiFi Context via Atalho (v1.3.0 — implementado):**
- `WifiContextCard` (componente) — exibe contexto Wi-Fi capturado via Atalho iOS antes do teste
- `wifiShortcut.ts` — módulo com funções: `parseWifiCallback`, `savePendingWifiContext`, `consumePendingWifiContext`, `runWifiShortcut`, `generateSessionId`
- Integrado em `App.tsx`, `ResultScreen.tsx` e `StartScreen.tsx`
- Contexto capturado é preservado no campo `wifiContext` de `SpeedTestResult`

**Estado de capacidade:** A tela exibe estado informativo de "recurso indisponível no browser" quando tentado fora do app nativo (Capacitor).

> **Android:** Análise Wi-Fi completa — SSID, RSSI, banda, canal, redes vizinhas
> **PWA:** Informação de tipo de conexão apenas. Wi-Fi detalhado impossível no browser. Contexto Wi-Fi disponível via Atalho iOS (integração opcional do usuário).

---

### 2.5 Dispositivos na Rede

**O que faz:**
Lista dispositivos conectados à rede local doméstica.

#### Android

**Tela:** `DevicesScreen` (`featureDevices/ui/DevicesScreen.kt`)
**Módulo:** `:featureDevices`

**Funcionalidade:**
- Scan de dispositivos na rede local
- Lista com hostname, IP, MAC
- Apelidos personalizados (persistidos via `ApelidoDispositivoDao`)
- Indicador de uso/atividade
- Identificação de fabricante por OUI — base expandida em v0.7.1 para +50 fabricantes novos: ZTE (12 OUIs), Sagemcom (6), Ubiquiti (6), Tenda (4), Dell (4), HP (4), Lenovo (4), OnePlus (3), Oppo (3), Realme (3), Nintendo (3), Roku (3)

#### PWA

**Tela:** `LocalNetworkScreen` (lazy-loaded)

**Funcionalidade:**
- Limitada — APIs web não permitem scan LAN completo
- Pode exibir informações do dispositivo local via APIs do browser
- Estado de "capacidade indisponível" para scan de rede completo

> **Android:** Scan LAN real com apelidos personalizados persistidos
> **PWA:** Capacidade muito reduzida. Scan de rede local impossível no browser.

---

### 2.6 DNS — Benchmark e Guia

**O que faz:**
Mede e compara latência de diferentes servidores DNS. Recomenda o melhor para o usuário.

#### Android

**Tela:** `DnsScreen` (`featureDns/ui/DnsScreen.kt`)
**Módulo:** `:featureDns`

**Funcionalidade:**
- Benchmark DoH de 6 resolvedores: DNS do sistema (via `InetAddress`) + Cloudflare, Google DNS, Quad9, OpenDNS, AdGuard
- Metodologia P50 — 3 rounds por provedor, descarta round 0 (warmup); amostras < 3ms do sistema são descartadas (provávelmente cache SO)
- Resultados ranqueados por latência em tempo real (publicação parcial após cada provedor medido)
- Grade de rapidez: A (≤ 15ms), B (≤ 30ms), C (≤ 50ms), D (> 50ms)
- Detecção automática do DNS do sistema: por IP (mapa de IPs de 10 provedores conhecidos) ou hostname de Private DNS configurado

#### PWA

**Integrado em:** `DNSGuideSheet` (bottom sheet dentro da `ResultScreen`)

**Funcionalidade:**
- Benchmark interno dos 5 servidores DoH (DNS over HTTPS)
- Recomendação inteligente baseada na latência medida
- Guia de configuração por plataforma (Android, iOS, Windows, macOS, roteador)
- Latência DNS medida via Resource Timing API (`dnsLatencyMs`)
- Provedor detectado via DoH whoami (`dnsResolverIp`, `dnsProvider`)

**Diferenças de comportamento:**

| Aspecto | Android | PWA |
|---|---|---|
| Acesso | Tela dedicada `DnsScreen` | Bottom sheet dentro de ResultScreen |
| Protocolo DNS testado | DoH (HTTPS) para provedores públicos + `InetAddress` para DNS do sistema | DoH (DNS over HTTPS) |
| Guia de configuração | Não — apenas resultados de benchmark ranqueados | Sim, por plataforma |

---

### 2.7 Fibra Ótica

**O que faz:**
Exibe informações e diagnóstico específicos para conexões via fibra ótica.

#### Android

**Tela:** `FibraScreen` (`featureFibra/ui/FibraScreen.kt`)
**Módulo:** `:featureFibra`

**Funcionalidade:**
- Conecta ao modem Nokia GPON (série SA/NT) via HTTP local — autenticação, leitura de status
- Estados da tela: `idle` (aguardando conexão automática), `conectando` (carregando), `concluido` (dados exibidos), `erro` (mensagem específica + botão retry)
- Seção "Sinal da Fibra": potência RX/TX em dBm, temperatura do laser, serial ONU — com grades visuais (Ótimo/Normal/Fraco)
- Seção "Sua Conexão": IP externo, detecção de CGNAT (RFC 6598 + RFC 1918), tipo (PPPoE/IPoE), tempo conectado
- Seção "Saúde do Modem": temperatura, tensão de alimentação, firmware, modelo, uptime do dispositivo
- Seção "Instabilidade recente" (condicional): exibe quando há `ppp.lastError` diferente de `ERROR_NONE`
- Dispositivos não suportados (ex.: TP-Link): estado especial com card informativo
- Configuração do modem: feita na `AjustesScreen` (host IP, usuário, senha, permanecer conectado)

**Presets de acesso rápido (v0.7.1):** Row com 3 TextButton exibidos antes do formulário manual. Permite preencher credenciais com um toque para os modelos mais comuns:

| Preset | Host | Usuário | Senha |
|---|---|---|---|
| Nokia / ONT | 192.168.1.1 | user | (vazio) |
| Intelbras | 192.168.1.1 | admin | admin |
| TP-Link | 192.168.0.1 | admin | (vazio) |

Default username do campo manual alterado de `"userAdmin"` para `"user"` (padrão Nokia/GPON).

> **Android:** Feature implementada em módulo dedicado.
> **PWA:** Feature ausente. Não prevista no roadmap atual.

---

### 2.8 Monitoramento Passivo — LinkaPulse

**O que faz:**
Monitora a qualidade da conexão em background, sem interação do usuário. Emite alertas quando detecta degradação.

#### Android

**Telas:** `LinkaPulseScreen`, `PassiveMonitoringScreen`

**Arquitetura:**
- `WorkManager` — agendamento periódico (30 min)
- `MonitoramentoWorker` — executa speedtest silencioso
- `LinkaPulseOrchestrator` — orquestra diagnóstico local + IA

**Fases de execução:**
1. **Collecting** — speedtest silencioso (~30–60s)
2. **Thinking** — diagnóstico local (engines sem IA)
3. **Analyzing** — chamada ao AI gateway

**Alertas gerados:**

| Alerta | Condição | Severidade |
|---|---|---|
| Velocidade Baixa | DL < 25 Mbps | Warn |
| Latência Alta | Latência > 80 ms | Warn |
| Instabilidade | Oscilação (Jitter) > 50 ms OU Perda > 2% | Fail |
| Wi-Fi Fraco | RSSI < -70 dBm | Warn |

**Controles de alerta:**
- Cooldown: 2 horas (sem repetição de alerta)
- Teto: 3 alertas/dia

**Configuração do usuário:** habilitar/desabilitar, intervalo (15/30/60 min), notificações on/off

#### PWA

**Tela:** `PulseScreen` (lazy-loaded)

**Funcionalidade:**
- Exibição de resultados do Pulse
- Sem background monitoring real via browser (Service Worker não tem acesso a network measurement)
- Via app Capacitor (Android nativo do PWA): pode ter funcionalidade mais próxima do Android

> **Android:** Monitoramento passivo real em background com WorkManager.
> **PWA:** Tela de visualização existe; background monitoring contínuo não é possível no browser puro. Via Capacitor, parcialmente possível.

---

### 2.9 Configurações / Ajustes

**O que faz:**
Permite ao usuário ajustar preferências do app.

#### Android

**Tela:** `SettingsScreen` (`featureSettings/ui/SettingsScreen.kt`)

**Configurações disponíveis** (tela `AjustesScreen.kt` em `:app`):

Seção "Rede e conexão":
- Provedor de internet (operadora, plano contratado, cidade/região)
- Configurações do roteador/modem (host IP, usuário, senha do Nokia GPON)

Seção "Experiência do app":
- Tema: Sistema / Claro / Escuro (3 opções visual com ícone)
- Notificações (abre configurações do sistema)

Seção "Medição e alertas":
- Alertas de qualidade (limite mínimo de download em Mbps)
- Análise avançada da conexão (toggle — aumenta consumo de bateria)
- Monitoramento passivo (toggle — acompanhado de aviso OEM para Samsung/Xiaomi/Moto)

Seção "Histórico e dados":
- Histórico de testes (acesso direto)
- Laudos técnicos (acesso direto)
- Dados usados pelo Linka (informativo + link para solicitar exclusão)
- Gerenciar dados locais (limpar histórico / apagar dados locais)

Seção "Ajuda e sobre":
- Novidades (changelog inline por versão)
- Diagnóstico do app (integridade, assinatura, versão)
- Permissões do sistema (abre configurações do sistema)
- Redefinir o app (com confirmação — irreversível)
- Sobre o Linka (versão, plataforma, central de medição, suporte)

#### PWA

**Integrado em:** `StartScreen` (bottom sheet) + `ExploreScreen` (hamburger menu)

**Configurações disponíveis:**
- Unidade: Mbps / Gbps (default: Mbps)
- Tipo de conexão: Auto / Wi-Fi / Cable / Celular
- Servidor de teste (atualmente só Cloudflare)
- Privacidade de IP ao compartilhar: Ocultar / Mostrar
- Tema: Light / Dark (toggle na StartScreen)
- Modo padrão: Rápido / Completo
- Perfil gamer: Off / Casual / MOBA / FPS / Cloud Gaming
- "Ver tutorial novamente" (ExploreScreen)

**Persistência:** `localStorage` via `useSettings` hook

**Diferenças de comportamento:**

| Aspecto | Android | PWA |
|---|---|---|
| Localização | Tela dedicada | Distribuído (StartScreen + ExploreScreen) |
| Persistência | Jetpack DataStore (`PreferenciasAppRepository`) — arquivo `linkaPreferencias` | localStorage |
| Tema | Preferência persistida | Toggle inline na StartScreen |
| Perfil gamer | Não | Sim — 4 perfis |

---

### 2.10 Relatório / Laudo

**O que faz:**
Gera relatório técnico detalhado do diagnóstico para compartilhamento ou arquivo.

#### Android

**Tela:** `LaudoScreen` (`app/ui/screens/ReportScreen.kt`)

**Funcionalidade:**
- Tela `LaudoScreen` acessível via `AjustesScreen` (seção "Histórico e dados")
- Exportação de histórico via `ExportHistoricoBottomSheet` (bottom sheet nativo Android)
- Formato de exportação: não documentado em detalhe no código lido — verificar em `LaudoScreen.kt`

#### PWA

**Funcionalidade:**
- Geração de PDF via jsPDF + html2canvas
- Compartilhamento via botão no TopBar da ResultScreen
- PDF gerado no browser, sem servidor

---

### 2.11 Features Exclusivas do PWA

Estas features existem apenas no PWA. Não há equivalente Android implementado.

#### Onboarding (1ª execução)

Carousel de 3 cards full-screen, exibido apenas na primeira execução.
- Flag de controle: `localStorage.linka.onboarding.done`
- Conteúdo: apresentação do produto, casos de uso, explicação de permissões
- Acesso posterior: "Ver tutorial novamente" no menu da ExploreScreen

#### Comparar Locais

Compara resultado do teste em dois locais (perto vs. longe do roteador).
- Dois testes consecutivos
- Comparação de DL, UL, latência com percentual de variação
- Diagnóstico: `coverage_issue / both_bad / both_good / other`

#### Antes e Depois

Compara resultado antes e depois de uma ação (ex: reiniciar roteador).

#### Prova Real (3×)

Executa 3 testes completos consecutivos e exibe a média. Reduz variação estatística.

#### Teste por Cômodo

Permite rotular cada teste com o cômodo onde foi feito (sala, quarto, etc.).
Campo `locationTag` salvo em `TestRecord`.

#### ~~Modo Gamer~~ (Removido — v1.3.0)

`GamerScreen` removida no Wave 5 (2026-05-16). O perfil de avaliação por jogo (Casual / MOBA / FPS / Cloud Gaming) foi descontinuado conforme recomendação do assessment da Cloude Consultoria: nicho dentro de nicho, usuário avançado usa ferramentas específicas, diagnóstico IA cobre o caso de uso com mais profundidade. O tipo `GamingProfile` pode ainda existir em `src/types/index.ts` como legado — não exposto na UI.

---

### 2.12 Aviso de Dados Móveis (v1.3.0 — PWA)

**O que faz:**
Exibe aviso antes do teste quando o dispositivo está em dados móveis, informando o consumo estimado.

#### PWA

**Tela:** `StartScreen`

**Comportamento:**
- Detecta tipo de conexão (via `navigator.connection` e contexto Capacitor)
- Quando em dados móveis (iOS ou Android via Capacitor): exibe card/banner de aviso antes de permitir início do teste
- Conteúdo: estimativa de consumo de dados do teste
- Usuário confirma antes de prosseguir

**Motivação (assessment Cloude Consultoria):** Reclamação #1 no mercado. Speedtest e Fast.com consomem 500 MB sem aviso. Usuários BR com plano controle/pré-pago são especialmente sensíveis.

> **Android nativo:** Não implementado — gap identificado no assessment.
> **PWA:** Implementado em v1.3.0.

---

### 2.13 Comparação RQUAL Anatel — Plano Contratado (v1.3.0 — PWA)

**O que faz:**
Compara o resultado do speedtest contra os limites regulatórios RQUAL da Anatel, calculando o percentual entregue vs. o plano contratado declarado pelo usuário.

#### PWA

**Tela:** `ResultScreen` (breakdown inline)

**Comportamento:**
- Usuário pode declarar sua velocidade contratada (Mbps)
- O sistema avalia DL e UL separadamente
- Exibe breakdown com percentual entregue vs. limite RQUAL:
  - **Limite instantâneo:** 40% da velocidade contratada
  - **Limite médio:** 80% da velocidade contratada
- InfoTooltip exibe explicação multiparágrafo sobre os direitos do consumidor

**Motivação (assessment Cloude Consultoria):** Nenhum concorrente faz isso bem. Argumento jurídico real (rescisão sem multa). "Provar que a operadora está te enganando" é o caso de uso emocional mais forte do mercado.

> **Android nativo:** Não implementado — gap identificado no assessment.
> **PWA:** Implementado em v1.3.0.

---

### 2.14 CGNAT — Banner de Alerta (v1.3.0 — PWA)

**O que faz:**
Detecta quando o usuário está por trás de CGNAT (Carrier Grade NAT) e exibe alerta com explicação em linguagem natural sobre os impactos práticos.

#### Android

**Localização:** `FibraScreen` — seção "Sua Conexão"

**Comportamento:**
- Detecta CGNAT via RFC 6598 (100.64.0.0/10) + RFC 1918 (192.168.x.x / 10.x.x.x)
- Exibe IP externo, tipo (PPPoE/IPoE), tempo conectado e flag de CGNAT

**Limitação atual:** A FibraScreen exige conexão ao modem Nokia GPON. Usuários sem fibra Nokia não veem a detecção de CGNAT. A explicação é técnica.

#### PWA

**Localização:** `HomeScreen` — banner de alerta (v1.3.0)

**Comportamento:**
- Detecta CGNAT via verificação do IP externo
- Quando detectado: exibe banner na HomeScreen com alerta visível
- Linguagem natural: impactos práticos (câmeras, jogos, VPN) e próximos passos

**Motivação (assessment Cloude Consultoria):** Endemia brasileira. O usuário não sabe por que câmeras param, jogos caem, VPNs não funcionam. Custo de implementação muito baixo.

> **Android:** Detecção na FibraScreen (requer modem Nokia). Explicação técnica — gap de apresentação identificado no assessment.
> **PWA:** Banner na HomeScreen implementado em v1.3.0.

---

## 3. Contratos Compartilhados

### 3.1 Schema de Diagnóstico (Compartilhado)

Ambas as plataformas usam o mesmo contrato de entrada/saída para o sistema de diagnóstico.

**Referência:** `linkaSpeedtestPwa/docs/CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1.md`

O worker Cloudflare (`linka-ai-diagnosis-worker.giammattey-luiz.workers.dev`) é usado por Android e PWA.

**Inputs compartilhados:**
- `dl` — Download (Mbps)
- `ul` — Upload (Mbps)
- `latency` — RTT mediano (ms)
- `jitter` — MAD da latência (ms)
- `packetLoss` — Perda de pacotes (%)
- `connectionType` — `wifi / mobile / cable / unknown`
- `timestamp` — Unix ms

**Dois caminhos de diagnóstico:**
1. IA (Claude API via Cloudflare Worker) — análise contextual
2. Rules Engine v1 — fallback determinístico, sem dependência externa

### 3.2 Thresholds de Qualidade (Compartilhados)

Baseados em `CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1.md` e nas regras de alerta do LinkaPulse:

| Métrica | Bom | Aceitável | Ruim |
|---|---|---|---|
| Download | ≥ 25 Mbps | 10–24 Mbps | < 10 Mbps |
| Latência | ≤ 80 ms | 80–150 ms | > 150 ms |
| Oscilação (Jitter) | ≤ 50 ms | 50–100 ms | > 100 ms |
| Perda de pacotes | ≤ 2% | 2–5% | > 5% |
| RSSI Wi-Fi | > -70 dBm | -70 a -80 dBm | < -80 dBm |

> Nota: Thresholds acima são os documentados. Valores exatos do rules engine do PWA podem ter granularidade adicional — consulte `CONTRATO_DIAGNOSTICO_RECOMENDACOES_V1.md`.

### 3.3 Métricas e Nomenclatura (Compartilhadas)

As métricas usam as mesmas unidades e nomenclatura nas duas plataformas:

| Métrica | Unidade | Cor semântica | Label ao usuário (Android v0.7.1+) |
|---|---|---|---|
| Download | Mbps | Azul (`#3AB6FF` dark / `#0A84FF` light) | Download |
| Upload | Mbps | Verde (`#22C55E` dark / `#30D158` light) | Upload |
| Latência | ms | Roxo/accent (`#6C2BFF`) | Latência |
| Jitter | ms | Amarelo/aviso (`#F5A623`) | **Oscilação** (renomeado de "Jitter" em v0.7.1) |
| Perda de pacotes | % | Vermelho/erro (`#FF453A` dark) | Perda de pacotes |

> **Android v0.7.1:** O termo "Jitter" foi renomeado para "Oscilação" em todas as telas onde aparecia visível ao usuário (`ResultadoVelocidadeScreen`, `HistoricoScreen`, `LaudoScreen`, `HomeScreen`). O campo interno de dados continua chamado `jitter` (sem mudança de contrato). O PWA mantém "jitter" nos tipos internos e pode usar linguagem mais técnica conforme contexto de tela.

### 3.4 Navegação e Deep Linking

**Android:** Deep links habilitados com schema `linka://screen/...` via `AppNavGraph.kt`

**PWA:** Navegação por stack manual em `App.tsx` via `useState<Screen>`. Sem `react-router`. Suporte a gestos: swipe horizontal para navegar, pull-to-refresh em `StartScreen` e `HistoryScreen`.

---

## 4. Mapa de Telas — Android vs. PWA

| # | Tela Android | Módulo Android | Equivalente PWA | Paridade |
|---|---|---|---|---|
| 1 | `HomeScreen` | `:featureHome` | `StartScreen` | Alta — fluxo principal alinhado |
| 2 | `SpeedTestScreen` | `:featureSpeedtest` | `RunningScreen` | Alta — estados de execução compatíveis |
| 3 | `ResultadoVelocidadeScreen` | `:featureSpeedtest` | `ResultScreen` | Média/Alta — necessita ajuste fino visual |
| 4 | `SinalScreen` | `:featureWifi` | `LocalWifiScreen` | Baixa — PWA com capacidade reduzida |
| 5 | `DevicesScreen` | `:featureDevices` | `LocalNetworkScreen` | Baixa — scan LAN impossível no browser |
| 6 | `DnsScreen` | `:featureDns` | `DNSGuideSheet` | Média — integrado na ResultScreen no PWA |
| 7 | `DiagnosticoScreen` | `:featureDiagnostico` | ResultScreen (card) | Média — abordagem diferente |
| 8 | `OrbitScreen` | `:featureDiagnostico` | Parcial em App/Pulse | Média — chat completo só no Android |
| 9 | `FibraScreen` | `:featureFibra` | Ausente | — |
| 10 | `HistoryScreen` | `:featureHistory` | `HistoryScreen` | Alta — estrutura funcional estável |
| 11 | `SettingsScreen` | `:featureSettings` | StartScreen + ExploreScreen | Média — organização diferente |
| 12 | `LaudoScreen` | `:app` | PDF export (ResultScreen) | Média — PDF no PWA |
| 13 | `LinkaPulseScreen` | `:app` | `PulseScreen` | Média — feature nova |
| 14 | `PassiveMonitoringScreen` | `:app` | Parcial | Baixa — WorkManager só Android |
| — | Ausente | — | `OnboardingScreen` | — |
| — | Ausente | — | `ComparisonScreen` | — |
| — | Ausente | — | `BeforeAfterScreen` | — |
| — | Ausente | — | `RoomTestScreen` | — |
| — | Ausente | — | `ExploreScreen` | — |

---

## 5. Gaps do Assessment da Cloude Consultoria — Pendentes

> Referência: `E:\Projetos\Linka\docs\Assesment\linka_roadmap_tabela.html`
> Itens implementados nas Waves 5-7 foram removidos desta lista e documentados nas seções acima.

### 5.1 Pendentes de Alta Prioridade ("Implementar Agora")

| Gap | Plataforma | Status |
|---|---|---|
| Aviso de dados móveis antes do teste | Android | Não implementado |
| RQUAL Anatel — comparação de plano | Android | Não implementado |
| Onboarding | Android | Não implementado |
| Declaração de privacidade como feature explícita | Android + PWA | Não implementado (PWA tem card no onboarding, mas sem destaque como feature de marketing) |
| Controles granulares do LinkaPulse (só Wi-Fi, bateria mínima, KB/dia exibido) | Android | Parcial — toggle e intervalo existem; sem restrição por bateria/dados |
| Laudo PDF reposicionado como "prova Anatel" (RQUAL + direitos do consumidor) | Android + PWA | Não implementado |
| Alerta de band steering — avisar quando em 2.4GHz com 5GHz disponível | Android | Não implementado |
| CGNAT — explicação em linguagem natural (FibraScreen Android) | Android | Detecta mas explicação é técnica |

### 5.2 Pendentes de Média Prioridade ("Melhorar")

| Gap | Plataforma | Status |
|---|---|---|
| Diagnóstico IA — nível de confiança ("alta/média/baixa certeza") e linguagem conservadora | Android + PWA | Não implementado |
| Interpretação de métricas por caso de uso (streaming, gaming, videochamada, download) | Android + PWA | Parcial — SpeedTestDiagnostics tem `streamingVerdict`, `gamingVerdict`, `videoCallVerdict` no PWA mas exibição na UI não confirmada em detalhe |
| Recomendação acionável de canal Wi-Fi em português ("Canal 6 lotado — mude para canal 11") | Android | Não implementado |
| LinkaPulse — exibir custo real KB/dia e diferenciar ping leve de teste completo | Android | Não implementado |
| Orbit/Chat — guardrails de alucinação, disclaimer na UI, cache de diagnósticos comuns | Android | Não implementado |
| Prova Real (3×) — trazer para Android | Android | Não implementado |
| Bufferbloat — explicação coloquial e regra no Rules Engine baseada em delta loaded/unloaded | Android + PWA | Bufferbloat medido; explicação coloquial ausente |
| Histórico PWA — gráfico de tendência mais visível, comparação mês a mês | PWA | Parcial |

### 5.3 Pendentes de "Retirar/Simplificar"

| Gap | Plataforma | Status |
|---|---|---|
| Configuração manual do modem (AjustesScreen) — esconder atrás de "avançado" por padrão | Android | Presets existem (v0.7.1) mas formulário manual ainda visível por padrão |
| Terminologia técnica — usar termos coloquiais como label primário em todas as telas | Android + PWA | Parcial — "Oscilação" implementado, mas RTT, dBm, jitter, DoH ainda expostos sem contexto em algumas telas |
| PWA — telas sem paridade real (LocalWifi, LocalNetwork) — decidir: Capacitor ou remover da nav | PWA | Pendente de decisão |
| Orbit — restringir escopo ao diagnóstico atual (não chat aberto sem dados de rede) | Android | Não implementado |

---

## 6. Notas de Manutenção

- Quando uma feature muda de comportamento em uma plataforma, atualizar este documento **na mesma tarefa**.
- Seções com `[a confirmar]` indicam comportamento não verificado em código — não especular, verificar e atualizar.
- Features marcadas como "Parcial" no PWA devem ser reavaliadas quando o Capacitor for atualizado ou quando APIs de browser evoluírem.
- Referência de paridade original: `linkaSpeedtestPwa/docs/ORB-151_Avaliacao_Tecnica_Paridade_PWA_Android.md`
- Assessment da Cloude Consultoria: `E:\Projetos\Linka\docs\Assesment\linka_roadmap_tabela.html` — última revisão 2026-05-16.
