# Telas do PWA

## Mapa

- `BottomNavBar` fixa em todas as telas principais: `Inicio`, `Velocidade`, `Sinal`, `Historico`, `Ajustes`.
- `Dispositivos` permanece como tela principal navegavel via atalho da Home e via fluxo interno de `Sinal`.
- Referencia visual oficial para as telas principais: mockup `linka-webapp.png` (Home, Velocidade, Sinal, Dispositivos, Historico e Ajustes).

- `HomeScreen`: entrada, proposta de valor, consumo por modo, ultimo resultado e atalhos.
- `SpeedTestScreen`: preparacao e inicio do teste, com o painel "Como o teste sera feito" explicando aparelho, rede atual e servidor externo em linguagem simples.
- `RunningScreen`: progresso da medicao em linguagem humana, com etapa atual, percentual, duracao esperada e cancelamento explicito.
- `ResultScreen`: resultado, diagnostico e detalhes.
  - Diagnostico deve destacar uma recomendacao principal em "Prioridade agora" (motivo + proximo passo) e listar no maximo passos complementares abaixo.
  - Exibir indicador simples de confianca da medicao (Alta/Media/Baixa) com orientacao de repetir o teste quando a amostra for instavel ou parcial.
  - Mostrar contexto leigo do teste (tipo de conexao, horario e comparacao com historico da mesma conexao) para facilitar interpretacao de variacao.
  - Recomendar teste complementar direto a partir do diagnostico (DNS, Wi-Fi/Ferramentas ou Avancado), evitando menu solto.
  - Permitir foco por perfil de uso com chips leves (todos, jogos, streaming, trabalho, chamadas), destacando impacto pratico no perfil selecionado.
  - Disponibilizar pacote de evidencia em dois formatos: resumo legivel para suporte e registro tecnico em JSON, ambos com aviso de evidencia circunstancial.
  - Organizar compartilhamento em card vertical separado entre rapido e tecnico/PDF, com dados sensiveis ocultos por padrao.
- `HistoryScreen`: historico local com resumo, leitura de tendencia e rotulos em linguagem humana.
- `SettingsScreen`: ajustes e recursos adicionais.
- `DNSBenchmarkScreen`: comparacao de DNS.
- `DNSGuideScreen`: orientacao para DNS.
- `LocalWifiScreen`: diagnostico Wi-Fi com fallback web.
- `LocalNetworkScreen`: descoberta de rede local com fallback web.
- `FibraScreen`: explicacao e limitacoes de diagnostico de fibra no navegador.
- `PulseScreen`: diagnostico guiado.
- `OnboardingScreen`: primeira experiencia.
- `OfflineScreen`: fallback dedicado para abertura sem internet, com orientacao leiga e atalho para historico offline.

## Regras

- Telas devem funcionar em mobile e desktop.
- Limitacoes do navegador devem ser explicitas.
- Quando o navegador nao identificar o tipo de rede, a interface deve informar "Rede nao identificada" e nao deve assumir Wi-Fi, cabo, dados moveis ou desconexao.
- Cancelar uma medicao deve encerrar o fluxo com aviso claro de que o teste foi interrompido e nenhum resultado novo foi salvo.
- Nenhuma tela deve depender de runtime nativo.
- Evitar emoji e simbolos decorativos na UI final; preferir icones e texto com tokens do design system.
