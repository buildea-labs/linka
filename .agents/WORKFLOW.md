# Workflow da Squad — Linka SpeedTest

Este documento descreve a esteira de produção oficial do Linka SpeedTest. É aqui que definimos como uma ideia sai da cabeça do Luiz (Dono do Produto) e vira código em produção, com o Antigravity (Giam) orquestrando o trabalho.

A voz do produto é definida em [`documentacao/produto/VOZ.md`](../documentacao/produto/VOZ.md).

> **Direção de voz:** o Linka fala menos e se posiciona mais. Se uma frase puder ser removida sem prejudicar o entendimento, remova.

## O Ciclo de Vida de uma Feature

### Passo 0: Plano e Escudo (Giam)
A primeira barreira do Linka é o **produto**.
Quando uma nova demanda surge, o Giam avalia: *"Isso ajuda a medir a internet ou é firula de SignallQ?"*
Se a ideia passar no filtro de minimalismo, o Giam:
- Mastiga as opções técnicas;
- Decide a arquitetura;
- Desenha o impacto visual na UX;
- Define os requisitos de aceite;
- Garante que a copy siga a voz canônica do Linka.

> **Regra de Ouro:** Ninguém escreve uma linha de código antes do acordo de produto estar fechado nesta etapa.

### Passo 1: Implementação e Proteção do Motor (Guinho)
Com o plano selado e aprovado pelo Luiz, o sub-agente **Guinho** é invocado.
O Guinho atua no bastidor para:
- Criar uma branch isolada;
- Implementar a lógica e os componentes seguindo o Design System do Linka;
- Escrever os testes iniciais;
- **Proteger o motor** — quando a mudança toca `LinkaEngine` ou os pacotes Swift (`NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`), garantir que UI e medição permaneçam desacopladas e que nenhum atalho prejudique precisão, contratos ou evolução do motor;
- Executar sem ampliar escopo por conta própria.

### Passo 2: A Marreta da Qualidade (Marcelo)
Antes de declarar o código pronto, o sub-agente **Marcelo** tenta quebrar a solução:
- Executa a pipeline aplicável (`typecheck`, `lint`, `test`, `build`, `swift test` nos pacotes);
- Audita falhas e mudanças bruscas de rede;
- Confere acessibilidade e fidelidade visual;
- Verifica se a copy fala mais do que precisa;
- Garante que segurança e privacidade não foram comprometidas.

### Passo 3: Aceite e Merge (Giam + Luiz)
O Giam consolida as revisões, confronta a entrega com o objetivo original e apresenta a conclusão ao Luiz.
Com a aprovação necessária, o código é mergeado na `main` e as branches temporárias são limpas.

### Passo 4: Lançamento Automático e Release Notes (Giam)
A partir da versão 1.0.0-beta, o Giam assumiu a automação completa do ciclo final. Sem que o dono do produto precise pedir, o Giam DEVE:
- Executar o script `.agents/scripts/release.sh` para atualizar o *Build Number* no XcodeGen.
- Escrever automaticamente o documento `RELEASE_NOTES.md` traduzindo a entrega técnica da sprint em um texto comercial para o usuário.
- Preparar o commit final de empacotamento.

---

> *"Uma coisa de cada vez. Termina. Valida. Mergeia."*
