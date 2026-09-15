import CoreGraphics
import XCTest
@testable import WorldOfMysteriesFeatures

/// 卡图档位解析与缓存行为的回归测试。
///
/// 这一组测试守两件事：**每个档位只读它自己那一份打包成片，运行时不做任何缩放**
/// （档位尺寸由打包侧的 `APP_IMAGE_TIERS` 与 `tests/test_app_image_staging.py` 守），
/// 以及**每张卡每档只解一次**（解码曾经在帧提交的主线程上反复发生，是卡顿来源）。
@MainActor
final class ArtworkStoreTests: XCTestCase {
    // MARK: - 档位

    func testEachVariantReadsItsOwnStagedFile() {
        XCTAssertEqual(ArtworkVariant.tile.fileName(for: "fool-s09"), "fool-s09-tile")
        XCTAssertEqual(ArtworkVariant.hero.fileName(for: "fool-s09"), "fool-s09-hero")
    }

    func testVariantsNeverResolveToTheSameFile() {
        let resource = "celestial-worthy-card-v1-v001"
        XCTAssertNotEqual(
            ArtworkVariant.tile.fileName(for: resource),
            ArtworkVariant.hero.fileName(for: resource),
            "网格与详情必须各读自己那一档；解析成同一个文件会让网格白白吃下详情档的成本"
        )
    }

    // MARK: - 缓存

    func testImageDecodesOnceAndThenServesTheSameInstanceFromCache() async {
        let log = DecodeLog()
        let store = ArtworkStore(decode: log.decoder())

        let first = await store.image("fool-s09", .hero)
        let second = await store.image("fool-s09", .hero)

        XCTAssertNotNil(first)
        XCTAssertTrue(first === second, "第二次取图应命中缓存，而不是再解一张")
        XCTAssertEqual(log.count, 1)
        XCTAssertEqual(log.recorded, ["fool-s09#hero"])
    }

    func testVariantsAreCachedSeparately() async {
        let log = DecodeLog()
        let store = ArtworkStore(decode: log.decoder())

        _ = await store.image("fool-s09", .tile)
        _ = await store.image("fool-s09", .hero)
        _ = await store.image("fool-s09", .tile)
        _ = await store.image("fool-s09", .hero)

        XCTAssertEqual(log.count, 2, "同一张卡的瓦片档与详情档各解一次，之后都走缓存")
        XCTAssertEqual(Set(log.recorded), ["fool-s09#tile", "fool-s09#hero"])
    }

    func testFailedDecodeIsNotCachedAsAnImage() async {
        let log = DecodeLog(result: nil)
        let store = ArtworkStore(decode: log.decoder())

        let image = await store.image("missing", .hero)
        XCTAssertNil(image)
        XCTAssertNil(store.cached("missing", .hero))
    }

    func testDroppingCachesForcesAFreshDecode() async {
        let log = DecodeLog()
        let store = ArtworkStore(decode: log.decoder())

        _ = await store.image("fool-s09", .tile)
        XCTAssertEqual(log.count, 1)

        store.dropCaches()
        XCTAssertNil(store.cached("fool-s09", .tile), "丢弃缓存后不应再命中")

        _ = await store.image("fool-s09", .tile)
        XCTAssertEqual(log.count, 2, "丢弃后应重新解一次，而不是把空结果留在缓存里")
    }

    func testConcurrentRequestsForTheSameImageShareOneDecode() async {
        let log = DecodeLog(decodeDelay: 0.02)
        let store = ArtworkStore(decode: log.decoder())

        async let first = store.image("fool-s09", .hero)
        async let second = store.image("fool-s09", .hero)
        let (a, b) = await (first, second)

        XCTAssertNotNil(a)
        XCTAssertTrue(a === b)
        XCTAssertEqual(log.count, 1, "同一张图同时在解时，第二次请求应该等同一份结果")
    }

    // MARK: - 预热

    func testPreloadWarmsBothVariantsOnceAndSkipsWorkOnSecondRun() async {
        let log = DecodeLog()
        let store = ArtworkStore(decode: log.decoder())
        let names = ["fool-s09", "fool-s00"]

        store.preload(names)
        let warmed = await waitUntil { store.cached("fool-s00", .hero) != nil }
        XCTAssertTrue(warmed, "预热应在后台把瓦片档与详情档都解好")

        XCTAssertNotNil(store.cached("fool-s09", .tile))
        XCTAssertNotNil(store.cached("fool-s09", .hero))
        XCTAssertNotNil(store.cached("fool-s00", .tile))
        XCTAssertEqual(log.count, names.count * 2)

        store.preload(names)
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(log.count, names.count * 2, "已经预热过的卡图不应重复解码")
    }

    func testPreloadStopsWarmingHeroesBeyondTheLimit() async {
        let log = DecodeLog()
        let store = ArtworkStore(decode: log.decoder())
        let names = (0...ArtworkStore.heroPreloadLimit).map { "card-\($0)" }

        store.preload(names)
        let warmed = await waitUntil { log.count == ArtworkStore.tilePreloadLimit }
        XCTAssertTrue(warmed, "超过详情档预热上限时，仍然要把网格瓦片档解好")
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(
            log.count,
            ArtworkStore.tilePreloadLimit,
            "超过上限后不再预热详情档，避免卡图变多时无限驻留"
        )
        XCTAssertTrue(log.recorded.allSatisfy { $0.hasSuffix("#tile") })
        XCTAssertNil(store.cached(names[0], .hero))
    }

    func testPreloadStopsWarmingTilesBeyondTheLimit() async {
        let log = DecodeLog()
        let store = ArtworkStore(decode: log.decoder())
        let names = (0...(ArtworkStore.tilePreloadLimit + 4)).map { "card-\($0)" }

        store.preload(names)
        let warmed = await waitUntil { log.count >= ArtworkStore.tilePreloadLimit }
        XCTAssertTrue(warmed, "预热应把可视范围内的瓦片档解好")
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(
            log.count,
            ArtworkStore.tilePreloadLimit,
            "超出可视范围的瓦片不预热：解了也会被成本限流淘汰，改为滚动到跟前时按需解码"
        )
        XCTAssertNil(store.cached(names[names.count - 1], .tile))
    }

// MARK: - 工具

    private func waitUntil(
        timeout: Duration = .seconds(2),
        _ condition: () -> Bool
    ) async -> Bool {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return condition()
    }
}

/// 记录解码调用：测试注入它之后，就能断言「解了几次、解了哪一档」，不必真的读 PNG。
private final class DecodeLog: @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [String] = []
    private let result: CGImage?
    private let decodeDelay: TimeInterval

    init(result: CGImage? = CardArtworkFixture.makeImage(), decodeDelay: TimeInterval = 0) {
        self.result = result
        self.decodeDelay = decodeDelay
    }

    var recorded: [String] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    var count: Int {
        recorded.count
    }

    func decoder() -> ArtworkStore.Decode {
        { name, variant in
            if self.decodeDelay > 0 {
                Thread.sleep(forTimeInterval: self.decodeDelay)
            }
            self.lock.lock()
            self.entries.append("\(name)#\(variant)")
            let result = self.result
            self.lock.unlock()
            return result
        }
    }
}

private enum CardArtworkFixture {
    static func makeImage() -> CGImage {
        let context = CGContext(
            data: nil,
            width: 4,
            height: 6,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let image = context?.makeImage() else {
            fatalError("测试用位图上下文创建失败")
        }
        return image
    }
}
