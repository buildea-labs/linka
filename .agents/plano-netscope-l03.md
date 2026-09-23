# Architecture Plan — Netscope L-03

## Problema e decisão

O resultado local do Linka já existe antes da leitura. L-03 adiciona apenas
uma superfície secundária para entendê-lo; não inicia, atrasa, altera ou
substitui a medição. A análise remota fica bloqueada até L-02 introduzir
snapshot permitido, atestação e cliente autenticado.

## Escopo

- CTA pós-resultado, loading calmo e estados `completed`, `inconclusive`,
  `unavailable`, `rateLimited` e `outOfScope` em iPhone, iPad e Mac.
- Protocolo injetável de leitura e provider padrão desligado, sem URLSession,
  endpoint, DNS, segredo, API key ou egress.
- Evidência e contexto declarado modelados separadamente na apresentação.
- Testes de estado, acessibilidade e localização proporcionais.

## Contrato e limites

- L-03 não serializa `NetworkMeasurement` nem cria snapshot remoto; L-02 será
  a única camada autorizada a projetar a allowlist de evidência.
- Não importar nem reutilizar `NetworkAssist`, `NetworkDiagnostics`,
  `AssistContainer`, `BuildeaDiagnosticTransport`, `NDSRequestBuilder` ou
  configuração NDS.
- O reader padrão devolve `unavailable` e não faz I/O. Uma implementação real
  substitui somente essa dependência após L-02.
- O CTA só aparece com resultado concluído. Reteste continua sendo a ação
  principal e voltar/cancelar preserva o resultado já exibido.

## Falhas e privacidade

- Falha de leitura não é falha de medição e nunca produz diagnóstico otimista.
- Campos Wi-Fi só aparecem quando recebidos como evidência; ausência é omissão.
- Contexto estruturado da pessoa pode enquadrar a leitura, mas nunca é fato,
  métrica ou evidência.
- Não exibir ou persistir SSID/BSSID, IP, gateway, operadora, localização,
  prompt, provider/modelo, payload, identificadores ou logs.

## Verificação

- Estados e CTA em iPhone, iPad e Mac; VoiceOver, Dynamic Type, Reduce Motion
  e idiomas pt-BR, en e es-419.
- Busca negativa de dependências Assist/NDS e de endpoints/segredos novos.
- Build/testes dos módulos Swift alterados e testes de UI quando viáveis.
