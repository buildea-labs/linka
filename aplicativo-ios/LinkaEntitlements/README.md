# LinkaEntitlements

Módulo independente da política comercial de acesso do Linka.

## Responsabilidade

Responder se uma capacidade do produto está disponível para um estado de entitlement conhecido.

A política v1 mantém o SpeedTest disponível independentemente do estado da assinatura e falha fechado apenas para capacidades premium.

## Planos

- `free`: SpeedTest.
- `plus`: SpeedTest, Histórico, Insights, Assist e integrações Apple.

## Estados

- `unknown`
- `inactive`
- `active`
- `expired`

## Fontes de acesso Plus

- assinatura;
- trial;
- promoção;
- lifetime.

## Não faz

- compra;
- restauração de compra;
- StoreKit;
- validação de recibo;
- chamada de backend;
- UI/paywall;
- precificação.

StoreKit ou qualquer outro sistema futuro deve apenas produzir um `LinkaEntitlementSnapshot`. A decisão de acesso permanece neste módulo.
