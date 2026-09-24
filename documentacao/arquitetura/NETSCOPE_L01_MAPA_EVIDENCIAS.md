# Netscope L-01 — mapa de evidências do Linka

**Status:** mapeamento factual para aprovação. Não cria backend, IA, chamada
remota, segredo, permissão, entitlement ou alteração no motor.

**Base verificável:** `AGENTS.md`, o modelo
`NetworkCore/Sources/NetworkMeasurement.swift` e os adaptadores e consumidores
citados em cada seção. Este documento mapeia o que o Linka já observa; ele não
transforma uma capacidade possível em dado existente.

## 1. Inventário factual já disponível

`NetworkMeasurement` é o registro canônico local. Todos os valores opcionais
abaixo usam ausência (`nil`) para “não medido/não disponível”; ausência não é
zero e não autoriza uma conclusão positiva.

| Grupo | Métrica ou fato local | Unidade/semântica | Elegível ao snapshot Netscope inicial? |
|---|---|---|---|
| Vazão | `downloadMbps`, `uploadMbps` | Mbps medidos | Sim, quando presentes |
| Qualidade | `latencyMs`, `jitterMs`, `packetLossPercent` | ms, ms, percentual | Sim, quando presentes; perda não passa de 100 |
| Sob carga | `loadedLatencyMs`, `loadedLatencyUploadMs` | ms de download/upload sob carga | Sim, somente se `loadResponsiveness.integrity == valid` |
| DNS | `dnsResolutionMs` | ms para resolver o host do teste | Sim, quando medido |
| Execução | `outcome`, `durationMs` | resultado completo/parcial e duração | `outcome` pode orientar estado; duração fica fora da primeira allowlist de análise |
| Caminho | `connectionKind` | Wi-Fi, móvel, Ethernet ou outro, amostrado no início e fim | Sim, pela projeção contratual definida na seção 2 |
| Wi-Fi nativo Mac | banda, canal, taxa de link e RSSI | CoreWLAN; valores independentes | Somente banda/canal/taxa, sob as regras da seção 3. RSSI não entra |
| Estabilidade/metodologia | `packetProbeEvidence`, `loadResponsiveness` | contagens, timeouts e integridade da metodologia | Integridade só como guarda local; não enviar os envelopes brutos na V1 |
| Referência de jogo | `regionalGameReference` | referência regional, não ping de jogo | Não entra na allowlist inicial |
| Wi-Fi local | SSID, hash local de AP, segurança, gateway, IP, fornecedor e URL de admin | contexto local/identificador | Não enviar |
| Wi-Fi avançado | `AdvancedWiFiDiagnostics` capturado nativamente no Mac ou importado por Atalho | diagnóstico avançado fora da allowlist inicial | Não enviar |
| Móvel/local | operadora, tecnologia, localização, IDs, servidor, rede e histórico | identificadores ou contexto além da necessidade | Não enviar |

Evidência de implementação: o modelo e a semântica de ausência estão em
`NetworkCore/Sources/NetworkMeasurement.swift`; a projeção do resultado em
`LinkaApp/Sources/Adapters/SpeedTestViewModel.swift`. O contrato novo não pode
reutilizar `NetworkDiagnostics`, `NDSRequestBuilder`, Assist ou suas regras.

## 2. Matriz de `connection_kind`

A fonte é sempre `NWPathMonitor`, não SSID, IP, nome de rede, throughput,
latência ou heurística. O app atual já compara a amostra do começo e do fim da
medição. O enum remoto A-02 deve ser fechado:
`wifi | cellular | ethernet | other | unknown`.

| Plataforma | `wifi` | `cellular` | `ethernet` | `other` | `unknown` | Permissão/entitlement Netscope |
|---|---|---|---|---|---|---|
| iPhone | `usesInterfaceType(.wifi)` | `usesInterfaceType(.cellular)` quando a rota o reportar | `usesInterfaceType(.wiredEthernet)` quando adaptador/rota o reportar | somente caminho **satisfeito** em interface reconhecida fora das três | sem caminho satisfeito, sem amostra, timeout ou divergência entre início/fim | nenhum novo |
| iPad | igual ao iPhone; não inferir pelo SSID | igual ao iPhone, somente em hardware/rota elegível | igual ao iPhone | igual ao iPhone | igual ao iPhone | nenhum novo |
| Mac | `usesInterfaceType(.wifi)` | somente se o `NWPath` o reportar; não inferir que é impossível | `usesInterfaceType(.wiredEthernet)` | somente caminho **satisfeito** em interface reconhecida fora das três | sem caminho satisfeito, sem amostra, timeout ou divergência entre início/fim | nenhum novo |

**Lacuna conhecida:** o sampler de resultado atual devolve `.other` quando o
`NWPath` não corresponde às três interfaces, sem testar `path.status`; o
monitor ao vivo já usa ausência quando o caminho não está satisfeito. L-02
deve fazer a projeção Netscope de caminho insatisfeito/ausente/trocado para
`unknown`, sem alterar retroativamente a medição local. `other` não é fallback
para incerteza.

## 3. Matriz de detalhes Wi-Fi

`wifi_details` só existe quando o `connection_kind` projetado é `wifi`. Cada
subcampo é independente e omitido do JSON quando não foi observado. Não usar
`null`, zero sentinela, taxa de download, SSID, RSSI, canal ou banda para
fabricar outro subcampo.

| Campo A-02 | iPhone / iPad: origem e regra | Mac: origem e regra | Permissão/entitlement e ausência |
|---|---|---|---|
| `frequency_mhz` | Não há API atualmente usada que o devolva; omitir | CoreWLAN usado pelo Linka devolve banda e canal, não frequência em MHz; omitir | Nenhum novo; sempre ausente nesta V1. Não calcular de canal/banda |
| `band` | O caminho público atual de `NEHotspotNetwork.fetchCurrent()` não expõe banda; omitir | `CWInterface.wlanChannel()?.channelBand`, mapeado apenas de valor explícito para `2.4ghz`, `5ghz` ou `6ghz` | Nenhum novo para Netscope. O entitlement `wifi-info` já consta no app, mas não prova provisionamento e não deve ser exigido por Netscope. Omitir se não Wi-Fi, interface/canal/banda ausente ou desconhecida |
| `channel` | Não exposto pelo caminho usado; omitir | `CWInterface.wlanChannel()?.channelNumber` | Nenhum novo para Netscope; omitir se não Wi-Fi, interface/canal ausente ou inválido |
| `link_speed_mbps` | Não exposto por API pública usada pelo Linka; omitir | `CWInterface.transmitRate()` | Nenhum novo para Netscope; omitir se não Wi-Fi, interface ausente ou valor não positivo. É taxa física, não download do teste |

O Linka atual tem `NEHotspotNetwork.fetchCurrent()` e textos de localização
para a identificação Wi-Fi já existente. Netscope não o chama, não aciona
prompt, não depende de localização precisa e não amplia capability. No Mac,
CoreWLAN é a única fonte nativa elegível nesta etapa. `AdvancedWiFiDiagnostics`
fica excluído, seja capturado nativamente no Mac ou importado por Atalho: seus
campos de diagnóstico avançado não fazem parte da allowlist inicial. Netscope
usa somente os valores CoreWLAN explicitamente mapeados nesta tabela e não
infere banda por SSID, BSSID ou canal.

## 4. Fato observado versus contexto declarado

| Classe | Pode ir ao request? | Pode aparecer em `evidence_used`? | Regra |
|---|---|---|---|
| Fato observado | Sim, apenas pela allowlist da seção 1 e pelas matrizes | Sim, com `source: system_observed` e somente se estava no request | Métrica local medida, `connection_kind` ou detalhe Wi-Fi nativo efetivamente observado |
| Contexto declarado | Sim, em `usage_context` | Não | `objective` e `subcategory` são intenção da pessoa. A resposta pode ecoá-los em `declared_context`: “Para uma chamada de vídeo que você indicou…”, nunca como prova de qualidade |
| Relato livre | Não na V1 | Não | Não enviar `reported_problem`; feedback V1 é apenas estruturado |
| Dado proibido | Não | Não | Identificadores, localização, histórico, dados de roteador, telemetria avançada importada e todo campo fora da allowlist |

A ausência de métricas exigidas pelo objetivo declarado leva a `inconclusive`.
Erro, timeout, resposta inválida, orçamento ou indisponibilidade levam ao
estado correspondente; nunca a “rede saudável”. O resultado local permanece
protagonista e não espera o Netscope.

## 5. Política de privacidade e contrato proposto para A-02

### Política por campo

| Campo/classe | Transporte | Persistência, log e prompt | Retenção/proibição |
|---|---|---|---|
| Métricas allowlist, `connection_kind`, `wifi_details` permitido | Processamento remoto transitório, somente após consentimento específico futuro | Nunca em D1, log, prompt salvo ou `analysis_audit` em bruto | Não persistir na V1 |
| `usage_context` | Transitório, separado da evidência | Não entra em `evidence_used`; não salvar relato livre | Não persistir na V1 |
| `locale`, versão/plataforma e consentimento | Mínimo operacional | Somente o que A-02 aprovar, com auditoria agregada/pseudonimizada | Conforme plano; sem vincular à medição crua |
| SSID/BSSID/hash de AP, RSSI, segurança, gateway/IP/URL, fornecedor, operadora/tecnologia móvel, localização, IDs de medição/rede/servidor, horário bruto, histórico, probes/envelopes, diagnóstico avançado | Proibido | Proibido | Nunca recebe, registra ou persiste |

O `PrivacyInfo.xcprivacy` atual declara nenhuma coleta e nenhum tracking. Ele,
App Privacy e a política pública **não mudam neste PR**; devem refletir a
implementação aprovada antes do primeiro tráfego remoto. Entitlement declarado
em arquivo não é prova de provisionamento: a validação de perfil/aparelho é
posterior (L-02/R-01).

### Shape contratual proposto

Pseudoshape de contrato — os textos entre `<…>` descrevem validação, não são
valores literais de request:

**Variante não Wi-Fi:** `wifi_details` é omitido.

```json
{
  "schema_version": "1.0.0",
  "measurement": {
    "download_mbps": "<número finito, se medido>",
    "upload_mbps": "<número finito, se medido>",
    "latency_ms": "<número finito, se medido>",
    "jitter_ms": "<número finito, se medido>",
    "packet_loss_percent": "<0..100, se medido>",
    "loaded_latency_download_ms": "<número finito, se integridade válida>",
    "loaded_latency_upload_ms": "<número finito, se integridade válida>",
    "dns_resolution_ms": "<número finito, se medido>",
    "connection_kind": "cellular"
  },
  "usage_context": { "objective": "video_call" },
  "locale": "pt-BR",
  "app": { "version": "", "platform": "ios" },
  "consent": { "diagnostic_processing": true }
}
```

**Variante Wi-Fi:** `wifi_details` só traz os subcampos efetivamente
observados.

```json
{
  "schema_version": "1.0.0",
  "measurement": {
    "connection_kind": "wifi",
    "wifi_details": {
      "band": "5ghz",
      "channel": 36,
      "link_speed_mbps": "<número finito, se observado>"
    }
  },
  "usage_context": { "objective": "video_call" },
  "locale": "pt-BR",
  "app": { "version": "", "platform": "ios" },
  "consent": { "diagnostic_processing": true }
}
```

No wire, toda métrica e todo subcampo opcional ausente é **omitido**; zero só
é aceito quando uma métrica foi realmente medida como zero. A-02 deve impor
número finito e não negativo (`packet_loss_percent <= 100`), canal inteiro
positivo, banda no enum fechado, e `wifi_details` proibido fora de `wifi`.
`subcategory` também é omitida quando não declarada, nunca `""`.

Na resposta, `evidence_used` só pode referenciar pares que chegaram no
snapshot permitido, com `source: system_observed`; `declared_context` é uma
área distinta. A validação rejeita enum inválido, campo não enviado, contexto
declarado rotulado como medição e qualquer referência a detalhe Wi-Fi ausente.

## 6. Aceite L-01 e verificações para A-02/L-02

L-01 está pronto para aceite quando esta documentação for a referência do
contrato e estiver explícito que não houve alteração de motor, backend, IA,
infraestrutura, segredo, DNS ou permissão. Antes de abrir tráfego, A-02 deve
cobrir ao menos:

- schema/fixtures para `wifi` sem detalhes, `cellular`, `ethernet`, `other` e
  `unknown`;
- ausência versus zero medido, `NaN`, infinito, negativo e perda acima de 100;
- `wifi_details` fora de Wi-Fi e seus quatro subcampos isolados;
- frequência ausente sem derivação por banda/canal; canal 6 GHz sem inferir
  banda; e detalhes Wi-Fi ausentes em iPhone/iPad;
- allowlist negativa para todos os identificadores/dados proibidos;
- `usage_context` apenas em `declared_context`, jamais em `evidence_used`;
- resposta que rejeita evidência ausente/não enviada, enum inválido e copy
  conclusiva em dados insuficientes;
- `inconclusive` para evidência insuficiente e `unavailable` para timeout,
  erro ou provider indisponível, preservando o resultado local.

L-02, sem antecipar sua implementação, terá de testar o adaptador de caminho
com Wi-Fi, móvel, Ethernet, outro, rota insatisfeita, timeout e troca
Wi-Fi→móvel/Ethernet; e a leitura nativa Mac com cada valor disponível ou
ausente. A confirmação em aparelho de entitlement/provisionamento e das
trilhas iPhone, iPad e Mac permanece gate de hardware posterior.

## Decisões e pendências para L-02

- manter intenção declarada, evidência observada e limites do diagnóstico em
  seções distintas, sem reutilizar copy otimista do Assist/NDS;
- projetar um snapshot independente de NDS, com enum remoto `unknown` e
  projection estritamente allowlisted;
- preservar a exclusão de diagnósticos avançados, nativos ou importados, e o
  estado `unknown` quando a rota não puder ser determinada;
- alinhar Privacy Manifest e App Privacy antes de qualquer tráfego de rede.
