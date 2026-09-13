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

    func testMakeSpeechRequestDoesNotResolveAsyncProvider() async throws {
        let probe = ProviderProbe()
        let client = try SpeechRailHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:8201")!,
            apiKeyProvider: { await probe.resolve() },
            session: makeSpeechRailSession()
        )

        let request = try client.makeSpeechRequest(
            SpeechRequest(input: "只构造请求，不访问凭据。", voice: "low-lantern")
        )

        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
        let callCount = await probe.callCount()
        XCTAssertEqual(callCount, 0)
    }

    func testSynthesizeResolvesAsyncProviderAtRequestTime() async throws {
        let probe = ProviderProbe()
        let client = try SpeechRailHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:8201")!,
            apiKeyProvider: { await probe.resolve() },
            session: makeSpeechRailSession()
        )

        let data = try await client.synthesize(
            SpeechRequest(input: "在发起合成时读取凭据。", voice: "low-lantern")
        )

        XCTAssertFalse(data.isEmpty)
        let callCount = await probe.callCount()
        XCTAssertEqual(callCount, 1)
    }

    func testFixedAPIKeyTakesPrecedenceOverAsyncProvider() async throws {
        let probe = ProviderProbe()
        let client = try SpeechRailHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:8201")!,
            apiKey: "fixed-key",
            apiKeyProvider: { await probe.resolve() },
            session: makeSpeechRailSession()
        )

        _ = try await client.synthesize(
            SpeechRequest(input: "固定凭据优先。", voice: "low-lantern")
        )

        let callCount = await probe.callCount()
        XCTAssertEqual(callCount, 0)
    }

    private func makeSpeechRailSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SpeechRailURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private actor ProviderProbe {
    private var calls = 0

    func resolve() -> String? {
        calls += 1
        return "test-key"
    }

    func callCount() -> Int {
        calls
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
        let responseData: Data
        if url.path == "/health" {
            responseData = Data(#"{"tts_ready":true,"tts_warm":false}"#.utf8)
        } else {
            responseData = Data([0x52, 0x49, 0x46, 0x46])
        }
        client?.urlProtocol(self, didLoad: responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
