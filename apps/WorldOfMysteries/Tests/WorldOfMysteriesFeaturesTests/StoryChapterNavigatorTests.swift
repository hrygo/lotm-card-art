import XCTest
import WorldOfMysteriesCore
@testable import WorldOfMysteriesFeatures

final class StoryChapterNavigatorTests: XCTestCase {
    func testNextSkipsPendingChapterAndSelectsNextPlayableChapter() {
        let chapters = [
            chapter(id: "chapter-01", title: "第一章", text: "第一章已确认", approved: true),
            chapter(id: "chapter-02", title: "第二章", text: "第二章待确认", approved: false),
            chapter(id: "chapter-03", title: "第三章", text: "第三章已确认", approved: true)
        ]
        let navigator = StoryChapterNavigator(
            chapters: chapters,
            selectedChapterID: "chapter-01"
        )

        XCTAssertEqual(navigator.nextPlayableChapter?.id, "chapter-03")
    }

    func testPreviousSkipsPendingChapterAndSelectsPreviousPlayableChapter() {
        let chapters = [
            chapter(id: "chapter-01", title: "第一章", text: "第一章已确认", approved: true),
            chapter(id: "chapter-02", title: "第二章", text: "第二章待确认", approved: false),
            chapter(id: "chapter-03", title: "第三章", text: "第三章已确认", approved: true)
        ]
        let navigator = StoryChapterNavigator(
            chapters: chapters,
            selectedChapterID: "chapter-03"
        )

        XCTAssertEqual(navigator.previousPlayableChapter?.id, "chapter-01")
    }

    func testNavigatorDoesNotMovePastPlayableBoundaries() {
        let chapters = [
            chapter(id: "chapter-01", title: "第一章", text: "第一章已确认", approved: true),
            chapter(id: "chapter-02", title: "第二章", text: "第二章待确认", approved: false)
        ]
        let navigator = StoryChapterNavigator(
            chapters: chapters,
            selectedChapterID: "chapter-01"
        )

        XCTAssertNil(navigator.previousPlayableChapter)
        XCTAssertNil(navigator.nextPlayableChapter)
    }

    private func chapter(
        id: String,
        title: String,
        text: String,
        approved: Bool
    ) -> StoryChapter {
        let digest = "\(id)-v1"
        return StoryChapter(
            id: id,
            title: title,
            line: NarrativeLine(
                id: id,
                kind: .story,
                text: text,
                sourceKind: .original,
                review: approved ? .approved(contentDigest: digest) : .draft,
                contentDigest: digest
            )
        )
    }
}
