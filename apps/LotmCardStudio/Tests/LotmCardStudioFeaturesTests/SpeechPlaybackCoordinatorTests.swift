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
}
