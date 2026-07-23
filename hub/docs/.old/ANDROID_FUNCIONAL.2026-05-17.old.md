# Documentação Funcional — Android Linka

**Público-alvo:** Desenvolvedor humano (dev novo ou colaborador)
**Plataforma:** Android exclusivo
**Última atualização:** 2026-05-17
**Mantido por:** Taisa

> Este documento responde: "O que o app Android faz, tela por tela, da perspectiva do usuário?"
> Para arquitetura interna e engines, consulte `ANDROID_TECNICO.md`.
> Para documentação cross-platform (Android + PWA), consulte `FUNCIONAL_CROSSPLATFORM.md`.

---

## 1. Visão Geral da Navegação

O app tem uma NavigationBar inferior com 5 abas fixas. Telas secundárias são sobrepostas com animação `slideInVertically` e têm botão "Voltar" — não são abas.

```
NavigationBar (5 abas)
├── [0] Home
├── [1] Diagnóstico  ← ResultadoVelocidadeScreen ou OrbitScreen (condicional)
├── [2] Dispositivos
├── [3] Histórico
└── [4] Ajustes

Telas sobrepostas (não são abas)
├── SpeedTestScreen    ← abre ao clicar "Testar velocidade"
├── VelocidadeScreen   ← aparece durante a execução do teste
├── ResultadoVelocidadeScreen  ← pós-teste (fluxo manual)
├── ChatScreen         ← IA conversacional (Orbit)
├── FibraScreen        ← abre nos Ajustes
├── SinalScreen        ← abre na HomeScreen
├── LaudoScreen        ← abre nos Ajustes
└── Sheets
    ├── DNS Benchmark BottomSheet  ← abre no SpeedTestScreen
    ├── PerfilEditSheet            ← abre na HomeScreen
    └── ExportHistoricoBottomSheet ← abre no HistoricoScreen
```

**Onboarding:** o app tem `OnboardingScreen`. É exibida na primeira execução (quando `onboarding_concluido = false` no DataStore). Após conclusão, nunca é exibida novamente.

---

## 2. Telas Principais

### 2.1 HomeScreen

**Arquivo:** `app/src/main/kotlin/.../ui/screen/HomeScreen.kt`
**Aba:** 0 — Home

**O que o usuário vê:**
- Status de conexão atual (tipo: Wi-Fi, dados móveis, ethernet, desconectado)
- SSID da rede conectada (quando Wi-Fi)
- Informações do ISP (operadora, ASN, IP público)
- Mini-gráfico de histórico de velocidade
- Última medição (download, upload, latência)
- Informações de sinal móvel (quando em dados móveis)
- Nome do usuário e foto de perfil
- Botão de iniciar teste de velocidade

**Ações disponíveis:**
- Iniciar teste de velocidade → abre `SpeedTestScreen`
  - Se estiver em dados móveis: exibe `ForaDoWifiDialog` antes de abrir o SpeedTest
- Abrir histórico → navega para aba 3
- Abrir perfil → abre `PerfilEditSheet`
- Abrir redes Wi-Fi → abre `SinalScreen`
- Abrir diagnóstico → navega para aba 1

**Estados visuais:**
- Conectado em Wi-Fi: exibe SSID, RSSI, banda
- Conectado em dados móveis: exibe operadora, tecnologia (4G/5G), RSRP
- Desconectado: estado sem internet
- Com dados de histórico: exibe mini-gráfico
- Sem dados de histórico: estado vazio

### 2.2 DiagnosticoScreen / OrbitScreen / ResultadoVelocidadeScreen

**Aba:** 1 — Diagnóstico

Esta aba tem comportamento condicional:

**Quando há resultado de speedtest disponível:**
→ Exibe `ResultadoVelocidadeScreen` com o diagnóstico do último teste.

**Quando não há resultado:**
→ Exibe `OrbitScreen` — o assistente IA interativo (Orbit).

#### ResultadoVelocidadeScreen

**O que o usuário vê:**
- Métricas do último teste: download, upload, latência, jitter, perda de pacotes
- Diagnóstico do resultado (status: bom, regular, crítico)
- Classificação técnica por categoria (velocidade, estabilidade, Wi-Fi, DNS)
- Impacto por uso: streaming, videochamada, games, trabalho, navegação
- Ações recomendadas pela IA
- Localização do servidor de teste
- Hipóteses descartadas (se disponível)
- Perguntas contextuais da IA (chips de resposta)
- Botão "Testar novamente"
- Botão "Abrir chat" → abre `ChatScreen` (Orbit)

#### OrbitScreen

**O que o usuário vê:**
- Estado Orbit: Idle, Collecting, Thinking, Analyzing, AwaitingInput, Success, Warning, Critical
- Mensagem de boas-vindas quando Idle
- Animação de "pensando" durante análise
- Perguntas contextuais com chips de resposta
- Resultado do diagnóstico quando disponível

**Ações disponíveis:**
- Iniciar sessão Orbit → coleta dados, roda speedtest silencioso, analisa
- Responder perguntas contextuais (chips ou texto livre)
- Resetar sessão

#### ChatScreen

**O que o usuário vê:**
- Histórico de mensagens (IA + usuário)
- Bolhas de mensagem: IA, usuário, pensando, resultado técnico
- Área de input de texto livre
- Chips de resposta rápida
- TopBar com título e botão de reset

**Ações disponíveis:**
- Enviar mensagem de texto livre
- Selecionar chip de resposta
- Voltar (fecha o chat, retorna ao ResultadoVelocidadeScreen)
- Resetar sessão Orbit

### 2.3 DispositivosScreen

**Arquivo:** `app/src/main/kotlin/.../ui/screen/DispositivosScreen.kt`
**Aba:** 2 — Dispositivos

**O que o usuário vê:**
- Lista de dispositivos detectados na rede local
- Para cada dispositivo: nome/apelido, IP, MAC mascarado, fabricante, tipo
- Indicação de "este dispositivo" (o próprio celular)
- Serviços mDNS detectados por dispositivo
- Estado do scan: carregando, concluído, erro

**Ações disponíveis:**
- Atualizar lista de dispositivos (pull to refresh ou botão)
- Dar apelido a um dispositivo (salvo no Room)
- Ver detalhes de um dispositivo

**Estados visuais:**
- Loading: durante o scan
- Lista com dispositivos
- Vazio: nenhum dispositivo detectado
- Erro: sem permissão ou falha no scan

### 2.4 HistoricoScreen

**Arquivo:** `app/src/main/kotlin/.../ui/screen/HistoricoScreen.kt`
**Aba:** 3 — Histórico

**O que o usuário vê:**
- Gráfico de uptime (`UptimeGridChart`) — visualização temporal de disponibilidade
- Narrativa textual do uptime (gerada pelo `UptimeNarrativaEngine`)
- Resumo do histórico: total de medições, médias
- Lista de medições passadas com data, download, upload, latência
- Indicação de medições "contaminadas" (descartadas da análise)
- Distinção entre medições de speedtest completo e medições do monitor passivo

**Ações disponíveis:**
- Exportar histórico (CSV ou PDF) → `ExportHistoricoBottomSheet`

**Estados visuais:**
- Loading: carregando histórico do banco
- Com dados: gráfico + lista
- Vazio: sem medições ainda

### 2.5 AjustesScreen

**Arquivo:** `app/src/main/kotlin/.../ui/screen/AjustesScreen.kt`
**Aba:** 4 — Ajustes

**O que o usuário vê e configura:**

| Seção | Configuração | Tipo |
|---|---|---|
| Perfil | Nome do usuário, foto | Editar |
| Provedor | Operadora, plano contratado, região | Editar |
| Tema | Sistema / Claro / Escuro | Seletor |
| Monitoramento | Ligar/desligar monitoramento passivo | Toggle |
| Notificações | Latência, DNS, RSSI, sem internet | Toggle individual |
| Alerta de velocidade | Limite de Mbps para alerta | Número |
| Análise avançada | Modo de análise técnica avançada | Toggle |
| Fibra (modem Nokia) | Host, usuário, senha, manter conectado | Formulário |
| Ações | Limpar histórico, apagar dados, resetar app | Botões destrutivos |
| Informações | Nome do dispositivo, versão do app | Exibição |

**Ações disponíveis:**
- Salvar perfil
- Salvar dados do provedor
- Configurar e conectar ao modem de fibra → abre `FibraScreen`
- Gerar laudo → abre `LaudoScreen`
- Ir para o histórico → navega para aba 3

---

## 3. Telas Secundárias (Sobrepostas)

### 3.1 SpeedTestScreen

**Trigger:** Botão "Testar velocidade" na HomeScreen (ou via aba Diagnóstico quando sem resultado)

**O que o usuário vê:**
- Modo de teste selecionado: Completo (padrão) ou Rápido
- Informações do ISP e servidor de teste
- Status da conexão atual
- Botão iniciar teste
- Botão "Comparar DNS" → abre DNS Benchmark Sheet
- Botão "Ver diagnóstico" → vai para aba 1
- Histórico de velocidade resumido

**Ações disponíveis:**
- Selecionar modo de teste (Completo / Ping only)
- Iniciar teste → `VelocidadeScreen`
- Cancelar → fecha a tela

**Aviso de dados móveis:** se o usuário tentar iniciar um teste com dados móveis, um `AlertDialog` ("Sem Wi-Fi") avisa sobre o consumo de dados e pede confirmação antes de prosseguir.

### 3.2 VelocidadeScreen

**Trigger:** automático ao iniciar um teste de velocidade

**O que o usuário vê:**
- Gauge circular animado com valor em tempo real
- Fase do teste (download / upload / latência)
- Velocidade atual em Mbps
- Localização do servidor e ISP
- Progresso do teste

**Ações disponíveis:**
- Cancelar teste em andamento
- Reiniciar teste

### 3.3 SinalScreen

**Trigger:** Botão "Redes" na HomeScreen

**O que o usuário vê:**
- Rede Wi-Fi conectada: SSID, RSSI, banda (2.4/5/6GHz), canal, largura de canal, padrão Wi-Fi, velocidade de link
- Lista de redes Wi-Fi vizinhas: SSID, RSSI, banda, canal, segurança
- Informações de link layer (WifiLinkSnapshot)

**Ações disponíveis:**
- Atualizar scan de redes
- Voltar

### 3.4 FibraScreen

**Trigger:** Botão "Conectar" nos Ajustes (seção Fibra)

**O que o usuário vê:**
- Estado da conexão com o modem: conectando, conectado, erro
- Se conectado: dados da ONT GPON
  - Status GPON (up/down)
  - Potência Rx em dBm (qualidade do sinal recebido)
  - Potência Tx em dBm (sinal transmitido)
  - Temperatura da ONT em °C
  - Corrente do laser em mA
  - Voltagem de alimentação
  - Número serial
  - Modo de operação
- Status WAN (IP, máscara, gateway)
- Status PPP (se aplicável)
- Dados do dispositivo (modelo da ONT)
- Gateway IP detectado automaticamente
- Formulário de configuração: host, usuário, senha
- Toggle "Permanecer conectado"

**Ações disponíveis:**
- Conectar/reconectar ao modem
- Salvar configuração do modem
- Voltar

**Limites detectados:** Detecção de CGNAT na FibraScreen com explicação ao usuário.

### 3.5 LaudoScreen

**Trigger:** Botão "Gerar Laudo" nos Ajustes

**O que o usuário vê:**
- Laudo técnico completo da conexão
- Dados do usuário: nome, operadora, SSID, IPs
- Última medição: download, upload, latência, jitter, perda
- Velocidade contratada vs. medida (quando configurado)
- Diagnóstico completo em texto (gerado pela IA)
- Data e hora do laudo

**Ações disponíveis:**
- Voltar

### 3.6 ChatScreen

Ver seção 2.2 (DiagnosticoScreen) acima.

---

## 4. Sheets e Dialogs

### 4.1 DNS Benchmark Sheet

**Trigger:** Botão "Comparar DNS" no SpeedTestScreen

**O que o usuário vê:**
- Lista de servidores DNS comparados via DoH
- Para cada servidor: nome, latência em ms, grade (A/B/C/D)
- Badge "atual" no DNS em uso
- Badge "recomendado" no mais rápido (exceto o atual)
- Estado loading enquanto mede

**Dentro do sheet — guia de configuração:**
- Como alterar o DNS no Android (DNS Privado, passo a passo)
- Como alterar o DNS no roteador (passo a passo)

### 4.2 Perfil Edit Sheet

**Trigger:** Toque na foto/nome na HomeScreen

**O que o usuário vê/edita:**
- Nome do usuário (campo de texto)
- Foto de perfil (upload de imagem)
- Nome do dispositivo (somente leitura)
- Versão do app (somente leitura)

### 4.3 Export Histórico Sheet

**Trigger:** Botão de exportação no HistoricoScreen

**Formatos de exportação:** CSV, PDF

### 4.4 ForaDoWifiDialog

**Trigger:** Tentativa de iniciar speedtest com dados móveis

**O que exibe:** Aviso de consumo de dados com opções "Continuar mesmo assim" e "Cancelar".

---

## 5. Onboarding

**Arquivo:** `OnboardingScreen.kt`

**Quando exibido:** Primeira execução (flag `onboarding_concluido = false` no DataStore).

**Comportamento:** Exibido uma única vez. Após conclusão, nunca mais aparece.

---

## 6. Monitoramento Passivo

**Como ativar:** Toggle "Monitoramento ativo" em Ajustes.

**O que faz em background:**
- Mede latência periodicamente (HTTP)
- Mede tempo de resolução DNS
- Coleta RSSI atual do Wi-Fi
- Persiste medições no histórico (visíveis no HistoricoScreen como pontos no gráfico de uptime)
- Dispara notificações quando detecta problemas persistentes (histerese)

**Notificações de alerta (configuráveis individualmente):**
| Tipo | Trigger | Toggle em Ajustes |
|---|---|---|
| Latência alta | Latência persistentemente elevada | Sim |
| DNS lento | DNS do provedor mais lento que alternativas | Sim |
| Sinal Wi-Fi fraco | RSSI abaixo do limiar | Sim |
| Sem internet | Sem conectividade | Sim |

**Histerese:** cada tipo de alerta só é disparado se a condição persistir entre verificações. Evita spam de notificações.

---

## 7. Features Exclusivas Android

As seguintes funcionalidades existem apenas no Android e não têm equivalente no PWA:

| Feature | Por quê é exclusiva |
|---|---|
| Scan de redes Wi-Fi com SSID, RSSI, canal | Requer `WifiManager` Android |
| Scan de dispositivos na rede (ARP, mDNS, port scan) | Requer acesso LAN nativo |
| Monitoramento passivo em background | Requer WorkManager / background execution |
| Leitura de dados da ONT GPON (FibraScreen) | Acesso HTTP ao modem local |
| Sinal de dados móveis (RSRP, RSRQ, SINR, banda) | Requer `TelephonyManager` |
| Gráfico de uptime com medições passivas | Requer histórico do monitoramento |
| Notificações de alerta de rede | Requer permissão de notificação + background |

---

## 8. Diagnóstico — Fluxo Completo

### 8.1 Fluxo via SpeedTest (manual)

```
1. Usuário toca "Testar velocidade"
2. SpeedTestScreen: usuário escolhe modo (Completo/Rápido)
3. VelocidadeScreen: gauge animado em tempo real
4. Teste concluído
5. ResultadoVelocidadeScreen: resultado + diagnóstico da IA
   └── [opcional] Abrir chat → ChatScreen (Orbit)
```

### 8.2 Fluxo via Orbit (assistente IA)

```
1. Aba Diagnóstico (sem resultado de speedtest)
2. OrbitScreen exibida
3. Usuário inicia sessão Orbit
4. Orbit coleta dados da rede (Wi-Fi, móvel, histórico)
5. Orbit roda speedtest silencioso (sem abrir VelocidadeScreen)
6. Orbit analisa com a IA
7. OrbitScreen exibe resultado inline (Success/Warning/Critical)
8. Perguntas contextuais exibidas para refinamento
9. [opcional] ChatScreen para diálogo contínuo
```

### 8.3 Lógica de diagnóstico

O diagnóstico local é feito por engines sequenciais:

```
DiagnosticOrchestrator
├── WifiSignalQualityEngine    → qualidade do sinal Wi-Fi
├── InternetDiagnosticEngine   → velocidade, latência, jitter, perda, bufferbloat
├── WifiChannelDiagnosticEngine → congestionamento de canal
├── DnsDiagnosticEngine        → qualidade do DNS
├── HistoricalDegradationEngine → tendência histórica
├── FibraSignalQualityEngine   → qualidade da fibra óptica (se disponível)
├── MobileSignalDiagnosticEngine → sinal móvel (se em dados móveis)
└── DiagnosticDecisionEngine   → decisão final consolidada
```

O resultado local é então enviado ao Worker Cloudflare com todos os dados brutos. A IA (Gemma 4 26B) produz o diagnóstico final em linguagem natural. Se a IA falhar, o `AiFallbackFactory` gera um resultado local sem IA.

---

## 9. Versão e Build

**Versão exibida em:** Ajustes → Informações (campo "Versão")

**BuildConfig.VERSION_NAME** é injetado diretamente no `AjustesScreen` e no `PerfilEditSheet`.
