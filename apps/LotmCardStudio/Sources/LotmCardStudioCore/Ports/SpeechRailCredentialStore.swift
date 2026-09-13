import Foundation
import LocalAuthentication
import Security

public enum KeychainProtection: Equatable, Sendable {
    case legacy
    case userPresence
}

public enum KeychainItemState: Equatable, Sendable {
    case present
    case missing
    case inaccessible
}

public enum SpeechRailCredentialState: Equatable, Sendable {
    case protected
    case legacy
    case missing
    case unavailable
}

public enum SpeechRailCredentialError: Error, Equatable, Sendable {
    case missing
    case unavailable
    case authenticationCancelled
    case authenticationFailed
    case invalidData
    case writeFailed
    case verificationFailed
}

public protocol KeychainAccessing: Sendable {
    func itemState(service: String, account: String) -> KeychainItemState
    func read(
        service: String,
        account: String,
        protection: KeychainProtection
    ) async throws -> Data
    func write(
        _ data: Data,
        service: String,
        account: String,
        protection: KeychainProtection
    ) throws
}

public final class SpeechRailCredentialStore: @unchecked Sendable {
    public static let shared = SpeechRailCredentialStore()
    public static let legacyService = "com.lotm.cardstudio.speechrail"
    public static let protectedService = "com.lotm.cardstudio.speechrail.touchid"
    public static let account = "api-key"

    private let keychain: any KeychainAccessing

    public init(keychain: any KeychainAccessing = SystemKeychainAccess()) {
        self.keychain = keychain
    }

    public func state() -> SpeechRailCredentialState {
        switch keychain.itemState(service: Self.protectedService, account: Self.account) {
        case .present:
            return .protected
        case .inaccessible:
            return .unavailable
        case .missing:
            break
        }

        switch keychain.itemState(service: Self.legacyService, account: Self.account) {
        case .present:
            return .legacy
        case .missing:
            return .missing
        case .inaccessible:
            return .unavailable
        }
    }

    public func readPreferredAPIKey() async throws -> String {
        let source: (service: String, protection: KeychainProtection)
        switch state() {
        case .protected:
            source = (Self.protectedService, .userPresence)
        case .legacy:
            source = (Self.legacyService, .legacy)
        case .missing:
            throw SpeechRailCredentialError.missing
        case .unavailable:
            throw SpeechRailCredentialError.unavailable
        }

        let data = try await keychain.read(
            service: source.service,
            account: Self.account,
            protection: source.protection
        )
        return try Self.decodeAPIKey(data)
    }

    public func saveProtectedAPIKey(_ value: String) async throws {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, let data = normalized.data(using: .utf8) else {
            throw SpeechRailCredentialError.invalidData
        }

        do {
            try keychain.write(
                data,
                service: Self.protectedService,
                account: Self.account,
                protection: .userPresence
            )
        } catch let error as SpeechRailCredentialError {
            throw error
        } catch {
            throw SpeechRailCredentialError.writeFailed
        }

        let verifiedData: Data
        do {
            verifiedData = try await keychain.read(
                service: Self.protectedService,
                account: Self.account,
                protection: .userPresence
            )
        } catch let error as SpeechRailCredentialError {
            throw error
        } catch {
            throw SpeechRailCredentialError.verificationFailed
        }

        guard try Self.decodeAPIKey(verifiedData) == normalized else {
            throw SpeechRailCredentialError.verificationFailed
        }
    }

    public func migrateLegacyToProtected() async throws {
        let legacyData = try await keychain.read(
            service: Self.legacyService,
            account: Self.account,
            protection: .legacy
        )
        let normalized = try Self.decodeAPIKey(legacyData)
        try await saveProtectedAPIKey(normalized)
    }

    private static func decodeAPIKey(_ data: Data) throws -> String {
        guard let value = String(data: data, encoding: .utf8) else {
            throw SpeechRailCredentialError.invalidData
        }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw SpeechRailCredentialError.invalidData
        }
        return normalized
    }
}

public final class SystemKeychainAccess: @unchecked Sendable {
    private static let protectedLocalizedReason = "为 SpeechRail 语音合成读取受保护的 API key"

    public init() {}

    public func itemState(service: String, account: String) -> KeychainItemState {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            return .present
        case errSecItemNotFound:
            return .missing
        case errSecInteractionNotAllowed:
            // A protected item exists, but status inspection is not allowed to open UI.
            return .present
        default:
            return .inaccessible
        }
    }

    public func read(
        service: String,
        account: String,
        protection: KeychainProtection
    ) async throws -> Data {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        if protection == .userPresence {
            let context = LAContext()
            context.localizedReason = Self.protectedLocalizedReason
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else {
            throw Self.readError(for: status)
        }
        guard let data = result as? Data else {
            throw SpeechRailCredentialError.invalidData
        }
        return data
    }

    public func write(
        _ data: Data,
        service: String,
        account: String,
        protection: KeychainProtection
    ) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        if protection == .userPresence {
            var accessControlError: Unmanaged<CFError>?
            guard let accessControl = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .userPresence,
                &accessControlError
            ) else {
                throw SpeechRailCredentialError.writeFailed
            }
            query[kSecAttrAccessControl as String] = accessControl
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecDuplicateItem else {
            guard addStatus == errSecSuccess else {
                throw SpeechRailCredentialError.writeFailed
            }
            return
        }

        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let update: [String: Any] = [kSecValueData as String: data]
        guard SecItemUpdate(lookup as CFDictionary, update as CFDictionary) == errSecSuccess else {
            throw SpeechRailCredentialError.writeFailed
        }
    }

    private static func readError(for status: OSStatus) -> SpeechRailCredentialError {
        switch status {
        case errSecItemNotFound:
            return .missing
        case errSecUserCanceled:
            return .authenticationCancelled
        case errSecAuthFailed:
            return .authenticationFailed
        case errSecInteractionNotAllowed:
            return .unavailable
        default:
            return .unavailable
        }
    }
}

extension SystemKeychainAccess: KeychainAccessing {}
