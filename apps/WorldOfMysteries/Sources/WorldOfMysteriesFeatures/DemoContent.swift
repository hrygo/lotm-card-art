import WorldOfMysteriesCore

public enum VisualTheme: String, Hashable, Sendable {
    case amber
    case violet
    case visionary
    case divineFool
    case celestialWorthy
    case godAlmighty
    case motherGoddessDepravity
    case eternalDarkness
    case fatherOfDemons
    case destructionCalamity
    case embodimentOfDisorder
    case demonOfKnowledge
    case keyOfLight
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
            collectionIntent: .formal
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
            collectionIntent: .formal
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
            collectionIntent: .formal
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
            collectionIntent: .formal
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
            collectionIntent: .formal
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.eternal-darkness.primordial-01",
                slotID: "lotm.eternal-darkness",
                displayName: "永恒之暗",
                sequenceName: "序列之上 · 永恒之暗",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "eternal-darkness",
                identitySliceID: "eternal-darkness.primordial"
            ),
            narrative: EternalDarknessNarrative.pack,
            visualTheme: .eternalDarkness,
            subtitle: "序列之上的永暗终点，把黑暗、死神与黄昏收进同一条河",
            artwork: .bundled(resourceName: "eternal-darkness-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 第四支柱的一半候选"),
                CardSemanticFact(index: "02", title: "扮演", value: "以终点本身的方式存在，不主动制造死亡"),
                CardSemanticFact(index: "03", title: "能力", value: "永暗之河／万物奇点／时空归一者（原著尊名）"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "单独不成第四支柱 · 需与灾祸之城合并")
            ],
            collectionIntent: .formal
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.father-of-demons.primordial-01",
                slotID: "lotm.father-of-demons",
                displayName: "恶魔之父",
                sequenceName: "序列之上 · 恶魔之父",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "father-of-demons",
                identitySliceID: "father-of-demons.primordial"
            ),
            narrative: FatherOfDemonsNarrative.pack,
            visualTheme: .fatherOfDemons,
            subtitle: "序列之上的暗影世界之主，把欲望、诅咒与异种收在同一个名字下",
            artwork: .bundled(resourceName: "father-of-demons-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 暗影世界之主"),
                CardSemanticFact(index: "02", title: "扮演", value: "汇聚欲望，收拢一切偏离原样的形态"),
                CardSemanticFact(index: "03", title: "能力", value: "深渊／被缚者／异类之主／诅咒之源"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "需两条途径的全部唯一性与序列1特性")
            ],
            collectionIntent: .formal
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.destruction-calamity.primordial-01",
                slotID: "lotm.destruction-calamity",
                displayName: "毁灭天灾",
                sequenceName: "序列之上 · 毁灭天灾",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "destruction-calamity",
                identitySliceID: "destruction-calamity.primordial"
            ),
            narrative: DestructionCalamityNarrative.pack,
            visualTheme: .destructionCalamity,
            subtitle: "序列之上的灾祸根源，把魔女与红祭司烧进同一座城",
            artwork: .bundled(resourceName: "destruction-calamity-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 第四支柱的另一半候选"),
                CardSemanticFact(index: "02", title: "扮演", value: "拆开世界，让战争与灾祸循环"),
                CardSemanticFact(index: "03", title: "能力", value: "灾祸之城／魔女／红祭司／根源之祸"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "单独不成第四支柱 · 需与永暗之河合并")
            ],
            collectionIntent: .formal
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.embodiment-of-disorder.primordial-01",
                slotID: "lotm.embodiment-of-disorder",
                displayName: "失序者",
                sequenceName: "序列之上 · 失序者",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "embodiment-of-disorder",
                identitySliceID: "embodiment-of-disorder.primordial"
            ),
            narrative: EmbodimentOfDisorderNarrative.pack,
            visualTheme: .embodimentOfDisorder,
            subtitle: "序列之上的秩序阴影，把黑皇帝与审判者收在秩序的另一半",
            artwork: .bundled(resourceName: "embodiment-of-disorder-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 尊名两句同指：失序者 · 秩序阴影"),
                CardSemanticFact(index: "02", title: "扮演", value: "替秩序保管它没有承认的那一半"),
                CardSemanticFact(index: "03", title: "能力", value: "失序之国／黑皇帝／审判者"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "需两条途径的全部唯一性与序列1特性")
            ],
            collectionIntent: .formal
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.demon-of-knowledge.primordial-01",
                slotID: "lotm.demon-of-knowledge",
                displayName: "知识之妖",
                sequenceName: "序列之上 · 知识之妖",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "demon-of-knowledge",
                identitySliceID: "demon-of-knowledge.primordial"
            ),
            narrative: DemonOfKnowledgeNarrative.pack,
            visualTheme: .demonOfKnowledge,
            subtitle: "序列之上的知识荒野，把隐者与完美者指向同一片疆域",
            artwork: .bundled(resourceName: "demon-of-knowledge-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 尊名两句：知识之妖 · 疯狂奥秘"),
                CardSemanticFact(index: "02", title: "扮演", value: "以「可被知道」的疆域为存在方式"),
                CardSemanticFact(index: "03", title: "能力", value: "知识荒野／隐者／完美者"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "需两条途径的全部唯一性与序列1特性")
            ],
            collectionIntent: .formal
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.key-of-light.primordial-01",
                slotID: "lotm.key-of-light",
                displayName: "光之钥",
                sequenceName: "序列之上 · 光之钥",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "key-of-light",
                identitySliceID: "key-of-light.primordial"
            ),
            narrative: KeyOfLightNarrative.pack,
            visualTheme: .keyOfLight,
            subtitle: "序列之上的命运化身，把概率与混乱绕在同一个轮上",
            artwork: .bundled(resourceName: "key-of-light-card-v1-v001"),
            audioStatus: .localBundle,
            semanticReadbacks: [
                CardSemanticFact(index: "01", title: "身份", value: "序列之上 · 存在名与源质名同为「光之钥」"),
                CardSemanticFact(index: "02", title: "扮演", value: "以概率、运气与混乱的方式存在"),
                CardSemanticFact(index: "03", title: "能力", value: "光之钥／命运之轮／无尽的混乱／命运化身"),
                CardSemanticFact(index: "04", title: "魔药", value: "不适用普通魔药体系"),
                CardSemanticFact(index: "05", title: "晋升", value: "远古序列之上存在 · 无完整起源仪式"),
                CardSemanticFact(index: "06", title: "限制", value: "只有一条途径与单份唯一性")
            ],
            collectionIntent: .formal
        )
    ]
}
