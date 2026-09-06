---
name: criar-componente-ui
description: Procedimento do Camillo para construir componentes SwiftUI do Linka e componentes do site institucional com fidelidade ao protótipo e Design System.
---

# Skill: criar-componente-ui

Procedimento de **Camillo** para implementar UI. Íris define comportamento/experiência e o protótipo/Design System são as fontes visuais.

Se surgir decisão de produto ou visual material não coberta pela especificação, não invente padrão dentro do componente: devolva ao Codex para consulta a Íris.

## Regras

- resultado/medição é protagonista;
- prefira componentes e tokens existentes;
- não crie segunda paleta ou design system paralelo;
- SwiftUI apresenta estado; não executa cálculo de medição nem conhece detalhes de rede que pertencem ao motor;
- site institucional não executa speed test;
- sem MD3, dashboard, cardização excessiva, sombras/gradientes gratuitos ou motion decorativo;
- suporte light/dark, Dynamic Type/contraste e Reduce Motion;
- alvo de toque e acessibilidade seguem padrões Apple e o Design System.

## Antes de criar componente novo

1. procure componente equivalente;
2. procure token existente;
3. confirme onde o estado aparece no protótipo;
4. confirme se o comportamento pertence ao escopo;
5. verifique se o componente precisa existir ou se composição de peças atuais resolve.

## Fronteira UI/motor

No app Apple:

- `View` desenha e envia intenção;
- adapter/ViewModel cuida de ciclo de vida e estado observável;
- pacotes de domínio/motor calculam e persistem;
- erro/partial/cancelamento não podem ser transformados em sucesso para simplificar layout.

## Copy

Use `aplicar-voz-linka` para texto de produto e `matar-cheiro-de-ia` para remover enfeite artificial. Se a tela precisar de parágrafos para explicar o fluxo principal, reveja o desenho com Íris.

## Validação

Antes de devolver:

- light/dark;
- acessibilidade aplicável;
- Reduce Motion;
- sem cálculo de medição na View;
- fidelidade ao protótipo/Design System;
- build/testes relevantes;
- aparelho real quando a mudança justificar.

Informe explicitamente o que não foi testado.
