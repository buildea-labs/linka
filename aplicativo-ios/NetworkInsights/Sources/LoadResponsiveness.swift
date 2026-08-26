import Foundation
import NetworkCore

/// Categoria objetiva de responsividade da conexão quando ocupada (issue
/// #128) — o quanto a latência cresce sob carga real (download/upload) em
/// relação à latência parada (`latencyMs`). É o proxy observável de
/// bufferbloat: uma fila cheia no roteador atrasa pacotes concorrentes
/// (ex.: um pacote de chamada de vídeo enquanto um upload grande está em
/// andamento), mesmo quando a vazão medida (Mbps) está ótima.
///
/// `.notAssessed` não é "boa" nem "ruim" — é "não sabemos", reservado para
/// quando falta a latência parada ou nenhuma das duas latências sob carga
/// (download/upload) está disponível. Mesmo espírito de
/// `UsageSuitability.SuitabilityLevel.notAssessed`: uma métrica ausente
/// nunca é tratada como zero, e nunca promove/rebaixa silenciosamente para
/// uma categoria fabricada.
public enum LoadResponsivenessCategory: String, Codable, Equatable, Sendable {
    case high
    case medium
    case low
    case notAssessed
}

/// Limiares que convertem "quanto a latência cresce sob carga, em %" em
/// `LoadResponsivenessCategory`. Reaproveita o `percentDelta` já calculado
/// por `MetricComparator` (a mesma fórmula usada por todo `MetricComparison`
/// deste pacote) — não introduz um segundo cálculo percentual.
///
/// Por que percentual e não delta absoluto em ms (a métrica clássica de
/// "grade de bufferbloat" tipo A/B/C/D/F): a issue #128 pede explicitamente
/// para reaproveitar a lógica de delta percentual já existente em
/// `NetworkInsights` (`MetricComparison`) em vez de inventar uma segunda
/// forma de medir mudança — então os limiares abaixo são deliberadamente
/// percentuais, não absolutos.
///
/// Os dois limiares abaixo são o parâmetro público desta decisão — nenhum
/// deles é usado como número mágico dentro da lógica de categorização,
/// ambos existem aqui por um motivo escrito:
///
/// - `highThresholdPercent` (25%): teto de crescimento de latência que
///   ainda soa "praticamente igual" a estar parado. Escolhido bem acima do
///   limiar de "estável" já usado para tendência histórica
///   (`NetworkInsightsConfiguration.stableChangeThresholdPercent`, default
///   3%) porque a latência sob carga tem ruído natural maior que uma leitura
///   parada isolada (ela compete de verdade com os streams de
///   download/upload) — um piso ~8x maior evita marcar como "degradada" uma
///   flutuação comum de rede saudável.
/// - `mediumThresholdPercent` (100%): a latência sob carga dobra ou mais em
///   relação à parada. Acima disso o sintoma já é inequívoco — a fila do
///   roteador está sendo monopolizada pela transferência concorrente, não é
///   mais "um pouco mais lento", é "a conexão fica de fato menos responsiva
///   enquanto algo grande transfere".
///
/// Entre os dois fica a faixa "média": perceptível, mas não necessariamente
/// grave (ex.: uma chamada de vídeo ainda funciona, com atraso notável).
public struct LoadResponsivenessThresholds: Equatable, Sendable {
    public var highThresholdPercent: Double
    public var mediumThresholdPercent: Double

    public init(
        highThresholdPercent: Double = 25,
        mediumThresholdPercent: Double = 100
    ) {
        self.highThresholdPercent = max(0, highThresholdPercent)
        self.mediumThresholdPercent = max(self.highThresholdPercent, mediumThresholdPercent)
    }
}

/// Resultado completo da avaliação de responsividade sob carga de uma
/// medição: a categoria e as duas comparações (parada-vs-carga) que a
/// sustentam, uma por direção. `downloadComparison`/`uploadComparison` nunca
/// são "ausentes" no sentido de Optional — seguem o mesmo padrão de
/// `MetricComparison.direction == .unavailable` já usado em todo o pacote
/// para representar "faltou dado", em vez de esconder a ausência atrás de
/// `nil` na struct inteira.
public struct LoadResponsivenessResult: Codable, Equatable, Sendable {
    public let category: LoadResponsivenessCategory
    public let downloadComparison: MetricComparison
    public let uploadComparison: MetricComparison

    public init(
        category: LoadResponsivenessCategory,
        downloadComparison: MetricComparison,
        uploadComparison: MetricComparison
    ) {
        self.category = category
        self.downloadComparison = downloadComparison
        self.uploadComparison = uploadComparison
    }
}

/// Categoriza a responsividade sob carga de uma medição a partir da latência
/// parada e da(s) latência(s) sob carga (download e/ou upload) — issue #128,
/// item 2 do aceite ("Existe uma categorização objetiva e testável").
///
/// Função pura e testável (mesmo espírito de `UsageSuitabilityEvaluator`):
/// não lança, não conhece copy de produto, não conhece UI. Recebe valores
/// já extraídos em vez de um `NetworkMeasurement` inteiro porque o chamador
/// mais natural (Detalhes, fora de escopo deste pacote) normalmente já tem
/// os três valores em mãos a partir de uma única medição — mas nada aqui
/// impede um `NetworkMeasurement` de ser a fonte desses três `Double?`.
public enum LoadResponsivenessEvaluator {
    /// - Parameters:
    ///   - idleLatencyMs: latência parada (`NetworkMeasurement.latencyMs`) —
    ///     é a referência ("baseline") das duas comparações.
    ///   - loadedDownloadLatencyMs: latência sob carga durante download
    ///     (`NetworkMeasurement.loadedLatencyMs`).
    ///   - loadedUploadLatencyMs: latência sob carga durante upload
    ///     (`NetworkMeasurement.loadedLatencyUploadMs`, issue #128).
    ///   - thresholds: limiares percentuais que decidem a categoria.
    /// - Returns: `.notAssessed` quando `idleLatencyMs` está ausente, ou
    ///   quando nenhuma das duas latências sob carga está disponível, ou
    ///   quando o `baseline` de todas as comparações disponíveis é `0`
    ///   (percentual indefinido — `MetricComparator` já devolve
    ///   `percentDelta == nil` nesse caso, e esta função nunca cai para
    ///   delta absoluto como substituto silencioso). Caso contrário, a pior
    ///   (maior) variação percentual entre download e upload decide a
    ///   categoria — um único sinal claro de bufferbloat em qualquer direção
    ///   já é o suficiente para revelar fila cheia no roteador, mesmo que a
    ///   outra direção esteja saudável.
    public static func evaluate(
        idleLatencyMs: Double?,
        loadedDownloadLatencyMs: Double?,
        loadedUploadLatencyMs: Double?,
        thresholds: LoadResponsivenessThresholds = .init()
    ) -> LoadResponsivenessResult {
        // `stableChangeThresholdPercent: thresholds.highThresholdPercent` faz
        // `MetricComparison.direction` concordar com a categoria: dentro do
        // teto de "alta responsividade" o crescimento de latência conta como
        // `.stable` (a mesma leitura de "praticamente igual a parado" que
        // justifica `.high` acima); além dele, `.worsened` acompanha
        // `.medium`/`.low`. Evita expor um `direction` que discorda da
        // `category` calculada a partir do mesmo delta.
        let downloadComparison = MetricComparator.compare(
            metric: .loadedLatencyMs,
            current: loadedDownloadLatencyMs,
            baseline: idleLatencyMs,
            stableChangeThresholdPercent: thresholds.highThresholdPercent
        )
        let uploadComparison = MetricComparator.compare(
            metric: .loadedLatencyUploadMs,
            current: loadedUploadLatencyMs,
            baseline: idleLatencyMs,
            stableChangeThresholdPercent: thresholds.highThresholdPercent
        )

        let measuredPercentDeltas = [downloadComparison, uploadComparison]
            .filter { $0.direction != .unavailable }
            .compactMap(\.percentDelta)

        guard let worstPercentDelta = measuredPercentDeltas.max() else {
            return LoadResponsivenessResult(
                category: .notAssessed,
                downloadComparison: downloadComparison,
                uploadComparison: uploadComparison
            )
        }

        // Só a piora (latência sob carga maior que parada) indica fila
        // cheia; uma latência sob carga menor que a parada (ruído/medição
        // mais favorável) nunca é tratada como sintoma — conta como "alta
        // responsividade", não como um crescimento negativo que abaixaria
        // artificialmente a categoria.
        let worstIncreasePercent = max(0, worstPercentDelta)

        let category: LoadResponsivenessCategory
        if worstIncreasePercent <= thresholds.highThresholdPercent {
            category = .high
        } else if worstIncreasePercent <= thresholds.mediumThresholdPercent {
            category = .medium
        } else {
            category = .low
        }

        return LoadResponsivenessResult(
            category: category,
            downloadComparison: downloadComparison,
            uploadComparison: uploadComparison
        )
    }
}
