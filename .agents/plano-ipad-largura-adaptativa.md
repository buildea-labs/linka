# Architecture Plan: Largura adaptativa no iPad + reabertura do device family

## 1. Contexto e Problema
O Luiz explorou, via protótipo visual fora do repo, como melhorar o aproveitamento de tela do iPad na tela de Resultado do Linka SpeedTest sem esticar o conteúdo borda a borda nem redesenhar a tela (rejeitou tanto split em duas colunas quanto cardização — ver §6 do AGENTS.md, "evite cardização").

Direção aprovada: manter a mesma pilha vertical de sempre (idle, medindo, resultado — mesma ordem, mesmos componentes, mesma interação de "Mais"), só redimensionar a coluna central para o iPad em vez de travá-la em 500pt.

Ao investigar para implementar, descobri um bloqueio: `TARGETED_DEVICE_FAMILY: "1"` (`aplicativo-ios/project.yml:26`, commit `012c63fd`, 2026-09-07, decisão do Luiz) faz o app compilar como iPhone-only. No iPad ele roda em modo de compatibilidade (iPhone ampliado pelo sistema) — nesse modo `horizontalSizeClass` nunca é `.regular`, então nenhum ajuste de layout baseado em size class tem efeito. Isso contradiz o AGENTS.md atual (§1/§2, iPad como destino oficial do produto), mas era uma decisão deliberada e recente — por isso perguntei ao Luiz antes de mexer, em vez de reverter sozinho. Ele confirmou: reabrir o iPad no build agora.

## 2. Decisão de Produto (Luiz, nesta sessão)
- Reabrir iPad no escopo de build (`TARGETED_DEVICE_FAMILY "1,2"`), mantendo iPhone-only em orientação (retrato) e adicionando as 4 orientações só para iPad.
- Redimensionar a coluna central do fluxo principal (idle/medindo/resultado) para ~720pt em `.regular`, mantendo 500pt em `.compact` (iPhone, sem mudança).
- **Não-objetivos:** sem split em duas colunas, sem cards novos, sem `NavigationSplitView`, sem redesenho de conteúdo. Mac (`MacMainView`) fora de escopo — já tem tratamento próprio.

## 3. Investigação de escopo (Íris — evidência de código)
Levantamento de toda `aplicativo-ios/LinkaApp/Sources/UI/*.swift` por padrões de largura fixa/full-screen:
- **`MainView.swift:261`** — único `.frame(maxWidth: 500)` real do fluxo iOS (idle/medindo/resultado), conteúdo empurrado via `NavigationStack` (não é sheet, ocupa a tela cheia). **Único ponto que precisava de ajuste.**
- `HistoryView`, `MeasurementDetailView`/`HistoricalMeasurementDetailView`, `AssistProblemSelectionView`, `UsageDiagnosticsView`, `ConnectionPathDetailView` usam `List`/`Form` nativos — já é o padrão HIG correto para iPad (mesmo comportamento do Settings.app), não precisam de cap.
- `AssistView`, `OptimizationView`, `PurchaseSheet`, `ConnectivityTriageView`, `SettingsView` (a `SettingsSheet.swift` com `struct SettingsView`) são todos apresentados via `.sheet(...)` a partir de `MainView.swift` — no iPad em `.regular`, `.sheet` já usa a apresentação em cartão nativa do sistema (não preenche a tela), então também não precisam de cap manual.
- O `maxWidth: 620` encontrado em `SettingsSheet.swift:365` é código exclusivo de `#if os(macOS)` (`macOSContent`) — irrelevante para iPad, não tocado.

Conclusão: o problema real era muito mais estreito do que "aplicar em todas as telas" sugeria — a Apple já resolve a maior parte via `List`/`Form`/`.sheet` adaptativos; só a raiz do `NavigationStack` precisava de ajuste manual.

## 4. Solução Técnica (Camillo)
Um único modificador reutilizável em vez de duplicar a constante:

```swift
// DesignSystem.swift
func linkaAdaptiveContentWidth() -> some View // 500pt compact / 720pt regular
```

Aplicado em `MainView.swift:261` no lugar de `.frame(maxWidth: 500)`. Qualquer tela cheia futura do fluxo principal (não-sheet) reaproveita o mesmo modificador em vez de inventar outro número mágico.

Build config (`project.yml` + `Info.plist`, regenerados via `xcodegen generate`):
- `TARGETED_DEVICE_FAMILY: "1,2"`.
- `UISupportedInterfaceOrientations~ipad`: portrait, portrait-upside-down, landscape-left, landscape-right (iPhone permanece só retrato).
- Ícone: `AppIcon.appiconset` já usa `idiom: universal` (formato de ícone único do Xcode 14+) — cobre iPad sem ativo novo.

## 5. Implementação (Pedro/Claude Code)
- `aplicativo-ios/LinkaApp/Sources/UI/DesignSystem.swift`: novo `LinkaAdaptiveContentWidthModifier` + extensão `linkaAdaptiveContentWidth()`.
- `aplicativo-ios/LinkaApp/Sources/UI/MainView.swift`: troca do `.frame(maxWidth: 500)` fixo pelo modificador; comentário atualizado.
- `aplicativo-ios/project.yml` e `aplicativo-ios/LinkaApp/Info.plist`: device family + orientações de iPad.
- `aplicativo-ios/LinkaApp.xcodeproj`: regenerado via `xcodegen generate` (reflete as duas mudanças acima).

## 6. Testes e validação (Tito)
- `xcodebuild -project LinkaApp.xcodeproj -scheme LinkaApp -destination "id=<iPad Pro 13-inch (M5)>" build` — **BUILD SUCCEEDED**, antes e depois da reabertura do device family.
- Validado visualmente no simulador iPad Pro 13" (retrato): antes da reabertura do device family, o app rodava em modo de compatibilidade (conteúdo borda a borda, sem efeito do novo modificador). Depois de reabrir o device family, o app roda nativamente como iPad app (barra de título própria) e o conteúdo passou a respeitar a margem — não mais borda a borda.
- **Não testado:** paisagem no simulador (a ferramenta de simulador desta sessão não expõe rotação), iPhone real/simulador (não deveria mudar — `.compact` mantém 500pt, mas não foi reconfirmado nesta sessão), `xcodebuild test` da suíte `LinkaAppTests` (mudança é só de layout/config, sem lógica nova, mas a suíte não foi rodada), telas apresentadas como `.sheet` (Assist, Otimização, Compra, Triagem, Ajustes) não foram reabertas uma a uma no iPad — a leitura de código indica que `.sheet` já é adaptativo nativamente, mas isso não foi confirmado visualmente tela por tela.

## 7. Riscos e gate humano
- Reabrir iPad no device family é decisão de escopo de produto/App Store (QA, ícones, revisão) — **autorizada pelo Luiz nesta sessão**, mas o gate de merge/publicação continua pendente.
- Nenhum merge, push ou release foi feito. O trabalho está no worktree `ios/.worktrees/ipad-adaptive-layout`, branch `feat/ipad-adaptive-layout`, a partir de `origin/main`, ainda não commitado.
