import SwiftUI
import WorldOfMysteriesCore

/// 故事书列表（PRD §3.7）：一本本已经发生过的命运。
struct StoryBookHomeView: View {
    @ObservedObject var model: AlbumViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.s22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
                        Text(WorldShellCopy.storyBook)
                            .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                            .foregroundStyle(ArchiveTheme.Aether.light)
                        Text("发生过的事")
                            .font(.system(size: DesignTokens.FontSize.s32, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ArchiveTheme.Parchment.primary, ArchiveTheme.Brass.gleam],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("每一段命运都会留下一本书；它写的必须是真正发生过的事。")
                            .font(.system(size: DesignTokens.FontSize.s13, design: .serif))
                            .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    }
                    Spacer(minLength: DesignTokens.Space.s20)
                    ShellSampleBadge(status: model.world.dataStatus)
                }

                let episodes = model.visibleEpisodes
                if episodes.isEmpty {
                    ShellEmptyState(
                        symbol: "book.closed",
                        title: model.hasSearchQuery ? "没有找到匹配的命运" : WorldShellCopy.noStoryBookEntries,
                        note: model.hasSearchQuery ? "可以清除搜索后继续浏览。" : "从一张卡牌开启命运之后，它就会出现在这里。"
                    )
                } else {
                    VStack(spacing: DesignTokens.Space.s8) {
                        ForEach(episodes) { episode in
                            ShellRow(
                                title: episode.title,
                                detail: episode.costSummary,
                                meta: "\(episode.protagonistName) · \(episode.metaLine)",
                                chips: storyChips(for: episode),
                                symbol: episode.state == .inProgress ? "hourglass" : "book.closed",
                                action: { model.select(episode: episode) }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Space.s36)
            .padding(.top, DesignTokens.Space.s68)
            .padding(.bottom, DesignTokens.Space.s44)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(ArchiveTheme.ink)
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "搜索命运、主角或地点")
    }

    private func storyChips(for episode: EpisodeRecord) -> [ShellChip] {
        var chips = [
            ShellChip(
                text: episode.statusLabel,
                color: episode.state == .inProgress ? ArchiveTheme.Brass.luster : ArchiveTheme.teal
            )
        ]
        if let closureLabel = episode.closureLabel {
            chips.append(ShellChip(text: closureLabel, color: ArchiveTheme.Aether.light))
        }
        chips.append(ShellChip(text: episode.secretSummary, color: ArchiveTheme.Parchment.secondary))
        return chips
    }
}

/// 命运详情（PRD §3.7）：阅读模式 / 聆听模式 / 命运记录与影响。
struct EpisodeDetailView: View {
    let episode: EpisodeRecord
    @ObservedObject var model: AlbumViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var card: AlbumCard? {
        model.cards.first { $0.id == episode.cardID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.s20) {
                header
                readingSection
                listeningSection
                choiceSection
                secretSection
                relationshipSection
                worldImpactSection
            }
            .padding(.horizontal, DesignTokens.Space.s36)
            .padding(.top, DesignTokens.Space.s68)
            .padding(.bottom, DesignTokens.Space.s44)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(ArchiveTheme.ink)
    }

    // MARK: - 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
                    Text(episode.state == .inProgress ? "还没有结束" : "已经发生过了")
                        .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                    Text(episode.title)
                        .font(.system(size: DesignTokens.FontSize.s32, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ArchiveTheme.Parchment.primary, ArchiveTheme.Brass.gleam],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("\(episode.protagonistName) · \(episode.metaLine)")
                        .font(.system(size: DesignTokens.FontSize.s13, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                }
                Spacer(minLength: DesignTokens.Space.s20)
                VStack(alignment: .trailing, spacing: DesignTokens.Space.s6) {
                    ShellChip(
                        text: episode.statusLabel,
                        color: episode.state == .inProgress ? ArchiveTheme.Brass.luster : ArchiveTheme.teal
                    )
                    if let closureLabel = episode.closureLabel {
                        ShellChip(text: "\(WorldShellCopy.closureKind)：\(closureLabel)", color: ArchiveTheme.Aether.light)
                    }
                    ShellSampleBadge(status: model.world.dataStatus)
                }
            }
            if let note = episode.worldlineNote {
                Text(note)
                    .font(.system(size: DesignTokens.FontSize.s12, weight: .semibold, design: .serif))
                    .foregroundStyle(ArchiveTheme.violet)
            }
        }
    }

    // MARK: - 阅读模式

    private var readingSection: some View {
        ShellPanel(tint: ArchiveTheme.Aether.light) {
            ShellSectionHeader(
                eyebrow: WorldShellCopy.readingMode,
                title: "这段命运记下的段落",
                note: "只呈现已经发生过的段落，不在事后重写一篇差不多的故事。"
            )
            if episode.state == .inProgress {
                Text(WorldShellCopy.inProgressStoryBookNote)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            }
            if let seed = episode.visibleSeed {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
                    ForEach(seed.visibleFields) { field in
                        HStack(alignment: .top, spacing: DesignTokens.Space.s10) {
                            Text(field.label)
                                .font(.system(size: DesignTokens.FontSize.s10, weight: .bold, design: .rounded))
                                .foregroundStyle(ArchiveTheme.Brass.luster)
                                .frame(width: DesignTokens.Size.control, alignment: .leading)
                            Text(field.value)
                                .font(.system(size: DesignTokens.FontSize.s13, design: .serif))
                                .foregroundStyle(ArchiveTheme.Parchment.primary)
                        }
                    }
                }
                .padding(DesignTokens.Space.s14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ArchiveTheme.Leather.deep.opacity(0.45), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r12, style: .continuous))
            }
            // 命运自己的段落优先；只有它还没有留下段落时才回退到卡片叙事，并说明来源。
            let material = EpisodeReadingResolver.resolve(
                episode: episode,
                cardChapters: card?.narrative?.readableChapters ?? []
            )
            if material.source == .cardNarrative {
                Text(WorldShellCopy.readingFromCardNote)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            }
            if material.isEmpty {
                Text(WorldShellCopy.readingHasNoPassages)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s14) {
                    ForEach(material.passages) { passage in
                        VStack(alignment: .leading, spacing: DesignTokens.Space.s7) {
                            Text(passage.title)
                                .font(.system(size: DesignTokens.FontSize.s12, weight: .bold, design: .serif))
                                .foregroundStyle(ArchiveTheme.Brass.gleam)
                            Text(passage.text)
                                .font(.system(size: DesignTokens.FontSize.s16, weight: .medium, design: .serif))
                                .foregroundStyle(ArchiveTheme.Parchment.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(DesignTokens.Space.s16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ArchiveTheme.Story.sheetSurface, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                        .stroke(ArchiveTheme.Story.edge, lineWidth: DesignTokens.Stroke.hairline)
                }
            }
            if !episode.stateNotes.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s6) {
                    ForEach(episode.stateNotes) { note in
                        VStack(alignment: .leading, spacing: DesignTokens.Space.s3) {
                            Text(note.text)
                                .font(.system(size: DesignTokens.FontSize.s13, weight: .semibold, design: .serif))
                                .foregroundStyle(ArchiveTheme.Brass.luster)
                            Text(note.sourceLabel)
                                .font(.system(size: DesignTokens.FontSize.s10, design: .rounded))
                                .foregroundStyle(ArchiveTheme.Parchment.muted)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 聆听模式

    private var listeningSection: some View {
        ShellPanel(tint: ArchiveTheme.Brass.core) {
            ShellSectionHeader(
                eyebrow: WorldShellCopy.listeningMode,
                title: "听起来是什么样",
                note: episode.listeningNote,
                accent: ArchiveTheme.Brass.core
            )
            HStack(spacing: DesignTokens.Space.s10) {
                Button(episode.state == .inProgress ? WorldShellCopy.rewindToFate : "听这段命运") {
                    openPlayer()
                }
                .buttonStyle(ShellPrimaryButtonStyle())

                if let card {
                    Button("打开这张卡") {
                        model.showCard(card)
                    }
                    .buttonStyle(ShellSecondaryButtonStyle())
                }
            }
        }
    }

    private func openPlayer() {
        guard let card else {
            return
        }
        if reduceMotion {
            model.beginFate(for: card)
        } else {
            withAnimation(.easeOut(duration: DesignTokens.MotionDuration.ms200)) {
                model.beginFate(for: card)
            }
        }
    }

    // MARK: - 命运记录

    private var choiceSection: some View {
        ShellPanel(tint: ArchiveTheme.violet) {
            ShellSectionHeader(
                eyebrow: WorldShellCopy.fateRecord,
                title: "你当时给过的建议",
                note: WorldShellCopy.fateRecordNote,
                accent: ArchiveTheme.violet
            )
            if episode.choicePath.isEmpty {
                Text("这段命运还没有走过一次抉择。")
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(episode.choicePath) { choice in
                        ShellRow(
                            title: "第 \(choice.index) 次 · \(choice.action)",
                            detail: "\(choice.outcome)",
                            meta: "\(choice.intent.label) · 代价：\(choice.cost)",
                            symbol: "arrow.turn.down.right"
                        )
                    }
                }
            }
            if let costSummary = episode.costSummary {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s5) {
                    Text(WorldShellCopy.storyCost)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Brass.luster)
                    Text(costSummary)
                        .font(.system(size: DesignTokens.FontSize.s13, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - 秘密

    private var secretSection: some View {
        ShellPanel(tint: ArchiveTheme.ice) {
            ShellSectionHeader(
                eyebrow: "秘密",
                title: episode.secretSummary,
                note: "没有弄明白的事不会在这里给出答案。",
                accent: ArchiveTheme.ice
            )
            VStack(spacing: DesignTokens.Space.s8) {
                ForEach(episode.secrets) { secret in
                    ShellRow(
                        title: secret.label,
                        detail: secret.displayText,
                        meta: nil,
                        chips: [
                            ShellChip(
                                text: secret.state.label,
                                color: secret.state == .hidden ? ArchiveTheme.Parchment.muted : ArchiveTheme.ice
                            )
                        ],
                        symbol: secret.state == .hidden ? "questionmark.circle" : "key"
                    )
                }
            }
        }
    }

    // MARK: - 关系变化

    private var relationshipSection: some View {
        ShellPanel(tint: ArchiveTheme.violet) {
            ShellSectionHeader(
                eyebrow: WorldShellCopy.relationshipChanges,
                title: WorldShellCopy.keyPeople,
                note: nil,
                accent: ArchiveTheme.violet
            )
            if episode.relationshipChanges.isEmpty {
                Text("这段命运没有改变谁和谁之间的关系。")
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(episode.relationshipChanges) { change in
                        ShellRow(
                            title: change.counterpartName,
                            detail: change.summary,
                            meta: change.axis.label,
                            symbol: "person.2"
                        )
                    }
                }
            }
        }
    }

    // MARK: - 世界影响

    private var worldImpactSection: some View {
        ShellPanel(tint: ArchiveTheme.teal) {
            ShellSectionHeader(
                eyebrow: WorldShellCopy.worldImpact,
                title: "这件事留在世界上的部分",
                note: "只有真正写进世界的改变才会出现在这里。",
                accent: ArchiveTheme.teal
            )
            let events = model.world.events(forEpisodeID: episode.id)
            if events.isEmpty {
                Text(WorldShellCopy.noWorldImpact)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(events) { event in
                        ShellRow(
                            title: event.title,
                            detail: event.detail,
                            meta: event.metaLine,
                            chips: [
                                ShellChip(text: event.scopeLabel, color: ArchiveTheme.Brass.core),
                                ShellChip(text: event.statusLabel, color: event.isUnresolved ? ArchiveTheme.violet : ArchiveTheme.teal)
                            ],
                            symbol: "globe.europe.africa"
                        )
                    }
                }
            }
        }
    }
}
