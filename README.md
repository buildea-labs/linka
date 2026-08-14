# Linka SpeedTest

**Linka é um SpeedTest minimalista, eficiente e visualmente refinado, Apple-first e também presente na Web.**

Ele existe para fazer uma coisa muito bem: medir a qualidade da conexão e apresentar o resultado de forma imediata, clara e bonita — sem login, sem onboarding, sem escolha de modo. Abre, mede, mostra, repete.

A fronteira com o produto irmão SignallQ é deliberada:

- **Linka mede.**
- **SignallQ interpreta, diagnostica e orienta.**

Governança completa em [`AGENTS.md`](AGENTS.md) na raiz — este README é só a porta de entrada.

## Onde vive cada coisa

| Pasta | Papel |
|---|---|
| [`aplicativo-ios/`](aplicativo-ios/) | App nativo Apple (iPhone/iPad/Mac). SwiftUI + Swift Concurrency, padrão Engine-Adapter-UI. Produto real. |
| [`aplicativo-ios/LinkaEngine/`](aplicativo-ios/LinkaEngine/) | Motor real de medição (download/upload/latência) |
| [`aplicativo-ios/NetworkCore/`](aplicativo-ios/NetworkCore/), [`MeasurementHistory/`](aplicativo-ios/MeasurementHistory/), [`NetworkInsights/`](aplicativo-ios/NetworkInsights/), [`NetworkAssist/`](aplicativo-ios/NetworkAssist/) | Pacotes Swift isolados (contrato canônico, histórico, estatísticas, contexto para IA) |
| [`aplicacao-web/`](aplicacao-web/) | Landing page de marketing. **Não roda teste de velocidade real.** |
| [`aplicacao-web-veloo/`](aplicacao-web-veloo/) | Landing page complementar |
| [`backend/`](backend/), [`servicos-backend/`](servicos-backend/) | Serviços de backend |
| [`documentacao/`](documentacao/) | Documentação atual do produto — comece por [`documentacao/arquitetura/INDICE.md`](documentacao/arquitetura/INDICE.md) |
| [`scripts-automacao/`](scripts-automacao/) | Scripts locais de automação |

## Plataformas

- **iPhone, iPad, Mac** — plataforma exclusiva do produto real de medição.
- **Web** — apenas landing page. Direciona para o app Apple; não mede.
- **Android** — não está previsto.

## Como executar

Cada pasta com código tem seu próprio ciclo de build/testes:

- **App iOS**: abrir `aplicativo-ios/LinkaApp.xcodeproj` no Xcode; testes via `swift test` em cada pacote (`NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaEngine`, `LinkaModules`). CI em `.github/workflows/swift-modules-ci.yml`.
- **Landing web** (`aplicacao-web/`): `npm install && npm run dev`.
- **Landing complementar** (`aplicacao-web-veloo/`): mesmo padrão, ver `aplicacao-web-veloo/README.md`.

Detalhes de build e teste do app iOS ficam nos README dos próprios pacotes Swift e em [`documentacao/arquitetura/`](documentacao/arquitetura/).

## Governança

- Autoridade única: [`AGENTS.md`](AGENTS.md)
- Squad e fluxo de trabalho: [`AGENTS.md`](AGENTS.md) §4-5 e [`.agents/WORKFLOW.md`](.agents/WORKFLOW.md)
- Política de branches: [`AGENTS.md`](AGENTS.md) §12
- Índice de documentação: [`documentacao/arquitetura/INDICE.md`](documentacao/arquitetura/INDICE.md)

Documentos antigos que descreviam workspaces anteriores (Android nativo Kotlin, PWA como produto de medição, workspaces `E:\`/`C:\`/`D:\`) foram arquivados em `<pasta>/.old/` durante a auditoria de 2026-08-14 — não são referência viva.

## Licença

MIT — ver `LICENSE`.
