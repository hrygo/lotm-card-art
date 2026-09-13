import Foundation
import XCTest
@testable import LotmCardStudioCore

final class SpeechRailCredentialStoreTests: XCTestCase {
    func testStatePrefersProtectedItemOverLegacyItem() {
        let keychain = InMemoryKeychainAccess(
            legacyData: Data("legacy-key".utf8),
            protectedData: Data("protected-key".utf8)
        )
        let store = SpeechRailCredentialStore(keychain: keychain)

        XCTAssertEqual(store.state(), .protected)
    }

    func testStateReportsLegacyWhenOnlyLegacyItemExists() {
        let keychain = InMemoryKeychainAccess(legacyData: Data("legacy-key".utf8))
        let store = SpeechRailCredentialStore(keychain: keychain)

        XCTAssertEqual(store.state(), .legacy)
    }

    func testStateReportsMissingWhenNoItemExists() {
        let store = SpeechRailCredentialStore(keychain: InMemoryKeychainAccess())

        XCTAssertEqual(store.state(), .missing)
    }

    func testReadPreferredDoesNotFallbackAfterProtectedAuthenticationFailure() async {
        let keychain = InMemoryKeychainAccess(
            legacyData: Data("legacy-key".utf8),
            protectedData: Data("protected-key".utf8),
            protectedReadError: SpeechRailCredentialError.authenticationFailed
        )
        let store = SpeechRailCredentialStore(keychain: keychain)

        do {
            _ = try await store.readPreferredAPIKey()
            XCTFail("Expected the protected authentication failure to be returned")
        } catch let error as SpeechRailCredentialError {
            XCTAssertEqual(error, .authenticationFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertEqual(keychain.readServices, [SpeechRailCredentialStore.protectedService])
    }

    func testSaveProtectedAPIKeyTrimsInputAndVerifiesProtectedRead() async throws {
        let keychain = InMemoryKeychainAccess()
        let store = SpeechRailCredentialStore(keychain: keychain)

        try await store.saveProtectedAPIKey("  test-key\n")

        XCTAssertEqual(keychain.protectedData, Data("test-key".utf8))
        XCTAssertEqual(
            keychain.events,
            [
                "write:\(SpeechRailCredentialStore.protectedService)",
                "read:\(SpeechRailCredentialStore.protectedService)"
            ]
        )
    }

    func testMigrationWritesProtectedItemBeforeVerificationAndKeepsLegacyItem() async throws {
        let keychain = InMemoryKeychainAccess(legacyData: Data("legacy-key".utf8))
        let store = SpeechRailCredentialStore(keychain: keychain)

        try await store.migrateLegacyToProtected()

        XCTAssertEqual(keychain.legacyData, Data("legacy-key".utf8))
        XCTAssertEqual(keychain.protectedData, Data("legacy-key".utf8))
        XCTAssertEqual(
            keychain.events,
            [
                "read:\(SpeechRailCredentialStore.legacyService)",
                "write:\(SpeechRailCredentialStore.protectedService)",
                "read:\(SpeechRailCredentialStore.protectedService)"
            ]
        )
    }

    func testEmptyAPIKeyIsRejectedWithoutWriting() async {
        let keychain = InMemoryKeychainAccess()
        let store = SpeechRailCredentialStore(keychain: keychain)

        do {
            try await store.saveProtectedAPIKey(" \n\t ")
            XCTFail("Expected empty input to be rejected")
        } catch let error as SpeechRailCredentialError {
            XCTAssertEqual(error, .invalidData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertTrue(keychain.events.isEmpty)
        XCTAssertNil(keychain.protectedData)
    }
}

private final class InMemoryKeychainAccess: KeychainAccessing, @unchecked Sendable {
    var legacyData: Data?
    var protectedData: Data?
    let legacyReadError: Error?
    let protectedReadError: Error?
    let writeError: Error?
    private(set) var readServices: [String] = []
    private(set) var events: [String] = []

    init(
        legacyData: Data? = nil,
        protectedData: Data? = nil,
        legacyReadError: Error? = nil,
        protectedReadError: Error? = nil,
        writeError: Error? = nil
    ) {
        self.legacyData = legacyData
        self.protectedData = protectedData
        self.legacyReadError = legacyReadError
        self.protectedReadError = protectedReadError
        self.writeError = writeError
    }

    func itemState(service: String, account: String) -> KeychainItemState {
        switch service {
        case SpeechRailCredentialStore.legacyService:
            return legacyData == nil ? .missing : .present
        case SpeechRailCredentialStore.protectedService:
            return protectedData == nil ? .missing : .present
        default:
            return .missing
        }
    }

    func read(
        service: String,
        account: String,
        protection: KeychainProtection
    ) async throws -> Data {
        readServices.append(service)
        events.append("read:\(service)")

        if service == SpeechRailCredentialStore.legacyService, let legacyReadError {
            throw legacyReadError
        }
        if service == SpeechRailCredentialStore.protectedService, let protectedReadError {
            throw protectedReadError
        }

        guard let data = service == SpeechRailCredentialStore.protectedService
            ? protectedData
            : legacyData
        else {
            throw SpeechRailCredentialError.missing
        }
        return data
    }

    func write(
        _ data: Data,
        service: String,
        account: String,
        protection: KeychainProtection
    ) throws {
        events.append("write:\(service)")
        if let writeError {
            throw writeError
        }
        if service == SpeechRailCredentialStore.protectedService {
            protectedData = data
        } else {
            legacyData = data
        }
    }
}
