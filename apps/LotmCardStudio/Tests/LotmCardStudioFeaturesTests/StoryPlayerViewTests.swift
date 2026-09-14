import XCTest
import LotmCardStudioCore
@testable import LotmCardStudioFeatures

final class StoryPlayerViewTests: XCTestCase {
    func testPlaybackStateStatusLabelsAndSystemImages() {
        XCTAssertEqual(PlaybackState.idle.captionStatusLabel, "已讲完")
        XCTAssertEqual(PlaybackState.idle.captionSystemImage, "checkmark.circle")

        XCTAssertEqual(PlaybackState.loading.captionStatusLabel, "正在准备声音")
        XCTAssertEqual(PlaybackState.loading.captionSystemImage, "waveform")

        XCTAssertEqual(PlaybackState.playing.captionStatusLabel, "正在讲述")
        XCTAssertEqual(PlaybackState.playing.captionSystemImage, "waveform")

        XCTAssertEqual(PlaybackState.paused.captionStatusLabel, "已暂停")
        XCTAssertEqual(PlaybackState.paused.captionSystemImage, "pause.circle")

        let failedState = PlaybackState.failed("网络错误")
        XCTAssertEqual(failedState.captionStatusLabel, "声音不可用")
        XCTAssertEqual(failedState.captionSystemImage, "exclamationmark.triangle")
    }

    func testStoryChaptersProvidePlayableStatusAndWordCount() {
        let digest = "digest-v1"
        let line = NarrativeLine(
            id: "line-01",
            kind: .story,
            text: "周明瑞醒来时，身边只有一把不属于他的左轮。",
            sourceKind: .original,
            review: .approved(contentDigest: digest),
            contentDigest: digest
        )
        let chapter = StoryChapter(id: "chapter-01", title: "第一章 · 帷幕接缝", line: line)

        XCTAssertTrue(chapter.line.isPlayable)
        XCTAssertEqual(chapter.line.text.count, 21)
        XCTAssertEqual(chapter.title, "第一章 · 帷幕接缝")
    }
}
