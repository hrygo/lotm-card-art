import SwiftUI
import WorldOfMysteriesCore

/// 世界外壳共用的轻量组件。
///
/// 视觉语言沿用档案馆材质，但比卡面更克制：世界、人物与故事书以信息为主，
/// 不使用卡面的华丽装饰（PRD §5.1）。

struct ShellSectionHeader: View {
    let eyebrow: String?
    let title: String
    let note: String?
    var accent: Color = ArchiveTheme.Aether.light

    init(eyebrow: String? = nil, title: String, note: String? = nil, accent: Color = ArchiveTheme.Aether.light) {
        self.eyebrow = eyebrow
        self.title = title
        self.note = note
        self.accent = accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s5) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.system(size: DesignTokens.FontSize.s10, weight: .bold, design: .serif))
                    .foregroundStyle(accent)
            }
            Text(title)
                .font(.system(size: DesignTokens.FontSize.s17, weight: .bold, design: .serif))
                .foregroundStyle(ArchiveTheme.Parchment.primary)
            if let note {
                Text(note)
                    .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct ShellPanel<Content: View>: View {
    var tint: Color = ArchiveTheme.Aether.light
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s16) {
            content()
        }
        .padding(DesignTokens.Space.s20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArchiveTheme.Gradients.leatherSurface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r18, style: .continuous))
        .glassEffect(.regular.tint(tint.opacity(0.06)), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r18, style: .continuous)
                .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.hairline)
        }
    }
}

struct ShellChip: View, Identifiable {
    let text: String
    var color: Color = ArchiveTheme.Parchment.secondary
    var isProminent = false

    nonisolated var id: String {
        text
    }

    var body: some View {
        Text(text)
            .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
            .foregroundStyle(isProminent ? ArchiveTheme.ink : color)
            .padding(.horizontal, DesignTokens.Space.s8)
            .padding(.vertical, DesignTokens.Space.s3)
            .background(
                Capsule(style: .continuous)
                    .fill(isProminent ? color.opacity(0.92) : color.opacity(0.14))
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(isProminent ? .clear : color.opacity(0.42), lineWidth: DesignTokens.Stroke.hairline)
            }
    }
}

/// 「示例」标记：世界、人物与故事书持续可见，说明这里的内容不是核验过的原著事实（PRD §7.2）。
struct ShellSampleBadge: View {
    let status: WorldDataStatus

    var body: some View {
        Label(status.label, systemImage: "info.circle")
            .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
            .foregroundStyle(ArchiveTheme.Brass.gleam)
            .padding(.horizontal, DesignTokens.Space.s9)
            .padding(.vertical, DesignTokens.Space.s4)
            .background(ArchiveTheme.Brass.core.opacity(0.16), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.hairline)
            }
            .help(status.note ?? "")
            .accessibilityLabel(status.note ?? status.label)
    }
}

struct ShellEmptyState: View {
    let symbol: String
    let title: String
    let note: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: DesignTokens.Space.s12) {
            Image(systemName: symbol)
                .font(.system(size: DesignTokens.FontSize.s24, weight: .light))
                .foregroundStyle(ArchiveTheme.Brass.luster)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: DesignTokens.FontSize.s16, weight: .bold, design: .serif))
                .foregroundStyle(ArchiveTheme.Parchment.primary)
            Text(note)
                .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(ShellPrimaryButtonStyle())
                    .padding(.top, DesignTokens.Space.s4)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .padding(DesignTokens.Space.s24)
        .background(ArchiveTheme.Leather.deep.opacity(0.55), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r18, style: .continuous)
                .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .contain)
    }
}

/// 可点击的信息行：用于事件、人物、命运与地点变化。
struct ShellRow: View {
    let title: String
    let detail: String?
    let meta: String?
    var chips: [ShellChip] = []
    var symbol: String?
    var isEnabled = true
    var action: (() -> Void)?

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        if let action, isEnabled {
            Button(action: action) {
                row
            }
            .buttonStyle(ShellRowButtonStyle())
        } else {
            row
        }
    }

    private var row: some View {
        HStack(alignment: .top, spacing: DesignTokens.Space.s12) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: DesignTokens.FontSize.s13, weight: .medium))
                    .foregroundStyle(isEnabled ? ArchiveTheme.Aether.light : ArchiveTheme.Parchment.muted)
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: DesignTokens.Space.s5) {
                Text(title)
                    .font(.system(size: DesignTokens.FontSize.s13, weight: .semibold, design: .serif))
                    .foregroundStyle(isEnabled ? ArchiveTheme.Parchment.primary : ArchiveTheme.Parchment.muted)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let meta {
                    Text(meta)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .medium, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Parchment.muted)
                }
                if !chips.isEmpty {
                    HStack(spacing: DesignTokens.Space.s6) {
                        ForEach(chips) { chip in
                            chip
                        }
                    }
                    .padding(.top, DesignTokens.Space.s2)
                }
            }
            Spacer(minLength: DesignTokens.Space.s8)
            if action != nil, isEnabled {
                Image(systemName: "chevron.right")
                    .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold))
                    .foregroundStyle(ArchiveTheme.Parchment.muted)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, DesignTokens.Space.s10)
        .padding(.horizontal, DesignTokens.Space.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArchiveTheme.Leather.deep.opacity(0.42), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
                .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.hairline)
        }
    }
}

struct ShellRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // 行级可点区域：按下反馈不改几何，避免靠近行边缘的按下被缩小后的命中区域漏掉（PRD §4.6）。
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(ArchiveTheme.Tokens.Motion.tactilePress, value: configuration.isPressed)
            .archiveInteractiveSurface(accent: ArchiveTheme.Brass.luster, cornerRadius: DesignTokens.Radius.r12, hoverScale: 1.0)
    }
}

struct ShellPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DesignTokens.FontSize.s13, weight: .bold, design: .rounded))
            .foregroundStyle(ArchiveTheme.ink)
            .padding(.horizontal, DesignTokens.Space.s18)
            .padding(.vertical, DesignTokens.Space.s9)
            .background(
                ArchiveTheme.Gradients.brassGleam,
                in: Capsule(style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(ArchiveTheme.Tokens.Motion.tactilePress, value: configuration.isPressed)
    }
}

struct ShellSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DesignTokens.FontSize.s12, weight: .semibold, design: .rounded))
            .foregroundStyle(ArchiveTheme.Parchment.primary)
            .padding(.horizontal, DesignTokens.Space.s14)
            .padding(.vertical, DesignTokens.Space.s7)
            .background(ArchiveTheme.Leather.elevated.opacity(0.35), in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.hairline)
            }
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(ArchiveTheme.Tokens.Motion.tactilePress, value: configuration.isPressed)
    }
}

/// 侧边栏的一级区域按钮。
struct ShellAreaButton: View {
    let area: PrimaryArea
    let isSelected: Bool
    let badge: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Space.s10) {
                Image(systemName: area.symbol)
                    .font(.system(size: DesignTokens.FontSize.s12, weight: .semibold))
                    .frame(width: 18)
                    .accessibilityHidden(true)
                Text(area.title)
                    .font(.system(size: DesignTokens.FontSize.s13, weight: .semibold, design: .serif))
                Spacer(minLength: DesignTokens.Space.s6)
                if let badge {
                    Text(badge)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                        .foregroundStyle(isSelected ? ArchiveTheme.Brass.luster : ArchiveTheme.Parchment.muted)
                }
            }
            .foregroundStyle(isSelected ? ArchiveTheme.Parchment.primary : ArchiveTheme.Parchment.secondary)
            .padding(.horizontal, DesignTokens.Space.s12)
            .padding(.vertical, DesignTokens.Space.s8)
            .background(
                isSelected ? ArchiveTheme.Brass.core.opacity(0.20) : .clear,
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r10, style: .continuous)
                    .stroke(isSelected ? ArchiveTheme.Borders.brassAccent : .clear, lineWidth: DesignTokens.Stroke.hairline)
            }
            // 整行都是点击范围：圆角外侧与右侧留白也属于这一行。
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .archiveInteractiveSurface(accent: ArchiveTheme.Brass.luster, cornerRadius: DesignTokens.Radius.r10)
        .help(area.summary)
    }
}
