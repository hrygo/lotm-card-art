import XCTest
@testable import LotmCardStudioFeatures

@MainActor
final class AlbumViewModelTests: XCTestCase {
    func testDemoLibraryShowsDynamicIdentityCardsAndAResearchCandidate() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.cards.count, 4)
        XCTAssertEqual(model.cards.filter { $0.identity.contentStatus == .confirmed }.count, 2)
        XCTAssertEqual(model.cards.filter { $0.identity.contentStatus == .proposed }.count, 2)
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "愚者" && $0.identity.sequenceName == "序列 00 · 真神" })
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

        XCTAssertEqual(card.identity.displayName, "愚者")
        XCTAssertEqual(card.identity.sequenceName, "序列 00 · 真神")
        XCTAssertEqual(card.visualTheme, .divineFool)
        XCTAssertEqual(card.artworkResourceName, "fool-s00-render-v003")
        XCTAssertEqual(narrative.voiceProfileID, "uncle_fu")
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName),
            [
                "s00-greeting-v1",
                "s00-catchphrase-01-v1",
                "s00-catchphrase-02-v1",
                "s00-story-01-v1",
                "s00-story-02-v1",
                "s00-story-03-v1"
            ]
        )
        XCTAssertEqual(narrative.readableChapters.count, 3)
        XCTAssertTrue(narrative.readableChapters.allSatisfy { $0.line.isPlayable })
        XCTAssertEqual(narrative.playableChapters.count, 3)
    }

    func testAudreyJusticePsychiatristCardKeepsIndependentIdentityAndPackagedNarrative() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(model.cards.first { $0.identity.cardID == "lotm.visionary.s07.audrey-01" })
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.visionary.s07")
        XCTAssertEqual(card.identity.displayName, "正义 · 奥黛丽")
        XCTAssertEqual(card.identity.sequenceName, "序列 07 · 心理医生")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "audrey")
        XCTAssertEqual(card.identity.identitySliceID, "audrey.s07.justice")
        XCTAssertEqual(card.visualTheme, .visionary)
        XCTAssertEqual(card.artworkResourceName, "audrey-s07-psychologist-v001")
        XCTAssertEqual(narrative.voiceProfileID, "serena")
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName),
            [
                "audrey-greeting-v1",
                "audrey-catchphrase-01-v1",
                "audrey-catchphrase-02-v1",
                "audrey-story-01-v1",
                "audrey-story-02-v1",
                "audrey-story-03-v1"
            ]
        )
        XCTAssertEqual(narrative.readableChapters.count, 3)
        XCTAssertTrue(narrative.readableChapters.allSatisfy { $0.line.isPlayable })
    }

    func testSidebarSectionsFilterCardsWithoutChangingCardIdentity() {
        let model = AlbumViewModel()

        model.show(.formal)
        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.fool.s03.klein-01"])

        model.show(.candidate)
        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.fool.s09.klein-02"])

        model.show(.wishlist)
        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.fool.s00.prototype"])
    }

    func testSearchTrimsWhitespaceAndMatchesIdentityMetadataCaseInsensitively() {
        let model = AlbumViewModel()

        model.searchText = "  KLEIN  "

        XCTAssertTrue(model.hasSearchQuery)
        XCTAssertEqual(
            model.visibleCards.map(\.id),
            ["lotm.fool.s03.klein-01", "lotm.fool.s09.klein-02"]
        )
    }

    func testClearingSearchRestoresTheActiveSectionResults() {
        let model = AlbumViewModel()
        model.show(.candidate)
        model.searchText = "序列 09"

        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.fool.s09.klein-02"])

        model.clearSearch()

        XCTAssertFalse(model.hasSearchQuery)
        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.fool.s09.klein-02"])
    }

    func testCharacterFamilyCountSupportsMultipleIndependentCards() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.characterCardCount(for: "klein"), 2)
        XCTAssertEqual(model.characterCardCount(for: nil), 0)
    }
}
