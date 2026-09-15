import Foundation
import XCTest
@testable import NetworkProfiles

final class NetworkProfilesTests: XCTestCase {
    private let installationSecret = Data(repeating: 7, count: 32)

    func testIdentityRejectsMissingEmptyAndInvalidPersistedValues() {
        XCTAssertNil(NetworkProfileIdentity(ssid: nil, installationSecret: installationSecret))
        XCTAssertNil(NetworkProfileIdentity(ssid: " \n\t ", installationSecret: installationSecret))
        XCTAssertNil(NetworkProfileIdentity(ssid: "Casa", installationSecret: Data()))
        XCTAssertNil(NetworkProfileIdentity(version: 2, fingerprint: String(repeating: "a", count: 64)))
        XCTAssertNil(NetworkProfileIdentity(version: 1, fingerprint: "not-a-sha256"))
    }

    func testIdentityNormalizesUnicodeAndBoundaryWhitespaceWithoutCollapsingDistinctSSID() {
        let composed = NetworkProfileIdentity(ssid: " Café ", installationSecret: installationSecret)
        let decomposed = NetworkProfileIdentity(ssid: "Cafe\u{301}", installationSecret: installationSecret)
        let differentCase = NetworkProfileIdentity(ssid: "café", installationSecret: installationSecret)

        XCTAssertEqual(composed, decomposed)
        XCTAssertNotEqual(composed, differentCase)
        XCTAssertEqual(NetworkProfileIdentity.normalizedSSID("\n Casa Wi-Fi \t"), "Casa Wi-Fi")
    }

    func testFileRepositoryRoundTripsAndUpsertsByIdentity() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let identity = try XCTUnwrap(NetworkProfileIdentity(ssid: "Casa", installationSecret: installationSecret))
        let createdAt = Date(timeIntervalSince1970: 1_000)
        let first = try XCTUnwrap(NetworkProfile(
            id: UUID(uuidString: "40E6215D-B5C6-4896-987C-F30F3678F608")!,
            identity: identity,
            name: "Casa",
            createdAt: createdAt,
            updatedAt: createdAt
        ))
        let updated = try XCTUnwrap(NetworkProfile(
            id: UUID(uuidString: "40E6215D-B5C6-4896-987C-F30F3678F608")!,
            identity: identity,
            name: "Casa principal",
            createdAt: createdAt,
            updatedAt: createdAt.addingTimeInterval(10),
            lastAnalyzedAt: createdAt.addingTimeInterval(10)
        ))

        let writer = FileNetworkProfileRepository(fileURL: fileURL)
        try await writer.upsert(first)
        try await writer.upsert(updated)

        let reader = FileNetworkProfileRepository(fileURL: fileURL)
        let restoredProfiles = try await reader.profiles()
        let restoredProfile = try await reader.profile(for: identity)
        XCTAssertEqual(restoredProfiles, [updated])
        XCTAssertEqual(restoredProfile, updated)
    }

    func testRemovalPersistsAndMissingFileStartsEmpty() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let repository = FileNetworkProfileRepository(fileURL: fileURL)
        let identity = try XCTUnwrap(NetworkProfileIdentity(ssid: "Trabalho", installationSecret: installationSecret))
        let profile = try XCTUnwrap(NetworkProfile(identity: identity, name: "Trabalho"))

        let initiallyStored = try await repository.profiles()
        XCTAssertTrue(initiallyStored.isEmpty)
        try await repository.upsert(profile)
        try await repository.remove(identity: identity)

        let reader = FileNetworkProfileRepository(fileURL: fileURL)
        let restoredProfile = try await reader.profile(for: identity)
        let restoredProfiles = try await reader.profiles()
        XCTAssertNil(restoredProfile)
        XCTAssertTrue(restoredProfiles.isEmpty)
    }

    func testCorruptedAndUnknownVersionFilesFailClosed() async throws {
        let corruptedURL = temporaryFileURL()
        let versionURL = temporaryFileURL()
        defer {
            try? FileManager.default.removeItem(at: corruptedURL.deletingLastPathComponent())
            try? FileManager.default.removeItem(at: versionURL.deletingLastPathComponent())
        }
        try FileManager.default.createDirectory(at: corruptedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: versionURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not-json".utf8).write(to: corruptedURL)
        try Data("{\"schemaVersion\":99,\"profiles\":[]}".utf8).write(to: versionURL)

        do {
            _ = try await FileNetworkProfileRepository(fileURL: corruptedURL).profiles()
            XCTFail("Expected corruptedStore")
        } catch let error as NetworkProfileRepositoryError {
            XCTAssertEqual(error, .corruptedStore)
        }

        do {
            _ = try await FileNetworkProfileRepository(fileURL: versionURL).profiles()
            XCTFail("Expected unsupportedStoreVersion")
        } catch let error as NetworkProfileRepositoryError {
            XCTAssertEqual(error, .unsupportedStoreVersion(99))
        }
    }

    func testPersistedJSONNeverContainsClearSSID() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let ssid = "Segredo Wi-Fi da Casa"
        let identity = try XCTUnwrap(NetworkProfileIdentity(ssid: ssid, installationSecret: installationSecret))
        let profile = try XCTUnwrap(NetworkProfile(identity: identity, name: "Casa"))
        let repository = FileNetworkProfileRepository(fileURL: fileURL)

        try await repository.upsert(profile)

        let document = try String(decoding: Data(contentsOf: fileURL), as: UTF8.self)
        XCTAssertFalse(document.contains(ssid))
        XCTAssertTrue(document.contains(identity.fingerprint))
        XCTAssertFalse(document.contains("ssid"))
    }

    func testReferenceStartPersistsAcrossRepositoryInstances() async throws {
        let fileURL = temporaryFileURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let identity = try XCTUnwrap(NetworkProfileIdentity(ssid: "Casa", installationSecret: installationSecret))
        let createdAt = Date(timeIntervalSince1970: 2_000)
        let referenceStartedAt = createdAt.addingTimeInterval(30)
        let profile = try XCTUnwrap(NetworkProfile(
            identity: identity,
            name: "Casa",
            createdAt: createdAt,
            updatedAt: referenceStartedAt,
            referenceStartedAt: referenceStartedAt
        ))

        let writer = FileNetworkProfileRepository(fileURL: fileURL)
        try await writer.upsert(profile)

        let reader = FileNetworkProfileRepository(fileURL: fileURL)
        let restored = try await reader.profile(for: identity)
        XCTAssertEqual(restored?.referenceStartedAt, referenceStartedAt)
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("NetworkProfilesTests-\(UUID().uuidString)")
            .appendingPathComponent("profiles.json")
    }
}
