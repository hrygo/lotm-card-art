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
        XCTAssertEqual(coordinator.state, .failed("SpeechRail 未连接"))
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

        XCTAssertEqual(coordinator.state, .failed("此内容尚未批准"))
    }

    func testCredentialErrorsRemainActionable() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailCredentialError.missing),
            "SpeechRail API key 缺失，请在设置中配置"
        )
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailCredentialError.authenticationCancelled),
            "未完成钥匙串认证，文字稿仍可阅读"
        )
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailCredentialError.authenticationFailed),
            "钥匙串认证失败，文字稿仍可阅读"
        )
    }

    func testHTTP401IsReportedAsMissingOrInvalidAPIKey() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailError.httpStatus(401)),
            "SpeechRail API key 缺失或无效，请在设置中配置"
        )
    }

    func testHTTP422IsReportedAsRequestValidationFailure() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailError.httpStatus(422)),
            "SpeechRail 拒绝了当前语音请求，请检查 voice 或文本"
        )
    }

    func testMissingConfigurationFileIsReportedAsActionable() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailConfigurationFileError.missing),
            "SpeechRail API key 缺失，请在设置中配置文件"
        )
    }

    func testInvalidConfigurationFileIsReportedAsActionable() {
        XCTAssertEqual(
            SpeechPlaybackCoordinator.message(for: SpeechRailConfigurationFileError.invalidData),
            "SpeechRail 配置文件无效，请在设置中重新保存"
        )
    }
}
