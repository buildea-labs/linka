# Netscope L-03 — UI local fail-closed

L-03 acrescenta o acesso **Entender esta medição** somente depois de uma
medição concluída. A ação abre uma superfície secundária: retestar continua
na tela do resultado e fechar a superfície preserva a medição exibida.

## Limite desta entrega

`NetscopeAnalysisView` recebe uma porta injetável
`NetscopeAnalysisReadingProviding`. A implementação entregue,
`DisabledNetscopeAnalysisReader`, devolve exclusivamente `unavailable` e não
faz I/O. Não há projeção de `NetworkMeasurement`, serialização, endpoint,
DNS, segredo ou provedor nesta camada.

L-02 é a única etapa autorizada a conectar uma leitura futura à allowlist de
evidência. Até lá, o app mostra que a leitura está indisponível e mantém a
medição local como a única fonte de resultado.

## Dados da apresentação

- `NetscopeObservedEvidence` é separado de `NetscopeDeclaredContext`.
- Detalhes Wi-Fi só podem permanecer quando o tipo observado é `wifi`; caso
  contrário são omitidos.
- Contexto declarado enquadra uma leitura futura, mas não é métrica ou fato
  observado.
- Uma leitura concluída recebe grupos injetáveis de evidência observada,
  limitações e contexto declarado. A UI os mostra em seções separadas e omite
  itens ausentes ou vazios; a seção de contexto só aparece quando há conteúdo
  declarado.

## Estados

O destino suporta `completed`, `inconclusive`, `unavailable` e `outOfScope`.
Nenhum estado de erro declara a conexão saudável, nem expõe
detalhes de rede, identificadores, payloads ou diagnóstico parcial.
`completed` também não declara saúde: indica apenas que uma leitura foi
recebida e usa ícone/cor neutros.

Em `unavailable`, **Tentar novamente** apenas recarrega o mesmo reader com o
mesmo input. Não inicia uma nova medição.

Toda a superfície de leitura fica em `ScrollView`. Isso mantém evidência,
limitações, contexto e ações alcançáveis com Dynamic Type grande em iPhone,
iPad e Mac, inclusive via VoiceOver.

## Regra para uma implementação futura

O campo `summary` de uma leitura concluída só pode resumir evidência recebida
de fato. A implementação precisa declarar limitações e dados ausentes que
afetem a leitura; nunca pode afirmar saúde, causa ou qualidade sem sustentação
na evidência. Em erro, timeout, `inconclusive`, `unavailable` ou `outOfScope`,
ela deve retornar o estado correspondente, nunca fabricar uma
leitura `completed`.

## Plataformas e inclusão no projeto

O arquivo está em `aplicativo-ios/LinkaApp/Sources/UI/`. O XcodeGen já inclui
esse diretório nos alvos `LinkaApp` (iPhone/iPad) e `LinkaApp_macOS`; o alvo
macOS exclui apenas `UI/MainView.swift`. A geração atualiza
`LinkaApp.xcodeproj` sem editar `project.pbxproj` manualmente.
