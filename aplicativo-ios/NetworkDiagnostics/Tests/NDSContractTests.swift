import XCTest
@testable import NetworkDiagnostics

final class NDSContractTests: XCTestCase {
    func testDecodeNDSResponse() throws {
        let json = """
        {
          "recommendation": {
            "id": "REC_WIFI_FAR",
            "type": "wifi_issue",
            "title": "Sinal Wi-Fi fraco",
            "description": "Aproxime-se do roteador..."
          },
          "results": [
            {
              "module": "diagnostics.wifi",
              "result": {
                "score": 85
              },
              "cards": [
                {
                  "id": "wifi_far",
                  "titulo": "Sinal Fraco",
                  "status": "attention",
                  "evidencia": null,
                  "mensagemUsuario": "Latência elevada",
                  "recomendacao": null,
                  "categoria": "wifi",
                  "podeConcluir": false,
                  "categoriaOrigem": null
                }
              ]
            }
          ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(NDSResponse.self, from: json)
        
        XCTAssertEqual(response.recommendation?.id, "REC_WIFI_FAR")
        XCTAssertEqual(response.results?.first?.result?.score, 85)
        XCTAssertEqual(response.results?.first?.cards?.first?.mensagemUsuario, "Latência elevada")
    }
}
