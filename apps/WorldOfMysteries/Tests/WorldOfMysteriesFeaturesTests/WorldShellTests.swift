import XCTest
import WorldOfMysteriesCore
@testable import WorldOfMysteriesFeatures

@MainActor
final class WorldShellTests: XCTestCase {
    // MARK: - 四个一级区域

    func testShellStartsAtTheWorldHomeAndKeepsPerAreaSelection() {
        let model = AlbumViewModel()
        XCTAssertEqual(model.activeArea, .world)

        let card = try! XCTUnwrap(model.cards.first { $0.id == SampleWorld.kleinTingenCardID })
        model.show(.cards)
        model.select(card)

        let character = try! XCTUnwrap(model.world.character(id: SampleWorld.kleinMorettiID))
        model.show(.characters)
        model.select(character: character)

        let episode = try! XCTUnwrap(model.world.episode(id: SampleWorld.archiveEpisodeID))
        model.show(.storyBook)
        model.select(episode: episode)

        model.show(.cards)
        XCTAssertEqual(model.selectedCardID, card.id)
        model.show(.characters)
        XCTAssertEqual(model.selectedCharacterID, character.id)
        model.show(.storyBook)
        XCTAssertEqual(model.selectedEpisodeID, episode.id)
        XCTAssertEqual(model.selectedEpisode?.title, "档案馆的第七个抽屉")
    }

    func testClearingSelectionsHappensPerArea() {
        let model = AlbumViewModel()
        model.show(.cards)
        model.select(try! XCTUnwrap(model.cards.first))
        model.select(character: try! XCTUnwrap(model.world.character(id: SampleWorld.kleinMorettiID)))
        model.select(episode: try! XCTUnwrap(model.world.episode(id: SampleWorld.archiveEpisodeID)))

        model.clearCharacterSelection()

        XCTAssertNil(model.selectedCharacterID)
        XCTAssertNotNil(model.selectedCardID)
        XCTAssertNotNil(model.selectedEpisodeID)

        model.clearEpisodeSelection()
        XCTAssertNil(model.selectedEpisodeID)
    }

    // MARK: - 世界首页数据

    func testSampleWorldFillsEveryWorldHomeSection() {
        let world = AlbumViewModel().world

        XCTAssertEqual(world.worldName, "本机示例世界")
        XCTAssertEqual(world.calendar.displayLabel, "第五纪 · 某年 十月")
        XCTAssertEqual(world.worldline.displayLabel, "主线")
        XCTAssertEqual(world.dataStatus, .sample)
        XCTAssertNotNil(world.narratorLine)
        XCTAssertEqual(world.events.count, 5)
        XCTAssertEqual(world.unresolvedEvents.count, 3)
        XCTAssertEqual(world.activeEpisodes.count, 1)
        XCTAssertEqual(world.completedEpisodes.count, 2)
        XCTAssertEqual(world.locationChanges.count, 2)
        XCTAssertFalse(world.recentlyActiveCharacters().isEmpty)
        XCTAssertFalse(world.latestCompletedEpisodes().isEmpty)
        XCTAssertFalse(world.isEmpty)
    }

    func testWorldHomeKeepsTheActiveFateVisibleForContinuing() {
        let model = AlbumViewModel()
        let episode = try! XCTUnwrap(model.world.activeEpisodes.first)

        XCTAssertEqual(episode.id, SampleWorld.inProgressEpisodeID)
        XCTAssertEqual(episode.protagonistName, "克莱恩·莫雷蒂")
        XCTAssertNotNil(episode.visibleSeed)

        model.continueFate(episode)

        XCTAssertEqual(model.activeArea, .cards)
        XCTAssertEqual(model.selectedCardID, episode.cardID)
        XCTAssertTrue(model.isStoryDrawerPresented)
    }

    func testUnresolvedEventsPointBackToTheFateThatLeftThem() {
        let world = AlbumViewModel().world
        let event = try! XCTUnwrap(world.event(id: "event.archive-missing-page"))

        XCTAssertTrue(event.isUnresolved)
        XCTAssertEqual(event.relatedEpisodeIDs, [SampleWorld.archiveEpisodeID])
        XCTAssertEqual(event.scopeLabel, "地区")
        XCTAssertEqual(event.statusLabel, "尚无结论")
        XCTAssertEqual(world.events(forEpisodeID: SampleWorld.archiveEpisodeID).map(\.id), [event.id])
    }

    // MARK: - 卡牌与命运入口

    func testCardDetailOffersTheRightFateEntryForEachCardKind() {
        let model = AlbumViewModel()
        let klein = try! XCTUnwrap(model.cards.first { $0.id == SampleWorld.kleinTingenCardID })
        let mrFool = try! XCTUnwrap(model.cards.first { $0.id == SampleWorld.mrFoolCardID })
        let celestial = try! XCTUnwrap(model.cards.first { $0.id == "lotm.celestial-worthy.primordial-01" })

        XCTAssertEqual(model.fateEntry(for: klein).primaryTitle, "继续这段命运")
        XCTAssertEqual(model.fateEntry(for: klein).secondaryTitle, "另起一段")
        XCTAssertEqual(model.fateEntry(for: mrFool).primaryTitle, "以祂的尺度介入世界")
        XCTAssertEqual(model.fateEntry(for: mrFool).role, .trueGod)
        XCTAssertEqual(model.fateEntry(for: celestial).primaryTitle, "以祂的尺度介入世界")
        XCTAssertEqual(model.fateEntry(for: celestial).role, .aboveSequence)
        XCTAssertTrue(model.fateEntry(for: celestial).isAvailable)
    }

    func testCardExperienceLabelsSeparateWorldHistoryFromContentStatus() {
        let model = AlbumViewModel()
        let klein = try! XCTUnwrap(model.cards.first { $0.id == SampleWorld.kleinTingenCardID })
        let celestial = try! XCTUnwrap(model.cards.first { $0.id == "lotm.celestial-worthy.primordial-01" })

        XCTAssertEqual(model.experienceLabel(for: klein), "有一段进行中的命运")
        XCTAssertEqual(model.experienceLabel(for: celestial), "未进入世界")
        XCTAssertEqual(celestial.identity.contentStatus, .proposed)
    }

    func testOpeningAndDismissingFateGenesisTracksTheCard() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(model.cards.first { $0.id == SampleWorld.kleinTingenCardID })

        model.presentFateGenesis(for: card)
        XCTAssertEqual(model.fateGenesisCard?.id, card.id)

        model.beginFate(for: card)
        XCTAssertNil(model.fateGenesisCardID)
        XCTAssertEqual(model.activeArea, .cards)
        XCTAssertEqual(model.selectedCardID, card.id)
        XCTAssertTrue(model.isStoryDrawerPresented)

        model.presentFateGenesis(for: card)
        model.dismissFateGenesis()
        XCTAssertNil(model.fateGenesisCardID)
    }

    func testShowingACardDoesNotOpenTheStoryDrawer() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(model.cards.first { $0.id == SampleWorld.mrFoolCardID })

        model.showCard(card)

        XCTAssertEqual(model.activeArea, .cards)
        XCTAssertEqual(model.selectedCardID, card.id)
        XCTAssertFalse(model.isStoryDrawerPresented)
    }

    func testActiveFateLimitBlocksStartingAnotherFate() {
        let cards = DemoLibrary.cards
        let activeEpisodes = (0..<AlbumViewModel.activeFateLimit).map { index in
            EpisodeRecord(
                id: "fate-limit-\(index)",
                cardID: "some-other-card-\(index)",
                protagonistCharacterID: "someone-\(index)",
                protagonistName: "某个人 \(index)",
                title: "还没有结束的命运 \(index)",
                timeLabel: "十月",
                locationLabel: "某处",
                state: .inProgress,
                listeningNote: "声音会补齐。"
            )
        }
        let world = WorldSnapshot(
            worldName: "上限测试世界",
            calendar: WorldCalendarStamp(eraLabel: "第五纪", dateLabel: "某年 十月"),
            worldline: WorldlineStamp(id: "main", label: "主线"),
            dataStatus: .sample,
            episodes: activeEpisodes
        )
        let model = AlbumViewModel(cards: cards, world: world)
        let freshCard = try! XCTUnwrap(cards.first { $0.id == "lotm.celestial-worthy.primordial-01" })

        let entry = model.fateEntry(for: freshCard)

        XCTAssertFalse(entry.isAvailable)
        XCTAssertTrue(entry.availabilityNote.contains("上限"))
        XCTAssertEqual(model.world.activeEpisodes.count, AlbumViewModel.activeFateLimit)
    }

    // MARK: - 命运生成界面

    func testGenesisPresentationOnlyExposesTheVisibleSeed() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(model.cards.first { $0.id == SampleWorld.kleinTingenCardID })
        let entry = model.fateEntry(for: card)
        let presentation = FateSeedLibrary.genesisPresentation(for: card, entry: entry)

        XCTAssertEqual(presentation.visibleFields(at: 0).map(\.label), ["时间", "地点", "异常", "压力"])
        XCTAssertEqual(presentation.visibleFields(at: 0).count, 4)
        XCTAssertEqual(presentation.primaryActionTitle, "编织命运")
        XCTAssertEqual(presentation.secondaryActionTitle, "换一个入口")
        XCTAssertFalse(presentation.disclosureNote.isEmpty)

        let joined = (
            presentation.visibleFields(at: 0).map(\.value)
                + [presentation.title, presentation.entryNote, presentation.disclosureNote]
        ).joined(separator: " ")
        for forbidden in ["秘密", "结局", "真相是", "难度"] {
            XCTAssertFalse(joined.contains(forbidden), "命运生成界面不应泄露：\(forbidden)")
        }
    }

    func testAnotherEntrySwapsTheVisibleSituationWithinTheSameScale() {
        let model = AlbumViewModel()
        let card = try! XCTUnwrap(model.cards.first { $0.id == SampleWorld.mrFoolCardID })
        let entry = model.fateEntry(for: card)
        let presentation = FateSeedLibrary.genesisPresentation(for: card, entry: entry)

        XCTAssertEqual(presentation.seedCount, 2)
        XCTAssertNotEqual(presentation.seed(at: 0), presentation.seed(at: 1))
        XCTAssertEqual(presentation.seed(at: 2), presentation.seed(at: 0))
        XCTAssertTrue(presentation.seed(at: 1).pressure.contains("线") || !presentation.seed(at: 1).pressure.isEmpty)
    }

    // MARK: - 人物

    func testCharactersAggregateIdentityCardsByCharacterID() {
        let model = AlbumViewModel()
        let klein = try! XCTUnwrap(model.world.character(id: SampleWorld.kleinMorettiID))

        XCTAssertEqual(klein.cardIDs, [SampleWorld.kleinTingenCardID, SampleWorld.mrFoolCardID])
        XCTAssertEqual(model.cards(for: klein).count, 2)
        XCTAssertEqual(klein.cardCountLabel, "2 张身份卡")
        XCTAssertEqual(klein.existenceKind, .canon)
        XCTAssertEqual(klein.subjectPronoun, "他")
        XCTAssertEqual(WorldShellCopy.knowledgeTitle(for: klein), "他知道的事")
    }

    func testTranscendentCharactersUseDivinePronounAndHaveNoLocalHistory() {
        let model = AlbumViewModel()
        let characterIDs = model.characters.map(\.id)

        XCTAssertEqual(characterIDs.count, 10)
        let transcendent = model.characters.filter { $0.existenceKind == .transcendent }
        XCTAssertEqual(transcendent.count, 9)
        for profile in transcendent {
            XCTAssertEqual(profile.subjectPronoun, "祂")
            XCTAssertEqual(profile.pathwayLabel, "序列之上")
            XCTAssertTrue(profile.relationships.isEmpty)
            XCTAssertNil(profile.lastSeenLabel)
            XCTAssertNil(profile.lastSeenOrder)
            XCTAssertEqual(WorldShellCopy.knowledgeTitle(for: profile), "祂知道的事")
            XCTAssertEqual(profile.lastSeenSummary, "尚未在你的世界里出现")
        }
        XCTAssertFalse(transcendent.contains { $0.id == SampleWorld.kleinMorettiID })
    }

    func testCharacterRelationshipsSeparateCanonFactsFromLocalExperience() {
        let model = AlbumViewModel()
        let klein = try! XCTUnwrap(model.world.character(id: SampleWorld.kleinMorettiID))

        XCTAssertEqual(klein.canonRelationshipCount, 2)
        XCTAssertEqual(klein.localRelationshipCount, 2)
        let local = try! XCTUnwrap(klein.relationships.first { $0.origin == .localExperience })
        XCTAssertEqual(local.changedByEpisodeID, SampleWorld.archiveEpisodeID)
        XCTAssertNotNil(model.world.episode(id: local.changedByEpisodeID ?? ""))
    }

    func testCharacterSurfaceOnlyShowsWhatTheCharacterKnows() {
        let model = AlbumViewModel()
        let klein = try! XCTUnwrap(model.world.character(id: SampleWorld.kleinMorettiID))

        XCTAssertEqual(klein.knowledgeFacts.map(\.scope.label), ["公开", "途径", "秘密"])
        XCTAssertEqual(model.world.episodes(forCharacterID: SampleWorld.kleinMorettiID).count, 3)
        XCTAssertEqual(model.world.episodes(forCharacterID: "celestial-worthy"), [])
    }

    func testCharacterAndStoryBookSearchFilterTheirOwnLists() {
        let model = AlbumViewModel()

        model.searchText = "克莱恩"
        XCTAssertEqual(model.visibleCharacters.map(\.id), [SampleWorld.kleinMorettiID])

        model.searchText = "档案馆"
        XCTAssertEqual(model.visibleEpisodes.map(\.id), [SampleWorld.archiveEpisodeID])

        model.searchText = "序列 9"
        XCTAssertEqual(model.visibleCharacters.map(\.id), [SampleWorld.kleinMorettiID])
        XCTAssertTrue(model.visibleEpisodes.isEmpty)
    }

    // MARK: - 故事书

    func testStoryBookListsActiveFateFirst() {
        let model = AlbumViewModel()
        let episodeIDs = model.visibleEpisodes.map(\.id)

        XCTAssertEqual(episodeIDs.first, SampleWorld.inProgressEpisodeID)
        XCTAssertEqual(episodeIDs.count, 3)
        XCTAssertEqual(model.visibleEpisodes.first?.statusLabel, "进行中")
    }

    func testCompletedFateKeepsRecordSecretsRelationshipsAndWorldImpact() {
        let model = AlbumViewModel()
        let episode = try! XCTUnwrap(model.world.episode(id: SampleWorld.archiveEpisodeID))

        XCTAssertEqual(episode.closureLabel, "开放结局")
        XCTAssertEqual(episode.choicePathLabels.first, "去翻那本案卷 · 信息优先")
        XCTAssertEqual(episode.choicePathLabels.count, 6)
        XCTAssertEqual(episode.secretSummary, "已揭开 4 / 7 个秘密")
        XCTAssertEqual(episode.relationshipChanges.count, 2)
        XCTAssertEqual(episode.worldImpactEventIDs, ["event.archive-missing-page"])
        XCTAssertFalse(model.world.events(forEpisodeID: episode.id).isEmpty)
        XCTAssertNotNil(episode.costSummary)
        XCTAssertNil(episode.worldlineNote)
    }

    func testUnrevealedSecretsNeverExposeTheirAnswer() {
        let model = AlbumViewModel()
        let episode = try! XCTUnwrap(model.world.episode(id: SampleWorld.archiveEpisodeID))
        let hidden = episode.secrets.filter { $0.state == .hidden }

        XCTAssertEqual(hidden.count, 2)
        for secret in hidden {
            XCTAssertNil(secret.revealedText)
            XCTAssertEqual(secret.displayText, WorldShellCopy.hiddenSecretText)
        }
    }

    func testInProgressFateHasNoClosureAndKeepsItsSeed() {
        let model = AlbumViewModel()
        let episode = try! XCTUnwrap(model.world.episode(id: SampleWorld.inProgressEpisodeID))

        XCTAssertEqual(episode.state, .inProgress)
        XCTAssertNil(episode.closureLabel)
        XCTAssertNil(episode.costSummary)
        XCTAssertEqual(episode.choicePath.count, 1)
        XCTAssertNotNil(episode.visibleSeed)
        XCTAssertFalse(episode.listeningNote.isEmpty)
    }

    func testEachSampleFateCarriesItsOwnPassages() {
        for episode in SampleWorld.episodes {
            XCTAssertFalse(
                episode.recordedPassages.isEmpty,
                "示例里的每段命运都该有自己的段落：\(episode.title)"
            )
            for passage in episode.recordedPassages {
                XCTAssertFalse(passage.title.isEmpty)
                XCTAssertFalse(passage.text.isEmpty)
            }
        }
    }

    func testFatesOfTheSameCardDoNotRepeatTheSameParagraphs() {
        let model = AlbumViewModel()
        let episodes = SampleWorld.episodes.filter { $0.cardID == SampleWorld.kleinTingenCardID }
        let texts = episodes.flatMap { $0.recordedPassages.map(\.text) }

        XCTAssertEqual(Set(texts).count, texts.count)
        XCTAssertGreaterThanOrEqual(episodes.count, 2)
    }

    func testInProgressFateNeverBorrowsTheCardsNarrativeChapters() {
        let model = AlbumViewModel()
        let episode = try! XCTUnwrap(model.world.episode(id: SampleWorld.inProgressEpisodeID))
        let chapters = try! XCTUnwrap(model.cards.first { $0.id == episode.cardID }?.narrative?.readableChapters)

        let material = EpisodeReadingResolver.resolve(episode: episode, cardChapters: chapters)

        XCTAssertEqual(material.source, .episode)
        XCTAssertFalse(chapters.isEmpty)
        XCTAssertTrue(material.passages.allSatisfy { passage in
            !chapters.contains { $0.title == passage.title }
        })
    }

    // MARK: - 状态文学化

    func testNarrativeStateNotesCarrySentencesInsteadOfNumbers() {
        for episode in SampleWorld.episodes {
            for note in episode.stateNotes {
                XCTAssertFalse(
                    note.text.contains { $0.isNumber && $0.isASCII },
                    "叙事状态提示不应出现数值：\(note.text)"
                )
                XCTAssertTrue(note.sourceLabel.contains("来自"))
            }
        }
    }

    func testNarrativeSurfaceDoesNotExposeEngineVariables() {
        let model = AlbumViewModel()
        let episode = try! XCTUnwrap(model.world.episode(id: SampleWorld.inProgressEpisodeID))
        let surface = (
            SampleWorld.episodes.flatMap { $0.stateNotes.map(\.text) }
                + SampleWorld.episodes.map(\.secretSummary)
                + [WorldShellCopy.experienceState, WorldShellCopy.fateSection]
        ).joined(separator: " ")

        for variable in ["spirituality", "exposure", "corruption", "danger"] {
            XCTAssertFalse(surface.contains(variable))
        }
        XCTAssertEqual(episode.secretSummary, "已揭开 1 / 4 个秘密")
        XCTAssertTrue(model.cards.count > 0)
    }

    // MARK: - 用户文案

    func testWorldShellCopyAvoidsInternalTerms() {
        let forbidden = [
            "fixture", "mock", "dummy", "synthetic", "snapshot", "draft",
            "candidate", "session", "seed", "prompt", "runtime", "episode", "state"
        ]
        let surface = [
            WorldShellCopy.world,
            WorldShellCopy.sampleBadge,
            WorldShellCopy.sampleBadgeNote,
            WorldShellCopy.primaryAreas,
            WorldShellCopy.localNavigation,
            WorldShellCopy.currentFate,
            WorldShellCopy.recentEvents,
            WorldShellCopy.activeFates,
            WorldShellCopy.activePeople,
            WorldShellCopy.unresolvedEvents,
            WorldShellCopy.locationChanges,
            WorldShellCopy.recentStories,
            WorldShellCopy.noActiveFate,
            WorldShellCopy.startFateFromCards,
            WorldShellCopy.emptyWorldTitle,
            WorldShellCopy.emptyWorldNote,
            WorldShellCopy.identitySlices,
            WorldShellCopy.identitySliceNote,
            WorldShellCopy.characterExperiences,
            WorldShellCopy.characterRelations,
            WorldShellCopy.characterKnowledge,
            WorldShellCopy.readingMode,
            WorldShellCopy.listeningMode,
            WorldShellCopy.fateRecord,
            WorldShellCopy.relationshipChanges,
            WorldShellCopy.worldImpact,
            WorldShellCopy.fateGenesisTitle,
            WorldShellCopy.weavingTitle,
            WorldShellCopy.weaveAction,
            WorldShellCopy.anotherEntry,
            WorldShellCopy.genesisDisclosure,
            WorldShellCopy.genesisHint,
            WorldShellCopy.hiddenSecretText,
            WorldShellCopy.rewindToFate
        ] + PrimaryArea.allCases.map(\.summary)
            + PrimaryArea.allCases.map { WorldShellCopy.footerAction(for: $0) }
            + WorldShellCopy.weavingLayers
            + SampleWorld.episodes.map(\.title)
            + SampleWorld.episodes.map(\.listeningNote)

        for text in surface {
            for term in forbidden {
                XCTAssertFalse(
                    text.localizedCaseInsensitiveContains(term),
                    "用户文案不应包含内部术语「\(term)」：\(text)"
                )
            }
        }
    }

    func testSampleWorldCopyStaysHumanReadable() {
        let surface = SampleWorld.episodes.flatMap { episode in
            [episode.title, episode.protagonistName, episode.locationLabel] + episode.choicePath.map(\.action)
        }

        for text in surface {
            XCTAssertFalse(text.isEmpty)
            XCTAssertFalse(text.contains("_"))
            XCTAssertFalse(text.contains("lotm."))
        }
    }
}
