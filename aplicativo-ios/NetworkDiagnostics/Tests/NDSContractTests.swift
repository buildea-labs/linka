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
              "result": {},
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
            },
            {
              "module": "scoring",
              "result": {
                "score": 85,
                "veredicto": "bom",
                "observed_dimensions": 2
              }
            },
            {
              "module": "ai",
              "result": {
                "explanation": {
                  "titulo_amigavel": "Tudo certo",
                  "resumo_tecnico_traduzido": "Sua conexão está boa."
                }
              }
            }
          ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(NDSResponse.self, from: json)
        
        XCTAssertEqual(response.recommendation?.id, "REC_WIFI_FAR")
        XCTAssertEqual(response.results?.first(where: { $0.module == "scoring" })?.result?.score, 85)
        XCTAssertEqual(response.results?.first(where: { $0.module == "scoring" })?.result?.veredicto, "bom")
        XCTAssertEqual(response.results?.first(where: { $0.module == "diagnostics.wifi" })?.cards?.first?.mensagemUsuario, "Latência elevada")
    }
}
