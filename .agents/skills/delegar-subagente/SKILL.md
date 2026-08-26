---
name: delegar-subagente
description: Delegar uma tarefa independente a um subagente nativo do Codex usando os perfis Giam, Guinho ou Marcelo, com escopo, permissões e retorno verificáveis.
---

# Skill: delegar-subagente

Use esta skill quando uma parte do trabalho for independente, concreta e suficientemente delimitada para rodar em paralelo. Ela orienta o agente principal; não cria um subagente sozinha.

## Escolha do perfil

- **Giam**: produto, experiência, curadoria, plano e aceite contra requisito.
- **Guinho**: implementação e testes, com arquivos de escrita explicitamente autorizados.
- **Marcelo**: auditoria, testes e verificação; somente leitura por padrão.

## Antes de delegar

Defina objetivo, contexto mínimo, arquivos permitidos, política de escrita e formato de retorno. Não delegue decisões acopladas ao próximo passo crítico, tarefas vagas ou duas tarefas que escrevam nos mesmos arquivos.

## Mensagem mínima

```text
Papel: <giam|guinho|marcelo>
Objetivo: <entrega concreta>
Escopo de leitura: <arquivos ou módulos>
Escopo de escrita: <somente leitura ou arquivos exatos>
Restrições: preserve mudanças existentes; não faça merge, push, deploy ou publicação.
Retorno: arquivos alterados, comandos/testes, evidências, riscos e bloqueios.
```

Para Marcelo, exigir `BLOQUEIA`, `AJUSTA` ou `ISSUE_FUTURA` com evidência. Para Guinho, revisar o diff retornado antes de integrar. Para qualquer perfil, o retorno não é aprovação de Giam ou Luiz.

## Depois de delegar

Enquanto o subagente trabalha, faça apenas trabalho não sobreposto. Aguarde quando o resultado for necessário, integre o retorno, valide a evidência e encerre o subagente concluído. Relate claramente o que foi delegado e o que foi verificado pelo agente principal.
