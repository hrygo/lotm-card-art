import Foundation
import XCTest
@testable import WorldOfMysteriesCore

final class SpeechRailConfigurationFileTests: XCTestCase {
    func testMissingConfigurationReportsMissingWithoutPrompting() {
        let store = makeStore()

        XCTAssertEqual(store.state(), .missing)
    }

    func testSaveConfigurationTrimsAndUsesPrivateFilePermissions() throws {
        let store = makeStore()

        try store.saveAPIKey("  file-test-key\n")

        XCTAssertEqual(try store.readAPIKey(), "file-test-key")
        let attributes = try FileManager.default.attributesOfItem(atPath: store.fileURL.path)
        let permissions = try XCTUnwrap((attributes[.posixPermissions] as? NSNumber)?.intValue)
        XCTAssertEqual(permissions & 0o777, 0o600)
    }

    func testEmptyConfigurationIsRejectedWithoutCreatingASecretFile() {
        let store = makeStore()

        XCTAssertThrowsError(try store.saveAPIKey(" \n\t ")) { error in
            XCTAssertEqual(error as? SpeechRailConfigurationFileError, .invalidData)
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    func testInvalidJSONReportsUnavailable() throws {
        let store = makeStore()
        try FileManager.default.createDirectory(
            at: store.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(to: store.fileURL)

        XCTAssertEqual(store.state(), .unavailable)
        XCTAssertThrowsError(try store.readAPIKey()) { error in
            XCTAssertEqual(error as? SpeechRailConfigurationFileError, .invalidData)
        }
    }

    func testReadFallsBackToPredecessorFileWhenCurrentFileIsMissing() throws {
        let (store, predecessorURL) = makeStoreWithPredecessor()
        try writeAPIKey("predecessor-file-key", to: predecessorURL)

        XCTAssertEqual(store.state(), .configured)
        XCTAssertEqual(try store.readAPIKey(), "predecessor-file-key")
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    func testCurrentFileWinsOverPredecessorFile() throws {
        let (store, predecessorURL) = makeStoreWithPredecessor()
        try writeAPIKey("predecessor-file-key", to: predecessorURL)

        try store.saveAPIKey("current-file-key")

        XCTAssertEqual(try store.readAPIKey(), "current-file-key")
    }

    func testSavingLeavesThePredecessorFileUntouched() throws {
        let (store, predecessorURL) = makeStoreWithPredecessor()
        try writeAPIKey("predecessor-file-key", to: predecessorURL)

        try store.saveAPIKey("current-file-key")

        XCTAssertEqual(try storedAPIKey(at: predecessorURL), "predecessor-file-key")
    }

    func testInvalidPredecessorFileReportsUnavailableInsteadOfMissing() throws {
        let (store, predecessorURL) = makeStoreWithPredecessor()
        try FileManager.default.createDirectory(
            at: predecessorURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not-json".utf8).write(to: predecessorURL)

        XCTAssertEqual(store.state(), .unavailable)
    }

    private func makeStore() -> SpeechRailConfigurationFileStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorldOfMysteriesTests-\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("SpeechRail.json")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return SpeechRailConfigurationFileStore(fileURL: fileURL, fallbackFileURL: nil)
    }

    private func makeStoreWithPredecessor() -> (SpeechRailConfigurationFileStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorldOfMysteriesTests-\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("current/SpeechRail.json")
        let predecessorURL = directory.appendingPathComponent("predecessor/SpeechRail.json")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return (
            SpeechRailConfigurationFileStore(fileURL: fileURL, fallbackFileURL: predecessorURL),
            predecessorURL
        )
    }

    private func writeAPIKey(_ value: String, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("{\"apiKey\":\"\(value)\"}".utf8).write(to: url)
    }

    private func storedAPIKey(at url: URL) throws -> String {
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        return (object as? [String: String])?["apiKey"] ?? ""
    }
}
