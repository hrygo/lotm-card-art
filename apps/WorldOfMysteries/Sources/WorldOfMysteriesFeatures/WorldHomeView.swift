import SwiftUI
import WorldOfMysteriesCore

/// 世界首页（PRD §3.1）：打开即确认「我回到了同一个世界」。
struct WorldHomeView: View {
    @ObservedObject var model: AlbumViewModel
    @State private var expandedEventID: String?

    private var world: WorldSnapshot {
        model.world
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.s22) {
                header
                if world.isEmpty {
                    ShellEmptyState(
                        symbol: "sparkles",
                        title: WorldShellCopy.emptyWorldTitle,
                        note: WorldShellCopy.emptyWorldNote,
                        actionTitle: WorldShellCopy.emptyWorldAction
                    ) {
                        model.show(.cards)
                    }
                } else {
                    recentEventsSection
                    activeFatesSection
                    activePeopleSection
                    unresolvedSection
                    locationSection
                    completedStoriesSection
                }
            }
            .padding(.horizontal, DesignTokens.Space.s36)
            .padding(.top, DesignTokens.Space.s68)
            .padding(.bottom, DesignTokens.Space.s44)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(ArchiveTheme.ink)
    }

    // MARK: - 世界状态头

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
                    Text(WorldShellCopy.worldStatus)
                        .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Aether.light)
                    Text(world.worldName)
                        .font(.system(size: DesignTokens.FontSize.s34, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ArchiveTheme.Parchment.primary, ArchiveTheme.Brass.gleam],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    HStack(spacing: DesignTokens.Space.s10) {
                        ShellChip(text: world.calendar.displayLabel, color: ArchiveTheme.Aether.light)
                        ShellChip(text: world.worldline.displayLabel, color: ArchiveTheme.Brass.core)
                        ShellSampleBadge(status: world.dataStatus)
                    }
                }
                Spacer(minLength: DesignTokens.Space.s20)
                VStack(alignment: .trailing, spacing: DesignTokens.Space.s6) {
                    Text(WorldSummaryCopy.activeFateLine(count: world.activeEpisodes.count))
                        .font(.system(size: DesignTokens.FontSize.s11, weight: .semibold, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                    Text(WorldSummaryCopy.unresolvedLine(count: world.unresolvedEvents.count))
                        .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                }
            }
            if let narratorLine = world.narratorLine {
                Text(narratorLine)
                    .font(.system(size: DesignTokens.FontSize.s13, design: .serif))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            }
        }
    }

    // MARK: - 最近发生的重要事件

    private var recentEventsSection: some View {
        ShellPanel(tint: ArchiveTheme.Aether.light) {
            ShellSectionHeader(
                eyebrow: "这段时间",
                title: WorldShellCopy.recentEvents,
                note: "每一件事都可以点开，看看它牵涉到了谁。"
            )
            let events = world.recentEvents()
            if events.isEmpty {
                Text(WorldShellCopy.noRecentEvents)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(events) { event in
                        eventRow(event)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func eventRow(_ event: WorldEventRecord) -> some View {
        let isExpanded = expandedEventID == event.id
        VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
            ShellRow(
                title: event.title,
                detail: isExpanded ? event.detail : nil,
                meta: event.metaLine,
                chips: isExpanded ? eventChips(event) : [ShellChip(text: event.scopeLabel, color: ArchiveTheme.Brass.core)],
                symbol: "circle.hexagongrid",
                isEnabled: true,
                action: {
                    withAnimation(.easeOut(duration: DesignTokens.MotionDuration.ms180)) {
                        expandedEventID = isExpanded ? nil : event.id
                    }
                }
            )
            if isExpanded, !relatedEpisodes(for: event).isEmpty {
                HStack(spacing: DesignTokens.Space.s8) {
                    ForEach(relatedEpisodes(for: event)) { episode in
                        Button {
                            openStoryBook(episode)
                        } label: {
                            Label(episode.title, systemImage: "book.closed")
                        }
                        .buttonStyle(ShellSecondaryButtonStyle())
                    }
                }
                .padding(.leading, DesignTokens.Space.s32)
            }
        }
    }

    private func eventChips(_ event: WorldEventRecord) -> [ShellChip] {
        var chips = [
            ShellChip(text: event.scopeLabel, color: ArchiveTheme.Brass.core),
            ShellChip(text: event.statusLabel, color: event.isUnresolved ? ArchiveTheme.violet : ArchiveTheme.teal)
        ]
        for characterID in event.involvedCharacterIDs {
            if let character = world.character(id: characterID) {
                chips.append(ShellChip(text: character.displayName, color: ArchiveTheme.Aether.light))
            }
        }
        return chips
    }

    private func relatedEpisodes(for event: WorldEventRecord) -> [EpisodeRecord] {
        event.relatedEpisodeIDs.compactMap { world.episode(id: $0) }
    }

    // MARK: - 正在进行的命运

    private var activeFatesSection: some View {
        ShellPanel(tint: ArchiveTheme.Brass.luster) {
            ShellSectionHeader(
                eyebrow: "还没有结束",
                title: WorldShellCopy.activeFates,
                note: "可以随时接着走，也可以先去看看别的地方。",
                accent: ArchiveTheme.Brass.luster
            )
            let episodes = world.activeEpisodes
            if episodes.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
                    Text(WorldShellCopy.noActiveFate)
                        .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    Button(WorldShellCopy.startFateFromCards) {
                        model.show(.cards)
                    }
                    .buttonStyle(ShellPrimaryButtonStyle())
                }
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(episodes) { episode in
                        ShellRow(
                            title: episode.title,
                            detail: activeFateLine(for: episode),
                            meta: "\(episode.protagonistName) · \(episode.metaLine)",
                            chips: [
                                ShellChip(text: episode.statusLabel, color: ArchiveTheme.Brass.luster),
                                ShellChip(text: episode.secretSummary, color: ArchiveTheme.Parchment.secondary)
                            ],
                            symbol: "hourglass",
                            action: { model.continueFate(episode) }
                        )
                    }
                }
            }
        }
    }

    private func activeFateLine(for episode: EpisodeRecord) -> String {
        guard let seed = episode.visibleSeed else {
            return episode.metaLine
        }
        return "\(seed.place)：\(seed.anomaly)。"
    }

    // MARK: - 最近活跃人物

    private var activePeopleSection: some View {
        ShellPanel(tint: ArchiveTheme.violet) {
            ShellSectionHeader(
                eyebrow: "谁最近出现过",
                title: WorldShellCopy.activePeople,
                note: "他们各自记得的事情不一样。",
                accent: ArchiveTheme.violet
            )
            let characters = world.recentlyActiveCharacters()
            if characters.isEmpty {
                Text(WorldShellCopy.rosterEmpty)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(characters) { character in
                        ShellRow(
                            title: character.displayName,
                            detail: character.identityLine,
                            meta: "\(WorldShellCopy.lastSeen)：\(character.lastSeenSummary)",
                            chips: [ShellChip(text: character.existenceKind.label, color: ArchiveTheme.violet)],
                            symbol: "person",
                            action: { openCharacter(character) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - 未解决事件

    private var unresolvedSection: some View {
        ShellPanel(tint: ArchiveTheme.ice) {
            ShellSectionHeader(
                eyebrow: "悬着的",
                title: WorldShellCopy.unresolvedEvents,
                note: "还没有结论的事会一直留在这里，直到有人把它弄清楚。",
                accent: ArchiveTheme.ice
            )
            let events = world.unresolvedEvents
            if events.isEmpty {
                Text(WorldShellCopy.noUnresolvedEvents)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(events) { event in
                        ShellRow(
                            title: event.title,
                            detail: event.detail,
                            meta: event.metaLine,
                            chips: [ShellChip(text: event.statusLabel, color: ArchiveTheme.ice)],
                            symbol: "questionmark.circle"
                        )
                    }
                }
            }
        }
    }

    // MARK: - 重要地点变化

    private var locationSection: some View {
        ShellPanel(tint: ArchiveTheme.Brass.core) {
            ShellSectionHeader(
                eyebrow: "地方也变了",
                title: WorldShellCopy.locationChanges,
                note: nil,
                accent: ArchiveTheme.Brass.core
            )
            let changes = world.locationChanges
            if changes.isEmpty {
                Text(WorldShellCopy.noLocationChanges)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(changes) { change in
                        ShellRow(
                            title: change.locationLabel,
                            detail: change.changeSummary,
                            meta: changeSource(for: change),
                            symbol: "mappin.and.ellipse"
                        )
                    }
                }
            }
        }
    }

    private func changeSource(for change: WorldLocationChange) -> String? {
        guard let episodeID = change.changedByEpisodeID,
              let episode = world.episode(id: episodeID)
        else {
            return nil
        }
        return "\(WorldShellCopy.changedBy)：\(episode.title)"
    }

    // MARK: - 最近完成的故事

    private var completedStoriesSection: some View {
        ShellPanel(tint: ArchiveTheme.teal) {
            ShellSectionHeader(
                eyebrow: "已经发生过了",
                title: WorldShellCopy.recentStories,
                note: "它们不会因为结束而消失。",
                accent: ArchiveTheme.teal
            )
            let episodes = world.latestCompletedEpisodes()
            if episodes.isEmpty {
                Text(WorldShellCopy.noCompletedStories)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(episodes) { episode in
                        ShellRow(
                            title: episode.title,
                            detail: episode.costSummary,
                            meta: "\(episode.protagonistName) · \(episode.metaLine)",
                            chips: [
                                ShellChip(text: episode.closureLabel ?? EpisodeState.completed.label, color: ArchiveTheme.teal),
                                ShellChip(text: episode.secretSummary, color: ArchiveTheme.Parchment.secondary)
                            ],
                            symbol: "book.closed",
                            action: { openStoryBook(episode) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - 跳转

    private func openCharacter(_ character: CharacterProfile) {
        model.show(.characters)
        model.select(character: character)
    }

    private func openStoryBook(_ episode: EpisodeRecord) {
        model.show(.storyBook)
        model.select(episode: episode)
    }
}
