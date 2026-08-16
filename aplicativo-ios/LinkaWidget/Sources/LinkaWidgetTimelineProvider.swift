import WidgetKit
import LinkaWidgetShared

/// Uma entrada = o último resumo espelhado no App Group, no instante em
/// que a timeline foi construída. `summary == nil` é estado normal
/// ("sem medição anterior" — requisito de aceite da issue #55), não erro.
struct LinkaWidgetEntry: TimelineEntry {
    let date: Date
    let summary: LinkaWidgetShared.LatestMeasurementSummary?
}

/// A extensão de widget só lê — nunca mede e nunca escreve o resumo
/// (isso é responsabilidade de `SpeedTestViewModel`, no app host, depois
/// de `MeasurementHistoryRepository.save()`). Sem polling: a timeline tem
/// uma única entrada e `policy: .never`, porque o resumo só muda quando o
/// usuário efetivamente mede — o app host chama
/// `WidgetCenter.shared.reloadTimelines(ofKind:)` explicitamente depois de
/// cada teste concluído em vez desta extensão ficar consultando por
/// tempo.
struct LinkaWidgetTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LinkaWidgetEntry {
        LinkaWidgetEntry(date: Date(), summary: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (LinkaWidgetEntry) -> Void) {
        let summary = context.isPreview ? nil : LinkaWidgetShared.readLatestSummary()
        completion(LinkaWidgetEntry(date: Date(), summary: summary))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LinkaWidgetEntry>) -> Void) {
        let entry = LinkaWidgetEntry(date: Date(), summary: LinkaWidgetShared.readLatestSummary())
        completion(Timeline(entries: [entry], policy: .never))
    }
}
