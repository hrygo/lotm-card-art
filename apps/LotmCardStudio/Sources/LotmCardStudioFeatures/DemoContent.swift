import LotmCardStudioCore

public enum VisualTheme: String, Hashable, Sendable {
    case amber
    case violet
    case empty
}

public struct AlbumCard: Identifiable, Hashable, Sendable {
    public let identity: CardIdentity
    public let narrative: NarrativePack?
    public let visualTheme: VisualTheme
    public let subtitle: String

    public var id: String {
        identity.cardID
    }

    public init(
        identity: CardIdentity,
        narrative: NarrativePack?,
        visualTheme: VisualTheme,
        subtitle: String
    ) {
        self.identity = identity
        self.narrative = narrative
        self.visualTheme = visualTheme
        self.subtitle = subtitle
    }
}

public enum DemoLibrary {
    public static let cards: [AlbumCard] = [
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.fool.s03.klein-01",
                slotID: "lotm.fool.s03",
                displayName: "小丑",
                sequenceName: "序列 03",
                contentStatus: .confirmed,
                identityKind: .character,
                characterID: "klein",
                identitySliceID: "klein.s03"
            ),
            narrative: NarrativePack(
                cardID: "lotm.fool.s03.klein-01",
                voiceProfileID: "low-lantern",
                lines: [
                    NarrativeLine(
                        id: "greeting-01",
                        kind: .greeting,
                        text: "先别急着相信我。",
                        sourceKind: .original,
                        review: .approved(contentDigest: "greeting-01-v1"),
                        contentDigest: "greeting-01-v1"
                    ),
                    NarrativeLine(
                        id: "catchphrase-01",
                        kind: .catchphrase,
                        text: "笑一笑，事情才有转圜的余地。",
                        sourceKind: .original,
                        review: .approved(contentDigest: "catchphrase-01-v1"),
                        contentDigest: "catchphrase-01-v1"
                    ),
                    NarrativeLine(
                        id: "story-01",
                        kind: .story,
                        text: "他把荒诞留在脸上，让真正的意图从笑声的缝隙里经过。",
                        sourceKind: .interpretation,
                        review: .approved(contentDigest: "story-01-v1"),
                        contentDigest: "story-01-v1"
                    ),
                    NarrativeLine(
                        id: "story-02",
                        kind: .story,
                        text: "这段故事仍在编辑。",
                        sourceKind: .original,
                        review: .draft,
                        contentDigest: "story-02-draft"
                    )
                ],
                chapters: [
                    StoryChapter(
                        id: "chapter-01",
                        title: "第一章 · 笑声的缝隙",
                        line: NarrativeLine(
                            id: "story-01",
                            kind: .story,
                            text: "他把荒诞留在脸上，让真正的意图从笑声的缝隙里经过。",
                            sourceKind: .interpretation,
                            review: .approved(contentDigest: "story-01-v1"),
                            contentDigest: "story-01-v1"
                        )
                    ),
                    StoryChapter(
                        id: "chapter-02",
                        title: "第二章 · 未完成稿",
                        line: NarrativeLine(
                            id: "story-02",
                            kind: .story,
                            text: "这段故事仍在编辑。",
                            sourceKind: .original,
                            review: .draft,
                            contentDigest: "story-02-draft"
                        )
                    )
                ]
            ),
            visualTheme: .amber,
            subtitle: "synthetic fixture · confirmed state"
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.fool.s09.klein-02",
                slotID: "lotm.fool.s09",
                displayName: "占卜家",
                sequenceName: "序列 09",
                contentStatus: .proposed,
                identityKind: .character,
                characterID: "klein",
                identitySliceID: "klein.s09"
            ),
            narrative: NarrativePack(
                cardID: "lotm.fool.s09.klein-02",
                voiceProfileID: "low-lantern",
                lines: [
                    NarrativeLine(
                        id: "greeting-draft",
                        kind: .greeting,
                        text: "候选台词仍在审核。",
                        sourceKind: .original,
                        review: .draft,
                        contentDigest: "greeting-draft-v1"
                    )
                ],
                chapters: []
            ),
            visualTheme: .violet,
            subtitle: "candidate · awaiting review"
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.fool.s00.prototype",
                slotID: "lotm.fool.s00",
                displayName: "未命名身份",
                sequenceName: "序列 00",
                contentStatus: .unfilled,
                identityKind: .archetype,
                characterID: nil,
                identitySliceID: nil
            ),
            narrative: nil,
            visualTheme: .empty,
            subtitle: "wishlist target · no card yet"
        )
    ]
}
