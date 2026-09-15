import CoreGraphics
import Dispatch
import Foundation
import ImageIO

/// 网格瓦片成片能覆盖的最大显示宽度。
///
/// 打包侧 `APP_IMAGE_TIERS.tile` 长边 1200 产出 800×1200，2x 屏幕上正好覆盖 400pt。
/// 网格列宽上限取这个值，窗口再宽也不会把瓦片拉过成片像素（研究稿 §3.2：先给瓦片设上限，
/// 再定档）。`tests/test_app_image_staging.py` 会反查这个数字与档位是否仍然自洽。
nonisolated let albumTileMaxDisplayWidth: CGFloat = 400

/// 卡图读哪一档。
///
/// **运行时不做任何图像处理**：每一档都在打包时从 `artifacts/**` 的母版生成好
/// （见 `tools/production.py` 的 `APP_IMAGE_TIERS` 与决策 D23），App 只负责读与画。
/// 实测依据：把 2048×3072 的母版在运行时缩到 800×1200 要 65.8ms，而直接读一张
/// 800×1200 的成片只要 2.7ms；PNG 的「缩略图解码」甚至比全尺寸更慢。
enum ArtworkVariant {
    /// 画册网格瓦片（2x 下不超过约 800px 宽）。
    case tile
    /// 卡牌详情大图与命运生成卡面。
    case hero

    /// 打包时生成的文件名后缀。
    var fileSuffix: String {
        switch self {
        case .tile: return "tile"
        case .hero: return "hero"
        }
    }

    func fileName(for resource: String) -> String {
        "\(resource)-\(fileSuffix)"
    }
}

/// 卡图解码：读到什么就解什么，不放缩。
///
/// `kCGImageSourceShouldCacheImmediately` 必须显式给：Apple 文档说明该键默认 `false`，
/// 「解码与缓存只在你渲染图像时才发生」——也就是在帧提交路径上。给了它，解码就落在
/// 创建这一步，也就是调用方放后台的那一步。
enum ArtworkDecoder {
    nonisolated static func decode(resource name: String, variant: ArtworkVariant) -> CGImage? {
        if let url = Bundle.main.url(
            forResource: variant.fileName(for: name),
            withExtension: "jpg",
            subdirectory: "CardArt"
        ), let image = decodeImage(at: url) {
            return image
        }
        // 只登记了母版（没有衍生档）时仍然可用：代价是那一次要按母版尺寸解码。
        // 正常打包总是同时落两个档，这条路径不该被走到。
        guard let master = Bundle.main.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "CardArt"
        ) else {
            return nil
        }
        return decodeImage(at: master)
    }

    private nonisolated static func decodeImage(at url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(
            url as CFURL,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, [
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }
}

/// 卡图缓存。视图在 `body` 里同步读命中项，未命中时才启动后台解码。
@MainActor
final class ArtworkStore {
    static let shared = ArtworkStore()

    /// 取图实现。默认走 `ArtworkDecoder`；测试注入计数实现即可断言「每张每档只解一次」，
    /// 不需要真的去读 App Bundle 里的 PNG。
    typealias Decode = @Sendable (_ name: String, _ variant: ArtworkVariant) -> CGImage?

    /// 网格瓦片：数量多但每张小，按数量限流。
    private let tiles = NSCache<NSString, CGImage>()
    /// 详情大图：全分辨率，按字节数限流，避免卡片变多后无限驻留。
    private let heroes = NSCache<NSString, CGImage>()
    /// 预热详情图的张数上限；超过之后详情图改为打开时按需解码。
    nonisolated static let heroPreloadLimit = 24
    /// 预热网格瓦片档的张数上限。按 4 列、可视 ± 若干行估算，超出这个数量再预热只会
    /// 让解码结果刚进缓存就被成本限流淘汰——那些图改为滚动到跟前时按需解码
    /// （每张几毫秒，且不在主线程）。
    nonisolated static let tilePreloadLimit = 24
    /// 瓦片档的常驻预算。同一张卡两档差约 10 倍，只按张数限流会在卡图变多后失控
    /// （200 张瓦片 ≈ 770MB），所以两档都按**字节成本**限流。
    nonisolated static let tileByteLimit = 96 * 1024 * 1024
    nonisolated static let heroByteLimit = 128 * 1024 * 1024

    private let decode: Decode
    /// 正在解码中的图：预热与「打开单卡」可能同时要同一张，等同一份结果即可，不要再解一次。
    private var inFlight: [String: Task<CGImage?, Never>] = [:]
    private var memoryPressure: DispatchSourceMemoryPressure?

    init(decode: @escaping Decode = ArtworkDecoder.decode) {
        self.decode = decode
        tiles.countLimit = 64
        tiles.totalCostLimit = Self.tileByteLimit
        heroes.totalCostLimit = Self.heroByteLimit
        startObservingMemoryPressure()
    }

    /// 收到系统内存压力就整体丢弃解码结果。重解一张瓦片只要几毫秒，留着上百 MB
    /// 等系统来杀进程不划算（研究稿 §3.5）。
    private func startObservingMemoryPressure() {
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.dropCaches() }
        }
        source.activate()
        memoryPressure = source
    }

    /// 丢弃全部解码结果；正在解码中的请求不受影响，完成后会重新进缓存。
    func dropCaches() {
        tiles.removeAllObjects()
        heroes.removeAllObjects()
    }

    /// 同步命中：预热或之前看过之后，视图不再出现「先空一下再补图」。
    func cached(_ name: String, _ variant: ArtworkVariant) -> CGImage? {
        cache(for: variant).object(forKey: name as NSString)
    }

    func image(_ name: String, _ variant: ArtworkVariant) async -> CGImage? {
        await decodeOnce(name, variant, priority: .userInitiated)
    }

    /// 预热：启动后先把网格那一档解好（进「卡牌」不再现场解码），
    /// 再把全分辨率的详情图备好，让「打开单卡」既不掉画质也不等解码。
    func preload(_ names: [String]) {
        let pendingTiles = names.prefix(Self.tilePreloadLimit).filter { cached($0, .tile) == nil }
        let pendingHeroes = names.count <= Self.heroPreloadLimit
            ? names.filter { cached($0, .hero) == nil }
            : []
        guard !pendingTiles.isEmpty || !pendingHeroes.isEmpty else { return }
        Task {
            // 瓦片档先解：那是进「卡牌」立刻要用的；详情档更大，放在后面用较低优先级慢慢备。
            for (variant, pending, priority) in [
                (ArtworkVariant.tile, pendingTiles, TaskPriority.userInitiated),
                (.hero, pendingHeroes, .utility)
            ] {
                for name in pending {
                    _ = await decodeOnce(name, variant, priority: priority)
                }
            }
        }
    }

    private func cache(for variant: ArtworkVariant) -> NSCache<NSString, CGImage> {
        switch variant {
        case .tile: return tiles
        case .hero: return heroes
        }
    }

    private func store(_ image: CGImage, name: String, variant: ArtworkVariant) {
        let cache = cache(for: variant)
        let cost = image.bytesPerRow * image.height
        cache.setObject(image, forKey: name as NSString, cost: cost)
    }

    /// 解码一次再进缓存。同一张同一档若已有解码在跑，就等那一份结果。
    private func decodeOnce(
        _ name: String,
        _ variant: ArtworkVariant,
        priority: TaskPriority
    ) async -> CGImage? {
        if let hit = cached(name, variant) {
            return hit
        }
        let key = "\(variant)#\(name)"
        if let existing = inFlight[key] {
            return await existing.value
        }
        let decode = self.decode
        let task = Task.detached(priority: priority) {
            decode(name, variant)
        }
        inFlight[key] = task
        let decoded = await task.value
        if let decoded {
            store(decoded, name: name, variant: variant)
        }
        inFlight[key] = nil
        return decoded
    }
}
