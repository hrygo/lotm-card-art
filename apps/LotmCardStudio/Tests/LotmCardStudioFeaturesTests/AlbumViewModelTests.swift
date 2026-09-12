import XCTest
@testable import LotmCardStudioFeatures

@MainActor
final class AlbumViewModelTests: XCTestCase {
    func testDemoLibraryShowsDynamicIdentityCardsAndAnUnfinishedTarget() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.cards.count, 3)
        XCTAssertEqual(model.cards.filter { $0.identity.contentStatus == .confirmed }.count, 1)
        XCTAssertEqual(model.cards.filter { $0.identity.contentStatus == .proposed }.count, 1)
        XCTAssertTrue(model.cards.contains { $0.identity.contentStatus == .unfilled })
    }

    func testSelectingCardUpdatesDetailAndCanOpenStoryDrawer() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(model.cards.first)

        model.select(card)
        model.toggleStoryDrawer()

        XCTAssertEqual(model.selectedCardID, card.id)
        XCTAssertTrue(model.isStoryDrawerPresented)
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

    func testCharacterFamilyCountSupportsMultipleIndependentCards() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.characterCardCount(for: "klein"), 2)
        XCTAssertEqual(model.characterCardCount(for: nil), 0)
    }
}
