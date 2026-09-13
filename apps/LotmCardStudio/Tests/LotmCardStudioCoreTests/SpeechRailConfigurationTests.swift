import Foundation
import XCTest
@testable import LotmCardStudioCore

final class SpeechRailConfigurationTests: XCTestCase {
    func testMakeClientDoesNotReadConfigurationDuringInitialization() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LotmCardStudioConfigurationTests-\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("SpeechRail.json")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        let store = SpeechRailConfigurationFileStore(fileURL: fileURL)

        _ = try SpeechRailConfiguration.makeClient(configurationStore: store)

        XCTAssertEqual(store.state(), .missing)
    }

    func testConfiguredClientReadsFileOnlyWhenSynthesisStarts() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LotmCardStudioConfigurationTests-\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("SpeechRail.json")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        let store = SpeechRailConfigurationFileStore(fileURL: fileURL)
        try store.saveAPIKey("config-test-key")

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ConfigurationURLProtocol.self]
        let client = try SpeechRailConfiguration.makeClient(
            configurationStore: store,
            session: URLSession(configuration: configuration)
        )
        _ = try await client.synthesize(
            SpeechRequest(input: "配置文件 provider", voice: "low-lantern")
        )

        XCTAssertTrue(true)
    }
}

private final class ConfigurationURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: 200,
                  httpVersion: nil,
                  headerFields: ["Content-Type": "audio/wav"]
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data([0x52, 0x49, 0x46, 0x46]))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
