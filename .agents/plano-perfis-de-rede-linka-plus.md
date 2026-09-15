# Plano — Perfis locais de rede (Fase 2 da Otimização)

## Decisão de produto

O Linka+ permite que a pessoa salve manualmente uma rede Wi-Fi identificada
como um perfil local, com um nome próprio como `Casa` ou `Trabalho`. O perfil
serve apenas para dar contexto às medições e comparar uma leitura com a faixa
habitual daquela mesma rede. Ele não monitora a conexão, não altera ajustes e
não afirma reconhecer um roteador físico.

O fluxo principal continua `ABRIR → MEDIR → MOSTRAR RESULTADO → REPETIR`.
Perfis aparecem somente como continuação da Otimização após uma medição
concluída; no Mac, ficam dentro do destino Otimização já existente.

## Regras de criação e privacidade

Um perfil só pode ser criado quando a medição for Wi-Fi, a identificação Wi-Fi
já estiver habilitada, o sistema tiver fornecido SSID não vazio e a pessoa
confirmar um nome. Não pedir localização nem permissão automaticamente.

- O novo store guarda somente um fingerprint versionado do SSID normalizado,
  nunca o SSID em texto claro, BSSID/MAC ou métricas duplicadas.
- O apelido visível é conteúdo local digitado pela pessoa.
- Perfis e baseline ficam somente no dispositivo nesta fase: sem CloudKit,
  NDS, Assist, endpoint ou telemetria.
- Excluir perfil remove apenas perfil, associação e baseline derivada. O
  Histórico de medições permanece intacto.
- Desabilitar identificação Wi-Fi impede criar/associar perfis novos, sem
  apagar silenciosamente dados que já existiam.

## Referência da rede

Uma referência exige pelo menos três medições completas, elegíveis e recentes
(janela inicial: 30 dias) cujo fingerprint corresponda ao perfil. Ela usa
mediana para download, upload, latência, jitter e perda; ausência de uma
métrica permanece ausência, sem zero sintético.

- Antes de três leituras: `Referência em formação · N de 3 medições`.
- Depois: `Referência pronta` e comparação com a faixa habitual quando a
  leitura atual for elegível.
- Rede sem SSID, celular, registro incompleto ou fora da janela não entra na
  referência.
- O `networkIdentifier` do teste não é identidade da LAN e não pode ser usado.

## Arquitetura

1. Criar pacote puro `NetworkProfiles`, dependente de `Foundation`,
   `CryptoKit` e `NetworkCore`.
2. Modelar `NetworkProfileIdentity`, `NetworkProfile`, protocolo de repositório
   e `FileNetworkProfileRepository` com JSON versionado e escrita atômica.
3. Manter o cálculo de baseline puro em `NetworkOptimization` por meio de
   `NetworkBaselineBuilder`; sem persistência nem estado de UI nesse pacote.
4. Criar `OptimizationProfileCoordinator` no app para aplicar preferência de
   identificação, consultar/salvar perfis locais, carregar histórico e
   atualizar `lastAnalyzedAt` somente após análise explícita.
5. Reutilizar a capability `.optimization`: Free vê a prévia; salvar, editar,
   remover e acompanhar perfil são ações Linka+.
6. Não alterar `LinkaEngine`, schema de `NetworkMeasurement`,
   `MeasurementHistoryCloudKit` ou os contratos de Assist.

## Jornada

### iPhone e iPad

Após resultado Wi-Fi identificável, a folha Otimização mostra `Conhecer esta
rede` e `Criar perfil`. A criação abre um sheet/Form nativo com sugestão de
nome baseada no SSID, campo editável, aviso local de privacidade e salvar.
Depois, o estado mostra a referência em formação ou pronta. `Perfis salvos`
fica dentro de Otimização, nunca na Home.

Se SSID não estiver disponível, explicar a indisponibilidade sem culpar a
pessoa ou o roteador. A prévia Free explica o valor, mas não cria perfil
parcialmente funcional.

### Mac

No destino Otimização, mostrar o contexto `Esta rede`, criar/ver perfil e uma
lista de perfis salvos. O detalhe do perfil mostra estado da referência, última
medição e contagem de amostras, sem dashboard paralelo.

### Gestão

Nome editável; `Refazer referência` remove somente a referência derivada e
reinicia a coleta; `Excluir perfil` é destrutivo com confirmação. VoiceOver
expõe nome, estado, contagem e efeito da exclusão.

## Testes e aceite

- `NetworkProfiles`: normalização/fingerprint, rejeição de identidade ausente,
  round-trip, upsert, remoção, arquivo ausente/corrompido/versão desconhecida
  e ausência de SSID claro no JSON.
- `NetworkOptimization`: janela, três medições, identidade igual, medições
  completas, mediana e métricas parcialmente ausentes.
- App: gate Plus/prévia Free, criação/edição/exclusão, identificação desligada,
  iPhone sem SSID, Mac com SSID e regressão da Fase 1.
- Regressão: `NetworkCore`, `NetworkInsights`, `MeasurementHistory`,
  `LinkaModules`, novo pacote, app iOS e build macOS.

## Não objetivos

Não entram benchmark/configuração de DNS, troca de banda, automação de
roteador, monitoramento em background, sincronização de perfis ou exclusão
automática de histórico.
