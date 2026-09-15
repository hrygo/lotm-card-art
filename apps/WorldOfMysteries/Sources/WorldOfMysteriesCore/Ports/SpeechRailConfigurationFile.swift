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
            .appendingPathComponent("WorldOfMysteries", isDirectory: true)
            .appendingPathComponent("SpeechRail.json", isDirectory: false)
    }()

    /// 更名（诡秘之主 → 诡秘世界）前的配置文件位置；只读回退，不写入、不删除旧文件。
    public static let predecessorFileURL: URL = {        let applicationSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
        return applicationSupport
            .appendingPathComponent("LotmCardStudio", isDirectory: true)
            .appendingPathComponent("SpeechRail.json", isDirectory: false)
    }()

    public let fileURL: URL
    /// 旧位置回退；为 `nil` 时只读当前 `fileURL`。读取回退不改变写入位置。
    public let fallbackFileURL: URL?

    private let fileManager: FileManager

    public init(
        fileURL: URL = SpeechRailConfigurationFileStore.defaultFileURL,
        fallbackFileURL: URL? = SpeechRailConfigurationFileStore.predecessorFileURL,
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fallbackFileURL = fallbackFileURL
        self.fileManager = fileManager
    }

    public func state() -> SpeechRailConfigurationFileState {
        do {
            _ = try readAPIKey()
            return .configured
        } catch SpeechRailConfigurationFileError.missing {
            return .missing
        } catch {
            return .unavailable
        }
    }

    /// 读取当前配置文件；当前文件缺失时才回退到更名前的旧位置。
    public func readAPIKey() throws -> String {
        if fileManager.fileExists(atPath: fileURL.path) {
            return try readAPIKey(at: fileURL)
        }

        if let fallbackFileURL, fileManager.fileExists(atPath: fallbackFileURL.path) {
            return try readAPIKey(at: fallbackFileURL)
        }

        throw SpeechRailConfigurationFileError.missing
    }

    private func readAPIKey(at url: URL) throws -> String {
        let data: Data
        do {
            data = try Data(contentsOf: url)
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
