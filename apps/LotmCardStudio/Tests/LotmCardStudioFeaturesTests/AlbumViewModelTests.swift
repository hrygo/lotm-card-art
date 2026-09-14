import XCTest
import LotmCardStudioCore
@testable import LotmCardStudioFeatures

@MainActor
final class AlbumViewModelTests: XCTestCase {
    func testDemoLibraryContainsOnlyTheTwoCurrentFoolCards() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.cards.count, 2)
        XCTAssertEqual(model.cards.filter { $0.identity.contentStatus == .confirmed }.count, 0)
        XCTAssertEqual(model.cards.filter { $0.identity.contentStatus == .proposed }.count, 2)
        XCTAssertEqual(
            model.cards.map(\.id),
            [
                "lotm.fool.s09.klein-moretti.tingen-01",
                "lotm.fool.s00.klein-moretti.mr-fool-01"
            ]
        )
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "愚者先生" && $0.identity.sequenceName == "序列 0 · 真神" })
        XCTAssertFalse(model.cards.contains { $0.identity.slotID == "lotm.fool.s03" })
        XCTAssertFalse(model.cards.contains { $0.identity.characterID == "audrey" })
    }

    func testSelectingCardUpdatesDetailAndCanOpenStoryDrawer() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(model.cards.first)

        model.select(card)
        model.toggleStoryDrawer()

        XCTAssertEqual(model.selectedCardID, card.id)
        XCTAssertTrue(model.isStoryDrawerPresented)
    }

    func testFoolSequenceZeroApprovedNarrativeUsesPackagedAudio() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(model.cards.first { $0.identity.slotID == "lotm.fool.s00" })
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.cardID, "lotm.fool.s00.klein-moretti.mr-fool-01")
        XCTAssertEqual(card.identity.displayName, "愚者先生")
        XCTAssertEqual(card.identity.sequenceName, "序列 0 · 真神")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "klein-moretti")
        XCTAssertEqual(card.identity.identitySliceID, "klein.s00.mr-fool")
        XCTAssertEqual(card.visualTheme, .divineFool)
        XCTAssertEqual(card.artworkResourceName, "fool-s00-card-agentic-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "uncle_fu")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(narrative.lines[1].text, "名字可以借来，面具可以更换，真正留下的，是你在无人注视时做出的选择。")
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName),
            [
                "s00-greeting-v2",
                "s00-catchphrase-01-v2",
                "s00-catchphrase-02-v2",
                "s00-story-01-v2",
                "s00-story-02-v2",
                "s00-story-03-v2"
            ]
        )
        XCTAssertEqual(narrative.readableChapters.count, 3)
        XCTAssertTrue(narrative.readableChapters.allSatisfy { $0.line.isPlayable })
        XCTAssertEqual(narrative.playableChapters.count, 3)
    }

    func testKleinTingenSeerCardUsesProducedArtworkAndPackagedNarrative() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.fool.s09.klein-moretti.tingen-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.fool.s09")
        XCTAssertEqual(card.identity.displayName, "克莱恩·莫雷蒂")
        XCTAssertEqual(card.identity.sequenceName, "序列 9 · 占卜家")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "klein-moretti")
        XCTAssertEqual(card.identity.identitySliceID, "klein.s09.tingen")
        XCTAssertEqual(card.identity.contentStatus, .proposed)
        XCTAssertEqual(card.visualTheme, .violet)
        XCTAssertEqual(card.artworkResourceName, "fool-s09-card-name-edit-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.voiceProfileID, "dylan")
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertEqual(
            narrative.lines.map(\.kind),
            [.greeting, .catchphrase, .catchphrase, .story, .story, .story]
        )
        XCTAssertTrue(narrative.lines.allSatisfy { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(narrative.lines[1].text, "占卜给不了你勇气，但能提醒你，别把鲁莽当成勇气。")
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName),
            [
                "s09-greeting-v1",
                "s09-catchphrase-01-v1",
                "s09-catchphrase-02-v1",
                "s09-story-01-v1",
                "s09-story-02-v1",
                "s09-story-03-v1"
            ]
        )
        XCTAssertEqual(narrative.chapters.count, 3)
        XCTAssertTrue(narrative.readableChapters.allSatisfy { $0.line.isPlayable })
        XCTAssertEqual(narrative.playableChapters.count, 3)
    }

    func testCurrentFoolCandidateBundlesKeepIdentityArtworkAndNarrativeTogether() {
        let model = AlbumViewModel()
        let cards = model.cards.filter { $0.identity.slotID == "lotm.fool.s00" || $0.identity.slotID == "lotm.fool.s09" }

        XCTAssertEqual(cards.map(\.id), [
            "lotm.fool.s09.klein-moretti.tingen-01",
            "lotm.fool.s00.klein-moretti.mr-fool-01"
        ])

        for card in cards {
            XCTAssertEqual(card.identity.contentStatus, .proposed)
            XCTAssertTrue(card.identity.hasValidIdentityBinding)
            XCTAssertNotNil(card.artworkResourceName)
            XCTAssertEqual(card.audioStatus, .localBundle)
            XCTAssertTrue(card.narrative?.lines.allSatisfy(\.isPlayable) == true)
            XCTAssertEqual(card.narrative?.cardID, card.identity.cardID)
        }
    }

    func testEveryDemoCardIsAnAtomicBundleWithSixDimensionsAndExplicitAudioState() {
        let model = AlbumViewModel()

        XCTAssertTrue(model.cards.allSatisfy(\.isAtomicBundle))
        XCTAssertTrue(model.cards.allSatisfy { $0.semanticReadbacks.count == 6 })
        XCTAssertTrue(model.cards.allSatisfy { $0.narrative?.cardID == $0.identity.cardID })
        XCTAssertEqual(
            model.cards.reduce(into: [:]) { result, card in result[card.id] = card.collectionIntent },
            model.collectionIntents
        )
    }

    func testRemovingACardPackageCannotLeaveCollectionOrWishlistStateBehind() {
        let removedID = "lotm.fool.s00.klein-moretti.mr-fool-01"
        let remaining = DemoLibrary.cards.filter { $0.id != removedID }
        let model = AlbumViewModel(cards: remaining)

        XCTAssertNil(model.collectionIntents[removedID])
        XCTAssertFalse(model.wishlistCardIDs.contains(removedID))
        XCTAssertFalse(model.cards.contains { $0.id == removedID })
    }

    func testSidebarSectionsFilterCardsWithoutChangingCardIdentity() {
        let model = AlbumViewModel()

        model.show(.formal)
        XCTAssertTrue(model.visibleCards.isEmpty)

        model.show(.candidate)
        XCTAssertEqual(
            model.visibleCards.map(\.id),
            [
                "lotm.fool.s09.klein-moretti.tingen-01",
                "lotm.fool.s00.klein-moretti.mr-fool-01"
            ]
        )

        model.show(.wishlist)
        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.fool.s00.klein-moretti.mr-fool-01"])
    }

    func testSearchTrimsWhitespaceAndMatchesIdentityMetadataCaseInsensitively() {
        let model = AlbumViewModel()

        model.searchText = "  KLEIN  "

        XCTAssertTrue(model.hasSearchQuery)
        XCTAssertEqual(
            model.visibleCards.map(\.id),
            [
                "lotm.fool.s09.klein-moretti.tingen-01",
                "lotm.fool.s00.klein-moretti.mr-fool-01"
            ]
        )
    }

    func testSearchUsesTheSameUnpaddedSequenceCopyAsTheCardUI() {
        let paddedCard = AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.test.s09.prototype",
                slotID: "lotm.test.s09",
                displayName: "测试原型",
                sequenceName: "序列 09",
                contentStatus: .proposed,
                identityKind: .archetype,
                characterID: nil,
                identitySliceID: nil
            ),
            narrative: nil,
            visualTheme: .empty,
            subtitle: "测试身份卡"
        )
        let model = AlbumViewModel(cards: [paddedCard])

        model.searchText = "序列 9"

        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.test.s09.prototype"])
    }

    func testClearingSearchRestoresTheActiveSectionResults() {
        let model = AlbumViewModel()
        model.show(.candidate)
        model.searchText = "序列 9"

        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.fool.s09.klein-moretti.tingen-01"])

        model.clearSearch()

        XCTAssertFalse(model.hasSearchQuery)
        XCTAssertEqual(
            model.visibleCards.map(\.id),
            [
                "lotm.fool.s09.klein-moretti.tingen-01",
                "lotm.fool.s00.klein-moretti.mr-fool-01"
            ]
        )
    }

    func testCharacterFamilyCountSupportsMultipleIndependentCards() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.characterCardCount(for: "klein-moretti"), 2)
        XCTAssertEqual(model.characterCardCount(for: nil), 0)
    }
}
