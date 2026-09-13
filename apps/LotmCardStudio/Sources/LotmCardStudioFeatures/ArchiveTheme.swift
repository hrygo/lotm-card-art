import AppKit
import SwiftUI
import LotmCardStudioCore

/// 《诡秘之主》秘史档案馆设计 Token 系统
///
/// 基于 App Logo（典藏原版 · 方案 B-1 复古牛皮与温润黄铜）提取的高精度色谱与质感构建。
/// 架构包含：Primitives（原始色谱）、Semantic Roles（语义角色）、Materials & Gradients（材质光影）。
enum ArchiveTheme {

    // MARK: - 1. Primitives (Logo 实测聚类原始色谱)

    /// 复古牛皮系列（Vintage Leather）
    enum Leather {
        /// 深邃星界虚空底盘 (#04080D) - 极暗沉浸
        static let void = Color(red: 0.016, green: 0.031, blue: 0.051)
        /// 鞣制古籍牛皮原色 (#1A181A) - 典籍封面基底
        static let deep = Color(red: 0.102, green: 0.094, blue: 0.102)
        /// 古籍封面本体牛皮 (#1F1D1E) - 侧栏与基底表面
        static let base = Color(red: 0.122, green: 0.114, blue: 0.118)
        /// 皮革凸棱骨架 (#2E2C2D) - 结构抬升与卡片底板
        static let raised = Color(red: 0.180, green: 0.173, blue: 0.176)
        /// 卡槽下沉与压印阴影 (#474441) - 分割线与浮雕深色
        static let elevated = Color(red: 0.278, green: 0.267, blue: 0.255)
        /// 皮革磨损泛光边 (#615C57) - 微弱暖灰高光
        static let highlight = Color(red: 0.380, green: 0.360, blue: 0.340)
    }

    /// 古典洛可可温润黄铜系列 (Antique Brass & Gold)
    enum Brass {
        /// 氧化暗铜包浆 (#6E6458) - 辅助弱化金属边
        static let patina = Color(red: 0.431, green: 0.392, blue: 0.345)
        /// 温润黄铜五金本体 (#A49274) - 锁扣与包角主体
        static let core = Color(red: 0.643, green: 0.573, blue: 0.455)
        /// 金属浮雕中调光 (#D1BF99) - 纹饰高光过渡
        static let gleam = Color(red: 0.820, green: 0.749, blue: 0.600)
        /// 洛可可黄铜高光与琥珀神辉 (#E8D2A1) - 核心金属反光与圣杯金
        static let luster = Color(red: 0.910, green: 0.824, blue: 0.631)
    }

    /// 序列灵界以太系列 (Ethereal Aether & Teal)
    enum Aether {
        /// 深层以太暗流
        static let deep = Color(red: 0.12, green: 0.25, blue: 0.24)
        /// 灵流主色
        static let core = Color(red: 0.30, green: 0.68, blue: 0.63)
        /// Logo 中央卡牌灵性幽碧流光 (#A2D7CE)
        static let light = Color(red: 0.635, green: 0.843, blue: 0.808)
    }

    /// 古典羊皮纸文字系列 (Parchment Typography)
    enum Parchment {
        /// 暖色羊皮纸高亮正文 (#F2EFE9) - 具备羊皮纸温润感，替代冷白
        static let primary = Color(red: 0.949, green: 0.937, blue: 0.914)
        /// 典籍墨水中调说明字 (#A39E93) - 次级信息
        static let secondary = Color(red: 0.639, green: 0.620, blue: 0.576)
        /// 暗金沉淀辅助弱化字 (#6E6458) - 脚注与元信息
        static let muted = Color(red: 0.431, green: 0.392, blue: 0.345)
    }

    /// 故事页羊皮纸卷宗系列（Aged Story Folio）
    ///
    /// 故事正文使用温暖的旧纸中间调，保留暗色档案馆的沉浸感，
    /// 只让正文成为一页被翻开的卷宗，而不是突兀的浅色卡片。
    enum Story {
        static let paper = Color(red: 0.300, green: 0.260, blue: 0.205)
        static let paperHighlight = Color(red: 0.870, green: 0.790, blue: 0.610)
        static let ink = Parchment.primary
        static let inkMuted = Parchment.secondary
        static let edge = Brass.gleam.opacity(0.58)
        static let shadow = Leather.void.opacity(0.72)

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
        static let violet = Color(red: 0.52, green: 0.44, blue: 0.76)
        /// 窥秘冰蓝 (#85AED1) - 聚焦高亮与空想家冷理智
        static let ice = Color(red: 0.52, green: 0.68, blue: 0.82)
        /// 血月警戒红 (#D95454) - 失控、危险与限制条件
        static let crimson = Color(red: 0.85, green: 0.33, blue: 0.33)
    }

    // MARK: - 2. Semantic Aliases (完全向下兼容既有调用)

    static let ink = Leather.void
    static let coal = Leather.deep
    static let raised = Leather.raised
    static let elevated = Leather.elevated
    static let primary = Parchment.primary
    static let secondary = Parchment.secondary
    static let amber = Brass.luster
    static let teal = Aether.light
    static let violet = Mystic.violet
    static let ice = Mystic.ice
    static let danger = Mystic.crimson

    // MARK: - 3. Gradients (古典魔典与黄铜光泽材质)

    enum Gradients {
        /// 古籍封皮深色渐变（从深皮过渡至暗渊星底）
        static let grimoireCover = LinearGradient(
            colors: [Leather.deep, Leather.void],
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
            colors: [Brass.patina, Brass.luster, Brass.core],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        /// 双色神圣灵界光流（金光与青碧交织，对应 Logo 卡牌）
        static let divineGaze = RadialGradient(
            colors: [Brass.luster.opacity(0.38), Aether.light.opacity(0.16), .clear],
            center: .center,
            startRadius: 4,
            endRadius: 280
        )
    }

    // MARK: - 4. Borders & Lines (边框与分割线)

    enum Borders {
        /// 皮革与金属交界微弱边框
        static let subtle = Leather.elevated.opacity(0.65)
        /// 暗铜包浆线框
        static let brassMuted = Brass.patina.opacity(0.50)
        /// 洛可可黄铜高光金边
        static let brassAccent = Brass.luster.opacity(0.40)
        /// 灵性幽碧流光边框
        static let aetherGlow = Aether.light.opacity(0.45)
    }

    // MARK: - 5. Dynamic Tokens (动态交互与微动效)

    enum Tokens {
        enum Motion {
            /// 触觉回弹微动效（按键、卡槽下压）
            static let tactilePress = Animation.spring(response: 0.22, dampingFraction: 0.68)
            /// 悬浮过渡动效
            static let hoverSpring = Animation.spring(response: 0.32, dampingFraction: 0.78)
            /// 灵流呼吸循环
            static let aetherBreathe = Animation.easeInOut(duration: 2.8).repeatForever(autoreverses: true)
        }

        enum Shadows {
            /// 黄铜圣光点燃光晕
            static let brassGlow = Color(red: 0.910, green: 0.824, blue: 0.631).opacity(0.38)
            /// 灵界以太幽碧光晕
            static let aetherPulse = Color(red: 0.635, green: 0.843, blue: 0.808).opacity(0.45)
            /// 古籍真皮深渊暗影
            static let leatherPlinth = Color(red: 0.016, green: 0.031, blue: 0.051).opacity(0.85)
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
            return ArchiveTheme.Brass.core
        case .proposed:
            return ArchiveTheme.Mystic.violet
        case .unresearched:
            return ArchiveTheme.Brass.luster
        case .confirmed:
            return ArchiveTheme.Aether.light
        }
    }
}

// MARK: - StatusChip (状态胶囊标签)

struct StatusChip: View {
    let status: ContentStatus

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(status.accentColor)
                .frame(width: 7, height: 7)
            Text(status.displayTitle)
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .foregroundStyle(status.accentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(
            .regular.tint(status.accentColor.opacity(0.14)),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .stroke(status.accentColor.opacity(0.28), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("内容状态：\(status.displayTitle)")
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
            let glowColor = theme == .violet
                ? ArchiveTheme.Mystic.violet
                : (theme == .visionary ? ArchiveTheme.Mystic.ice : ArchiveTheme.Aether.light)
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 16 : 24, style: .continuous)
                    .fill(ArchiveTheme.Gradients.grimoireCover)

                Circle()
                    .fill(glowColor.opacity(0.42))
                    .frame(width: size * 0.62, height: size * 0.62)
                    .blur(radius: compact ? 24 : 44)

                if let resourceName {
                    BundledArtworkView(resourceName: resourceName, compact: compact)
                } else if theme == .divineFool {
                    DivineFoolArtworkView(compact: compact)
                } else if theme == .empty {
                    Circle()
                        .stroke(ArchiveTheme.Brass.core.opacity(0.65), lineWidth: 1)
                        .frame(width: size * 0.52, height: size * 0.52)
                    Text("+")
                        .font(.system(size: compact ? 28 : 46, weight: .light, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                } else {
                    Circle()
                        .stroke(ArchiveTheme.Brass.core.opacity(0.62), lineWidth: 1)
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

    var body: some View {
        if let image = Self.loadImage(named: resourceName) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            DivineFoolArtworkView(compact: compact)
        }
    }

    private static func loadImage(named resourceName: String) -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: resourceName,
            withExtension: "png",
            subdirectory: "CardArt"
        ) else {
            return nil
        }
        return NSImage(contentsOf: url)
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
                        Color(red: 0.08, green: 0.06, blue: 0.11),
                        ArchiveTheme.Leather.void,
                        Color(red: 0.04, green: 0.08, blue: 0.13)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
            Text(value)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
