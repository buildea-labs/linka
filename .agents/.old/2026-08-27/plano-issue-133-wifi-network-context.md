# plano.md — Issue #133: identidade da rede Wi-Fi

**Trilha:** Full-flow.
**Branch:** `feat/issue-133-wifi-network-context`.
**Autorização:** Luiz solicitou a implementação e o merge nesta sessão em 2026-08-27.

## Objetivo

Associar cada medição Wi-Fi à rede realmente usada, quando a Apple autorizar
essa leitura, sem transformar o Linka em uma tela técnica ou bloquear a
medição.

## Mudança arquitetural

- Adicionar `WiFiNetworkContext` opcional ao contrato canônico e manter
  compatibilidade de decodificação com medições antigas.
- No iPhone/iPad, usar exclusivamente `NEHotspotNetwork.fetchCurrent()` após
  ação explícita do usuário e com Access Wi-Fi Information + localização
  precisa; amostrar em paralelo ao motor no início e no fim do teste.
- No macOS, continuar com CoreWLAN e preservar os fatos que ele expõe.
- Persistir SSID e o identificador de ponto de acesso derivado apenas no
  histórico local. Não enviar SSID/BSSID ao NDS e não sincronizá-los pelo
  CloudKit nesta entrega.
- Mostrar a rede apenas em `Ver detalhes` e no Histórico; Ajustes oferece o
  gatilho de permissão, sem prometer alterar a permissão do sistema.

## Requisito de aceite

- SSID e segurança aparecem para nova medição Wi-Fi quando a Apple permite.
- Falta de permissão, rede ausente ou troca de SSID tornam o contexto ausente,
  sem impedir o Speedtest.
- BSSID cru não é persistido, exibido, enviado ao NDS ou sincronizado.
- iPhone não exibe banda, RSSI ou link speed sem fato exposto; macOS preserva
  os seus dados CoreWLAN.
- Contratos, testes de unidade, packages e builds dos targets passam; o fluxo
  em dispositivo físico fica documentado como validação de release.

## Não-objetivos

- Scan de redes, localização contínua, inferência pelo SSID e Hotspot Helper.
- Diagnóstico causal, nova aba Wi-Fi, alteração do motor ou envio de dados de
  rede ao serviço remoto.
