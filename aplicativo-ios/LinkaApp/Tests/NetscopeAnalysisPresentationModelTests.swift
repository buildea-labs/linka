import XCTest
@testable import LinkaApp

@MainActor
final class NetscopeAnalysisPresentationModelTests: XCTestCase {
    func test_disabledReaderFailsClosedAsUnavailable() async {
        let model = NetscopeAnalysisPresentationModel()

        await model.load()

        XCTAssertEqual(model.state, .reading(.unavailable))
    }

    func test_injectedReaderPresentsEveryContractState() async {
        let readings: [NetscopeAnalysisReading] = [
            .completed(NetscopeAnalysisPresentation(
                summary: "Apenas uma fixture de apresentação.",
                observedEvidence: [],
                limitations: [],
                declaredContext: []
            )),
            .inconclusive,
            .unavailable,
            .rateLimited,
            .outOfScope
        ]

        for reading in readings {
            let model = NetscopeAnalysisPresentationModel(
                reader: StaticReader(reading: reading),
                input: .empty
            )

            await model.load()

            XCTAssertEqual(model.state, .reading(reading))
        }
    }

    func test_wifiDetailsAreOmittedUnlessTheObservedRouteIsWifi() {
        let details = NetscopeObservedEvidence.WiFiDetails(
            frequencyMHz: 5_180,
            band: "5ghz",
            channel: 36,
            linkSpeedMbps: 866
        )

        let cellular = NetscopeObservedEvidence(connectionKind: .cellular, wifiDetails: details)
        let wifi = NetscopeObservedEvidence(connectionKind: .wifi, wifiDetails: details)

        XCTAssertNil(cellular.wifiDetails)
        XCTAssertEqual(wifi.wifiDetails, details)
        XCTAssertEqual(wifi.wifiDetails?.frequencyMHz, 5_180)
    }

    func test_declaredContextIsASeparateInputFromObservedEvidence() {
        let evidence = NetscopeObservedEvidence(connectionKind: .ethernet, wifiDetails: nil)
        let context = NetscopeDeclaredContext(objective: .gaming)
        let input = NetscopeAnalysisInput(observedEvidence: evidence, declaredContext: context)

        XCTAssertEqual(input.observedEvidence.connectionKind, .ethernet)
        XCTAssertEqual(input.declaredContext.objective, .gaming)
        XCTAssertNil(input.observedEvidence.wifiDetails)
    }

    func test_completedReadingCarriesObservedEvidenceLimitsAndContextSeparately() {
        let presentation = NetscopeAnalysisPresentation(
            summary: "A leitura usa a evidência disponível.",
            observedEvidence: [NetscopePresentationItem(label: "Latência", value: "24 ms")],
            limitations: ["Jitter não foi medido."],
            declaredContext: [NetscopePresentationItem(label: "Objetivo", value: "Jogos")]
        )

        XCTAssertEqual(presentation.observedEvidence.map(\.label), ["Latência"])
        XCTAssertEqual(presentation.limitations, ["Jitter não foi medido."])
        XCTAssertEqual(presentation.declaredContext.map(\.label), ["Objetivo"])
    }

    func test_completedReadingUsesNeutralReadIconRatherThanHealthVerdict() {
        let reading = NetscopeAnalysisReading.completed(NetscopeAnalysisPresentation(
            summary: "Leitura recebida.",
            observedEvidence: [],
            limitations: [],
            declaredContext: []
        ))

        XCTAssertEqual(NetscopeReadingCopy(reading: reading).symbol, "text.magnifyingglass")
    }

    func test_missingPresentationDataIsNotDisplayable() {
        let presentation = NetscopeAnalysisPresentation(
            summary: "Sem dados adicionais.",
            observedEvidence: [
                NetscopePresentationItem(label: "", value: "24 ms"),
                NetscopePresentationItem(label: "Latência", value: " ")
            ],
            limitations: ["", "  "],
            declaredContext: [NetscopePresentationItem(label: "Objetivo", value: "")]
        )

        XCTAssertTrue(presentation.displayableObservedEvidence.isEmpty)
        XCTAssertTrue(presentation.displayableLimitations.isEmpty)
        XCTAssertTrue(presentation.displayableDeclaredContext.isEmpty)
    }

    func test_longPresentationKeepsEveryDisplayableSectionItemForScrollableView() {
        let evidence = (0..<24).map {
            NetscopePresentationItem(label: "Métrica \($0)", value: "\($0) ms")
        }
        let limitations = (0..<12).map { "Limitação \($0)" }
        let context = (0..<8).map {
            NetscopePresentationItem(label: "Contexto \($0)", value: "Informado")
        }
        let presentation = NetscopeAnalysisPresentation(
            summary: "Leitura recebida.",
            observedEvidence: evidence,
            limitations: limitations,
            declaredContext: context
        )

        XCTAssertEqual(presentation.displayableObservedEvidence, evidence)
        XCTAssertEqual(presentation.displayableLimitations, limitations)
        XCTAssertEqual(presentation.displayableDeclaredContext, context)
    }

    func test_retryReloadsTheSameReaderAndInputWithoutStartingMeasurement() async {
        let input = NetscopeAnalysisInput(
            observedEvidence: NetscopeObservedEvidence(connectionKind: .unknown, wifiDetails: nil),
            declaredContext: .absent
        )
        let reader = CountingReader()
        let model = NetscopeAnalysisPresentationModel(reader: reader, input: input)

        await model.load()
        await model.load()

        let received = await reader.inputs()
        XCTAssertEqual(received, [input, input])
        XCTAssertEqual(model.state, .reading(.unavailable))
    }
}

private struct StaticReader: NetscopeAnalysisReadingProviding {
    let reading: NetscopeAnalysisReading

    func read(_ input: NetscopeAnalysisInput) async -> NetscopeAnalysisReading {
        reading
    }
}

private actor CountingReader: NetscopeAnalysisReadingProviding {
    private var receivedInputs: [NetscopeAnalysisInput] = []

    func read(_ input: NetscopeAnalysisInput) async -> NetscopeAnalysisReading {
        receivedInputs.append(input)
        return .unavailable
    }

    func inputs() -> [NetscopeAnalysisInput] {
        receivedInputs
    }
}
