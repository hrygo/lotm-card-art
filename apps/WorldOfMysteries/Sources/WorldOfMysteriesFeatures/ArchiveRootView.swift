import SwiftUI
import WorldOfMysteriesCore

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
                .navigationSplitViewColumnWidth(min: 240, ideal: 278, max: 330)
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle(navigationTitle)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        toolbarActions
                    }
                }
        }
        .navigationSplitViewStyle(.balanced)
        .background(ArchiveTheme.ink)
        .backgroundExtensionEffect()
        .preferredColorScheme(.dark)
        .frame(minWidth: DesignTokens.Size.windowMinWidth, minHeight: DesignTokens.Size.windowMinHeight)
        .sheet(isPresented: fateGenesisPresented) {
            fateGenesisSheet
        }
        .onChange(of: model.selectedCardID) { _, _ in
            playback.stop()
        }
        .task {
            // 启动后就把画册要用的这一档卡图在后台解好：进「卡牌」不再现场解码
            // （实测每张 PNG 冷解码约 20ms，解码曾经落在帧提交的主线程上）。
            ArtworkStore.shared.preload(model.cards.compactMap(\.artworkResourceName))
        }
        .onDisappear {
            playback.stop()
        }
    }

    // MARK: - 一级区域路由（PRD §2.3）

    @ViewBuilder
    private var detailContent: some View {
        switch model.activeArea {
        case .world:
            WorldHomeView(model: model)
        case .cards:
            Group {
                if let card = model.selectedCard {
                    CardDetailView(card: card, model: model, playback: playback)
                } else {
                    AlbumHomeView(model: model)
                }
            }
            .id(model.selectedCardID ?? "archive-home")
        case .characters:
            if let profile = model.selectedCharacter {
                CharacterProfileView(profile: profile, model: model)
                    .id(profile.id)
            } else {
                CharacterRosterView(model: model)
            }
        case .storyBook:
            if let episode = model.selectedEpisode {
                EpisodeDetailView(episode: episode, model: model)
                    .id(episode.id)
            } else {
                StoryBookHomeView(model: model)
            }
        }
    }

    private var navigationTitle: String {
        switch model.activeArea {
        case .world:
            return model.world.worldName
        case .cards:
            return model.selectedCard?.identity.displayName ?? ""
        case .characters:
            return model.selectedCharacter?.displayName ?? WorldShellCopy.characterList
        case .storyBook:
            return model.selectedEpisode?.title ?? WorldShellCopy.storyBook
        }
    }

    @ViewBuilder
    private var toolbarActions: some View {
        switch model.activeArea {
        case .cards:
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
        case .characters:
            if model.selectedCharacter != nil {
                Button {
                    model.clearCharacterSelection()
                } label: {
                    Label("返回人物列表", systemImage: "chevron.left")
                }
                .help("返回人物列表")
                .keyboardShortcut(.escape, modifiers: [])
            }
        case .storyBook:
            if model.selectedEpisode != nil {
                Button {
                    model.clearEpisodeSelection()
                } label: {
                    Label("返回故事书", systemImage: "chevron.left")
                }
                .help("返回故事书")
                .keyboardShortcut(.escape, modifiers: [])
            }
        case .world:
            EmptyView()
        }
    }

    private var fateGenesisPresented: Binding<Bool> {
        Binding(
            get: { model.fateGenesisCard != nil },
            set: { isPresented in
                if !isPresented {
                    model.dismissFateGenesis()
                }
            }
        )
    }

    @ViewBuilder
    private var fateGenesisSheet: some View {
        if let card = model.fateGenesisCard {
            let entry = model.fateEntry(for: card)
            FateGenesisSheet(
                card: card,
                entry: entry,
                presentation: FateSeedLibrary.genesisPresentation(for: card, entry: entry),
                model: model
            )
        }
    }
}

private struct ArchiveSidebar: View {
    @ObservedObject var model: AlbumViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s5) {
                    Text("LOTM")
                        .font(.system(size: DesignTokens.FontSize.s22, weight: .black, design: .rounded))
                        .foregroundStyle(ArchiveTheme.amber)
                    Text("秘史档案馆")
                        .font(.system(size: DesignTokens.FontSize.s12, weight: .medium))
                        .foregroundStyle(ArchiveTheme.primary)
                }
                Spacer()
                Circle()
                    .stroke(ArchiveTheme.amber.opacity(0.78), lineWidth: DesignTokens.Stroke.hairline)
                    .frame(width: DesignTokens.Size.controlSmall, height: DesignTokens.Size.controlSmall)
                    .overlay {
                        Text("✦")
                            .font(.system(size: DesignTokens.FontSize.s14))
                            .foregroundStyle(ArchiveTheme.amber)
                    }
            }
            .padding(.top, DesignTokens.Space.s24)
            .padding(.bottom, DesignTokens.Space.s24)

            // 品牌头固定；下面的导航在窗口不高时滚动，而不是把一级入口裁掉。
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(WorldShellCopy.primaryAreas)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                        .padding(.bottom, DesignTokens.Space.s12)

                    VStack(spacing: DesignTokens.Space.s6) {
                        ForEach(PrimaryArea.allCases) { area in
                            ShellAreaButton(
                                area: area,
                                isSelected: model.activeArea == area,
                                badge: badge(for: area),
                                action: { model.show(area) }
                            )
                        }
                    }
                    .padding(.bottom, DesignTokens.Space.s24)

                    Text(WorldShellCopy.localNavigation)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                        .padding(.bottom, DesignTokens.Space.s12)

                    if model.activeArea == .cards {
                        cardsLocalNavigation
                    } else {
                        areaLocalNavigation
                    }

                    Rectangle()
                        .fill(ArchiveTheme.elevated)
                        .frame(height: 1)
                        .padding(.vertical, DesignTokens.Space.s22)

                    Text(ArchiveCopy.localLibrary)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                    Text("\(model.confirmedCount) 张已确认卡牌")
                        .font(.system(size: DesignTokens.FontSize.s12, weight: .medium, design: .rounded))
                        .foregroundStyle(ArchiveTheme.primary)
                        .padding(.top, DesignTokens.Space.s12)
                    Text("内容保存在本机")
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .regular, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                        .padding(.top, DesignTokens.Space.s5)

                    areaStatusBlock
                        .padding(.top, DesignTokens.Space.s20)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.never)

            // 进行中的命运固定在侧边栏底部，切换区域时也看得见（PRD §2.2）。
            if let episode = model.world.activeEpisodes.first {
                Rectangle()
                    .fill(ArchiveTheme.elevated)
                    .frame(height: 1)
                    .padding(.top, DesignTokens.Space.s18)
                activeFateBlock(episode)
                    .padding(.top, DesignTokens.Space.s18)
            }
        }
        .padding(DesignTokens.Space.s24)
        .padding(.leading, DesignTokens.Space.s8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(ArchiveTheme.Leather.base.opacity(0.88))
        .overlay(alignment: .leading) {
            GrimoireSpineBands()
        }
    }

    // MARK: - 卡牌区域的局部导航（既有收藏分栏与途径入口）

    @ViewBuilder
    private var cardsLocalNavigation: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarButton(
                title: "画册",
                symbol: "rectangle.grid.2x2",
                isSelected: model.activeSection == .gallery
            ) {
                model.show(.cards)
                model.show(.gallery)
            }
            SidebarButton(title: "我的收藏", symbol: "diamond", isSelected: model.activeSection == .formal) {
                model.show(.cards)
                model.show(.formal)
            }
            SidebarButton(title: "候选收藏", symbol: "sparkles", isSelected: model.activeSection == .candidate) {
                model.show(.cards)
                model.show(.candidate)
            }
            SidebarButton(title: "愿望清单", symbol: "sparkle", isSelected: model.activeSection == .wishlist) {
                model.show(.cards)
                model.show(.wishlist)
            }

            Text(ArchiveCopy.pathways)
                .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.top, DesignTokens.Space.s28)
                .padding(.bottom, DesignTokens.Space.s12)

            PathwayButton(
                title: "愚者",
                detail: model.pathwaySummary(for: "fool"),
                color: ArchiveTheme.teal,
                action: {
                    model.show(.cards)
                    model.clearSelection()
                }
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
        }
    }

    // MARK: - 其余区域的局部导航（PRD §2.2）

    @ViewBuilder
    private var areaLocalNavigation: some View {
        switch model.activeArea {
        case .cards:
            EmptyView()
        case .world:
            VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
                Text(WorldShellCopy.areaHint(for: .world))
                    .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                ShellChip(
                    text: WorldSummaryCopy.unresolvedLine(count: model.world.unresolvedEvents.count),
                    color: ArchiveTheme.ice
                )
            }
        case .characters:
            let characters = model.characters
            if characters.isEmpty {
                Text(WorldShellCopy.rosterEmpty)
                    .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s4) {
                    ForEach(characters) { character in
                        SidebarButton(
                            title: character.displayName,
                            symbol: "person",
                            isSelected: model.selectedCharacterID == character.id
                        ) {
                            model.show(.characters)
                            model.select(character: character)
                        }
                    }
                }
            }
        case .storyBook:
            let episodes = model.visibleEpisodes
            if episodes.isEmpty {
                Text(WorldShellCopy.noStoryBookEntries)
                    .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s4) {
                    ForEach(episodes) { episode in
                        SidebarButton(
                            title: episode.title,
                            symbol: episode.state == .inProgress ? "hourglass" : "book.closed",
                            isSelected: model.selectedEpisodeID == episode.id
                        ) {
                            model.show(.storyBook)
                            model.select(episode: episode)
                        }
                    }
                }
            }
        }
    }

    private var areaStatusBlock: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
            HStack(spacing: DesignTokens.Space.s8) {
                Circle()
                    .fill(ArchiveTheme.Aether.light)
                    .frame(width: 7, height: 7)
                Text(model.activeArea.title)
                    .font(.system(size: DesignTokens.FontSize.s12, weight: .semibold))
                    .foregroundStyle(ArchiveTheme.Parchment.primary)
            }
            Text(WorldShellCopy.areaHint(for: model.activeArea))
                .font(.system(size: DesignTokens.FontSize.s10, design: .rounded))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(WorldShellCopy.footerAction(for: model.activeArea))
                .font(.system(size: DesignTokens.FontSize.s11, weight: .semibold))
                .foregroundStyle(ArchiveTheme.Brass.luster)
        }
        .padding(DesignTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArchiveTheme.Leather.raised, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.hairline)
        }
    }

    private func badge(for area: PrimaryArea) -> String? {
        switch area {
        case .world:
            return nil
        case .cards:
            return "\(model.cards.count)"
        case .characters:
            return "\(model.characters.count)"
        case .storyBook:
            return "\(model.world.episodes.count)"
        }
    }

    private func activeFateBlock(_ episode: EpisodeRecord) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
            HStack(spacing: DesignTokens.Space.s8) {
                Circle()
                    .fill(ArchiveTheme.Brass.luster)
                    .frame(width: 7, height: 7)
                Text(WorldShellCopy.currentFate)
                    .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Brass.luster)
            }
            Text(episode.title)
                .font(.system(size: DesignTokens.FontSize.s12, weight: .semibold, design: .serif))
                .foregroundStyle(ArchiveTheme.Parchment.primary)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(episode.protagonistName) · \(episode.metaLine)")
                .font(.system(size: DesignTokens.FontSize.s10, design: .rounded))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(WorldShellCopy.continueFate) {
                model.continueFate(episode)
            }
            .buttonStyle(ShellSecondaryButtonStyle())
        }
        .padding(DesignTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArchiveTheme.Leather.raised, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.hairline)
        }
    }
}

private struct SidebarTactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.08 : 0.0)
            .opacity(configuration.isPressed ? 0.86 : 1.0)
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
            HStack(spacing: DesignTokens.Space.s14) {
                Image(systemName: symbol)
                    .font(.system(size: DesignTokens.FontSize.s14, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 18)
                Text(title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                Spacer()
                if isSelected {
                    Text("✦")
                        .font(.system(size: DesignTokens.FontSize.s10))
                        .foregroundStyle(ArchiveTheme.Brass.luster.opacity(0.85))
                }
            }
            .padding(.horizontal, DesignTokens.Space.s14)
            .frame(height: DesignTokens.Size.hitTarget)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
                        .fill(ArchiveTheme.Gradients.leatherSurface)
                }
            }
            .glassEffect(
                isSelected
                    ? .regular.tint(ArchiveTheme.Brass.luster.opacity(0.18))
                    : .identity,
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
            )
            .overlay {
                if isSelected {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
                            .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.hairline)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [ArchiveTheme.Brass.luster, ArchiveTheme.Brass.core],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3.5, height: DesignTokens.Size.controlSmall)
                            .shadow(color: ArchiveTheme.Brass.luster.opacity(0.8), radius: 4)
                    }
                }
            }
            // 命中区域按整行矩形声明：圆角外侧与 Spacer 留白也算这一行的点击范围，
            // 否则只有画出来的圆角背景与文字图标可点。
            .contentShape(Rectangle())
            .archiveInteractiveSurface(
                accent: ArchiveTheme.Brass.luster,
                cornerRadius: DesignTokens.Radius.r12
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
            HStack(spacing: DesignTokens.Space.s12) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: DesignTokens.Space.s4) {
                    Text(title)
                        .font(.system(size: DesignTokens.FontSize.s13, weight: .semibold))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text(detail)
                        .font(.system(size: DesignTokens.FontSize.s10, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Space.s14)
            .frame(height: 52)
            .background(
                title == "愚者" ? ArchiveTheme.raised.opacity(0.38) : .clear,
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
            )
            .glassEffect(
                title == "愚者"
                    ? .regular.tint(color.opacity(0.14))
                    : .identity,
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
            )
            .contentShape(Rectangle())
            .archiveInteractiveSurface(
                accent: color,
                cornerRadius: DesignTokens.Radius.r12,
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
            VStack(alignment: .leading, spacing: DesignTokens.Space.s26) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
                        Text(ArchiveCopy.sectionEyebrow(for: model.activeSection))
                            .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                            .foregroundStyle(ArchiveTheme.Aether.light)
                        Text(model.activeSection.title)
                            .font(.system(size: DesignTokens.FontSize.s34, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ArchiveTheme.Parchment.primary, ArchiveTheme.Brass.gleam],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: ArchiveTheme.Brass.luster.opacity(0.20), radius: 8, x: 0, y: 2)
                        Text(model.activeSection.subtitle)
                            .font(.system(size: DesignTokens.FontSize.s13, design: .serif))
                            .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    }
                    Spacer(minLength: DesignTokens.Space.s24)
                    Label("保存在本机", systemImage: "internaldrive")
                        .font(.system(size: DesignTokens.FontSize.s11, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                }

                HStack(spacing: 0) {
                    MetricTile(title: "已确认", value: "\(model.confirmedCount)", color: ArchiveTheme.Aether.light)
                    MetricTile(title: "正式收藏", value: "\(model.formalCount)", color: ArchiveTheme.Brass.luster)
                    MetricTile(title: "候选收藏", value: "\(model.candidateCount)", color: ArchiveTheme.Status.candidate)
                    MetricTile(
                        title: ArchiveCopy.wishlistMetricTitle,
                        value: "\(model.wishlistCount)",
                        color: ArchiveTheme.Parchment.secondary
                    )
                }
                .padding(DesignTokens.Space.s24)
                .background(ArchiveTheme.Gradients.leatherSurface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r20, style: .continuous))
                .glassEffect(.regular.tint(ArchiveTheme.Aether.light.opacity(0.06)), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r20, style: .continuous)
                        .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.hairline)
                }

                VStack(alignment: .leading, spacing: DesignTokens.Space.s6) {
                    Text(ArchiveCopy.localLibrary)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                    Text(ArchiveCopy.recentDiscoveries)
                        .font(.system(size: DesignTokens.FontSize.s22, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.primary)
                    Text("\(model.visibleCards.count) 张卡牌")
                        .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                }

                if model.visibleCards.isEmpty {
                    EmptyLibraryState(model: model)
                } else {
                    // 瓦片各自的玻璃面放进同一个容器一起渲染，减少逐片采样背景的开销。
                    // 容器 spacing 特意小于网格间距（16）：Apple 文档说明「容器 spacing 大于内部
                    // 布局 spacing 会让相邻玻璃在静止时就融合成一片」，这里要保持卡面各自独立。
                    GlassEffectContainer(spacing: DesignTokens.Space.s8) {
                        // 列宽上限与瓦片成片的显示覆盖一致（`albumTileMaxDisplayWidth`）：
                        // 没有上限时超宽窗口会把瓦片拉过 800px 成片，卡面就糊了。
                        LazyVGrid(
                            columns: [
                                GridItem(
                                    .flexible(minimum: 165, maximum: albumTileMaxDisplayWidth),
                                    spacing: DesignTokens.Space.s16
                                ),
                                GridItem(
                                    .flexible(minimum: 165, maximum: albumTileMaxDisplayWidth),
                                    spacing: DesignTokens.Space.s16
                                ),
                                GridItem(
                                    .flexible(minimum: 165, maximum: albumTileMaxDisplayWidth),
                                    spacing: DesignTokens.Space.s16
                                ),
                                GridItem(
                                    .flexible(minimum: 220, maximum: albumTileMaxDisplayWidth),
                                    spacing: DesignTokens.Space.s16
                                )
                            ],
                            alignment: .leading,
                            spacing: DesignTokens.Space.s16
                        ) {
                            ForEach(model.visibleCards) { card in
                                CardTileView(card: card, experienceLabel: model.experienceLabel(for: card)) {
                                    model.select(card)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Space.s36)
            .padding(.bottom, DesignTokens.Space.s40)
            .padding(.top, DesignTokens.Space.s68)
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
        VStack(spacing: DesignTokens.Space.s14) {
            Image(systemName: model.hasSearchQuery ? "magnifyingglass" : "tray")
                .font(.system(size: DesignTokens.FontSize.s26, weight: .light))
                .foregroundStyle(ArchiveTheme.amber)
                .accessibilityHidden(true)
            Text(model.hasSearchQuery ? "没有找到匹配的身份卡" : "这个清单还没有身份卡")
                .font(.system(size: DesignTokens.FontSize.s19, weight: .bold))
                .foregroundStyle(ArchiveTheme.primary)
            Text(
                model.hasSearchQuery
                    ? "没有卡牌匹配“\(query)”；可以清除搜索后继续浏览。"
                    : "新的身份卡收录后会出现在这里。"
            )
            .font(.system(size: DesignTokens.FontSize.s12))
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
        .padding(DesignTokens.Space.s28)
        .glassEffect(
            .regular.tint(ArchiveTheme.amber.opacity(0.08)),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r20, style: .continuous)
        )
        .accessibilityElement(children: .contain)
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
    let experienceLabel: String
    let action: () -> Void

    private var roleLabel: String {
        IdentityRoleResolver.role(for: card.identity).label
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ArchiveArtworkView(
                    theme: card.visualTheme,
                    compact: true,
                    resourceName: card.artworkResourceName
                )
                .padding(DesignTokens.Space.s12)
                VStack(alignment: .leading, spacing: DesignTokens.Space.s7) {
                    SequenceBadge(sequenceName: card.identity.sequenceName)
                    Text(card.identity.displayName)
                        .font(.system(size: DesignTokens.FontSize.s17, weight: .bold))
                        .foregroundStyle(ArchiveTheme.primary)
                        .lineLimit(1)
                    Text(card.subtitle)
                        .font(.system(size: DesignTokens.FontSize.s10, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                        .lineLimit(1)
                    HStack(spacing: DesignTokens.Space.s6) {
                        ShellChip(text: roleLabel, color: ArchiveTheme.Brass.core)
                        Text(experienceLabel)
                            .font(.system(size: DesignTokens.FontSize.s10, design: .rounded))
                            .foregroundStyle(ArchiveTheme.Parchment.muted)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        StatusChip(status: card.identity.contentStatus)
                    }
                }
                .padding(.horizontal, DesignTokens.Space.s16)
                .padding(.bottom, DesignTokens.Space.s14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ArchiveTheme.Gradients.leatherSurface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r17, style: .continuous))
            .glassEffect(
                // 不再叠 `.interactive()`：瓦片本身是按钮，悬停描边与指针反馈已由
                // archiveInteractiveSurface 负责，材质再接管指针只是重复开销。
                .regular.tint(card.identity.contentStatus.accentColor.opacity(0.10)),
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r17, style: .continuous)
            )
            .overlay {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r17, style: .continuous)
                        .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.hairline)
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r17, style: .continuous)
                        .stroke(card.identity.contentStatus.accentColor.opacity(0.32), lineWidth: DesignTokens.Stroke.hairline)
                }
            }
            .archiveInteractiveSurface(
                accent: card.identity.contentStatus.accentColor,
                cornerRadius: DesignTokens.Radius.r17,
                hoverScale: 1.01
            )
        }
        .buttonStyle(TactileCardButtonStyle(accentColor: card.identity.contentStatus.accentColor))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(card.identity.displayName)，\(roleLabel)，\(ArchiveCopy.sequenceDisplayLabel(for: card.identity.sequenceName, includesRank: true))"
        )
        .accessibilityValue(
            "状态：\(card.identity.contentStatus.displayTitle)；\(experienceLabel)；\(card.subtitle)"
        )
        .accessibilityHint("打开卡牌详情")
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
                    withAnimation(.easeOut(duration: DesignTokens.MotionDuration.ms200)) {
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
                    .padding(.top, DesignTokens.Space.s110)
                    .padding(.bottom, CardDetailLayout.verticalPadding)
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
            VStack(alignment: .center, spacing: DesignTokens.Space.s28) {
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
        VStack(spacing: DesignTokens.Space.s14) {
            ZStack {
                // 底层：做旧古籍真皮封皮深色渐变
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r28, style: .continuous)
                    .fill(ArchiveTheme.Gradients.grimoireCover)

                // 核心法阵：Logo 封皮同款赫密斯同心圆占星法阵与暖金+青碧双色灵流
                HermeticSigilView(size: 380, showDualGlow: true)

                // 典籍内嵌卡槽边框（黄铜暗金压条与内凹阴影）
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r22, style: .continuous)
                    .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.strong)
                    .padding(DesignTokens.Space.s20)

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
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.r28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r28, style: .continuous)
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
                        lineWidth: DesignTokens.Stroke.strong
                    )
            }
            .shadow(color: ArchiveTheme.Leather.void.opacity(0.60), radius: 18, y: 10)
            .archiveCursor(.arrow)

            HStack {
                SequenceBadge(sequenceName: card.identity.sequenceName, includesRank: true)
                Spacer()
                Text(card.identity.displayName)
                    .font(.system(size: DesignTokens.FontSize.s13, weight: .bold, design: .serif))
                    .foregroundStyle(ArchiveTheme.Parchment.primary)
            }
            .frame(width: CardDetailLayout.motionViewportSize.width)
            .archiveCursor(.arrow)

            Text(card.subtitle)
                .font(.system(size: DesignTokens.FontSize.s10, design: .rounded))
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
        VStack(alignment: .leading, spacing: DesignTokens.Space.s20) {
            FateEntryPanel(card: card, model: model)

            HStack(spacing: DesignTokens.Space.s12) {
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

                Spacer(minLength: DesignTokens.Space.s12)

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
        .padding(DesignTokens.Space.s24)
        .frame(
            maxWidth: .infinity,
            minHeight: CardDetailLayout.minimumRailHeight(for: mode),
            alignment: .topLeading
        )
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r22, style: .continuous)
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
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.r22, style: .continuous))
        }
        .glassEffect(.regular.tint(ArchiveTheme.Brass.luster.opacity(0.04)), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r22, style: .continuous)
                .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.hairline)
        }
        .frame(
            minWidth: isStacked ? 0 : CardDetailLayout.railMinimumWidth,
            maxWidth: isStacked ? .infinity : CardDetailLayout.railMaximumWidth,
            alignment: .topLeading
        )
        .archiveCursor(.arrow)
    }
}

/// 卡牌详情的命运入口（PRD §3.3）：措辞随身份类型变化，并显示这张卡在世界里的位置。
private struct FateEntryPanel: View {
    let card: AlbumCard
    @ObservedObject var model: AlbumViewModel

    private var entry: FateEntry {
        model.fateEntry(for: card)
    }

    private var experience: String {
        model.experienceLabel(for: card)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s12) {
            HStack(spacing: DesignTokens.Space.s8) {
                Text(WorldShellCopy.fateSection)
                    .font(.system(size: DesignTokens.FontSize.s10, weight: .bold, design: .serif))
                    .foregroundStyle(ArchiveTheme.Brass.luster)
                ShellChip(text: entry.role.label, color: ArchiveTheme.Brass.core)
                ShellChip(text: experience, color: ArchiveTheme.Aether.light)
            }

            Text(note)
                .font(.system(size: DesignTokens.FontSize.s12, design: .serif))
                .foregroundStyle(ArchiveTheme.Parchment.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: DesignTokens.Space.s10) {
                Button(entry.primaryTitle) {
                    activate()
                }
                .buttonStyle(ShellPrimaryButtonStyle())
                .disabled(!entry.isAvailable)
                .help(entry.availabilityNote)

                if let secondaryTitle = entry.secondaryTitle {
                    Button(secondaryTitle) {
                        model.presentFateGenesis(for: card)
                    }
                    .buttonStyle(ShellSecondaryButtonStyle())
                    .disabled(!entry.isAvailable)
                }
            }
        }
        .padding(DesignTokens.Space.s16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ArchiveTheme.Leather.deep.opacity(0.45),
            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r16, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r16, style: .continuous)
                .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.hairline)
        }
        .accessibilityElement(children: .contain)
    }

    private var note: String {
        if let activeEpisodeID = entry.activeEpisodeID,
           let episode = model.world.episode(id: activeEpisodeID) {
            let situation = episode.visibleSeed?.anomaly ?? episode.metaLine
            return "\(episode.title)：\(situation)。"
        }
        return WorldShellCopy.fateEntryNote(for: entry, experience: experience)
    }

    private func activate() {
        guard entry.isAvailable else {
            return
        }
        if let activeEpisodeID = entry.activeEpisodeID,
           let episode = model.world.episode(id: activeEpisodeID) {
            model.continueFate(episode)
        } else {
            model.presentFateGenesis(for: card)
        }
    }
}

private struct IdentityPanel: View {
    let card: AlbumCard
    @ObservedObject var model: AlbumViewModel
    @ObservedObject var playback: SpeechPlaybackCoordinator

    private var voiceAvailability: VoiceAvailability {
        switch card.audioStatus {
        case .localBundle:
            return .localAudio
        case .speechRailFallback:
            return .speechRail
        case .pendingApproval:
            return .pending
        }
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
            return ArchiveTheme.Playback.ready
        case .speechRail:
            return ArchiveTheme.Playback.preparing
        case .pending:
            return ArchiveTheme.Playback.idle
        }
    }

    private var pathwayLabel: String {
        if card.identity.slotID.hasPrefix("lotm.visionary") {
            return "观众途径 · 空想家"
        }
        if card.identity.slotID.hasPrefix("lotm.celestial-worthy") {
            return "序列之上 · 诡秘之主"
        }
        if card.identity.slotID.hasPrefix("lotm.god-almighty") {
            return "序列之上 · 星界支柱"
        }
        if card.identity.slotID.hasPrefix("lotm.mother-goddess-depravity") {
            return "序列之上 · 现实支柱"
        }
        if card.identity.slotID.hasPrefix("lotm.eternal-darkness") {
            return "序列之上 · 永暗之河"
        }
        if card.identity.slotID.hasPrefix("lotm.father-of-demons") {
            return "序列之上 · 暗影世界"
        }
        if card.identity.slotID.hasPrefix("lotm.destruction-calamity") {
            return "序列之上 · 灾祸之城"
        }
        if card.identity.slotID.hasPrefix("lotm.embodiment-of-disorder") {
            return "序列之上 · 失序之国"
        }
        if card.identity.slotID.hasPrefix("lotm.demon-of-knowledge") {
            return "序列之上 · 知识荒野"
        }
        if card.identity.slotID.hasPrefix("lotm.key-of-light") {
            return "序列之上 · 光之钥"
        }
        return "愚者途径"
    }

    private var sequenceLabelColor: Color {
        ArchiveTheme.Sequence.labelColor(
            for: ArchiveCopy.sequenceTier(for: card.identity.sequenceName)
        )
    }

    private func semanticColor(for index: String) -> Color {
        switch index {
        case "01":
            return sequenceLabelColor
        case "02":
            return ArchiveTheme.Semantic.acting
        case "03":
            return ArchiveTheme.Semantic.ability
        case "04":
            return ArchiveTheme.Semantic.potion
        case "05":
            return ArchiveTheme.Semantic.promotion
        case "06":
            return ArchiveTheme.Semantic.limitation
        default:
            return ArchiveTheme.Semantic.limitation
        }
    }

    private var semanticReadbacks: [SemanticReadback] {
        card.semanticReadbacks.map { fact in
            SemanticReadback(
                index: fact.index,
                title: fact.title,
                value: fact.value,
                color: semanticColor(for: fact.index)
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s7) {
                    Text(ArchiveCopy.identityInfo)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.teal)
                    Text(card.identity.displayName)
                        .font(.system(size: DesignTokens.FontSize.s28, weight: .bold))
                        .foregroundStyle(ArchiveTheme.primary)
                    HStack(spacing: DesignTokens.Space.s7) {
                        SequenceBadge(sequenceName: card.identity.sequenceName, includesRank: true)
                        Text(pathwayLabel)
                            .font(.system(size: DesignTokens.FontSize.s12))
                            .foregroundStyle(ArchiveTheme.secondary)
                    }
                }
                Spacer()
            }

            PanelDivider()

            Text(ArchiveCopy.characterRelationTitle(for: card.identity.characterID))
                .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s5) {
                    Text(ArchiveCopy.characterName(for: card.identity.characterID))
                        .font(.system(size: DesignTokens.FontSize.s16, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.primary)
                    if let note = ArchiveCopy.characterRelationNote(for: card.identity.characterID) {
                        Text(note)
                            .font(.system(size: DesignTokens.FontSize.s11))
                            .foregroundStyle(ArchiveTheme.secondary)
                    }
                }
                Spacer()
                Text(
                    ArchiveCopy.characterCountLabel(
                        for: card.identity.characterID,
                        count: model.characterCardCount(for: card.identity.characterID)
                    )
                )
                .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.teal)
            }
            .padding(.top, DesignTokens.Space.s12)

            PanelDivider()

            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s5) {
                    Text(ArchiveCopy.voice)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                    Text(ArchiveCopy.voiceTitle(for: card.identity))
                        .font(.system(size: DesignTokens.FontSize.s16, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.primary)
                    Text(voiceStatusLabel)
                        .font(.system(size: DesignTokens.FontSize.s10, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                HStack(spacing: DesignTokens.Space.s7) {
                    Circle()
                        .fill(voiceStatusColor)
                        .frame(width: 6, height: 6)
                    Text(voiceAvailability.statusLabel)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold))
                        .foregroundStyle(voiceStatusColor)
                }
                .padding(.horizontal, DesignTokens.Space.s10)
                .padding(.vertical, DesignTokens.Space.s8)
                .background(ArchiveTheme.coal, in: Capsule())
            }

            GlassEffectContainer(spacing: DesignTokens.Space.s12) {
                HStack(spacing: DesignTokens.Space.s12) {
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
                }
            }
            .padding(.top, DesignTokens.Space.s24)

            LiveCaptionRail(
                caption: playback.currentCaption,
                state: playback.state,
                storyDrawerPresented: model.isStoryDrawerPresented,
                emptyMessage: voiceAvailability.captionPrompt,
                onOpenStory: {
                    if !model.isStoryDrawerPresented {
                        model.toggleStoryDrawer()
                    }
                }
            )
            .padding(.top, DesignTokens.Space.s16)

            PanelDivider()

            Text(ArchiveCopy.semanticReadback)
                .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.bottom, DesignTokens.Space.s14)
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
            .padding(.vertical, DesignTokens.Space.s22)
    }
}

private struct IdentityReadbackGrid: View {
    let rows: [SemanticReadback]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: DesignTokens.Space.s12) {
                readbackColumn(rows: rows.enumerated().compactMap { index, row in
                    index.isMultiple(of: 2) ? row : nil
                })
                readbackColumn(rows: rows.enumerated().compactMap { index, row in
                    index.isMultiple(of: 2) ? nil : row
                })
            }
            .frame(minWidth: 532, maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
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
        VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
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
    let emptyMessage: String
    let onOpenStory: () -> Void

    private var accentColor: Color {
        switch state {
        case .failed:
            return ArchiveTheme.Playback.failed
        case .paused:
            return ArchiveTheme.Playback.preparing
        case .loading:
            return ArchiveTheme.Playback.preparing
        case .playing:
            return ArchiveTheme.Playback.ready
        case .idle:
            return caption == nil ? ArchiveTheme.Playback.idle : ArchiveTheme.Playback.ready
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
            return "未播放"
        }
        return state.captionStatusLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
            HStack(spacing: DesignTokens.Space.s8) {
                Image(systemName: caption == nil ? "captions.bubble" : state.captionSystemImage)
                    .font(.system(size: DesignTokens.FontSize.s12, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text(headerTitle)
                    .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)

                Spacer(minLength: DesignTokens.Space.s10)

                if state == .loading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(accentColor)
                }

                Text(statusLabel)
                    .font(.system(size: DesignTokens.FontSize.s10, weight: .medium, design: .rounded))
                    .foregroundStyle(ArchiveTheme.secondary)
            }

            if let caption {
                Text(caption.text)
                    .font(.system(size: DesignTokens.FontSize.s16, weight: .medium))
                    .foregroundStyle(ArchiveTheme.primary)
                    .lineLimit(caption.kind == .story ? 4 : 3)
                    .fixedSize(horizontal: false, vertical: true)

                if caption.kind == .story {
                    HStack(spacing: DesignTokens.Space.s6) {
                        Image(systemName: "book.closed")
                            .font(.system(size: DesignTokens.FontSize.s10, weight: .medium))
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
                                cornerRadius: DesignTokens.Radius.r6
                            )
                        }
                    }
                    .font(.system(size: DesignTokens.FontSize.s10, weight: .medium))
                    .foregroundStyle(ArchiveTheme.secondary)
                }

                if case let .failed(message) = state {
                    Text(message)
                        .font(.system(size: DesignTokens.FontSize.s11, weight: .medium))
                        .foregroundStyle(ArchiveTheme.danger)
                }
            } else {
                Text(emptyMessage)
                    .font(.system(size: DesignTokens.FontSize.s12))
                    .foregroundStyle(ArchiveTheme.secondary)
            }
        }
        .padding(DesignTokens.Space.s15)
        .background(ArchiveTheme.coal.opacity(0.78), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                .stroke(accentColor.opacity(caption == nil ? 0.16 : 0.36), lineWidth: DesignTokens.Stroke.hairline)
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

    private var chapterNavigator: StoryChapterNavigator {
        StoryChapterNavigator(
            chapters: chapters,
            selectedChapterID: selectedChapterID
        )
    }

    private var selectedChapter: StoryChapter? {
        chapterNavigator.selectedChapter
    }

    private var selectedChapterIsPlayable: Bool {
        selectedChapter?.line.isPlayable == true
    }

    private var hasPlayableChapter: Bool {
        chapters.contains { $0.line.isPlayable }
    }

    private var previousPlayableChapter: StoryChapter? {
        chapterNavigator.previousPlayableChapter
    }

    private var nextPlayableChapter: StoryChapter? {
        chapterNavigator.nextPlayableChapter
    }

    private var canReplaySelectedChapter: Bool {
        guard selectedChapterIsPlayable else {
            return false
        }
        return !selectedChapterIsCurrent || playback.state != .loading
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

    private var playButtonSystemImage: String {
        guard selectedChapterIsPlayable else {
            return "lock.fill"
        }
        if selectedChapterIsCurrent, playback.state == .loading {
            return "waveform"
        }
        return selectedChapterIsCurrent && playback.state == .playing ? "pause.fill" : "play.fill"
    }

    private var playButtonAccessibilityLabel: String {
        guard selectedChapterIsPlayable else {
            return "故事还在确认中"
        }
        if selectedChapterIsCurrent, playback.state == .loading {
            return "正在生成故事声音"
        }
        if selectedChapterIsCurrent, playback.state == .playing {
            return "暂停故事"
        }
        if selectedChapterIsCurrent, playback.state == .paused {
            return "继续故事"
        }
        return "开始播放故事"
    }

    private func play(_ chapter: StoryChapter) {
        guard chapter.line.isPlayable else {
            return
        }
        if playback.state == .loading,
           playback.currentCaption?.lineID == chapter.line.id {
            return
        }
        selectedChapterID = chapter.id
        playback.playStory(
            chapter,
            voiceProfileID: card.narrative?.voiceProfileID ?? ""
        )
    }

    private func togglePlay() {
        if selectedChapterIsCurrent, playback.state == .playing {
            playback.pause()
        } else if selectedChapterIsCurrent, playback.state == .paused {
            playback.resume()
        } else if let chapter = selectedChapter {
            play(chapter)
        }
    }

    private func replay() {
        if selectedChapterIsCurrent {
            playback.replay()
        } else if let chapter = selectedChapter {
            play(chapter)
        }
    }

    private func stop() {
        playback.stop()
    }

    private func previous() {
        if let chapter = previousPlayableChapter {
            play(chapter)
        }
    }

    private func next() {
        if let chapter = nextPlayableChapter {
            play(chapter)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ArchiveTheme.Story.Metrics.sectionSpacing) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: ArchiveTheme.Story.Metrics.headerSpacing) {
                    HStack(spacing: DesignTokens.Space.s6) {
                        Text(ArchiveCopy.story)
                            .font(ArchiveTheme.Story.Typography.eyebrow)
                            .foregroundStyle(ArchiveTheme.teal)

                        Text("·")
                            .font(.system(size: DesignTokens.FontSize.s10, weight: .bold))
                            .foregroundStyle(ArchiveTheme.Borders.brassMuted)

                        Text("秘音卷宗")
                            .font(ArchiveTheme.Story.Typography.eyebrow)
                            .foregroundStyle(ArchiveTheme.Brass.luster)
                    }

                    Text("\(card.identity.displayName)的故事")
                        .font(ArchiveTheme.Story.Typography.title)
                        .foregroundStyle(ArchiveTheme.primary)

                    Text(hasPlayableChapter ? "第三人称故事 · 可以朗读" : "第三人称故事 · 等待确认")
                        .font(ArchiveTheme.Story.Typography.note)
                        .foregroundStyle(ArchiveTheme.secondary)
                }

                Spacer()

                HStack(spacing: DesignTokens.Space.s6) {
                    Circle()
                        .fill(
                            selectedChapterIsCurrent && playback.state == .playing
                                ? ArchiveTheme.Aether.light
                                : ArchiveTheme.Brass.core
                        )
                        .frame(width: 6, height: 6)
                        .shadow(
                            color: selectedChapterIsCurrent && playback.state == .playing
                                ? ArchiveTheme.Aether.light.opacity(0.8)
                                : Color.clear,
                            radius: 4
                        )

                    Text(drawerPlaybackLabel)
                        .font(ArchiveTheme.Story.Typography.status)
                        .foregroundStyle(selectedChapterIsCurrent ? ArchiveTheme.teal : ArchiveTheme.secondary)
                }
                .padding(.horizontal, DesignTokens.Space.s10)
                .padding(.vertical, DesignTokens.Space.s5)
                .background {
                    Capsule()
                        .fill(ArchiveTheme.Leather.deep.opacity(0.8))
                    Capsule()
                        .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.hairline)
                }
            }

            Rectangle()
                .fill(ArchiveTheme.elevated)
                .frame(height: 1)

            HStack(alignment: .top, spacing: DesignTokens.Space.s20) {
                StoryFolioSheet(
                    chapter: selectedChapter,
                    isPlayable: selectedChapterIsPlayable,
                    isCurrentPlaying: selectedChapterIsCurrent,
                    playbackState: playback.state
                )

                StoryPlayerRail(
                    chapters: chapters,
                    selectedChapter: selectedChapter,
                    previousPlayableChapter: previousPlayableChapter,
                    nextPlayableChapter: nextPlayableChapter,
                    selectedChapterIsPlayable: selectedChapterIsPlayable,
                    selectedChapterIsCurrent: selectedChapterIsCurrent,
                    canReplaySelectedChapter: canReplaySelectedChapter,
                    playbackState: playback.state,
                    onPlayChapter: { chapter in
                        play(chapter)
                    },
                    onSelectChapter: { chapter in
                        selectedChapterID = chapter.id
                        if chapter.line.isPlayable && !selectedChapterIsCurrent {
                            play(chapter)
                        }
                    },
                    onTogglePlay: togglePlay,
                    onReplay: replay,
                    onStop: stop,
                    onPrevious: previous,
                    onNext: next
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DesignTokens.FontSize.s12, weight: .bold, design: .serif))
            .foregroundStyle(ArchiveTheme.Leather.void)
            .padding(.horizontal, DesignTokens.Space.s18)
            .frame(height: 40)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
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
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
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
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
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
                cornerRadius: DesignTokens.Radius.r12,
                isInteractive: isEnabled
            )
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DesignTokens.FontSize.s12, weight: .semibold, design: .serif))
            .foregroundStyle(
                configuration.isPressed
                    ? ArchiveTheme.Brass.luster
                    : ArchiveTheme.Parchment.primary
            )
            .padding(.horizontal, DesignTokens.Space.s16)
            .frame(height: 40)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
                        .fill(
                            configuration.isPressed
                                ? ArchiveTheme.Leather.void
                                : ArchiveTheme.Leather.deep.opacity(0.85)
                        )
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
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
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous)
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
                cornerRadius: DesignTokens.Radius.r12,
                isInteractive: isEnabled
            )
    }
}

private struct IconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DesignTokens.FontSize.s14, weight: .semibold))
            .foregroundStyle(
                configuration.isPressed
                    ? ArchiveTheme.Brass.luster
                    : ArchiveTheme.Parchment.primary
            )
            .frame(width: 36, height: 36)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r10, style: .continuous)
                        .fill(
                            configuration.isPressed
                                ? ArchiveTheme.Leather.void
                                : ArchiveTheme.Leather.deep.opacity(0.75)
                        )
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r10, style: .continuous)
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
                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r10, style: .continuous)
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
                cornerRadius: DesignTokens.Radius.r10,
                isInteractive: isEnabled
            )
    }
}
