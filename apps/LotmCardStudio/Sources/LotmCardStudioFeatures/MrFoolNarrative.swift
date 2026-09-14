import LotmCardStudioCore

enum MrFoolNarrative {
    private static let greeting = NarrativeLine(
        id: "mr-fool-s00-greeting-01",
        kind: .greeting,
        text: "晚上好。这里是灰雾之上；你可以称我为愚者，但答案最好先留在心里。",
        sourceKind: .original,
        review: .approved(contentDigest: "a2ee328cde0d646aea632d592df3e26e66c1824136ffed0c44b1e7ff395ea820"),
        contentDigest: "a2ee328cde0d646aea632d592df3e26e66c1824136ffed0c44b1e7ff395ea820",
        audioResourceName: "s00-greeting-v2"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "mr-fool-s00-catchphrase-01",
        kind: .catchphrase,
        text: "名字可以借来，面具可以更换，真正留下的，是你在无人注视时做出的选择。",
        sourceKind: .original,
        review: .approved(contentDigest: "20db143ca4f4960b0636b7693a00f086eae89735db75af50cd62d19eae20192d"),
        contentDigest: "20db143ca4f4960b0636b7693a00f086eae89735db75af50cd62d19eae20192d",
        audioResourceName: "s00-catchphrase-01-v2"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "mr-fool-s00-catchphrase-02",
        kind: .catchphrase,
        text: "命运偶尔可以被愚弄；代价却不会因此消失，只会换一种方式回来。",
        sourceKind: .original,
        review: .approved(contentDigest: "a358e17e36aa0909e0bf6b881368922b2a602d91264aabed844ece3d93814f2a"),
        contentDigest: "a358e17e36aa0909e0bf6b881368922b2a602d91264aabed844ece3d93814f2a",
        audioResourceName: "s00-catchphrase-02-v2"
    )

    private static let storyOne = NarrativeLine(
        id: "mr-fool-s00-story-01",
        kind: .story,
        text: "周明瑞醒来时，先面对的不是神明，而是一间陌生的房间、一把不属于他的左轮和一个必须接手的名字。他没有急着寻找宏大的答案，只先确认门窗、钱袋与今晚能否平安度过。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "beba5eb3152ee160319891d665e78b16b99e9fbf35edf8913ee0433ff6e6b583"),
        contentDigest: "beba5eb3152ee160319891d665e78b16b99e9fbf35edf8913ee0433ff6e6b583",
        audioResourceName: "s00-story-01-v2"
    )

    private static let storyTwo = NarrativeLine(
        id: "mr-fool-s00-story-02",
        kind: .story,
        text: "灰雾之上的长桌起初只是一场交换：情报换取帮助，秘密换取希望。可当塔罗会的成员把真正的愿望交到他面前，愚者先生便不能只做一个遥远的称呼；每一次回应，都意味着愿意承担一部分后果。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "880495ff7924ca0d95c9a3364dfc0888a6770d416b60a6600a168cc5350f96cd"),
        contentDigest: "880495ff7924ca0d95c9a3364dfc0888a6770d416b60a6600a168cc5350f96cd",
        audioResourceName: "s00-story-02-v2"
    )

    private static let storyThree = NarrativeLine(
        id: "mr-fool-s00-story-03",
        kind: .story,
        text: "走到序列零以后，时间、历史与命运都可以出现被重新安排的缝隙，可权柄没有抹去疲惫与牵挂。克莱恩把许多身份留在身上，也把清醒留给仍在行走的人；在长久沉睡之前，他仍然选择替别人挡下那场风暴。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "f2e4f94973c3337a1ca02702437febd4cfc34c57f5bb1c058c344db3ba5d8b5c"),
        contentDigest: "f2e4f94973c3337a1ca02702437febd4cfc34c57f5bb1c058c344db3ba5d8b5c",
        audioResourceName: "s00-story-03-v2"
    )

    static let pack = NarrativePack(
        cardID: "lotm.fool.s00.klein-moretti.mr-fool-01",
        voiceProfileID: "uncle_fu",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "mr-fool-s00-chapter-01", title: "第一章 · 陌生名字", line: storyOne),
            StoryChapter(id: "mr-fool-s00-chapter-02", title: "第二章 · 灰雾之上的长桌", line: storyTwo),
            StoryChapter(id: "mr-fool-s00-chapter-03", title: "第三章 · 风暴与沉睡", line: storyThree)
        ]
    )
}
