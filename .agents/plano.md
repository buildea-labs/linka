# Plano de Feature: Identificação do Gateway / Roteador Wi-Fi

> **Trilha:** Full-flow | **Produto:** Íris | **Arquitetura:** Camillo | **Orquestração:** Codex

## 1. Objetivo
Permitir que o Linka identifique de forma confiável o gateway IPv4 da rede Wi-Fi atual (ex.: `192.168.1.1`), detecte a acessibilidade da interface web e infira fabricante/modelo básico quando houver evidência suficiente, oferecendo ação direta de **"Abrir configurações"** no Assist e em Detalhes da Medição.

## 2. Mudança Arquitetural
- **`NetworkDiagnostics`**:
  - `LocalGatewayDiscovery`: leitura de `getifaddrs` e rotas BSD para extrair IP do gateway.
  - `GatewayProber` & `GatewayVendorFingerprinter`: sondagem HTTP/HTTPS assíncrona com timeout estrito e detecção de interface de administração/indícios de fabricante.
  - `GatewayInfo`: modelo de dados com IP, status de acesso, fabricante quando identificável e URL administrativa.
- **`PlatformHints` / `NetworkAssist`**:
  - enriquecimento dos hints de Wi-Fi e geração de ações com URL administrativa contextualizada no Assist.
- **UI (`LinkaApp`)**:
  - `MeasurementDetailView`: exibição do gateway e atalho na seção Wi-Fi.
  - `AssistView`: ação direta em recomendações relacionadas ao roteador quando houver base real.

## 3. Requisito de Aceite
- `LinkaEngine` intocado e velocidade de medição sem interferência.
- timeout curto e execução fora do caminho crítico da medição.
- conformidade com Apple Local Network Privacy aplicável.
- testes unitários cobrindo discovery, parsing e fallback.
- ausência de fabricante/modelo é representada como desconhecida, nunca inferida sem evidência.
- copy concisa e aderente à voz do Linka.

## 4. Não-Objetivos
- Não é scanner de rede (sem ARP scan de outros dispositivos da LAN).
- Não tenta alcançar ONUs/modems em bridge isolados da sub-rede.
- Não armazena nem gerencia credenciais de roteador nesta fatia.
