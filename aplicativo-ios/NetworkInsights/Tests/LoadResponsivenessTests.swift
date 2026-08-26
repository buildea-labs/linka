import XCTest
import NetworkCore
@testable import NetworkInsights

/// Cobre `LoadResponsivenessEvaluator` (issue #128): categorização objetiva
/// de responsividade sob carga a partir do delta percentual entre latência
/// parada e latência sob carga (download/upload). Função pura — sem rede,
/// sem `Date()` ao vivo — mesmo espírito de `UsageSuitabilityTests`.
final class LoadResponsivenessTests: XCTestCase {

    // MARK: - Categorias com limiares padrão (high 25% / medium 100%)

    func testSmallIncreaseIsHighResponsiveness() {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 20,
            loadedDownloadLatencyMs: 24, // +20%
            loadedUploadLatencyMs: 22    // +10%
        )

        XCTAssertEqual(result.category, .high)
        XCTAssertEqual(result.downloadComparison.direction, .stable)
        XCTAssertEqual(result.uploadComparison.direction, .stable)
    }

    func testHighThresholdIsInclusiveAtTheBoundary() {
        // Exatamente 25% de crescimento — limiar documentado como inclusivo
        // ("até highThresholdPercent") em `LoadResponsivenessThresholds`.
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 20,
            loadedDownloadLatencyMs: 25, // exatamente +25%
            loadedUploadLatencyMs: nil
        )

        XCTAssertEqual(result.category, .high)
    }

    func testModerateIncreaseIsMediumResponsiveness() {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 20,
            loadedDownloadLatencyMs: 30, // +50%
            loadedUploadLatencyMs: nil
        )

        XCTAssertEqual(result.category, .medium)
        XCTAssertEqual(result.downloadComparison.direction, .worsened)
    }

    func testLargeIncreaseIsLowResponsiveness() {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 20,
            loadedDownloadLatencyMs: nil,
            loadedUploadLatencyMs: 50 // +150%
        )

        XCTAssertEqual(result.category, .low)
        XCTAssertEqual(result.uploadComparison.direction, .worsened)
    }

    // MARK: - Pior direção decide a categoria

    func testWorstOfDownloadAndUploadDecidesCategory() {
        // Download quase inalterado (+10%, alta responsividade sozinho);
        // upload degrada muito (+150%, baixa responsividade sozinho). Um
        // sintoma claro de bufferbloat em qualquer direção já é suficiente —
        // a categoria final acompanha a pior das duas.
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 20,
            loadedDownloadLatencyMs: 22,
            loadedUploadLatencyMs: 50
        )

        XCTAssertEqual(result.category, .low)
    }

    // MARK: - Estado explícito "não avaliado"

    func testMissingIdleLatencyIsNotAssessedEvenWithBothLoadedValues() {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: nil,
            loadedDownloadLatencyMs: 30,
            loadedUploadLatencyMs: 40
        )

        XCTAssertEqual(result.category, .notAssessed)
        XCTAssertEqual(result.downloadComparison.direction, .unavailable)
        XCTAssertEqual(result.uploadComparison.direction, .unavailable)
    }

    func testMissingBothLoadedLatenciesIsNotAssessedEvenWithIdlePresent() {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 20,
            loadedDownloadLatencyMs: nil,
            loadedUploadLatencyMs: nil
        )

        XCTAssertEqual(result.category, .notAssessed)
    }

    /// Latência parada de 0 é um caso degenerado (não deveria ocorrer numa
    /// medição real, mas não pode ser tratado com ginástica): o percentual
    /// de mudança é indefinido (`MetricComparator` já devolve `percentDelta
    /// == nil` quando `baseline == 0`), então a categorização nunca cai para
    /// um cálculo alternativo silencioso — vira "não avaliado".
    func testZeroBaselineNeverFabricatesACategory() {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 0,
            loadedDownloadLatencyMs: 10,
            loadedUploadLatencyMs: nil
        )

        XCTAssertEqual(result.category, .notAssessed)
        XCTAssertNil(result.downloadComparison.percentDelta)
    }

    // MARK: - Uma única direção disponível

    func testAssessesFromDownloadAloneWhenUploadIsMissing() {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 40,
            loadedDownloadLatencyMs: 90, // +125%
            loadedUploadLatencyMs: nil
        )

        XCTAssertEqual(result.category, .low)
        XCTAssertEqual(result.uploadComparison.direction, .unavailable)
    }

    func testAssessesFromUploadAloneWhenDownloadIsMissing() {
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 40,
            loadedDownloadLatencyMs: nil,
            loadedUploadLatencyMs: 44 // +10%
        )

        XCTAssertEqual(result.category, .high)
        XCTAssertEqual(result.downloadComparison.direction, .unavailable)
    }

    // MARK: - Latência sob carga menor que a parada (ruído favorável)

    func testLoadedLatencyLowerThanIdleNeverLowersCategory() {
        // Sob carga saiu mais rápida que parada (ruído de medição) — não é
        // um sintoma de bufferbloat, então não deve rebaixar a categoria
        // para "melhor que alta" (não existe tal categoria) nem para
        // qualquer outra coisa fabricada a partir de um delta negativo.
        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 50,
            loadedDownloadLatencyMs: 30, // -40%
            loadedUploadLatencyMs: nil
        )

        XCTAssertEqual(result.category, .high)
        XCTAssertEqual(result.downloadComparison.direction, .improved)
    }

    // MARK: - Limiares customizados

    func testCustomThresholdsChangeCategoryBoundaries() {
        let thresholds = LoadResponsivenessThresholds(
            highThresholdPercent: 10,
            mediumThresholdPercent: 50
        )

        let result = LoadResponsivenessEvaluator.evaluate(
            idleLatencyMs: 20,
            loadedDownloadLatencyMs: 23, // +15%: seria "high" no padrão (25%), mas não com highThresholdPercent: 10
            loadedUploadLatencyMs: nil,
            thresholds: thresholds
        )

        XCTAssertEqual(result.category, .medium)
    }

    func testThresholdsClampMediumToAtLeastHigh() {
        // `mediumThresholdPercent` nunca pode ficar abaixo de
        // `highThresholdPercent` — faria uma faixa "medium" invertida/vazia.
        let thresholds = LoadResponsivenessThresholds(
            highThresholdPercent: 50,
            mediumThresholdPercent: 20
        )

        XCTAssertEqual(thresholds.mediumThresholdPercent, 50)
    }
}
