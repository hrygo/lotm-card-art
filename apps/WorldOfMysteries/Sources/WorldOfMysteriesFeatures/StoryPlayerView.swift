import SwiftUI
import WorldOfMysteriesCore

// MARK: - 1. 动态神秘学音波律动条 (Mystic Audio Equalizer Bars)

public struct MysticWaveformBarView: View {
    let isPlaying: Bool
    let isLoading: Bool

    public init(isPlaying: Bool, isLoading: Bool) {
        self.isPlaying = isPlaying
        self.isLoading = isLoading
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.12)) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: DesignTokens.Space.s3) {
                ForEach(0..<5, id: \.self) { index in
                    let height: CGFloat = calculateHeight(index: index, time: date)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: barColors(index: index),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 2.5, height: height)
                }
            }
            .frame(height: 20, alignment: .bottom)
        }
        .accessibilityHidden(true)
    }

    private func calculateHeight(index: Int, time: TimeInterval) -> CGFloat {
        if isPlaying {
            let offset = Double(index) * 1.35
            let sine = sin(time * 6.5 + offset)
            let normalized = (sine + 1.0) / 2.0 // 0.0 ... 1.0
            return 4 + CGFloat(normalized) * 14
        } else if isLoading {
            let wave = sin(time * 3.5 + Double(index) * 0.8)
            let normalized = (wave + 1.0) / 2.0
            return 4 + CGFloat(normalized) * 8
        } else {
            return 4
        }
    }

    private func barColors(index: Int) -> [Color] {
        if isPlaying {
            return [
                ArchiveTheme.Brass.core,
                ArchiveTheme.Brass.luster,
                ArchiveTheme.Aether.light
            ]
        } else if isLoading {
            return [
                ArchiveTheme.Brass.patina,
                ArchiveTheme.Brass.luster.opacity(0.7)
            ]
        } else {
            return [
                ArchiveTheme.Leather.highlight.opacity(0.4),
                ArchiveTheme.Brass.patina.opacity(0.4)
            ]
        }
    }
}

// MARK: - 2. 英雄主播放按钮 (Hero Play Button)

public struct PlayerHeroPlayButton: View {
    let isPlaying: Bool
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    @State private var isHovered = false

    public init(
        isPlaying: Bool,
        isLoading: Bool,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) {
        self.isPlaying = isPlaying
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                // 外圈以太与鎏金呼吸光晕
                Circle()
                    .fill(
                        isPlaying
                            ? ArchiveTheme.Aether.light.opacity(isHovered ? 0.45 : 0.28)
                            : ArchiveTheme.Brass.gleam.opacity(isHovered ? 0.35 : 0.12)
                    )
                    .frame(width: 52, height: 52)
                    .blur(radius: isPlaying ? 8 : 4)

                // 黄铜外环金边
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: isPlaying
                                ? [ArchiveTheme.Brass.gleam, ArchiveTheme.Aether.light, ArchiveTheme.Brass.luster]
                                : [ArchiveTheme.Brass.luster, ArchiveTheme.Brass.core, ArchiveTheme.Brass.patina],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 2.0 : 1.5
                    )
                    .frame(width: 46, height: 46)

                // 核心黑曜石/暗皮革圆盘
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                isHovered ? ArchiveTheme.Leather.raised : ArchiveTheme.Leather.deep,
                                ArchiveTheme.Leather.void
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 22
                        )
                    )
                    .frame(width: DesignTokens.Size.hitTarget, height: DesignTokens.Size.hitTarget)

                // 播放/暂停/加载图标
                Group {
                    if isLoading {
                        Image(systemName: "waveform")
                            .font(.system(size: DesignTokens.FontSize.s17, weight: .bold))
                            .foregroundStyle(ArchiveTheme.Aether.light)
                    } else if isPlaying {
                        Image(systemName: "pause.fill")
                            .font(.system(size: DesignTokens.FontSize.s17, weight: .bold))
                            .foregroundStyle(ArchiveTheme.Aether.light)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: DesignTokens.FontSize.s17, weight: .bold))
                            .foregroundStyle(ArchiveTheme.Brass.luster)
                            .offset(x: 1.5) // 光学居中
                    }
                }
                .shadow(
                    color: isPlaying ? ArchiveTheme.Aether.light.opacity(0.8) : ArchiveTheme.Brass.gleam.opacity(0.5),
                    radius: 4
                )
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.45)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - 3. 次级步进按钮 (上一章 / 下一章)

public struct PlayerStepButton: View {
    let systemImage: String
    let isEnabled: Bool
    let accessibilityLabel: String
    let action: () -> Void

    @State private var isHovered = false

    public init(
        systemImage: String,
        isEnabled: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        isHovered && isEnabled
                            ? ArchiveTheme.Leather.raised.opacity(0.85)
                            : ArchiveTheme.Leather.deep.opacity(0.65)
                    )
                    .frame(width: 32, height: 32)

                Circle()
                    .stroke(
                        isHovered && isEnabled
                            ? ArchiveTheme.Brass.luster.opacity(0.8)
                            : ArchiveTheme.Borders.brassMuted.opacity(0.6),
                        lineWidth: DesignTokens.Stroke.hairline
                    )
                    .frame(width: 32, height: 32)

                Image(systemName: systemImage)
                    .font(.system(size: DesignTokens.FontSize.s13, weight: .semibold))
                    .foregroundStyle(
                        isEnabled
                            ? (isHovered ? ArchiveTheme.Brass.luster : ArchiveTheme.Parchment.primary)
                            : ArchiveTheme.Parchment.muted
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.38)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - 4. 辅助轻量按钮 (重播 / 停止)

public struct PlayerUtilityButton: View {
    let systemImage: String
    let isEnabled: Bool
    let accessibilityLabel: String
    let action: () -> Void

    @State private var isHovered = false

    public init(
        systemImage: String,
        isEnabled: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.r6, style: .continuous)
                    .fill(
                        isHovered && isEnabled
                            ? ArchiveTheme.Leather.raised.opacity(0.6)
                            : Color.clear
                    )
                    .frame(width: 26, height: 26)

                Image(systemName: systemImage)
                    .font(.system(size: DesignTokens.FontSize.s11, weight: .semibold))
                    .foregroundStyle(
                        isEnabled
                            ? (isHovered ? ArchiveTheme.Brass.luster : ArchiveTheme.Parchment.secondary)
                            : ArchiveTheme.Parchment.muted
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.35)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - 5. 章节卡片条目 (Story Chapter Row)

public struct StoryChapterCardRow: View {
    let chapter: StoryChapter
    let romanIndex: String
    let isSelected: Bool
    let isCurrentPlaying: Bool
    let playbackState: PlaybackState
    let onSelect: () -> Void

    @State private var isHovered = false

    public init(
        chapter: StoryChapter,
        romanIndex: String,
        isSelected: Bool,
        isCurrentPlaying: Bool,
        playbackState: PlaybackState,
        onSelect: @escaping () -> Void
    ) {
        self.chapter = chapter
        self.romanIndex = romanIndex
        self.isSelected = isSelected
        self.isCurrentPlaying = isCurrentPlaying
        self.playbackState = playbackState
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DesignTokens.Space.s10) {
                // 左侧罗马序数徽章
                ZStack {
                    Circle()
                        .fill(
                            isSelected
                                ? ArchiveTheme.Leather.void
                                : ArchiveTheme.Leather.deep.opacity(0.8)
                        )
                        .frame(width: 24, height: 24)

                    Circle()
                        .stroke(
                            isSelected
                                ? ArchiveTheme.Brass.luster
                                : (isHovered ? ArchiveTheme.Brass.core.opacity(0.7) : ArchiveTheme.Borders.subtle),
                            lineWidth: isSelected ? 1.4 : 0.8
                        )
                        .frame(width: 24, height: 24)

                    Text(romanIndex)
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .bold, design: .serif))
                        .foregroundStyle(
                            isSelected
                                ? ArchiveTheme.Brass.luster
                                : ArchiveTheme.Parchment.secondary
                        )
                }

                // 中间章节标题与字数/状态概览
                VStack(alignment: .leading, spacing: DesignTokens.Space.s2) {
                    Text(chapter.title)
                        .font(.system(size: DesignTokens.FontSize.s12, weight: isSelected ? .bold : .medium, design: .serif))
                        .foregroundStyle(
                            isSelected
                                ? ArchiveTheme.Story.paperHighlight
                                : ArchiveTheme.Parchment.primary
                        )
                        .lineLimit(1)

                    HStack(spacing: DesignTokens.Space.s4) {
                        Text("\(chapter.line.text.count) 字")
                            .font(.system(size: DesignTokens.FontSize.s9, weight: .regular))
                            .foregroundStyle(ArchiveTheme.Parchment.muted)

                        Text("·")
                            .font(.system(size: DesignTokens.FontSize.s9, weight: .regular))
                            .foregroundStyle(ArchiveTheme.Parchment.muted)

                        Text(chapter.line.isPlayable ? "已核验" : "待确认")
                            .font(.system(size: DesignTokens.FontSize.s9, weight: .medium))
                            .foregroundStyle(
                                chapter.line.isPlayable
                                    ? ArchiveTheme.Playback.ready.opacity(0.9)
                                    : ArchiveTheme.Playback.preparing
                            )
                    }
                }

                Spacer(minLength: DesignTokens.Space.s4)

                // 右侧状态与动效
                if isCurrentPlaying {
                    // 当前章节正在朗读中：律动三小柱
                    HStack(alignment: .bottom, spacing: DesignTokens.Space.s2) {
                        Capsule()
                            .fill(ArchiveTheme.Aether.light)
                            .frame(width: 2, height: playbackState == .playing ? 10 : 4)
                        Capsule()
                            .fill(ArchiveTheme.Brass.luster)
                            .frame(width: 2, height: playbackState == .playing ? 14 : 4)
                        Capsule()
                            .fill(ArchiveTheme.Aether.light)
                            .frame(width: 2, height: playbackState == .playing ? 8 : 4)
                    }
                    .frame(height: 14)
                } else if chapter.line.isPlayable {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .medium))
                        .foregroundStyle(
                            isSelected
                                ? ArchiveTheme.Brass.luster.opacity(0.85)
                                : ArchiveTheme.Parchment.muted
                        )
                } else {
                    Image(systemName: "lock")
                        .font(.system(size: DesignTokens.FontSize.s9, weight: .medium))
                        .foregroundStyle(ArchiveTheme.Parchment.muted)
                }
            }
            .padding(.horizontal, DesignTokens.Space.s12)
            .padding(.vertical, DesignTokens.Space.s9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.r8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        ArchiveTheme.Brass.luster.opacity(0.16),
                                        ArchiveTheme.Leather.raised.opacity(0.7)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.r8, style: .continuous)
                            .stroke(ArchiveTheme.Brass.luster.opacity(0.45), lineWidth: DesignTokens.Stroke.hairline)
                    } else if isHovered {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.r8, style: .continuous)
                            .fill(ArchiveTheme.Leather.deep.opacity(0.5))
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.r8, style: .continuous)
                            .stroke(ArchiveTheme.Borders.subtle, lineWidth: DesignTokens.Stroke.thin)
                    }
                }
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [ArchiveTheme.Brass.gleam, ArchiveTheme.Brass.core],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2.5, height: 18)
                        .padding(.leading, DesignTokens.Space.s1)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(chapter.title)
        .accessibilityHint(chapter.line.isPlayable ? "选择并准备播放此章节" : "此章节仍在核验中")
    }
}

// MARK: - 6. 左侧故事羊皮纸卷宗卡片 (Story Folio Sheet)

public struct StoryFolioSheet: View {
    let chapter: StoryChapter?
    let isPlayable: Bool
    let isCurrentPlaying: Bool
    let playbackState: PlaybackState

    public init(
        chapter: StoryChapter?,
        isPlayable: Bool,
        isCurrentPlaying: Bool,
        playbackState: PlaybackState
    ) {
        self.chapter = chapter
        self.isPlayable = isPlayable
        self.isCurrentPlaying = isCurrentPlaying
        self.playbackState = playbackState
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s14) {
            // 卷宗顶部标头
            HStack(spacing: DesignTokens.Space.s8) {
                Image(systemName: "scroll.fill")
                    .font(.system(size: DesignTokens.FontSize.s12, weight: .bold))
                    .foregroundStyle(ArchiveTheme.Brass.luster)

                Text(chapter?.title ?? "故事正文")
                    .font(.system(size: DesignTokens.FontSize.s14, weight: .bold, design: .serif))
                    .foregroundStyle(ArchiveTheme.Story.ink)

                Spacer()

                if isCurrentPlaying {
                    HStack(spacing: DesignTokens.Space.s5) {
                        Circle()
                            .fill(ArchiveTheme.Aether.light)
                            .frame(width: 6, height: 6)
                            .shadow(color: ArchiveTheme.Aether.light.opacity(0.7), radius: 3)

                        Text("正在诵读")
                            .font(.system(size: DesignTokens.FontSize.s10, weight: .semibold, design: .rounded))
                            .foregroundStyle(ArchiveTheme.Aether.light)
                    }
                    .padding(.horizontal, DesignTokens.Space.s8)
                    .padding(.vertical, DesignTokens.Space.s3)
                    .background {
                        Capsule()
                            .fill(ArchiveTheme.Leather.void.opacity(0.6))
                        Capsule()
                            .stroke(ArchiveTheme.Aether.light.opacity(0.4), lineWidth: DesignTokens.Stroke.thin)
                    }
                }
            }

            // 卷宗细金分割线
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            ArchiveTheme.Brass.luster.opacity(0.35),
                            ArchiveTheme.Brass.core.opacity(0.15),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // 故事正文内容
            Text(chapter?.line.text ?? "暂未收录故事卷宗。")
                .font(.system(size: DesignTokens.FontSize.s16, weight: .regular, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(ArchiveTheme.Story.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: DesignTokens.Space.s8)

            // 卷宗底部印记
            HStack(spacing: DesignTokens.Space.s6) {
                Image(systemName: "sparkle")
                    .font(.system(size: DesignTokens.FontSize.s9, weight: .bold))
                    .foregroundStyle(ArchiveTheme.Brass.patina)

                Text(
                    isPlayable
                        ? "本卷宗已由 SpeechRail 完成声学核验，可于右侧留声台随心聆听或静默研读。"
                        : "本卷宗正文仍在整理校对中，当前仅提供文字阅览。"
                )
                .font(.system(size: DesignTokens.FontSize.s10, weight: .medium, design: .rounded))
                .foregroundStyle(
                    isPlayable
                        ? ArchiveTheme.Story.inkMuted
                        : ArchiveTheme.Playback.preparing
                )
            }
            .padding(.top, DesignTokens.Space.s4)
        }
        .padding(DesignTokens.Space.s18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                .fill(ArchiveTheme.Story.sheetSurface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                .stroke(
                    isCurrentPlaying
                        ? ArchiveTheme.Brass.luster.opacity(0.6)
                        : ArchiveTheme.Story.edge,
                    lineWidth: DesignTokens.Stroke.hairline
                )
        }
        .shadow(
            color: ArchiveTheme.Story.shadow,
            radius: 12,
            y: 5
        )
    }
}

// MARK: - 7. 右侧秘音留声台 (Story Player Rail)

public struct StoryPlayerRail: View {
    let chapters: [StoryChapter]
    let selectedChapter: StoryChapter?
    let previousPlayableChapter: StoryChapter?
    let nextPlayableChapter: StoryChapter?
    let selectedChapterIsPlayable: Bool
    let selectedChapterIsCurrent: Bool
    let canReplaySelectedChapter: Bool
    let playbackState: PlaybackState
    let onPlayChapter: (StoryChapter) -> Void
    let onSelectChapter: (StoryChapter) -> Void
    let onTogglePlay: () -> Void
    let onReplay: () -> Void
    let onStop: () -> Void
    let onPrevious: () -> Void
    let onNext: () -> Void

    private let romanNumerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

    public init(
        chapters: [StoryChapter],
        selectedChapter: StoryChapter?,
        previousPlayableChapter: StoryChapter?,
        nextPlayableChapter: StoryChapter?,
        selectedChapterIsPlayable: Bool,
        selectedChapterIsCurrent: Bool,
        canReplaySelectedChapter: Bool,
        playbackState: PlaybackState,
        onPlayChapter: @escaping (StoryChapter) -> Void,
        onSelectChapter: @escaping (StoryChapter) -> Void,
        onTogglePlay: @escaping () -> Void,
        onReplay: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.chapters = chapters
        self.selectedChapter = selectedChapter
        self.previousPlayableChapter = previousPlayableChapter
        self.nextPlayableChapter = nextPlayableChapter
        self.selectedChapterIsPlayable = selectedChapterIsPlayable
        self.selectedChapterIsCurrent = selectedChapterIsCurrent
        self.canReplaySelectedChapter = canReplaySelectedChapter
        self.playbackState = playbackState
        self.onPlayChapter = onPlayChapter
        self.onSelectChapter = onSelectChapter
        self.onTogglePlay = onTogglePlay
        self.onReplay = onReplay
        self.onStop = onStop
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    private var isPlaying: Bool {
        selectedChapterIsCurrent && playbackState == .playing
    }

    private var isLoading: Bool {
        selectedChapterIsCurrent && playbackState == .loading
    }

    private var statusPillLabel: String {
        guard selectedChapterIsCurrent else {
            return "留声待命"
        }
        return playbackState.captionStatusLabel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.s14) {
            // 1. 播放器顶部：留声台标头 + 律动波形 + 状态徽标
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: DesignTokens.Space.s2) {
                    HStack(spacing: DesignTokens.Space.s5) {
                        Image(systemName: "headphones")
                            .font(.system(size: DesignTokens.FontSize.s10, weight: .bold))
                            .foregroundStyle(ArchiveTheme.Brass.luster)

                        Text("秘音留声台")
                            .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                            .foregroundStyle(ArchiveTheme.Brass.luster)
                    }

                    Text(selectedChapter?.title ?? "未选择章节")
                        .font(.system(size: DesignTokens.FontSize.s10, weight: .regular))
                        .foregroundStyle(ArchiveTheme.Parchment.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // 动态声波律动
                MysticWaveformBarView(isPlaying: isPlaying, isLoading: isLoading)

                // 状态胶囊药丸
                Text(statusPillLabel)
                    .font(.system(size: DesignTokens.FontSize.s9, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        isPlaying
                            ? ArchiveTheme.Aether.light
                            : (isLoading ? ArchiveTheme.Brass.luster : ArchiveTheme.Parchment.muted)
                    )
                    .padding(.horizontal, DesignTokens.Space.s7)
                    .padding(.vertical, DesignTokens.Space.s3)
                    .background {
                        Capsule()
                            .fill(ArchiveTheme.Leather.deep)
                        Capsule()
                            .stroke(
                                isPlaying
                                    ? ArchiveTheme.Aether.light.opacity(0.4)
                                    : ArchiveTheme.Borders.brassMuted,
                                lineWidth: DesignTokens.Stroke.thin
                            )
                    }
            }

            // 2. 核心播放控制排布 (Transport Controls)
            HStack(spacing: 0) {
                PlayerUtilityButton(
                    systemImage: "arrow.counterclockwise",
                    isEnabled: canReplaySelectedChapter,
                    accessibilityLabel: "从头重播当前章节",
                    action: onReplay
                )

                Spacer(minLength: DesignTokens.Space.s8)

                PlayerStepButton(
                    systemImage: "chevron.left",
                    isEnabled: previousPlayableChapter != nil,
                    accessibilityLabel: "播放上一章节",
                    action: onPrevious
                )

                Spacer(minLength: DesignTokens.Space.s10)

                PlayerHeroPlayButton(
                    isPlaying: isPlaying,
                    isLoading: isLoading,
                    isEnabled: selectedChapterIsPlayable && !isLoading,
                    action: onTogglePlay
                )

                Spacer(minLength: DesignTokens.Space.s10)

                PlayerStepButton(
                    systemImage: "chevron.right",
                    isEnabled: nextPlayableChapter != nil,
                    accessibilityLabel: "播放下一章节",
                    action: onNext
                )

                Spacer(minLength: DesignTokens.Space.s8)

                PlayerUtilityButton(
                    systemImage: "stop.fill",
                    isEnabled: selectedChapterIsCurrent && (playbackState == .playing || playbackState == .paused),
                    accessibilityLabel: "停止当前朗读",
                    action: onStop
                )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Space.s2)

            // 3. 黄铜星芒细分割线
            HStack(spacing: DesignTokens.Space.s6) {
                Rectangle()
                    .fill(ArchiveTheme.Borders.brassMuted.opacity(0.6))
                    .frame(height: 1)

                Image(systemName: "sparkle")
                    .font(.system(size: DesignTokens.FontSize.s8, weight: .light))
                    .foregroundStyle(ArchiveTheme.Brass.core.opacity(0.5))

                Rectangle()
                    .fill(ArchiveTheme.Borders.brassMuted.opacity(0.6))
                    .frame(height: 1)
            }
            .frame(maxWidth: .infinity)

            // 4. 章节列表标头
            HStack {
                Text("卷宗目录")
                    .font(.system(size: DesignTokens.FontSize.s11, weight: .bold, design: .serif))
                    .foregroundStyle(ArchiveTheme.Parchment.primary)

                Spacer()

                Text("\(chapters.count) 篇")
                    .font(.system(size: DesignTokens.FontSize.s10, weight: .medium, design: .rounded))
                    .foregroundStyle(ArchiveTheme.Parchment.muted)
            }
            .frame(maxWidth: .infinity)

            // 5. 章节列表项
            VStack(spacing: DesignTokens.Space.s6) {
                ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                    let isSel = chapter.id == selectedChapter?.id
                    let isCurPlaying = selectedChapterIsCurrent && isSel
                    let roman = index < romanNumerals.count ? romanNumerals[index] : "\(index + 1)"

                    StoryChapterCardRow(
                        chapter: chapter,
                        romanIndex: roman,
                        isSelected: isSel,
                        isCurrentPlaying: isCurPlaying,
                        playbackState: playbackState,
                        onSelect: {
                            onSelectChapter(chapter)
                        }
                    )
                }

                if chapters.isEmpty {
                    Text("暂未收录章节")
                        .font(.system(size: DesignTokens.FontSize.s11, weight: .medium))
                        .foregroundStyle(ArchiveTheme.Playback.preparing)
                        .padding(.vertical, DesignTokens.Space.s8)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, DesignTokens.Space.s18)
        .padding(.vertical, DesignTokens.Space.s16)
        .frame(width: 296)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                .fill(ArchiveTheme.Story.railSurface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.r14, style: .continuous)
                .stroke(ArchiveTheme.Borders.brassMuted, lineWidth: DesignTokens.Stroke.hairline)
        }
    }
}
