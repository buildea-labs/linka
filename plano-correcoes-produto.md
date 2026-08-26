# Plano de correções e melhorias do Linka

## Objetivo

Remover os bloqueadores de segurança e ajustar a experiência do Linka para que o resultado continue sendo o protagonista, enquanto o Assist oferece interpretação somente quando houver medição e contexto suficientes.

## Diagnóstico de origem

- `CLIENT_API_TOKEN` está versionado em `aplicativo-ios/project.yml` e é injetado no `Info.plist` do app.
- A tela de resultado combina medição, Assist bloqueado, histórico recente, controles e reteste numa mesma superfície.
- O teaser do Assist usa skeleton decorativo para conteúdo indisponível.
- O Assist envia uma pergunta genérica com medição atual, mas sem histórico nem evidências adicionais.
- A validação atual não cobre de forma suficiente iPhone real, iPad, Mac, VoiceOver, Dynamic Type e estados remotos do NDS.

## Mudanças funcionais

### Fase 0 — Bloqueador de segurança

- Remover qualquer token real do projeto, `Info.plist`, configurações versionadas e bundle.
- Alterar o transporte para falhar fechado quando não houver credencial/configuração segura.
- Definir uma fronteira segura para o NDS: preferencialmente um relay/backend que mantenha o segredo fora do app; o app não receberá uma chave permanente.
- Rotacionar/revogar o token exposto como ação operacional separada, antes de qualquer publicação.

### Fase 1 — Resultado mais focado

- Preservar o número medido, unidade, fase, detalhes e reteste.
- Reduzir a competição visual abaixo do resultado.
- Remover ou mover o bloco “Último teste” para Histórico, evitando repetição da medição atual.
- Substituir o teaser bloqueado do Assist por uma chamada simples e não enganosa, ou ocultá-lo quando não puder gerar valor imediato.
- Manter Histórico, Ajustes e detalhes acessíveis sem transformá-los em navegação concorrente.
- Preservar a divulgação progressiva: ping, jitter, perda e dados técnicos continuam em Detalhes.

### Fase 2 — Assist baseado em evidência

- Enviar a medição atual como evidência obrigatória.
- Enviar histórico somente quando existir e dentro do limite definido pelo contrato.
- Enviar contexto de uso somente quando o usuário tiver fornecido esse contexto; não inferir finalidade.
- Exibir erro explícito quando o NDS estiver indisponível, sem resposta, sem credencial ou sem dados suficientes.
- Preservar uma única recomendação determinística do NDS e seus passos, sem criar diagnóstico paralelo no iOS.
- Não colocar interpretação no primeiro frame do resultado.

### Fase 3 — Acessibilidade e plataformas

- Garantir rótulos e valores acessíveis para ring, fase, resultado, detalhes, reteste, histórico e Assist.
- Validar Dynamic Type, VoiceOver, contraste e áreas de toque.
- Validar o fluxo em iPhone, iPad e Mac, incluindo janela redimensionada onde aplicável.
- Validar estados de rede: offline, timeout, resposta parcial, cancelamento e falha do NDS.

## Arquitetura afetada

- `LinkaApp`: hierarquia visual, teaser do Assist, Histórico e acessibilidade.
- `NetworkAssist`: contrato de contexto/evidência, sem importar SwiftUI e sem regra diagnóstica.
- `NetworkDiagnostics`: transporte seguro, erros explícitos e contrato NDS.
- Infraestrutura do relay/backend, caso esta seja a solução aprovada para manter o token fora do cliente.
- `LinkaEngine` e `NetworkCore`: não devem ser alterados, salvo para corrigir uma evidência objetivamente ausente e com plano separado.

## Critérios de aceite

- Nenhum segredo ou token permanente aparece no repositório, `Info.plist` ou bundle do app.
- O app não exibe Assist bloqueado como conteúdo falso ou skeleton de uma resposta inexistente.
- O primeiro frame do resultado continua priorizando a medição.
- O Assist não responde sobre histórico/contexto que não recebeu.
- Falhas de credencial, relay, NDS, timeout e dados insuficientes aparecem como estados explícitos e acionáveis.
- A recomendação do NDS continua única, rastreável e baseada em evidências.
- Testes unitários cobrem transporte seguro, ausência de contexto, histórico limitado, erro remoto e recomendação nula.
- `swift test` passa nos pacotes afetados; o app compila para iOS e macOS.
- Há validação visual em simulador e validação funcional em pelo menos um iPhone real antes do aceite final.

## Ordem de execução

1. Segurança e rotação do segredo.
2. Contrato de transporte seguro para o Assist/NDS.
3. Redução da densidade da tela de resultado.
4. Contexto real e evidências do Assist.
5. Acessibilidade e validação multiplataforma.

## Riscos e decisões necessárias

- Remover o token sem um relay ou mecanismo seguro pode deixar o Assist indisponível temporariamente. Isso é preferível a publicar uma credencial no cliente.
- O relay exige decisão de infraestrutura, autenticação/rate limit e custo operacional; não será implantado sem aprovação específica.
- Ocultar completamente o Assist reduz conversão do Plus, mas protege o protagonismo do resultado e evita promessa enganosa.
- A mudança visual deve permanecer contida: não transformar o Linka em dashboard nem reintroduzir navegação pesada.

## Não-objetivos

- Não criar versão Web ou Android do produto.
- Não transformar o Linka em central de diagnóstico.
- Não adicionar chat aberto, explicações genéricas ou recomendações inventadas.
- Não alterar a metodologia do SpeedTest nesta entrega.
- Não fazer deploy, publicar em loja, revogar credenciais ou alterar infraestrutura sem autorização operacional explícita.
