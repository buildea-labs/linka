# Direção visual do Linka para macOS

> Decisão de produto — 16 de setembro de 2026.

Esta é a direção visual aprovada para o Linka no Mac. Ela complementa o Design System; não altera a experiência de iPhone ou iPad.

## Ideia central

O Mac deve parecer um espaço calmo para **medir, entender e agir**. A leitura começa pelo resultado ou pela decisão do usuário. Contexto técnico, métricas auxiliares e caminhos especializados aparecem só quando ajudam a avançar.

Não transformar o Linka em dashboard. Mais espaço de tela não é permissão para mostrar tudo ao mesmo tempo.

## Hierarquia

1. Um resultado, estado ou decisão principal por tela.
2. Uma ação primária clara por estado. Ela não divide peso visual com links, ícones ou CTAs concorrentes.
3. Ações de contexto (por exemplo, Assist e Otimização) ficam no cabeçalho ou na próxima camada, nunca coladas ao CTA primário.
4. Metadados, métricas auxiliares, diagnóstico físico e explicações extensas usam divulgação progressiva (`DisclosureGroup`, detalhe, navegação ou sheet), fechados por padrão quando não forem necessários à decisão inicial.
5. Não repetir o mesmo dado em hero, card, lateral e rodapé. Cada métrica tem uma casa.

## Estrutura da janela

- Sidebar nativa e estável como navegação primária.
- Wordmark oficial na sidebar; o `iconApp` continua usando o símbolo da marca.
- Conteúdo principal com largura deliberada e legível, sem esticar cards ou listas só para preencher a janela.
- Coluna lateral, quando existir, serve para contexto recorrente (qualidade, histórico recente), não para duplicar o conteúdo principal.
- Em páginas utilitárias, prefira seções simples, listas e separadores a coleções de cartões decorativos.

## Estados e detalhes

- Estado vazio deve explicar o que falta, por que importa e qual é o próximo passo — sem empilhar blocos frouxos pela tela.
- Erro ou indisponibilidade deve apresentar o resumo compreensível primeiro; causa técnica, resposta remota ou texto longo entram em detalhe.
- Dados não confirmados não recebem aparência de certeza.
- Sheets seguem o mesmo princípio: título e decisão no topo, ação explícita, cancelamento nativo e conteúdo rolável apenas quando necessário.

## Aplicação por família

| Família | Regra de leitura |
| --- | --- |
| Velocímetro | Download e upload são protagonistas; uma ação de repetir; detalhes e rede atual ficam recolhidos. |
| Histórico | Tendência e lista são a tarefa principal; mantenha densidade de lista e abra a medição para profundidade. |
| Assist | Pergunta e caminho de diagnóstico primeiro; a medição usada como contexto compacto. |
| Otimização | Uma oportunidade ou uma conclusão clara primeiro; comparações e retestes são próximos passos, não CTAs dispersos. |
| DNS | Estado do resolvedor e decisão de comparar primeiro; metodologia e ressalvas em camada secundária. |
| Ajustes e Ambientes | Seções agrupadas, listas nativas e próximos passos concretos para estados vazios. |
| Status de serviços | Resumo legível do estado antes de texto remoto; detalhes extensos não devem dominar a lista. |

## Gate de aceite visual no Mac

Antes de considerar uma área padronizada, validar no app instalado os destinos alcançáveis pela sidebar, navegação, toolbar, sheets, alertas e detalhes aninhados, nos estados que existirem: vazio, carregando, resultado, erro e ação destrutiva.

O aceite verifica: resultado/decisão compreensível em poucos segundos, uma ação primária por estado, ausência de repetição de dados, leitura confortável em janela ampla e foco/rotulagem acessíveis. A inspeção visual não substitui testes de teclado, VoiceOver, contraste e Dynamic Type.

## Auditoria inicial — 16 de setembro de 2026

Capturada no app macOS instalado, com uma medição concluída e dados locais reais. Esta é uma linha de base para priorização, não substitui a validação dos estados ainda não exercitados.

| Tela ou caminho | Situação | Próximo passo |
| --- | --- | --- |
| Velocímetro — resultado | Aprovado | Manter a hierarquia opção 3: resultado, CTA único, detalhes e rede atual recolhidos. |
| Histórico | Saudável | Manter lista densa e gráfico como contexto; revisar apenas os estados vazio e detalhe de uma medição. |
| Assist — seleção | Saudável | Manter pergunta primeiro e medição compacta; não reintroduzir cards decorativos. |
| Otimização — sem oportunidade | Ajustar | Reunir a conclusão, o contexto de ambiente e o próximo passo em uma sequência curta; hoje os CTAs e blocos ficam dispersos. |
| Resposta de DNS — indisponível | Ajustar leve | Preservar a honestidade do estado; reduzir a metodologia visível e priorizar a decisão de iniciar a comparação. |
| Ajustes | Saudável | Manter as seções agrupadas e a navegação de detalhe nativa. |
| Ambientes — vazio | Saudável | Manter o próximo passo explícito; validar o estado com ambientes salvos e os sheets de edição. |
| Status de serviços | Ajustar | Mostrar um resumo de estado curto por serviço; texto remoto longo e em inglês deve ir para detalhe, sem dominar a lista. |

Pendências de validação: carregamento e erro do DNS, resultado e erro do Assist, oportunidades/reteste de Otimização, detalhe de histórico, ambientes preenchidos e os sheets/alertas. Elas não foram forçadas nesta auditoria para não alterar dados locais ou disparar diagnósticos durante a inspeção visual.
