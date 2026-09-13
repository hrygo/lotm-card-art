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
            .contentShape(Rectangle())
            .onHover { isHovered = isInteractive && $0 }
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(accent.opacity(isInteractive && isHovered ? 0.62 : 0), lineWidth: 1)
                    RoundedRectangle(cornerRadius: cornerRadius + 2, style: .continuous)
                        .stroke(
                            ArchiveTheme.ice.opacity(isInteractive && isFocused ? 0.92 : 0),
                            lineWidth: isInteractive && isFocused ? 2 : 0
                        )
                        .padding(-3)
                }
            }
            .scaleEffect(isInteractive && isHovered && !reduceMotion ? hoverScale : 1)
            .animation(
                reduceMotion ? nil : .easeOut(duration: 0.16),
                value: isHovered
            )
            .modifier(
                ArchiveCursorModifier(
                    cursor: isInteractive ? .pointingHand : .arrow
                )
            )
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
