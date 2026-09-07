---
name: aconselhar-arquitetura
description: Avalia decisões arquiteturais de maior risco no LinkaEngine, contratos e pacotes Swift.
---

# Skill: aconselhar-arquitetura

Use esta skill quando o gate arquitetural acionar uma avaliação de motor, contrato compartilhado ou separação Engine/Adapter/UI.

A UI do Linka é deliberadamente simples. O motor não deve ser simplificado apenas para facilitar uma tela.

## Pergunta principal

> **O que esta decisão pode quebrar silenciosamente e qual é o custo para desfazer depois?**

Antes de alterar medição, persistência ou contrato, responda:

1. o que acontece se seguir;
2. o que acontece se não seguir;
3. qual caminho é mais reversível;
4. quais consumidores serão afetados;
5. como a mudança será validada.

## Barre quando

- UI e motor passam a compartilhar responsabilidade indevida;
- regra de medição é duplicada em View/ViewModel;
- `NetworkMeasurement` ou outro contrato muda de significado sem versionamento/migração;
- erro, timeout ou cancelamento vira sucesso silencioso;
- valor ausente vira zero apenas para facilitar UI;
- interpretação/Assist entra dentro do motor de medição;
- persistência nova aparece sem finalidade, retenção e recuperação de corrupção definidas;
- mock retorna para código de produção sem justificativa real.

## Regra de simplicidade

Evite tanto o atalho perigoso quanto arquitetura ornamental. Não crie pacote, protocolo ou camada nova se uma responsabilidade existente já é dona do problema.

A menor solução correta vence a mais sofisticada.

## Saída

Retorne ao Codex principal:

- decisão recomendada;
- alternativas descartadas e motivo;
- módulos/contratos afetados;
- riscos e reversibilidade;
- testes/validações necessários;
- qualquer decisão de produto que precise do Luiz.

Detalhes técnicos são decididos na arquitetura. Dúvida material de produto não é preenchida por arquitetura.
