# Assist: diagnóstico do agora

## Objetivo

Separar claramente o teste de velocidade do diagnóstico de rede. O Assist
sempre coleta uma medição nova antes de consultar o NDS e explica somente
essa medição.

## Mudança

- A Home passa a chamar a ação de medição de **Testar velocidade**.
- A entrada **Analisar minha conexão** pergunta o sintoma, mede agora e só
  então abre o Assist com esse contexto.
- Histórico deixa de abrir o Assist por uma medição antiga.
- Assist não envia medições recentes, resumo histórico ou cache de análise
  como se fossem parte do diagnóstico atual.

## Aceite

- Abrir o Assist nunca reutiliza teste ou análise antigos.
- O payload do NDS contém somente a medição recém-concluída da jornada.
- Histórico permanece uma superfície de consulta, sem atalho de diagnóstico.

## Não objetivo

Não altera o motor de medição nem cria comparação histórica dentro do Assist.
