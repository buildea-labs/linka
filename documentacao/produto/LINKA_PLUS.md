# Linka Free e Linka Plus

Este documento define a fronteira de produto e a arquitetura inicial dos módulos opcionais do Linka no ecossistema Apple.

`AGENTS.md` continua sendo a autoridade de governança do repositório.

## Princípio

O Linka mede. O SignallQ diagnostica.

O Linka Plus pode acompanhar, comparar e explicar os dados que o próprio Linka mediu. Ele não deve evoluir para investigação de causa-raiz, diagnóstico de roteador/Wi-Fi, reparo ou recomendação técnica profunda.

## Free

O teste principal permanece completo e útil sem assinatura:

- medição de latência;
- download;
- upload;
- resultado;
- detalhes básicos;
- reteste.

Não limitar quantidade de testes para forçar assinatura.

## Plus

O Plus habilita capacidades adicionais sem alterar o motor de medição:

- histórico e comparação;
- tendências baseadas nas próprias medições;
- Assist para perguntas sobre medição atual e histórico;
- integrações Apple, como Widgets, App Intents/Siri Shortcuts e histórico compartilhado quando forem implementadas.

## Arquitetura

`LinkaEngine` continua responsável exclusivamente pela medição.

`LinkaModules` é um Swift Package separado e não importa SwiftUI, UIKit, StoreKit ou SDK de IA. A UI e adapters concretos ficam no app.

```text
LinkaApp (SwiftUI)
    |
    +-- LinkaEngine      -> mede
    |
    +-- LinkaModules
          +-- EntitlementProviding
          +-- HistoryProviding
          +-- InsightProviding
          +-- AssistProviding / AssistTransport
          +-- AppleIntegrationProviding
```

A ligação deve ocorrer por protocolos. Uma implementação local pode ser substituída por persistência, StoreKit, CloudKit ou serviço remoto sem mudar as telas consumidoras.

## Política de acesso

A matriz fica centralizada em `LinkaAccessPolicy`:

| Capacidade | Free | Plus |
| --- | --- | --- |
| SpeedTest | sim | sim |
| Histórico | não | sim |
| Insights | não | sim |
| Assist | não | sim |
| Integrações Apple | não | sim |

A UI não deve espalhar verificações de assinatura. Ela pergunta ao provedor de entitlement se uma capacidade está disponível.

## Estado das implementações

### Funcional agora

- contratos públicos dos módulos;
- política Free/Plus;
- histórico em memória;
- comparação determinística entre duas medições;
- transporte injetável do Assist;
- abstração de disponibilidade das integrações Apple;
- testes unitários da matriz de acesso, histórico, comparação e falha segura do Assist.

### Deliberadamente ainda não implementado

- StoreKit e compra real;
- persistência permanente do histórico;
- CloudKit/sincronização entre dispositivos;
- Widgets;
- App Intents/Siri;
- endpoint ou chave de IA;
- autenticação/backend;
- paywall final.

O `UnconfiguredAssistTransport` falha de forma explícita. Nenhuma chave ou chamada remota é embutida no app nesta fundação.

## Assist: limite de escopo

Entrada permitida:

- pergunta do usuário;
- medição atual;
- medições recentes do Linka.

Exemplos adequados:

- "Minha velocidade mudou desde ontem?"
- "Esse resultado é diferente dos últimos testes?"
- "Meu ping aumentou?"

O Assist não deve receber autorização para virar o motor de diagnóstico do SignallQ.

## Integração ao projeto Xcode

`aplicativo-ios/project.yml` declara `LinkaModules` como package local ao lado de `LinkaEngine`.

Após alterar dependências ou arquivos do projeto, regenere o `.xcodeproj` via XcodeGen no ambiente de desenvolvimento e valide build no simulador/dispositivo antes de merge.

## Gate antes de merge

1. `swift test` em `aplicativo-ios/LinkaModules`.
2. Regenerar `LinkaApp.xcodeproj` com XcodeGen.
3. Build iOS e macOS.
4. Confirmar que o SpeedTest existente não mudou.
5. Confirmar que não há SwiftUI/UIKit/StoreKit dentro de `LinkaModules`.
6. Confirmar que não existe API key ou endpoint de IA embutido.
