import WorldOfMysteriesCore

enum GodAlmightyNarrative {
    private static let greeting = NarrativeLine(
        id: "ga-greeting-01",
        kind: .greeting,
        text: "这里是混沌海。你所知道的一切，都只是我从这片海中取出的一小部分。",
        sourceKind: .original,
        review: .approved(contentDigest: "0d39fcfdf55a09ab13136d16fe2f37f57e157904e009a620adbe0d3df27ac9fa"),
        contentDigest: "0d39fcfdf55a09ab13136d16fe2f37f57e157904e009a620adbe0d3df27ac9fa",
        audioResourceName: "god-almighty-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "ga-catchphrase-01",
        kind: .catchphrase,
        text: "全知不是看见了什么，而是没有什么不在其中。",
        sourceKind: .original,
        review: .approved(contentDigest: "8f93d00c1098cd82f75e69c1a43ddec472698aff59b58db66f9e51f76e1a3c92"),
        contentDigest: "8f93d00c1098cd82f75e69c1a43ddec472698aff59b58db66f9e51f76e1a3c92",
        audioResourceName: "god-almighty-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "ga-catchphrase-02",
        kind: .catchphrase,
        text: "我不必创造新的东西；可能性早已在这里。",
        sourceKind: .original,
        review: .approved(contentDigest: "412ffa3f038d322b36a77ecfc64861bfb45bb383650c46d7fead6dd6ff666c1e"),
        contentDigest: "412ffa3f038d322b36a77ecfc64861bfb45bb383650c46d7fead6dd6ff666c1e",
        audioResourceName: "god-almighty-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "ga-story-01",
        kind: .story,
        text: "在一切尚未被命名之前，祂已经看见了它们。祂不必走进海里，海本身就是祂的一部分：所有颜色、所有秘密、所有尚未发生的可能性，都在那片黑色的表面下互相翻涌。祂的创造不是从无到有，而是从这无限的可能性中取出一部分，让它们成为可以被看见、被谈论、被记住的东西。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "2212ec31d6a09d52f36a845c19232ee7e4ec7c2c32ffb38e668696f8cc48f391"),
        contentDigest: "2212ec31d6a09d52f36a845c19232ee7e4ec7c2c32ffb38e668696f8cc48f391",
        audioResourceName: "god-almighty-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "ga-story-02",
        kind: .story,
        text: "祂不注视，因为注视意味着还有看不见的地方；祂不出手，因为出手意味着还有做不到的事。祂所表达的全知与全能，更像是世界本身在按规则运行：知道与做到早已发生，只是没有留下一个可以被称为「瞬间」的时刻。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "ba6ea9761a1fe5b1e528a78cea43e7ff776bcd475cec042692876e55f3bb9db5"),
        contentDigest: "ba6ea9761a1fe5b1e528a78cea43e7ff776bcd475cec042692876e55f3bb9db5",
        audioResourceName: "god-almighty-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "ga-story-03",
        kind: .story,
        text: "祂是星界的主人。可「主人」并不是一个位置，而是一种关系：星界不需要被管理，只需要有一个足够大的存在，让其中的一切不至于失序。祂存在的方式，就是让星界继续成为星界。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "1c522012aee0cb9e1f8bcb7bdc75c672f0062df332acc19e747338ac8eadbdfb"),
        contentDigest: "1c522012aee0cb9e1f8bcb7bdc75c672f0062df332acc19e747338ac8eadbdfb",
        audioResourceName: "god-almighty-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.god-almighty.primordial-01",
        voiceProfileID: "god-almighty",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "ga-chapter-01", title: "第一章 · 站在混沌海之上", line: storyOne),
            StoryChapter(id: "ga-chapter-02", title: "第二章 · 全知与全能不是动作", line: storyTwo),
            StoryChapter(id: "ga-chapter-03", title: "第三章 · 星界的主人", line: storyThree)
        ]
    )
}
