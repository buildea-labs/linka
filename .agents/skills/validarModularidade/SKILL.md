---
name: validar-modularidade
description: Detecta acoplamento, mistura de responsabilidades, duplicação de regra e abstração prematura no Linka.
---

# Skill: validar-modularidade

Use esta skill para revisar risco estrutural real, não para punir arquivo grande por numerologia.

## Sinais de problema

- SwiftUI `View` conhece `URLSession`, cálculo de bytes ou persistência de domínio;
- regra de medição/conversão duplicada;
- cleanup de `Task`, `URLSession` ou timer sem dono;
- tipo muda por várias razões independentes;
- pacote de motor depende de framework de UI;
- contrato canônico tem mais de uma definição;
- abstração criada para feature futura sem necessidade atual;
- teste de regra exige montar o app inteiro sem motivo.

## Tamanho

Tamanho de arquivo é sinal para revisar coesão, não verdict automático. Arquivo grande com uma responsabilidade e invariantes coesos pode ser melhor que decomposição artificial.

## Direção de dependências

Preferir:

```text
View → Adapter/ViewModel → domínio/motor
```

Nunca o motor dependendo da View.

`NetworkCore` e contratos de base não devem depender de componentes de produto que os consomem.

## Duplicação perigosa

Priorize duplicação de regra, não repetição cosmética:

- bytes → Mbps;
- complete vs partial;
- retenção do histórico;
- agregações estatísticas;
- schema de `NetworkMeasurement`;
- thresholds/regras determinísticas.

Se a mesma regra existir em plataformas diferentes, procure contrato/fixture/teste de paridade em vez de deixar implementações divergirem silenciosamente.

## Escopo

Refatoração não pode introduzir, escondida, capacidade nova de Assist, diagnóstico, Wi‑Fi avançado ou coleta de dado. Produto novo passa pela definição de produto e pelo gate arquitetural quando aplicável antes de entrar.

## Verdict

A auditoria classifica achados conforme `AGENTS.md`/workflow:

- `BLOQUEIA` quando o acoplamento ameaça contrato, medição, segurança ou regressão relevante;
- `AJUSTA` quando deve ser corrigido nesta entrega;
- `ISSUE_FUTURA` quando é dívida real sem relação necessária com a fatia atual.

Inclua arquivo/símbolo, efeito concreto e recomendação mínima. Evite “crie uma camada” como resposta automática.
