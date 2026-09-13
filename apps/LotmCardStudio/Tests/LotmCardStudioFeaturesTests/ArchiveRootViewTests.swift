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
        XCTAssertEqual(VoiceAvailability.pending.statusLabel, "等待确认")
        XCTAssertEqual(VoiceAvailability.localAudio.statusLabel, "可以播放")
        XCTAssertEqual(VoiceAvailability.speechRail.statusLabel, "可生成声音")
    }

    func testDemoCardSubtitlesUseHumanLanguageInsteadOfPipelineMetadata() {
        let forbiddenTerms = [
            "synthetic",
            "fixture",
            "approved copy",
            "awaiting review",
            "candidate",
            "local audio",
            "research",
            "snapshot",
            "voice recipe",
            "2:3",
            "uncle_fu",
            "serena"
        ]

        for card in DemoLibrary.cards {
            for term in forbiddenTerms {
                XCTAssertFalse(
                    card.subtitle.localizedCaseInsensitiveContains(term),
                    "用户文案不应包含内部术语：\(card.subtitle)"
                )
            }
        }
    }

    func testLibrarySectionDescriptionsDoNotExposeImplementationLanguage() {
        let descriptions = [
            LibrarySection.gallery.subtitle,
            LibrarySection.formal.subtitle,
            LibrarySection.candidate.subtitle,
            LibrarySection.wishlist.subtitle
        ]
        let forbiddenTerms = ["fixture", "snapshot", "local", "approved", "candidate", "draft", "review"]

        for description in descriptions {
            for term in forbiddenTerms {
                XCTAssertFalse(
                    description.localizedCaseInsensitiveContains(term),
                    "用户说明不应包含内部术语：\(description)"
                )
            }
        }
    }

    func testPresentationCopyTranslatesInternalIdentityAndVoiceIDs() {
        let fool = DemoLibrary.cards.first { $0.identity.cardID == "lotm.fool.s00.prototype" }!
        let audrey = DemoLibrary.cards.first { $0.identity.cardID == "lotm.visionary.s07.audrey-01" }!

        XCTAssertEqual(ArchiveCopy.characterName(for: "klein"), "克莱恩")
        XCTAssertEqual(ArchiveCopy.characterName(for: "audrey"), "奥黛丽")
        XCTAssertEqual(ArchiveCopy.characterName(for: nil), "途径原型")
        XCTAssertEqual(ArchiveCopy.voiceTitle(for: fool.identity), "愚者的声音")
        XCTAssertEqual(ArchiveCopy.voiceTitle(for: audrey.identity), "正义的声音")
        XCTAssertEqual(ArchiveCopy.pathwaySummary(confirmed: 1, candidate: 1), "1 张已确认 · 1 张候选")
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
