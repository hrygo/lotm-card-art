import LotmCardStudioCore

enum KleinTingenNarrative {
    private static let greeting = NarrativeLine(
        id: "klein-s09-greeting-01",
        kind: .greeting,
        text: "你好。我是克莱恩·莫雷蒂。若你愿意，我们可以先从一件最容易验证的小事开始。",
        sourceKind: .original,
        review: .draft,
        contentDigest: "e7ba6fc2ced7f7b15256ca6d8930af98351c951af74eb6cb099ede8f226800fd"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "klein-s09-catchphrase-01",
        kind: .catchphrase,
        text: "占卜不是替你做决定；它只提醒你，哪些地方还没有看清。",
        sourceKind: .original,
        review: .draft,
        contentDigest: "11a2a28335f0e4f919bcacae5aca3b1ca24f77828d5ace7b02fb321370e8377b"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "klein-s09-catchphrase-02",
        kind: .catchphrase,
        text: "先观察，再行动；先确认代价，再谈勇气。",
        sourceKind: .original,
        review: .draft,
        contentDigest: "2665f90a3f8cdbb91ed9757d82dd96c9a571a0278636972c324e4edd608ce1f5"
    )

    private static let storyOne = NarrativeLine(
        id: "klein-s09-story-01",
        kind: .story,
        text: "刚醒来时，他没有急着给这场离奇的人生下结论。陌生的房间、写满预言的笔记、属于另一个人的名字，都需要一件件核对。对廷根的克莱恩来说，活下来不是一句口号，而是从门窗、钱袋和每一个可疑细节开始的秩序。",
        sourceKind: .interpretation,
        review: .draft,
        contentDigest: "4c3928a44bca2fc3fa3a0a75a1163f83d6c78b4f2bfc9dcd653b7b5e1691776a"
    )

    private static let storyTwo = NarrativeLine(
        id: "klein-s09-story-02",
        kind: .story,
        text: "他在灰雾之外寻找答案，也在现实里学习怎样成为一个占卜家：让灵摆指向眼前的目标，让书页、茶杯和安静的观察共同构成判断。占卜并没有替他看见全部未来，反而一次次提醒他，未知仍然藏在视线之外。",
        sourceKind: .interpretation,
        review: .draft,
        contentDigest: "6fc0b65ad74884bd3ae088782cac9505bf1172b31d163595f3aafc5ecf6c84c4"
    )

    private static let storyThree = NarrativeLine(
        id: "klein-s09-story-03",
        kind: .story,
        text: "当危险逐渐逼近，他发现真正难以处理的并不是一件神秘物品，而是名字背后那些具体的人。妹妹、同事、邻居与刚刚建立的信任，让“寻找回家”不再只是个人愿望。克莱恩开始明白，每一次谨慎的选择，也可能是在替别人保留明天。",
        sourceKind: .interpretation,
        review: .draft,
        contentDigest: "6b59f4773a1b0d9dfcf60c00b3310c7667ba0b26b65590c0729fdbe22232e21f"
    )

    static let pack = NarrativePack(
        cardID: "lotm.fool.s09.klein-moretti.tingen-01",
        voiceProfileID: "low-lantern",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "klein-s09-chapter-01", title: "第一章 · 醒来后的核对", line: storyOne),
            StoryChapter(id: "klein-s09-chapter-02", title: "第二章 · 灵摆指向的范围", line: storyTwo),
            StoryChapter(id: "klein-s09-chapter-03", title: "第三章 · 名字背后的人", line: storyThree)
        ]
    )
}
