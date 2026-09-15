import AppKit
import SwiftUI
import WorldOfMysteriesCore

/// 《诡秘之主》秘史档案馆设计 Token 系统
///
/// 基于 App Logo（典藏原版 · 方案 B-1 复古牛皮与温润黄铜）提取的高精度色谱与质感构建。
/// 架构包含：Primitives（原始色谱）、Semantic Roles（语义角色）、Materials & Gradients（材质光影）。
enum ArchiveTheme {

    // MARK: - 1. Primitives (Logo 实测聚类原始色谱)

    /// 复古牛皮系列（Vintage Leather）
    enum Leather {
        /// 深邃星界虚空底盘 (#04080D) - 极暗沉浸
        static let void = DesignTokens.Palette.leatherVoid
        /// 鞣制古籍牛皮原色 (#1A181A) - 典籍封面基底
        static let deep = DesignTokens.Palette.leatherDeep
        /// 古籍封面本体牛皮 (#1F1D1E) - 侧栏与基底表面
        static let base = DesignTokens.Palette.leatherBase
        /// 皮革凸棱骨架 (#2E2C2D) - 结构抬升与卡片底板
        static let raised = DesignTokens.Palette.leatherRaised
        /// 卡槽下沉与压印阴影 (#474441) - 分割线与浮雕深色
        static let elevated = DesignTokens.Palette.leatherElevated
        /// 皮革磨损泛光边 (#615C57) - 微弱暖灰高光
        static let highlight = DesignTokens.Palette.leatherHighlight
    }

    /// 古典洛可可温润黄铜系列 (Antique Brass & Gold)
    enum Brass {
        /// 氧化暗铜包浆 (#6E6458) - 辅助弱化金属边
        static let patina = DesignTokens.Palette.brassPatina
        /// 温润黄铜五金本体 (#A49274) - 锁扣与包角主体
        static let core = DesignTokens.Palette.brassCore
        /// 金属浮雕中调光 (#D1BF99) - 纹饰高光过渡
        static let gleam = DesignTokens.Palette.brassGleam
        /// 洛可可黄铜高光与琥珀神辉 (#E8D2A1) - 核心金属反光与圣杯金
        static let luster = DesignTokens.Palette.brassLuster
    }

    /// 序列灵界以太系列 (Ethereal Aether & Teal)
    enum Aether {
        /// 深层以太暗流
        static let deep = DesignTokens.Palette.aetherDeep
        /// 灵流主色
        static let core = DesignTokens.Palette.aetherCore
        /// Logo 中央卡牌灵性幽碧流光 (#A2D7CE)
        static let light = DesignTokens.Palette.aetherLight
    }

    /// 古典羊皮纸文字系列 (Parchment Typography)
    enum Parchment {
        /// 暖色羊皮纸高亮正文 (#F2EFE9) - 具备羊皮纸温润感，替代冷白
        static let primary = DesignTokens.Palette.parchmentPrimary
        /// 典籍墨水中调说明字 (#A39E93) - 次级信息
        static let secondary = DesignTokens.Palette.parchmentSecondary
        /// 暗金沉淀辅助弱化字 (#6E6458) - 脚注与元信息
        static let muted = DesignTokens.Palette.brassPatina
    }

    /// 故事页羊皮纸卷宗系列（Aged Story Folio）
    ///
    /// 故事正文使用温暖的旧纸中间调，保留暗色档案馆的沉浸感，
    /// 只让正文成为一页被翻开的卷宗，而不是突兀的浅色卡片。
    enum Story {
        static let paper = DesignTokens.Palette.storyPaper
        static let paperHighlight = DesignTokens.Palette.storyPaperHighlight
        static let ink = DesignTokens.Palette.parchmentPrimary
        static let inkMuted = DesignTokens.Palette.parchmentSecondary
        static let edge = DesignTokens.Palette.storyEdge
        static let shadow = DesignTokens.Palette.storyShadow

        static let sheetSurface = LinearGradient(
            colors: [
                paperHighlight.opacity(0.13),
                paper,
                paper.opacity(0.86)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let railSurface = LinearGradient(
            colors: [Leather.raised.opacity(0.72), Leather.deep.opacity(0.92)],
            startPoint: .top,
            endPoint: .bottom
        )

        enum Metrics {
            static let sectionSpacing: CGFloat = 16
            static let headerSpacing: CGFloat = 7
            static let contentSpacing: CGFloat = 16
            static let bodySpacing: CGFloat = 12
            static let controlSpacing: CGFloat = 10
            static let transportSpacing: CGFloat = 8
            static let sheetPadding: CGFloat = 18
            static let railPadding: CGFloat = 14
            static let sheetRadius: CGFloat = 14
            static let railRadius: CGFloat = 14
            static let chapterRadius: CGFloat = 8
            static let chapterRailWidth: CGFloat = 232
            static let sheetShadowRadius: CGFloat = 10
            static let sheetShadowYOffset: CGFloat = 5
            static let chapterRowMarkerHeight: CGFloat = 20
            static let chapterRowMarkerInset: CGFloat = 6
            static let chapterRowSpacer: CGFloat = 8
        }

        enum Typography {
            static let eyebrow = Font.system(size: 10, weight: .semibold, design: .rounded)
            static let title = Font.system(size: 20, weight: .bold, design: .serif)
            static let chapterTitle = Font.system(size: 12, weight: .bold, design: .serif)
            static let body = Font.system(size: 17, weight: .medium, design: .serif)
            static let note = Font.system(size: 11, weight: .regular, design: .rounded)
            static let chapterMeta = Font.system(size: 11, weight: .medium, design: .rounded)
            static let status = Font.system(size: 10, weight: .semibold, design: .rounded)
        }
    }

    /// 神秘学状态与仪式系列 (Mystic States)
    enum Mystic {
        /// 占卜秘祈紫 (#8570C2) - 候选状态与神秘学事件
        static let violet = DesignTokens.Palette.mysticViolet
        /// 窥秘冰蓝 (#85AED1) - 聚焦高亮与空想家冷理智
        static let ice = DesignTokens.Palette.mysticIce
        /// 血月警戒红 (#D95454) - 失控、危险与限制条件
        static let crimson = DesignTokens.Palette.mysticCrimson
    }

    /// 序列层级稀有度色（只表达力量层级，不表达内容状态）
    ///
    /// 采用典型游戏稀有度的可辨识阶梯：银白、翡翠绿、秘蓝、典藏紫、橙金。
    /// 映射 `config/sequence-hierarchy.json`：序列 9–8 为低序列，
    /// 7–5 为中序列，4–3 为圣者，2–1 为天使，0 为真神。
    enum Sequence {
        enum Tier: String, CaseIterable, Hashable, Sendable {
            case low
            case mid
            case saint
            case angel
            case trueGod
            case unknown

            init(sequenceNumber: Int?) {
                guard let sequenceNumber else {
                    self = .unknown
                    return
                }

                switch sequenceNumber {
                case 8...9:
                    self = .low
                case 5...7:
                    self = .mid
                case 3...4:
                    self = .saint
                case 1...2:
                    self = .angel
                case 0:
                    self = .trueGod
                default:
                    self = .unknown
                }
            }
        }

        struct Token {
            let label: Color
            let border: Color
            let surface: Color
            let glow: Color
        }

        /// 低序列：中性银白，作为稀有度阶梯的视觉基线。
        static let low = Token(
            label: DesignTokens.Palette.tierLowLabel,
            border: DesignTokens.Palette.tierLowBorder,
            surface: DesignTokens.Palette.tierLowSurface,
            glow: DesignTokens.Palette.tierLowGlow
        )

        /// 中序列：偏绿的翡翠色，避免与内容确认态的青绿色相混。
        static let mid = Token(
            label: DesignTokens.Palette.tierMidLabel,
            border: DesignTokens.Palette.tierMidBorder,
            surface: DesignTokens.Palette.tierMidSurface,
            glow: DesignTokens.Palette.tierMidGlow
        )

        /// 圣者：秘蓝，承接典型 RPG 中的稀有色，但不使用紫色。
        static let saint = Token(
            label: DesignTokens.Palette.tierSaintLabel,
            border: DesignTokens.Palette.tierSaintBorder,
            surface: DesignTokens.Palette.tierSaintSurface,
            glow: DesignTokens.Palette.tierSaintGlow
        )

        /// 天使：典藏紫，保留紫色的高阶稀有度联想，并与圣者蓝色拉开色相距离。
        static let angel = Token(
            label: DesignTokens.Palette.tierAngelLabel,
            border: DesignTokens.Palette.tierAngelBorder,
            surface: DesignTokens.Palette.tierAngelSurface,
            glow: DesignTokens.Palette.tierAngelGlow
        )

        /// 真神：高饱和橙金，避免与低序列银白或浅黄铜产生相近观感。
        static let trueGod = Token(
            label: DesignTokens.Palette.tierTrueGodLabel,
            border: DesignTokens.Palette.tierTrueGodBorder,
            surface: DesignTokens.Palette.tierTrueGodSurface,
            glow: DesignTokens.Palette.tierTrueGodGlow
        )

        static let unknown = Token(
            label: DesignTokens.Palette.parchmentSecondary,
            border: Borders.subtle,
            surface: DesignTokens.Palette.tierUnknownSurface,
            glow: .clear
        )

        static func token(for tier: Tier) -> Token {
            switch tier {
            case .low:
                return low
            case .mid:
                return mid
            case .saint:
                return saint
            case .angel:
                return angel
            case .trueGod:
                return trueGod
            case .unknown:
                return unknown
            }
        }

        static let lowLabel = low.label
        static let midLabel = mid.label
        static let saintLabel = saint.label
        static let angelLabel = angel.label
        static let trueGodLabel = trueGod.label
        static let unknownLabel = unknown.label

        static func labelColor(for tier: Tier) -> Color {
            token(for: tier).label
        }
    }

    /// 六维信息色：只表达信息维度，不表达序列层级或内容状态。
    enum Semantic {
        static let acting = DesignTokens.Palette.semanticActing
        static let ability = DesignTokens.Palette.aetherLight
        static let potion = DesignTokens.Palette.semanticPotion
        static let promotion = DesignTokens.Palette.semanticPromotion
        static let limitation = DesignTokens.Palette.mysticCrimson
    }

    /// 内容状态色：只表达资料状态，不表达序列稀有度。
    enum Status {
        static let unfilled = DesignTokens.Palette.statusUnfilled
        static let candidate = DesignTokens.Palette.statusCandidate
        static let unresearched = DesignTokens.Palette.statusUnresearched
        static let confirmed = DesignTokens.Palette.aetherLight
    }

    /// 声音与故事播放状态色：只表达当前可操作性。
    enum Playback {
        static let ready = DesignTokens.Palette.aetherLight
        static let preparing = DesignTokens.Palette.brassGleam
        static let failed = DesignTokens.Palette.mysticCrimson
        static let idle = DesignTokens.Palette.parchmentSecondary
    }

    // MARK: - 2. Semantic Aliases (完全向下兼容既有调用)

    static let ink = DesignTokens.Palette.leatherVoid
    static let coal = DesignTokens.Palette.leatherDeep
    static let raised = DesignTokens.Palette.leatherRaised
    static let elevated = DesignTokens.Palette.leatherElevated
    static let primary = DesignTokens.Palette.parchmentPrimary
    static let secondary = DesignTokens.Palette.parchmentSecondary
    static let amber = DesignTokens.Palette.brassLuster
    static let teal = DesignTokens.Palette.aetherLight
    static let violet = DesignTokens.Palette.mysticViolet
    static let ice = DesignTokens.Palette.mysticIce
    static let danger = DesignTokens.Palette.mysticCrimson

    // MARK: - 3. Gradients (古典魔典与黄铜光泽材质)

    enum Gradients {
        /// 古籍封皮深色渐变（从深皮过渡至暗渊星底）
        static let grimoireCover = LinearGradient(
            colors: [DesignTokens.Palette.leatherDeep, DesignTokens.Palette.leatherVoid],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 卡片与面板真皮微光渐变
        static let leatherSurface = LinearGradient(
            colors: [Leather.raised.opacity(0.85), Leather.deep.opacity(0.95)],
            startPoint: .top,
            endPoint: .bottom
        )

        /// 洛可可黄铜拉丝反光渐变
        static let brassGleam = LinearGradient(
            colors: [DesignTokens.Palette.brassPatina, DesignTokens.Palette.brassLuster, DesignTokens.Palette.brassCore],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 双色神圣灵界光流（金光与青碧交织，对应 Logo 卡牌）
        static let divineGaze = RadialGradient(
            colors: [DesignTokens.Palette.shadowBrassGlow, Aether.light.opacity(0.16), .clear],
            center: .center,
            startRadius: 4,
            endRadius: 280
        )
    }

    // MARK: - 4. Borders & Lines (边框与分割线)

    enum Borders {
        /// 皮革与金属交界微弱边框
        static let subtle = DesignTokens.Palette.tierUnknownBorder
        /// 暗铜包浆线框
        static let brassMuted = DesignTokens.Palette.borderBrassMuted
        /// 洛可可黄铜高光金边
        static let brassAccent = DesignTokens.Palette.borderBrassAccent
        /// 灵性幽碧流光边框
        static let aetherGlow = DesignTokens.Palette.borderAetherGlow
    }

    // MARK: - 5. Dynamic Tokens (动态交互与微动效)

    enum Tokens {
        enum Motion {
            /// 触觉回弹微动效（按键、卡槽下压）
            static let tactilePress = Animation.spring(DesignTokens.MotionSpring.tactilePress)
            /// 悬浮过渡动效
            static let hoverSpring = Animation.spring(DesignTokens.MotionSpring.hover)
            /// 灵流呼吸循环
            static let aetherBreathe = Animation.easeInOut(duration: DesignTokens.MotionDuration.ms2800).repeatForever(autoreverses: true)
        }

        enum Shadows {
            /// 黄铜圣光点燃光晕
            static let brassGlow = DesignTokens.Palette.shadowBrassGlow
            /// 灵界以太幽碧光晕
            static let aetherPulse = DesignTokens.Palette.borderAetherGlow
            /// 古籍真皮深渊暗影
            static let leatherPlinth = DesignTokens.Palette.shadowLeatherPlinth
        }
    }
}

// MARK: - ContentStatus 语义与色彩映射

extension ContentStatus {
    var displayTitle: String {
        switch self {
        case .unfilled:
            return "待收录"
        case .proposed:
            return "候选"
        case .unresearched:
            return "待研究"
        case .confirmed:
            return "已确认"
        }
    }

    var accentColor: Color {
        switch self {
        case .unfilled:
            return ArchiveTheme.Status.unfilled
        case .proposed:
            return ArchiveTheme.Status.candidate
        case .unresearched:
            return ArchiveTheme.Status.unresearched
        case .confirmed:
            return ArchiveTheme.Status.confirmed
        }
    }
}

// MARK: - StatusChip (状态胶囊标签)

struct StatusChip: View {
    let status: ContentStatus

    var body: some View {
        HStack(spacing: DesignTokens.Space.s7) {
            Circle()
                .fill(status.accentColor)
                .frame(width: 7, height: 7)
            Text(status.displayTitle)
        }
        .font(.system(size: DesignTokens.FontSize.s11, weight: .semibold, design: .rounded))
        .foregroundStyle(status.accentColor)
        .padding(.horizontal, DesignTokens.Space.s10)
        .padding(.vertical, DesignTokens.Space.s6)
        .glassEffect(
            .regular.tint(status.accentColor.opacity(0.14)),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(status.accentColor.opacity(0.28), lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("内容状态：\(status.displayTitle)")
    }
}

// MARK: - SequenceBadge (序列层级标识)

struct SequenceBadge: View {
    let sequenceName: String
    let includesRank: Bool

    init(sequenceName: String, includesRank: Bool = false) {
        self.sequenceName = sequenceName
        self.includesRank = includesRank
    }

    private var tier: ArchiveTheme.Sequence.Tier {
        ArchiveCopy.sequenceTier(for: sequenceName)
    }

    private var token: ArchiveTheme.Sequence.Token {
        ArchiveTheme.Sequence.token(for: tier)
    }

    private var displayLabel: String {
        ArchiveCopy.sequenceDisplayLabel(for: sequenceName, includesRank: includesRank)
    }

    private var accessibilityLabel: String {
        ArchiveCopy.sequenceDisplayLabel(for: sequenceName, includesRank: true)
    }

    var body: some View {
        HStack(spacing: DesignTokens.Space.s6) {
            Circle()
                .fill(token.label)
                .frame(width: includesRank ? 6 : 5, height: includesRank ? 6 : 5)
            Text(displayLabel)
                .lineLimit(1)
        }
        .font(
            .system(
                size: includesRank ? 11 : 10,
                weight: includesRank ? .bold : .semibold,
                design: .rounded
            )
        )
        .foregroundStyle(token.label)
        .padding(.horizontal, includesRank ? 9 : 7)
        .padding(.vertical, includesRank ? 5 : 4)
        .background(token.surface, in: Capsule())
        .overlay {
            Capsule()
                .stroke(token.border.opacity(0.72), lineWidth: DesignTokens.Stroke.hairline)
        }
        .shadow(
            color: token.glow.opacity(includesRank ? 0.65 : 0.45),
            radius: includesRank ? 5 : 3
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("序列层级")
        .accessibilityValue(accessibilityLabel)
    }
}

// MARK: - ArchiveArtworkView (卡面与视觉展示)

struct ArchiveArtworkView: View {
    let theme: VisualTheme
    let compact: Bool
    let resourceName: String?

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let glowColor: Color = (theme == .violet || theme == .celestialWorthy || theme == .godAlmighty || theme == .motherGoddessDepravity || theme == .eternalDarkness || theme == .fatherOfDemons || theme == .destructionCalamity || theme == .embodimentOfDisorder || theme == .demonOfKnowledge || theme == .keyOfLight)
                ? ArchiveTheme.Mystic.violet
                : (theme == .visionary ? ArchiveTheme.Mystic.ice : ArchiveTheme.Aether.light)
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 16 : 24, style: .continuous)
                    .fill(ArchiveTheme.Gradients.grimoireCover)

                if compact {
                    // 网格瓦片：径向渐变替代离屏模糊（同层绘制完成，滚动时少一次离屏处理）。
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [glowColor.opacity(0.42), glowColor.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: size * 0.35
                            )
                        )
                        .frame(width: size * 0.70, height: size * 0.70)
                } else {
                    // 单卡详情保持原有模糊发光：详情页不做任何视觉降级。
                    Circle()
                        .fill(glowColor.opacity(0.42))
                        .frame(width: size * 0.62, height: size * 0.62)
                        .blur(radius: 44)
                }

                if let resourceName {
                    BundledArtworkView(resourceName: resourceName, compact: compact)
                } else if theme == .divineFool {
                    DivineFoolArtworkView(compact: compact)
                } else if theme == .empty {
                    Circle()
                        .stroke(ArchiveTheme.Brass.core.opacity(0.65), lineWidth: DesignTokens.Stroke.hairline)
                        .frame(width: size * 0.52, height: size * 0.52)
                    Text("+")
                        .font(.system(size: compact ? 28 : 46, weight: .light, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                } else {
                    Circle()
                        .stroke(ArchiveTheme.Brass.core.opacity(0.62), lineWidth: DesignTokens.Stroke.hairline)
                        .frame(width: size * 0.60, height: size * 0.48)

                    Circle()
                        .fill(ArchiveTheme.Brass.luster.opacity(0.88))
                        .frame(width: size * (compact ? 0.16 : 0.24))
                        .blur(radius: compact ? 8 : 14)

                    Text(theme == .violet ? "◌" : "✦")
                        .font(.system(size: compact ? 25 : 42, weight: .regular, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.primary)

                    ForEach(0..<8, id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? ArchiveTheme.Brass.luster : ArchiveTheme.Aether.light)
                            .frame(width: 2, height: compact ? 16 : 30)
                            .offset(y: -(size * 0.34))
                            .rotationEffect(.degrees(Double(index) * 45))
                            .opacity(0.84)
                    }
                }
            }
        }
        .aspectRatio(2 / 3, contentMode: .fit)
        .clipped()
        .accessibilityHidden(true)
    }
}

private struct BundledArtworkView: View {
    let resourceName: String
    let compact: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var decoded: CGImage?
    @State private var isMissing = false

    private var variant: ArtworkVariant {
        compact ? .tile : .hero
    }

    var body: some View {
        artwork
            .task(id: resourceName) { await loadIfNeeded() }
    }

    @ViewBuilder
    private var artwork: some View {
        // 先在主 actor 上同步读缓存：预热完成或看过一次之后，重绘不再等待解码。
        if let image = decoded ?? ArtworkStore.shared.cached(resourceName, variant) {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .transition(.opacity)
        } else if isMissing {
            // 没有这张卡图就走程序化卡面，不占图解流程。
            DivineFoolArtworkView(compact: compact)
        } else {
            // 解码在后台线程进行；这段时间保留卡面底色，不摆假图。
            Color.clear
        }
    }

    private func loadIfNeeded() async {
        guard decoded == nil, ArtworkStore.shared.cached(resourceName, variant) == nil else { return }
        guard let image = await ArtworkStore.shared.image(resourceName, variant) else {
            isMissing = true
            return
        }
        withAnimation(reduceMotion ? nil : .easeOut(duration: DesignTokens.MotionDuration.ms160)) {
            decoded = image
        }
    }
}

private struct DivineFoolArtworkView: View {
    let compact: Bool

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let lineWidth = compact ? 1.0 : 1.5

            ZStack {
                LinearGradient(
                    colors: [
                        DesignTokens.Palette.artworkDivineDusk,
                        ArchiveTheme.Leather.void,
                        DesignTokens.Palette.artworkDivineDeep
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // 琥珀神辉光晕 (对应 Logo 左侧金色灵流)
                RadialGradient(
                    colors: [ArchiveTheme.Brass.luster.opacity(0.36), .clear],
                    center: .init(x: 0.24, y: 0.39),
                    startRadius: 2,
                    endRadius: width * 0.52
                )

                // 灵界幽碧微光 (对应 Logo 右侧青碧灵流)
                RadialGradient(
                    colors: [ArchiveTheme.Aether.light.opacity(0.24), .clear],
                    center: .init(x: 0.82, y: 0.62),
                    startRadius: 2,
                    endRadius: width * 0.62
                )

                // 神秘学递归法阵回廊
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: width * 0.025, style: .continuous)
                        .stroke(
                            index.isMultiple(of: 2)
                                ? ArchiveTheme.Brass.luster.opacity(0.34)
                                : Color.white.opacity(0.18),
                            lineWidth: lineWidth
                        )
                        .frame(
                            width: width * (0.30 + Double(index) * 0.10),
                            height: height * (0.18 + Double(index) * 0.08)
                        )
                        .rotationEffect(.degrees(Double(index) * 8 - 20))
                        .offset(x: width * 0.07, y: height * (Double(index) * 0.045 - 0.04))
                        .blur(radius: index > 3 ? 0.4 : 0)
                }

                // 历史缝隙中的星辰轨迹
                Circle()
                    .stroke(ArchiveTheme.Brass.luster.opacity(0.58), lineWidth: lineWidth)
                    .frame(width: width * 0.24, height: width * 0.24)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.28), lineWidth: lineWidth)
                            .frame(width: width * 0.12, height: width * 0.12)
                    }
                    .overlay {
                        Image(systemName: "sparkle")
                            .font(.system(size: compact ? 14 : 23, weight: .light))
                            .foregroundStyle(ArchiveTheme.Brass.luster)
                    }
                    .rotationEffect(.degrees(-18))
                    .offset(x: -width * 0.21, y: -height * 0.18)

                ForEach(0..<3, id: \.self) { index in
                    Ellipse()
                        .stroke(
                            index == 1
                                ? ArchiveTheme.Brass.luster.opacity(0.68)
                                : Color.white.opacity(0.18),
                            lineWidth: lineWidth
                        )
                        .frame(width: width * (0.52 + Double(index) * 0.09), height: height * (0.20 + Double(index) * 0.07))
                        .rotationEffect(.degrees(Double(index) * 21 - 25))
                        .offset(x: -width * 0.12, y: -height * 0.17)
                }

                // 比例尺度锚点
                VStack(spacing: -1) {
                    Circle()
                        .fill(Color.black.opacity(0.85))
                        .frame(width: width * 0.026, height: width * 0.026)
                    Capsule()
                        .fill(Color.black.opacity(0.80))
                        .frame(width: width * 0.032, height: height * 0.080)
                }
                .shadow(color: ArchiveTheme.Brass.luster.opacity(0.42), radius: compact ? 4 : 8)
                .offset(x: width * 0.11, y: height * 0.13)

                // 命运波折线
                Path { path in
                    path.move(to: CGPoint(x: width * 0.61, y: -height * 0.04))
                    path.addCurve(
                        to: CGPoint(x: width * 0.48, y: height * 0.66),
                        control1: CGPoint(x: width * 0.42, y: height * 0.17),
                        control2: CGPoint(x: width * 0.72, y: height * 0.38)
                    )
                    path.addCurve(
                        to: CGPoint(x: width * 0.54, y: height * 0.84),
                        control1: CGPoint(x: width * 0.34, y: height * 0.73),
                        control2: CGPoint(x: width * 0.72, y: height * 0.75)
                    )
                }
                .stroke(ArchiveTheme.Brass.luster, style: StrokeStyle(lineWidth: compact ? 2 : 3, lineCap: .round))
                .shadow(color: ArchiveTheme.Brass.luster.opacity(0.72), radius: compact ? 4 : 10)

                Capsule()
                    .fill(ArchiveTheme.Leather.void)
                    .frame(width: width * 0.12, height: height * 0.055)
                    .overlay {
                        Capsule()
                            .stroke(ArchiveTheme.Brass.luster.opacity(0.50), style: StrokeStyle(lineWidth: lineWidth, dash: [3, 4]))
                    }
                    .offset(x: width * 0.02, y: height * 0.81)

                RoundedRectangle(cornerRadius: compact ? 16 : 24, style: .continuous)
                    .stroke(ArchiveTheme.Brass.luster.opacity(0.58), lineWidth: lineWidth)
            }
        }
    }
}

// MARK: - MetricTile (度量指标磁贴)

struct MetricTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
            Text(title)
                .font(.system(size: DesignTokens.FontSize.s11, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
            Text(value)
                .font(.system(size: DesignTokens.FontSize.s27, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
