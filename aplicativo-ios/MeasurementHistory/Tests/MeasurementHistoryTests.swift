import Foundation
import XCTest
import NetworkCore
@testable import MeasurementHistory

final class MeasurementHistoryTests: XCTestCase {
    func testSaveIsIdempotentByMeasurementID() async throws {
        let id = UUID()
        let repository = InMemoryMeasurementHistoryRepository()

        try await repository.save(makeMeasurement(id: id, download: 100))
        try await repository.save(makeMeasurement(id: id, download: 200))

        let count = try await repository.totalCount()
        let stored = try await repository.measurement(id: id)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(stored?.downloadMbps, 200)
    }

    func testQueryFiltersSortsAndPaginates() async throws {
        let repository = InMemoryMeasurementHistoryRepository()
        let base = Date(timeIntervalSince1970: 1_000)

        try await repository.save(makeMeasurement(
            measuredAt: base,
            download: 100,
            connectionKind: .wifi
        ))
        try await repository.save(makeMeasurement(
            measuredAt: base.addingTimeInterval(100),
            download: 200,
            connectionKind: .cellular
        ))
        try await repository.save(makeMeasurement(
            measuredAt: base.addingTimeInterval(200),
            download: 300,
            connectionKind: .wifi
        ))

        let query = MeasurementQuery(
            measuredFrom: base,
            connectionKinds: [.wifi],
            offset: 1,
            limit: 1,
            sortOrder: .newestFirst
        )
        let result = try await repository.measurements(matching: query)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.downloadMbps, 100)
    }

    func testRetentionKeepsNewestEntries() async throws {
        let repository = InMemoryMeasurementHistoryRepository(
            retentionPolicy: HistoryRetentionPolicy(maximumEntries: 2)
        )
        let base = Date()

        try await repository.save(makeMeasurement(
            measuredAt: base.addingTimeInterval(-200),
            download: 100
        ))
        try await repository.save(makeMeasurement(
            measuredAt: base.addingTimeInterval(-100),
            download: 200
        ))
        try await repository.save(makeMeasurement(
            measuredAt: base,
            download: 300
        ))

        let result = try await repository.measurements(matching: .all)
        XCTAssertEqual(result.map(\.downloadMbps), [300, 200])
    }

    func testInvalidMeasurementIsRejected() async {
        let repository = InMemoryMeasurementHistoryRepository()
        let invalid = NetworkMeasurement(downloadMbps: -10)

        do {
            try await repository.save(invalid)
            XCTFail("Expected invalidMeasurement")
        } catch let error as MeasurementHistoryError {
            guard case .invalidMeasurement(let violations) = error else {
                XCTFail("Unexpected history error: \(error)")
                return
            }
            XCTAssertTrue(violations.contains("downloadMbps"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFileRepositoryPersistsAcrossInstances() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let measurement = makeMeasurement(download: 512)
        let writer = FileMeasurementHistoryRepository(fileURL: fileURL)
        try await writer.save(measurement)

        let reader = FileMeasurementHistoryRepository(fileURL: fileURL)
        let restored = try await reader.measurement(id: measurement.id)

        XCTAssertEqual(restored, measurement)
    }

    func testFileRepositoryPersistsDeletion() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let measurement = makeMeasurement(download: 512)
        let writer = FileMeasurementHistoryRepository(fileURL: fileURL)
        try await writer.save(measurement)
        try await writer.delete(id: measurement.id)

        let reader = FileMeasurementHistoryRepository(fileURL: fileURL)
        let restored = try await reader.measurement(id: measurement.id)
        let count = try await reader.totalCount()
        XCTAssertNil(restored)
        XCTAssertEqual(count, 0)
    }

    func testCorruptedFileFailsClosed() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(to: fileURL)

        let repository = FileMeasurementHistoryRepository(fileURL: fileURL)

        do {
            _ = try await repository.totalCount()
            XCTFail("Expected corruptedStore")
        } catch let error as MeasurementHistoryError {
            XCTAssertEqual(error, .corruptedStore)
        }
    }

    func testUnsupportedStoreVersionFailsClosed() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = Data("{\"schemaVersion\":99,\"measurements\":[]}".utf8)
        try data.write(to: fileURL)

        let repository = FileMeasurementHistoryRepository(fileURL: fileURL)

        do {
            _ = try await repository.totalCount()
            XCTFail("Expected unsupportedStoreVersion")
        } catch let error as MeasurementHistoryError {
            XCTAssertEqual(error, .unsupportedStoreVersion(99))
        }
    }

    private func makeMeasurement(
        id: UUID = UUID(),
        measuredAt: Date = Date(),
        download: Double = 100,
        connectionKind: NetworkConnectionKind? = .wifi
    ) -> NetworkMeasurement {
        NetworkMeasurement(
            id: id,
            measuredAt: measuredAt,
            outcome: .complete,
            downloadMbps: download,
            uploadMbps: 50,
            latencyMs: 15,
            connectionKind: connectionKind
        )
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("measurement-history-tests")
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("history.json")
    }
}
