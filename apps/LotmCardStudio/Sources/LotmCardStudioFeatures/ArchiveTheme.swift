import AppKit
import SwiftUI
import LotmCardStudioCore

enum ArchiveTheme {
    static let ink = Color(red: 0.035, green: 0.047, blue: 0.075)
    static let coal = Color(red: 0.055, green: 0.071, blue: 0.11)
    static let raised = Color(red: 0.09, green: 0.11, blue: 0.16)
    static let elevated = Color(red: 0.13, green: 0.15, blue: 0.21)
    static let primary = Color(red: 0.93, green: 0.92, blue: 0.88)
    static let secondary = Color(red: 0.60, green: 0.63, blue: 0.69)
    static let amber = Color(red: 0.89, green: 0.69, blue: 0.39)
    static let teal = Color(red: 0.39, green: 0.85, blue: 0.77)
    static let violet = Color(red: 0.56, green: 0.47, blue: 0.84)
    static let ice = Color(red: 0.56, green: 0.73, blue: 0.86)
    static let danger = Color(red: 0.88, green: 0.42, blue: 0.41)
}

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
            return ArchiveTheme.amber
        case .proposed:
            return ArchiveTheme.violet
        case .unresearched:
            return ArchiveTheme.amber
        case .confirmed:
            return ArchiveTheme.teal
        }
    }
}

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
            .regular.tint(status.accentColor.opacity(0.13)),
            in: Capsule()
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("内容状态：\(status.displayTitle)")
    }
}

struct ArchiveArtworkView: View {
    let theme: VisualTheme
    let compact: Bool
    let resourceName: String?

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let glowColor = theme == .violet
                ? ArchiveTheme.violet
                : (theme == .visionary ? ArchiveTheme.ice : ArchiveTheme.teal)
            ZStack {
                RoundedRectangle(cornerRadius: compact ? 16 : 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [ArchiveTheme.coal, ArchiveTheme.ink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(glowColor.opacity(0.48))
                    .frame(width: size * 0.62, height: size * 0.62)
                    .blur(radius: compact ? 24 : 44)

                if let resourceName {
                    BundledArtworkView(resourceName: resourceName, compact: compact)
                } else if theme == .divineFool {
                    DivineFoolArtworkView(compact: compact)
                } else if theme == .empty {
                    Circle()
                        .stroke(ArchiveTheme.amber.opacity(0.65), lineWidth: 1)
                        .frame(width: size * 0.52, height: size * 0.52)
                    Text("+")
                        .font(.system(size: compact ? 28 : 46, weight: .light, design: .rounded))
                        .foregroundStyle(ArchiveTheme.amber)
                } else {
                    Circle()
                        .stroke(ArchiveTheme.amber.opacity(0.62), lineWidth: 1)
                        .frame(width: size * 0.60, height: size * 0.48)

                    Circle()
                        .fill(ArchiveTheme.amber.opacity(0.88))
                        .frame(width: size * (compact ? 0.16 : 0.24))
                        .blur(radius: compact ? 8 : 14)

                    Text(theme == .violet ? "◌" : "✦")
                        .font(.system(size: compact ? 25 : 42, weight: .regular, design: .serif))
                        .foregroundStyle(ArchiveTheme.primary)

                    ForEach(0..<8, id: \.self) { index in
                        Rectangle()
                            .fill(index.isMultiple(of: 2) ? ArchiveTheme.amber : ArchiveTheme.teal)
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
                        Color(red: 0.08, green: 0.05, blue: 0.12),
                        ArchiveTheme.ink,
                        Color(red: 0.05, green: 0.09, blue: 0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RadialGradient(
                    colors: [ArchiveTheme.amber.opacity(0.34), .clear],
                    center: .init(x: 0.24, y: 0.39),
                    startRadius: 2,
                    endRadius: width * 0.52
                )

                RadialGradient(
                    colors: [Color.white.opacity(0.22), .clear],
                    center: .init(x: 0.82, y: 0.62),
                    startRadius: 2,
                    endRadius: width * 0.62
                )

                // The divine realm is represented as a self-completing field of
                // recursive corridors rather than a humanoid subject.
                ForEach(0..<6, id: \.self) { index in
                    RoundedRectangle(cornerRadius: width * 0.025, style: .continuous)
                        .stroke(
                            index.isMultiple(of: 2)
                                ? ArchiveTheme.amber.opacity(0.32)
                                : Color.white.opacity(0.16),
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

                // A star and its orbit are grafted into the history seam.
                Circle()
                    .stroke(ArchiveTheme.amber.opacity(0.58), lineWidth: lineWidth)
                    .frame(width: width * 0.24, height: width * 0.24)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.28), lineWidth: lineWidth)
                            .frame(width: width * 0.12, height: width * 0.12)
                    }
                    .overlay {
                        Image(systemName: "sparkle")
                            .font(.system(size: compact ? 14 : 23, weight: .light))
                            .foregroundStyle(ArchiveTheme.amber)
                    }
                    .rotationEffect(.degrees(-18))
                    .offset(x: -width * 0.21, y: -height * 0.18)

                ForEach(0..<3, id: \.self) { index in
                    Ellipse()
                        .stroke(
                            index == 1
                                ? ArchiveTheme.amber.opacity(0.68)
                                : Color.white.opacity(0.18),
                            lineWidth: lineWidth
                        )
                        .frame(width: width * (0.52 + Double(index) * 0.09), height: height * (0.20 + Double(index) * 0.07))
                        .rotationEffect(.degrees(Double(index) * 21 - 25))
                        .offset(x: -width * 0.12, y: -height * 0.17)
                }

                // One small, faceless identity residue establishes scale without
                // turning the True God into a character portrait.
                VStack(spacing: -1) {
                    Circle()
                        .fill(Color.black.opacity(0.82))
                        .frame(width: width * 0.026, height: width * 0.026)
                    Capsule()
                        .fill(Color.black.opacity(0.76))
                        .frame(width: width * 0.032, height: height * 0.080)
                }
                .shadow(color: ArchiveTheme.amber.opacity(0.40), radius: compact ? 4 : 8)
                .offset(x: width * 0.11, y: height * 0.13)

                // History folds into one seam, then stops at a dark discontinuity.
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
                .stroke(ArchiveTheme.amber, style: StrokeStyle(lineWidth: compact ? 2 : 3, lineCap: .round))
                .shadow(color: ArchiveTheme.amber.opacity(0.72), radius: compact ? 4 : 10)

                Capsule()
                    .fill(ArchiveTheme.ink)
                    .frame(width: width * 0.12, height: height * 0.055)
                    .overlay {
                        Capsule()
                            .stroke(ArchiveTheme.amber.opacity(0.50), style: StrokeStyle(lineWidth: lineWidth, dash: [3, 4]))
                    }
                    .offset(x: width * 0.02, y: height * 0.81)

                RoundedRectangle(cornerRadius: compact ? 16 : 24, style: .continuous)
                    .stroke(ArchiveTheme.amber.opacity(0.58), lineWidth: lineWidth)
            }
        }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
            Text(value)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
