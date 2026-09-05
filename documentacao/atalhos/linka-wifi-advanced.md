# Linka Wi-Fi Advanced

**Versão do atalho:** 1  
**Schema do payload:** 1

O atalho oficial é montado conscientemente no app **Atalhos**. Ele não usa
API privada, perfil de diagnóstico, serviço de terceiros ou instalação
silenciosa.

## Montagem

1. Crie um atalho chamado **Linka Wi-Fi Advanced**.
2. Adicione **Obter detalhes da rede** e peça, quando disponíveis: Nome da
   rede, BSSID, Padrão Wi-Fi, Taxa RX, Taxa TX, RSSI, Ruído e Número do canal.
3. Adicione a ação Linka **Registrar diagnóstico Wi-Fi avançado**.
4. Encaixe cada saída de **Obter detalhes da rede** no parâmetro equivalente
   da ação do Linka.

## Caminho legado por JSON

A ação Linka **Importar diagnóstico Wi-Fi** continua aceita para depuração e
compatibilidade. Nesse caminho, crie um dicionário com os nomes abaixo, use
data ISO-8601 em `capturedAt`, um UUID novo em `captureIdentifier`, converta o
dicionário em JSON e passe o texto em *Payload de diagnóstico*.

```json
{
  "schemaVersion": 1,
  "shortcutVersion": 1,
  "captureIdentifier": "550E8400-E29B-41D4-A716-446655440000",
  "capturedAt": "2026-08-27T04:00:00Z",
  "ssid": "Casa",
  "bssid": "AA:BB:CC:DD:EE:FF",
  "wifiStandard": "Wi-Fi 6",
  "rxRateMbps": 720,
  "txRateMbps": 866,
  "rssiDbm": -54,
  "noiseDbm": -92,
  "channelNumber": 44
}
```

`hardwareMacAddress` pode constar no dicionário do Atalhos, mas é descartado
antes de persistir. O BSSID cru só produz identificador local derivado. O
atalho nunca adiciona chamadas de rede.

## Atualização e limites

O Linka rejeita schema desconhecido, versão futura, JSON acima de 4 KiB, data
futura acima de 30 segundos, captura expirada e `captureIdentifier` repetido.
Campos não oferecidos pelo sistema ficam ausentes; nunca substitua ausência por
zero. Largura de canal, MCS e spatial streams não fazem parte do payload.

Como alternativa de depuração, um atalho pode abrir
`linka://wifi-advanced?payload=<JSON percent-encoded>`. O mesmo validador e
identificador de captura são usados; esse caminho não transporta segredo.
