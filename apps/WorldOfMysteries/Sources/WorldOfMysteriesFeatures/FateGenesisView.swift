import SwiftUI
import WorldOfMysteriesCore

/// 命运生成界面（PRD §3.4）：让用户看到「即将进入什么」，同时不泄露幕后真相。
struct FateGenesisSheet: View {
    let card: AlbumCard
    let entry: FateEntry
    let presentation: FateGenesisPresentation
    @ObservedObject var model: AlbumViewModel

    @State private var variant = 0
    @State private var isWeaving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s18) {
            HStack(alignment: .top, spacing: DesignTokens.Space.s18) {
                cardThumbnail
                VStack(alignment: .leading, spacing: DesignTokens.Space.s7) {
                    Text(entry.kind.actionTitle)
                        .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                    Text(card.identity.displayName)
                        .font(.system(size: DesignTokens.FontSize.s24, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.primary)
                    Text(ArchiveCopy.sequenceDisplayLabel(for: card.identity.sequenceName, includesRank: true))
                        .font(.system(size: DesignTokens.FontSize.s12, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    Text(presentation.entryNote)
                        .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider().overlay(ArchiveTheme.Borders.subtle)

            if isWeaving {
                weavingIndicator
            } else {
                seedSection
                Text(presentation.disclosureNote)
                    .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.muted)
                actions
            }
        }
        .padding(DesignTokens.Space.s24)
        .frame(width: 520)
        .background(ArchiveTheme.Leather.base)
    }

    // MARK: - 卡面

    private var cardThumbnail: some View {
        ArchiveArtworkView(
            theme: card.visualTheme,
            compact: true,
            resourceName: card.artworkResourceName
        )
        .frame(width: 96, height: 144)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
                .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityHidden(true)
    }

    // MARK: - 可见种子

    private var seedSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
            Text(WorldShellCopy.genesisHint)
                .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
            VStack(alignment: .leading, spacing: DesignTokens.Space.s9) {
                ForEach(presentation.visibleFields(at: variant)) { field in
                    HStack(alignment: .top, spacing: DesignTokens.Space.s12) {
                        Text(field.label)
                            .font(.system(size: DesignTokens.FontSize.s10, weight: .bold, design: .rounded))
                            .foregroundStyle(ArchiveTheme.Brass.luster)
                            .frame(width: 36, alignment: .leading)
                        Text(field.value)
                            .font(.system(size: DesignTokens.FontSize.s14, weight: .medium, design: .serif))
                            .foregroundStyle(ArchiveTheme.Parchment.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(DesignTokens.Space.s16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ArchiveTheme.Leather.deep.opacity(0.55), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                    .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.hairline)
            }
            .id(variant)
            .transition(.opacity)
        }
    }

    // MARK: - 编织中

    private var weavingIndicator: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s12) {
            HStack(spacing: DesignTokens.Space.s10) {
                ProgressView()
                    .controlSize(.small)
                Text(WorldShellCopy.weavingTitle)
                    .font(.system(size: DesignTokens.FontSize.s14, weight: .semibold, design: .serif))
                    .foregroundStyle(ArchiveTheme.Parchment.primary)
            }
            VStack(alignment: .leading, spacing: DesignTokens.Space.s6) {
                ForEach(WorldShellCopy.weavingLayers, id: \.self) { layer in
                    HStack(spacing: DesignTokens.Space.s8) {
                        Circle()
                            .fill(ArchiveTheme.Aether.light)
                            .frame(width: 5, height: 5)
                        Text(layer)
                            .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                            .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    }
                }
            }
        }
        .padding(.vertical, DesignTokens.Space.s8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - 操作

    private var actions: some View {
        HStack(spacing: DesignTokens.Space.s10) {
            Button(presentation.primaryActionTitle) {
                weave()
            }
            .buttonStyle(ShellPrimaryButtonStyle())
            .keyboardShortcut(.defaultAction)

            Button(presentation.secondaryActionTitle) {
                swapVariant()
            }
            .buttonStyle(ShellSecondaryButtonStyle())

            Spacer()

            Button(WorldShellCopy.cancel) {
                model.dismissFateGenesis()
            }
            .buttonStyle(ShellSecondaryButtonStyle())
            .keyboardShortcut(.cancelAction)
        }
    }

    private func swapVariant() {
        guard presentation.seedCount > 1 else {
            return
        }
        if reduceMotion {
            variant = (variant + 1) % presentation.seedCount
        } else {
            withAnimation(.easeOut(duration: DesignTokens.MotionDuration.ms180)) {
                variant = (variant + 1) % presentation.seedCount
            }
        }
    }

    private func weave() {
        isWeaving = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            model.beginFate(for: card)
        }
    }
}
