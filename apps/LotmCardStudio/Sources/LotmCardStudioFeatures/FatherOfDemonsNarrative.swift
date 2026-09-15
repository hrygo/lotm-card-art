import LotmCardStudioCore

enum FatherOfDemonsNarrative {
    private static let greeting = NarrativeLine(
        id: "father-of-demons-greeting-01",
        kind: .greeting,
        text: "你闻到的不是血腥味，是欲望的味道。这里所有的东西都从祂长出来。",
        sourceKind: .original,
        review: .approved(contentDigest: "04ec0e488315ddbafebdac6fa9f592647e92a70f88fc814acc83fe91ce6aa66a"),
        contentDigest: "04ec0e488315ddbafebdac6fa9f592647e92a70f88fc814acc83fe91ce6aa66a",
        audioResourceName: "father-of-demons-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "father-of-demons-catchphrase-01",
        kind: .catchphrase,
        text: "所有欲望终将汇聚，所有形态终将退化。",
        sourceKind: .original,
        review: .approved(contentDigest: "2eba356c0ab44fedcfb05c06bf9fef658659a51f1c65aa53c77b73a2b7c5fa4c"),
        contentDigest: "2eba356c0ab44fedcfb05c06bf9fef658659a51f1c65aa53c77b73a2b7c5fa4c",
        audioResourceName: "father-of-demons-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "father-of-demons-catchphrase-02",
        kind: .catchphrase,
        text: "被诅咒的人和被束缚的神，本来就是同一批。",
        sourceKind: .original,
        review: .approved(contentDigest: "c361550e1f4efb3a708bd380b1733000e22454d9effd8f02b04698082366136b"),
        contentDigest: "c361550e1f4efb3a708bd380b1733000e22454d9effd8f02b04698082366136b",
        audioResourceName: "father-of-demons-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "father-of-demons-story-01",
        kind: .story,
        text: "暗影世界是欲望与诅咒本身的源质。深渊与被缚者两条途径从祂里面长出来，一条向下张开，一条向内收紧——它们不是两种恶，而是同一件事的两种方向。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "9181758ddd2d36e3c9f0fbc0b49119c20583d0faea026b361563761d1d438303"),
        contentDigest: "9181758ddd2d36e3c9f0fbc0b49119c20583d0faea026b361563761d1d438303",
        audioResourceName: "father-of-demons-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "father-of-demons-story-02",
        kind: .story,
        text: "祂并不只是「最大的那个恶魔」。祂的第二个名字是异类之主，第三个是诅咒之源：凡是拒绝保持原样的东西，凡是自愿或被迫改变了自己形态的存在，都在祂的名下。祂不是恶的极限，祂是「偏离」这件事的源头。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "b113e6147429dc1c61460fd687b0f3445d18b5f20f25b51640cb265f36fdc66d"),
        contentDigest: "b113e6147429dc1c61460fd687b0f3445d18b5f20f25b51640cb265f36fdc66d",
        audioResourceName: "father-of-demons-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "father-of-demons-story-03",
        kind: .story,
        text: "承载暗影世界，需要深渊与被缚者两条途径的全部：深渊的唯一性、被缚者的唯一性，再加上污秽君王与神孽这样的非凡特性。当这些东西凑齐，名字就不再是称号，而是你自己。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "80138e6308d6881a7943fe3d0fb101bfcb84203b26a67a19d473049f4f54fb19"),
        contentDigest: "80138e6308d6881a7943fe3d0fb101bfcb84203b26a67a19d473049f4f54fb19",
        audioResourceName: "father-of-demons-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.father-of-demons.primordial-01",
        voiceProfileID: "father-of-demons",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "father-of-demons-chapter-01", title: "第一章 · 暗影世界", line: storyOne),
            StoryChapter(id: "father-of-demons-chapter-02", title: "第二章 · 异类之主", line: storyTwo),
            StoryChapter(id: "father-of-demons-chapter-03", title: "第三章 · 要成为祂，需要什么", line: storyThree)
        ]
    )
}
