---
name: desenhar-interface
description: Procedimento da Íris para especificar a UI do Linka a partir do protótipo e Design System antes do Camillo implementar.
---

# Skill: desenhar-interface

**Íris** transforma a experiência aprovada em especificação visual. **Camillo** implementa. O Codex principal resolve conflitos e leva ao Luiz apenas decisões materiais de produto.

Fontes:

1. `documentacao/design/prototipo/` — fluxo, geometria e comportamento;
2. `documentacao/design/design_system/` — tokens, identidade, componentes e motion.

Se houver divergência material, não invente um terceiro padrão.

## Antes de especificar

- procure estado equivalente no protótipo;
- procure componente existente;
- use token semântico existente;
- confirme comportamento em light/dark;
- considere Dynamic Type, contraste, VoiceOver e Reduce Motion;
- preserve o número/resultado como protagonista quando estiver no fluxo de medição.

## Evitar

- novo token sem necessidade real;
- segunda paleta;
- cardização de todo conteúdo;
- sombras e gradientes decorativos;
- glassmorphism gratuito;
- MD3;
- animação que compete com medição;
- explicação longa em tela para compensar fluxo ruim.

## Saída

```text
ESTADO: região/tela afetada
FORMA: componente existente ou novo
TOKENS: nomes semânticos usados
MEDIDA: limites, alvo de toque e adaptação
MOVIMENTO: comportamento e curva
REDUCED MOTION: degradação
A11Y: foco, rótulo, contraste, leitura
PROTÓTIPO: referência do estado
NÃO FAZ: limites explícitos
```

Se for componente novo, justifique por que composição dos existentes não resolve.

Camillo recebe a especificação e usa `criar-componente-ui`. Tito confere fidelidade na revisão.
