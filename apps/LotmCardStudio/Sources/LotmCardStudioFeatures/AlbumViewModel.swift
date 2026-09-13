import Combine
import LotmCardStudioCore

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
            return "只显示当前内容已确认、并由你正式收藏的身份卡。"
        case .candidate:
            return "候选选择保留在这里，内容确认后也不会自动升级。"
        case .wishlist:
            return "记录你想继续研究或等待收录的身份目标。"
        }
    }
}

@MainActor
public final class AlbumViewModel: ObservableObject {
    @Published public var activeSection: LibrarySection = .gallery
    @Published public var selectedCardID: String?
    @Published public var isStoryDrawerPresented = false
    @Published public var searchText = ""

    public let cards: [AlbumCard]
    public private(set) var collectionIntents: [String: CollectionIntent]
    public private(set) var wishlistCardIDs: Set<String>

    public init(cards: [AlbumCard] = DemoLibrary.cards) {
        self.cards = cards
        self.collectionIntents = [
            "lotm.fool.s03.klein-01": .formal,
            "lotm.fool.s09.klein-moretti.tingen-01": .candidate
        ]
        self.wishlistCardIDs = ["lotm.fool.s00.prototype"]
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

    public var visibleCards: [AlbumCard] {
        switch activeSection {
        case .gallery:
            return filteredCards
        case .formal:
            return filteredCards.filter {
                $0.identity.contentStatus == .confirmed
                    && collectionIntents[$0.id] == .formal
            }
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
        cards.filter {
            $0.identity.contentStatus == .confirmed
                && collectionIntents[$0.id] == .formal
        }.count
    }

    public var candidateCount: Int {
        cards.filter { collectionIntents[$0.id] == .candidate }.count
    }

    public var wishlistCount: Int {
        cards.filter { wishlistCardIDs.contains($0.id) }.count
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
