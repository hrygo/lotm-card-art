import WorldOfMysteriesCore

enum DestructionCalamityNarrative {
    private static let greeting = NarrativeLine(
        id: "destruction-calamity-greeting-01",
        kind: .greeting,
        text: "战争烧掉世界，灾祸把它重建起来。你以为你在选择，其实你在循环。",
        sourceKind: .original,
        review: .approved(contentDigest: "bd013cf2cf185eb8c93b9f0b130df762ef3030a5303e35bf66c11ce1fec72198"),
        contentDigest: "bd013cf2cf185eb8c93b9f0b130df762ef3030a5303e35bf66c11ce1fec72198",
        audioResourceName: "destruction-calamity-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "destruction-calamity-catchphrase-01",
        kind: .catchphrase,
        text: "灾祸不是意外，灾祸是根源。",
        sourceKind: .original,
        review: .approved(contentDigest: "a5671ec9e1207824315de831e7a1dbeed71afdbfd568fcc49c3abb577a4da2c4"),
        contentDigest: "a5671ec9e1207824315de831e7a1dbeed71afdbfd568fcc49c3abb577a4da2c4",
        audioResourceName: "destruction-calamity-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "destruction-calamity-catchphrase-02",
        kind: .catchphrase,
        text: "一切都会终结，也都会重来。",
        sourceKind: .original,
        review: .approved(contentDigest: "9ccd6b9077c14918149597f3151d73a68d61e0cace7b2e6c120d55dc3961e040"),
        contentDigest: "9ccd6b9077c14918149597f3151d73a68d61e0cace7b2e6c120d55dc3961e040",
        audioResourceName: "destruction-calamity-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "destruction-calamity-story-01",
        kind: .story,
        text: "魔女与红祭司——原初魔女与混沌魔女，还有那些把征服当作本能的人——两条途径最终都汇入同一座城。灾祸之城不是某一场灾难的现场，祂是灾难这件事的产地。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "a9bcb7689e208b71250e5958d88d5db2837326f16a60f40d4091e5adbb7f1542"),
        contentDigest: "a9bcb7689e208b71250e5958d88d5db2837326f16a60f40d4091e5adbb7f1542",
        audioResourceName: "destruction-calamity-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "destruction-calamity-story-02",
        kind: .story,
        text: "祂的第二个名字是根源之祸。这意味着祂不是被召唤来的惩罚，也不是可以被平息的事故：祂是「祸」这个概念第一次成立的地方。战争、瘟疫、崩塌，都只是祂伸出来的手。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "2cd0093ed90be3e4075fd752dd5fba745146813d4650d47cbf6a13700c440d73"),
        contentDigest: "2cd0093ed90be3e4075fd752dd5fba745146813d4650d47cbf6a13700c440d73",
        audioResourceName: "destruction-calamity-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "destruction-calamity-story-03",
        kind: .story,
        text: "灾祸之城与永暗之河合在一起，才是那个隐含的第四支柱。单独放着的时候，祂只是末日的一半：负责把世界拆开，却不负责让世界停下来。另一半在永暗之河那里等着。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "59843dc4cf3cf18caf017d05d3605a1003283fea930d5cec5a00a41337cc8d0d"),
        contentDigest: "59843dc4cf3cf18caf017d05d3605a1003283fea930d5cec5a00a41337cc8d0d",
        audioResourceName: "destruction-calamity-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.destruction-calamity.primordial-01",
        voiceProfileID: "destruction-calamity",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "destruction-calamity-chapter-01", title: "第一章 · 灾祸之城", line: storyOne),
            StoryChapter(id: "destruction-calamity-chapter-02", title: "第二章 · 根源之祸", line: storyTwo),
            StoryChapter(id: "destruction-calamity-chapter-03", title: "第三章 · 与永暗之河成对", line: storyThree)
        ]
    )
}
