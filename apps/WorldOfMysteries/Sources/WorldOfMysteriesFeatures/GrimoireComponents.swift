import SwiftUI
import WorldOfMysteriesCore

// MARK: - 1. 洛可可黄铜雕花包角 (Brass Corner Filigree)

/// 洛可可黄铜雕花金属包角
///
/// 还原 Logo 四角繁复华丽的维多利亚卷草纹金属护角与机械固定铆钉。
public struct BrassCornerFiligree: View {
    public enum Corner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight

        var rotation: Angle {
            switch self {
            case .topLeft: return .degrees(0)
            case .topRight: return .degrees(90)
            case .bottomRight: return .degrees(180)
            case .bottomLeft: return .degrees(270)
            }
        }
    }

    let corner: Corner
    let size: CGFloat

    public init(corner: Corner, size: CGFloat = 64) {
        self.corner = corner
        self.size = size
    }

    public var body: some View {
        ZStack {
            // 主包角金属折边
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: size, y: 0))
                path.addLine(to: CGPoint(x: size * 0.82, y: size * 0.18))
                path.addLine(to: CGPoint(x: size * 0.38, y: size * 0.18))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.18, y: size * 0.38),
                    control: CGPoint(x: size * 0.22, y: size * 0.22)
                )
                path.addLine(to: CGPoint(x: size * 0.18, y: size * 0.82))
                path.addLine(to: CGPoint(x: 0, y: size))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        ArchiveTheme.Brass.luster,
                        ArchiveTheme.Brass.core,
                        ArchiveTheme.Brass.patina
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: ArchiveTheme.Leather.void.opacity(0.65), radius: 3, x: 1, y: 1)

            // 金属内层卷草镂空藤蔓与凹槽
            Path { path in
                // 外弧卷草
                path.move(to: CGPoint(x: size * 0.12, y: size * 0.65))
                path.addCurve(
                    to: CGPoint(x: size * 0.65, y: size * 0.12),
                    control1: CGPoint(x: size * 0.18, y: size * 0.28),
                    control2: CGPoint(x: size * 0.28, y: size * 0.18)
                )
                // 次级涡卷装饰
                path.move(to: CGPoint(x: size * 0.24, y: size * 0.48))
                path.addQuadCurve(
                    to: CGPoint(x: size * 0.48, y: size * 0.24),
                    control: CGPoint(x: size * 0.32, y: size * 0.32)
                )
                // 顶端小卷花
                path.move(to: CGPoint(x: size * 0.08, y: size * 0.28))
                path.addLine(to: CGPoint(x: size * 0.28, y: size * 0.08))
            }
            .stroke(
                ArchiveTheme.Brass.gleam.opacity(0.85),
                style: StrokeStyle(lineWidth: DesignTokens.Stroke.strong, lineCap: .round)
            )

            // 洛可可圆润金属铆钉 (Rivet)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ArchiveTheme.Brass.luster,
                            ArchiveTheme.Brass.core,
                            ArchiveTheme.Leather.void
                        ],
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0.5,
                        endRadius: size * 0.06
                    )
                )
                .frame(width: size * 0.12, height: size * 0.12)
                .overlay {
                    Circle()
                        .stroke(ArchiveTheme.Brass.patina, lineWidth: DesignTokens.Stroke.thin)
                }
                .shadow(color: ArchiveTheme.Leather.void.opacity(0.8), radius: 1.5, x: 0.5, y: 0.5)
                .offset(x: -size * 0.22, y: -size * 0.22)
        }
        .frame(width: size, height: size)
        .rotationEffect(corner.rotation)
    }
}

// MARK: - 2. 赫密斯同心圆占星法阵 (Hermetic Sigil View)

/// 赫密斯同心圆占星法阵水印
///
/// 还原 Logo 封皮上压凹印的手工同心圆、占星刻度与非凡者双色灵流光晕。
public struct HermeticSigilView: View {
    let size: CGFloat
    let showDualGlow: Bool

    public init(size: CGFloat = 340, showDualGlow: Bool = true) {
        self.size = size
        self.showDualGlow = showDualGlow
    }

    public var body: some View {
        ZStack {
            if showDualGlow {
                // 左侧暖金与右侧以太幽碧双色灵焰微光 (Logo 核心)
                HStack(spacing: 0) {
                    Circle()
                        .fill(ArchiveTheme.Brass.luster.opacity(0.18))
                        .blur(radius: 40)
                    Circle()
                        .fill(ArchiveTheme.Aether.light.opacity(0.14))
                        .blur(radius: 40)
                }
                .frame(width: size * 1.1, height: size * 1.1)
            }

            // 外层同心圆轮廓 (带金属微反光与下陷阴影)
            Circle()
                .stroke(ArchiveTheme.Brass.core.opacity(0.35), lineWidth: DesignTokens.Stroke.strong)
                .frame(width: size * 0.96, height: size * 0.96)

            Circle()
                .stroke(ArchiveTheme.Brass.patina.opacity(0.40), lineWidth: DesignTokens.Stroke.hairline)
                .frame(width: size * 0.88, height: size * 0.88)

            // 12 星宫向心刻度线
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(
                        index.isMultiple(of: 3)
                            ? ArchiveTheme.Brass.luster.opacity(0.45)
                            : ArchiveTheme.Brass.patina.opacity(0.28)
                    )
                    .frame(width: index.isMultiple(of: 3) ? 1.5 : 1, height: index.isMultiple(of: 3) ? 14 : 8)
                    .offset(y: -(size * 0.44 - 4))
                    .rotationEffect(.degrees(Double(index) * 30))
            }

            // 中层符文圆环
            Circle()
                .stroke(ArchiveTheme.Brass.luster.opacity(0.28), style: StrokeStyle(lineWidth: DesignTokens.Stroke.medium, dash: [4, 6]))
                .frame(width: size * 0.74, height: size * 0.74)

            // 内接正八角星神圣几何 (八大非凡枢纽)
            ForEach(0..<2, id: \.self) { i in
                Rectangle()
                    .stroke(ArchiveTheme.Brass.core.opacity(0.20), lineWidth: DesignTokens.Stroke.hairline)
                    .frame(width: size * 0.50, height: size * 0.50)
                    .rotationEffect(.degrees(Double(i) * 45))
            }

            // 内层核心圆环
            Circle()
                .stroke(ArchiveTheme.Brass.core.opacity(0.30), lineWidth: DesignTokens.Stroke.hairline)
                .frame(width: size * 0.42, height: size * 0.42)

            // 核心神秘学交错菱形
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.08, weight: .light))
                .foregroundStyle(ArchiveTheme.Brass.luster.opacity(0.40))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - 3. 古籍书脊装订凸棱 (Grimoire Spine Bands)

/// 古籍书脊装订凸棱修饰器
///
/// 还原 Logo 左侧书脊上凸起的立体真皮装订横棱与深色凹槽，营造真实典籍装帧体量。
public struct GrimoireSpineBands: View {
    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            // 最左侧书脊边缘包边与缝线阴影
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            ArchiveTheme.Leather.void,
                            ArchiveTheme.Leather.deep,
                            ArchiveTheme.Leather.raised
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 6)

            // 3 道立体装订皮棱 (Raised Bands)
            VStack(spacing: 0) {
                Spacer(minLength: DesignTokens.Space.s40)
                bandSegment
                Spacer()
                bandSegment
                Spacer()
                bandSegment
                Spacer(minLength: DesignTokens.Space.s60)
            }
            .frame(width: 4)

            Spacer()
        }
        .accessibilityHidden(true)
    }

    private var bandSegment: some View {
        VStack(spacing: 0) {
            // 凸棱顶部受光高光
            Rectangle()
                .fill(ArchiveTheme.Leather.highlight.opacity(0.7))
                .frame(height: 2)
            // 凸棱本体
            Rectangle()
                .fill(ArchiveTheme.Brass.patina.opacity(0.35))
                .frame(height: 24)
            // 凸棱底部下沉阴影
            Rectangle()
                .fill(ArchiveTheme.Leather.void.opacity(0.9))
                .frame(height: 3)
        }
        .cornerRadius(DesignTokens.Radius.ridge)
        .shadow(color: ArchiveTheme.Leather.void.opacity(0.8), radius: 2, x: 1, y: 1)
    }
}

// MARK: - 4. 古典羊皮纸六维卷宗磁贴 (Parchment Semantic Tile)

/// 古典羊皮纸六维卷宗磁贴
///
/// 还原羊皮纸档案卷宗与古典旧墨水手写质感，彻底消除无质感的现代灰色色块。
public struct ParchmentSemanticTile: View {
    let index: String
    let title: String
    let value: String
    let accentColor: Color

    public init(index: String, title: String, value: String, accentColor: Color) {
        self.index = index
        self.title = title
        self.value = value
        self.accentColor = accentColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s7) {
            HStack(spacing: DesignTokens.Space.s8) {
                // 羊皮纸金属封印印记 (带黄铜外圈与内部索引号)
                ZStack {
                    Circle()
                        .fill(ArchiveTheme.Leather.deep)
                        .frame(width: 20, height: 20)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [ArchiveTheme.Brass.luster, ArchiveTheme.Brass.patina],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: DesignTokens.Stroke.hairline
                        )
                        .frame(width: 20, height: 20)
                    Text(index)
                        .font(.system(size: DesignTokens.FontSize.s9, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                }

                Text(title)
                    .font(.system(size: DesignTokens.FontSize.s12, weight: .bold, design: .serif))
                    .foregroundStyle(ArchiveTheme.Parchment.primary)

                Spacer()

                // 微弱灵性状态呼吸点
                Circle()
                    .fill(accentColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: accentColor.opacity(0.6), radius: 3)
            }

            Text(value)
                .font(.system(size: DesignTokens.FontSize.s11, weight: .medium))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Space.s12)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .background {
            // 真实古旧羊皮纸叠层底纹
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r10, style: .continuous)
                    .fill(ArchiveTheme.Leather.base.opacity(0.72))
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                ArchiveTheme.Parchment.primary.opacity(0.06),
                                ArchiveTheme.Brass.patina.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .overlay {
            // 细致的暗金羊皮纸裁切边线
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r10, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            ArchiveTheme.Brass.patina.opacity(0.42),
                            ArchiveTheme.Borders.subtle
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: DesignTokens.Stroke.hairline
                )
        }
    }
}
