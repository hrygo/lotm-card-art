import XCTest
@testable import LotmCardStudioCore

final class NarrativeApprovalTests: XCTestCase {
    func testDraftNarrativeCannotBePlayed() {
        let line = NarrativeLine(
            id: "greeting-01",
            kind: .greeting,
            text: "我在这里。",
            sourceKind: .original,
            review: .draft,
            contentDigest: "digest-01"
        )

        XCTAssertFalse(line.isPlayable)
    }

    func testApprovedNarrativeRequiresMatchingReviewDigest() {
        let approved = NarrativeLine(
            id: "greeting-01",
            kind: .greeting,
            text: "我在这里。",
            sourceKind: .original,
            review: .approved(contentDigest: "digest-01"),
            contentDigest: "digest-01"
        )
        let stale = NarrativeLine(
            id: "greeting-02",
            kind: .greeting,
            text: "文本已被修改。",
            sourceKind: .original,
            review: .approved(contentDigest: "digest-old"),
            contentDigest: "digest-new"
        )

        XCTAssertTrue(approved.isPlayable)
        XCTAssertFalse(stale.isPlayable)
    }

    func testNarrativePackKeepsDraftTranscriptButOnlyExposesApprovedPlayback() {
        let approved = NarrativeLine(
            id: "story-01",
            kind: .story,
            text: "他把荒诞留在脸上。",
            sourceKind: .interpretation,
            review: .approved(contentDigest: "story-digest"),
            contentDigest: "story-digest"
        )
        let draft = NarrativeLine(
            id: "story-02",
            kind: .story,
            text: "这段仍在编辑。",
            sourceKind: .original,
            review: .draft,
            contentDigest: "draft-digest"
        )
        let pack = NarrativePack(
            cardID: "lotm.fool.s03.klein-01",
            voiceProfileID: "low-lantern",
            lines: [approved, draft],
            chapters: [
                StoryChapter(id: "chapter-01", title: "第一章", line: approved),
                StoryChapter(id: "chapter-02", title: "草稿章节", line: draft)
            ]
        )

        XCTAssertEqual(pack.lines.count, 2)
        XCTAssertEqual(pack.playableLines.map { $0.id }, ["story-01"])
        XCTAssertEqual(pack.playableChapters.map { $0.id }, ["chapter-01"])
    }
}
