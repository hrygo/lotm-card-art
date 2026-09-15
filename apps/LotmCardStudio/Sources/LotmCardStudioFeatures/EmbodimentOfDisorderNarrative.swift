import LotmCardStudioCore

enum EmbodimentOfDisorderNarrative {
    private static let greeting = NarrativeLine(
        id: "embodiment-of-disorder-greeting-01",
        kind: .greeting,
        text: "秩序给你形状，失序给你生命。两者都是真的。",
        sourceKind: .original,
        review: .approved(contentDigest: "4f3e3c80c2415abeea7e37c00264dc41a04d90195b17547425979f3b3a4f3aa3"),
        contentDigest: "4f3e3c80c2415abeea7e37c00264dc41a04d90195b17547425979f3b3a4f3aa3",
        audioResourceName: "embodiment-of-disorder-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "embodiment-of-disorder-catchphrase-01",
        kind: .catchphrase,
        text: "规则塌陷的地方，自由才开始。",
        sourceKind: .original,
        review: .approved(contentDigest: "cc525bb7f07c911607e55957e355ad70442b36e81227714c0bd4569b52285c72"),
        contentDigest: "cc525bb7f07c911607e55957e355ad70442b36e81227714c0bd4569b52285c72",
        audioResourceName: "embodiment-of-disorder-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "embodiment-of-disorder-catchphrase-02",
        kind: .catchphrase,
        text: "我是秩序的阴影——不是祂的敌人。",
        sourceKind: .original,
        review: .approved(contentDigest: "de081389c9ac73986ef33bb477dd8f9ef6d5820321a7e6c5ae422f4559cbe28f"),
        contentDigest: "de081389c9ac73986ef33bb477dd8f9ef6d5820321a7e6c5ae422f4559cbe28f",
        audioResourceName: "embodiment-of-disorder-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "embodiment-of-disorder-story-01",
        kind: .story,
        text: "黑皇帝与审判者，两条途径长在同一片土地上。一条利用规则、渐渐演变成秩序的暗面；一条代表秩序与规则本身。它们看起来对立，其实共用同一个根。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "c1a836b83ede5f5a8cd79836b37c96dc73e74c47ae1cab847323903529d9dbd5"),
        contentDigest: "c1a836b83ede5f5a8cd79836b37c96dc73e74c47ae1cab847323903529d9dbd5",
        audioResourceName: "embodiment-of-disorder-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "embodiment-of-disorder-story-02",
        kind: .story,
        text: "祂被称作失序者，也被称作秩序的阴影。这两句是同一个尊名的两半：祂并不站在秩序的对立面，祂只是替秩序保管秩序自己没有承认的那一半。审判者负责划线，黑皇帝负责让线弯曲。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "ee5a6e2b841c7578c4e73fb93df5b414c8d330f928e97168a0e297dcd2018a36"),
        contentDigest: "ee5a6e2b841c7578c4e73fb93df5b414c8d330f928e97168a0e297dcd2018a36",
        audioResourceName: "embodiment-of-disorder-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "embodiment-of-disorder-story-03",
        kind: .story,
        text: "在新秩序的裂缝里，会生出新的世界。这就是祂存在的理由：不是一个更坏的秩序，而是「本来还可以是别的样子」这件事，有了一个固定的名字。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "b2ddfb8939c52157ff0456e7734b71a07f32fd6cfb6aae17af4f9ee49069bf7e"),
        contentDigest: "b2ddfb8939c52157ff0456e7734b71a07f32fd6cfb6aae17af4f9ee49069bf7e",
        audioResourceName: "embodiment-of-disorder-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.embodiment-of-disorder.primordial-01",
        voiceProfileID: "embodiment-of-disorder",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "embodiment-of-disorder-chapter-01", title: "第一章 · 失序之国", line: storyOne),
            StoryChapter(id: "embodiment-of-disorder-chapter-02", title: "第二章 · 阴影不是敌人", line: storyTwo),
            StoryChapter(id: "embodiment-of-disorder-chapter-03", title: "第三章 · 万象的另一种可能", line: storyThree)
        ]
    )
}
