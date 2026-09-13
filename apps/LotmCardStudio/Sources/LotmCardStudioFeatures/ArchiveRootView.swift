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
            .navigationTitle(model.selectedCard?.identity.displayName ?? model.activeSection.title)
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
                        .help(model.isStoryDrawerPresented ? "隐藏故事抽屉" : "查看故事抽屉")
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

            Text("ARCHIVE")
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

            Text("PATHWAYS")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.top, 38)
                .padding(.bottom, 12)

            PathwayButton(
                title: "愚者",
                detail: "1 confirmed · 1 candidate",
                color: ArchiveTheme.teal,
                action: { model.clearSelection() }
            )
            PathwayButton(
                title: "错误",
                detail: "0 confirmed · 1 draft",
                color: ArchiveTheme.violet,
                isEnabled: false,
                action: {}
            )
            PathwayButton(
                title: "门",
                detail: "coming later",
                color: ArchiveTheme.amber,
                isEnabled: false,
                action: {}
            )

            Rectangle()
                .fill(ArchiveTheme.elevated)
                .frame(height: 1)
                .padding(.vertical, 30)

            Text("LOCAL LIBRARY")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.teal)
            Text("\(model.confirmedCount) confirmed identities")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(ArchiveTheme.primary)
                .padding(.top, 12)
            Text("snapshot · local only")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.top, 5)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(ArchiveTheme.teal)
                        .frame(width: 7, height: 7)
                    Text("内容库已就绪")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ArchiveTheme.primary)
                }
                Text("SpeechRail 按需连接")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(ArchiveTheme.secondary)
                Text("重新导入  ›")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(ArchiveTheme.amber)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ArchiveTheme.coal.opacity(0.74))
    }
}

private struct SidebarButton: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                Spacer()
            }
            .foregroundStyle(isSelected ? ArchiveTheme.primary : ArchiveTheme.secondary)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(
                isSelected ? ArchiveTheme.raised.opacity(0.38) : .clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .glassEffect(
                isSelected
                    ? .regular.tint(ArchiveTheme.amber.opacity(0.16)).interactive()
                    : .identity,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(ArchiveTheme.amber)
                        .frame(width: 3, height: 28)
                }
            }
            .archiveInteractiveSurface(
                accent: ArchiveTheme.amber,
                cornerRadius: 12
            )
        }
        .buttonStyle(.plain)
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
        .buttonStyle(.plain)
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
                        Text("ARCHIVE / FOOL PATHWAY")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(ArchiveTheme.teal)
                        Text(model.activeSection.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(ArchiveTheme.primary)
                        Text(model.activeSection.subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(ArchiveTheme.secondary)
                    }
                    Spacer(minLength: 24)
                    Label("本机快照", systemImage: "internaldrive")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                }

                HStack(spacing: 0) {
                    MetricTile(title: "已确认", value: "\(model.confirmedCount)", color: ArchiveTheme.teal)
                    MetricTile(title: "正式收藏", value: "\(model.formalCount)", color: ArchiveTheme.amber)
                    MetricTile(title: "候选收藏", value: "\(model.candidateCount)", color: ArchiveTheme.violet)
                    MetricTile(title: "愿望目标", value: "01", color: ArchiveTheme.secondary)
                }
                .padding(22)
                .background(ArchiveTheme.raised.opacity(0.45), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .glassEffect(.regular.tint(ArchiveTheme.teal.opacity(0.08)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                HStack(spacing: 16) {
                    Circle()
                        .fill(ArchiveTheme.teal)
                        .frame(width: 11, height: 11)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TODAY'S PULSE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(ArchiveTheme.teal)
                        Text("你上次唤醒了「小丑」")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ArchiveTheme.primary)
                        Text("继续探索同一角色的另一张身份卡")
                            .font(.system(size: 11))
                            .foregroundStyle(ArchiveTheme.secondary)
                    }
                    Spacer()
                    PulseLine()
                        .frame(width: 270, height: 28)
                }
                .padding(22)
                .background(ArchiveTheme.coal.opacity(0.58), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .glassEffect(.regular.tint(ArchiveTheme.teal.opacity(0.08)), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("RECENTLY DISCOVERED")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.amber)
                    Text("最近发现")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text("\(model.visibleCards.count) identities")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
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
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    Text(card.identity.sequenceName.uppercased())
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
            .background(ArchiveTheme.raised.opacity(0.48), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .glassEffect(
                .regular.tint(card.identity.contentStatus.accentColor.opacity(0.10)).interactive(),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(card.identity.contentStatus.accentColor.opacity(0.28), lineWidth: 1)
            }
            .archiveInteractiveSurface(
                accent: card.identity.contentStatus.accentColor,
                cornerRadius: 17,
                hoverScale: 1.01
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(card.identity.displayName)，\(card.identity.sequenceName)")
        .accessibilityValue("状态：\(card.identity.contentStatus.displayTitle)；\(card.subtitle)")
        .accessibilityHint("打开卡牌详情")
    }
}

private struct ArchiveRuleCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ONE PATHWAY / MANY IDENTITIES")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.teal)
            Text("序列是容器，身份才是卡牌。")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(ArchiveTheme.primary)
            Text("同一个序列可以有零张、一张或多张身份卡。相同角色的不同身份会在角色族谱中聚合，但仍然各自收藏、各自发声。")
                .font(.system(size: 13))
                .foregroundStyle(ArchiveTheme.secondary)
            Rectangle()
                .fill(ArchiveTheme.elevated)
                .frame(height: 1)
            Text("CARD ID  ·  stable · unique · independent")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.amber)
            Text("VOICE  ·  inherited, unless explicitly overridden")
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
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                ArchiveTheme.coal.opacity(0.92),
                                ArchiveTheme.ink.opacity(0.96)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Circle()
                    .fill(ArchiveTheme.amber.opacity(0.18))
                    .frame(width: 260, height: 260)
                    .blur(radius: 48)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(ArchiveTheme.amber.opacity(0.22), lineWidth: 1)
                    .padding(24)
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
                    color: ArchiveTheme.ink.opacity(0.48),
                    radius: 18,
                    y: 10
                )
            }
            .frame(
                width: CardDetailLayout.motionViewportSize.width,
                height: CardDetailLayout.motionViewportSize.height
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(ArchiveTheme.elevated.opacity(0.72), lineWidth: 1)
            }
            .archiveCursor(.arrow)

            HStack {
                Text(card.identity.sequenceName.uppercased())
                    .foregroundStyle(ArchiveTheme.amber)
                Spacer()
                Text(card.identity.displayName)
                    .foregroundStyle(ArchiveTheme.primary)
            }
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .frame(width: CardDetailLayout.motionViewportSize.width)
            .archiveCursor(.arrow)

            Text("\(card.subtitle)  ·  2:3  ·  local snapshot")
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
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
        .background(ArchiveTheme.raised.opacity(0.46), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glassEffect(.regular.tint(ArchiveTheme.teal.opacity(0.08)), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ArchiveTheme.teal.opacity(0.18), lineWidth: 1)
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
        if card.identity.slotID == "lotm.fool.s00" && hasPlayableGreeting {
            return "已批准文案 · 本地 WAV 已生成 · uncle_fu"
        }
        if card.identity.slotID == "lotm.fool.s00" {
            return "新音色草稿 · 文案待审批 · 音频未生成"
        }
        if card.identity.cardID == "lotm.visionary.s07.audrey-01" && hasPlayableGreeting {
            return "已批准文案 · 本地 WAV 已生成 · serena"
        }
        return card.identity.contentStatus == .confirmed
            ? "base profile inherited · continuity review pending"
            : "voice recipe draft · approval pending"
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
                SemanticReadback(index: "02", title: "扮演", value: "身份错位中保持自我 · 候选", color: ArchiveTheme.amber),
                SemanticReadback(index: "03", title: "能力", value: "愚弄 / 历史投影 · 片段", color: ArchiveTheme.teal),
                SemanticReadback(index: "04", title: "魔药", value: "唯一性 + 诡秘侍者特性 · 待核验", color: ArchiveTheme.violet),
                SemanticReadback(index: "05", title: "晋升", value: "愚弄时间、历史或命运 · 候选", color: ArchiveTheme.amber),
                SemanticReadback(index: "06", title: "限制", value: "完整限制清单待中文核验", color: ArchiveTheme.danger)
            ]
        }

        if card.identity.cardID == "lotm.visionary.s07.audrey-01" {
            return [
                SemanticReadback(index: "01", title: "身份", value: "正义 · 奥黛丽 · 序列 07", color: ArchiveTheme.teal),
                SemanticReadback(index: "02", title: "扮演", value: "主动应用 · 帮助他人", color: ArchiveTheme.amber),
                SemanticReadback(index: "03", title: "能力", value: "安抚 / 读心 · 状态转变", color: ArchiveTheme.teal),
                SemanticReadback(index: "04", title: "魔药", value: "镜龙材料 · 长者之树果实", color: ArchiveTheme.violet),
                SemanticReadback(index: "05", title: "晋升", value: "序列7独立仪式 · 本来源未列", color: ArchiveTheme.amber),
                SemanticReadback(index: "06", title: "限制", value: "失败概率 · 媒介 / 半催眠", color: ArchiveTheme.danger)
            ]
        }

        return [
            SemanticReadback(index: "01", title: "身份", value: "\(card.identity.sequenceName) · \(card.identity.displayName)", color: ArchiveTheme.teal),
            SemanticReadback(index: "02", title: "扮演", value: "以荒诞掩护真实", color: ArchiveTheme.amber),
            SemanticReadback(index: "03", title: "能力", value: "操纵表情与注意力", color: ArchiveTheme.teal),
            SemanticReadback(index: "04", title: "魔药", value: "需绑定已核验来源", color: ArchiveTheme.violet),
            SemanticReadback(index: "05", title: "晋升", value: "批准依赖待复核", color: ArchiveTheme.amber),
            SemanticReadback(index: "06", title: "限制", value: "语音仅在本机可用时生成", color: ArchiveTheme.danger)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("IDENTITY PANEL")
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

            Text("CHARACTER FAMILY")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(card.identity.characterID.map { $0.uppercased() } ?? "ARCHETYPE")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text("角色族谱只用于聚合浏览，身份卡仍独立收藏。")
                        .font(.system(size: 11))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                Text(card.identity.characterID == nil ? "—" : "\(model.characterCardCount(for: card.identity.characterID)) CARDS")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(ArchiveTheme.teal)
            }
            .padding(.top, 12)

            PanelDivider()

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("VOICE / SPEECHRAIL")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                    Text(card.narrative?.voiceProfileID ?? "暂无音色绑定")
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
                        Label("唤醒卡牌", systemImage: "waveform")
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

            Text("SEMANTIC READBACK")
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
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(index)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ArchiveTheme.primary)
            }
            Text(value)
                .font(.system(size: 11))
                .foregroundStyle(ArchiveTheme.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(11)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
        .background(
            ArchiveTheme.coal.opacity(0.46),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(ArchiveTheme.elevated.opacity(0.62), lineWidth: 1)
        }
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
        return "\(prefix) · \(caption.kind.captionDisplayName)"
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
                            Text("故事全文在故事抽屉中")
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
                    Text("STORY DRAWER  /  CHAPTER 01")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                    Text("\(card.identity.displayName)的序列")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text(hasPlayableChapter ? "第三人称档案叙述  ·  人工确认  ·  interpretation" : "第三人称档案叙述  ·  候选稿  ·  interpretation")
                        .font(.system(size: 11))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                Text(drawerPlaybackLabel.uppercased())
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
                    Text(selectedChapter?.line.text ?? "暂无故事草稿")
                        .font(.system(size: 17))
                        .foregroundStyle(ArchiveTheme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(selectedChapterIsPlayable ? "文字稿已确认；音频失败不会阻塞故事阅读。" : "候选文字稿可阅读；人工批准后才会进入声音播放。")
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
                                : "故事未获批准"
                        )
                        .accessibilityValue(selectedChapterIsCurrent ? playback.state.captionStatusLabel : "未播放当前章节")
                        .accessibilityHint(
                            selectedChapterIsPlayable
                                ? "播放当前章节"
                                : "当前章节只能阅读文字稿，人工批准后才可播放"
                        )
                        Button {
                            playback.replay()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(IconButtonStyle())
                        .disabled(!selectedChapterIsPlayable || !selectedChapterIsCurrent)
                        .accessibilityLabel("重播当前章节")
                        .accessibilityHint("从头播放当前已批准章节")
                        Button {
                            playback.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(IconButtonStyle())
                        .accessibilityLabel("停止播放")
                        .accessibilityHint("停止当前故事音频")
                    }
                    Text("CHAPTERS")
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
                                Text(chapter.line.isPlayable ? "可播放" : "草稿")
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
                        .accessibilityValue(chapter.line.isPlayable ? "可播放" : "草稿")
                        .accessibilityHint(
                            chapter.line.isPlayable
                                ? "选择并播放该章节"
                                : "可阅读文字稿，但尚未批准播放"
                        )
                    }
                    if chapters.isEmpty {
                        Text("暂无故事内容")
                            .font(.system(size: 10))
                            .foregroundStyle(ArchiveTheme.amber)
                    } else if !hasPlayableChapter {
                        Text("候选稿可阅读；人工批准后进入播放列表")
                            .font(.system(size: 10))
                            .foregroundStyle(ArchiveTheme.amber)
                    }
                }
                .frame(width: 250, alignment: .leading)
                .padding(16)
                .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        Text("SOURCE SNAPSHOT  ·  content hash matched  ·  voice recipe v0.2")
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(ArchiveTheme.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ArchiveTheme.ink)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .glassEffect(
                .regular.tint(ArchiveTheme.amber).interactive(),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .archiveInteractiveSurface(
                accent: ArchiveTheme.amber,
                cornerRadius: 12,
                isInteractive: isEnabled
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ArchiveTheme.primary)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .glassEffect(
                .regular.tint(ArchiveTheme.teal.opacity(0.12)).interactive(),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .archiveInteractiveSurface(
                accent: ArchiveTheme.teal,
                cornerRadius: 12,
                isInteractive: isEnabled
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct IconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(ArchiveTheme.primary)
            .frame(width: 36, height: 36)
            .glassEffect(
                .regular.tint(ArchiveTheme.elevated.opacity(0.32)).interactive(),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .archiveInteractiveSurface(
                accent: ArchiveTheme.teal,
                cornerRadius: 10,
                isInteractive: isEnabled
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}
