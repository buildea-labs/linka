# Compatibilidade do Linka Assist com o NDS atual

## Objetivo

Atualizar o consumidor iOS do Linka Assist para o contrato canônico atual do NDS, preservando a medição no Linka e mantendo a interpretação remota em superfície secundária.

## Mudança arquitetural

- `NetworkDiagnostics` passa a modelar `requested_outputs`, `context`, `traces` e os campos aditivos da recomendação (`steps`).
- `NDSRequestBuilder` passa a separar capacidades de evidência dos outputs solicitados: `capabilities` descreve dados disponíveis e `requested_outputs` solicita scoring/IA.
- O contexto do Assist fica modelado para uso futuro; esta chamada de compatibilidade só envia contexto quando ele existir, sem inventar problema ou resposta no cliente.
- O adaptador do Assist continuará consumindo uma única `recommendation`; os passos serão preservados no contrato nativo para evolução posterior da UI.
- Erros HTTP do NDS serão decodificados no envelope estável (`error.code`, `message`, `retryable`, `request_id`) e continuarão sendo falhas explícitas.

### Custo das opções

- Seguir com o contrato atual do NDS evita aliases legados no cliente, mantém a recomendação determinística e reduz divergência entre iOS, Android e Web.
- Não seguir deixaria o Linka dependente de aliases de transição e descartaria `steps`, além de dificultar diagnóstico de erros correlacionáveis.
- A mudança é reversível no cliente porque o NDS mantém compatibilidade aditiva na API v1; não haverá migração de dados persistidos.

## Requisito de aceite

- O Linka envia `requested_outputs: ["scoring", "ai"]` no fluxo Assist remoto e não usa esses valores como capabilities de evidência.
- O payload mantém apenas evidências realmente disponíveis da medição e do sistema Apple.
- O Linka decodifica a recomendação com `steps`, `traces` e o envelope de erro canônico sem quebrar respostas compatíveis anteriores.
- Testes cobrem request novo, resposta com recomendação e passos, recomendação nula e erro canônico.
- `swift test` passa em `NetworkDiagnostics`, `NetworkAssist`, `LinkaModules` e demais pacotes afetados.

## Não-objetivo

- Não alterar `LinkaEngine`, `NetworkCore` ou a metodologia de medição.
- Não duplicar regras do NDS no iOS.
- Não criar chat aberto, fallback diagnóstico local ou nova tela no primeiro frame do resultado.
- Não fazer deploy do NDS, publicar o app ou alterar o repositório do NDS nesta entrega.
