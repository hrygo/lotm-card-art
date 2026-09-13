import Foundation

public enum SpeechRailConfigurationFileState: Equatable, Sendable {
    case configured
    case missing
    case unavailable
}

public enum SpeechRailConfigurationFileError: Error, Equatable, Sendable {
    case missing
    case invalidData
    case readFailed
    case writeFailed
}

public final class SpeechRailConfigurationFileStore: @unchecked Sendable {
    public static let defaultFileURL: URL = {
        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        return applicationSupport
            .appendingPathComponent("LotmCardStudio", isDirectory: true)
            .appendingPathComponent("SpeechRail.json", isDirectory: false)
    }()

    public let fileURL: URL

    private let fileManager: FileManager

    public init(
        fileURL: URL = SpeechRailConfigurationFileStore.defaultFileURL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public func state() -> SpeechRailConfigurationFileState {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .missing
        }

        do {
            _ = try readAPIKey()
            return .configured
        } catch {
            return .unavailable
        }
    }

    public func readAPIKey() throws -> String {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw SpeechRailConfigurationFileError.missing
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw SpeechRailConfigurationFileError.readFailed
        }

        let payload: Payload
        do {
            payload = try JSONDecoder().decode(Payload.self, from: data)
        } catch {
            throw SpeechRailConfigurationFileError.invalidData
        }

        let normalized = payload.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw SpeechRailConfigurationFileError.invalidData
        }
        return normalized
    }

    public func saveAPIKey(_ value: String) throws {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw SpeechRailConfigurationFileError.invalidData
        }

        do {
            let directoryURL = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try fileManager.setAttributes(
                [.posixPermissions: 0o700],
                ofItemAtPath: directoryURL.path
            )

            let data = try JSONEncoder().encode(Payload(apiKey: normalized))
            try data.write(to: fileURL, options: .atomic)
            try fileManager.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: fileURL.path
            )
        } catch {
            throw SpeechRailConfigurationFileError.writeFailed
        }
    }

    private struct Payload: Codable, Sendable {
        let apiKey: String
    }
}
