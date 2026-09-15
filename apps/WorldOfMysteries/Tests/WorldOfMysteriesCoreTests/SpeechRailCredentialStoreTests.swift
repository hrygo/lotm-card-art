import Foundation
import XCTest
@testable import WorldOfMysteriesCore

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

    func testStateReportsLegacyWhenOnlyPredecessorLegacyItemExists() {
        let keychain = InMemoryKeychainAccess(predecessorLegacyData: Data("old-key".utf8))
        let store = SpeechRailCredentialStore(keychain: keychain)

        XCTAssertEqual(store.state(), .legacy)
    }

    func testStateReportsProtectedWhenOnlyPredecessorProtectedItemExists() {
        let keychain = InMemoryKeychainAccess(predecessorProtectedData: Data("old-key".utf8))
        let store = SpeechRailCredentialStore(keychain: keychain)

        XCTAssertEqual(store.state(), .protected)
    }

    func testCurrentServiceWinsOverPredecessorService() {
        let keychain = InMemoryKeychainAccess(
            legacyData: Data("current-key".utf8),
            predecessorLegacyData: Data("old-key".utf8)
        )
        let store = SpeechRailCredentialStore(keychain: keychain)

        XCTAssertEqual(store.state(), .legacy)
        XCTAssertEqual(keychain.readServices, [])
    }

    func testReadPreferredReadsPredecessorServiceOnlyWhenRenamedServicesAreEmpty() async throws {
        let keychain = InMemoryKeychainAccess(predecessorLegacyData: Data("old-key".utf8))
        let store = SpeechRailCredentialStore(keychain: keychain)

        let apiKey = try await store.readPreferredAPIKey()

        XCTAssertEqual(apiKey, "old-key")
        XCTAssertEqual(
            keychain.readServices,
            [SpeechRailCredentialStore.predecessorLegacyService]
        )
    }

    func testMigrationReadsPredecessorLegacyItemWhenRenamedLegacyItemIsMissing() async throws {
        let keychain = InMemoryKeychainAccess(predecessorLegacyData: Data("old-key".utf8))
        let store = SpeechRailCredentialStore(keychain: keychain)

        try await store.migrateLegacyToProtected()

        XCTAssertEqual(keychain.protectedData, Data("old-key".utf8))
        XCTAssertEqual(
            keychain.events,
            [
                "read:\(SpeechRailCredentialStore.predecessorLegacyService)",
                "write:\(SpeechRailCredentialStore.protectedService)",
                "read:\(SpeechRailCredentialStore.protectedService)"
            ]
        )
    }

    func testWritesNeverTargetPredecessorServices() async throws {
        let keychain = InMemoryKeychainAccess()
        let store = SpeechRailCredentialStore(keychain: keychain)

        try await store.saveProtectedAPIKey("test-key")

        XCTAssertNil(keychain.predecessorProtectedData)
        XCTAssertNil(keychain.predecessorLegacyData)
        XCTAssertTrue(
            keychain.events.allSatisfy { !$0.contains("com.lotm.cardstudio") },
            "旧服务名不得成为写入目标：\(keychain.events)"
        )
    }
}

private final class InMemoryKeychainAccess: KeychainAccessing, @unchecked Sendable {
    var legacyData: Data?
    var protectedData: Data?
    var predecessorLegacyData: Data?
    var predecessorProtectedData: Data?
    let legacyReadError: Error?
    let protectedReadError: Error?
    let writeError: Error?
    private(set) var readServices: [String] = []
    private(set) var events: [String] = []

    init(
        legacyData: Data? = nil,
        protectedData: Data? = nil,
        predecessorLegacyData: Data? = nil,
        predecessorProtectedData: Data? = nil,
        legacyReadError: Error? = nil,
        protectedReadError: Error? = nil,
        writeError: Error? = nil
    ) {
        self.legacyData = legacyData
        self.protectedData = protectedData
        self.predecessorLegacyData = predecessorLegacyData
        self.predecessorProtectedData = predecessorProtectedData
        self.legacyReadError = legacyReadError
        self.protectedReadError = protectedReadError
        self.writeError = writeError
    }

    func itemState(service: String, account: String) -> KeychainItemState {
        storedData(for: service) == nil ? .missing : .present
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

        guard let data = storedData(for: service) else {
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

        switch service {
        case SpeechRailCredentialStore.protectedService:
            protectedData = data
        case SpeechRailCredentialStore.legacyService:
            legacyData = data
        case SpeechRailCredentialStore.predecessorProtectedService:
            predecessorProtectedData = data
        case SpeechRailCredentialStore.predecessorLegacyService:
            predecessorLegacyData = data
        default:
            break
        }
    }

    private func storedData(for service: String) -> Data? {
        switch service {
        case SpeechRailCredentialStore.protectedService:
            return protectedData
        case SpeechRailCredentialStore.legacyService:
            return legacyData
        case SpeechRailCredentialStore.predecessorProtectedService:
            return predecessorProtectedData
        case SpeechRailCredentialStore.predecessorLegacyService:
            return predecessorLegacyData
        default:
            return nil
        }
    }
}
