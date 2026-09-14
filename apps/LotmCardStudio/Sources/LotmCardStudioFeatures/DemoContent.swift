import LotmCardStudioCore

public enum VisualTheme: String, Hashable, Sendable {
    case amber
    case violet
    case visionary
    case divineFool
    case celestialWorthy
    case godAlmighty
    case motherGoddessDepravity
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
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.celestial-worthy.primordial-01",
                slotID: "lotm.celestial-worthy",
                displayName: "福生玄黄天尊",
                sequenceName: "序列之上 · 诡秘之主",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "celestial-worthy",
                identitySliceID: "celestial-worthy.primordial"
            ),
            narrative: CelestialWorthyNarrative.pack,
            visualTheme: .celestialWorthy,
            subtitle: "序列之上的诡秘之主，把源堡、穿越者与复苏写进同一盘布局",
            artwork: .bundled(resourceName: "celestial-worthy-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 诡秘之主 · 源堡原主"),
                CardSemanticFact(index: "02", title: "扮演", value: "长期复苏布局与身份渗透"),
                CardSemanticFact(index: "03", title: "能力", value: "统御愚者/错误/门与源堡（线索）"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "残留意志与主体争夺 · 非已死亡")
            ],
            collectionIntent: .candidate
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.god-almighty.primordial-01",
                slotID: "lotm.god-almighty",
                displayName: "上帝",
                sequenceName: "序列之上 · 星界支柱",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "god-almighty",
                identitySliceID: "god-almighty.primordial"
            ),
            narrative: GodAlmightyNarrative.pack,
            visualTheme: .godAlmighty,
            subtitle: "序列之上的星界支柱，把全知、全能与创造收在混沌海之下",
            artwork: .bundled(resourceName: "god-almighty-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 星界支柱 · 三大支柱之一"),
                CardSemanticFact(index: "02", title: "扮演", value: "无需现身即已涵盖的存在方式"),
                CardSemanticFact(index: "03", title: "能力", value: "全知/全能/造物主/星界之主（编辑裁定）"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "主体限制未披露 · 非无限制")
            ],
            collectionIntent: .candidate
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.mother-goddess-depravity.primordial-01",
                slotID: "lotm.mother-goddess-depravity",
                displayName: "堕落母神",
                sequenceName: "序列之上 · 现实支柱",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "mother-goddess-depravity",
                identitySliceID: "mother-goddess-depravity.primordial"
            ),
            narrative: MotherGoddessDepravityNarrative.pack,
            visualTheme: .motherGoddessDepravity,
            subtitle: "序列之上的现实支柱，把母巢、生命与繁衍收在粉紫的月光之下",
            artwork: .bundled(resourceName: "mother-goddess-depravity-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 现实支柱 · 三大支柱之一"),
                CardSemanticFact(index: "02", title: "扮演", value: "以繁衍、污染与神谕从侧面主导现实"),
                CardSemanticFact(index: "03", title: "能力", value: "母巢／生命与繁衍／现实主导（二手交叉）"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "母巢被撕裂未取回 · 非已死亡")
            ],
            collectionIntent: .candidate
        )
    ]
}
