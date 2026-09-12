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
        .background(status.accentColor.opacity(0.13), in: Capsule())
        .overlay {
            Capsule()
                .stroke(status.accentColor.opacity(0.30), lineWidth: 1)
        }
    }
}

struct ArchiveArtworkView: View {
    let theme: VisualTheme
    let compact: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
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
                    .fill((theme == .violet ? ArchiveTheme.violet : ArchiveTheme.teal).opacity(0.48))
                    .frame(width: size * 0.62, height: size * 0.62)
                    .blur(radius: compact ? 24 : 44)

                if theme == .empty {
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
