# Plano — DNS Linka+ (benchmark DoH e configuração consentida)

## Objetivo

Permitir que a pessoa Linka+ compare, por ação explícita e após uma medição
concluída, a resposta DNS nesta conexão e, se escolher, crie uma configuração
DoH do provedor selecionado. Medição de velocidade continua protagonista.

## Comportamento esperado

- O percurso é `Resultado → Otimização → Comparar resposta de DNS`, em Wi-Fi
  ou rede móvel. Não há Home, atalho, execução automática ou histórico DNS.
- Free recebe apenas prévia sem nomes de provedores, consultas ou resultados.
- A sessão é efêmera: saúde do DNS atual e benchmark não entram em Histórico,
  perfis, CloudKit, NDS, Assist, telemetria ou backend.
- Saúde atual significa apenas uma resolução pelo resolver do sistema;
  permanece fora do ranking por cache e transporte diferentes.
- O comparativo consulta via DoH Cloudflare, Google, Quad9, OpenDNS e AdGuard.
  Cada candidato recebe a mesma query sintética por rodada, três rodadas,
  ordem determinística randomizada e mediana das amostras válidas. A menor
  mediana é o vencedor matemático; empate só quando as medianas são iguais.
- Timeout, cancelamento, falha e ausência são distintos e nunca equivalem a
  `0 ms`. Menos de duas amostras válidas deixa o candidato inconclusivo.
- Um candidato válido pode ser escolhido manualmente. A indicação é factual:
  menor mediana desta tentativa, nunca “melhor DNS” nem promessa de ganho de
  Mbps, ping ou Wi-Fi.
- Antes de criar a configuração, há confirmação não pré-marcada com provedor,
  DoH, efeito system-wide, envio de consultas ao provedor, política dele e
  remoção. O Linka só cria a própria configuração; a pessoa a habilita no SO.
- Só mostrar `Ativa` depois de reload e `isEnabled` confirmados. Falha ou
  conflito não sobrescreve VPN, MDM ou terceiros e não troca provedor sozinho.
  A remoção chama-se `Remover configuração de DNS` e afeta só a configuração
  criada pelo Linka.
- Após aplicar, `Medir de novo` é sempre manual.

## Mudança técnica

- Novo pacote puro `NetworkDNSBenchmark` para catálogo, modelos, agregação,
  ordenação, validação e testes. Executor de rede isolado no app; não inserir
  regra, UI ou rede no `LinkaEngine`, nem mudar `NetworkMeasurement`.
- Catálogo local e versionado contendo id, nome, URL DoH, bootstrap IPs e URL
  de privacidade. Sem fetch remoto ou reverse lookup. Só exibir IP quando o
  transporte devolver endereço remoto factual; gateway privado é apenas
  `Gateway/local`, nunca DNS upstream.
- Usar requests DNS wire-format DoH com `URLSession` efêmera, caches/cookies
  desligados, timeout de dois segundos, sem retry oculto e cancelamento real.
- Criar adaptador de `NEDNSSettingsManager`/`NEDNSOverHTTPSSettings`, testável
  por protocolo fake, para load/save/reload/remove da única configuração da
  app. Exige `com.apple.developer.networking.networkextension = dns-settings`.
- Ajustes: manter SF Symbol `wifi` em Identificação de rede e usar `tag` para
  Perfis de rede em iOS/iPad e macOS.

## Aceite

- Benchmark só inicia em Linka+ após resultado; Free não vê candidatos ou
  dados reais; cancelamento não produz ranking válido.
- Cada resultado anuncia provedor, tempo, unidade e estado para VoiceOver.
  Copy usa “Comparar resposta de DNS” e não promete aceleração.
- Testes cobrem catálogo, ordem, mesma query por rodada, mediana, empate,
  timeout, falha, cancelamento, mudança de conexão e dados não persistidos.
- Testes do manager cobrem save/reload, estado ativo, divergência, erro e
  remoção sem alterar configuração alheia.
- Teste físico em iPhone e Mac valida provisioning, habilitação manual no SO,
  reload/isEnabled, relaunch, troca de conexão, remoção e conflitos.

## Não-objetivos e gates

- Sem DoT, proxy DNS, VPN, worker, backend, telemetria, automação de roteador,
  perfil externo ou fallback automático.
- Benchmark pode ser entregue se a capability Apple não for provisionada;
  nesse caso Aplicar fica indisponível sem workaround.
- Antes da aplicação: validar endpoints e políticas dos cinco provedores,
  capability/provisioning de ambos os targets, codesign real, App Privacy e
  notas de App Review. Simulador não prova DNS system-wide.
