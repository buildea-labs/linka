---
name: rodar-no-iphone
description: Procedimento do Camillo para construir, assinar e instalar o Linka em iPhone, iPad ou Mac reais sem transformar build local em publicação.
---

# Skill: rodar-no-iphone

Procedimento de **Camillo** para build e instalação local no ecossistema Apple.

Projeto principal: `aplicativo-ios/LinkaApp.xcodeproj`. Use o estado real do repositório como fonte para schemes, targets e pacotes disponíveis.

## Primeiro valide os pacotes tocados

Execute `swift test` nos pacotes afetados antes de partir para validação mais cara no app.

## Simulador

Simulador é útil para layout, navegação e adaptação rápida de telas. Não é prova de medição de rede real.

## Dispositivo real

Com aparelho autorizado e configuração de assinatura válida:

- faça build usando Xcode/xcodebuild conforme o target atual;
- instale pelo Xcode ou ferramentas oficiais da Apple;
- valide em Wi‑Fi e celular quando a mudança tocar medição;
- teste background/foreground, cancelamento e offline quando aplicável.

Não altere `DEVELOPMENT_TEAM`, certificados ou entitlements compartilhados no repositório apenas para fazer a máquina local compilar sem entender o impacto.

## Problemas de ambiente

Licença do Xcode, plataforma iOS ausente, Developer Mode, signing e Keychain podem exigir ação do dono da máquina. Não tente contornar segurança da plataforma nem desabilite assinatura/testes para declarar sucesso.

## O que esta skill não autoriza

- TestFlight;
- App Store;
- distribuição externa;
- nova entitlement/capability material;
- nova permissão sensível;
- mudança de credencial;
- desabilitar pipeline.

Essas ações seguem os gates de `AGENTS.md`.

## Relatório

Informe:

- destino usado;
- build/testes executados;
- instalação realizada ou não;
- cenários verificados;
- o que ficou sem teste.

Tito usa essa evidência na auditoria; “build verde” sozinho não encerra validação de comportamento.
