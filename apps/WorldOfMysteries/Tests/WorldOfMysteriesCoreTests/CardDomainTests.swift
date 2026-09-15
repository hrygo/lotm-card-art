import XCTest
@testable import WorldOfMysteriesCore

final class CardDomainTests: XCTestCase {
    func testSequenceMayContainZeroOrManyIdentityCards() {
        let cards = [
            CardIdentity(
                cardID: "lotm.fool.s03.klein-01",
                slotID: "lotm.fool.s03",
                displayName: "小丑",
                sequenceName: "序列 3",
                contentStatus: .confirmed,
                identityKind: .character,
                characterID: "klein",
                identitySliceID: "klein.s03"
            ),
            CardIdentity(
                cardID: "lotm.fool.s03.klein-02",
                slotID: "lotm.fool.s03",
                displayName: "小丑 · 异画",
                sequenceName: "序列 3",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "klein",
                identitySliceID: "klein.s03.alt"
            )
        ]

        XCTAssertEqual(cards.count, 2)
        XCTAssertEqual(Set(cards.map { $0.cardID }).count, 2)
        XCTAssertEqual(Set(cards.map { $0.characterID }).count, 1)
    }

    func testCandidateIntentSurvivesContentUpgradeWithoutAutomaticPromotion() {
        let state = CollectionResolver.resolve(intent: .candidate, contentStatus: .confirmed)

        XCTAssertEqual(state, .upgradeAvailable)
    }

    func testCandidateIntentStaysCandidateBeforeContentIsConfirmed() {
        let state = CollectionResolver.resolve(intent: .candidate, contentStatus: .proposed)

        XCTAssertEqual(state, .candidate)
    }

    func testFormalIntentRequiresCurrentConfirmedContent() {
        let state = CollectionResolver.resolve(intent: .formal, contentStatus: .proposed)

        XCTAssertEqual(state, .needsReview)
    }

    func testConfirmedProgressUsesTheCurrentDynamicCardSet() {
        let cards = [
            CardIdentity(
                cardID: "lotm.fool.s03.klein-01",
                slotID: "lotm.fool.s03",
                displayName: "小丑",
                sequenceName: "序列 3",
                contentStatus: .confirmed,
                identityKind: .character,
                characterID: "klein",
                identitySliceID: "klein.s03"
            ),
            CardIdentity(
                cardID: "lotm.fool.s09.prototype",
                slotID: "lotm.fool.s09",
                displayName: "占卜家原型",
                sequenceName: "序列 9",
                contentStatus: .proposed,
                identityKind: .archetype,
                characterID: nil,
                identitySliceID: nil
            )
        ]

        let progress = CollectionProgress.confirmed(cards: cards, formalCardIDs: ["lotm.fool.s03.klein-01"])

        XCTAssertEqual(progress.confirmedCount, 1)
        XCTAssertEqual(progress.formalCount, 1)
        XCTAssertEqual(progress.denominator, 1)
        XCTAssertEqual(progress.fraction, 1)
    }
}
