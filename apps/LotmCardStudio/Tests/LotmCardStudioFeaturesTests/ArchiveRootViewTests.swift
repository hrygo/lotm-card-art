import XCTest
@testable import LotmCardStudioFeatures

final class ArchiveRootViewTests: XCTestCase {
    @MainActor
    func testArchiveRootViewCanBeConstructedWithoutSpeechRail() {
        _ = ArchiveRootView(speechClient: nil)
        XCTAssertTrue(true)
    }
}
