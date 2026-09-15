import AppKit
import SwiftUI

private struct ArchiveCursorModifier: ViewModifier {
    let cursor: NSCursor

    func body(content: Content) -> some View {
        content.onHover { isHovering in
            if isHovering {
                cursor.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

private struct ArchiveInteractiveSurfaceModifier: ViewModifier {
    let accent: Color
    let cornerRadius: CGFloat
    let hoverScale: CGFloat
    let isInteractive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isFocused) private var isFocused
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .overlay { decoration.allowsHitTesting(false) }
            .contentShape(Rectangle())
            .onHover { isHovered = isInteractive && $0 }
            .scaleEffect(isInteractive && isHovered && !reduceMotion ? hoverScale : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: DesignTokens.MotionDuration.ms160),
                value: isHovered
            )
            .modifier(
                ArchiveCursorModifier(
                    cursor: isInteractive ? .pointingHand : .arrow
                )
            )
    }

    /// 悬停描边与焦点环只是可见状态提示，必须整层退出命中测试：描边正好压在控件边界上，
    /// 焦点环还向外多占 3pt；它们若参与命中，落在边界或环上的点击会被装饰吃掉，
    /// 表现为「点在同一行上，有时有效、有时没有反应」。
    private var decoration: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(accent.opacity(isInteractive && isHovered ? 0.62 : 0), lineWidth: DesignTokens.Stroke.hairline)
            RoundedRectangle(cornerRadius: cornerRadius + 2, style: .continuous)
                .stroke(
                    ArchiveTheme.ice.opacity(isInteractive && isFocused ? 0.92 : 0),
                    lineWidth: isInteractive && isFocused ? 2 : 0
                )
                .padding(-3)
        }
    }
}

extension View {
    func archiveCursor(_ cursor: NSCursor) -> some View {
        modifier(ArchiveCursorModifier(cursor: cursor))
    }

    func archiveInteractiveSurface(
        accent: Color,
        cornerRadius: CGFloat,
        hoverScale: CGFloat = 1,
        isInteractive: Bool = true
    ) -> some View {
        modifier(
            ArchiveInteractiveSurfaceModifier(
                accent: accent,
                cornerRadius: cornerRadius,
                hoverScale: hoverScale,
                isInteractive: isInteractive
            )
        )
    }
}
