import LotmCardStudioCore

enum DemonOfKnowledgeNarrative {
    private static let greeting = NarrativeLine(
        id: "demon-of-knowledge-greeting-01",
        kind: .greeting,
        text: "所有能被知道的东西，都已经存在了。你就是在走近祂。",
        sourceKind: .original,
        review: .approved(contentDigest: "cb5fa6ad72d09fd6035e97c52513b319f4c7037c18ee6f9b833df80770089122"),
        contentDigest: "cb5fa6ad72d09fd6035e97c52513b319f4c7037c18ee6f9b833df80770089122",
        audioResourceName: "demon-of-knowledge-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "demon-of-knowledge-catchphrase-01",
        kind: .catchphrase,
        text: "信息塑造世界。",
        sourceKind: .original,
        review: .approved(contentDigest: "f80e5d2669cc2bab33171f29462e9177abc8e0f30459e9143c7a4bbd3318fe0c"),
        contentDigest: "f80e5d2669cc2bab33171f29462e9177abc8e0f30459e9143c7a4bbd3318fe0c",
        audioResourceName: "demon-of-knowledge-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "demon-of-knowledge-catchphrase-02",
        kind: .catchphrase,
        text: "你知道得越多，祂就越像在回看你。",
        sourceKind: .original,
        review: .approved(contentDigest: "1dafb1dc9fec390f68f135f9c7f73aa5a5a8a3349ce7090be732bd98a5bb5809"),
        contentDigest: "1dafb1dc9fec390f68f135f9c7f73aa5a5a8a3349ce7090be732bd98a5bb5809",
        audioResourceName: "demon-of-knowledge-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "demon-of-knowledge-story-01",
        kind: .story,
        text: "隐者与完美者，两条途径通向同一片荒野。一条向内、向隐秘处走；一条向外、向完备处走。走到尽头会发现，它们量的是同一块地方——所有可被知道的东西构成的疆域。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "c9a3f2feba109d69c2809306a62daa2345943d74e5b81422bbe924f8474ef77e"),
        contentDigest: "c9a3f2feba109d69c2809306a62daa2345943d74e5b81422bbe924f8474ef77e",
        audioResourceName: "demon-of-knowledge-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "demon-of-knowledge-story-02",
        kind: .story,
        text: "祂的第二个名字是疯狂奥秘。这不是修辞：在祂这里，知识从来不是中性的。你理解一样东西的同时，那样东西也开始理解你。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "76e93c041f504cf58b6573bb04d06d0f6d1e1dbf28d7f808926084f58ed8a8bc"),
        contentDigest: "76e93c041f504cf58b6573bb04d06d0f6d1e1dbf28d7f808926084f58ed8a8bc",
        audioResourceName: "demon-of-knowledge-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "demon-of-knowledge-story-03",
        kind: .story,
        text: "向祂走近的人会先改变自己。这不是祂设下的惩罚，而是这条路的形状：看懂一样东西，就必须先变成能看懂祂的那种存在。代价就是路径的一部分。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "309606a7d408d976f84d718b8695c0549f5695defaa7e0fc6882f83f15519de7"),
        contentDigest: "309606a7d408d976f84d718b8695c0549f5695defaa7e0fc6882f83f15519de7",
        audioResourceName: "demon-of-knowledge-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.demon-of-knowledge.primordial-01",
        voiceProfileID: "demon-of-knowledge",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "demon-of-knowledge-chapter-01", title: "第一章 · 知识荒野", line: storyOne),
            StoryChapter(id: "demon-of-knowledge-chapter-02", title: "第二章 · 疯狂奥秘", line: storyTwo),
            StoryChapter(id: "demon-of-knowledge-chapter-03", title: "第三章 · 越近就越像回看", line: storyThree)
        ]
    )
}
