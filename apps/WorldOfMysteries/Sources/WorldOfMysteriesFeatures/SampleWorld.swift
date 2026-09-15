import WorldOfMysteriesCore

/// 客户端世界外壳的**合成示例世界**（PRD §7.1）。
///
/// - 这里的时间、事件、经历与关系都是为验证界面而写的示例数据，**不是**核验过的原著事实；
///   世界首页会持续显示「示例」标记与说明（`WorldDataStatus.sample`）。
/// - 数据只存在于 App 进程内，不写入 `pathways/**`、`canon.json`、`artifacts/**` 或任何批准记录。
/// - 人物档案按 `character_id` 聚合卡牌；九位「序列之上」存在没有本机经历，保持「尚未出现」。
enum SampleWorld {
    static let kleinMorettiID = "klein-moretti"
    static let kleinTingenCardID = "lotm.fool.s09.klein-moretti.tingen-01"
    static let mrFoolCardID = "lotm.fool.s00.klein-moretti.mr-fool-01"
    static let inProgressEpisodeID = "fate.klein.tingen-01"
    static let archiveEpisodeID = "fate.klein.tingen-02"
    static let foolEpisodeID = "fate.fool.s00-01"

    static func snapshot(cards: [AlbumCard] = DemoLibrary.cards) -> WorldSnapshot {
        WorldSnapshot(
            worldName: "本机示例世界",
            calendar: WorldCalendarStamp(eraLabel: "第五纪", dateLabel: "某年 十月"),
            worldline: WorldlineStamp(id: "worldline-main", label: "主线"),
            dataStatus: .sample,
            narratorLine: "这里的经历不是原著的情节，但会一直留在你的世界里。",
            events: events,
            locationChanges: locationChanges,
            characters: characters(cards: cards),
            episodes: episodes
        )
    }

    // MARK: - 人物

    static func characters(cards: [AlbumCard]) -> [CharacterProfile] {
        var profiles: [CharacterProfile] = [kleinMorettiProfile(cards: cards)]
        profiles.append(contentsOf: transcendentProfiles(cards: cards))
        return profiles
    }

    static func kleinMorettiProfile(cards: [AlbumCard]) -> CharacterProfile {
        let cardIDs = cards
            .filter { $0.identity.characterID == kleinMorettiID }
            .map(\.id)
        return CharacterProfile(
            id: kleinMorettiID,
            displayName: "克莱恩·莫雷蒂",
            pathwayLabel: "愚者途径",
            sequenceLabel: "序列 9 · 占卜家 → 序列 0 · 真神",
            existenceKind: .canon,
            subjectPronoun: "他",
            cardIDs: cardIDs,
            knowledgeFacts: [
                CharacterKnowledgeFact(
                    id: "klein.knowledge.streets",
                    content: "深夜的廷根哪些街区还能买到东西、哪些门不该敲。",
                    scope: .publicKnowledge
                ),
                CharacterKnowledgeFact(
                    id: "klein.knowledge.pathway",
                    content: "占卜家途径前几个序列的常识，以及它们各自的禁忌。",
                    scope: .pathway
                ),
                CharacterKnowledgeFact(
                    id: "klein.knowledge.origin",
                    content: "自己的某些来历，连最亲近的人也没有听过。",
                    scope: .secret
                )
            ],
            relationships: [
                CharacterRelationshipRecord(
                    id: "klein.relation.benson",
                    counterpartName: "班森·莫雷蒂",
                    axis: .affection,
                    summary: "家人；在这个世界里他仍然要按时回家。",
                    origin: .canon
                ),
                CharacterRelationshipRecord(
                    id: "klein.relation.melissa",
                    counterpartName: "梅丽莎·莫雷蒂",
                    axis: .affection,
                    summary: "家人；她不知道深夜里发生了什么。",
                    origin: .canon
                ),
                CharacterRelationshipRecord(
                    id: "klein.relation.lucia",
                    counterpartName: "档案馆管理员 · 露西娅",
                    axis: .trust,
                    summary: "她替你合上过一本不该被翻开的案卷，也记住了你的名字。",
                    origin: .localExperience,
                    changedByEpisodeID: archiveEpisodeID
                ),
                CharacterRelationshipRecord(
                    id: "klein.relation.carlisle",
                    counterpartName: "旧书商 · 卡莱尔",
                    axis: .debt,
                    summary: "那桩委托之前，他还欠你一次解释。",
                    origin: .localExperience,
                    changedByEpisodeID: archiveEpisodeID
                )
            ],
            lastSeenLabel: "昨夜 · 廷根 · 明斯特街",
            lastSeenOrder: 0,
            profileNote: "同一个人的不同时期：序列 9 的廷根时期与序列 0 的愚者先生。原著里的他另有自己的故事。"
        )
    }

    /// 九位「序列之上」存在来自非序列卡位；界面上用「祂」，且没有本机经历。
    static func transcendentProfiles(cards: [AlbumCard]) -> [CharacterProfile] {
        cards.compactMap { card in
            let identity = card.identity
            guard let characterID = identity.characterID,
                  IdentityRoleResolver.role(for: identity) == .aboveSequence
            else {
                return nil
            }
            return CharacterProfile(
                id: characterID,
                displayName: identity.displayName,
                pathwayLabel: "序列之上",
                sequenceLabel: ArchiveCopy.sequenceName(for: identity.sequenceName),
                existenceKind: .transcendent,
                subjectPronoun: "祂",
                cardIDs: [card.id],
                knowledgeFacts: [
                    CharacterKnowledgeFact(
                        id: "\(characterID).knowledge.own-domain",
                        content: "\(ArchiveCopy.sequenceName(for: identity.sequenceName)) 所对应的权柄与概念。",
                        scope: .cosmic
                    )
                ],
                relationships: [],
                lastSeenLabel: nil,
                lastSeenOrder: nil,
                profileNote: "这个位格不使用普通人的选择方式：可以决定的是是否回应、以及让哪种因果进入现实。"
            )
        }
    }

    // MARK: - 世界事件

    static let events: [WorldEventRecord] = [
        WorldEventRecord(
            id: "event.tingen-commission",
            title: "深夜的一桩委托被接下了",
            detail: "一位占卜者在明斯特街接下了委托；他当时还不知道结果会指向明天。",
            scope: .personal,
            timeLabel: "十月 · 深夜",
            locationLabel: "廷根 · 明斯特街",
            isUnresolved: true,
            involvedCharacterIDs: [kleinMorettiID],
            relatedEpisodeIDs: [inProgressEpisodeID]
        ),
        WorldEventRecord(
            id: "event.archive-missing-page",
            title: "市档案馆少了一页记录",
            detail: "被抽走的那一页属于一份多年前的案卷，抽屉里留下了一道空的印子。",
            scope: .local,
            timeLabel: "十月 · 前夜",
            locationLabel: "廷根 · 市档案馆",
            isUnresolved: true,
            involvedCharacterIDs: [kleinMorettiID],
            relatedEpisodeIDs: [archiveEpisodeID]
        ),
        WorldEventRecord(
            id: "event.midnight-stall",
            title: "旧书市多了一个只在午夜开张的摊位",
            detail: "摊主收的既不是钱也不是书，而是一些不方便写在纸上的东西。",
            scope: .local,
            timeLabel: "十月 · 初",
            locationLabel: "贝克兰德 · 东区旧书市",
            isUnresolved: true
        ),
        WorldEventRecord(
            id: "event.prayer-answered",
            title: "某个没有记录的夜晚，有人得到了一次回应",
            detail: "祈祷的人得到了一个模糊的答案，并且记住了这个答案。",
            scope: .major,
            timeLabel: "十月 · 某个夜晚",
            locationLabel: "地点没有留下",
            isUnresolved: false,
            relatedEpisodeIDs: [foolEpisodeID]
        ),
        WorldEventRecord(
            id: "event.rainy-house",
            title: "一间旧宅在雨夜之后换了主人",
            detail: "没有人见过新主人，但灯每天都在同一个时辰亮起来。",
            scope: .relationship,
            timeLabel: "九月 · 末",
            locationLabel: "廷根 · 铁十字街",
            isUnresolved: false
        )
    ]

    static let locationChanges: [WorldLocationChange] = [
        WorldLocationChange(
            id: "location.muenster-27",
            locationLabel: "廷根 · 明斯特街 27 号",
            changeSummary: "门锁被换过，二楼的窗前多了一盏不熄的灯。",
            changedByEpisodeID: archiveEpisodeID
        ),
        WorldLocationChange(
            id: "location.east-book-market",
            locationLabel: "贝克兰德 · 东区旧书市",
            changeSummary: "午夜摊位背后多了一道没有招牌的门。",
            changedByEpisodeID: nil
        )
    ]

    // MARK: - 命运

    static let inProgressSeed = FateVisibleSeed(
        time: "深夜",
        place: "廷根 · 明斯特街",
        anomaly: "一个已经死去，却仍然拥有明天的人",
        pressure: "天亮以前"
    )

    static let episodes: [EpisodeRecord] = [
        EpisodeRecord(
            id: inProgressEpisodeID,
            cardID: kleinTingenCardID,
            protagonistCharacterID: kleinMorettiID,
            protagonistName: "克莱恩·莫雷蒂",
            title: "雨夜的委托",
            timeLabel: "十月 · 深夜",
            locationLabel: "廷根 · 明斯特街",
            state: .inProgress,
            visibleSeed: inProgressSeed,
            recordedPassages: [
                EpisodePassage(
                    id: "\(inProgressEpisodeID).passage-1",
                    title: "第一段 · 雨夜的敲门声",
                    text: "雨没有要停的意思。有人敲门，把一件不该在雨夜出现的事交到你手上：一个已经死去、却仍然拥有明天的人。"
                ),
                EpisodePassage(
                    id: "\(inProgressEpisodeID).passage-2",
                    title: "第二段 · 明天才会发生的事",
                    text: "你重新摆了灵摆。指针没有指向凶手，而是指向了明天——结果指向了一件明天才会发生的事，而你的灵性已经接近枯竭。"
                )
            ],
            choicePath: [
                FateChoiceRecord(
                    id: "\(inProgressEpisodeID).choice-1",
                    index: 1,
                    action: "重新进行占卜",
                    intent: .investigate,
                    cost: "灵性消耗",
                    outcome: "结果指向了一件明天才会发生的事。"
                )
            ],
            secrets: [
                FateSecretRecord(
                    id: "\(inProgressEpisodeID).secret-1",
                    label: "委托人的名字是假的",
                    state: .revealed,
                    revealedText: "名册上根本没有这个人，但笔迹是真实的。"
                ),
                FateSecretRecord(
                    id: "\(inProgressEpisodeID).secret-2",
                    label: "那具尸体与这条街有关",
                    state: .partial
                ),
                FateSecretRecord(
                    id: "\(inProgressEpisodeID).secret-3",
                    label: "雨夜里真正等在街角的是什么",
                    state: .hidden
                ),
                FateSecretRecord(
                    id: "\(inProgressEpisodeID).secret-4",
                    label: "委托人究竟想让你看见什么",
                    state: .hidden
                )
            ],
            stateNotes: [
                NarrativeStateNote(
                    id: "\(inProgressEpisodeID).note-1",
                    text: "你的灵性已经接近枯竭。",
                    sourceLabel: "来自：第 1 次抉择「重新进行占卜」"
                ),
                NarrativeStateNote(
                    id: "\(inProgressEpisodeID).note-2",
                    text: "有人开始怀疑你的真实身份。",
                    sourceLabel: "来自：这一次占卜留下的痕迹"
                )
            ],
            listeningNote: "这一段命运还在进行中，声音会随着叙述补齐。",
            divergesWorldline: false
        ),
        EpisodeRecord(
            id: archiveEpisodeID,
            cardID: kleinTingenCardID,
            protagonistCharacterID: kleinMorettiID,
            protagonistName: "克莱恩·莫雷蒂",
            title: "档案馆的第七个抽屉",
            timeLabel: "十月 · 前夜",
            locationLabel: "廷根 · 市档案馆",
            state: .completed,
            closureKind: .open,
            recordedPassages: [
                EpisodePassage(
                    id: "\(archiveEpisodeID).passage-1",
                    title: "第一段 · 少掉的那一页",
                    text: "你翻开了那本案卷。名册上少的那一页确实被人动过，缺口很齐，像是有人当着灯慢慢撕下来的。"
                ),
                EpisodePassage(
                    id: "\(archiveEpisodeID).passage-2",
                    title: "第二段 · 借书证上的名字",
                    text: "你把身份藏在借书证后面。管理员替你合上案卷，也记住了你的名字——从这一刻起，档案馆里有别人知道你来过。"
                ),
                EpisodePassage(
                    id: "\(archiveEpisodeID).passage-3",
                    title: "第三段 · 陌生人开出的条件",
                    text: "你把一半真相交给那位陌生人。他给了你一把钥匙，也留下了一个条件：有些抽屉，打开之后要自己负责合上。"
                ),
                EpisodePassage(
                    id: "\(archiveEpisodeID).passage-4",
                    title: "第四段 · 空着的第七格",
                    text: "仪式照常举行，只是你不在场。案卷合上了，抽屉的第七格仍然是空的，像一句没有写完的话。"
                )
            ],
            choicePath: [
                FateChoiceRecord(
                    id: "\(archiveEpisodeID).choice-1",
                    index: 1,
                    action: "去翻那本案卷",
                    intent: .investigate,
                    cost: "时间成本",
                    outcome: "你确认名册上少的那一页确实被人动过。"
                ),
                FateChoiceRecord(
                    id: "\(archiveEpisodeID).choice-2",
                    index: 2,
                    action: "把身份藏在借书证后面",
                    intent: .conceal,
                    cost: "留下痕迹",
                    outcome: "管理员记住了你的名字。"
                ),
                FateChoiceRecord(
                    id: "\(archiveEpisodeID).choice-3",
                    index: 3,
                    action: "把一半真相交给那位陌生人",
                    intent: .cooperate,
                    cost: "共享秘密",
                    outcome: "他给了你一把钥匙，也留下了一个条件。"
                ),
                FateChoiceRecord(
                    id: "\(archiveEpisodeID).choice-4",
                    index: 4,
                    action: "不参加那场仪式",
                    intent: .retreat,
                    cost: "错过时机",
                    outcome: "仪式照常举行，只是你不在场。"
                ),
                FateChoiceRecord(
                    id: "\(archiveEpisodeID).choice-5",
                    index: 5,
                    action: "先把人送出去",
                    intent: .protect,
                    cost: "自己被留下",
                    outcome: "那个人活了下来，你成了唯一还留在里面的人。"
                ),
                FateChoiceRecord(
                    id: "\(archiveEpisodeID).choice-6",
                    index: 6,
                    action: "让这件事留在城市里",
                    intent: .observe,
                    cost: "没有结论",
                    outcome: "案卷合上了，抽屉的第七格仍然是空的。"
                )
            ],
            secrets: [
                FateSecretRecord(
                    id: "\(archiveEpisodeID).secret-1",
                    label: "那一页上写的是谁的名字",
                    state: .revealed,
                    revealedText: "一个在很多年前就该被划掉的名字。"
                ),
                FateSecretRecord(
                    id: "\(archiveEpisodeID).secret-2",
                    label: "是谁抽走了那一页",
                    state: .revealed,
                    revealedText: "是那个每天开门的人，她只是照别人的话做了。"
                ),
                FateSecretRecord(
                    id: "\(archiveEpisodeID).secret-3",
                    label: "钥匙能打开什么",
                    state: .revealed,
                    revealedText: "第七个抽屉，那个本该是空的抽屉。"
                ),
                FateSecretRecord(
                    id: "\(archiveEpisodeID).secret-4",
                    label: "仪式上到底发生了什么",
                    state: .revealed,
                    revealedText: "有人替你把那一步走完了，代价不由你支付。"
                ),
                FateSecretRecord(
                    id: "\(archiveEpisodeID).secret-5",
                    label: "陌生人要的那个条件",
                    state: .partial
                ),
                FateSecretRecord(
                    id: "\(archiveEpisodeID).secret-6",
                    label: "抽屉第七格原本该装什么",
                    state: .hidden
                ),
                FateSecretRecord(
                    id: "\(archiveEpisodeID).secret-7",
                    label: "谁在名册上等着被找到",
                    state: .hidden
                )
            ],
            relationshipChanges: [
                RelationshipChangeRecord(
                    id: "\(archiveEpisodeID).relation-1",
                    counterpartName: "档案馆管理员 · 露西娅",
                    axis: .trust,
                    summary: "她替你合上过一本不该被翻开的案卷，也因此把自己放在了危险里。",
                    episodeID: archiveEpisodeID,
                    episodeTitle: "档案馆的第七个抽屉"
                ),
                RelationshipChangeRecord(
                    id: "\(archiveEpisodeID).relation-2",
                    counterpartName: "旧书商 · 卡莱尔",
                    axis: .debt,
                    summary: "他欠你一次解释，你欠他一次说明。",
                    episodeID: archiveEpisodeID,
                    episodeTitle: "档案馆的第七个抽屉"
                )
            ],
            stateNotes: [
                NarrativeStateNote(
                    id: "\(archiveEpisodeID).note-1",
                    text: "有人开始在档案里寻找你的名字。",
                    sourceLabel: "来自：第 2 次抉择「把身份藏在借书证后面」"
                )
            ],
            worldImpactEventIDs: ["event.archive-missing-page"],
            listeningNote: "这段命运的声音已经完整保留，可以从头听一遍。",
            costSummary: "你换来了一个活着的证人；代价是从此有人在档案馆里记得你的名字。",
            divergesWorldline: false
        ),
        EpisodeRecord(
            id: foolEpisodeID,
            cardID: mrFoolCardID,
            protagonistCharacterID: kleinMorettiID,
            protagonistName: "愚者先生",
            title: "一次无人应答的回应",
            timeLabel: "十月 · 某个没有记录的夜晚",
            locationLabel: "灰雾之上",
            state: .completed,
            closureKind: .open,
            recordedPassages: [
                EpisodePassage(
                    id: "\(foolEpisodeID).passage-1",
                    title: "第一段 · 灰雾之上的一声祈祷",
                    text: "灰雾之上，有一声祈祷落下来。它没有说清楚要什么，只反复念着同一个人的名字。"
                ),
                EpisodePassage(
                    id: "\(foolEpisodeID).passage-2",
                    title: "第二段 · 没有留下名字的回应",
                    text: "祂回应了一声。一次回应改动了某个人的一生；而祂没有留下名字，也没有解释为什么是那一天。"
                )
            ],
            choicePath: [
                FateChoiceRecord(
                    id: "\(foolEpisodeID).choice-1",
                    index: 1,
                    action: "回应了一声祈祷",
                    intent: .cooperate,
                    cost: "让某件事进入现实",
                    outcome: "祈祷的人得到了一个模糊的答案，并且记住了这个答案。"
                ),
                FateChoiceRecord(
                    id: "\(foolEpisodeID).choice-2",
                    index: 2,
                    action: "没有让那条线继续延伸",
                    intent: .conceal,
                    cost: "留下一个悬空的结局",
                    outcome: "有人的一生就此停在了一个没有下文的夜里。"
                )
            ],
            secrets: [
                FateSecretRecord(
                    id: "\(foolEpisodeID).secret-1",
                    label: "那次回应落到了谁的身上",
                    state: .revealed,
                    revealedText: "一个不在任何名册上的人。"
                ),
                FateSecretRecord(
                    id: "\(foolEpisodeID).secret-2",
                    label: "祂为什么选择在那一天回应",
                    state: .hidden
                ),
                FateSecretRecord(
                    id: "\(foolEpisodeID).secret-3",
                    label: "那条被停住的线原本会走到哪里",
                    state: .hidden
                )
            ],
            stateNotes: [
                NarrativeStateNote(
                    id: "\(foolEpisodeID).note-1",
                    text: "你在现实里留下了一道很淡的痕迹。",
                    sourceLabel: "来自：第 1 次抉择「回应了一声祈祷」"
                )
            ],
            worldImpactEventIDs: ["event.prayer-answered"],
            listeningNote: "这一段的声音还没有准备；现在可以安静阅读。",
            costSummary: "一次回应改动了某个人的一生；而祂没有留下名字。",
            divergesWorldline: false
        )
    ]
}

/// 命运生成界面的可见种子（PRD §3.4）：按卡的位格给不同的入口。
enum FateSeedLibrary {
    /// 「换一个入口」在同一个位格尺度内换一个可见处境，不改变卡的语义。
    static func seeds(for entry: FateEntry, card: AlbumCard) -> [FateVisibleSeed] {
        if card.identity.cardID == SampleWorld.kleinTingenCardID {
            return [
                SampleWorld.inProgressSeed,
                FateVisibleSeed(
                    time: "第二天清晨",
                    place: "廷根 · 市档案馆",
                    anomaly: "名册上多出了一个昨天还不存在的名字",
                    pressure: "档案馆开门之前"
                )
            ]
        }
        switch entry.role {
        case .aboveSequence, .trueGod:
            return [
                FateVisibleSeed(
                    time: "不在任何历法里",
                    place: card.identity.displayName == "愚者先生" ? "灰雾之上" : "世界之外的高处",
                    anomaly: "有人向一个不该被念出的名字祈祷",
                    pressure: "回应与否，都会留下痕迹"
                ),
                FateVisibleSeed(
                    time: "某个即将被改写的时刻",
                    place: "一条已经存在的因果线上",
                    anomaly: "一件本该固定发生的事出现了第二种可能",
                    pressure: "这条线还连着别人"
                )
            ]
        case .archetypeCard:
            return [
                FateVisibleSeed(
                    time: "一个平常的白天",
                    place: "还没有选定的城市",
                    anomaly: "一条途径正在寻找它的下一个使用者",
                    pressure: "魔药不会等人"
                ),
                FateVisibleSeed(
                    time: "一个不太平的夜里",
                    place: "你熟悉的那条街",
                    anomaly: "有人在你面前用出了这一途径的能力",
                    pressure: "他看见你的时间只有几秒"
                )
            ]
        case .identityCard:
            return [
                FateVisibleSeed(
                    time: "某个夜里",
                    place: "还没有确定的街区",
                    anomaly: "一件本来不该有人知道的事被说漏了嘴",
                    pressure: "明天之前"
                ),
                FateVisibleSeed(
                    time: "午后",
                    place: "常去的那家店",
                    anomaly: "一个熟悉的客人换了一副陌生的说法",
                    pressure: "他今天就要离开这座城市"
                )
            ]
        }
    }

    static func seed(for entry: FateEntry, card: AlbumCard) -> FateVisibleSeed {
        seeds(for: entry, card: card)[0]
    }

    static func genesisPresentation(for card: AlbumCard, entry: FateEntry) -> FateGenesisPresentation {
        FateGenesisPresentation(
            cardID: card.identity.cardID,
            title: "将要开始的命运",
            seeds: seeds(for: entry, card: card),
            entryNote: entry.kind.inheritanceNote
        )
    }
}

/// 命运生成界面呈现的全部内容；幕后真相、秘密数量、NPC 目标与结局集合都不在其中。
struct FateGenesisPresentation: Hashable {
    let cardID: String
    let title: String
    let seeds: [FateVisibleSeed]
    let entryNote: String

    var seedCount: Int {
        seeds.count
    }

    func seed(at index: Int) -> FateVisibleSeed {
        guard !seeds.isEmpty else {
            return FateVisibleSeed(time: "", place: "", anomaly: "", pressure: "")
        }
        return seeds[index % seeds.count]
    }

    func visibleFields(at index: Int) -> [FateVisibleField] {
        seed(at: index).visibleFields
    }

    var disclosureNote: String {
        "这里只显示你已经能察觉的部分；真相会在过程里慢慢展开。"
    }

    var primaryActionTitle: String {
        "编织命运"
    }

    var secondaryActionTitle: String {
        "换一个入口"
    }

}
