import SwiftUI
import LotmCardStudioCore

@MainActor
public struct ArchiveRootView: View {
    @StateObject private var model: AlbumViewModel
    @StateObject private var playback: SpeechPlaybackCoordinator

    public init(speechClient: SpeechRailHTTPClient? = nil) {
        _model = StateObject(wrappedValue: AlbumViewModel())
        _playback = StateObject(wrappedValue: SpeechPlaybackCoordinator(client: speechClient))
    }

    public var body: some View {
        HStack(spacing: 0) {
            ArchiveSidebar(model: model)
            Rectangle()
                .fill(ArchiveTheme.elevated)
                .frame(width: 1)

            Group {
                if let card = model.selectedCard {
                    CardDetailView(card: card, model: model, playback: playback)
                } else {
                    AlbumHomeView(model: model)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ArchiveTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .preferredColorScheme(.dark)
        .frame(minWidth: 1180, minHeight: 760)
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
        .frame(width: 238)
        .background(ArchiveTheme.coal)
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
                isSelected ? ArchiveTheme.raised : .clear,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(ArchiveTheme.amber)
                        .frame(width: 3, height: 28)
                }
            }
        }
        .buttonStyle(.plain)
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
            .background(title == "愚者" ? ArchiveTheme.raised : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.48)
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
                    HStack(spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            TextField("搜索卡牌、角色或序列", text: $model.searchText)
                                .textFieldStyle(.plain)
                        }
                        .foregroundStyle(ArchiveTheme.secondary)
                        .padding(.horizontal, 13)
                        .frame(width: 245, height: 38)
                        .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Button {
                            model.searchText = ""
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(IconButtonStyle())
                        .accessibilityLabel("清除搜索")
                    }
                }

                HStack(spacing: 0) {
                    MetricTile(title: "已确认", value: "\(model.confirmedCount)", color: ArchiveTheme.teal)
                    MetricTile(title: "正式收藏", value: "\(model.formalCount)", color: ArchiveTheme.amber)
                    MetricTile(title: "候选收藏", value: "\(model.candidateCount)", color: ArchiveTheme.violet)
                    MetricTile(title: "愿望目标", value: "01", color: ArchiveTheme.secondary)
                }
                .padding(22)
                .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

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
                .background(ArchiveTheme.coal, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

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
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(ArchiveTheme.ink)
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
                ArchiveArtworkView(theme: card.visualTheme, compact: true)
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
            .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(card.identity.contentStatus.accentColor.opacity(0.28), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
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
        .background(ArchiveTheme.coal, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

private struct CardDetailView: View {
    let card: AlbumCard
    @ObservedObject var model: AlbumViewModel
    @ObservedObject var playback: SpeechPlaybackCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Button {
                        model.clearSelection()
                    } label: {
                        Label("返回画册", systemImage: "chevron.left")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ArchiveTheme.secondary)
                    Spacer()
                    Text("秘史书页")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ArchiveTheme.teal)
                }

                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IDENTITY CARD  ·  \(card.id)")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(ArchiveTheme.amber)
                        VStack(alignment: .leading, spacing: 14) {
                            ArchiveArtworkView(theme: card.visualTheme, compact: false)
                                .frame(maxWidth: 320)
                            HStack {
                                Text(card.identity.sequenceName.uppercased())
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(ArchiveTheme.amber)
                                Spacer()
                                Text(card.identity.displayName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(ArchiveTheme.primary)
                            }
                        }
                        .padding(16)
                        .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        Text("\(card.subtitle) · 2:3 · local snapshot")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundStyle(ArchiveTheme.secondary)
                    }
                    .frame(width: 340)

                    IdentityPanel(card: card, model: model, playback: playback)
                        .frame(maxWidth: .infinity, alignment: .top)
                }

                if model.isStoryDrawerPresented {
                    StoryDrawer(card: card, playback: playback)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(ArchiveTheme.ink)
        .animation(.easeOut(duration: 0.22), value: model.isStoryDrawerPresented)
    }
}

private struct IdentityPanel: View {
    let card: AlbumCard
    @ObservedObject var model: AlbumViewModel
    @ObservedObject var playback: SpeechPlaybackCoordinator

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
                    Text("\(card.identity.sequenceName)  ·  愚者途径")
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
                    Text("base profile inherited · continuity review pending")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                HStack(spacing: 7) {
                    Circle()
                        .fill(ArchiveTheme.teal)
                        .frame(width: 6, height: 6)
                    Text("本机配置")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(ArchiveTheme.teal)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ArchiveTheme.coal, in: Capsule())
            }

            HStack(spacing: 12) {
                Button {
                    playback.awaken(card: card)
                } label: {
                    Label("唤醒卡牌", systemImage: "waveform")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    model.toggleStoryDrawer()
                } label: {
                    Label("查看故事", systemImage: "book.closed")
                }
                .buttonStyle(SecondaryButtonStyle())

                Text("点击唤醒，不会自动播放")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ArchiveTheme.amber)
                    .lineLimit(1)
            }
            .padding(.top, 24)

            if case let .failed(message) = playback.state {
                Text(message)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ArchiveTheme.danger)
                    .padding(.top, 12)
            } else if playback.state != .idle {
                Text(playback.state.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ArchiveTheme.teal)
                    .padding(.top, 12)
            }

            PanelDivider()

            Text("SEMANTIC READBACK")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(ArchiveTheme.secondary)
                .padding(.bottom, 14)
            SemanticRow(index: "01", title: "身份", value: "\(card.identity.sequenceName) · \(card.identity.displayName)", color: ArchiveTheme.teal)
            SemanticRow(index: "02", title: "扮演", value: "以荒诞掩护真实", color: ArchiveTheme.amber)
            SemanticRow(index: "03", title: "能力", value: "操纵表情与注意力", color: ArchiveTheme.teal)
            SemanticRow(index: "04", title: "魔药", value: "需绑定已核验来源", color: ArchiveTheme.violet)
            SemanticRow(index: "05", title: "晋升", value: "批准依赖待复核", color: ArchiveTheme.amber)
            SemanticRow(index: "06", title: "限制", value: "语音仅在本机可用时生成", color: ArchiveTheme.danger)
        }
        .padding(26)
        .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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

private struct SemanticRow: View {
    let index: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(index)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 24, alignment: .leading)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ArchiveTheme.primary)
                .frame(width: 48, alignment: .leading)
            Text(value)
                .font(.system(size: 11))
                .foregroundStyle(ArchiveTheme.secondary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 29)
    }
}

private struct StoryDrawer: View {
    let card: AlbumCard
    @ObservedObject var playback: SpeechPlaybackCoordinator
    @State private var selectedChapterID: StoryChapter.ID?

    private var chapters: [StoryChapter] {
        card.narrative?.playableChapters ?? []
    }

    private var selectedChapter: StoryChapter? {
        guard let selectedChapterID else {
            return chapters.first
        }
        return chapters.first { $0.id == selectedChapterID } ?? chapters.first
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
                    Text("第三人称档案叙述  ·  人工确认  ·  interpretation")
                        .font(.system(size: 11))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                Spacer()
                Text(playback.state.label.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(playback.state == .playing ? ArchiveTheme.teal : ArchiveTheme.secondary)
            }

            Rectangle()
                .fill(ArchiveTheme.elevated)
                .frame(height: 1)

            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 9) {
                        Text(selectedChapter?.line.text ?? "暂无已批准故事章节")
                        .font(.system(size: 17))
                        .foregroundStyle(ArchiveTheme.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("文字稿始终可读；音频失败不会阻塞故事阅读。")
                        .font(.system(size: 11))
                        .foregroundStyle(ArchiveTheme.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Button {
                            if playback.state == .playing {
                                playback.pause()
                            } else if playback.state == .paused {
                                playback.resume()
                            } else if let chapter = selectedChapter {
                                selectedChapterID = chapter.id
                                playback.playStory(chapter, voiceProfileID: card.narrative?.voiceProfileID ?? "")
                            }
                        } label: {
                            Image(systemName: playback.state == .playing ? "pause.fill" : "play.fill")
                        }
                        .buttonStyle(IconButtonStyle())
                        Button {
                            playback.replay()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .buttonStyle(IconButtonStyle())
                        Button {
                            playback.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .buttonStyle(IconButtonStyle())
                    }
                    Text("CHAPTERS")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.secondary)
                    ForEach(chapters) { chapter in
                        Button(chapter.title) {
                            selectedChapterID = chapter.id
                            playback.playStory(chapter, voiceProfileID: card.narrative?.voiceProfileID ?? "")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(ArchiveTheme.teal)
                        .buttonStyle(.plain)
                    }
                    if chapters.isEmpty {
                        Text("未批准内容不会进入播放列表")
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
        .padding(24)
        .background(ArchiveTheme.coal, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ArchiveTheme.teal.opacity(0.24), lineWidth: 1)
        }
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ArchiveTheme.ink)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(ArchiveTheme.amber, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ArchiveTheme.primary)
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ArchiveTheme.elevated, lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

private struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(ArchiveTheme.primary)
            .frame(width: 36, height: 36)
            .background(ArchiveTheme.raised, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}
