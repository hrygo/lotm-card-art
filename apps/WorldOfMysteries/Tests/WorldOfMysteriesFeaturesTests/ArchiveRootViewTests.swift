import XCTest
import SwiftUI
import WorldOfMysteriesCore
@testable import WorldOfMysteriesFeatures

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

    func testStoryModeUsesCardAreaAsDefaultMinimumHeight() {
        XCTAssertEqual(
            CardDetailLayout.minimumRailHeight(for: .story),
            CardDetailLayout.motionViewportSize.height
        )
        XCTAssertEqual(CardDetailLayout.minimumRailHeight(for: .identity), 0)
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

    func testGallerySubtitleExplainsTheIdentityCardReadingFlow() {
        XCTAssertEqual(
            LibrarySection.gallery.subtitle,
            "选择一张身份卡，查看身份、六维信息和故事。"
        )
    }

    func testPresentationCopyTranslatesInternalIdentityAndVoiceIDs() {
        let fool = DemoLibrary.cards.first { $0.identity.cardID == "lotm.fool.s00.klein-moretti.mr-fool-01" }!
        let audreyIdentity = CardIdentity(
            cardID: "lotm.visionary.s07.audrey-01",
            slotID: "lotm.visionary.s07",
            displayName: "正义",
            sequenceName: "序列 7 · 心理医生",
            contentStatus: .proposed,
            identityKind: .character,
            characterID: "audrey",
            identitySliceID: nil
        )

        XCTAssertEqual(ArchiveCopy.characterName(for: "klein-moretti"), "克莱恩·莫雷蒂")
        XCTAssertEqual(ArchiveCopy.characterName(for: "audrey"), "奥黛丽")
        XCTAssertEqual(ArchiveCopy.characterName(for: nil), "途径原型")
        XCTAssertEqual(ArchiveCopy.voiceTitle(for: fool.identity), "愚者先生的声音")
        XCTAssertEqual(ArchiveCopy.voiceTitle(for: audreyIdentity), "正义的声音")
        XCTAssertEqual(ArchiveCopy.pathwaySummary(formal: 2, candidate: 1), "2 张已收藏 · 1 张候选")
    }

    func testPresentationCopyUsesUnpaddedSequenceNumbers() {
        XCTAssertEqual(ArchiveCopy.sequenceName(for: "序列 00 · 真神"), "序列 0 · 真神")
        XCTAssertEqual(ArchiveCopy.sequenceName(for: "序列 01"), "序列 1")
        XCTAssertEqual(ArchiveCopy.sequenceName(for: "序列 09"), "序列 9")
        XCTAssertEqual(ArchiveCopy.sequenceName(for: "序列 07 · 心理医生"), "序列 7 · 心理医生")
        XCTAssertEqual(ArchiveCopy.sequenceName(for: "序列 3"), "序列 3")
    }

    func testSequenceTierUsesFiveRankHierarchy() {
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 9"), .low)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 8"), .low)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 7"), .mid)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 5"), .mid)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 4"), .saint)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 3"), .saint)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 2"), .angel)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 1"), .angel)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "序列 00 · 真神"), .trueGod)
        XCTAssertEqual(ArchiveCopy.sequenceTier(for: "未知层级"), .unknown)
    }

    func testSequenceRankCopyNamesTheFiveUserFacingRanks() {
        XCTAssertEqual(ArchiveCopy.sequenceRankTitle(for: "序列 9"), "低序列")
        XCTAssertEqual(ArchiveCopy.sequenceRankTitle(for: "序列 7"), "中序列")
        XCTAssertEqual(ArchiveCopy.sequenceRankTitle(for: "序列 4"), "圣者")
        XCTAssertEqual(ArchiveCopy.sequenceRankTitle(for: "序列 2"), "天使")
        XCTAssertEqual(ArchiveCopy.sequenceRankTitle(for: "序列 0"), "真神")
        XCTAssertEqual(ArchiveCopy.sequenceRankTitle(for: "未知层级"), "未分级")
    }

    func testSequenceDisplayCopyAddsRankWithoutDuplicatingExistingRankText() {
        XCTAssertEqual(
            ArchiveCopy.sequenceDisplayLabel(for: "序列 01", includesRank: true),
            "序列 1 · 天使"
        )
        XCTAssertEqual(
            ArchiveCopy.sequenceDisplayLabel(for: "序列 00 · 真神", includesRank: true),
            "序列 0 · 真神"
        )
        XCTAssertEqual(
            ArchiveCopy.sequenceDisplayLabel(for: "序列 09", includesRank: true),
            "序列 9 · 低序列"
        )
    }

    func testSequenceTokensUseDistinctRarityFamilies() {
        XCTAssertEqual(
            ArchiveTheme.Sequence.low.label,
            Color(red: 0.91, green: 0.929, blue: 0.949)
        )
        XCTAssertEqual(
            ArchiveTheme.Sequence.mid.label,
            Color(red: 0.333, green: 0.725, blue: 0.471)
        )
        XCTAssertEqual(
            ArchiveTheme.Sequence.saint.label,
            Color(red: 0.302, green: 0.592, blue: 0.831)
        )
        XCTAssertEqual(
            ArchiveTheme.Sequence.angel.label,
            Color(red: 0.651, green: 0.42, blue: 0.839)
        )
        XCTAssertEqual(
            ArchiveTheme.Sequence.trueGod.label,
            Color(red: 0.941, green: 0.698, blue: 0.247)
        )

        let labels = [
            ArchiveTheme.Sequence.low.label,
            ArchiveTheme.Sequence.mid.label,
            ArchiveTheme.Sequence.saint.label,
            ArchiveTheme.Sequence.angel.label,
            ArchiveTheme.Sequence.trueGod.label
        ]
        for (index, label) in labels.enumerated() {
            for otherLabel in labels.dropFirst(index + 1) {
                XCTAssertNotEqual(label, otherLabel)
            }
        }
    }

    func testStatusAndSemanticAccentsDoNotReuseSequenceRarityColors() {
        XCTAssertNotEqual(ArchiveTheme.Status.candidate, ArchiveTheme.Sequence.angel.label)
        XCTAssertNotEqual(ArchiveTheme.Status.candidate, ArchiveTheme.Sequence.low.label)
        XCTAssertNotEqual(ArchiveTheme.Status.candidate, ArchiveTheme.Sequence.trueGod.label)
        XCTAssertNotEqual(ArchiveTheme.Semantic.potion, ArchiveTheme.Sequence.angel.label)
        XCTAssertNotEqual(ArchiveTheme.Status.unresearched, ArchiveTheme.Sequence.trueGod.label)
        XCTAssertNotEqual(ArchiveTheme.Semantic.promotion, ArchiveTheme.Sequence.trueGod.label)
    }

    func testArchetypeRelationCopyDoesNotPretendThereIsACharacterBinding() {
        XCTAssertEqual(
            ArchiveCopy.characterRelationNote(for: nil),
            "当前途径在该序列的通用原型卡，不对应具体角色。"
        )
        XCTAssertEqual(
            ArchiveCopy.characterCountLabel(for: nil, count: 0),
            "原型卡"
        )
        XCTAssertNil(
            ArchiveCopy.characterRelationNote(for: "klein"),
        )
        XCTAssertEqual(
            ArchiveCopy.characterRelationTitle(for: nil),
            "身份类型"
        )
        XCTAssertEqual(
            ArchiveCopy.characterRelationTitle(for: "klein"),
            "角色关联"
        )
    }

    func testIdentityPageCopyKeepsVoicePromptInTheCaptionRail() {
        XCTAssertEqual(
            VoiceAvailability.localAudio.captionPrompt,
            "点击“播放声音”，当前台词会显示在这里。"
        )
        XCTAssertEqual(
            VoiceAvailability.speechRail.captionPrompt,
            "点击“播放声音”，会先准备声音，再显示台词。"
        )
        XCTAssertEqual(
            VoiceAvailability.pending.captionPrompt,
            "台词确认后，声音和字幕会显示在这里。"
        )
    }

    func testWishlistMetricCopyUsesTheActualListName() {
        XCTAssertEqual(ArchiveCopy.wishlistMetricTitle, "愿望清单")
        XCTAssertEqual(ArchiveCopy.recentDiscoveries, "卡牌列表")
    }

    func testPlaybackStateUsesPlainLanguageForIdleAndLoading() {
        XCTAssertEqual(PlaybackState.idle.label, "未播放")
        XCTAssertEqual(PlaybackState.loading.label, "正在准备声音")
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
