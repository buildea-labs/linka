# Plano — issues #135 e #136: Ajustes e Linka Plus

## Classificação

**Feature · Full-flow.** As issues reorganizam superfícies secundárias do app,
mudam os pontos de entrada de compra e exigem páginas institucionais distintas.
Não alteram o motor de medição.

## Objetivo

Deixar Ajustes como a casa de assinatura, preferências e integrações opcionais,
e reposicionar o Linka Plus pelo benefício entregue. O resultado e a medição
continuam sem bloqueio e sem nova etapa no fluxo principal.

## Experiência

| Entrada | Antes | Ação | Depois | Falha/saída |
| --- | --- | --- | --- | --- |
| Ajustes | estado real do plano | tocar em Linka Plus | Free abre paywall geral; Plus mostra gestão/restauração oficiais | cancelar fecha sem erro |
| Resultado | medição pronta, detalhes secundários | tocar em entender o resultado | paywall contextual ou Assist, conforme entitlement | compra cancelada retorna ao resultado |
| Histórico | histórico permanece disponível | tocar em análise/Assist | paywall de padrões ou Assist, conforme entitlement | voltar preserva histórico |
| Wi-Fi avançado | integração opcional | tocar em configurar | Free abre paywall Wi-Fi; Plus abre Atalhos/configuração | Atalhos indisponível não vira “Ativo” |
| Identificação Wi-Fi | estado claro, sem prompt automático | tocar no item | explicação curta antes da permissão; estado negado leva aos Ajustes do iOS | desligar interrompe o uso pelo Linka, sem fingir revogar permissão |

Não há mudança de estado, modal ou bloqueio antes de medir. Reduced Motion não
perde conteúdo porque estas são listas e sheets nativas.

## Mudança arquitetural

1. Criar no `LinkaApp` uma fonte única `LinkaExternalLinks` para site, método,
   privacidade, termos e suporte. Nenhuma URL institucional permanece nas Views.
2. Introduzir `PurchaseEntryPoint` (`settings`, `assist`, `historyInsights`,
   `advancedWiFi`) e fazer `PurchaseSheet` receber somente esse contexto. A
   tela continua única; título/subtítulo mudam sem duplicação.
3. Centralizar as ações de assinatura em uma superfície de conta: StoreKit é a
   fonte de entitlement, `restore()` é reutilizado, e o gerenciamento usa a
   sheet oficial da App Store nas plataformas em que ela é suportada. Nenhuma
   assinatura é inferida de `UserDefaults` e nenhum cancelamento é próprio.
4. Reorganizar `SettingsSheet` em Linka Plus, Rede e diagnóstico,
   Preferências, Atividade e Sobre o Linka. A identificação Wi-Fi ganha uma
   confirmação explicando a permissão; Wi-Fi avançado preserva os estados
   Free/Configurar/Ativo e permite desativar apenas a integração local.
5. No site institucional, criar roteamento explícito para `/como-medimos`,
   `/privacidade`, `/termos` e, somente com destino oficial confirmado,
   `/suporte`. O Hosting continuará a servir o app React, mas cada rota terá
   conteúdo próprio e metadados adequados em vez de uma landing genérica.
6. Ajustar os callsites existentes de resultado, histórico, Ajustes e Atalhos
   para passar o contexto correto e retomar a intenção depois de compra
   confirmada quando a ação já existir e for segura.

## Especificação visual e copy

- Usar listas SwiftUI agrupadas, separadores hairline, SF Symbols e controles
  nativos; sem hero comercial, dashboard ou nova navegação principal.
- Paywall: título `Linka Plus`; benefício geral `Entenda o que está acontecendo
  com a sua conexão.` Contextos encurtam a mensagem sem mencionar NDS, Insights
  ou nomes internos.
- Free explicita medição, histórico, detalhes básicos e identificação de rede
  quando disponível. Plus descreve interpretação, padrões e Wi-Fi avançado com
  a observação de que Atalhos é configuração opcional.
- Preço vem exclusivamente de `Product.displayPrice`; CTA usa `Assinar`, não
  `Comprar`; cancelamento do sheet StoreKit permanece silencioso.

## Requisito de aceite

- Ajustes mostra plano real e ações coerentes de assinar, gerenciar e restaurar.
- Todo ponto Plus visível para Free abre o mesmo paywall com origem correta.
- Após compra confirmada, entitlement atualiza e a ação de origem é retomada
  apenas quando existente e segura.
- Rede Wi-Fi e Wi-Fi avançado têm estado real e não pedem permissão ao abrir
  Ajustes.
- Aparência reutiliza `appAppearance`; Histórico é atalho secundário.
- Privacidade e Termos são links separados, centralizados e levam a páginas
  oficiais distintas; cada rota publicada tem conteúdo correspondente.
- Testes cobrem contextos de compra, Free/Plus, restauração e estados de
  configuração; builds iOS simulador e macOS continuam verdes.

## Não-objetivos

- Não criar plano mensal, trial, preço fixo, telemetria nova, conta, dashboard,
  widget, mapa ou automação silenciosa.
- Não mudar App Store Connect, preço, produto StoreKit, URLs de ficha da loja,
  credenciais, Hosting ou publicar o site.
- Não escrever política de privacidade, termos ou contato de suporte sem fonte
  oficial aprovada pelo Luiz.

## Bloqueios conhecidos para concluir os links de release

1. `linka-speedtest.web.app` é a base atualmente usada, mas hoje devolve a
   landing genérica para `/como-medimos`, `/privacidade`, `/termos` e
   `/suporte`; não há páginas específicas publicadas.
2. Não há canal oficial de suporte identificado no repositório. A rota e o
   contato só entram quando o Luiz confirmar a fonte oficial.
3. O produto StoreKit `com.linka.plus.annual` ainda está documentado como
   placeholder e não há configuração `.storekit`; a UI pode ser testada por
   estado, mas compra/restauração/gerenciamento reais exigem essa configuração
   ou sandbox/App Store Connect.
