import Combine
import WorldOfMysteriesCore

public enum LibrarySection: String, Hashable, Sendable {
    case gallery
    case formal
    case candidate
    case wishlist

    public var title: String {
        switch self {
        case .gallery:
            return "画册"
        case .formal:
            return "我的收藏"
        case .candidate:
            return "候选收藏"
        case .wishlist:
            return "愿望清单"
        }
    }

    public var subtitle: String {
        switch self {
        case .gallery:
            return "选择一张身份卡，查看身份、六维信息和故事。"
        case .formal:
            return "你正式收藏的身份卡；每张卡的内容核验状态以卡片自身的标注为准。"
        case .candidate:
            return "候选选择保留在这里，内容确认后也不会自动升级。"
        case .wishlist:
            return "记录你想继续研究或等待收录的身份目标。"
        }
    }
}

@MainActor
public final class AlbumViewModel: ObservableObject {
    @Published public var activeArea: PrimaryArea = .world
    @Published public var activeSection: LibrarySection = .gallery
    @Published public var selectedCardID: String?
    @Published public var selectedCharacterID: String?
    @Published public var selectedEpisodeID: String?
    @Published public var fateGenesisCardID: String?
    @Published public var isStoryDrawerPresented = false
    @Published public var searchText = ""

    public let cards: [AlbumCard]
    /// 客户端世界外壳展示的世界状态；当前来自合成示例世界（PRD §7.1）。
    public let world: WorldSnapshot
    public private(set) var collectionIntents: [String: CollectionIntent]
    public private(set) var wishlistCardIDs: Set<String>

    public init(cards: [AlbumCard] = DemoLibrary.cards, world: WorldSnapshot? = nil) {
        self.cards = cards
        self.world = world ?? SampleWorld.snapshot(cards: cards)
        self.collectionIntents = Dictionary(
            uniqueKeysWithValues: cards.map { ($0.id, $0.collectionIntent) }
        )
        self.wishlistCardIDs = Set(cards.filter(\.isWishlisted).map(\.id))
    }

    private var normalizedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var hasSearchQuery: Bool {
        !normalizedSearchText.isEmpty
    }

    public var selectedCard: AlbumCard? {
        guard let selectedCardID else {
            return nil
        }
        return cards.first { $0.id == selectedCardID }
    }

    public var filteredCards: [AlbumCard] {
        let query = normalizedSearchText
        guard !query.isEmpty else {
            return cards
        }
        return cards.filter {
            $0.identity.displayName.localizedCaseInsensitiveContains(query)
                || ArchiveCopy.sequenceName(for: $0.identity.sequenceName)
                    .localizedCaseInsensitiveContains(query)
                || ($0.identity.characterID?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    // MARK: - 世界外壳（PRD §2）

    public func show(_ area: PrimaryArea) {
        activeArea = area
    }

    /// 切换一级区域时保留该区域上一次的选中项；卡牌区域的选中项由 `selectedCardID` 独立保存。
    public var selectedCharacter: CharacterProfile? {
        guard let selectedCharacterID else {
            return nil
        }
        return world.character(id: selectedCharacterID)
    }

    public var selectedEpisode: EpisodeRecord? {
        guard let selectedEpisodeID else {
            return nil
        }
        return world.episode(id: selectedEpisodeID)
    }

    public var fateGenesisCard: AlbumCard? {
        guard let fateGenesisCardID else {
            return nil
        }
        return cards.first { $0.id == fateGenesisCardID }
    }

    public var characters: [CharacterProfile] {
        world.characters
    }

    public var visibleCharacters: [CharacterProfile] {
        let query = normalizedSearchText
        guard !query.isEmpty else {
            return characters
        }
        return characters.filter {
            $0.displayName.localizedCaseInsensitiveContains(query)
                || $0.pathwayLabel.localizedCaseInsensitiveContains(query)
                || $0.sequenceLabel.localizedCaseInsensitiveContains(query)
        }
    }

    public var visibleEpisodes: [EpisodeRecord] {
        let query = normalizedSearchText
        let episodes = world.activeEpisodes + world.completedEpisodes
        guard !query.isEmpty else {
            return episodes
        }
        return episodes.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.protagonistName.localizedCaseInsensitiveContains(query)
                || $0.locationLabel.localizedCaseInsensitiveContains(query)
        }
    }

    public func select(character: CharacterProfile) {
        selectedCharacterID = character.id
    }

    public func clearCharacterSelection() {
        selectedCharacterID = nil
    }

    public func select(episode: EpisodeRecord) {
        selectedEpisodeID = episode.id
    }

    public func clearEpisodeSelection() {
        selectedEpisodeID = nil
    }

    public func presentFateGenesis(for card: AlbumCard) {
        fateGenesisCardID = card.id
    }

    public func dismissFateGenesis() {
        fateGenesisCardID = nil
    }

    /// 命运入口的可用性、措辞与进行中状态（PRD §3.3）。
    public func fateEntry(for card: AlbumCard) -> FateEntry {
        let entry = FateEntryResolver.entry(
            for: card.identity,
            activeEpisodeID: world.activeEpisode(forCardID: card.id)?.id
        )
        guard entry.blocker == nil,
              entry.activeEpisodeID == nil,
              world.activeEpisodes.count >= Self.activeFateLimit
        else {
            return entry
        }
        return FateEntry(
            cardID: entry.cardID,
            kind: entry.kind,
            role: entry.role,
            blocker: "同时进行的命运已经到上限（\(Self.activeFateLimit) 段），先收束其中一段，再开始新的。",
            activeEpisodeID: nil
        )
    }

    /// 同时存在的进行中命运上限（PRD §3.3）。
    public static let activeFateLimit = 3

    public func experienceLabel(for card: AlbumCard) -> String {
        world.experienceLabel(forCardID: card.id)
    }

    public func cards(for character: CharacterProfile) -> [AlbumCard] {
        character.cardIDs.compactMap { cardID in
            cards.first { $0.id == cardID }
        }
    }

    /// 从卡牌开启命运：进入该卡并展开既有故事流程；命运生成界面随之收起。
    public func beginFate(for card: AlbumCard) {
        activeArea = .cards
        select(card)
        isStoryDrawerPresented = true
        fateGenesisCardID = nil
    }

    /// 打开卡牌详情（不自动展开故事）。
    public func showCard(_ card: AlbumCard) {
        activeArea = .cards
        select(card)
    }

    /// 从世界首页或故事书继续一段进行中的命运。
    public func continueFate(_ episode: EpisodeRecord) {
        guard let card = cards.first(where: { $0.id == episode.cardID }) else {
            return
        }
        beginFate(for: card)
    }

    public var visibleCards: [AlbumCard] {
        switch activeSection {
        case .gallery:
            return filteredCards
        case .formal:
            return filteredCards.filter { collectionIntents[$0.id] == .formal }
        case .candidate:
            return filteredCards.filter { collectionIntents[$0.id] == .candidate }
        case .wishlist:
            return filteredCards.filter { wishlistCardIDs.contains($0.id) }
        }
    }

    public var confirmedCount: Int {
        cards.filter { $0.identity.contentStatus == .confirmed }.count
    }

    public var formalCount: Int {
        cards.filter { collectionIntents[$0.id] == .formal }.count
    }

    public var candidateCount: Int {
        cards.filter { collectionIntents[$0.id] == .candidate }.count
    }

    public var wishlistCount: Int {
        cards.filter { wishlistCardIDs.contains($0.id) }.count
    }

    public func pathwaySummary(for pathwayID: String) -> String {
        let prefix = "lotm.\(pathwayID)."
        let pathwayCards = cards.filter { $0.identity.slotID.hasPrefix(prefix) }
        let formal = pathwayCards.filter { collectionIntents[$0.id] == .formal }.count
        let candidate = pathwayCards.filter { collectionIntents[$0.id] == .candidate }.count
        return ArchiveCopy.pathwaySummary(formal: formal, candidate: candidate)
    }

    public func characterCardCount(for characterID: String?) -> Int {
        guard let characterID, !characterID.isEmpty else {
            return 0
        }
        return cards.filter { $0.identity.characterID == characterID }.count
    }

    public func show(_ section: LibrarySection) {
        activeSection = section
        clearSelection()
    }

    public func select(_ card: AlbumCard) {
        selectedCardID = card.id
        isStoryDrawerPresented = false
    }

    public func clearSelection() {
        selectedCardID = nil
        isStoryDrawerPresented = false
    }

    public func clearSearch() {
        searchText = ""
    }

    public func toggleStoryDrawer() {
        isStoryDrawerPresented.toggle()
    }
}
