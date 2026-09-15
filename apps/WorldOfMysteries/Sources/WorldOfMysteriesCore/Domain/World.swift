import Foundation

// MARK: - 一级区域

/// 《macOS UX / Interaction PRD》§2.1 的四个并列一级区域。
public enum PrimaryArea: String, CaseIterable, Hashable, Sendable, Identifiable {
    case world
    case cards
    case characters
    case storyBook

    public var id: Self {
        self
    }

    public var title: String {
        switch self {
        case .world:
            return "世界"
        case .cards:
            return "卡牌"
        case .characters:
            return "人物"
        case .storyBook:
            return "故事书"
        }
    }

    public var symbol: String {
        switch self {
        case .world:
            return "globe.europe.africa"
        case .cards:
            return "rectangle.grid.2x2"
        case .characters:
            return "person.crop.rectangle.stack"
        case .storyBook:
            return "book.closed"
        }
    }

    public var summary: String {
        switch self {
        case .world:
            return "这个世界现在是什么状态：时间、事件、进行中的命运与尚未解决的事。"
        case .cards:
            return "收藏与设定：身份、六维信息与声音，也是进入世界的入口。"
        case .characters:
            return "从人物视角回访这个世界：身份切片、经历、关系与知识边界。"
        case .storyBook:
            return "已经发生过的命运：选择路径、秘密、关系变化与对世界的影响。"
        }
    }
}

// MARK: - 世界状态

/// 界面上所有内容都必须可区分来源（PRD §7.2）。
public enum WorldDataStatus: String, Hashable, Sendable {
    case sample
    case verified

    public var label: String {
        switch self {
        case .sample:
            return "示例"
        case .verified:
            return "已核验"
        }
    }

    public var note: String? {
        switch self {
        case .sample:
            return "当前是用于验证界面的示例世界，其中的时间、事件与经历都不是核验过的原著事实。"
        case .verified:
            return nil
        }
    }
}

public struct WorldCalendarStamp: Hashable, Sendable {
    public let eraLabel: String
    public let dateLabel: String

    public init(eraLabel: String, dateLabel: String) {
        self.eraLabel = eraLabel
        self.dateLabel = dateLabel
    }

    public var displayLabel: String {
        "\(eraLabel) · \(dateLabel)"
    }
}

public struct WorldlineStamp: Hashable, Sendable {
    public let id: String
    public let label: String
    public let isDiverged: Bool
    public let note: String?

    public init(id: String, label: String, isDiverged: Bool = false, note: String? = nil) {
        self.id = id
        self.label = label
        self.isDiverged = isDiverged
        self.note = note
    }

    public var displayLabel: String {
        isDiverged ? "\(label) · 已分叉" : label
    }
}

/// 世界事件分级（母 PRD §7.3）。
public enum WorldEventScope: String, CaseIterable, Hashable, Sendable {
    case personal
    case relationship
    case local
    case major

    public var label: String {
        switch self {
        case .personal:
            return "个人"
        case .relationship:
            return "关系"
        case .local:
            return "地区"
        case .major:
            return "世界"
        }
    }
}

public struct WorldEventRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let scope: WorldEventScope
    public let timeLabel: String
    public let locationLabel: String
    public let isUnresolved: Bool
    public let involvedCharacterIDs: [String]
    public let relatedEpisodeIDs: [String]

    public init(
        id: String,
        title: String,
        detail: String,
        scope: WorldEventScope,
        timeLabel: String,
        locationLabel: String,
        isUnresolved: Bool,
        involvedCharacterIDs: [String] = [],
        relatedEpisodeIDs: [String] = []
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.scope = scope
        self.timeLabel = timeLabel
        self.locationLabel = locationLabel
        self.isUnresolved = isUnresolved
        self.involvedCharacterIDs = involvedCharacterIDs
        self.relatedEpisodeIDs = relatedEpisodeIDs
    }

    public var scopeLabel: String {
        scope.label
    }

    public var statusLabel: String {
        isUnresolved ? "尚无结论" : "已有结果"
    }

    public var metaLine: String {
        "\(timeLabel) · \(locationLabel) · \(scope.label)"
    }
}

public struct WorldLocationChange: Identifiable, Hashable, Sendable {
    public let id: String
    public let locationLabel: String
    public let changeSummary: String
    public let changedByEpisodeID: String?

    public init(
        id: String,
        locationLabel: String,
        changeSummary: String,
        changedByEpisodeID: String? = nil
    ) {
        self.id = id
        self.locationLabel = locationLabel
        self.changeSummary = changeSummary
        self.changedByEpisodeID = changedByEpisodeID
    }
}

// MARK: - 人物

public enum CharacterExistenceKind: String, CaseIterable, Hashable, Sendable {
    case canon
    case original
    case transcendent

    public var label: String {
        switch self {
        case .canon:
            return "原著人物"
        case .original:
            return "原创人物"
        case .transcendent:
            return "特殊存在"
        }
    }
}

/// 知识级别（母 PRD §9.2）。
public enum KnowledgeScope: String, CaseIterable, Hashable, Sendable {
    case publicKnowledge
    case social
    case organization
    case church
    case pathway
    case highSequence
    case secret
    case forbidden
    case cosmic

    public var label: String {
        switch self {
        case .publicKnowledge:
            return "公开"
        case .social:
            return "社交"
        case .organization:
            return "组织"
        case .church:
            return "教会"
        case .pathway:
            return "途径"
        case .highSequence:
            return "高序列"
        case .secret:
            return "秘密"
        case .forbidden:
            return "禁忌"
        case .cosmic:
            return "宇宙"
        }
    }
}

public struct CharacterKnowledgeFact: Identifiable, Hashable, Sendable {
    public let id: String
    public let content: String
    public let scope: KnowledgeScope

    public init(id: String, content: String, scope: KnowledgeScope) {
        self.id = id
        self.content = content
        self.scope = scope
    }
}

public enum RelationshipAxis: String, CaseIterable, Hashable, Sendable {
    case trust
    case fear
    case respect
    case affection
    case hostility
    case debt
    case sharedSecret
    case lastEncounter

    public var label: String {
        switch self {
        case .trust:
            return "信任"
        case .fear:
            return "恐惧"
        case .respect:
            return "尊重"
        case .affection:
            return "亲近"
        case .hostility:
            return "敌意"
        case .debt:
            return "债务"
        case .sharedSecret:
            return "共享秘密"
        case .lastEncounter:
            return "上次相遇"
        }
    }
}

/// 事实来源：原著事实与本机经历必须在界面上分区（PRD §3.6）。
public enum FactOrigin: String, Hashable, Sendable {
    case canon
    case localExperience

    public var label: String {
        switch self {
        case .canon:
            return "原著事实"
        case .localExperience:
            return "本机经历"
        }
    }
}

public struct CharacterRelationshipRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public let counterpartName: String
    public let axis: RelationshipAxis
    public let summary: String
    public let origin: FactOrigin
    public let changedByEpisodeID: String?

    public init(
        id: String,
        counterpartName: String,
        axis: RelationshipAxis,
        summary: String,
        origin: FactOrigin,
        changedByEpisodeID: String? = nil
    ) {
        self.id = id
        self.counterpartName = counterpartName
        self.axis = axis
        self.summary = summary
        self.origin = origin
        self.changedByEpisodeID = changedByEpisodeID
    }
}

public struct CharacterProfile: Identifiable, Hashable, Sendable {
    public let id: String
    public let displayName: String
    public let pathwayLabel: String
    public let sequenceLabel: String
    public let existenceKind: CharacterExistenceKind
    /// 界面文案对该人物使用的第三人称；真神及以上用「祂」（D15）。
    public let subjectPronoun: String
    public let cardIDs: [String]
    public let knowledgeFacts: [CharacterKnowledgeFact]
    public let relationships: [CharacterRelationshipRecord]
    public let lastSeenLabel: String?
    public let lastSeenOrder: Int?
    public let profileNote: String?

    public init(
        id: String,
        displayName: String,
        pathwayLabel: String,
        sequenceLabel: String,
        existenceKind: CharacterExistenceKind,
        subjectPronoun: String,
        cardIDs: [String],
        knowledgeFacts: [CharacterKnowledgeFact] = [],
        relationships: [CharacterRelationshipRecord] = [],
        lastSeenLabel: String? = nil,
        lastSeenOrder: Int? = nil,
        profileNote: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.pathwayLabel = pathwayLabel
        self.sequenceLabel = sequenceLabel
        self.existenceKind = existenceKind
        self.subjectPronoun = subjectPronoun
        self.cardIDs = cardIDs
        self.knowledgeFacts = knowledgeFacts
        self.relationships = relationships
        self.lastSeenLabel = lastSeenLabel
        self.lastSeenOrder = lastSeenOrder
        self.profileNote = profileNote
    }

    public var identityLine: String {
        "\(pathwayLabel) · \(sequenceLabel)"
    }

    public var cardCountLabel: String {
        cardIDs.isEmpty ? "还没有身份卡" : "\(cardIDs.count) 张身份卡"
    }

    public var lastSeenSummary: String {
        lastSeenLabel ?? "尚未在你的世界里出现"
    }

    public var knowledgeScopeLabels: [String] {
        var seen = Set<String>()
        return knowledgeFacts.compactMap { fact in
            let label = fact.scope.label
            return seen.insert(label).inserted ? label : nil
        }
    }

    public var canonRelationshipCount: Int {
        relationships.filter { $0.origin == .canon }.count
    }

    public var localRelationshipCount: Int {
        relationships.filter { $0.origin == .localExperience }.count
    }
}

// MARK: - 命运（Episode）

public enum EpisodeState: String, CaseIterable, Hashable, Sendable {
    case inProgress
    case completed

    public var label: String {
        switch self {
        case .inProgress:
            return "进行中"
        case .completed:
            return "已完结"
        }
    }
}

/// 选择策略（母 PRD §13.3 Choice Intent）。
public enum FateIntent: String, CaseIterable, Hashable, Sendable {
    case investigate
    case observe
    case confront
    case deceive
    case retreat
    case protect
    case cooperate
    case sacrifice
    case manipulate
    case conceal
    case risk

    public var label: String {
        switch self {
        case .investigate:
            return "信息优先"
        case .observe:
            return "谨慎观察"
        case .confront:
            return "正面交锋"
        case .deceive:
            return "以假乱真"
        case .retreat:
            return "保存自己"
        case .protect:
            return "先护住人"
        case .cooperate:
            return "借他人之力"
        case .sacrifice:
            return "付出代价"
        case .manipulate:
            return "引导他人"
        case .conceal:
            return "掩藏行踪"
        case .risk:
            return "承担风险"
        }
    }
}

public struct FateChoiceRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public let index: Int
    public let action: String
    public let intent: FateIntent
    public let cost: String
    public let outcome: String

    public init(
        id: String,
        index: Int,
        action: String,
        intent: FateIntent,
        cost: String,
        outcome: String
    ) {
        self.id = id
        self.index = index
        self.action = action
        self.intent = intent
        self.cost = cost
        self.outcome = outcome
    }

    public var displayLabel: String {
        "\(action) · \(intent.label)"
    }
}

public enum SecretState: String, CaseIterable, Hashable, Sendable {
    case hidden
    case partial
    case revealed

    public var label: String {
        switch self {
        case .hidden:
            return "未揭开"
        case .partial:
            return "只看到一角"
        case .revealed:
            return "已揭开"
        }
    }
}

public struct FateSecretRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let state: SecretState
    /// 只有已揭开（或部分揭开）的秘密才持有可展示文本；未揭开的秘密不保留答案。
    public let revealedText: String?

    public init(id: String, label: String, state: SecretState, revealedText: String? = nil) {
        self.id = id
        self.label = label
        self.state = state
        let isOpen = state != .hidden
        self.revealedText = isOpen ? revealedText : nil
    }

    public var displayText: String {
        revealedText ?? "这件事还没有被弄明白。"
    }
}

/// 结局类型（母 PRD §14.4）。
public enum FateClosureKind: String, CaseIterable, Hashable, Sendable {
    case truth
    case victory
    case survival
    case cost
    case failure
    case escape
    case wrongTruth
    case open
    case outOfControl
    case death

    public var label: String {
        switch self {
        case .truth:
            return "真相结局"
        case .victory:
            return "胜利结局"
        case .survival:
            return "幸存结局"
        case .cost:
            return "代价结局"
        case .failure:
            return "失败结局"
        case .escape:
            return "逃离结局"
        case .wrongTruth:
            return "错误的真相"
        case .open:
            return "开放结局"
        case .outOfControl:
            return "失控结局"
        case .death:
            return "死亡结局"
        }
    }
}

public struct RelationshipChangeRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public let counterpartName: String
    public let axis: RelationshipAxis
    public let summary: String
    public let episodeID: String
    public let episodeTitle: String

    public init(
        id: String,
        counterpartName: String,
        axis: RelationshipAxis,
        summary: String,
        episodeID: String,
        episodeTitle: String
    ) {
        self.id = id
        self.counterpartName = counterpartName
        self.axis = axis
        self.summary = summary
        self.episodeID = episodeID
        self.episodeTitle = episodeTitle
    }

    public var displayLabel: String {
        "\(counterpartName) · \(axis.label)"
    }
}

/// 文学化状态提示（PRD §4.3 / 母 PRD §19.5）：只有句子，没有数值。
public struct NarrativeStateNote: Identifiable, Hashable, Sendable {
    public let id: String
    public let text: String
    public let sourceLabel: String

    public init(id: String, text: String, sourceLabel: String) {
        self.id = id
        self.text = text
        self.sourceLabel = sourceLabel
    }
}

/// 命运生成界面唯一可见的种子子集（母 PRD §19.3）。
public struct FateVisibleSeed: Hashable, Sendable {
    public let time: String
    public let place: String
    public let anomaly: String
    public let pressure: String

    public init(time: String, place: String, anomaly: String, pressure: String) {
        self.time = time
        self.place = place
        self.anomaly = anomaly
        self.pressure = pressure
    }
}

public struct FateVisibleField: Identifiable, Hashable, Sendable {
    public let id: String
    public let label: String
    public let value: String

    public init(id: String, label: String, value: String) {
        self.id = id
        self.label = label
        self.value = value
    }
}

extension FateVisibleSeed {
    /// 界面只呈现这四项；秘密数量、NPC 目标与结局集合都不在其中。
    public var visibleFields: [FateVisibleField] {
        [
            FateVisibleField(id: "time", label: "时间", value: time),
            FateVisibleField(id: "place", label: "地点", value: place),
            FateVisibleField(id: "anomaly", label: "异常", value: anomaly),
            FateVisibleField(id: "pressure", label: "压力", value: pressure)
        ]
    }
}

/// 一段已经写下来的叙事（命运自己的段落，或卡片叙事兜底）。
public struct EpisodePassage: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let text: String

    public init(id: String, title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
}

/// 阅读模式里这些段落的来源；界面据此说明它们是从哪里来的。
public enum EpisodeReadingSource: String, Hashable, Sendable {
    /// 这段命运自己记下的段落。
    case episode
    /// 兜底：这张卡片的叙事段落（命运还没有留下自己的段落时）。
    case cardNarrative
    /// 两处都没有：只保留空态说明。
    case none
}

public struct EpisodeReadingMaterial: Hashable, Sendable {
    public let source: EpisodeReadingSource
    public let passages: [EpisodePassage]

    public init(source: EpisodeReadingSource, passages: [EpisodePassage]) {
        self.source = source
        self.passages = passages
    }

    public var isEmpty: Bool {
        passages.isEmpty
    }
}

/// 阅读模式的内容优先级（PRD §3.7）。
///
/// 命运自己的段落优先；只有在它还没有留下任何段落时才回退到卡片叙事，
/// 并由界面说明来源，避免把「还没有发生过的章节」当成已经发生的事。
public enum EpisodeReadingResolver {
    public static func resolve(episode: EpisodeRecord, cardChapters: [StoryChapter]) -> EpisodeReadingMaterial {
        if !episode.recordedPassages.isEmpty {
            return EpisodeReadingMaterial(source: .episode, passages: episode.recordedPassages)
        }
        guard !cardChapters.isEmpty else {
            return EpisodeReadingMaterial(source: .none, passages: [])
        }
        return EpisodeReadingMaterial(
            source: .cardNarrative,
            passages: cardChapters.map { chapter in
                EpisodePassage(id: chapter.id, title: chapter.title, text: chapter.line.text)
            }
        )
    }
}

public struct EpisodeRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public let cardID: String
    public let protagonistCharacterID: String
    public let protagonistName: String
    public let title: String
    public let timeLabel: String
    public let locationLabel: String
    public let state: EpisodeState
    public let closureKind: FateClosureKind?
    public let visibleSeed: FateVisibleSeed?
    /// 这段命运自己记下的段落（PRD §3.7 阅读模式）。
    /// 与卡片叙事分开：进行中的命运只能出现已经发生过的段落，不能借用卡片完整的章节。
    public let recordedPassages: [EpisodePassage]
    public let choicePath: [FateChoiceRecord]
    public let secrets: [FateSecretRecord]
    public let relationshipChanges: [RelationshipChangeRecord]
    public let stateNotes: [NarrativeStateNote]
    public let worldImpactEventIDs: [String]
    public let listeningNote: String
    public let costSummary: String?
    public let divergesWorldline: Bool

    public init(
        id: String,
        cardID: String,
        protagonistCharacterID: String,
        protagonistName: String,
        title: String,
        timeLabel: String,
        locationLabel: String,
        state: EpisodeState,
        closureKind: FateClosureKind? = nil,
        visibleSeed: FateVisibleSeed? = nil,
        recordedPassages: [EpisodePassage] = [],
        choicePath: [FateChoiceRecord] = [],
        secrets: [FateSecretRecord] = [],
        relationshipChanges: [RelationshipChangeRecord] = [],
        stateNotes: [NarrativeStateNote] = [],
        worldImpactEventIDs: [String] = [],
        listeningNote: String,
        costSummary: String? = nil,
        divergesWorldline: Bool = false
    ) {
        self.id = id
        self.cardID = cardID
        self.protagonistCharacterID = protagonistCharacterID
        self.protagonistName = protagonistName
        self.title = title
        self.timeLabel = timeLabel
        self.locationLabel = locationLabel
        self.state = state
        self.closureKind = closureKind
        self.visibleSeed = visibleSeed
        self.recordedPassages = recordedPassages
        self.choicePath = choicePath
        self.secrets = secrets
        self.relationshipChanges = relationshipChanges
        self.stateNotes = stateNotes
        self.worldImpactEventIDs = worldImpactEventIDs
        self.listeningNote = listeningNote
        self.costSummary = costSummary
        self.divergesWorldline = divergesWorldline
    }

    public var statusLabel: String {
        state.label
    }

    public var closureLabel: String? {
        closureKind?.label
    }

    public var secretSummary: String {
        "已揭开 \(revealedSecretCount) / \(totalSecretCount) 个秘密"
    }

    public var revealedSecretCount: Int {
        secrets.filter { $0.state == .revealed }.count
    }

    public var totalSecretCount: Int {
        secrets.count
    }

    public var choicePathLabels: [String] {
        choicePath.map(\.displayLabel)
    }

    public var metaLine: String {
        "\(timeLabel) · \(locationLabel)"
    }

    public var worldlineNote: String? {
        divergesWorldline ? "从这里开始，历史走向了另一条线。" : nil
    }
}

// MARK: - 世界快照

public struct WorldSnapshot: Hashable, Sendable {
    public let worldName: String
    public let calendar: WorldCalendarStamp
    public let worldline: WorldlineStamp
    public let dataStatus: WorldDataStatus
    public let narratorLine: String?
    /// 事件按由新到旧排列。
    public let events: [WorldEventRecord]
    public let locationChanges: [WorldLocationChange]
    public let characters: [CharacterProfile]
    public let episodes: [EpisodeRecord]

    public init(
        worldName: String,
        calendar: WorldCalendarStamp,
        worldline: WorldlineStamp,
        dataStatus: WorldDataStatus,
        narratorLine: String? = nil,
        events: [WorldEventRecord] = [],
        locationChanges: [WorldLocationChange] = [],
        characters: [CharacterProfile] = [],
        episodes: [EpisodeRecord] = []
    ) {
        self.worldName = worldName
        self.calendar = calendar
        self.worldline = worldline
        self.dataStatus = dataStatus
        self.narratorLine = narratorLine
        self.events = events
        self.locationChanges = locationChanges
        self.characters = characters
        self.episodes = episodes
    }

    public var statusChipLabel: String {
        dataStatus.label
    }

    public var isEmpty: Bool {
        events.isEmpty && episodes.isEmpty && characters.isEmpty
    }

    public func recentEvents(limit: Int = 5) -> [WorldEventRecord] {
        Array(events.prefix(limit))
    }

    public var unresolvedEvents: [WorldEventRecord] {
        events.filter(\.isUnresolved)
    }

    public var activeEpisodes: [EpisodeRecord] {
        episodes.filter { $0.state == .inProgress }
    }

    public var completedEpisodes: [EpisodeRecord] {
        episodes.filter { $0.state == .completed }
    }

    public func latestCompletedEpisodes(limit: Int = 3) -> [EpisodeRecord] {
        Array(completedEpisodes.prefix(limit))
    }

    public func recentlyActiveCharacters(limit: Int = 4) -> [CharacterProfile] {
        characters
            .filter { $0.lastSeenOrder != nil }
            .sorted { ($0.lastSeenOrder ?? 0) < ($1.lastSeenOrder ?? 0) }
            .prefix(limit)
            .map { $0 }
    }

    public func character(id: String) -> CharacterProfile? {
        characters.first { $0.id == id }
    }

    public func event(id: String) -> WorldEventRecord? {
        events.first { $0.id == id }
    }

    public func episode(id: String) -> EpisodeRecord? {
        episodes.first { $0.id == id }
    }

    public func episodes(forCardID cardID: String) -> [EpisodeRecord] {
        episodes.filter { $0.cardID == cardID }
    }

    public func episodes(forCharacterID characterID: String) -> [EpisodeRecord] {
        episodes.filter { $0.protagonistCharacterID == characterID }
    }

    public func activeEpisode(forCardID cardID: String) -> EpisodeRecord? {
        episodes.first { $0.cardID == cardID && $0.state == .inProgress }
    }

    /// 卡牌在本机世界中的经历状态（PRD §3.2）。
    public func experienceLabel(forCardID cardID: String) -> String {
        let cardEpisodes = episodes(forCardID: cardID)
        guard !cardEpisodes.isEmpty else {
            return "未进入世界"
        }
        if cardEpisodes.contains(where: { $0.state == .inProgress }) {
            return "有一段进行中的命运"
        }
        return "已有 \(cardEpisodes.count) 段历史"
    }

    public func events(forEpisodeID episodeID: String) -> [WorldEventRecord] {
        guard let episode = episode(id: episodeID) else {
            return []
        }
        return episode.worldImpactEventIDs.compactMap { event(id: $0) }
    }
}

// MARK: - 身份角色与命运入口

public enum IdentityRole: String, CaseIterable, Hashable, Sendable {
    case identityCard
    case archetypeCard
    case trueGod
    case aboveSequence

    public var label: String {
        switch self {
        case .identityCard:
            return "身份卡"
        case .archetypeCard:
            return "原型卡"
        case .trueGod:
            return "真神"
        case .aboveSequence:
            return "序列之上"
        }
    }
}

public enum IdentityRoleResolver {
    /// 从 `lotm.<pathway>.s09` 这类卡槽中解析序列号；非序列卡位返回 nil。
    public static func sequenceNumber(from slotID: String) -> Int? {
        for component in slotID.split(separator: ".") {
            guard component.hasPrefix("s") else {
                continue
            }
            let digits = component.dropFirst()
            guard !digits.isEmpty, digits.allSatisfy(\.isNumber), let value = Int(digits) else {
                continue
            }
            return value
        }
        return nil
    }

    public static func role(for slotID: String, identityKind: IdentityKind) -> IdentityRole {
        guard let sequence = sequenceNumber(from: slotID) else {
            return .aboveSequence
        }
        if sequence == 0 {
            return .trueGod
        }
        return identityKind == .archetype ? .archetypeCard : .identityCard
    }

    public static func role(for identity: CardIdentity) -> IdentityRole {
        role(for: identity.slotID, identityKind: identity.identityKind)
    }
}

/// 卡牌详情的命运入口（PRD §3.3）。
public enum FateEntryKind: Hashable, Sendable {
    case character(name: String)
    case archetype
    case transcendent(name: String)

    public var actionTitle: String {
        switch self {
        case let .character(name):
            return "进入\(name)"
        case .archetype:
            return "以该序列创造一个人"
        case .transcendent:
            return "以祂的尺度介入世界"
        }
    }

    public var inheritanceNote: String {
        switch self {
        case .character:
            return "将继承这个人此刻的身份、能力边界与已经知道的事。"
        case .archetype:
            return "会以这个序列为约束，诞生一个属于你的原创人物。"
        case .transcendent:
            return "这一次你决定的不再是往哪边走，而是是否回应、让哪种因果进入现实。"
        }
    }
}

public struct FateEntry: Hashable, Sendable {
    public let cardID: String
    public let kind: FateEntryKind
    public let role: IdentityRole
    public let blocker: String?
    public let activeEpisodeID: String?

    public init(
        cardID: String,
        kind: FateEntryKind,
        role: IdentityRole,
        blocker: String? = nil,
        activeEpisodeID: String? = nil
    ) {
        self.cardID = cardID
        self.kind = kind
        self.role = role
        self.blocker = blocker
        self.activeEpisodeID = activeEpisodeID
    }

    public var isAvailable: Bool {
        blocker == nil
    }

    public var primaryTitle: String {
        activeEpisodeID == nil ? kind.actionTitle : "继续这段命运"
    }

    public var secondaryTitle: String? {
        activeEpisodeID == nil ? nil : "另起一段"
    }

    public var title: String {
        primaryTitle
    }

    public var availabilityNote: String {
        blocker ?? kind.inheritanceNote
    }
}

public enum FateEntryResolver {
    public static func entry(for identity: CardIdentity, activeEpisodeID: String? = nil) -> FateEntry {
        let role = IdentityRoleResolver.role(for: identity)
        let kind: FateEntryKind
        switch role {
        case .aboveSequence, .trueGod:
            kind = .transcendent(name: identity.displayName)
        case .archetypeCard:
            kind = .archetype
        case .identityCard:
            kind = .character(name: identity.displayName)
        }
        let blocker = identity.hasValidIdentityBinding
            ? nil
            : "这张卡缺少对应的人物档案或身份切片，无法进入这个视角。"
        return FateEntry(
            cardID: identity.cardID,
            kind: kind,
            role: role,
            blocker: blocker,
            activeEpisodeID: activeEpisodeID
        )
    }
}

/// 世界首页 / 侧边栏共用的一句世界状态摘要。
public enum WorldSummaryCopy {
    public static func activeFateLine(count: Int) -> String {
        guard count > 0 else {
            return "此刻没有人正在经历什么。"
        }
        return count == 1 ? "有 1 段命运还停在中途。" : "有 \(count) 段命运还停在中途。"
    }

    public static func unresolvedLine(count: Int) -> String {
        guard count > 0 else {
            return "没有悬而未决的事。"
        }
        return count == 1 ? "有 1 件事还没有结论。" : "有 \(count) 件事还没有结论。"
    }
}
