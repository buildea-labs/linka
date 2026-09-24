# L-05 — base de transporte atestado do Netscope

## Entrega

`NetscopeTransport` é um pacote Swift isolado, dependente somente de
`NetscopeEvidence` e Foundation/CryptoKit. Ele define o cliente de análise,
contratos injetáveis de App Attest e de HTTP, e o contrato local dos marcos de
progresso seguros: `accepted`, `analysis_started` e `validating_result`.

Não há `URLSession`, host, segredo, API key, log, persistência ou composição no
app. `DisabledNetscopeAnalysisReader` continua sendo a única composição do
Linka nesta fase; portanto a instalação deste pacote não produz tráfego remoto.

## Comportamento fechado

- só `iPhonePhysical` e `iPadPhysical` podem tentar a sequência;
- macOS, simulador e plataformas sem App Attest retornam `unavailable` antes de
  challenge, registro, assertion ou HTTP;
- por leitura: novo challenge, registro quando necessário e assertion ligada ao
  SHA-256 do exato body que seguirá no POST. O pedido também carrega
  `nonce` e `timestampUnixMilliseconds` recebidos do servidor no challenge;
  o segundo hash cobre `POST`, rota, body exato, nonce e timestamp usando
  campos UTF-8 prefixados por tamanho. Não há hipótese de serialização JSON
  canônica universal;
- o transporte é injetado, executa no máximo uma vez e não oferece retry;
- timeout, cancelamento, falha de App Attest, HTTP não-2xx, URL final diferente
  (incluindo redirect), JSON inválido e resposta incompatível retornam
  `unavailable`;
- frames de progresso fora da allowlist são rejeitados, sem mostrar texto de
  provider, raciocínio, prompt ou payload.

## Gates para conectar a operação real

1. hostname HTTPS final e provisionamento da rota;
2. App Attest provisionado e prova física em iPhone e iPad;
3. avaliação aprovada de provider/modelo, timeout e resposta;
4. valor e responsável pelo teto global de emergência;
5. implementação separada de Keychain e transporte sem redirects cross-host,
   seguida de revisão de segurança e aceite humano.

macOS permanece desligado nesta trilha até decisão e desenho próprios.
