import Foundation
import XCTest
@testable import LotmCardStudioCore

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

    private func makeStore() -> SpeechRailConfigurationFileStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LotmCardStudioTests-\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("SpeechRail.json")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return SpeechRailConfigurationFileStore(fileURL: fileURL)
    }
}
