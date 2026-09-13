import XCTest
import LotmCardStudioCore
@testable import LotmCardStudioFeatures

final class ArchiveRootViewTests: XCTestCase {
    @MainActor
    func testArchiveRootViewCanBeConstructedWithoutSpeechRail() {
        _ = ArchiveRootView(speechClient: nil)
        XCTAssertTrue(true)
    }

    func testCardDetailLayoutReservesFixedMotionViewport() {
        XCTAssertEqual(CardDetailLayout.motionViewportSize, CGSize(width: 420, height: 630))
        XCTAssertEqual(CardDetailLayout.cardSize, CGSize(width: 320, height: 480))
        XCTAssertEqual(CardDetailLayout.horizontalSafeArea, 50)
        XCTAssertEqual(CardDetailLayout.verticalSafeArea, 75)
        XCTAssertEqual(CardDetailLayout.railMinimumWidth, 460)
        XCTAssertEqual(CardDetailLayout.railMaximumWidth, 760)
    }

    func testCardDetailLayoutStacksOnlyBelowTwoColumnContentWidth() {
        XCTAssertTrue(CardDetailLayout.usesTwoColumns(for: 912))
        XCTAssertFalse(CardDetailLayout.usesTwoColumns(for: 911))
    }

    func testVoiceAvailabilitySeparatesLocalRemoteAndPendingGreetings() {
        let local = NarrativePack(
            cardID: "local",
            voiceProfileID: "test",
            lines: [approvedGreeting(audioResourceName: "fixture")],
            chapters: []
        )
        let remote = NarrativePack(
            cardID: "remote",
            voiceProfileID: "test",
            lines: [approvedGreeting(audioResourceName: nil)],
            chapters: []
        )
        let pending = NarrativePack(
            cardID: "pending",
            voiceProfileID: "test",
            lines: [
                NarrativeLine(
                    id: "pending-greeting",
                    kind: .greeting,
                    text: "待审核",
                    sourceKind: .original,
                    review: .draft,
                    contentDigest: "pending-v1"
                )
            ],
            chapters: []
        )

        XCTAssertEqual(voiceAvailability(for: local), .localAudio)
        XCTAssertEqual(voiceAvailability(for: remote), .speechRail)
        XCTAssertEqual(voiceAvailability(for: pending), .pending)
        XCTAssertEqual(voiceAvailability(for: nil), .pending)
        XCTAssertEqual(VoiceAvailability.speechRail.statusLabel, "需要 SpeechRail")
    }

    private func approvedGreeting(audioResourceName: String?) -> NarrativeLine {
        NarrativeLine(
            id: "approved-greeting",
            kind: .greeting,
            text: "已批准",
            sourceKind: .original,
            review: .approved(contentDigest: "approved-v1"),
            contentDigest: "approved-v1",
            audioResourceName: audioResourceName
        )
    }
}
