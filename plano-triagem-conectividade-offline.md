# Piloto — triagem local de conectividade

## Objetivo

Quando uma medição falhar por falta ou perda de conectividade, permitir que a
pessoa verifique localmente o que o Linka consegue observar e receba uma
orientação segura para retestar. A triagem é gratuita, secundária ao reteste e
nunca aparece no resultado bem-sucedido.

## Mudança arquitetural

- Criar `NetworkConnectivityTriage`, pacote local com sondas de caminho e HTTPS
  e um classificador determinístico, separado de `LinkaEngine` e `NetworkAssist`.
  As sondas usam somente `GET` efêmero e sem autenticação em `/v1/health` e
  `/v1/version` do NDS, endpoints públicos controlados pela Buildea; elas não
  acionam a avaliação diagnóstica, o Assist ou IA.
- A tela de erro chama o adaptador somente após `offline` ou `connectionLost`.
  O relatório é efêmero: não entra no histórico, em `NetworkMeasurement` ou em
  qualquer requisição remota.
- A interface apresenta fatos observados e uma ação proporcional. Portal cativo
  é apenas suspeita; gateway, rota e causa no roteador/provedor não são
  inferidos.

## Requisito de aceite

- Retestar continua a ação principal e a triagem funciona sem Assist, Plus ou
  medição completa; as únicas chamadas remotas são as duas sondas HTTPS
  públicas, efêmeras e sem dados descritas acima.
- A copy não atribui falha a Wi-Fi, DNS, roteador, operadora ou dispositivo sem
  evidência observável; na ausência dela, declara resultado inconclusivo.
- Cancelamento, segundo teste e ida ao segundo plano não exibem orientação
  antiga nem disparam sondas duplicadas.
- Há testes do classificador, das sondas injetáveis e da UI para offline, perda
  durante teste, caminho funcional, indício de portal, timeout e cancelamento.
- VoiceOver, Dynamic Type e Reduce Motion são validados na superfície nova.

## Não-objetivos

- Alterar a metodologia ou os contratos do `LinkaEngine`.
- Diagnosticar gateway, canal, interferência, equipamento ou operadora.
- Configurar DNS, abrir ajustes privados do sistema, persistir identificadores
  de rede ou chamar NDS/IA.
- Transformar a falha em dashboard, histórico ou recurso pago.
