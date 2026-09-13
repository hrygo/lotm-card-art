import SwiftUI
import LotmCardStudioCore

@MainActor
public struct ArchiveRootView: View {
    @StateObject private var model: AlbumViewModel
    @StateObject private var playback: SpeechPlaybackCoordinator
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    public init(speechClient: SpeechRailHTTPClient? = nil) {
        _model = StateObject(wrappedValue: AlbumViewModel())
        _playback = StateObject(wrappedValue: SpeechPlaybackCoordinator(client: speechClient))
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            ArchiveSidebar(model: model)
                .navigationSplitViewColumnWidth(min: 220, ideal: 258, max: 310)
        } detail: {
            Group {
                if let card = model.selectedCard {
                    CardDetailView(card: card, model: model, playback: playback)
                } else {
                    AlbumHomeView(model: model)
                }
            }
            .id(model.selectedCardID ?? "archive-home")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(model.selectedCard?.identity.displayName ?? "")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if model.selectedCard != nil {
                        Button {
                            model.clearSelection()
                        } label: {
                            Label("返回画册", systemImage: "chevron.left")
                        }
                        .help("返回画册")
                        .keyboardShortcut(.escape, modifiers: [])

                        Button {
                            model.toggleStoryDrawer()
                        } label: {
                            Label(
                                model.isStoryDrawerPresented ? "隐藏故事" : "查看故事",
                                systemImage: model.isStoryDrawerPresented ? "book.closed.fill" : "book.closed"
                            )
                        }
                        .help(model.isStoryDrawerPresented ? "收起故事" : "打开故事")
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(ArchiveTheme.ink)
        .backgroundExtensionEffect()
        .preferredColorScheme(.dark)
        .frame(minWidth: 1180, minHeight: 760)
        .onChange(of: model.selectedCardID) { _, _ in
            playback.stop()
        }
        .onDisappear {
            playback.stop()
        }
    }
}

private struct ArchiveSidebar: View {
    @ObservedObject var model: AlbumViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("LOTM")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(ArchiveTheme.amber)
                    Text("秘史档案馆")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ArchiveTheme.primary)
                }
                Spacer()
                Circle()
                    .stroke(ArchiveTheme.amber.opacity(0.78), lineWidth: 1)
                    .frame(width: 28, height: 28)
                    .overlay {
                        Text("✦")
                            .font(.system(size: 14))
                            .foregroundStyle(ArchiveTheme.amber)
                    }
            }
            .padding(.bottom, 42)

            Text("收藏导航")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.bottom, 12)

            SidebarButton(
                title: "画册",
                symbol: "rectangle.grid.2x2",
                isSelected: model.activeSection == .gallery
            ) {
                model.show(.gallery)
            }
            SidebarButton(title: "我的收藏", symbol: "diamond", isSelected: model.activeSection == .formal) {
                model.show(.formal)
            }
            SidebarButton(title: "候选收藏", symbol: "sparkles", isSelected: model.activeSection == .candidate) {
                model.show(.candidate)
            }
            SidebarButton(title: "愿望清单", symbol: "sparkle", isSelected: model.activeSection == .wishlist) {
                model.show(.wishlist)
            }

            Text(ArchiveCopy.pathways)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.top, 38)
                .padding(.bottom, 12)

            PathwayButton(
                title: "愚者",
                detail: ArchiveCopy.pathwaySummary(confirmed: 1, candidate: 1),
                color: ArchiveTheme.teal,
                action: { model.clearSelection() }
            )
            PathwayButton(
                title: "错误",
                detail: "暂未收录",
                color: ArchiveTheme.violet,
                isEnabled: false,
                action: {}
            )
            PathwayButton(
                title: "门",
                detail: "即将收录",
                color: ArchiveTheme.amber,
                isEnabled: false,
                action: {}
            )

            Rectangle()
                .fill(ArchiveTheme.elevated)
                .frame(height: 1)
                .padding(.vertical, 30)

            Text(ArchiveCopy.localLibrary)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.teal)
            Text("\(model.confirmedCount) 张已确认卡牌")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ArchiveTheme.primary)
                .padding(.top, 12)
            Text("内容保存在本机")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.top, 5)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(ArchiveTheme.Aether.light)
                        .frame(width: 7, height: 7)
                    Text("画册已准备好")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ArchiveTheme.Parchment.primary)
                }
                Text("声音会在需要时准备")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
                Text("选择一张卡牌开始")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ArchiveTheme.Brass.luster)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ArchiveTheme.Leather.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ArchiveTheme.Borders.subtle, lineWidth: 1)
            }
        }
        .padding(24)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ArchiveTheme.Leather.base.opacity(0.88))
        .overlay(alignment: .leading) {
            GrimoireSpineBands()
        }
    }
}

private struct SidebarTactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? 0.08 : 0.0)
            .animation(ArchiveTheme.Tokens.Motion.tactilePress, value: configuration.isPressed)
    }
}

private struct SidebarButton: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    private var titleFont: Font {
        isSelected ? .system(size: 13, weight: .bold, design: .serif) : .system(size: 13, weight: .medium)
    }

    private var titleColor: Color {
        isSelected ? ArchiveTheme.Parchment.primary : ArchiveTheme.Parchment.secondary
    }

    private var iconColor: Color {
        isSelected ? ArchiveTheme.Brass.luster : ArchiveTheme.Parchment.secondary
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 18)
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                Spacer()
                if isSelected {
                    Text("✦")
                        .font(.system(size: 10))
                        .foregroundStyle(ArchiveTheme.Brass.luster.opacity(0.85))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ArchiveTheme.Gradients.leatherSurface)
                }
            }
            .glassEffect(
                isSelected
                    ? .regular.tint(ArchiveTheme.Brass.luster.opacity(0.18)).interactive()
                    : .identity,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay {
                if isSelected {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: 1)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [ArchiveTheme.Brass.luster, ArchiveTheme.Brass.core],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3.5, height: 28)
                            .shadow(color: ArchiveTheme.Brass.luster.opacity(0.8), radius: 4)
                    }
                }
            }
            .archiveInteractiveSurface(
                accent: ArchiveTheme.Brass.luster,
                cornerRadius: 12
            )
        }
        .buttonStyle(SidebarTactileButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "已选中" : "未选中")
        .accessibilityHint("切换到\(title)")
    }
}

private struct PathwayButton: View {
    let title: String
    let detail: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    init(
        title: String,
        detail: String,
        color: Color,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.detail = detail
        self.color = color
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text(detail)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(
                title == "愚者" ? ArchiveTheme.raised.opacity(0.38) : .clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .glassEffect(
                title == "愚者"
                    ? .regular.tint(color.opacity(0.14)).interactive()
                    : .identity,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .archiveInteractiveSurface(
                accent: color,
                cornerRadius: 12,
                isInteractive: isEnabled
            )
        }
        .buttonStyle(SidebarTactileButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.48)
        .accessibilityLabel(title)
        .accessibilityValue(detail)
        .accessibilityHint(isEnabled ? "打开\(title)途径" : "\(title)途径尚未开放")
    }
}

private struct AlbumHomeView: View {
    @ObservedObject var model: AlbumViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ArchiveCopy.sectionEyebrow(for: model.activeSection))
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundStyle(ArchiveTheme.Aether.light)
                        Text(model.activeSection.title)
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ArchiveTheme.Parchment.primary, ArchiveTheme.Brass.gleam],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: ArchiveTheme.Brass.luster.opacity(0.20), radius: 8, x: 0, y: 2)
                        Text(model.activeSection.subtitle)
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    }
                    Spacer(minLength: 24)
                    Label("保存在本机", systemImage: "internaldrive")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                }

                HStack(spacing: 0) {
                    MetricTile(title: "已确认", value: "\(model.confirmedCount)", color: ArchiveTheme.Aether.light)
                    MetricTile(title: "正式收藏", value: "\(model.formalCount)", color: ArchiveTheme.Brass.luster)
                    MetricTile(title: "候选收藏", value: "\(model.candidateCount)", color: ArchiveTheme.Mystic.violet)
                    MetricTile(title: "愿望目标", value: "01", color: ArchiveTheme.Parchment.secondary)
                }
                .padding(24)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(ArchiveTheme.Gradients.leatherSurface)
                        HermeticSigilView(size: 260, showDualGlow: false)
                            .opacity(0.16)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .glassEffect(.regular.tint(ArchiveTheme.Aether.light.opacity(0.06)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: 1)
                        BrassCornerFiligree(corner: .topLeft, size: 36)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        BrassCornerFiligree(corner: .topRight, size: 36)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    }
                }

                HStack(spacing: 16) {
                    Circle()
                        .fill(ArchiveTheme.Aether.light)
                        .frame(width: 11, height: 11)
                        .shadow(color: ArchiveTheme.Aether.light.opacity(0.8), radius: 6)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最近唤醒")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .foregroundStyle(ArchiveTheme.Aether.light)
                        Text("你上次唤醒了「小丑」")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundStyle(ArchiveTheme.Parchment.primary)
                        Text("继续探索同一角色的另一张身份卡")
                            .font(.system(size: 11, design: .serif))
                            .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    }
                    Spacer()
                    PulseLine()
                        .frame(width: 270, height: 28)
                }
                .padding(22)
                .background(ArchiveTheme.Leather.deep.opacity(0.85), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .glassEffect(.regular.tint(ArchiveTheme.Brass.luster.opacity(0.06)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(ArchiveTheme.Borders.brassMuted.opacity(0.70), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(ArchiveCopy.localLibrary)
                        .font(.system(size: 10, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                    Text(ArchiveCopy.recentDiscoveries)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.primary)
                    Text("\(model.visibleCards.count) 张卡牌")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                }

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 165), spacing: 16),
                        GridItem(.flexible(minimum: 165), spacing: 16),
                        GridItem(.flexible(minimum: 165), spacing: 16),
                        GridItem(.flexible(minimum: 220), spacing: 16)
                    ],
                    alignment: .leading,
                    spacing: 16
                ) {
                    if model.visibleCards.isEmpty {
                        EmptyLibraryState(model: model)
                            .gridCellColumns(4)
                    } else {
                        ForEach(model.visibleCards) { card in
                            CardTileView(card: card) {
                                model.select(card)
                            }
                        }
                        if model.activeSection == .gallery {
                            ArchiveRuleCard()
                        }
                    }
                }
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 40)
            .padding(.top, 48)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 24)
        }
        .scrollIndicators(.hidden)
        .background(ArchiveTheme.ink)
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "搜索卡牌、角色或序列")
    }
}

private struct EmptyLibraryState: View {
    @ObservedObject var model: AlbumViewModel

    private var query: String {
        model.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: model.hasSearchQuery ? "magnifyingglass" : "tray")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(ArchiveTheme.amber)
                .accessibilityHidden(true)
            Text(model.hasSearchQuery ? "没有找到匹配身份" : "这个清单还没有身份卡")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(ArchiveTheme.primary)
            Text(
                model.hasSearchQuery
                    ? "没有卡牌匹配“\(query)”；可以清除搜索后继续浏览。"
                    : "新的身份卡收录后会出现在这里。"
            )
            .font(.system(size: 12))
            .foregroundStyle(ArchiveTheme.secondary)
            .multilineTextAlignment(.center)
            if model.hasSearchQuery {
                Button {
                    model.clearSearch()
                } label: {
                    Label("清除搜索", systemImage: "xmark.circle")
                }
                .buttonStyle(SecondaryButtonStyle())
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding(28)
        .glassEffect(
            .regular.tint(ArchiveTheme.amber.opacity(0.08)),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .accessibilityElement(children: .contain)
    }
}

private struct PulseLine: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(ArchiveTheme.teal)
                .frame(height: 2)
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(ArchiveTheme.teal)
                    .frame(width: 7, height: 7)
                    .offset(y: index.isMultiple(of: 2) ? -5 : 0)
                if index < 5 {
                    Rectangle()
                        .fill(ArchiveTheme.teal.opacity(0.70))
                        .frame(height: 2)
                }
            }
        }
    }
}

private struct TactileCardButtonStyle: ButtonStyle {
    let accentColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .shadow(
                color: configuration.isPressed
                    ? accentColor.opacity(0.55)
                    : .clear,
                radius: configuration.isPressed ? 12 : 0,
                y: configuration.isPressed ? 2 : 0
            )
            .animation(ArchiveTheme.Tokens.Motion.tactilePress, value: configuration.isPressed)
    }
}

private struct CardTileView: View {
    let card: AlbumCard
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ArchiveArtworkView(
                    theme: card.visualTheme,
                    compact: true,
                    resourceName: card.artworkResourceName
                )
                .padding(12)
                VStack(alignment: .leading, spacing: 7) {
                    Text(card.identity.sequenceName)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(card.identity.contentStatus.accentColor)
                    Text(card.identity.displayName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(ArchiveTheme.primary)
                        .lineLimit(1)
                    Text(card.subtitle)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                        .lineLimit(1)
                    StatusChip(status: card.identity.contentStatus)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ArchiveTheme.Gradients.leatherSurface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .glassEffect(
                .regular.tint(card.identity.contentStatus.accentColor.opacity(0.10)).interactive(),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(ArchiveTheme.Borders.subtle, lineWidth: 1)
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(card.identity.contentStatus.accentColor.opacity(0.32), lineWidth: 1)
                }
            }
            .archiveInteractiveSurface(
                accent: card.identity.contentStatus.accentColor,
                cornerRadius: 17,
                hoverScale: 1.01
            )
        }
        .buttonStyle(TactileCardButtonStyle(accentColor: card.identity.contentStatus.accentColor))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.identity.displayName)，\(card.identity.sequenceName)")
        .accessibilityValue("状态：\(card.identity.contentStatus.displayTitle)；\(card.subtitle)")
        .accessibilityHint("打开卡牌详情")
    }
}

private struct ArchiveRuleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("途径与身份")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.teal)
            Text("同一途径可以有多张身份卡。")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(ArchiveTheme.primary)
            Text("同一角色的不同身份会分别收藏，也会分别讲述。")
                .font(.system(size: 13))
                .foregroundStyle(ArchiveTheme.secondary)
            Rectangle()
                .fill(ArchiveTheme.elevated)
                .frame(height: 1)
            Text("每张身份卡都独立保存")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.amber)
            Text("同一角色的不同身份也会分别讲述")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.amber)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ArchiveTheme.coal.opacity(0.56), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .glassEffect(.regular.tint(ArchiveTheme.amber.opacity(0.07)), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct CardDetailView: View {
    let card: AlbumCard
    @ObservedObject var model: AlbumViewModel
    @ObservedObject var playback: SpeechPlaybackCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var detailMode: Binding<CardDetailMode> {
        Binding(
            get: { model.isStoryDrawerPresented ? .story : .identity },
            set: { newMode in
                if reduceMotion {
                    model.isStoryDrawerPresented = newMode == .story
                } else {
                    withAnimation(.easeOut(duration: 0.20)) {
                        model.isStoryDrawerPresented = newMode == .story
                    }
                }
            }
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical) {
                detailLayout(for: proxy.size.width)
                    .frame(maxWidth: CardDetailLayout.contentMaximumWidth)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, CardDetailLayout.horizontalPadding)
                    .padding(.vertical, CardDetailLayout.verticalPadding)
            }
            .scrollIndicators(.hidden)
            .background(ArchiveTheme.ink)
        }
        .background(ArchiveTheme.ink)
    }

    @ViewBuilder
    private func detailLayout(for width: CGFloat) -> some View {
        let contentWidth = max(
            0,
            min(
                width - CardDetailLayout.horizontalPadding * 2,
                CardDetailLayout.contentMaximumWidth
            )
        )

        if CardDetailLayout.usesTwoColumns(for: contentWidth) {
            HStack(alignment: .top, spacing: CardDetailLayout.stageToRailGap) {
                CardMotionViewport(card: card)
                DetailRail(
                    card: card,
                    model: model,
                    playback: playback,
                    mode: detailMode,
                    isStacked: false
                )
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        } else {
            VStack(alignment: .center, spacing: 28) {
                CardMotionViewport(card: card)
                DetailRail(
                    card: card,
                    model: model,
                    playback: playback,
                    mode: detailMode,
                    isStacked: true
                )
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
}

private struct CardMotionViewport: View {
    let card: AlbumCard

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                // 底层：做旧古籍真皮封皮深色渐变
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ArchiveTheme.Gradients.grimoireCover)

                // 核心法阵：Logo 封皮同款赫密斯同心圆占星法阵与暖金+青碧双色灵流
                HermeticSigilView(size: 380, showDualGlow: true)

                // 典籍内嵌卡槽边框（黄铜暗金压条与内凹阴影）
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: 1.5)
                    .padding(20)

                // 卡牌实体（带深邃的典籍卡槽立体投影）
                ArchiveArtworkView(
                    theme: card.visualTheme,
                    compact: false,
                    resourceName: card.artworkResourceName
                )
                .frame(
                    width: CardDetailLayout.cardSize.width,
                    height: CardDetailLayout.cardSize.height
                )
                .shadow(
                    color: ArchiveTheme.Leather.void.opacity(0.85),
                    radius: 22,
                    y: 12
                )

                // 四角固定：维多利亚洛可可黄铜雕花包角（Logo 标志性物理构件）
                VStack {
                    HStack {
                        BrassCornerFiligree(corner: .topLeft, size: 56)
                        Spacer()
                        BrassCornerFiligree(corner: .topRight, size: 56)
                    }
                    Spacer()
                    HStack {
                        BrassCornerFiligree(corner: .bottomLeft, size: 56)
                        Spacer()
                        BrassCornerFiligree(corner: .bottomRight, size: 56)
                    }
                }
            }
            .frame(
                width: CardDetailLayout.motionViewportSize.width,
                height: CardDetailLayout.motionViewportSize.height
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                ArchiveTheme.Brass.luster.opacity(0.70),
                                ArchiveTheme.Brass.core.opacity(0.40),
                                ArchiveTheme.Brass.patina.opacity(0.60)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
            .shadow(color: ArchiveTheme.Leather.void.opacity(0.60), radius: 18, y: 10)
            .archiveCursor(.arrow)

            HStack {
                Text(card.identity.sequenceName)
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundStyle(ArchiveTheme.Brass.luster)
                Spacer()
                Text(card.identity.displayName)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .foregroundStyle(ArchiveTheme.Parchment.primary)
            }
            .frame(width: CardDetailLayout.motionViewportSize.width)
            .archiveCursor(.arrow)

            Text(card.subtitle)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
                .frame(width: CardDetailLayout.motionViewportSize.width, alignment: .leading)
                .archiveCursor(.arrow)
        }
        .frame(width: CardDetailLayout.motionViewportSize.width, alignment: .top)
        .layoutPriority(1)
    }
}

private struct DetailRail: View {
    let card: AlbumCard
    @ObservedObject var model: AlbumViewModel
    @ObservedObject var playback: SpeechPlaybackCoordinator
    @Binding var mode: CardDetailMode
    let isStacked: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Picker("详情模式", selection: $mode) {
                    ForEach(CardDetailMode.allCases) { detailMode in
                        Text(detailMode.title)
                            .tag(detailMode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 220)
                .accessibilityLabel("详情模式")

                Spacer(minLength: 12)

                StatusChip(status: card.identity.contentStatus)
            }

            PanelDivider()
                .padding(.vertical, 0)

            Group {
                switch mode {
                case .identity:
                    IdentityPanel(card: card, model: model, playback: playback)
                case .story:
                    StoryDrawer(card: card, playback: playback)
                }
            }
            .id(mode)
            .transition(
                reduceMotion
                    ? .identity
                    : .opacity.combined(with: .move(edge: .trailing))
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(ArchiveTheme.Gradients.leatherSurface)
                VStack {
                    HStack {
                        BrassCornerFiligree(corner: .topLeft, size: 36)
                        Spacer()
                        BrassCornerFiligree(corner: .topRight, size: 36)
                    }
                    Spacer()
                    HStack {
                        BrassCornerFiligree(corner: .bottomLeft, size: 36)
                        Spacer()
                        BrassCornerFiligree(corner: .bottomRight, size: 36)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .glassEffect(.regular.tint(ArchiveTheme.Brass.luster.opacity(0.04)), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: 1)
        }
        .frame(
            minWidth: isStacked ? 0 : CardDetailLayout.railMinimumWidth,
            maxWidth: isStacked ? .infinity : CardDetailLayout.railMaximumWidth,
            alignment: .topLeading
        )
        .archiveCursor(.arrow)
    }
}

private struct IdentityPanel: View {
    let card: AlbumCard
    @ObservedObject var model: AlbumViewModel
    @ObservedObject var playback: SpeechPlaybackCoordinator

    private var voiceAvailability: VoiceAvailability {
        LotmCardStudioFeatures.voiceAvailability(for: card.narrative)
    }

    private var hasPlayableGreeting: Bool {
        voiceAvailability != .pending
    }

    private var voiceStatusLabel: String {
        switch voiceAvailability {
        case .localAudio:
            return "声音已经准备好"
        case .speechRail:
            return "播放时准备声音"
        case .pending:
            return "台词确认后可以播放"
        }
    }

    private var voiceStatusColor: Color {
        switch voiceAvailability {
        case .localAudio:
            return ArchiveTheme.teal
        case .speechRail:
            return ArchiveTheme.amber
        case .pending:
            return ArchiveTheme.secondary
        }
    }

    private var pathwayLabel: String {
        card.identity.slotID.hasPrefix("lotm.visionary") ? "观众途径 · 空想家" : "愚者途径"
    }

    private var semanticReadbacks: [SemanticReadback] {
        if card.identity.slotID == "lotm.fool.s00" {
            return [
                SemanticReadback(index: "01", title: "身份", value: "序列 00 · 愚者 · 真神", color: ArchiveTheme.teal),
                SemanticReadback(index: "02", title: "扮演", value: "在不同身份中保持自我", color: ArchiveTheme.amber),
                SemanticReadback(index: "03", title: "能力", value: "愚弄与历史投影（节选）", color: ArchiveTheme.teal),
                SemanticReadback(index: "04", title: "魔药", value: "唯一性与诡秘侍者特性（待核对）", color: ArchiveTheme.violet),
                SemanticReadback(index: "05", title: "晋升", value: "愚弄时间、历史或命运（部分资料）", color: ArchiveTheme.amber),
                SemanticReadback(index: "06", title: "限制", value: "相关资料仍在整理", color: ArchiveTheme.danger)
            ]
        }

        if card.identity.cardID == "lotm.visionary.s07.audrey-01" {
            return [
                SemanticReadback(index: "01", title: "身份", value: "正义 · 奥黛丽 · 序列 07", color: ArchiveTheme.teal),
                SemanticReadback(index: "02", title: "扮演", value: "主动观察并帮助他人", color: ArchiveTheme.amber),
                SemanticReadback(index: "03", title: "能力", value: "安抚心灵、读取情绪", color: ArchiveTheme.teal),
                SemanticReadback(index: "04", title: "魔药", value: "镜龙材料 · 长者之树果实", color: ArchiveTheme.violet),
                SemanticReadback(index: "05", title: "晋升", value: "独立仪式（资料待补）", color: ArchiveTheme.amber),
                SemanticReadback(index: "06", title: "限制", value: "受媒介与半催眠条件影响", color: ArchiveTheme.danger)
            ]
        }

        return [
            SemanticReadback(index: "01", title: "身份", value: "\(card.identity.sequenceName) · \(card.identity.displayName)", color: ArchiveTheme.teal),
            SemanticReadback(index: "02", title: "扮演", value: "以荒诞掩护真实", color: ArchiveTheme.amber),
            SemanticReadback(index: "03", title: "能力", value: "操纵表情与注意力", color: ArchiveTheme.teal),
            SemanticReadback(index: "04", title: "魔药", value: "相关材料待确认", color: ArchiveTheme.violet),
            SemanticReadback(index: "05", title: "晋升", value: "晋升条件待复核", color: ArchiveTheme.amber),
            SemanticReadback(index: "06", title: "限制", value: "声音需要在本机准备", color: ArchiveTheme.danger)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(ArchiveCopy.identityInfo)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                    Text(card.identity.displayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text("\(card.identity.sequenceName)  ·  \(pathwayLabel)")
                        .font(.system(size: 12))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                StatusChip(status: card.identity.contentStatus)
            }

            PanelDivider()

            Text(ArchiveCopy.characterRelation)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(ArchiveCopy.characterName(for: card.identity.characterID))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text("同一角色的不同身份会分别保存。")
                        .font(.system(size: 11))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                Text(card.identity.characterID == nil
                    ? "途径原型"
                    : "\(model.characterCardCount(for: card.identity.characterID)) 张身份卡")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(ArchiveTheme.teal)
            }
            .padding(.top, 12)

            PanelDivider()

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(ArchiveCopy.voice)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                    Text(ArchiveCopy.voiceTitle(for: card.identity))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text(voiceStatusLabel)
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                HStack(spacing: 7) {
                    Circle()
                        .fill(voiceStatusColor)
                        .frame(width: 6, height: 6)
                    Text(voiceAvailability.statusLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(voiceStatusColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ArchiveTheme.coal, in: Capsule())
            }

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        playback.awaken(card: card)
                    } label: {
                        Label("播放声音", systemImage: "waveform")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!hasPlayableGreeting)
                    .help(voiceAvailability.buttonHelp)
                    .accessibilityValue(voiceAvailability.accessibilityValue)

                    Button {
                        model.toggleStoryDrawer()
                    } label: {
                        Label("查看故事", systemImage: "book.closed")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityValue(model.isStoryDrawerPresented ? "已展开" : "已收起")

                    Text(voiceAvailability.prompt)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(hasPlayableGreeting ? ArchiveTheme.amber : ArchiveTheme.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.top, 24)

            LiveCaptionRail(
                caption: playback.currentCaption,
                state: playback.state,
                storyDrawerPresented: model.isStoryDrawerPresented,
                onOpenStory: {
                    if !model.isStoryDrawerPresented {
                        model.toggleStoryDrawer()
                    }
                }
            )
            .padding(.top, 16)

            PanelDivider()

                Text(ArchiveCopy.semanticReadback)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.bottom, 14)
            IdentityReadbackGrid(rows: semanticReadbacks)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct SemanticReadback: Identifiable {
    let id: String
    let index: String
    let title: String
    let value: String
    let color: Color

    init(index: String, title: String, value: String, color: Color) {
        self.id = index
        self.index = index
        self.title = title
        self.value = value
        self.color = color
    }
}

private struct PanelDivider: View {
    var body: some View {
        Rectangle()
            .fill(ArchiveTheme.elevated)
            .frame(height: 1)
            .padding(.vertical, 22)
    }
}

private struct IdentityReadbackGrid: View {
    let rows: [SemanticReadback]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                readbackColumn(rows: rows.enumerated().compactMap { index, row in
                    index.isMultiple(of: 2) ? row : nil
                })
                readbackColumn(rows: rows.enumerated().compactMap { index, row in
                    index.isMultiple(of: 2) ? nil : row
                })
            }
            .frame(minWidth: 532, maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(rows) { row in
                    SemanticRow(
                        index: row.index,
                        title: row.title,
                        value: row.value,
                        color: row.color
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func readbackColumn(rows: [SemanticReadback]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(rows) { row in
                SemanticRow(
                    index: row.index,
                    title: row.title,
                    value: row.value,
                    color: row.color
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct SemanticRow: View {
    let index: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        ParchmentSemanticTile(
            index: index,
            title: title,
            value: value,
            accentColor: color
        )
        .archiveCursor(.arrow)
    }
}

private extension PlaybackState {
    var captionStatusLabel: String {
        switch self {
        case .idle:
            return "已讲完"
        case .loading:
            return "正在准备声音"
        case .playing:
            return "正在讲述"
        case .paused:
            return "已暂停"
        case .failed:
            return "声音不可用"
        }
    }

    var captionSystemImage: String {
        switch self {
        case .idle:
            return "checkmark.circle"
        case .loading:
            return "waveform"
        case .playing:
            return "waveform"
        case .paused:
            return "pause.circle"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
}

private extension NarrativeKind {
    var captionDisplayName: String {
        switch self {
        case .greeting:
            return "问候语"
        case .catchphrase:
            return "口头禅"
        case .story:
            return "故事章节"
        }
    }
}

private struct LiveCaptionRail: View {
    let caption: PlaybackCaption?
    let state: PlaybackState
    let storyDrawerPresented: Bool
    let onOpenStory: () -> Void

    private var accentColor: Color {
        switch state {
        case .failed:
            return ArchiveTheme.danger
        case .paused:
            return ArchiveTheme.amber
        case .loading:
            return ArchiveTheme.amber
        case .playing:
            return ArchiveTheme.teal
        case .idle:
            return caption == nil ? ArchiveTheme.secondary : ArchiveTheme.teal
        }
    }

    private var headerTitle: String {
        guard let caption else {
            return "实时字幕"
        }
        let prefix: String
        switch state {
        case .idle:
            prefix = "最近讲述"
        case .failed:
            prefix = "文字稿保留"
        default:
            prefix = "正在讲述"
        }
        return "\(prefix)：\(caption.kind.captionDisplayName)"
    }

    private var statusLabel: String {
        guard caption != nil else {
            return "等待唤醒"
        }
        return state.captionStatusLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: caption == nil ? "captions.bubble" : state.captionSystemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text(headerTitle)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)

                Spacer(minLength: 10)

                if state == .loading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(accentColor)
                }

                Text(statusLabel)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(ArchiveTheme.secondary)
            }

            if let caption {
                Text(caption.text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ArchiveTheme.primary)
                    .lineLimit(caption.kind == .story ? 4 : 3)
                    .fixedSize(horizontal: false, vertical: true)

                if caption.kind == .story {
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 10, weight: .medium))
                        if storyDrawerPresented {
                            Text("故事全文已展开")
                        } else {
                            Text("打开故事查看全文")
                            Button("打开") {
                                onOpenStory()
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(ArchiveTheme.teal)
                            .archiveInteractiveSurface(
                                accent: ArchiveTheme.teal,
                                cornerRadius: 6
                            )
                        }
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ArchiveTheme.secondary)
                }

                if case let .failed(message) = state {
                    Text(message)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ArchiveTheme.danger)
                }
            } else {
                Text("点击唤醒后，当前台词会显示在这里。")
                    .font(.system(size: 12))
                    .foregroundStyle(ArchiveTheme.secondary)
            }
        }
        .padding(15)
        .background(ArchiveTheme.coal.opacity(0.78), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(caption == nil ? 0.16 : 0.36), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct StoryDrawer: View {
    let card: AlbumCard
    @ObservedObject var playback: SpeechPlaybackCoordinator
    @State private var selectedChapterID: StoryChapter.ID?

    private var chapters: [StoryChapter] {
        card.narrative?.readableChapters ?? []
    }

    private var selectedChapter: StoryChapter? {
        guard let selectedChapterID else {
            return chapters.first
        }
        return chapters.first { $0.id == selectedChapterID } ?? chapters.first
    }

    private var selectedChapterIsPlayable: Bool {
        selectedChapter?.line.isPlayable == true
    }

    private var hasPlayableChapter: Bool {
        chapters.contains { $0.line.isPlayable }
    }

    private var selectedChapterIsCurrent: Bool {
        guard let selectedChapter,
              let caption = playback.currentCaption
        else {
            return false
        }
        return caption.lineID == selectedChapter.line.id
    }

    private var drawerPlaybackLabel: String {
        guard selectedChapterIsCurrent, playback.currentCaption != nil else {
            return playback.state.label
        }
        return playback.state.captionStatusLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(ArchiveCopy.story)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                    Text("\(card.identity.displayName)的故事")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text(hasPlayableChapter ? "第三人称故事 · 可以朗读" : "第三人称故事 · 等待确认")
                        .font(.system(size: 11))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                Text(drawerPlaybackLabel)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(selectedChapterIsCurrent ? ArchiveTheme.teal : ArchiveTheme.secondary)
            }

            Rectangle()
                .fill(ArchiveTheme.elevated)
                .frame(height: 1)

            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 9) {
                    if selectedChapterIsCurrent {
                        HStack(spacing: 7) {
                            Image(systemName: playback.state.captionSystemImage)
                                .font(.system(size: 10, weight: .semibold))
                            Text(playback.state.captionStatusLabel)
                        }
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                    }
                    Text(selectedChapter?.line.text ?? "暂时没有故事")
                        .font(.system(size: 17))
                        .foregroundStyle(ArchiveTheme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(selectedChapterIsPlayable ? "声音暂时不可用时，仍可阅读故事。" : "这段故事还在确认中，目前只能阅读。")
                        .font(.system(size: 11))
                        .foregroundStyle(selectedChapterIsPlayable ? ArchiveTheme.secondary : ArchiveTheme.amber)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Button {
                            if selectedChapterIsCurrent, playback.state == .playing {
                                playback.pause()
                            } else if selectedChapterIsCurrent, playback.state == .paused {
                                playback.resume()
                            } else if let chapter = selectedChapter {
                                selectedChapterID = chapter.id
                                playback.playStory(chapter, voiceProfileID: card.narrative?.voiceProfileID ?? "")
                            }
                        } label: {
                            Image(systemName: selectedChapterIsPlayable
                                ? (selectedChapterIsCurrent && playback.state == .playing ? "pause.fill" : "play.fill")
                                : "lock.fill")
                        }
                        .buttonStyle(IconButtonStyle())
                        .disabled(!selectedChapterIsPlayable)
                        .accessibilityLabel(
                            selectedChapterIsPlayable
                                ? (selectedChapterIsCurrent && playback.state == .playing
                                    ? "暂停故事"
                                    : selectedChapterIsCurrent && playback.state == .paused
                                        ? "继续故事"
                                        : "播放故事")
                                : "故事还在确认中"
                        )
                        .accessibilityValue(selectedChapterIsCurrent ? playback.state.captionStatusLabel : "未播放当前章节")
                        .accessibilityHint(
                            selectedChapterIsPlayable
                                ? "播放当前章节"
                                : "当前章节只能阅读文字，确认后才可朗读"
                        )
                        Button {
                            playback.replay()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(IconButtonStyle())
                        .disabled(!selectedChapterIsPlayable || !selectedChapterIsCurrent)
                        .accessibilityLabel("重播当前章节")
                        .accessibilityHint("从头朗读当前章节")
                        Button {
                            playback.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(IconButtonStyle())
                        .accessibilityLabel("停止播放")
                        .accessibilityHint("停止当前故事音频")
                    }
                    Text(ArchiveCopy.chapters)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                    ForEach(chapters) { chapter in
                        Button {
                            selectedChapterID = chapter.id
                            if chapter.line.isPlayable {
                                playback.playStory(chapter, voiceProfileID: card.narrative?.voiceProfileID ?? "")
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(chapter.title)
                                Spacer(minLength: 8)
                                Text(chapter.line.isPlayable ? "可朗读" : "待确认")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundStyle(chapter.line.isPlayable ? ArchiveTheme.teal : ArchiveTheme.amber)
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(chapter.line.isPlayable ? ArchiveTheme.teal : ArchiveTheme.secondary)
                        .archiveInteractiveSurface(
                            accent: chapter.line.isPlayable ? ArchiveTheme.teal : ArchiveTheme.amber,
                            cornerRadius: 8,
                            isInteractive: chapter.line.isPlayable
                        )
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(chapter.title)
                        .accessibilityValue(chapter.line.isPlayable ? "可朗读" : "待确认")
                        .accessibilityHint(
                            chapter.line.isPlayable
                                ? "选择并播放该章节"
                                : "可阅读文字，但还未确认朗读"
                        )
                    }
                    if chapters.isEmpty {
                        Text("暂无故事内容")
                            .font(.system(size: 10))
                            .foregroundStyle(ArchiveTheme.amber)
                    } else if !hasPlayableChapter {
                        Text("故事仍在整理，确认后可以朗读")
                            .font(.system(size: 10))
                            .foregroundStyle(ArchiveTheme.amber)
                    }
                }
                .frame(width: 250, alignment: .leading)
                .padding(16)
                .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .serif))
            .foregroundStyle(ArchiveTheme.Leather.void)
            .padding(.horizontal, 18)
            .frame(height: 40)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            configuration.isPressed
                                ? LinearGradient(
                                    colors: [ArchiveTheme.Brass.gleam, ArchiveTheme.Brass.luster, ArchiveTheme.Aether.light],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [ArchiveTheme.Brass.luster, ArchiveTheme.Brass.core],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            configuration.isPressed
                                ? ArchiveTheme.Aether.light
                                : ArchiveTheme.Brass.gleam.opacity(0.65),
                            lineWidth: configuration.isPressed ? 1.5 : 1
                        )
                }
            }
            .glassEffect(
                configuration.isPressed
                    ? .regular.tint(ArchiveTheme.Brass.luster.opacity(0.35)).interactive()
                    : .regular.tint(ArchiveTheme.Brass.luster.opacity(0.18)).interactive(),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(
                color: configuration.isPressed
                    ? ArchiveTheme.Aether.light.opacity(0.70)
                    : ArchiveTheme.Brass.luster.opacity(0.30),
                radius: configuration.isPressed ? 10 : 4,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(ArchiveTheme.Tokens.Motion.tactilePress, value: configuration.isPressed)
            .archiveInteractiveSurface(
                accent: ArchiveTheme.Brass.luster,
                cornerRadius: 12,
                isInteractive: isEnabled
            )
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .serif))
            .foregroundStyle(
                configuration.isPressed
                    ? ArchiveTheme.Brass.luster
                    : ArchiveTheme.Parchment.primary
            )
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            configuration.isPressed
                                ? ArchiveTheme.Leather.void
                                : ArchiveTheme.Leather.deep.opacity(0.85)
                        )
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            configuration.isPressed
                                ? ArchiveTheme.Brass.luster
                                : ArchiveTheme.Borders.subtle,
                            lineWidth: configuration.isPressed ? 1.5 : 1
                        )
                }
            }
            .glassEffect(
                configuration.isPressed
                    ? .regular.tint(ArchiveTheme.Brass.luster.opacity(0.24)).interactive()
                    : .regular.tint(ArchiveTheme.Aether.light.opacity(0.10)).interactive(),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(
                color: configuration.isPressed
                    ? ArchiveTheme.Brass.luster.opacity(0.40)
                    : .clear,
                radius: 6,
                y: 1
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(ArchiveTheme.Tokens.Motion.tactilePress, value: configuration.isPressed)
            .archiveInteractiveSurface(
                accent: ArchiveTheme.Aether.light,
                cornerRadius: 12,
                isInteractive: isEnabled
            )
    }
}

private struct IconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(
                configuration.isPressed
                    ? ArchiveTheme.Brass.luster
                    : ArchiveTheme.Parchment.primary
            )
            .frame(width: 36, height: 36)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            configuration.isPressed
                                ? ArchiveTheme.Leather.void
                                : ArchiveTheme.Leather.deep.opacity(0.75)
                        )
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            configuration.isPressed
                                ? ArchiveTheme.Brass.luster
                                : ArchiveTheme.Borders.subtle,
                            lineWidth: configuration.isPressed ? 1.5 : 1
                        )
                }
            }
            .glassEffect(
                configuration.isPressed
                    ? .regular.tint(ArchiveTheme.Brass.luster.opacity(0.28)).interactive()
                    : .regular.tint(ArchiveTheme.Leather.elevated.opacity(0.36)).interactive(),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .shadow(
                color: configuration.isPressed
                    ? ArchiveTheme.Brass.luster.opacity(0.50)
                    : .clear,
                radius: 5,
                y: 1
            )
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .animation(ArchiveTheme.Tokens.Motion.tactilePress, value: configuration.isPressed)
            .archiveInteractiveSurface(
                accent: ArchiveTheme.Brass.core,
                cornerRadius: 10,
                isInteractive: isEnabled
            )
    }
}
