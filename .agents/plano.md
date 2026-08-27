# plano.md — Issue #134: diagnóstico Wi-Fi avançado via Atalhos

**Trilha:** Full-flow.
**Branch:** `feat/issue-134-wifi-advanced-shortcut`.
**Autorização:** Luiz solicitou a implementação e o merge nesta sessão em 2026-08-27.

## Objetivo

Permitir, apenas para Linka Plus e por ação explícita, que um atalho criado
no app Atalhos importe fatos públicos da rede Wi-Fi e os associe com segurança
à medição correta, sem interromper o Speedtest quando o atalho estiver ausente.

## Mudança arquitetural

- Criar `AdvancedWiFiDiagnostics` no `NetworkCore`, separado do contexto
  nativo da #133; BSSID e MAC entram somente como valores transitórios e se
  tornam identificadores locais derivados antes de qualquer persistência.
- Expor `ImportWiFiDiagnosticsIntent` com um JSON limitado e versionado como
  entrada oficial do atalho. O atalho é um fluxo explícito no app Atalhos:
  `Obter detalhes da rede` → montar JSON → `Importar diagnóstico Wi-Fi`.
- Guardar um diagnóstico avançado pendente somente no aparelho, com expiração
  curta. O ViewModel decide a associação pelo intervalo temporal, Wi-Fi e
  ausência de contradição de SSID; conflitos não são anexados à medição.
- Incluir o contexto avançado opcional em `NetworkMeasurement`, histórico e
  detalhes. CloudKit continua sem esse contexto; NDS recebe apenas fatos
  avançados medidos, jamais SSID, BSSID ou MAC.
- Acrescentar a capacidade Plus `advancedWiFiDiagnostics` ao
  `LinkaEntitlementPolicy`; Ajustes e detalhes usam essa política, não gates
  locais espalhados.

## Requisito de aceite

- Payload válido, parcial e inválido têm validação determinística; não há
  zero artificial, schema desconhecido, timestamp implausível nem payload
  duplicado associado.
- SNR e banda provável só são derivados por regras documentadas; largura de
  canal, MCS e demais fatos não expostos permanecem ausentes.
- A interface mostra campos avançados somente sob detalhes e mantém a lista
  do histórico discreta; ausência do atalho não muda o fluxo de medição.
- BSSID/MAC crus não persistem, não entram no CloudKit, NDS ou logs.
- Testes de unidade e targets compilam; a matriz de Atalhos em iPhone físico
  fica registrada como validação de release se o dispositivo não estiver
  disponível nesta sessão.

## Não-objetivos

- API privada, Hotspot Helper, scan Wi-Fi, largura de canal, MCS, spatial
  streams, alteração de roteador/canal, lookup externo ou causa raiz.
- Instalação silenciosa de atalho, coleta automática durante todo Speedtest,
  upload de identificadores de rede ou mudança do motor de medição.
