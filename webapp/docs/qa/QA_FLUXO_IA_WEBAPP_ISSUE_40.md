# QA - Fluxo IA WebApp (Issue #40)

Checklist manual minimo para validar a migracao do fluxo IA canônico.

## Pre-condicoes

- Build local sem erro.
- Ambiente com internet.
- WebApp rodando em modo de desenvolvimento ou preview.

## Cenarios - PulseScreen

1. Iniciar um diagnostico IA no Pulse.
2. Confirmar que o resultado chega com texto de analise remota quando o Worker responde.
3. Simular indisponibilidade (offline ou erro remoto) e confirmar fallback local.
4. Validar rotulo de fallback: `Diagnóstico local do Linka`.

## Cenarios - ResultScreen / useDiagnosis

1. Executar speedtest e abrir tela de resultado.
2. Confirmar diagnostico principal sem erro visual quando remoto responde.
3. Simular erro remoto e confirmar diagnostico local com rodape:
   `Motor de análise: Diagnóstico local do Linka`.
4. Confirmar que nao aparece estado quebrado (`undefined`, card vazio, loading preso).

## Regressao minima

Executar:

```bash
npm run lint
npm test
npm run build
```

Resultado esperado: todos os comandos passando.
