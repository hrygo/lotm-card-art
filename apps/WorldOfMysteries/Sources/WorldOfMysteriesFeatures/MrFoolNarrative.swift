import WorldOfMysteriesCore

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
        text: "周明瑞醒来时，先面对的不是神明，而是一间陌生的房间、一把不属于祂的左轮和一个必须接手的名字。祂没有急着寻找宏大的答案，只先确认门窗、钱袋与今晚能否平安度过。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "e5462134f3f206080737ff9d1ad5703298b393bb8ea238d5bd0b7fd7e1bbb97c"),
        contentDigest: "e5462134f3f206080737ff9d1ad5703298b393bb8ea238d5bd0b7fd7e1bbb97c",
        audioResourceName: "s00-story-01-v2"
    )

    private static let storyTwo = NarrativeLine(
        id: "mr-fool-s00-story-02",
        kind: .story,
        text: "灰雾之上的长桌起初只是一场交换：情报换取帮助，秘密换取希望。可当塔罗会的成员把真正的愿望交到祂面前，愚者先生便不能只做一个遥远的称呼；每一次回应，都意味着愿意承担一部分后果。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "ddb2db2d21267b1a958f7118e340c8ac66b334768f4d78102912d63e3f413970"),
        contentDigest: "ddb2db2d21267b1a958f7118e340c8ac66b334768f4d78102912d63e3f413970",
        audioResourceName: "s00-story-02-v2"
    )

    private static let storyThree = NarrativeLine(
        id: "mr-fool-s00-story-03",
        kind: .story,
        text: "走到序列零以后，时间、历史与命运都可以出现被重新安排的缝隙，可权柄没有抹去疲惫与牵挂。克莱恩把许多身份留在身上，也把清醒留给仍在行走的人；在长久沉睡之前，祂仍然选择替别人挡下那场风暴。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "5a87d0d6ec4d4b3765c41da60b6e52ac7200e1af309ecec8484672fd05988817"),
        contentDigest: "5a87d0d6ec4d4b3765c41da60b6e52ac7200e1af309ecec8484672fd05988817",
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
