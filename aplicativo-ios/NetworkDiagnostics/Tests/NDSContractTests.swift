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
              "module": "wifi",
              "result": {
                "score": 85,
                "findings": [
                  {
                    "type": "latency",
                    "severity": "high",
                    "value": 150.0,
                    "message": "Latência elevada"
                  }
                ]
              }
            }
          ]
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(NDSResponse.self, from: json)
        
        XCTAssertEqual(response.recommendation?.id, "REC_WIFI_FAR")
        XCTAssertEqual(response.results?.first?.result?.score, 85)
        XCTAssertEqual(response.results?.first?.result?.findings?.first?.message, "Latência elevada")
    }
}
