import Foundation
import XCTest
@testable import LotmCardStudioCore

final class SpeechRailClientTests: XCTestCase {
    func testRejectsNonLoopbackSpeechRailURL() {
        XCTAssertThrowsError(
            try SpeechRailHTTPClient(baseURL: URL(string: "https://example.com")!)
        ) { error in
            XCTAssertEqual(error as? SpeechRailError, .nonLoopbackAddress)
        }
    }

    func testBuildsSnakeCaseSpeechRequestWithOptionalAuthorization() throws {
        let client = try SpeechRailHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:8201")!,
            apiKey: "local-test-key"
        )
        let request = try client.makeSpeechRequest(
            SpeechRequest(
                input: "我在这里。",
                voice: "low-lantern",
                instructions: "低声、克制",
                speed: 0.9,
                language: "zh"
            )
        )
        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )

        XCTAssertEqual(request.url?.absoluteString, "http://127.0.0.1:8201/v1/audio/speech")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer local-test-key")
        XCTAssertEqual(json["input"] as? String, "我在这里。")
        XCTAssertEqual(json["response_format"] as? String, "wav")
        XCTAssertEqual(json["instructions"] as? String, "低声、克制")
        XCTAssertEqual(json["speed"] as? Double, 0.9)
        XCTAssertEqual(request.timeoutInterval, 180, accuracy: 0.001)
    }

    func testRejectsSpeechInputLongerThanContractLimit() throws {
        let client = try SpeechRailHTTPClient(baseURL: URL(string: "http://127.0.0.1:8201")!)

        XCTAssertThrowsError(
            try client.makeSpeechRequest(
                SpeechRequest(input: String(repeating: "字", count: 4_097), voice: "low-lantern")
            )
        ) { error in
            XCTAssertEqual(error as? SpeechRailError, .inputTooLong)
        }
    }

    func testHealthDecodesSpeechRailSnakeCaseReadiness() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SpeechRailURLProtocol.self]
        let client = try SpeechRailHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:8201")!,
            session: URLSession(configuration: configuration)
        )

        let health = try await client.health()

        XCTAssertTrue(health.ttsReady)
        XCTAssertEqual(health.ttsWarm, false)
    }
}

private final class SpeechRailURLProtocol: URLProtocol {
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
                  headerFields: ["Content-Type": "application/json"]
              )
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(#"{"tts_ready":true,"tts_warm":false}"#.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
