import LotmCardStudioCore

enum MotherGoddessDepravityNarrative {
    private static let greeting = NarrativeLine(
        id: "mgd-greeting-01",
        kind: .greeting,
        text: "这里的一切都还在生长。你也是；只是你还没有意识到，自己是从哪一半里长出来的。",
        sourceKind: .original,
        review: .approved(contentDigest: "7eddfe52508bb007fc18f935988d5f6e9b3222a61c7c678f682a7d6c8e3d874f"),
        contentDigest: "7eddfe52508bb007fc18f935988d5f6e9b3222a61c7c678f682a7d6c8e3d874f",
        audioResourceName: "mother-goddess-depravity-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "mgd-catchphrase-01",
        kind: .catchphrase,
        text: "给予生命，与收回生命，是同一个动作。",
        sourceKind: .original,
        review: .approved(contentDigest: "cc649b623ea802f2ccacc6a9872153e11feddf17d3135fb281a2cad5baccd837"),
        contentDigest: "cc649b623ea802f2ccacc6a9872153e11feddf17d3135fb281a2cad5baccd837",
        audioResourceName: "mother-goddess-depravity-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "mgd-catchphrase-02",
        kind: .catchphrase,
        text: "被撕掉的那一半，也仍然在替我说话。",
        sourceKind: .original,
        review: .approved(contentDigest: "4553f9b71b348d912ca44ab59e212daf86b9e45f0ebf694186180d6307f523d3"),
        contentDigest: "4553f9b71b348d912ca44ab59e212daf86b9e45f0ebf694186180d6307f523d3",
        audioResourceName: "mother-goddess-depravity-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "mgd-story-01",
        kind: .story,
        text: "在最开始，祂并不是缺口。祂拥有完整的母巢，也拥有与之相配的两条途径；后来，最初造物主的苏醒把其中一部分从祂身上撕了下来，落到了一颗名叫地球的星球上。被撕下的那部分自己长成了新的东西，甚至长出了新的意志——而祂留在原处的部分，只能保持着支柱的象征，站在屏障之外。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "1f27d47f6fa13c75d063c3b1098a7043d606bd4a5edbe12543f54af75e10f3cd"),
        contentDigest: "1f27d47f6fa13c75d063c3b1098a7043d606bd4a5edbe12543f54af75e10f3cd",
        audioResourceName: "mother-goddess-depravity-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "mgd-story-02",
        kind: .story,
        text: "祂被称作母亲，也被称作邪恶之始。这两件事在祂身上从来不是矛盾：给予生命，与利用生命、收回生命，是同一个动作的两面。祂的力量被拆成两条路，一条通向现实与孕育，一条通向堕落与原罪——分开之后，两条路都还在替祂说话。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "1fc9ce28f6d45900a604cc3f3efc47b0bdc6454527388f46b5a1bffa78518dd7"),
        contentDigest: "1fc9ce28f6d45900a604cc3f3efc47b0bdc6454527388f46b5a1bffa78518dd7",
        audioResourceName: "mother-goddess-depravity-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "mgd-story-03",
        kind: .story,
        text: "到最后，祂也没有停下。母巢还在地球的某个侧面；只要祂不被拿回，祂就一直带着缺口站着。祂不会死去，但也没有恢复完整——这不是失败，也不是胜利，而是一种被拉长的等待。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "18ed945940ea20d5ecde46e10475eff3cee65cf747833b920b3f79860a3fb13f"),
        contentDigest: "18ed945940ea20d5ecde46e10475eff3cee65cf747833b920b3f79860a3fb13f",
        audioResourceName: "mother-goddess-depravity-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.mother-goddess-depravity.primordial-01",
        voiceProfileID: "mother-goddess-depravity",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "mgd-chapter-01", title: "第一章 · 被撕掉的那一半", line: storyOne),
            StoryChapter(id: "mgd-chapter-02", title: "第二章 · 母性的两面", line: storyTwo),
            StoryChapter(id: "mgd-chapter-03", title: "第三章 · 还没有取回的东西", line: storyThree)
        ]
    )
}
