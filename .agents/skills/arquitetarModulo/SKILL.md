---
name: arquitetar-modulo
description: Procedimento do Camillo para desenhar mudanças modulares no Linka, com Íris fornecendo restrições de produto e o Codex consolidando o plano.
---

# Skill: arquitetar-modulo

A arquitetura da mudança é responsabilidade principal de **Camillo**. **Íris** fornece problema, comportamento esperado, não-objetivos e critérios de produto. O **Codex principal** consolida o resultado no `plano.md` quando necessário.

## Antes da arquitetura

Leia `AGENTS.md §1-3` e o código relevante. Confirme primeiro que a capacidade pertence ao Linka e é viável no ecossistema Apple.

Se houver dúvida de produto, não invente uma resposta técnica para escondê-la. Devolva ao Codex para consulta a Íris/Luiz.

## Regras estruturais

1. **Motor separado da UI.** `NetworkCore`, `LinkaEngine`, `MeasurementHistory`, `NetworkInsights` e `NetworkAssist` não conhecem SwiftUI.
2. **Interpretação fora do motor.** Assist, recomendação e diagnóstico não entram no código de medição.
3. **Contrato é contrato.** Mudança incompatível exige versionamento/migração; campo opcional ausente não vira zero.
4. **Modularidade não é quantidade de arquivos.** Não crie pacote novo para uma responsabilidade pequena já coberta por módulo existente.

## Comece pelo comportamento

Antes de criar camada, escreva:

```text
entrada → transformação/ação → saída
```

Liste:

- estado persistido, se houver;
- falhas importantes;
- timeout/cancelamento;
- recursos com ciclo de vida explícito;
- consumidores do dado/contrato.

## Onde a mudança pode morar

Responsabilidades típicas:

- `NetworkCore` — contrato canônico de medição;
- `LinkaEngine` — medição real;
- `MeasurementHistory` — persistência/histórico;
- `NetworkInsights` — estatísticas e comparação;
- `NetworkAssist` — contexto para IA sobre dado medido;
- `LinkaAppIntents` — App Intents/Shortcuts;
- `LinkaEntitlements` — capacidades da plataforma;
- `LinkaApp` — UI e adapters.

Use o código atual como fonte de verdade; não crie módulo com base apenas nesta lista.

## Persistência

Antes de persistir dado novo:

1. prove que precisa sobreviver ao ciclo de vida atual;
2. procure entidade/repositório existente;
3. defina retenção;
4. defina comportamento para dado corrompido/versão desconhecida;
5. avalie privacidade e compartilhamento.

## Saída para o plano

Camillo devolve:

- pacotes/camadas afetados;
- contrato novo/modificado, se houver;
- comportamento de erro/cancelamento;
- persistência/privacidade;
- testes e validações;
- riscos de regressão;
- **o que não será feito nesta fatia**.

A última linha é obrigatória para impedir expansão silenciosa de escopo.
