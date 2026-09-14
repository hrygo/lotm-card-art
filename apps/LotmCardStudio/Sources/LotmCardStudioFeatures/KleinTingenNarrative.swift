import LotmCardStudioCore

enum KleinTingenNarrative {
    private static let greeting = NarrativeLine(
        id: "klein-s09-greeting-01",
        kind: .greeting,
        text: "你好，我是克莱恩·莫雷蒂。若要面对未知，就先把眼前这一步看清。",
        sourceKind: .original,
        review: .approved(contentDigest: "cc822d65efdd867272a41c7cebe1ac2c1f4b4aae097c8d4eb734c03a29c22bcc"),
        contentDigest: "cc822d65efdd867272a41c7cebe1ac2c1f4b4aae097c8d4eb734c03a29c22bcc",
        audioResourceName: "s09-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "klein-s09-catchphrase-01",
        kind: .catchphrase,
        text: "占卜给不了你勇气，但能提醒你，别把鲁莽当成勇气。",
        sourceKind: .original,
        review: .approved(contentDigest: "50959d3a1df7a278e1393a515277d397969c2902b3fd5a97ece89111549a82eb"),
        contentDigest: "50959d3a1df7a278e1393a515277d397969c2902b3fd5a97ece89111549a82eb",
        audioResourceName: "s09-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "klein-s09-catchphrase-02",
        kind: .catchphrase,
        text: "灵摆只会指向答案附近；剩下的路，要靠你自己核对。",
        sourceKind: .original,
        review: .approved(contentDigest: "8ab3d4c16fd1fed9c605e952315ff42a44d14a19f8dd394d7e023f285db85f80"),
        contentDigest: "8ab3d4c16fd1fed9c605e952315ff42a44d14a19f8dd394d7e023f285db85f80",
        audioResourceName: "s09-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "klein-s09-story-01",
        kind: .story,
        text: "醒来后的克莱恩，先接受了一件事：这不是属于他的房间，也不是属于他的名字。门窗、钱袋、笔记和每一处异常，都要重新确认；活下去的第一步，是让混乱重新有了顺序。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "1acad6cff9d10580705dc746deb4c34fafcc3de9ea181b6650a68ce8b9e4448d"),
        contentDigest: "1acad6cff9d10580705dc746deb4c34fafcc3de9ea181b6650a68ce8b9e4448d",
        audioResourceName: "s09-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "klein-s09-story-02",
        kind: .story,
        text: "在廷根，他把占卜从神秘的仪式变成耐心的工作。灵摆给出倾向，书页留下线索，现实负责最后的核验。一个占卜家真正依靠的，不是漂亮的预言，而是知道什么时候仍然不能下结论。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "a1a3baeab1fb0e8b72e0ac97c3e24012ecf28a2f5481b55192aa4b23fa505acb"),
        contentDigest: "a1a3baeab1fb0e8b72e0ac97c3e24012ecf28a2f5481b55192aa4b23fa505acb",
        audioResourceName: "s09-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "klein-s09-story-03",
        kind: .story,
        text: "他越想回到原来的世界，越无法把身边的人当成过客。妹妹的晚餐、同事的玩笑、街角亮起的灯，都让“回家”多了一层含义：在离开之前，先替仍留在这里的人挡住一部分风雨。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "b9472780d049e41bf900208e4491d4a71ddb5b533fe55a4eaefd154905c70f0b"),
        contentDigest: "b9472780d049e41bf900208e4491d4a71ddb5b533fe55a4eaefd154905c70f0b",
        audioResourceName: "s09-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.fool.s09.klein-moretti.tingen-01",
        voiceProfileID: "dylan",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "klein-s09-chapter-01", title: "第一章 · 先把眼前看清", line: storyOne),
            StoryChapter(id: "klein-s09-chapter-02", title: "第二章 · 灵摆之外的核验", line: storyTwo),
            StoryChapter(id: "klein-s09-chapter-03", title: "第三章 · 回家之前", line: storyThree)
        ]
    )
}
