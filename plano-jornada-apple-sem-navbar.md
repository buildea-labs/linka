# Jornada Apple do Linka sem navbar

## Objetivo

Dar ao usuário controle explícito sobre a medição e manter o estado real da
conexão visível em toda a jornada: abrir, compreender a rota ativa, iniciar
um teste, ver o resultado e recorrer a detalhes, histórico ou Assist sem uma
barra de navegação persistente.

## Mudança arquitetural

- A abertura não inicia `SpeedTestCore` automaticamente. A Home começa em
  estado pronto e só `Testar conexão` inicia uma medição.
- A Home usa um Caminho da Conexão de contexto ao vivo (aparelho → interface
  ativa → internet), separado do `ConnectionPathReport`, que só existe após
  evidência de uma medição. O contexto ao vivo não afirma saúde da internet.
- O `SpeedTestViewModel` mantém um snapshot da rota que iniciou a medição.
  Uma alteração posterior de interface ou disponibilidade cancela o task,
  descarta dados parciais, não salva histórico e expõe um estado explícito
  `connectionChanged` até novo toque do usuário.
- Resultado e histórico guardam apenas o contexto da medição concluída.
  O contexto ativo pode aparecer como informação secundária, sem alterar o
  registro salvo.
- Detalhes simples usam divulgação progressiva. Atividade, Assist, Ajustes e
  compra são superfícies contextuais apresentadas sem navbar persistente.
- Enquanto aguarda o Assist remoto, a UI mostra os fatos já coletados e a
  mensagem `Analisando esta medição`; não mostra progresso percentual nem
  afirma que uma nova medição está acontecendo.

## Requisito de aceite

- Abrir ou retornar ao app nunca inicia uma medição sem ação explícita.
- A Home atualiza o Caminho da Conexão entre Wi-Fi, rede móvel, Ethernet e
  indisponível enquanto está visível.
- Trocar Wi-Fi ↔ móvel ou perder o caminho durante uma medição cancela-a,
  descarta qualquer resultado parcial e oferece apenas `Testar conexão`.
- Resultado, histórico e Assist nunca recebem uma medição que atravessou
  duas rotas.
- O resultado continua protagonista e distingue, quando necessário, a rede
  medida da conexão atual.
- O Assist tem estados visuais de espera, sucesso, erro e retentativa, com
  copy factual e sem spinner genérico isolado.
- Não há tab bar ou toolbar de navegação persistente na Home. Fluxos
  secundários preservam retorno explícito ao contexto de origem.
- Testes cobrem abertura sem medição automática, cancelamento por mudança de
  rota, ausência de persistência e estado transitório do Assist; build iOS,
  macOS e validação manual no iPhone passam.

## Não-objetivos

- Não alterar metodologia, servidores ou precisão de `LinkaEngine`.
- Não inferir saúde da internet, roteador ou operadora apenas do
  `NWPathMonitor`.
- Não criar dashboard, tabs, conta, coleta adicional, telemetria de rota ou
  automação de testes em segundo plano.
- Não publicar, fazer merge, deploy ou alterar credenciais nesta entrega.
