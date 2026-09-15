import WorldOfMysteriesCore

/// 世界外壳的用户可见文案（PRD §附录 B）。
///
/// 这里只放面向用户的说法：不出现 fixture / session / seed / runtime 这类内部术语，
/// 也不出现任何引擎数值。
enum WorldShellCopy {
    // MARK: - 通用

    static let world = "世界"
    static let sampleBadge = WorldDataStatus.sample.label
    static let sampleBadgeNote = WorldDataStatus.sample.note ?? ""
    static let primaryAreas = "四个入口"
    static let localNavigation = "本区导航"
    static let currentFate = "当前命运"
    static let openWorld = "回到世界"

    // MARK: - 世界首页

    static let worldStatus = "这个世界"
    static let recentEvents = "最近发生的重要事件"
    static let activeFates = "正在进行的命运"
    static let activePeople = "最近活跃人物"
    static let unresolvedEvents = "未解决事件"
    static let locationChanges = "重要地点变化"
    static let recentStories = "最近完成的故事"
    static let noActiveFate = "此刻没有人正在经历什么。"
    static let startFateFromCards = "从一张卡牌开始一段命运"
    static let noRecentEvents = "还没有什么值得记下来的事。"
    static let noUnresolvedEvents = "眼下没有悬而未决的事。"
    static let noLocationChanges = "重要地点都还是原来的样子。"
    static let noCompletedStories = "还没有已经完结的命运。"
    static let emptyWorldTitle = "这个世界还是空的"
    static let emptyWorldNote = "从一张卡牌开始，让它进入这个世界。"
    static let emptyWorldAction = "前往卡牌"
    static let continueFate = "继续"
    static let openStoryBook = "打开故事书"
    static let openCharacter = "查看人物"
    static let eventInvolved = "牵涉到"
    static let worldUnavailableTitle = "本机世界状态读取失败"
    static let worldUnavailableNote = "这不是「世界为空」，而是这份状态没有读出来。"
    static let retry = "再试一次"

    // MARK: - 卡牌

    static let fateSection = "命运"
    static let experienceState = "在世界里的位置"
    static let roleLabel = "身份类型"
    static let inWorld = "已进入世界"

    static func fateEntryNote(for entry: FateEntry, experience: String) -> String {
        guard entry.isAvailable else {
            return entry.availabilityNote
        }
        return "\(entry.kind.inheritanceNote)当前状态：\(experience)。"
    }

    // MARK: - 人物

    static let characterList = "人物"
    static let identitySlices = "身份切片"
    static let identitySliceNote = "同一个人的不同时期与身份，各自是独立的一张卡。"
    static let characterExperiences = "本机世界的经历"
    static let characterRelations = "关系"
    static let characterKnowledge = "知道的事"
    static let characterRelationsNote = "只有这位人物自己知道的事会出现在这里。"
    static let noIdentityCards = "这个人还没有身份卡。"
    static let noCharacterExperience = "这个人还没有在你的世界里经历过什么。"
    static let noRelations = "还没有留下可以被称为关系的东西。"
    static let noKnowledge = "这个人知道的事还没有被记录下来。"
    static let originCanon = FactOrigin.canon.label
    static let originLocal = FactOrigin.localExperience.label
    static let changedBy = "来自"
    static let lastSeen = "最近一次出现"
    static let noLastSeen = "尚未在你的世界里出现"
    static let rosterEmpty = "还没有任何人物进入这个世界。"

    static func knowledgeTitle(for profile: CharacterProfile) -> String {
        "\(profile.subjectPronoun)知道的事"
    }

    static func experienceCostLabel(for episode: EpisodeRecord) -> String {
        episode.costSummary ?? "这段命运还没有走到可以说代价的地方。"
    }

    // MARK: - 故事书

    static let storyBook = "故事书"
    static let fateList = "命运"
    static let readingMode = "阅读模式"
    static let listeningMode = "聆听模式"
    static let fateRecord = "命运记录"
    static let fateRecordNote = "按发生的顺序排下来，不重写。"
    static let relationshipChanges = "关系变化"
    static let worldImpact = "对世界的影响"
    static let keyPeople = "关键人物"
    static let storyCost = "这次留下的代价"
    static let closureKind = "结局"
    static let inProgressStoryBookNote = "这段命运还在中途，故事书会随着它继续写下去。"
    static let readingHasNoPassages = "这一段命运还没有留下可以阅读的段落。"
    static let readingFromCardNote = "这段命运还没有留下自己的段落；下面是这张卡片的叙事段落。"
    static let noStoryBookEntries = "故事书还是空的。等到一段命运结束，它会出现在这里。"
    static let noWorldImpact = "这段命运没有在世界上留下需要记下来的变化。"
    static let hiddenSecretText = "这件事还没有被弄明白。"
    static let rewindToFate = "继续这段命运"

    // MARK: - 命运生成

    static let fateGenesisTitle = "将要开始的命运"
    static let weavingTitle = "正在编织命运…"
    static let weavingLayers = ["世界状态", "人物档案", "知识边界", "声音"]
    static let weaveAction = "编织命运"
    static let anotherEntry = "换一个入口"
    static let cancel = "先不开始"
    static let genesisDisclosure = "这里只显示你已经能察觉的部分；真相会在过程里慢慢展开。"
    static let genesisHint = "故事会从这个人自己看到的处境开始。"

    // MARK: - 侧边栏

    static func areaHint(for area: PrimaryArea) -> String {
        area.summary
    }

    static func footerAction(for area: PrimaryArea) -> String {
        switch area {
        case .world:
            return "一切从这里开始"
        case .cards:
            return "选择一张卡牌开始"
        case .characters:
            return "从列表里选一个人"
        case .storyBook:
            return "打开其中一本"
        }
    }

    static func episodeStatusNote(for episode: EpisodeRecord) -> String {
        switch episode.state {
        case .inProgress:
            return "进行中 · 第 \(episode.choicePath.count) 次抉择之后"
        case .completed:
            return episode.closureLabel ?? EpisodeState.completed.label
        }
    }
}
