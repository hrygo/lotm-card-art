import WorldOfMysteriesCore

enum CelestialWorthyNarrative {
    private static let greeting = NarrativeLine(
        id: "cw-greeting-01",
        kind: .greeting,
        text: "欢迎来到源堡。这里保存着许多尚未被释放的名字；你的，也许只是其中之一。",
        sourceKind: .original,
        review: .approved(contentDigest: "6a75b05403d8105863b88acbd3a41d7b5d06f260228c04a0a8254faf15e85076"),
        contentDigest: "6a75b05403d8105863b88acbd3a41d7b5d06f260228c04a0a8254faf15e85076",
        audioResourceName: "celestial-worthy-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "cw-catchphrase-01",
        kind: .catchphrase,
        text: "命运也只是幕后的道具。",
        sourceKind: .original,
        review: .approved(contentDigest: "fe36e429b0ead1343dd12753bcbbeb0a9cb4af2f9201cd1038b85493acb7b049"),
        contentDigest: "fe36e429b0ead1343dd12753bcbbeb0a9cb4af2f9201cd1038b85493acb7b049",
        audioResourceName: "celestial-worthy-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "cw-catchphrase-02",
        kind: .catchphrase,
        text: "我从不催促；布局会替我等到落子的那一刻。",
        sourceKind: .original,
        review: .approved(contentDigest: "5966d796d0db5e1bb2a70a0d53c17633a70d88330685f1529f6caef88b27c9ca"),
        contentDigest: "5966d796d0db5e1bb2a70a0d53c17633a70d88330685f1529f6caef88b27c9ca",
        audioResourceName: "celestial-worthy-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "cw-story-01",
        kind: .story,
        text: "很久以前，祂就知道死亡未必意味着结束。于是祂把人封进茧里，把释放的条件拆进历史，把源堡留成一座等待某个时代到来的宫殿；每一个被保留下来的灵魂，都是计划中的一笔。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "82d86e987799d5ee2c9a834883ff0d6438ae85691cdcdd74b6f8152cb87fa3e1"),
        contentDigest: "82d86e987799d5ee2c9a834883ff0d6438ae85691cdcdd74b6f8152cb87fa3e1",
        audioResourceName: "celestial-worthy-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "cw-story-02",
        kind: .story,
        text: "祂的尊名、仪式与象征从旧时代流入不同的文明，却没有留下一个能被简单理解的完整教义。有人把祂当成古老的神明，也有人在无意中触碰了通往源堡的入口；祂不必一直现身，只需要让人们在错误的时间说出正确的名字。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "0c878a368454dbafa6750dec94d09153a8d479ef41a043bef91773d507ca307f"),
        contentDigest: "0c878a368454dbafa6750dec94d09153a8d479ef41a043bef91773d507ca307f",
        audioResourceName: "celestial-worthy-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "cw-story-03",
        kind: .story,
        text: "当克莱恩晋升为愚者，多方力量同时阻止祂彻底苏醒；在阿蒙的逼迫下，克莱恩又不得不主动释放一部分高位意志来赢下赌局。祂没有赢，也还没有退场——第一部结束时，真正的胜负仍被压缩在「谁能保留自我」这个问题里。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "242b3eb988f450eeaa8a63e8d7890bebfa5398bc79aa1d40c94e5af39599f8a9"),
        contentDigest: "242b3eb988f450eeaa8a63e8d7890bebfa5398bc79aa1d40c94e5af39599f8a9",
        audioResourceName: "celestial-worthy-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.celestial-worthy.primordial-01",
        voiceProfileID: "celestial-worthy",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "cw-chapter-01", title: "第一章 · 把复苏写进源堡", line: storyOne),
            StoryChapter(id: "cw-chapter-02", title: "第二章 · 用名字影响世界", line: storyTwo),
            StoryChapter(id: "cw-chapter-03", title: "第三章 · 没有结束的失败", line: storyThree)
        ]
    )
}
