import WorldOfMysteriesCore

enum KeyOfLightNarrative {
    private static let greeting = NarrativeLine(
        id: "key-of-light-greeting-01",
        kind: .greeting,
        text: "每一次选择，都创造了一个世界。",
        sourceKind: .original,
        review: .approved(contentDigest: "3375f58341893632d51062993ef682d80d250815041feb6f1dae2cb671e41bc2"),
        contentDigest: "3375f58341893632d51062993ef682d80d250815041feb6f1dae2cb671e41bc2",
        audioResourceName: "key-of-light-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "key-of-light-catchphrase-01",
        kind: .catchphrase,
        text: "混乱里才有无限的可能。",
        sourceKind: .original,
        review: .approved(contentDigest: "6fcb580efb6c5803ea2e31fc7abf3906f94e0cf4fc8538bfd5c7e8869d30f600"),
        contentDigest: "6fcb580efb6c5803ea2e31fc7abf3906f94e0cf4fc8538bfd5c7e8869d30f600",
        audioResourceName: "key-of-light-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "key-of-light-catchphrase-02",
        kind: .catchphrase,
        text: "许多条路，同一个轮。",
        sourceKind: .original,
        review: .approved(contentDigest: "a964e18648ff68cad5a6caae5f4d7c395a19c5be9b865ebcfa5ac612f00648dc"),
        contentDigest: "a964e18648ff68cad5a6caae5f4d7c395a19c5be9b865ebcfa5ac612f00648dc",
        audioResourceName: "key-of-light-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "key-of-light-story-01",
        kind: .story,
        text: "祂的名字和祂的源质是同一个词：光之钥。这在九份源质里是唯一的。有人把这当作巧合，有人把它当作命运的玩笑——考虑到祂掌管的东西，后一种说法更贴切。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "853058c833a534bb710c29198f13d3f24226c90c084b21c7351f36488c7ffec6"),
        contentDigest: "853058c833a534bb710c29198f13d3f24226c90c084b21c7351f36488c7ffec6",
        audioResourceName: "key-of-light-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "key-of-light-story-02",
        kind: .story,
        text: "命运之轮是唯一一条通向祂的途径，因为这里只有一份唯一性。概率、运气、意外、混乱——这些词指的是同一件事的不同切面，而那件事有一个人形的答案。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "d87e31dae24723749fc87da3abdd2df4891d10a7042591808b5f34cb6461c981"),
        contentDigest: "d87e31dae24723749fc87da3abdd2df4891d10a7042591808b5f34cb6461c981",
        audioResourceName: "key-of-light-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "key-of-light-story-03",
        kind: .story,
        text: "祂的第二、第三个名字是「无尽的混乱」与「命运化身」。这两句并不矛盾：一条路上有无数个可能的分支，而走到最后会发现，所有的分支都绕在同一个轮子上。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "b7598a91e022aedb37c7ba2bec56d47738215c266f0877a5c90a58d11e941c64"),
        contentDigest: "b7598a91e022aedb37c7ba2bec56d47738215c266f0877a5c90a58d11e941c64",
        audioResourceName: "key-of-light-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.key-of-light.primordial-01",
        voiceProfileID: "key-of-light",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "key-of-light-chapter-01", title: "第一章 · 名字相同", line: storyOne),
            StoryChapter(id: "key-of-light-chapter-02", title: "第二章 · 命运之轮", line: storyTwo),
            StoryChapter(id: "key-of-light-chapter-03", title: "第三章 · 无尽的混乱", line: storyThree)
        ]
    )
}
