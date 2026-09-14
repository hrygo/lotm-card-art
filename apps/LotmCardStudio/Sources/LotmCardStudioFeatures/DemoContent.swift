import LotmCardStudioCore

public enum VisualTheme: String, Hashable, Sendable {
    case amber
    case violet
    case visionary
    case divineFool
    case empty
}

public enum ArtworkAsset: Hashable, Sendable {
    case bundled(resourceName: String)
    case procedural

    public var resourceName: String? {
        guard case let .bundled(resourceName) = self else {
            return nil
        }
        return resourceName
    }
}

public enum CardAudioStatus: String, Hashable, Sendable {
    case localBundle
    case speechRailFallback
    case pendingApproval
}

public struct CardSemanticFact: Hashable, Sendable {
    public let index: String
    public let title: String
    public let value: String

    public init(index: String, title: String, value: String) {
        self.index = index
        self.title = title
        self.value = value
    }
}

public struct AlbumCard: Identifiable, Hashable, Sendable {
    public let identity: CardIdentity
    public let narrative: NarrativePack?
    public let artwork: ArtworkAsset
    public let audioStatus: CardAudioStatus
    public let semanticReadbacks: [CardSemanticFact]
    public let collectionIntent: CollectionIntent
    public let isWishlisted: Bool
    public let visualTheme: VisualTheme
    public let subtitle: String

    public var id: String {
        identity.cardID
    }

    public var artworkResourceName: String? {
        artwork.resourceName
    }

    public var isAtomicBundle: Bool {
        let expectedIndexes = ["01", "02", "03", "04", "05", "06"]
        let hasArtwork = artwork == .procedural
            || !(artwork.resourceName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasAudioBinding = narrative?.lines.allSatisfy { line in
            line.isPlayable && !(line.audioResourceName?.isEmpty ?? true)
        } == true
        return identity.hasValidIdentityBinding
            && hasArtwork
            && narrative?.cardID == identity.cardID
            && semanticReadbacks.map(\.index) == expectedIndexes
            && hasAudioBinding
    }

    public init(
        identity: CardIdentity,
        narrative: NarrativePack?,
        visualTheme: VisualTheme,
        subtitle: String,
        artwork: ArtworkAsset = .procedural,
        audioStatus: CardAudioStatus = .pendingApproval,
        semanticReadbacks: [CardSemanticFact] = [],
        collectionIntent: CollectionIntent = .none,
        isWishlisted: Bool = false
    ) {
        self.identity = identity
        self.narrative = narrative
        self.artwork = artwork
        self.audioStatus = audioStatus
        self.semanticReadbacks = semanticReadbacks
        self.collectionIntent = collectionIntent
        self.isWishlisted = isWishlisted
        self.visualTheme = visualTheme
        self.subtitle = subtitle
    }
}

public enum DemoLibrary {
    public static let cards: [AlbumCard] = [
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.fool.s09.klein-moretti.tingen-01",
                slotID: "lotm.fool.s09",
                displayName: "克莱恩·莫雷蒂",
                sequenceName: "序列 9 · 占卜家",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "klein-moretti",
                identitySliceID: "klein.s09.tingen"
            ),
            narrative: KleinTingenNarrative.pack,
            visualTheme: .violet,
            subtitle: "廷根时期的克莱恩，在灵摆与未知之间寻找可验证的方向",
            artwork: .bundled(resourceName: "fool-s09-card-name-edit-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "愚者途径 · 占卜家 · 克莱恩 · 序列 9"),
                CardSemanticFact(index: "02", title: "扮演", value: "专注而克制地实践占卜"),
                CardSemanticFact(index: "03", title: "能力", value: "灵摆针对近处目标占卜"),
                CardSemanticFact(index: "04", title: "魔药", value: "暗色容器与星点晶体的材料意象"),
                CardSemanticFact(index: "05", title: "晋升", value: "空杯与材料盒提示入序，不重演仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "聚焦近处目标，结果仍需核对")
            ],
            collectionIntent: .candidate
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.fool.s00.klein-moretti.mr-fool-01",
                slotID: "lotm.fool.s00",
                displayName: "愚者先生",
                sequenceName: "序列 0 · 真神",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "klein-moretti",
                identitySliceID: "klein.s00.mr-fool"
            ),
            narrative: MrFoolNarrative.pack,
            visualTheme: .divineFool,
            subtitle: "愚者途径的真神，在灰雾之上承担名字与选择",
            artwork: .bundled(resourceName: "fool-s00-card-agentic-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列 0 · 愚者 · 真神"),
                CardSemanticFact(index: "02", title: "扮演", value: "在不同身份中保持自我"),
                CardSemanticFact(index: "03", title: "能力", value: "愚弄与历史投影（节选）"),
                CardSemanticFact(index: "04", title: "魔药", value: "唯一性与诡秘侍者特性（待核对）"),
                CardSemanticFact(index: "05", title: "晋升", value: "愚弄时间、历史或命运（部分资料）"),
                CardSemanticFact(index: "06", title: "限制", value: "相关资料仍在整理")
            ],
            collectionIntent: .candidate,
            isWishlisted: true
        )
    ]
}
