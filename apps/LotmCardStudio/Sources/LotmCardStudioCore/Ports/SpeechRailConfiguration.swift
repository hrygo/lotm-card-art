import Foundation

public enum SpeechRailConfiguration {
    public static let defaultBaseURL = URL(string: "http://127.0.0.1:8201")!

    public static func makeClient(
        configurationStore: SpeechRailConfigurationFileStore = .init(),
        session: URLSession? = nil
    ) throws -> SpeechRailHTTPClient {
        try SpeechRailHTTPClient(
            baseURL: defaultBaseURL,
            apiKeyProvider: {
                try configurationStore.readAPIKey()
            },
            session: session
        )
    }
}
