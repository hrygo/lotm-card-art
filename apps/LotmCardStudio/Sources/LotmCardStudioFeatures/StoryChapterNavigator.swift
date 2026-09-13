import LotmCardStudioCore

struct StoryChapterNavigator: Sendable {
    let chapters: [StoryChapter]
    let selectedChapterID: StoryChapter.ID?

    init(chapters: [StoryChapter], selectedChapterID: StoryChapter.ID?) {
        self.chapters = chapters
        self.selectedChapterID = selectedChapterID
    }

    var selectedChapter: StoryChapter? {
        guard let selectedChapterID else {
            return chapters.first
        }
        return chapters.first { $0.id == selectedChapterID } ?? chapters.first
    }

    var previousPlayableChapter: StoryChapter? {
        adjacentPlayableChapter(step: -1)
    }

    var nextPlayableChapter: StoryChapter? {
        adjacentPlayableChapter(step: 1)
    }

    private func adjacentPlayableChapter(step: Int) -> StoryChapter? {
        guard let selectedChapter,
              let selectedIndex = chapters.firstIndex(where: { $0.id == selectedChapter.id })
        else {
            return step > 0 ? chapters.first(where: { $0.line.isPlayable }) : nil
        }

        var index = selectedIndex + step
        while chapters.indices.contains(index) {
            if chapters[index].line.isPlayable {
                return chapters[index]
            }
            index += step
        }
        return nil
    }
}
