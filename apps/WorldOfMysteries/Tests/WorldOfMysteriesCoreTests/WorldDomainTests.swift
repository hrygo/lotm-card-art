import XCTest
import WorldOfMysteriesCore

final class WorldDomainTests: XCTestCase {
    // MARK: - 一级区域

    func testPrimaryAreasAreFourSideBySideEntries() {
        XCTAssertEqual(PrimaryArea.allCases, [.world, .cards, .characters, .storyBook])
        XCTAssertEqual(PrimaryArea.allCases.map(\.title), ["世界", "卡牌", "人物", "故事书"])
        for area in PrimaryArea.allCases {
            XCTAssertFalse(area.symbol.isEmpty)
            XCTAssertFalse(area.summary.isEmpty)
        }
    }

    // MARK: - 身份角色与命运入口

    func testSequenceSlotsResolveToIdentityRoles() {
        XCTAssertEqual(IdentityRoleResolver.sequenceNumber(from: "lotm.fool.s09"), 9)
        XCTAssertEqual(IdentityRoleResolver.sequenceNumber(from: "lotm.fool.s00"), 0)
        XCTAssertNil(IdentityRoleResolver.sequenceNumber(from: "lotm.celestial-worthy"))

        XCTAssertEqual(
            IdentityRoleResolver.role(for: "lotm.fool.s09", identityKind: .character),
            .identityCard
        )
        XCTAssertEqual(
            IdentityRoleResolver.role(for: "lotm.fool.s07", identityKind: .archetype),
            .archetypeCard
        )
        XCTAssertEqual(
            IdentityRoleResolver.role(for: "lotm.fool.s00", identityKind: .character),
            .trueGod
        )
        XCTAssertEqual(
            IdentityRoleResolver.role(for: "lotm.key-of-light", identityKind: .character),
            .aboveSequence
        )
        XCTAssertEqual(
            [IdentityRole.identityCard, .archetypeCard, .trueGod, .aboveSequence].map(\.label),
            ["身份卡", "原型卡", "真神", "序列之上"]
        )
    }

    func testFateEntryCopyFollowsIdentityRole() {
        let klein = CardIdentity(
            cardID: "lotm.fool.s09.klein-moretti.tingen-01",
            slotID: "lotm.fool.s09",
            displayName: "克莱恩·莫雷蒂",
            sequenceName: "序列 9 · 占卜家",
            contentStatus: .proposed,
            identityKind: .character,
            characterID: "klein-moretti",
            identitySliceID: "klein.s09.tingen"
        )
        let archetype = CardIdentity(
            cardID: "lotm.fool.s07.archetype",
            slotID: "lotm.fool.s07",
            displayName: "序列 7 原型",
            sequenceName: "序列 7",
            contentStatus: .unfilled,
            identityKind: .archetype,
            characterID: nil,
            identitySliceID: nil
        )
        let celestial = CardIdentity(
            cardID: "lotm.celestial-worthy.primordial-01",
            slotID: "lotm.celestial-worthy",
            displayName: "福生玄黄天尊",
            sequenceName: "序列之上 · 诡秘之主",
            contentStatus: .proposed,
            identityKind: .character,
            characterID: "celestial-worthy",
            identitySliceID: "celestial-worthy.primordial"
        )

        let characterEntry = FateEntryResolver.entry(for: klein)
        XCTAssertEqual(characterEntry.kind, .character(name: "克莱恩·莫雷蒂"))
        XCTAssertEqual(characterEntry.primaryTitle, "进入克莱恩·莫雷蒂")
        XCTAssertTrue(characterEntry.isAvailable)
        XCTAssertFalse(characterEntry.kind.inheritanceNote.isEmpty)

        let archetypeEntry = FateEntryResolver.entry(for: archetype)
        XCTAssertEqual(archetypeEntry.kind, .archetype)
        XCTAssertEqual(archetypeEntry.primaryTitle, "以该序列创造一个人")

        let transcendentEntry = FateEntryResolver.entry(for: celestial)
        XCTAssertEqual(transcendentEntry.kind, .transcendent(name: "福生玄黄天尊"))
        XCTAssertEqual(transcendentEntry.primaryTitle, "以祂的尺度介入世界")
    }

    func testFateEntryIsBlockedWithoutAValidIdentityBinding() {
        let broken = CardIdentity(
            cardID: "lotm.fool.s09.broken",
            slotID: "lotm.fool.s09",
            displayName: "缺少档案的身份",
            sequenceName: "序列 9",
            contentStatus: .unfilled,
            identityKind: .character,
            characterID: nil,
            identitySliceID: nil
        )

        let entry = FateEntryResolver.entry(for: broken)

        XCTAssertFalse(entry.isAvailable)
        XCTAssertNotNil(entry.blocker)
        XCTAssertEqual(entry.availabilityNote, entry.blocker)
    }

    func testFateEntryPrefersContinuingAnActiveEpisode() {
        let identity = CardIdentity(
            cardID: "lotm.fool.s09.klein-moretti.tingen-01",
            slotID: "lotm.fool.s09",
            displayName: "克莱恩·莫雷蒂",
            sequenceName: "序列 9 · 占卜家",
            contentStatus: .proposed,
            identityKind: .character,
            characterID: "klein-moretti",
            identitySliceID: "klein.s09.tingen"
        )

        let entry = FateEntryResolver.entry(for: identity, activeEpisodeID: "fate-1")

        XCTAssertEqual(entry.primaryTitle, "继续这段命运")
        XCTAssertEqual(entry.secondaryTitle, "另起一段")
    }

    // MARK: - 命运生成只暴露可见种子

    func testVisibleSeedExposesExactlyFourNarrativeFields() {
        let seed = FateVisibleSeed(
            time: "深夜",
            place: "廷根",
            anomaly: "一个已经死去，却仍然拥有明天的人",
            pressure: "天亮以前"
        )

        XCTAssertEqual(seed.visibleFields.map(\.label), ["时间", "地点", "异常", "压力"])
        XCTAssertEqual(seed.visibleFields.map(\.id), ["time", "place", "anomaly", "pressure"])
        XCTAssertEqual(seed.visibleFields.count, 4)
    }

    // MARK: - 秘密

    func testHiddenSecretsNeverCarryTheirAnswer() {
        let hidden = FateSecretRecord(
            id: "secret-1",
            label: "雨夜里真正等在街角的是什么",
            state: .hidden,
            revealedText: "答案不应该出现在这里"
        )
        let revealed = FateSecretRecord(
            id: "secret-2",
            label: "委托人的名字是假的",
            state: .revealed,
            revealedText: "名册上根本没有这个人。"
        )

        XCTAssertNil(hidden.revealedText)
        XCTAssertEqual(hidden.displayText, "这件事还没有被弄明白。")
        XCTAssertEqual(revealed.revealedText, "名册上根本没有这个人。")
    }

    func testEpisodeSecretSummaryCountsOnlyRevealedSecrets() {
        let episode = EpisodeRecord(
            id: "fate-1",
            cardID: "card-1",
            protagonistCharacterID: "klein-moretti",
            protagonistName: "克莱恩·莫雷蒂",
            title: "雨夜的委托",
            timeLabel: "十月 · 深夜",
            locationLabel: "廷根",
            state: .inProgress,
            secrets: [
                FateSecretRecord(id: "s1", label: "一", state: .revealed, revealedText: "已揭开"),
                FateSecretRecord(id: "s2", label: "二", state: .partial),
                FateSecretRecord(id: "s3", label: "三", state: .hidden)
            ],
            listeningNote: "声音会补齐。"
        )

        XCTAssertEqual(episode.revealedSecretCount, 1)
        XCTAssertEqual(episode.totalSecretCount, 3)
        XCTAssertEqual(episode.secretSummary, "已揭开 1 / 3 个秘密")
    }

    // MARK: - 阅读模式的段落来源

    func testReadingModePrefersTheFatesOwnPassages() {
        let episode = EpisodeRecord(
            id: "fate-1",
            cardID: "card-1",
            protagonistCharacterID: "klein-moretti",
            protagonistName: "克莱恩·莫雷蒂",
            title: "雨夜的委托",
            timeLabel: "十月 · 深夜",
            locationLabel: "廷根",
            state: .inProgress,
            recordedPassages: [
                EpisodePassage(id: "p1", title: "第一段 · 雨夜的敲门声", text: "有人敲门。")
            ],
            listeningNote: "声音会补齐。"
        )

        let material = EpisodeReadingResolver.resolve(
            episode: episode,
            cardChapters: [Self.chapter(index: 1, title: "第一章 · 先把眼前看清")]
        )

        XCTAssertEqual(material.source, .episode)
        XCTAssertEqual(material.passages.map(\.title), ["第一段 · 雨夜的敲门声"])
    }

    func testReadingModeFallsBackToCardNarrativeWithAnExplicitSource() {
        let episode = EpisodeRecord(
            id: "fate-2",
            cardID: "card-1",
            protagonistCharacterID: "klein-moretti",
            protagonistName: "克莱恩·莫雷蒂",
            title: "雨夜的委托",
            timeLabel: "十月 · 深夜",
            locationLabel: "廷根",
            state: .inProgress,
            listeningNote: "声音会补齐。"
        )

        let material = EpisodeReadingResolver.resolve(
            episode: episode,
            cardChapters: [
                Self.chapter(index: 1, title: "第一章 · 先把眼前看清"),
                Self.chapter(index: 2, title: "第二章 · 灵摆之外的核验")
            ]
        )

        XCTAssertEqual(material.source, .cardNarrative)
        XCTAssertEqual(material.passages.map(\.title), ["第一章 · 先把眼前看清", "第二章 · 灵摆之外的核验"])
    }

    func testReadingModeStaysEmptyWhenNeitherSourceHasPassages() {
        let episode = EpisodeRecord(
            id: "fate-3",
            cardID: "card-1",
            protagonistCharacterID: "klein-moretti",
            protagonistName: "克莱恩·莫雷蒂",
            title: "雨夜的委托",
            timeLabel: "十月 · 深夜",
            locationLabel: "廷根",
            state: .inProgress,
            listeningNote: "声音会补齐。"
        )

        let material = EpisodeReadingResolver.resolve(episode: episode, cardChapters: [])

        XCTAssertEqual(material.source, .none)
        XCTAssertTrue(material.isEmpty)
    }

    // MARK: - 选择记录

    private static func chapter(index: Int, title: String) -> StoryChapter {
        StoryChapter(
            id: "chapter-\(index)",
            title: title,
            line: NarrativeLine(
                id: "line-\(index)",
                kind: .story,
                text: "第 \(index) 章的正文。",
                sourceKind: .original,
                review: .draft,
                contentDigest: "digest-\(index)"
            )
        )
    }

    func testChoiceRecordCarriesActionStrategyAndCost() {
        let choice = FateChoiceRecord(
            id: "choice-1",
            index: 1,
            action: "重新进行占卜",
            intent: .investigate,
            cost: "灵性消耗",
            outcome: "结果指向了一件明天才会发生的事。"
        )

        XCTAssertEqual(choice.displayLabel, "重新进行占卜 · 信息优先")
        XCTAssertEqual(FateIntent.allCases.count, 11)
        XCTAssertFalse(choice.cost.isEmpty)
    }

    // MARK: - 世界快照

    func testWorldSnapshotDerivesSectionsFromRecords() {
        let snapshot = makeSnapshot()

        XCTAssertEqual(snapshot.recentEvents(limit: 2).map(\.id), ["e1", "e2"])
        XCTAssertEqual(snapshot.unresolvedEvents.map(\.id), ["e1"])
        XCTAssertEqual(snapshot.activeEpisodes.map(\.id), ["ep-active"])
        XCTAssertEqual(snapshot.completedEpisodes.map(\.id), ["ep-done"])
        XCTAssertEqual(snapshot.latestCompletedEpisodes(limit: 1).map(\.id), ["ep-done"])
        XCTAssertEqual(snapshot.recentlyActiveCharacters(limit: 1).map(\.id), ["klein"])
        XCTAssertEqual(snapshot.experienceLabel(forCardID: "card-1"), "有一段进行中的命运")
        XCTAssertEqual(snapshot.experienceLabel(forCardID: "card-2"), "已有 1 段历史")
        XCTAssertEqual(snapshot.experienceLabel(forCardID: "card-3"), "未进入世界")
        XCTAssertEqual(snapshot.events(forEpisodeID: "ep-done").map(\.id), ["e2"])
        XCTAssertTrue(snapshot.events(forEpisodeID: "ep-active").isEmpty)
    }

    func testWorldSnapshotEmptyStateIsRecognisedAsEmpty() {
        let snapshot = WorldSnapshot(
            worldName: "空世界",
            calendar: WorldCalendarStamp(eraLabel: "第一纪", dateLabel: "某日"),
            worldline: WorldlineStamp(id: "main", label: "主线"),
            dataStatus: .sample
        )

        XCTAssertTrue(snapshot.isEmpty)
        XCTAssertEqual(snapshot.calendar.displayLabel, "第一纪 · 某日")
        XCTAssertEqual(snapshot.worldline.displayLabel, "主线")
    }

    func testSampleStatusIsLabelledAndExplained() {
        XCTAssertEqual(WorldDataStatus.sample.label, "示例")
        XCTAssertNotNil(WorldDataStatus.sample.note)
        XCTAssertEqual(WorldDataStatus.verified.label, "已核验")
        XCTAssertNil(WorldDataStatus.verified.note)
    }

    func testWorldSummaryCopyUsesPlainSentences() {
        XCTAssertEqual(WorldSummaryCopy.activeFateLine(count: 0), "此刻没有人正在经历什么。")
        XCTAssertEqual(WorldSummaryCopy.activeFateLine(count: 2), "有 2 段命运还停在中途。")
        XCTAssertEqual(WorldSummaryCopy.unresolvedLine(count: 1), "有 1 件事还没有结论。")
    }

    // MARK: - 关系来源

    func testRelationshipOriginSeparatesCanonFromLocalExperience() {
        let canon = CharacterRelationshipRecord(
            id: "r1",
            counterpartName: "班森·莫雷蒂",
            axis: .affection,
            summary: "家人。",
            origin: .canon
        )
        let local = CharacterRelationshipRecord(
            id: "r2",
            counterpartName: "档案馆管理员 · 露西娅",
            axis: .trust,
            summary: "她记住了你的名字。",
            origin: .localExperience,
            changedByEpisodeID: "ep-done"
        )

        XCTAssertEqual(canon.origin.label, "原著事实")
        XCTAssertEqual(local.origin.label, "本机经历")
        XCTAssertEqual(local.changedByEpisodeID, "ep-done")
        XCTAssertEqual(RelationshipAxis.allCases.count, 8)
    }

    // MARK: - Fixtures

    private func makeSnapshot() -> WorldSnapshot {
        let event1 = WorldEventRecord(
            id: "e1",
            title: "悬着的事",
            detail: "还没有结论。",
            scope: .personal,
            timeLabel: "十月 · 深夜",
            locationLabel: "廷根",
            isUnresolved: true,
            involvedCharacterIDs: ["klein"],
            relatedEpisodeIDs: ["ep-active"]
        )
        let event2 = WorldEventRecord(
            id: "e2",
            title: "有了结果的事",
            detail: "留下了一页纸。",
            scope: .local,
            timeLabel: "十月 · 前夜",
            locationLabel: "廷根 · 档案馆",
            isUnresolved: false,
            relatedEpisodeIDs: ["ep-done"]
        )
        let character = CharacterProfile(
            id: "klein",
            displayName: "克莱恩·莫雷蒂",
            pathwayLabel: "愚者途径",
            sequenceLabel: "序列 9 · 占卜家",
            existenceKind: .canon,
            subjectPronoun: "他",
            cardIDs: ["card-1", "card-2"],
            lastSeenLabel: "昨夜 · 廷根",
            lastSeenOrder: 0
        )
        let activeEpisode = EpisodeRecord(
            id: "ep-active",
            cardID: "card-1",
            protagonistCharacterID: "klein",
            protagonistName: "克莱恩·莫雷蒂",
            title: "雨夜的委托",
            timeLabel: "十月 · 深夜",
            locationLabel: "廷根",
            state: .inProgress,
            listeningNote: "声音会补齐。"
        )
        let doneEpisode = EpisodeRecord(
            id: "ep-done",
            cardID: "card-2",
            protagonistCharacterID: "klein",
            protagonistName: "克莱恩·莫雷蒂",
            title: "档案馆的第七个抽屉",
            timeLabel: "十月 · 前夜",
            locationLabel: "廷根 · 市档案馆",
            state: .completed,
            closureKind: .open,
            worldImpactEventIDs: ["e2"],
            listeningNote: "声音已经保留。",
            costSummary: "留下了一个活着的证人。"
        )
        return WorldSnapshot(
            worldName: "测试世界",
            calendar: WorldCalendarStamp(eraLabel: "第五纪", dateLabel: "某年 十月"),
            worldline: WorldlineStamp(id: "main", label: "主线"),
            dataStatus: .sample,
            events: [event1, event2],
            characters: [character],
            episodes: [activeEpisode, doneEpisode]
        )
    }
}
