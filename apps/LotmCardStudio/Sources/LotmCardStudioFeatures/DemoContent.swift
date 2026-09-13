import LotmCardStudioCore

public enum VisualTheme: String, Hashable, Sendable {
    case amber
    case violet
    case visionary
    case divineFool
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

    public var artworkResourceName: String? {
        switch identity.cardID {
        case "lotm.fool.s00.prototype":
            return "fool-s00-render-v003"
        case "lotm.visionary.s07.audrey-01":
            return "audrey-s07-psychologist-v001"
        default:
            return nil
        }
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
            subtitle: "小丑的笑容下，藏着冷静的判断"
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
            subtitle: "从占卜开始，走近灰雾"
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.fool.s00.prototype",
                slotID: "lotm.fool.s00",
                displayName: "愚者",
                sequenceName: "序列 00 · 真神",
                contentStatus: .proposed,
                identityKind: .archetype,
                characterID: nil,
                identitySliceID: nil
            ),
            narrative: NarrativePack(
                cardID: "lotm.fool.s00.prototype",
                voiceProfileID: "uncle_fu",
                lines: [
                    NarrativeLine(
                        id: "s00-greeting",
                        kind: .greeting,
                        text: "你可以称我为愚者。至于是否相信我，先保留意见——这是我在灰雾之上仍坚持的好习惯。",
                        sourceKind: .original,
                        review: .approved(contentDigest: "s00-greeting-approved-v1"),
                        contentDigest: "s00-greeting-approved-v1",
                        audioResourceName: "s00-greeting-v1"
                    ),
                    NarrativeLine(
                        id: "s00-catchphrase-01",
                        kind: .catchphrase,
                        text: "占卜不是替你做决定；它只是在坏消息到来之前，给你留一点准备时间。",
                        sourceKind: .original,
                        review: .approved(contentDigest: "s00-catchphrase-01-approved-v1"),
                        contentDigest: "s00-catchphrase-01-approved-v1",
                        audioResourceName: "s00-catchphrase-01-v1"
                    ),
                    NarrativeLine(
                        id: "s00-catchphrase-02",
                        kind: .catchphrase,
                        text: "我有很多名字，也戴过很多张脸；摘下面具之后，仍然知道自己是谁，这才是最重要的事。",
                        sourceKind: .original,
                        review: .approved(contentDigest: "s00-catchphrase-02-approved-v1"),
                        contentDigest: "s00-catchphrase-02-approved-v1",
                        audioResourceName: "s00-catchphrase-02-v1"
                    ),
                    NarrativeLine(
                        id: "s00-story-01",
                        kind: .story,
                        text: "周明瑞醒来时，身边只有一把不属于他的左轮、一本写着死亡预言的笔记，以及一副必须立刻接手的人生。他先确认门窗、武器、钱和能不能活过今晚，再去追查克莱恩·莫雷蒂留下的秘密。后来他发现，那个名字并不是一件可以随手穿上的外套：那里有兄妹、有邻居，也有许多还没走到结尾的普通日子。于是，他寻找回家的路，慢慢变成了守住他们活下去的理由。",
                        sourceKind: .interpretation,
                        review: .approved(contentDigest: "s00-story-01-approved-v1"),
                        contentDigest: "s00-story-01-approved-v1",
                        audioResourceName: "s00-story-01-v1"
                    ),
                    NarrativeLine(
                        id: "s00-story-02",
                        kind: .story,
                        text: "他给自己准备过许多名字：夏洛克·莫里亚蒂的谨慎，格尔曼·斯帕罗的冷硬，道恩·唐泰斯的从容。每一张脸都让他更安全，也让他多背上一份责任。灰雾之上的塔罗会起初是一场交换，后来却成了他不能轻易放下的人——当他们把希望递过来，他总会先计算代价，再悄悄把自己放进最危险的位置。",
                        sourceKind: .interpretation,
                        review: .approved(contentDigest: "s00-story-02-approved-v1"),
                        contentDigest: "s00-story-02-approved-v1",
                        audioResourceName: "s00-story-02-v1"
                    ),
                    NarrativeLine(
                        id: "s00-story-03",
                        kind: .story,
                        text: "走到序列0以后，世界开始不再以人的尺度运转：时间可以被愚弄，历史可以被重新接上，神国像一场完整而无边的梦。但权柄没有替他消除疲惫、恐惧和牵挂。面对必须承担的最后一战，他把清醒留给仍在行走的人，把自己交给漫长沉睡——不是因为他失去了人性，而是因为他仍不愿让别人替他承担代价。",
                        sourceKind: .interpretation,
                        review: .approved(contentDigest: "s00-story-03-approved-v1"),
                        contentDigest: "s00-story-03-approved-v1",
                        audioResourceName: "s00-story-03-v1"
                    )
                ],
                chapters: [
                    StoryChapter(
                        id: "chapter-01",
                        title: "第一章 · 帷幕接缝",
                        line: NarrativeLine(
                            id: "s00-story-01",
                            kind: .story,
                            text: "周明瑞醒来时，身边只有一把不属于他的左轮、一本写着死亡预言的笔记，以及一副必须立刻接手的人生。他先确认门窗、武器、钱和能不能活过今晚，再去追查克莱恩·莫雷蒂留下的秘密。后来他发现，那个名字并不是一件可以随手穿上的外套：那里有兄妹、有邻居，也有许多还没走到结尾的普通日子。于是，他寻找回家的路，慢慢变成了守住他们活下去的理由。",
                            sourceKind: .interpretation,
                            review: .approved(contentDigest: "s00-story-01-approved-v1"),
                            contentDigest: "s00-story-01-approved-v1",
                            audioResourceName: "s00-story-01-v1"
                        )
                    ),
                    StoryChapter(
                        id: "chapter-02",
                        title: "第二章 · 被折叠的现在",
                        line: NarrativeLine(
                            id: "s00-story-02",
                            kind: .story,
                            text: "他给自己准备过许多名字：夏洛克·莫里亚蒂的谨慎，格尔曼·斯帕罗的冷硬，道恩·唐泰斯的从容。每一张脸都让他更安全，也让他多背上一份责任。灰雾之上的塔罗会起初是一场交换，后来却成了他不能轻易放下的人——当他们把希望递过来，他总会先计算代价，再悄悄把自己放进最危险的位置。",
                            sourceKind: .interpretation,
                            review: .approved(contentDigest: "s00-story-02-approved-v1"),
                            contentDigest: "s00-story-02-approved-v1",
                            audioResourceName: "s00-story-02-v1"
                        )
                    ),
                    StoryChapter(
                        id: "chapter-03",
                        title: "第三章 · 沉睡之前",
                        line: NarrativeLine(
                            id: "s00-story-03",
                            kind: .story,
                            text: "走到序列0以后，世界开始不再以人的尺度运转：时间可以被愚弄，历史可以被重新接上，神国像一场完整而无边的梦。但权柄没有替他消除疲惫、恐惧和牵挂。面对必须承担的最后一战，他把清醒留给仍在行走的人，把自己交给漫长沉睡——不是因为他失去了人性，而是因为他仍不愿让别人替他承担代价。",
                            sourceKind: .interpretation,
                            review: .approved(contentDigest: "s00-story-03-approved-v1"),
                            contentDigest: "s00-story-03-approved-v1",
                            audioResourceName: "s00-story-03-v1"
                        )
                    )
                ]
            ),
            visualTheme: .divineFool,
            subtitle: "愚者途径的真神"
        ),
        AlbumCard(
            identity: CardIdentity(
                cardID: "lotm.visionary.s07.audrey-01",
                slotID: "lotm.visionary.s07",
                displayName: "正义 · 奥黛丽",
                sequenceName: "序列 07 · 心理医生",
                contentStatus: .confirmed,
                identityKind: .character,
                characterID: "audrey",
                identitySliceID: "audrey.s07.justice"
            ),
            narrative: NarrativePack(
                cardID: "lotm.visionary.s07.audrey-01",
                voiceProfileID: "serena",
                lines: [
                    NarrativeLine(
                        id: "audrey-greeting",
                        kind: .greeting,
                        text: "下午好，愚者先生。请放心，我会先听完，再给出判断。",
                        sourceKind: .original,
                        review: .approved(contentDigest: "audrey-greeting-approved-v1"),
                        contentDigest: "audrey-greeting-approved-v1",
                        audioResourceName: "audrey-greeting-v1"
                    ),
                    NarrativeLine(
                        id: "audrey-catchphrase-01",
                        kind: .catchphrase,
                        text: "情绪不是罪证；但它留下的痕迹，值得被认真看见。",
                        sourceKind: .original,
                        review: .approved(contentDigest: "audrey-catchphrase-01-approved-v1"),
                        contentDigest: "audrey-catchphrase-01-approved-v1",
                        audioResourceName: "audrey-catchphrase-01-v1"
                    ),
                    NarrativeLine(
                        id: "audrey-catchphrase-02",
                        kind: .catchphrase,
                        text: "我可以安抚你，却不能替你决定。",
                        sourceKind: .original,
                        review: .approved(contentDigest: "audrey-catchphrase-02-approved-v1"),
                        contentDigest: "audrey-catchphrase-02-approved-v1",
                        audioResourceName: "audrey-catchphrase-02-v1"
                    ),
                    NarrativeLine(
                        id: "audrey-story-01",
                        kind: .story,
                        text: "奥黛丽是鲁恩贵族家的小姐，也是塔罗会的“正义”。她拥有令人羡慕的教养、财富和笑容，却没有因此对他人的痛苦视而不见。她会记住舞会外那些疲惫的脸，也会认真听苏茜分享那些没人愿意承认的心事。",
                        sourceKind: .interpretation,
                        review: .approved(contentDigest: "audrey-story-01-approved-v1"),
                        contentDigest: "audrey-story-01-approved-v1",
                        audioResourceName: "audrey-story-01-v1"
                    ),
                    NarrativeLine(
                        id: "audrey-story-02",
                        kind: .story,
                        text: "她从观众学会观察，从读心者学会分辨，再以心理医生的身份把看见变成帮助。烛火与纯露让心智的门缝短暂敞开；安抚可以把人从失控边缘拉回，却并不保证成功。奥黛丽因此更加谨慎：心灵不是可以随意翻阅的档案。",
                        sourceKind: .interpretation,
                        review: .approved(contentDigest: "audrey-story-02-approved-v1"),
                        contentDigest: "audrey-story-02-approved-v1",
                        audioResourceName: "audrey-story-02-v1"
                    ),
                    NarrativeLine(
                        id: "audrey-story-03",
                        kind: .story,
                        text: "“正义”不是替所有人做决定。每一次温和的引导前，她都要确认自己没有把善意变成控制；每一次安抚失败后，她也必须承认，有些痛苦不能被一句话抹平。看见他人的脆弱之后，选择不利用它，就是她对正义的回答。",
                        sourceKind: .interpretation,
                        review: .approved(contentDigest: "audrey-story-03-approved-v1"),
                        contentDigest: "audrey-story-03-approved-v1",
                        audioResourceName: "audrey-story-03-v1"
                    )
                ],
                chapters: [
                    StoryChapter(
                        id: "audrey-chapter-01",
                        title: "第一章 · 先听完再判断",
                        line: NarrativeLine(
                            id: "audrey-story-01",
                            kind: .story,
                            text: "奥黛丽是鲁恩贵族家的小姐，也是塔罗会的“正义”。她拥有令人羡慕的教养、财富和笑容，却没有因此对他人的痛苦视而不见。她会记住舞会外那些疲惫的脸，也会认真听苏茜分享那些没人愿意承认的心事。",
                            sourceKind: .interpretation,
                            review: .approved(contentDigest: "audrey-story-01-approved-v1"),
                            contentDigest: "audrey-story-01-approved-v1",
                            audioResourceName: "audrey-story-01-v1"
                        )
                    ),
                    StoryChapter(
                        id: "audrey-chapter-02",
                        title: "第二章 · 心灵的门缝",
                        line: NarrativeLine(
                            id: "audrey-story-02",
                            kind: .story,
                            text: "她从观众学会观察，从读心者学会分辨，再以心理医生的身份把看见变成帮助。烛火与纯露让心智的门缝短暂敞开；安抚可以把人从失控边缘拉回，却并不保证成功。奥黛丽因此更加谨慎：心灵不是可以随意翻阅的档案。",
                            sourceKind: .interpretation,
                            review: .approved(contentDigest: "audrey-story-02-approved-v1"),
                            contentDigest: "audrey-story-02-approved-v1",
                            audioResourceName: "audrey-story-02-v1"
                        )
                    ),
                    StoryChapter(
                        id: "audrey-chapter-03",
                        title: "第三章 · 不替你决定",
                        line: NarrativeLine(
                            id: "audrey-story-03",
                            kind: .story,
                            text: "“正义”不是替所有人做决定。每一次温和的引导前，她都要确认自己没有把善意变成控制；每一次安抚失败后，她也必须承认，有些痛苦不能被一句话抹平。看见他人的脆弱之后，选择不利用它，就是她对正义的回答。",
                            sourceKind: .interpretation,
                            review: .approved(contentDigest: "audrey-story-03-approved-v1"),
                            contentDigest: "audrey-story-03-approved-v1",
                            audioResourceName: "audrey-story-03-v1"
                        )
                    )
                ]
            ),
            visualTheme: .visionary,
            subtitle: "正义的温柔与坚定"
        )
    ]
}
