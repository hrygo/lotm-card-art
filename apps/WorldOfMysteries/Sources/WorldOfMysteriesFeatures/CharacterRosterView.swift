import SwiftUI
import WorldOfMysteriesCore

/// 人物列表（PRD §3.6）：把「人物」当作可从任意角度回访的存在。
struct CharacterRosterView: View {
    @ObservedObject var model: AlbumViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Space.s22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
                        Text(WorldShellCopy.characterList)
                            .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                            .foregroundStyle(ArchiveTheme.Aether.light)
                        Text("这个世界里的人")
                            .font(.system(size: DesignTokens.FontSize.s32, weight: .bold, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ArchiveTheme.Parchment.primary, ArchiveTheme.Brass.gleam],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("同一个人可以有多张身份卡；他们各自只知道自己该知道的事。")
                            .font(.system(size: DesignTokens.FontSize.s13, design: .serif))
                            .foregroundStyle(ArchiveTheme.Parchment.secondary)
                    }
                    Spacer(minLength: DesignTokens.Space.s20)
                    ShellSampleBadge(status: model.world.dataStatus)
                }

                let characters = model.visibleCharacters
                if characters.isEmpty {
                    ShellEmptyState(
                        symbol: "person.crop.circle.badge.questionmark",
                        title: model.hasSearchQuery ? "没有找到匹配的人物" : WorldShellCopy.rosterEmpty,
                        note: model.hasSearchQuery ? "可以清除搜索后继续浏览。" : "人物会随着世界里的经历出现。"
                    )
                } else {
                    VStack(spacing: DesignTokens.Space.s8) {
                        ForEach(characters) { character in
                            ShellRow(
                                title: character.displayName,
                                detail: character.identityLine,
                                meta: "\(WorldShellCopy.lastSeen)：\(character.lastSeenSummary)",
                                chips: [
                                    ShellChip(text: character.existenceKind.label, color: ArchiveTheme.violet),
                                    ShellChip(text: character.cardCountLabel, color: ArchiveTheme.Aether.light)
                                ],
                                symbol: "person",
                                action: { model.select(character: character) }
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
        .searchable(text: $model.searchText, placement: .toolbar, prompt: "搜索人物或途径")
    }
}

/// 人物档案（PRD §3.6）：身份切片 / 本机经历 / 关系 / 知识边界。
struct CharacterProfileView: View {
    let profile: CharacterProfile
    @ObservedObject var model: AlbumViewModel

    var body: some View {
        ScrollView {
            // 四个面板各带一层玻璃：放进同一个容器里一起渲染，避免逐面板采样背景。
            // 容器 spacing 特意小于面板间距（20）：容器 spacing 大于内部布局 spacing 会让
            // 相邻玻璃在静止时就融合成一片，这里要保持四个面板各自独立。
            GlassEffectContainer(spacing: DesignTokens.Space.s8) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s20) {
                    header
                    identitySection
                    experienceSection
                    relationshipSection
                    knowledgeSection
                    if let note = profile.profileNote {
                        Text(note)
                            .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                            .foregroundStyle(ArchiveTheme.Parchment.muted)
                            .fixedSize(horizontal: false, vertical: true)
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s8) {
                    Text(profile.existenceKind.label)
                        .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.violet)
                    Text(profile.displayName)
                        .font(.system(size: DesignTokens.FontSize.s32, weight: .bold, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.primary)
                    Text(profile.identityLine)
                        .font(.system(size: DesignTokens.FontSize.s13, design: .serif))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                }
                Spacer(minLength: DesignTokens.Space.s20)
                VStack(alignment: .trailing, spacing: DesignTokens.Space.s6) {
                    ShellChip(text: profile.cardCountLabel, color: ArchiveTheme.Aether.light)
                    ShellSampleBadge(status: model.world.dataStatus)
                }
            }
            Text("\(WorldShellCopy.lastSeen)：\(profile.lastSeenSummary)")
                .font(.system(size: DesignTokens.FontSize.s11, design: .rounded))
                .foregroundStyle(ArchiveTheme.Parchment.muted)
        }
    }

    private var identitySection: some View {
        ShellPanel(tint: ArchiveTheme.Aether.light) {
            ShellSectionHeader(
                eyebrow: WorldShellCopy.identitySlices,
                title: "\(profile.displayName)的身份",
                note: WorldShellCopy.identitySliceNote
            )
            let cards = model.cards(for: profile)
            if cards.isEmpty {
                Text(WorldShellCopy.noIdentityCards)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(cards) { card in
                        ShellRow(
                            title: card.identity.displayName,
                            detail: ArchiveCopy.sequenceDisplayLabel(for: card.identity.sequenceName, includesRank: true),
                            meta: "\(WorldShellCopy.experienceState)：\(model.experienceLabel(for: card))",
                            chips: [
                                ShellChip(
                                    text: IdentityRoleResolver.role(for: card.identity).label,
                                    color: ArchiveTheme.Brass.core
                                )
                            ],
                            symbol: "rectangle.portrait.on.rectangle.portrait",
                            action: { model.showCard(card) }
                        )
                    }
                }
            }
        }
    }

    private var experienceSection: some View {
        ShellPanel(tint: ArchiveTheme.Brass.luster) {
            ShellSectionHeader(
                eyebrow: WorldShellCopy.characterExperiences,
                title: "这个人经历过什么",
                note: "这里只记录在你的世界里真正发生过的事。",
                accent: ArchiveTheme.Brass.luster
            )
            let episodes = model.world.episodes(forCharacterID: profile.id)
            if episodes.isEmpty {
                Text(WorldShellCopy.noCharacterExperience)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(episodes) { episode in
                        ShellRow(
                            title: episode.title,
                            detail: WorldShellCopy.experienceCostLabel(for: episode),
                            meta: "\(episode.metaLine) · \(WorldShellCopy.episodeStatusNote(for: episode))",
                            chips: [
                                ShellChip(text: episode.statusLabel, color: ArchiveTheme.Brass.luster),
                                ShellChip(text: episode.secretSummary, color: ArchiveTheme.Parchment.secondary)
                            ],
                            symbol: "hourglass",
                            action: {
                                if episode.state == .inProgress {
                                    model.continueFate(episode)
                                } else {
                                    model.show(.storyBook)
                                    model.select(episode: episode)
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    private var relationshipSection: some View {
        ShellPanel(tint: ArchiveTheme.violet) {
            ShellSectionHeader(
                eyebrow: WorldShellCopy.characterRelations,
                title: "这个人和别人的关系",
                note: "原著事实与本机经历分开写，不混在一起。",
                accent: ArchiveTheme.violet
            )
            if profile.relationships.isEmpty {
                Text(WorldShellCopy.noRelations)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(profile.relationships) { relation in
                        ShellRow(
                            title: relation.counterpartName,
                            detail: relation.summary,
                            meta: changedByLine(for: relation),
                            chips: [
                                ShellChip(text: relation.axis.label, color: ArchiveTheme.violet),
                                ShellChip(
                                    text: relation.origin.label,
                                    color: relation.origin == .canon ? ArchiveTheme.Brass.gleam : ArchiveTheme.Aether.light
                                )
                            ],
                            symbol: "person.2"
                        )
                    }
                }
            }
        }
    }

    private func changedByLine(for relation: CharacterRelationshipRecord) -> String? {
        guard let episodeID = relation.changedByEpisodeID,
              let episode = model.world.episode(id: episodeID)
        else {
            return nil
        }
        return "\(WorldShellCopy.changedBy)：\(episode.title)"
    }

    private var knowledgeSection: some View {
        ShellPanel(tint: ArchiveTheme.ice) {
            ShellSectionHeader(
                eyebrow: "知识边界",
                title: WorldShellCopy.knowledgeTitle(for: profile),
                note: WorldShellCopy.characterRelationsNote,
                accent: ArchiveTheme.ice
            )
            if profile.knowledgeFacts.isEmpty {
                Text(WorldShellCopy.noKnowledge)
                    .font(.system(size: DesignTokens.FontSize.s12, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.secondary)
            } else {
                VStack(spacing: DesignTokens.Space.s8) {
                    ForEach(profile.knowledgeFacts) { fact in
                        ShellRow(
                            title: fact.content,
                            detail: nil,
                            meta: nil,
                            chips: [ShellChip(text: fact.scope.label, color: ArchiveTheme.ice)],
                            symbol: "eye"
                        )
                    }
                }
            }
        }
    }
}
