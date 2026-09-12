# Plano: unificar direção visual (nav persistente + dashboard) em iOS e Mac

> **Trilha:** Full-flow | **Produto:** pendente de Íris (ver §5) | **Arquitetura:** este documento | **Orquestração:** Claude Code
>
> Nota de transparência: esta sessão não tem acesso aos subagentes nativos
> `.codex/agents/` (Íris/Camillo/Tito). As decisões de design abaixo (§5)
> são recomendações, não deliberação de um especialista separado — precisam
> de confirmação de produto antes de virar UI final.

## 1. Origem e decisão do Luiz

Luiz montou uma direção de design no Claude Design (`Mac Apps.dc.html` → componente `Mac Dashboard`) com: nav persistente em pill no topo (Velocímetro / Histórico), conteúdo em cards (dashboard), e um gauge semicircular no lugar do anel atual.

**Escopo final confirmado (revisão de 2026-09-12): esta direção é exclusiva do Mac.** Uma instrução anterior desta mesma sessão pedia unificação com o iOS; foi revertida explicitamente — **o iOS permanece 100% como está hoje**, sem nenhuma alteração de layout, navegação, gauge ou toolbar. Isso significa que `plano-jornada-apple-sem-navbar.md` **não é superado nem contestado por este plano** — continua valendo integralmente para o iOS. Os dois planos coexistem porque descrevem plataformas diferentes, não porque um substitui o outro.

Todas as decisões da Íris em §5 (originalmente pensadas para os dois destinos) aplicam-se **somente ao target `LinkaApp_macOS`**.

## 2. Comportamento desejado

- **Só o Mac** ganha: nav persistente no topo com 2 pills ("Velocímetro" e "Histórico"), sem push/pop de tela cheia para trocar entre eles.
- No painel "Velocímetro" do Mac, a máquina de estados existente (idle → connecting → downloading → uploading → done/error/connectionChanged) continua a mesma — só reembalada num único card, em vez de full-bleed.
- "Histórico" no Mac é um painel embutido no mesmo nav, não uma tela empurrada; fica desabilitado (visível, não clicável) durante medição ativa.
- Settings, Assist, Usage Diagnostics, Caminho da Conexão, Router/Gateway e Purchase continuam como sheet/modal no Mac — não entram como pill de nav.
- O pill de "servidor" do mock mantém o **dado** (nome do servidor da medição atual) como texto informativo, mas **sem** nenhuma ação de troca/seleção manual — nem botão, nem ícone de ajuste ao lado.
- **iOS e iPad não mudam nada nesta entrega** — nenhum layout, ícone, navegação ou componente visual do iOS é tocado. `plano-jornada-apple-sem-navbar.md` continua sendo a referência ativa para essas plataformas.

## 3. Arquitetura atual relevante

`LinkaApp/Sources/UI/MainView.swift` é compartilhado pelos targets iOS e macOS (`LinkaApp` e `LinkaApp_macOS`, mesmos 41 arquivos-fonte) e instanciado a partir de `LinkaApp/Sources/LinkaApp.swift` (`WindowGroup { MainView() }`), também compartilhado. Hoje:

- Um único `NavigationStack` com `navPath: NavigationPath`.
- `enum AppRoute { settings, history, measurementDetail }` — destinos de **push**.
- Toolbar contextual por fase (`viewModel.uiPhase`): ícone de casa, relógio → `navPath.append(.history)`, share, settings → `navPath.append(.settings)`.
- `activeMeasurementView` mapeia `viewModel.uiPhase` para `idleView` / `measuringView` / `resultView` / `errorView` / `connectionChangedView`.
- Assist, Purchase, Usage, ConnectionPath, ConnectivityTriage, ExpertModeMigrationBanner, Details, ShareSheet: todos `.sheet(isPresented:)`.
- Histórico de commits mostra padrão recorrente de "guardar API iOS-only" para manter o build do macOS íntegro (issues #108, #111, #112, #113, #115) — mas isso era proteção de **compilação**, não separação de **UI**. Esta entrega precisa do segundo tipo de separação, mais forte.

**Decisão de arquitetura (dado o requisito "iOS não muda nada"): não editar `MainView.swift`.** Editar esse arquivo — mesmo sob `#if os(macOS)` — cria risco real de regressão silenciosa no iOS a cada mudança futura nele, porque as duas plataformas passam a compartilhar pontos de decisão dentro do mesmo corpo de função. A garantia de "zero mudança no iOS" fica muito mais forte com um arquivo novo, exclusivo do Mac.

**Proposta:** criar `LinkaApp/Sources/UI/MacMainView.swift` (novo arquivo, presente apenas no target `LinkaApp_macOS` — não adicionado ao target iOS no `project.pbxproj`), contendo a nav de pills + os cards descritos em §5. Em `LinkaApp.swift`, o único ponto de contato:

```swift
var body: some Scene {
    WindowGroup {
        #if os(macOS)
        MacMainView()
        #else
        MainView()
        #endif
        .environmentObject(entitlements)
        ...
    }
}
```

Esse é o **único** ponto de `LinkaApp.swift` (arquivo hoje compartilhado) que muda — uma bifurcação de 3 linhas, sem tocar em nenhuma lógica existente do branch iOS.

## 4. Módulos afetados

- **Novo:** `LinkaApp/Sources/UI/MacMainView.swift` — nav de pills, card único do Velocímetro, painel de Histórico embutido. Reaproveita `SpeedTestViewModel`, `LinkaHealthCheck`, `AppIntentCoordinator`, `StoreKitEntitlementProvider` — mesmos view models do iOS, camada de apresentação nova.
- `LinkaApp/Sources/LinkaApp.swift` — bifurcação de 3 linhas por `#if os(macOS)` (ver §3). Único arquivo hoje compartilhado que sofre qualquer edição.
- **Intocados:** `MainView.swift`, `HistoryView.swift` e todo o resto da UI do iOS — nenhuma linha alterada.
- `project.pbxproj` — adicionar `MacMainView.swift` só ao target `LinkaApp_macOS`.
- Design System — precisa de: componente de pill/segmented nav, gauge semicircular (D1), card único (D3). Se esses componentes forem adicionados ao pacote de Design System compartilhado (em vez de ficarem só dentro de `MacMainView.swift`), eles ficam disponíveis para o iOS também usar no futuro — mas **não usados por nenhuma view iOS nesta entrega**. Isso é seguro (adição, não alteração de componente existente).
- `LinkaWidgetShared` / `LinkaEngine` / `NetworkCore` / entitlements: **não afetados**.

## 5. Decisões de design — consolidadas pela Íris (via `codex exec`, somente leitura, 2026-09-12)

Delegadas ao subagente nativo `iris` do Codex CLI (`.codex/agents/iris.toml`), leitura restrita a este plano, ao plano anterior, a `MainView.swift`/`HistoryView.swift` e à documentação de protótipo/Design System. Nenhum código ou documento foi alterado por ela.

**D1 — Gauge: DECIDIDO.** Semicírculo único, iOS e Mac. Comunica fase/progresso; o número medido central continua sendo a verdade — sem escala inventada nem estética de velocímetro automotivo.

**D2 — Nav vs. sheet: DECIDIDO.** Só duas pills persistentes — **Velocímetro** e **Histórico**. Settings, Assist, Usage Diagnostics, Router/Gateway e Purchase seguem em sheet/modal contextual, como hoje. Refinamento da Íris: durante uma medição ativa, o pill de Histórico fica visível mas **desabilitado** — não deixa a pessoa saltar pra fora do teste em andamento.

**D3 — Card: DECIDIDO.** Um único painel-card cobre todos os estados do Velocímetro (idle, connecting, download, upload, resultado, erro, mudança de conexão) — a moldura não muda, só o conteúdo dentro dela. Sem cardização em cascata, sem virar dashboard de métricas.

**D4 — Toolbar: DECIDIDO.** A pill substitui os ícones de casa e relógio (saem do toolbar). Settings continua em sheet. Compartilhar aparece só no resultado concluído. **Sem** atalho de troca manual de servidor.

### Pontos resolvidos pelo Luiz após a devolução da Íris

1. `Mac Apps.dc.html` não está versionado no repo — não há como exigir fidelidade geométrica pixel a pixel ao mock, só a direção descrita acima.
2. Pill de "servidor": **mantém o dado** (nome do servidor da medição atual, texto informativo), **remove a ação de troca manual** — sem botão, sem ícone de ajuste ao lado. Refinamento do Luiz sobre a recomendação da Íris (que sugeria remover o pill inteiro); resultado final preserva a informação sem reabrir seleção manual de servidor (§6 do AGENTS.md).
3. **Escopo restrito ao Mac**: todas as decisões D1–D4 abaixo aplicam-se exclusivamente a `MacMainView.swift`/target `LinkaApp_macOS`. Nenhuma delas é aplicada ao iOS nesta entrega.

### Critérios de aceite (Íris)

- Duas pills apenas.
- Trocar entre idle/resultado não perde estado.
- Medição ativa continua visível e cancelável (Histórico desabilitado, não escondido).
- Resultado mantém download como maior hierarquia visual.
- Erro e mudança de rede preservam explicação factual e reteste.
- VoiceOver, contraste, Dynamic Type e alvos de toque seguem suportados.

## 6. Contratos e fluxo de dados

Nenhum contrato de `NetworkMeasurement`, `LinkaEngine` ou `LinkaEntitlements` muda. É reorganização de apresentação sobre dados que já existem. Único dado novo cogitado (canal Wi-Fi via CoreWLAN no Mac, visto no mock) fica **fora deste plano** — entra como item separado se/quando confirmado.

## 7. Persistência

Sem mudança. Histórico continua via `MeasurementHistoryRepository` (+ sync CloudKit já existente).

## 8. Falhas

Sem novo modo de falha. Garantir que `errorView` e `connectionChangedView` renderizam corretamente dentro do novo shell de nav (não podem depender de estarem no topo da pilha de navegação, já que não há mais pilha).

## 9. Segurança/privacidade

Sem impacto — mudança de apresentação apenas.

## 10. Compatibilidade

Deployment target atual (iOS 16 / macOS 13) suporta tudo que este plano precisa (`Shape`/`Path` para gauge, segmented control custom) sem elevar target.

## 11. Testes

- Testes de navegação: trocar entre pills não deve disparar nova medição nem perder estado do painel oposto.
- Testes visuais/manuais contra o protótipo do Claude Design (fonte canônica agora, por §3).
- Build e `swift test` nos pacotes tocados; validação manual em iPhone e Mac (dois destinos oficiais do produto, §2 do AGENTS.md).

## 12. Riscos

- **Divergência intencional entre iOS e Mac** deixa de ser risco e passa a ser o objetivo desta entrega — mas precisa de nota clara em qualquer changelog/release notes para não parecer inconsistência não-intencional.
- Se `MacMainView.swift` reaproveitar mal os view models (ex.: reimplementar lógica que já existe em `SpeedTestViewModel`/`MainView`), duplica bug de estado entre as duas telas — mitigar reutilizando os mesmos `@StateObject`/`@ObservedObject`, só trocando a camada de apresentação.
- `HistoryView` (usada apenas pelo iOS a partir de agora) não é reaproveitada pelo Mac — o painel de Histórico do Mac é conteúdo novo dentro de `MacMainView.swift`, então não há risco de regressão nela, mas também não há reuso: dados/consulta ao `MeasurementHistoryRepository` precisam ser reimplementados na camada de apresentação do Mac (não na lógica).
- Adicionar `MacMainView.swift` só ao target `LinkaApp_macOS` no `project.pbxproj` exige atenção manual (fácil de esquecer e acabar compilando também no iOS, ou de esquecer no Mac).

## 13. Não-objetivos

- **Não altera `MainView.swift`, `HistoryView.swift` ou qualquer arquivo/layout usado pelo iOS ou iPad.** Esse é o requisito mais rígido desta entrega.
- Não altera `LinkaEngine`, metodologia de medição ou métricas coletadas.
- Não adiciona Assist/Router/Usage/Settings/Purchase como pill de nav no Mac (D2).
- Não reabre o Mapa de Infraestrutura Wi-Fi (já avaliado e descartado em análise anterior).
- Não altera preço, entitlements ou modelo de assinatura.
- Não faz merge, deploy, publicação ou release — só implementação local até gate humano.

## 14. Status de implementação (2026-09-12)

Implementado:

- `LinkaApp/Sources/UI/MacMainView.swift` (novo, todo o arquivo dentro de `#if os(macOS)`) — nav de 2 pills, painel-card único do Velocímetro cobrindo idle/connecting/downloading/uploading/done/error/connectionChanged, gauge semicircular próprio (`SemicircularGauge`, privado ao arquivo), coluna de Detalhes técnicos + Últimas medições, painel de Histórico embutido, Ajustes/Assist/Purchase/ConnectivityTriage em sheet. Reaproveita `SpeedTestViewModel`, `StoreKitEntitlementProvider`, `AppIntentCoordinator` sem duplicar lógica de motor.
- `LinkaApp/Sources/LinkaApp.swift`: única mudança, uma `@ViewBuilder private var rootView` que bifurca `MacMainView()`/`MainView()` por `#if os(macOS)`.
- `LinkaApp.xcodeproj/project.pbxproj`: `MacMainView.swift` registrado **só** no target `LinkaApp_macOS` (confirmado por diff automatizado contra a árvore de arquivos em disco — não aparece na lista de Sources do target iOS).
- Botão de compartilhar **não** foi incluído na tela de resultado do Mac: `ShareCardView.swift` já tem um branch `#else` (não-UIKit) que é no-op — incluir o botão criaria uma ação que não faz nada. Fora do escopo deste plano implementar compartilhamento nativo no Mac.

Achados durante a implementação (não previstos no plano original):

1. **O projeto usa XcodeGen (`project.yml`), mas o target `LinkaApp_macOS` não está declarado nele** — existe só por edição manual acumulada direto no `project.pbxproj`. Rodar `xcodegen generate` reconstruiria o projeto a partir de `project.yml` e **apagaria o target macOS inteiro**. Isso explica o padrão recorrente de commits "guarda API iOS-only para desbloquear build macOS": o target Mac não é regenerado automaticamente e vai ficando fora de sincronia com `LinkaApp/Sources` (que o iOS varre via glob de pasta) sempre que alguém adiciona um arquivo novo sem lembrar de também registrá-lo manualmente no lado macOS do `pbxproj`.
2. Consequência direta do item 1: `AppStoreReviewPolicy.swift` (issue de solicitar avaliação, já em produção no iOS) estava **ausente do `project.pbxproj` nos dois targets** — nem iOS nem macOS o tinham registrado explicitamente. Corrigido nesta entrega (adicionado aos dois, mecanicamente, sem alterar o conteúdo do arquivo) porque sem isso nenhum build direto do `.pbxproj` compilava.
3. **Bloqueio pré-existente e não resolvido nesta entrega**: com tudo acima corrigido, `xcodebuild` do target `LinkaApp_macOS` ainda falha — de forma consistente em duas tentativas — com `MainView.swift:177: error: the compiler is unable to type-check this expression in reasonable time`, dentro do `body` de `MainView` (`ZStack { Color(uiColor: .systemGroupedBackground)... }` com toolbar/sheets encadeados). Esse erro é **inteiramente dentro de `MainView.swift`**, arquivo que este plano proíbe explicitamente de tocar — não tentei corrigi-lo. Nenhum erro foi reportado em `MacMainView.swift` ou em `LinkaApp.swift` nos dois builds completos que rodei — o código novo compila; quem não compila hoje no target macOS é o arquivo do iOS que ele também carrega.

### Resolução do bloqueio de build (2026-09-12, mesmo dia)

O timeout de type-check em `MainView.swift:177` foi contornado sem tocar no arquivo: `MainView.swift` **saiu da lista de Sources do target `LinkaApp_macOS`** no `project.pbxproj` (só isso — o arquivo continua intacto e é usado normalmente pelo iOS). Isso é seguro porque `AppRoute` e os demais tipos internos de `MainView.swift` não são referenciados por nenhum outro arquivo do target Mac (`MacMainView.swift` tem seu próprio estado de navegação, independente). Confirmado por `grep` que nada mais no target depende desses tipos.

Resultado: `xcodebuild -scheme LinkaApp_macOS` → **BUILD SUCCEEDED**. `xcodebuild -scheme LinkaApp_iOS` → **BUILD SUCCEEDED** (inalterado). Ambos verificados nesta sessão.

Pendente para alguém decidir (fora do escopo desta entrega, que era só a UI do Mac):

- Provisionar o container CloudKit (issue #71, já documentada) para o histórico sincronizar entre iPhone e Mac.
- App Sandbox/entitlements para distribuição na Mac App Store.
- Decidir se o target `LinkaApp_macOS` deve ser formalizado em `project.yml` (XcodeGen) — hoje ele só sobrevive por edição manual acumulada no `.pbxproj`; qualquer `xcodegen generate` futuro sem essa formalização apaga o target Mac inteiro.
