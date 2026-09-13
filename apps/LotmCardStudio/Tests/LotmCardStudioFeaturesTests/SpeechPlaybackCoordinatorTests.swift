import Foundation
import XCTest
import LotmCardStudioCore
@testable import LotmCardStudioFeatures

@MainActor
final class SpeechPlaybackCoordinatorTests: XCTestCase {
    func testSpeakPublishesCaptionBeforeSpeechRailFailureAndKeepsTranscriptVisible() {
        let coordinator = SpeechPlaybackCoordinator(client: nil)
        let line = NarrativeLine(
            id: "approved-line",
            kind: .greeting,
            text: "我会把这句话留在灰雾之上。",
            sourceKind: .original,
            review: .approved(contentDigest: "approved-line-v1"),
            contentDigest: "approved-line-v1"
        )

        coordinator.speak(line, voiceProfileID: "uncle_fu")

        XCTAssertEqual(
            coordinator.currentCaption,
            PlaybackCaption(lineID: line.id, kind: line.kind, text: line.text)
        )
        XCTAssertEqual(coordinator.currentText, line.text)
        XCTAssertEqual(coordinator.state, .failed("声音服务未连接"))
    }

    func testStopClearsCaptionAndTranscriptAfterPlaybackAttempt() {
        let coordinator = SpeechPlaybackCoordinator(client: nil)
        let line = NarrativeLine(
            id: "approved-line",
            kind: .catchphrase,
            text: "先观察，再决定。",
            sourceKind: .original,
            review: .approved(contentDigest: "approved-line-v1"),
            contentDigest: "approved-line-v1"
        )

        coordinator.speak(line, voiceProfileID: "uncle_fu")
        coordinator.stop()

        XCTAssertNil(coordinator.currentCaption)
        XCTAssertNil(coordinator.currentText)
        XCTAssertEqual(coordinator.state, .idle)
    }

    func testReplayReusesGeneratedAudioForSameApprovedLine() async throws {
        let probe = SpeechPlaybackProbe()
        let client = try SpeechRailHTTPClient(
            baseURL: URL(string: "http://127.0.0.1:8201")!,
            apiKeyProvider: { await probe.resolve() },
            session: makePlaybackSession()
        )
        let coordinator = SpeechPlaybackCoordinator(client: client)
        let line = NarrativeLine(
            id: "remote-story-line",
            kind: .story,
            text: "这段完整章节只应当合成一次。",
            sourceKind: .original,
            review: .approved(contentDigest: "remote-story-line-v1"),
            contentDigest: "remote-story-line-v1"
        )

        coordinator.speak(line, voiceProfileID: "serena")
        try await waitForSynthesis(coordinator, probe: probe)
        var requestCount = await probe.callCount()
        XCTAssertEqual(requestCount, 1)

        coordinator.replay()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotEqual(coordinator.state, .loading)
        requestCount = await probe.callCount()
        XCTAssertEqual(requestCount, 1)

        coordinator.stop()
        coordinator.speak(line, voiceProfileID: "serena")
        XCTAssertNotEqual(coordinator.state, .loading)
        requestCount = await probe.callCount()
        XCTAssertEqual(requestCount, 1)
    }

    func testSpeakRejectsUnapprovedLineBeforeTouchingSpeechRail() {
        let coordinator = SpeechPlaybackCoordinator(client: nil)
        let line = NarrativeLine(
            id: "draft-line",
            kind: .greeting,
            text: "这是一条尚未批准的台词。",
            sourceKind: .original,
            review: .draft,
            contentDigest: "draft-line-v1"
        )

        coordinator.speak(line, voiceProfileID: "uncle_fu")

        XCTAssertEqual(coordinator.state, .failed("这段文字还在确认中"))
    }

    func testCredentialErrorsRemainActionable() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailCredentialError.missing),
            "声音服务密钥缺失，请在“语音设置”中配置"
        )
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailCredentialError.authenticationCancelled),
            "未完成安全验证，仍可阅读文字"
        )
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailCredentialError.authenticationFailed),
            "安全验证失败，仍可阅读文字"
        )
    }

    func testHTTP401IsReportedAsMissingOrInvalidAPIKey() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailError.httpStatus(401)),
            "声音服务密钥缺失或无效，请在“语音设置”中配置"
        )
    }

    func testHTTP422IsReportedAsRequestValidationFailure() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailError.httpStatus(422)),
            "声音服务暂时无法处理这段文字，请稍后重试"
        )
    }

    func testMissingConfigurationFileIsReportedAsActionable() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailConfigurationFileError.missing),
            "声音服务密钥缺失，请在“语音设置”中配置"
        )
    }

    func testInvalidConfigurationFileIsReportedAsActionable() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailConfigurationFileError.invalidData),
            "声音服务设置无效，请在“语音设置”中重新保存"
        )
    }

    private func waitForSynthesis(
        _ coordinator: SpeechPlaybackCoordinator,
        probe: SpeechPlaybackProbe
    ) async throws {
        for _ in 0..<100 {
            if await probe.callCount() == 1, coordinator.state != .loading {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTFail("SpeechRail 合成没有在测试窗口内完成")
    }

    private func makePlaybackSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PlaybackURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private actor SpeechPlaybackProbe {
    private var requests = 0

    func resolve() -> String? {
        requests += 1
        return "test-key"
    }

    func callCount() -> Int {
        requests
    }
}

private final class PlaybackURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.path == "/v1/audio/speech"
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
        client?.urlProtocol(self, didLoad: makeSilentWAV())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private func makeSilentWAV() -> Data {
    let sampleCount = 400
    let dataSize = UInt32(sampleCount * 2)
    var data = Data()
    data.append(contentsOf: Array("RIFF".utf8))
    appendLittleEndian(UInt32(36) + dataSize, to: &data)
    data.append(contentsOf: Array("WAVE".utf8))
    data.append(contentsOf: Array("fmt ".utf8))
    appendLittleEndian(UInt32(16), to: &data)
    appendLittleEndian(UInt16(1), to: &data)
    appendLittleEndian(UInt16(1), to: &data)
    appendLittleEndian(UInt32(8_000), to: &data)
    appendLittleEndian(UInt32(16_000), to: &data)
    appendLittleEndian(UInt16(2), to: &data)
    appendLittleEndian(UInt16(16), to: &data)
    data.append(contentsOf: Array("data".utf8))
    appendLittleEndian(dataSize, to: &data)
    data.append(contentsOf: repeatElement(UInt8(0), count: Int(dataSize)))
    return data
}

private func appendLittleEndian(_ value: UInt16, to data: inout Data) {
    data.append(UInt8(truncatingIfNeeded: value))
    data.append(UInt8(truncatingIfNeeded: value >> 8))
}

private func appendLittleEndian(_ value: UInt32, to data: inout Data) {
    data.append(UInt8(truncatingIfNeeded: value))
    data.append(UInt8(truncatingIfNeeded: value >> 8))
    data.append(UInt8(truncatingIfNeeded: value >> 16))
    data.append(UInt8(truncatingIfNeeded: value >> 24))
}
