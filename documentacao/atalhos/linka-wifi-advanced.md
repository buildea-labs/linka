# Linka Wi-Fi Advanced

**Versão do atalho:** 1  
**Schema do payload:** 1

O template oficial é distribuído pelo iCloud Shortcuts. No Linka, a pessoa
abre a página de importação da Apple, revisa o fluxo e confirma **Adicionar
Atalho**. Não há instalação silenciosa, API privada ou perfil de diagnóstico.

## Montagem

1. No Linka, abra **Ajustes → Diagnóstico Wi-Fi avançado** e escolha
   **Adicionar atalho Wi-Fi avançado**.
2. Revise o template na interface da Apple e confirme **Adicionar Atalho**.
3. O atalho instalado se chama **Linka Wi-Fi Advanced** e coleta Nome da rede,
   BSSID, Padrão Wi-Fi, Taxa RX, Taxa TX, RSSI, Ruído e Número do canal antes
   de chamar **Registrar diagnóstico Wi-Fi avançado** do Linka.

Ao tocar em medir no Linka, o app executa o atalho primeiro. Quando o Atalhos
devolve os dados, a medição começa; se o atalho for cancelado, a medição não é
iniciada por engano e o Linka oferece tentar novamente ou medir sem os dados
avançados.

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
