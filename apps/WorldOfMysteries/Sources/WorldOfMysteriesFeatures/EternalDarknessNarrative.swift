import WorldOfMysteriesCore

enum EternalDarknessNarrative {
    private static let greeting = NarrativeLine(
        id: "eternal-darkness-greeting-01",
        kind: .greeting,
        text: "这里是永暗之河的尽头。所有的光都会熄灭；你不必害怕，你只是回到熄灭之前的地方。",
        sourceKind: .original,
        review: .approved(contentDigest: "657cbe60e0552b3dc672a9c53b06575f2f26d71610411d09fcc4f116a13fd85b"),
        contentDigest: "657cbe60e0552b3dc672a9c53b06575f2f26d71610411d09fcc4f116a13fd85b",
        audioResourceName: "eternal-darkness-greeting-v1"
    )

    private static let catchphraseOne = NarrativeLine(
        id: "eternal-darkness-catchphrase-01",
        kind: .catchphrase,
        text: "黑暗不是光的缺席，而是所有光的归处。",
        sourceKind: .original,
        review: .approved(contentDigest: "d0c1b785dc0b50e34a3dbabdff00c14c4a06982acafac8c97413945233430426"),
        contentDigest: "d0c1b785dc0b50e34a3dbabdff00c14c4a06982acafac8c97413945233430426",
        audioResourceName: "eternal-darkness-catchphrase-01-v1"
    )

    private static let catchphraseTwo = NarrativeLine(
        id: "eternal-darkness-catchphrase-02",
        kind: .catchphrase,
        text: "终点不是消失，是万物重新对齐的那一刻。",
        sourceKind: .original,
        review: .approved(contentDigest: "1470c4a34ab37706e1a70f76b2e8651a8431d0dadf0b9e8e4a57ca429d845f18"),
        contentDigest: "1470c4a34ab37706e1a70f76b2e8651a8431d0dadf0b9e8e4a57ca429d845f18",
        audioResourceName: "eternal-darkness-catchphrase-02-v1"
    )

    private static let storyOne = NarrativeLine(
        id: "eternal-darkness-story-01",
        kind: .story,
        text: "永暗之河是三份源质中流向终点的那一份。祂不制造死亡，祂只是收纳一切终将抵达那里的东西：不眠者的夜、收尸人的静默、还有战士放下武器之后的那一段沉默。黑暗、死神、黄昏巨人——三条途径长在同一个方向上，像三条河汇入同一片海。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "7f6c2dbfdc4404fbd92b7d6cb25d0ad6d50d2e0b00876761e107d48676a716ce"),
        contentDigest: "7f6c2dbfdc4404fbd92b7d6cb25d0ad6d50d2e0b00876761e107d48676a716ce",
        audioResourceName: "eternal-darkness-story-01-v1"
    )

    private static let storyTwo = NarrativeLine(
        id: "eternal-darkness-story-02",
        kind: .story,
        text: "祂单独的时候，只是永恒之暗，不是终结本身。宇宙里还隐含着一个第四支柱，对应永暗之河与灾祸之城两份源质——可祂至今没有成为那个东西，因为两份源质几乎不可能被同一位存在同时容纳。所以祂守着终点的一半，等着永远不会来的另一半。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "0abf9000caf70b3a3a2e49223e95dfbc61f6a2192f7d2cbdc39cc6099aa5ec35"),
        contentDigest: "0abf9000caf70b3a3a2e49223e95dfbc61f6a2192f7d2cbdc39cc6099aa5ec35",
        audioResourceName: "eternal-darkness-story-02-v1"
    )

    private static let storyThree = NarrativeLine(
        id: "eternal-darkness-story-03",
        kind: .story,
        text: "如果真的有人同时容纳了那两份源质，摆在祂面前的只有三条路：进入沉眠，被动分裂，或者让包括祂自己在内的整个宇宙消亡、重新开始。三条路里没有一条通向「更好」。这就是为什么终点一直停在终点上。",
        sourceKind: .interpretation,
        review: .approved(contentDigest: "899484d310d7dec48ce5fd0f35259b639c44206ae485efc6828ec2edfeee1a02"),
        contentDigest: "899484d310d7dec48ce5fd0f35259b639c44206ae485efc6828ec2edfeee1a02",
        audioResourceName: "eternal-darkness-story-03-v1"
    )

    static let pack = NarrativePack(
        cardID: "lotm.eternal-darkness.primordial-01",
        voiceProfileID: "eternal-darkness",
        lines: [greeting, catchphraseOne, catchphraseTwo, storyOne, storyTwo, storyThree],
        chapters: [
            StoryChapter(id: "eternal-darkness-chapter-01", title: "第一章 · 万物奇点", line: storyOne),
            StoryChapter(id: "eternal-darkness-chapter-02", title: "第二章 · 祂还不是第四支柱", line: storyTwo),
            StoryChapter(id: "eternal-darkness-chapter-03", title: "第三章 · 沉眠、分裂，或者重来", line: storyThree)
        ]
    )
}
