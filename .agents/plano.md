# Plano de Feature: Identificação do Gateway / Roteador Wi-Fi

> **Trilha:** Full-flow | **Papel líder:** Giammattey (Produto & Arquitetura)

## 1. Objetivo
Permitir que o Linka identifique de forma confiável o gateway IPv4 da rede Wi-Fi atual (ex.: `192.168.1.1`), detecte a acessibilidade da interface web e infira fabricante/modelo básico (ex.: TP-Link, Huawei, Intelbras, Nokia), oferecendo ação direta de **"Abrir configurações"** no Assist e em Detalhes da Medição.

## 2. Mudança Arquitetural
- **`NetworkDiagnostics`**:
  - `LocalGatewayDiscovery`: leitura de `getifaddrs` e rotas BSD para extrair IP do gateway.
  - `GatewayProber` & `GatewayVendorFingerprinter`: sondagem HTTP/HTTPS assíncrona (timeout 1.5s) com detecção de interface de administração e headers de fabricante.
  - `GatewayInfo`: modelo de dados com IP, status de acesso, fabricante e URL administrativa.
- **`PlatformHints` / `NetworkAssist`**:
  - Enriquecimento dos hints de Wi-Fi e geração de ações com URL administrativa contextualizada no Assist.
- **UI (`LinkaApp`)**:
  - `MeasurementDetailView`: Exibição do gateway e atalho na seção Wi-Fi.
  - `AssistView`: Botão de ação direta nas recomendações de roteador/canal.

## 3. Requisito de Aceite
- `LinkaEngine` intocado e velocidade de medição sem qualquer interferência.
- Timeout estrito de 1.5s em thread de background.
- Conformidade total com Apple Local Network Privacy (TN3179).
- Testes unitários cobrindo discovery, parsing e fallback.
- Copy concisa e aderente à voz do Linka.

## 4. Não-Objetivos
- Não é scanner de rede (sem ARP scan de outros dispositivos da LAN).
- Não tenta alcançar ONUs/modems em bridge isolados da sub-rede.
- Não armazena nem gerencia credenciais de roteador.
