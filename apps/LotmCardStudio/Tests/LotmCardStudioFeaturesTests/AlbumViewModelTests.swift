import XCTest
import LotmCardStudioCore
@testable import LotmCardStudioFeatures

@MainActor
final class AlbumViewModelTests: XCTestCase {
    func testDemoLibraryContainsTheCurrentIsolatedCards() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.cards.count, 11)
        XCTAssertEqual(model.cards.filter { $0.identity.contentStatus == .confirmed }.count, 0)
        XCTAssertEqual(model.cards.filter { $0.identity.contentStatus == .proposed }.count, 11)
        XCTAssertEqual(
            model.cards.map(\.id),
            [
                "lotm.fool.s09.klein-moretti.tingen-01",
                "lotm.fool.s00.klein-moretti.mr-fool-01",
                "lotm.celestial-worthy.primordial-01",
                "lotm.god-almighty.primordial-01",
                "lotm.mother-goddess-depravity.primordial-01",
                "lotm.eternal-darkness.primordial-01",
                "lotm.father-of-demons.primordial-01",
                "lotm.destruction-calamity.primordial-01",
                "lotm.embodiment-of-disorder.primordial-01",
                "lotm.demon-of-knowledge.primordial-01",
                "lotm.key-of-light.primordial-01"
            ]
        )
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "愚者先生" && $0.identity.sequenceName == "序列 0 · 真神" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "福生玄黄天尊" && $0.identity.sequenceName == "序列之上 · 诡秘之主" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "上帝" && $0.identity.sequenceName == "序列之上 · 星界支柱" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "堕落母神" && $0.identity.sequenceName == "序列之上 · 现实支柱" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "永恒之暗" && $0.identity.sequenceName == "序列之上 · 永恒之暗" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "恶魔之父" && $0.identity.sequenceName == "序列之上 · 恶魔之父" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "毁灭天灾" && $0.identity.sequenceName == "序列之上 · 毁灭天灾" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "失序者" && $0.identity.sequenceName == "序列之上 · 失序者" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "知识之妖" && $0.identity.sequenceName == "序列之上 · 知识之妖" })
        XCTAssertTrue(model.cards.contains { $0.identity.displayName == "光之钥" && $0.identity.sequenceName == "序列之上 · 光之钥" })
        XCTAssertFalse(model.cards.contains { $0.identity.slotID == "lotm.fool.s03" })
        XCTAssertFalse(model.cards.contains { $0.identity.characterID == "audrey" })
    }

    func testPathwaySummaryUsesCurrentCardsAndCollectionIntents() {
        let model = AlbumViewModel()

        XCTAssertEqual(
            model.pathwaySummary(for: "fool"),
            "2 张已收藏 · 0 张候选"
        )
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

    func testEveryDemoCardIsTheUsersFormalCollectionWhileContentStaysUnconfirmed() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.cards.count, 11)
        XCTAssertEqual(model.formalCount, 11)
        XCTAssertEqual(model.candidateCount, 0)
        XCTAssertTrue(model.cards.allSatisfy { $0.collectionIntent == .formal })
        // 「转正式」只动收藏意图，不连带声明内容已核验：九位「序列之上」仍是待核验内容
        let aboveSequenceSlots: Set<String> = [
            "lotm.celestial-worthy", "lotm.god-almighty", "lotm.mother-goddess-depravity",
            "lotm.eternal-darkness", "lotm.father-of-demons", "lotm.destruction-calamity",
            "lotm.embodiment-of-disorder", "lotm.demon-of-knowledge", "lotm.key-of-light"
        ]
        let aboveSequence = model.cards.filter { aboveSequenceSlots.contains($0.identity.slotID) }
        XCTAssertEqual(aboveSequence.count, 9)
        XCTAssertTrue(aboveSequence.allSatisfy { $0.identity.contentStatus == .proposed })
        XCTAssertEqual(model.confirmedCount, 0)
        // 正式收藏与愿望清单互斥：已收藏的卡不应同时是待收目标
        XCTAssertEqual(model.wishlistCount, 0)
        XCTAssertTrue(model.wishlistCardIDs.isEmpty)
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
        XCTAssertEqual(
            model.visibleCards.map(\.id),
            [
                "lotm.fool.s09.klein-moretti.tingen-01",
                "lotm.fool.s00.klein-moretti.mr-fool-01",
                "lotm.celestial-worthy.primordial-01",
                "lotm.god-almighty.primordial-01",
                "lotm.mother-goddess-depravity.primordial-01",
                "lotm.eternal-darkness.primordial-01",
                "lotm.father-of-demons.primordial-01",
                "lotm.destruction-calamity.primordial-01",
                "lotm.embodiment-of-disorder.primordial-01",
                "lotm.demon-of-knowledge.primordial-01",
                "lotm.key-of-light.primordial-01"
            ]
        )

        model.show(.candidate)
        XCTAssertTrue(model.visibleCards.isEmpty)

        model.show(.wishlist)
        // 十一张卡均归入正式收藏，fixture 中愿望清单为空（分栏与指标保留给后续新增目标）
        XCTAssertTrue(model.visibleCards.isEmpty)
        XCTAssertEqual(model.wishlistCount, 0)
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
        model.show(.formal)
        model.searchText = "序列 9"

        XCTAssertEqual(model.visibleCards.map(\.id), ["lotm.fool.s09.klein-moretti.tingen-01"])

        model.clearSearch()

        XCTAssertFalse(model.hasSearchQuery)
        XCTAssertEqual(
            model.visibleCards.map(\.id),
            [
                "lotm.fool.s09.klein-moretti.tingen-01",
                "lotm.fool.s00.klein-moretti.mr-fool-01",
                "lotm.celestial-worthy.primordial-01",
                "lotm.god-almighty.primordial-01",
                "lotm.mother-goddess-depravity.primordial-01",
                "lotm.eternal-darkness.primordial-01",
                "lotm.father-of-demons.primordial-01",
                "lotm.destruction-calamity.primordial-01",
                "lotm.embodiment-of-disorder.primordial-01",
                "lotm.demon-of-knowledge.primordial-01",
                "lotm.key-of-light.primordial-01"
            ]
        )
    }

    func testCharacterFamilyCountSupportsMultipleIndependentCards() {
        let model = AlbumViewModel()

        XCTAssertEqual(model.characterCardCount(for: "klein-moretti"), 2)
        XCTAssertEqual(model.characterCardCount(for: nil), 0)
    }

    func testCelestialWorthyCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.celestial-worthy.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.celestial-worthy")
        XCTAssertEqual(card.identity.displayName, "福生玄黄天尊")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 诡秘之主")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "celestial-worthy")
        XCTAssertEqual(card.identity.identitySliceID, "celestial-worthy.primordial")
        XCTAssertEqual(card.visualTheme, .celestialWorthy)
        XCTAssertEqual(card.artworkResourceName, "celestial-worthy-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "celestial-worthy")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "celestial-worthy-catchphrase-01-v1",
                "celestial-worthy-catchphrase-02-v1",
                "celestial-worthy-greeting-v1",
                "celestial-worthy-story-01-v1",
                "celestial-worthy-story-02-v1",
                "celestial-worthy-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }

    func testGodAlmightyCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.god-almighty.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.god-almighty")
        XCTAssertEqual(card.identity.displayName, "上帝")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 星界支柱")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "god-almighty")
        XCTAssertEqual(card.identity.identitySliceID, "god-almighty.primordial")
        XCTAssertEqual(card.visualTheme, .godAlmighty)
        XCTAssertEqual(card.artworkResourceName, "god-almighty-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "god-almighty")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "god-almighty-catchphrase-01-v1",
                "god-almighty-catchphrase-02-v1",
                "god-almighty-greeting-v1",
                "god-almighty-story-01-v1",
                "god-almighty-story-02-v1",
                "god-almighty-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }

    func testMotherGoddessDepravityCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.mother-goddess-depravity.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.mother-goddess-depravity")
        XCTAssertEqual(card.identity.displayName, "堕落母神")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 现实支柱")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "mother-goddess-depravity")
        XCTAssertEqual(card.identity.identitySliceID, "mother-goddess-depravity.primordial")
        XCTAssertEqual(card.visualTheme, .motherGoddessDepravity)
        XCTAssertEqual(card.artworkResourceName, "mother-goddess-depravity-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "mother-goddess-depravity")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "mother-goddess-depravity-catchphrase-01-v1",
                "mother-goddess-depravity-catchphrase-02-v1",
                "mother-goddess-depravity-greeting-v1",
                "mother-goddess-depravity-story-01-v1",
                "mother-goddess-depravity-story-02-v1",
                "mother-goddess-depravity-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }

    func testEternalDarknessCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.eternal-darkness.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.eternal-darkness")
        XCTAssertEqual(card.identity.displayName, "永恒之暗")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 永恒之暗")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "eternal-darkness")
        XCTAssertEqual(card.identity.identitySliceID, "eternal-darkness.primordial")
        XCTAssertEqual(card.visualTheme, .eternalDarkness)
        XCTAssertEqual(card.artworkResourceName, "eternal-darkness-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "eternal-darkness")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "eternal-darkness-catchphrase-01-v1",
                "eternal-darkness-catchphrase-02-v1",
                "eternal-darkness-greeting-v1",
                "eternal-darkness-story-01-v1",
                "eternal-darkness-story-02-v1",
                "eternal-darkness-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }

    func testFatherOfDemonsCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.father-of-demons.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.father-of-demons")
        XCTAssertEqual(card.identity.displayName, "恶魔之父")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 恶魔之父")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "father-of-demons")
        XCTAssertEqual(card.identity.identitySliceID, "father-of-demons.primordial")
        XCTAssertEqual(card.visualTheme, .fatherOfDemons)
        XCTAssertEqual(card.artworkResourceName, "father-of-demons-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "father-of-demons")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "father-of-demons-catchphrase-01-v1",
                "father-of-demons-catchphrase-02-v1",
                "father-of-demons-greeting-v1",
                "father-of-demons-story-01-v1",
                "father-of-demons-story-02-v1",
                "father-of-demons-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }

    func testDestructionCalamityCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.destruction-calamity.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.destruction-calamity")
        XCTAssertEqual(card.identity.displayName, "毁灭天灾")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 毁灭天灾")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "destruction-calamity")
        XCTAssertEqual(card.identity.identitySliceID, "destruction-calamity.primordial")
        XCTAssertEqual(card.visualTheme, .destructionCalamity)
        XCTAssertEqual(card.artworkResourceName, "destruction-calamity-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "destruction-calamity")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "destruction-calamity-catchphrase-01-v1",
                "destruction-calamity-catchphrase-02-v1",
                "destruction-calamity-greeting-v1",
                "destruction-calamity-story-01-v1",
                "destruction-calamity-story-02-v1",
                "destruction-calamity-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }

    func testEmbodimentOfDisorderCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.embodiment-of-disorder.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.embodiment-of-disorder")
        XCTAssertEqual(card.identity.displayName, "失序者")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 失序者")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "embodiment-of-disorder")
        XCTAssertEqual(card.identity.identitySliceID, "embodiment-of-disorder.primordial")
        XCTAssertEqual(card.visualTheme, .embodimentOfDisorder)
        XCTAssertEqual(card.artworkResourceName, "embodiment-of-disorder-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "embodiment-of-disorder")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "embodiment-of-disorder-catchphrase-01-v1",
                "embodiment-of-disorder-catchphrase-02-v1",
                "embodiment-of-disorder-greeting-v1",
                "embodiment-of-disorder-story-01-v1",
                "embodiment-of-disorder-story-02-v1",
                "embodiment-of-disorder-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }

    func testDemonOfKnowledgeCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.demon-of-knowledge.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.demon-of-knowledge")
        XCTAssertEqual(card.identity.displayName, "知识之妖")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 知识之妖")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "demon-of-knowledge")
        XCTAssertEqual(card.identity.identitySliceID, "demon-of-knowledge.primordial")
        XCTAssertEqual(card.visualTheme, .demonOfKnowledge)
        XCTAssertEqual(card.artworkResourceName, "demon-of-knowledge-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "demon-of-knowledge")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "demon-of-knowledge-catchphrase-01-v1",
                "demon-of-knowledge-catchphrase-02-v1",
                "demon-of-knowledge-greeting-v1",
                "demon-of-knowledge-story-01-v1",
                "demon-of-knowledge-story-02-v1",
                "demon-of-knowledge-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }

    func testKeyOfLightCardIsOneAtomicAboveSequenceBundle() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(
            model.cards.first { $0.identity.cardID == "lotm.key-of-light.primordial-01" }
        )
        let narrative = try! XCTUnwrap(card.narrative)

        XCTAssertEqual(card.identity.slotID, "lotm.key-of-light")
        XCTAssertEqual(card.identity.displayName, "光之钥")
        XCTAssertEqual(card.identity.sequenceName, "序列之上 · 光之钥")
        XCTAssertEqual(card.identity.identityKind, .character)
        XCTAssertEqual(card.identity.characterID, "key-of-light")
        XCTAssertEqual(card.identity.identitySliceID, "key-of-light.primordial")
        XCTAssertEqual(card.visualTheme, .keyOfLight)
        XCTAssertEqual(card.artworkResourceName, "key-of-light-card-v1-v001")
        XCTAssertEqual(card.audioStatus, .localBundle)
        XCTAssertEqual(narrative.voiceProfileID, "key-of-light")
        XCTAssertEqual(narrative.cardID, card.identity.cardID)
        XCTAssertEqual(narrative.lines.count, 6)
        XCTAssertTrue(narrative.lines.allSatisfy(\.isPlayable))
        XCTAssertEqual(
            narrative.lines.compactMap(\.audioResourceName).sorted(),
            [
                "key-of-light-catchphrase-01-v1",
                "key-of-light-catchphrase-02-v1",
                "key-of-light-greeting-v1",
                "key-of-light-story-01-v1",
                "key-of-light-story-02-v1",
                "key-of-light-story-03-v1"
            ]
        )
        XCTAssertTrue(card.isAtomicBundle)
    }
}
