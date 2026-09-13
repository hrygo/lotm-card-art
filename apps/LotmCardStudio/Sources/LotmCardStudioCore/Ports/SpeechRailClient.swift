import Foundation

public struct SpeechRequest: Codable, Equatable, Sendable {
    public let model: String
    public let input: String
    public let voice: String
    public let responseFormat: String
    public let speed: Double
    public let language: String
    public let instructions: String?

    public init(
        input: String,
        voice: String,
        instructions: String? = nil,
        speed: Double = 1,
        language: String = "zh",
        model: String = "speechrail/qwen3-tts",
        responseFormat: String = "wav"
    ) {
        self.model = model
        self.input = input
        self.voice = voice
        self.responseFormat = responseFormat
        self.speed = speed
        self.language = language
        self.instructions = instructions
    }
}

public struct SpeechRailHealth: Codable, Equatable, Sendable {
    public let ttsReady: Bool
    public let ttsWarm: Bool?

    public init(ttsReady: Bool, ttsWarm: Bool? = nil) {
        self.ttsReady = ttsReady
        self.ttsWarm = ttsWarm
    }
}

public enum SpeechRailError: Error, Equatable, Sendable {
    case nonLoopbackAddress
    case inputTooLong
    case invalidSpeed
    case invalidResponse
    case httpStatus(Int)
    case transport(String)
    case decoding(String)
}

public final class SpeechRailHTTPClient: @unchecked Sendable {
    public typealias APIKeyProvider = @Sendable () async throws -> String?

    public let baseURL: URL
    public let apiKey: String?
    private let apiKeyProvider: APIKeyProvider?
    private let session: URLSession
    private let sessionDelegate: LoopbackRedirectBlocker?

    public init(
        baseURL: URL,
        apiKey: String? = nil,
        apiKeyProvider: APIKeyProvider? = nil,
        session: URLSession? = nil
    ) throws {
        guard Self.isLoopback(baseURL) else {
            throw SpeechRailError.nonLoopbackAddress
        }
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.apiKeyProvider = apiKeyProvider
        if let session {
            self.session = session
            self.sessionDelegate = nil
        } else {
            let delegate = LoopbackRedirectBlocker()
            self.session = URLSession(
                configuration: .ephemeral,
                delegate: delegate,
                delegateQueue: nil
            )
            self.sessionDelegate = delegate
        }
    }

    public func makeSpeechRequest(_ speech: SpeechRequest) throws -> URLRequest {
        try makeSpeechRequest(speech, apiKey: apiKey)
    }

    private func makeSpeechRequest(
        _ speech: SpeechRequest,
        apiKey: String?
    ) throws -> URLRequest {
        guard speech.input.count <= 4_096 else {
            throw SpeechRailError.inputTooLong
        }
        guard (0.25...4).contains(speech.speed) else {
            throw SpeechRailError.invalidSpeed
        }

        var request = URLRequest(url: endpoint("/v1/audio/speech"))
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/wav", forHTTPHeaderField: "Accept")
        if let apiKey, !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        do {
            request.httpBody = try encoder.encode(speech)
        } catch {
            throw SpeechRailError.transport(error.localizedDescription)
        }
        return request
    }

    public func health() async throws -> SpeechRailHealth {
        var request = URLRequest(url: endpoint("/health"))
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        let (data, _) = try await send(request)
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(SpeechRailHealth.self, from: data)
        } catch {
            throw SpeechRailError.decoding(error.localizedDescription)
        }
    }

    public func synthesize(_ speech: SpeechRequest) async throws -> Data {
        let resolvedAPIKey: String?
        if let apiKey {
            resolvedAPIKey = apiKey
        } else {
            resolvedAPIKey = try await apiKeyProvider?()
        }
        let request = try makeSpeechRequest(speech, apiKey: resolvedAPIKey)
        let (data, _) = try await send(request)
        guard !data.isEmpty else {
            throw SpeechRailError.invalidResponse
        }
        return data
    }

    private func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            let result = try await session.data(for: request)
            guard let response = result.1 as? HTTPURLResponse else {
                throw SpeechRailError.invalidResponse
            }
            guard let finalURL = response.url, Self.isLoopback(finalURL) else {
                throw SpeechRailError.nonLoopbackAddress
            }
            guard (200..<300).contains(response.statusCode) else {
                throw SpeechRailError.httpStatus(response.statusCode)
            }
            return result
        } catch let error as SpeechRailError {
            throw error
        } catch {
            throw SpeechRailError.transport(error.localizedDescription)
        }
    }

    private func endpoint(_ path: String) -> URL {
        baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }

    private static func isLoopback(_ url: URL) -> Bool {
        guard url.scheme == "http" || url.scheme == "https", let host = url.host else {
            return false
        }
        if host == "::1" {
            return true
        }
        let parts = host.split(separator: ".")
        guard parts.count == 4, parts.first == "127" else {
            return false
        }
        return parts.allSatisfy { part in
            guard let value = Int(part) else { return false }
            return (0...255).contains(value)
        }
    }
}

private final class LoopbackRedirectBlocker: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}
