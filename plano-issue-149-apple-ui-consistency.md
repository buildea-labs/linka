# Issue #149 - consistencia Apple-first

## Objetivo

Aplicar uma gramatica visual unica nas telas SwiftUI do Linka, priorizando componentes nativos do iOS, Dynamic Type e comportamento padrao da plataforma.

## Inventario SwiftUI existente

- `MainView`: Home, medicao, resultado, erro, conexao alterada e apresentacao de sheets. Concentra CTAs duplicados a mao, overlays proprios de topbar, cards recorrentes e tipografia fixa.
- `MeasurementDetailView` e `HistoricalMeasurementDetailView`: detalhes tecnicos ja usam `List`, `Section`, `LabeledContent` e toolbar nativa.
- `HistoryView`: usa `ScrollView` com container/card proprio para linhas; filtro e nativo, mas empty state, lista e sort usam padroes locais.
- `AssistView` e `AssistProblemSelectionView`: fluxo preservado, mas headers de sheet sao customizados e blocos internos repetem padroes de card/acao.
- `ConnectionPathDetailView`, `UsageDiagnosticsView` e `ConnectivityTriageView`: conteudo e adequado, mas usam headers proprios em vez de navegacao/toolbar nativa.
- `SettingsView` e `SubscriptionManagementSheet`: Ajustes ja usa `Form`; gerenciamento de assinatura ainda tem header customizado.
- `PurchaseSheet`: paywall com fluxo StoreKit preservado; CTA/restore repetem estilos de botao ja usados em outras telas.
- Componentes recorrentes atuais: `MetricRing`, `StatDisplay`, `PhaseDots`, `LiveConnectionPathView`, `ConnectionPathView`, `HistoryRow`, `PrototypeHistoryRow`, `PlusBadge` duplicado em duas telas.

## Divergencias priorizadas

- Cabecalhos proprios em sheets equivalentes, quando `NavigationStack` + `toolbar` resolve.
- Botoes primarios repetidos com padding, fundo, raio e cor local.
- Empty/error states diferentes entre Historico, Assist e triagem, sem fallback central para iOS 16.
- `PlusBadge` duplicado e chips de status escritos localmente.
- Historico representado como card manual onde `List`/`Section` comunica melhor o padrao iOS.
- Tipografia fixa em pontos em areas que nao sao metrica protagonista.

## Mudanca arquitetural

- Ampliar `DesignSystem.swift` com tokens SwiftUI pequenos: espacamentos, raios, estilo de botao primario/secundario, badge Plus e empty state com `ContentUnavailableView` quando disponivel.
- Substituir headers customizados de sheets por `NavigationStack` e toolbar de cancelamento.
- Converter o Historico principal para `List`/`Section`, preservando filtro, ordenacao e navegacao para detalhe.
- Aplicar estilos centralizados aos CTAs recorrentes sem redesenhar fluxo, copy ou regras de Plus.

## Requisito de aceite

- Todas as telas listadas na issue foram auditadas e as divergencias relevantes corrigidas.
- Funcionalidades atuais preservadas: medir, repetir, detalhe, historico, Assist, Plus, ajustes, Wi-Fi e share.
- Sem nova dependencia visual externa.
- `xcodebuild test` e build iOS aplicavel executados ou reportados como pendencia.

## Nao-objetivo

- Nao alterar `LinkaEngine`, metodologia de medicao, contrato NDS/Assist, StoreKit, entitlement, ads ou publicacao.
- Nao transformar o Linka em dashboard nem recriar UIKit/SwiftUI.
- Nao fazer redesign global ou troca de identidade visual.
