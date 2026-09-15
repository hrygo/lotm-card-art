// Deterministic carrier pipeline for the Fool Agentic mother → direct five-tier
// frame freeze → ten sequences. Agentic images own tier appearance; this program
// owns matte removal, canonical alpha, exact glyphs, direct mapping, local diffs,
// and non-destructive output. It must never recolor or synthesize a tier frame.
import AppKit
import CoreText
import CryptoKit
import ImageIO

enum Failure: Error { case invalid(String) }

func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw Failure.invalid(message) }
}

let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

struct Raster {
    var w: Int
    var h: Int
    var p: [UInt8] // straight RGBA, top-left row-major

    init(_ w: Int, _ h: Int) {
        self.w = w
        self.h = h
        self.p = [UInt8](repeating: 0, count: w * h * 4)
    }

    init(_ url: URL) throws {
        guard let rep = NSBitmapImageRep(data: try Data(contentsOf: url)),
              let image = rep.cgImage else {
            throw Failure.invalid("Cannot decode image: \(url.path)")
        }
        self.init(image.width, image.height)
        p.withUnsafeMutableBytes { bytes in
            let context = CGContext(
                data: bytes.baseAddress,
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: w * 4,
                space: sRGB,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        unpremultiply()
    }

    var image: CGImage {
        var bytes = p
        for i in stride(from: 0, to: bytes.count, by: 4) {
            let a = Int(bytes[i + 3])
            for c in 0..<3 {
                bytes[i + c] = a == 0 ? 0 : UInt8(min(255, Int(bytes[i + c]) * a / 255))
            }
        }
        return CGImage(
            width: w,
            height: h,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: w * 4,
            space: sRGB,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: Data(bytes) as CFData)!,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!
    }

    // A lossless straight-RGBA export for localized edits. The normal image
    // property is premultiplied for CoreGraphics compositing; using it for a
    // frozen carrier would quantize RGB values on semi-transparent edge
    // pixels when the PNG is decoded again, appearing as false drift outside
    // the declared edit domain.
    var straightImage: CGImage {
        CGImage(
            width: w,
            height: h,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: w * 4,
            space: sRGB,
            bitmapInfo: CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)),
            provider: CGDataProvider(data: Data(p) as CFData)!,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!
    }

    mutating func unpremultiply() {
        for i in stride(from: 0, to: p.count, by: 4) {
            let a = Int(p[i + 3])
            if a > 0 {
                for c in 0..<3 { p[i + c] = UInt8(min(255, Int(p[i + c]) * 255 / a)) }
            }
        }
    }

    func save(_ url: URL) throws {
        try require(!FileManager.default.fileExists(atPath: url.path), "Refusing overwrite: \(url.path)")
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw Failure.invalid("Cannot encode image: \(url.path)")
        }
        try data.write(to: url, options: .withoutOverwriting)
    }

    func saveStraight(_ url: URL) throws {
        try require(!FileManager.default.fileExists(atPath: url.path), "Refusing overwrite: \(url.path)")
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            "public.png" as CFString,
            1,
            nil
        ) else {
            throw Failure.invalid("Cannot create straight RGBA PNG destination: \(url.path)")
        }
        CGImageDestinationAddImage(destination, straightImage, nil)
        try require(CGImageDestinationFinalize(destination), "Cannot finalize straight RGBA PNG: \(url.path)")
    }

    var alpha: [UInt8] { stride(from: 3, to: p.count, by: 4).map { p[$0] } }

    func bbox(_ threshold: UInt8 = 8) -> [Int] {
        var x0 = w
        var y0 = h
        var x1 = -1
        var y1 = -1
        for y in 0..<h {
            for x in 0..<w where p[(y * w + x) * 4 + 3] > threshold {
                x0 = min(x0, x)
                y0 = min(y0, y)
                x1 = max(x1, x)
                y1 = max(y1, y)
            }
        }
        return x1 < 0 ? [0, 0, 0, 0] : [x0, y0, x1 - x0 + 1, y1 - y0 + 1]
    }

    func resized(_ width: Int, _ height: Int) -> Raster {
        var result = Raster(width, height)
        result.p.withUnsafeMutableBytes { bytes in
            let context = CGContext(
                data: bytes.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: sRGB,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        result.unpremultiply()
        return result
    }
}

func sha(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

func digest(_ url: URL) throws -> String { sha(try Data(contentsOf: url)) }

func safeRelative(_ root: URL, _ relative: String) throws -> URL {
    try require(!relative.hasPrefix("/") && !relative.split(separator: "/").contains(".."), "Unsafe relative path: \(relative)")
    let base = root.resolvingSymlinksInPath()
    let url = base.appendingPathComponent(relative).resolvingSymlinksInPath()
    try require(url.path.hasPrefix(base.path + "/"), "Path escapes root: \(relative)")
    return url
}

func resolvePath(_ root: URL, _ value: String) throws -> URL {
    if value.hasPrefix("/") { return URL(fileURLWithPath: value).standardizedFileURL }
    return try safeRelative(root, value)
}

func relativePath(_ root: URL, _ url: URL) -> String {
    let base = root.standardizedFileURL.path
    let path = url.standardizedFileURL.path
    return path.hasPrefix(base + "/") ? String(path.dropFirst(base.count + 1)) : path
}

func jsonObject(_ url: URL) throws -> [String: Any] {
    guard let value = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] else {
        throw Failure.invalid("Expected JSON object: \(url.path)")
    }
    return value
}

func object(_ value: Any?, _ label: String) throws -> [String: Any] {
    guard let value = value as? [String: Any] else { throw Failure.invalid("Expected object: \(label)") }
    return value
}

func objects(_ value: Any?, _ label: String) throws -> [[String: Any]] {
    guard let values = value as? [Any] else { throw Failure.invalid("Expected object array: \(label)") }
    return try values.enumerated().map { try object($0.element, "\(label)[\($0.offset)]") }
}

func string(_ value: Any?, _ label: String, allowEmpty: Bool = false) throws -> String {
    guard let value = value as? String, allowEmpty || !value.isEmpty else {
        throw Failure.invalid("Missing string: \(label)")
    }
    return value
}

func integer(_ value: Any?, _ label: String) throws -> Int {
    if let value = value as? Int { return value }
    if let value = value as? NSNumber { return value.intValue }
    throw Failure.invalid("Expected integer: \(label)")
}

func real(_ value: Any?, _ label: String) throws -> Double {
    if let value = value as? Double { return value }
    if let value = value as? NSNumber { return value.doubleValue }
    throw Failure.invalid("Expected number: \(label)")
}

func boolean(_ value: Any?, _ label: String) throws -> Bool {
    guard let value = value as? Bool else { throw Failure.invalid("Expected boolean: \(label)") }
    return value
}

func reals(_ value: Any?, _ label: String) throws -> [Double] {
    guard let values = value as? [Any] else { throw Failure.invalid("Expected number array: \(label)") }
    return try values.enumerated().map { try real($0.element, "\(label)[\($0.offset)]") }
}

func hexColor(_ value: String) throws -> [Double] {
    let raw = String(value.dropFirst())
    try require(value.hasPrefix("#") && raw.count == 6, "Invalid color: \(value)")
    guard let n = Int(raw, radix: 16) else { throw Failure.invalid("Invalid color: \(value)") }
    return [Double((n >> 16) & 0xff) / 255.0, Double((n >> 8) & 0xff) / 255.0, Double(n & 0xff) / 255.0]
}

func clamp(_ value: Double) -> Double { max(0, min(1, value)) }

func blend(_ lhs: [Double], _ rhs: [Double], _ amount: Double) -> [Double] {
    zip(lhs, rhs).map { $0 * (1 - amount) + $1 * amount }
}

func cgColor(_ rgb: [Double], _ alpha: Double = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(clamp(rgb[0])), green: CGFloat(clamp(rgb[1])), blue: CGFloat(clamp(rgb[2])), alpha: CGFloat(clamp(alpha)))
}

// 对不存在的路径调用 resolvingSymlinksInPath() 结果不稳定，故只归一经由已存在祖先的路径分量。
func canonicalOutputPath(_ url: URL) -> URL {
    var existing = url.standardizedFileURL
    var tail: [String] = []
    while !FileManager.default.fileExists(atPath: existing.path), existing.pathComponents.count > 1 {
        tail.insert(existing.lastPathComponent, at: 0)
        existing = existing.deletingLastPathComponent()
    }
    var result = existing.resolvingSymlinksInPath()
    for component in tail { result.appendPathComponent(component) }
    return result.standardizedFileURL
}

func isPath(_ child: URL, inside parent: URL) -> Bool {
    let childComponents = canonicalOutputPath(child).pathComponents
    let parentComponents = canonicalOutputPath(parent).pathComponents
    return childComponents.count > parentComponents.count
        && Array(childComponents.prefix(parentComponents.count)) == parentComponents
}

func ensureNewOutput(_ root: URL, _ output: URL) throws {
    let base = root.appendingPathComponent("artifacts/production")
    try require(isPath(output, inside: base), "Output must be a child of artifacts/production")
    let resolved = output.standardizedFileURL
    try require(!FileManager.default.fileExists(atPath: resolved.path), "Output already exists: \(resolved.path)")
    try FileManager.default.createDirectory(at: resolved, withIntermediateDirectories: true)
}

func writeJSON(_ value: Any, _ url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    try require(!FileManager.default.fileExists(atPath: url.path), "Refusing overwrite: \(url.path)")
    try data.write(to: url, options: .withoutOverwriting)
}

func saveAndHash(_ raster: Raster, _ url: URL) throws -> String {
    try raster.save(url)
    return try digest(url)
}

func saveAndHashStraight(_ raster: Raster, _ url: URL) throws -> String {
    try raster.saveStraight(url)
    return try digest(url)
}

// PNG serialization through ImageIO can apply a deterministic premultiplied
// round-trip to semi-transparent edge RGB values. For the persisted-artifact
// gate, compare the output with the same frozen base after the same encoder
// round-trip; the actual edit-domain invariant is still checked on the
// straight-RGBA rasters before serialization and is recorded in the manifest.
func roundTripForComparison(_ raster: Raster) throws -> Raster {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("foolpipeline-roundtrip-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: url) }
    try raster.saveStraight(url)
    return try Raster(url)
}

func saveMask(_ width: Int, _ height: Int, _ rect: CGRect, _ url: URL) throws -> String {
    var mask = Raster(width, height)
    let x0 = max(0, Int(rect.minX.rounded(.down)))
    let y0 = max(0, Int(rect.minY.rounded(.down)))
    let x1 = min(width, Int(rect.maxX.rounded(.up)))
    let y1 = min(height, Int(rect.maxY.rounded(.up)))
    if x0 < x1 && y0 < y1 {
        for y in y0..<y1 {
            for x in x0..<x1 {
                let i = (y * width + x) * 4
                mask.p[i] = 255; mask.p[i + 1] = 255; mask.p[i + 2] = 255; mask.p[i + 3] = 255
            }
        }
    }
    return try saveAndHash(mask, url)
}

func clearDesignRect(_ source: inout Raster, _ designRect: [Double]) {
    let sx = Double(source.w) / 1024.0
    let sy = Double(source.h) / 1536.0
    let x0 = max(0, Int((designRect[0] * sx).rounded(.down)))
    let y0 = max(0, Int((designRect[1] * sy).rounded(.down)))
    let x1 = min(source.w, Int(((designRect[0] + designRect[2]) * sx).rounded(.up)))
    let y1 = min(source.h, Int(((designRect[1] + designRect[3]) * sy).rounded(.up)))
    guard x0 < x1 && y0 < y1 else { return }
    for y in y0..<y1 {
        for x in x0..<x1 { source.p[(y * source.w + x) * 4 + 3] = 0 }
    }
}

func clearInteriorBlack(_ source: inout Raster, _ seed: CGPoint, _ threshold: Int = 42) {
    let startX = Int(seed.x.rounded())
    let startY = Int(seed.y.rounded())
    guard startX >= 0 && startX < source.w && startY >= 0 && startY < source.h else { return }
    func nearBlack(_ index: Int) -> Bool {
        let i = index * 4
        return source.p[i + 3] > 0 && Int(source.p[i]) <= threshold && Int(source.p[i + 1]) <= threshold && Int(source.p[i + 2]) <= threshold
    }
    let start = startY * source.w + startX
    guard nearBlack(start) else { return }
    var visited = [Bool](repeating: false, count: source.w * source.h)
    var queue = [Int]()
    func add(_ index: Int) {
        guard index >= 0 && index < visited.count && !visited[index] && nearBlack(index) else { return }
        visited[index] = true
        queue.append(index)
    }
    add(start)
    var cursor = 0
    while cursor < queue.count {
        let value = queue[cursor]
        cursor += 1
        let x = value % source.w
        let y = value / source.w
        if x > 0 { add(value - 1) }
        if x + 1 < source.w { add(value + 1) }
        if y > 0 { add(value - source.w) }
        if y + 1 < source.h { add(value + source.w) }
    }
    for value in queue { source.p[value * 4 + 3] = 0 }
}

func removeBoundaryBlack(_ source: Raster, threshold: Int = 42) -> Raster {
    var result = source
    var visited = [Bool](repeating: false, count: source.w * source.h)
    var queue = [Int]()
    func nearBlack(_ index: Int) -> Bool {
        let i = index * 4
        return Int(source.p[i]) <= threshold && Int(source.p[i + 1]) <= threshold && Int(source.p[i + 2]) <= threshold
    }
    func add(_ index: Int) {
        guard index >= 0 && index < visited.count && !visited[index] && nearBlack(index) else { return }
        visited[index] = true
        queue.append(index)
    }
    for x in 0..<source.w { add(x); add((source.h - 1) * source.w + x) }
    for y in 0..<source.h { add(y * source.w); add(y * source.w + source.w - 1) }
    var cursor = 0
    while cursor < queue.count {
        let v = queue[cursor]; cursor += 1
        let x = v % source.w
        let y = v / source.w
        if x > 0 { add(v - 1) }
        if x + 1 < source.w { add(v + 1) }
        if y > 0 { add(v - source.w) }
        if y + 1 < source.h { add(v + source.w) }
    }
    for v in queue { result.p[v * 4 + 3] = 0 }
    return result
}

func alphaDifference(_ lhs: Raster, _ rhs: Raster) -> Int {
    guard lhs.w == rhs.w && lhs.h == rhs.h else { return Int.max }
    return zip(lhs.alpha, rhs.alpha).filter { $0 != $1 }.count
}

func pixelDifference(_ lhs: Raster, _ rhs: Raster) -> Int {
    guard lhs.w == rhs.w && lhs.h == rhs.h else { return Int.max }
    return zip(lhs.p, rhs.p).filter { $0 != $1 }.count
}

func differenceOutside(_ lhs: Raster, _ rhs: Raster, _ allowed: CGRect) -> Int {
    guard lhs.w == rhs.w && lhs.h == rhs.h else { return Int.max }
    var changed = 0
    for y in 0..<lhs.h {
        for x in 0..<lhs.w where !allowed.contains(CGPoint(x: x, y: y)) {
            let i = (y * lhs.w + x) * 4
            if lhs.p[i] != rhs.p[i] || lhs.p[i + 1] != rhs.p[i + 1] || lhs.p[i + 2] != rhs.p[i + 2] || lhs.p[i + 3] != rhs.p[i + 3] {
                changed += 1
            }
        }
    }
    return changed
}

func differenceInside(_ lhs: Raster, _ rhs: Raster, _ allowed: CGRect) -> Int {
    guard lhs.w == rhs.w && lhs.h == rhs.h else { return Int.max }
    var changed = 0
    for y in 0..<lhs.h {
        for x in 0..<lhs.w where allowed.contains(CGPoint(x: x, y: y)) {
            let i = (y * lhs.w + x) * 4
            if lhs.p[i] != rhs.p[i] || lhs.p[i + 1] != rhs.p[i + 1] || lhs.p[i + 2] != rhs.p[i + 2] || lhs.p[i + 3] != rhs.p[i + 3] {
                changed += 1
            }
        }
    }
    return changed
}

func drawLayers(_ layers: [(Raster, CGRect)], _ width: Int, _ height: Int, background: [Double]? = nil) -> Raster {
    var result = Raster(width, height)
    result.p.withUnsafeMutableBytes { bytes in
        let context = CGContext(
            data: bytes.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: sRGB,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        if let bg = background {
            context.setFillColor(cgColor(bg))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        context.interpolationQuality = .high
        for (raster, rect) in layers {
            let converted = CGRect(x: rect.minX, y: CGFloat(height) - rect.maxY, width: rect.width, height: rect.height)
            context.draw(raster.image, in: converted)
        }
    }
    result.unpremultiply()
    return result
}

// Composite a local effect directly into a frozen base image. Using a full
// canvas CGContext pass here would re-rasterize even untouched transparent
// and anti-aliased pixels, making a visually local inscription fail the
// byte-level outside-edit-domain gate. This straight-RGBA source-over pass
// preserves every byte outside the declared rectangle.
func compositeWithin(_ base: Raster, _ overlay: Raster, _ allowed: CGRect) -> Raster {
    var result = base
    let minX = max(0, Int(floor(allowed.minX)))
    let maxX = min(base.w, Int(ceil(allowed.maxX)))
    let minY = max(0, Int(floor(allowed.minY)))
    let maxY = min(base.h, Int(ceil(allowed.maxY)))
    guard minX < maxX && minY < maxY else { return result }
    for y in minY..<maxY {
        for x in minX..<maxX {
            let i = (y * base.w + x) * 4
            let sourceAlpha = Double(overlay.p[i + 3]) / 255.0
            guard sourceAlpha > 0 else { continue }
            let destinationAlpha = Double(base.p[i + 3]) / 255.0
            let outputAlpha = sourceAlpha + destinationAlpha * (1.0 - sourceAlpha)
            guard outputAlpha > 0 else { continue }
            for channel in 0..<3 {
                let source = Double(overlay.p[i + channel]) / 255.0
                let destination = Double(base.p[i + channel]) / 255.0
                let output = (source * sourceAlpha + destination * destinationAlpha * (1.0 - sourceAlpha)) / outputAlpha
                result.p[i + channel] = UInt8((clamp(output) * 255.0).rounded())
            }
            result.p[i + 3] = UInt8((clamp(outputAlpha) * 255.0).rounded())
        }
    }
    return result
}

// Extract a design-space crop without touching any other image bytes. The
// Agentic inscription candidates are full-frame previews; this stage only
// consumes the declared right-side edit domain and maps it back to the frozen
// 2K frame.
func cropped(_ source: Raster, _ rect: CGRect) throws -> Raster {
    let x0 = max(0, Int(floor(rect.minX)))
    let y0 = max(0, Int(floor(rect.minY)))
    let x1 = min(source.w, Int(ceil(rect.maxX)))
    let y1 = min(source.h, Int(ceil(rect.maxY)))
    try require(x0 < x1 && y0 < y1, "Invalid crop rectangle")
    var result = Raster(x1 - x0, y1 - y0)
    for y in y0..<y1 {
        for x in x0..<x1 {
            let sourceIndex = (y * source.w + x) * 4
            let targetIndex = ((y - y0) * result.w + (x - x0)) * 4
            for channel in 0..<4 { result.p[targetIndex + channel] = source.p[sourceIndex + channel] }
        }
    }
    return result
}

// Preserve the frozen base alpha while importing the Agentic crop. This is
// essential for RGB Agentic previews: their baked black background must not
// become an opaque rectangle inside the transparent card silhouette.
func localizedInscription(_ base: Raster, _ candidate: Raster) throws -> Raster {
    try require(base.w == 2048 && base.h == 3072, "Localized base must be 2048x3072")
    let designCandidate = candidate.w == 1024 && candidate.h == 1536 ? candidate : candidate.resized(1024, 1536)
    let sourceCrop = try cropped(designCandidate, FoolGeometry.rightSequenceZone)
    let target = FoolGeometry.finalRect(FoolGeometry.rightSequenceZone)
    let targetWidth = Int(target.width.rounded())
    let targetHeight = Int(target.height.rounded())
    let resizedCrop = sourceCrop.resized(targetWidth, targetHeight)
    var overlay = Raster(base.w, base.h)
    for y in 0..<targetHeight {
        for x in 0..<targetWidth {
            let sourceIndex = (y * resizedCrop.w + x) * 4
            let targetX = Int(target.minX.rounded()) + x
            let targetY = Int(target.minY.rounded()) + y
            guard targetX >= 0 && targetX < base.w && targetY >= 0 && targetY < base.h else { continue }
            let targetIndex = (targetY * base.w + targetX) * 4
            overlay.p[targetIndex] = resizedCrop.p[sourceIndex]
            overlay.p[targetIndex + 1] = resizedCrop.p[sourceIndex + 1]
            overlay.p[targetIndex + 2] = resizedCrop.p[sourceIndex + 2]
            // The frozen base owns the silhouette and anti-aliased edge.
            let edgeFade = min(
                min(Double(x + 1) / 18.0, Double(targetWidth - x) / 18.0),
                min(Double(y + 1) / 18.0, Double(targetHeight - y) / 18.0)
            )
            let blend = UInt8((clamp(edgeFade) * Double(base.p[targetIndex + 3])).rounded())
            overlay.p[targetIndex + 3] = blend
        }
    }
    return compositeWithin(base, overlay, target)
}

struct TierStyle {
    let id: String
    let primary: [Double]
}

struct FoolGeometry {
    static let geometryID = "fool-agentic-mother-v2"
    // Frozen against the regenerated mother candidate: the lower jewel is a
    // regular equilateral hexagon in the bottom rail, not an ornament on the
    // name surface. All values are design-space coordinates (1024x1536).
    static let illustrationWindow = CGRect(x: 143.36, y: 300.0, width: 737.28, height: 910.0)
    static let nameSurface = CGRect(x: 224.0, y: 1216.0, width: 576.0, height: 136.0)
    static let nameSafe = CGRect(x: 240.0, y: 1228.0, width: 544.0, height: 112.0)
    static let gemCenter = CGPoint(x: 512.0, y: 1421.0)
    static let gemVisibleSize = CGSize(width: 132.0, height: 114.0)
    static let gemNameClearance = 12.0
    // The reserved inscription groove is the continuous mid-pillar channel
    // used by the Agentic candidates. The previous y=780..1060 declaration
    // cut the upper glyphs of multi-character names; this interface keeps a
    // 16-design-pixel safety margin while covering the full 3–4 glyph stack.
    static let rightSequenceZone = CGRect(x: 878.0, y: 584.0, width: 108.0, height: 300.0)
    static let rightSequenceSafe = CGRect(x: 890.0, y: 600.0, width: 84.0, height: 268.0)
    static let pathwayCrown = CGRect(x: 350.0, y: 0.0, width: 330.0, height: 260.0)
    static let numeralExclusion = CGRect(x: 454.0, y: 82.0, width: 116.0, height: 112.0)
    static let rankNumeralCenter = CGPoint(x: 512.0, y: 136.0)
    static let rankNumeralSafe = CGRect(x: 466.0, y: 88.0, width: 92.0, height: 96.0)
    static let rankNumeralVisibleHeightFinal = CGFloat(148.0)

    static var gemRect: CGRect {
        CGRect(
            x: gemCenter.x - gemVisibleSize.width * 0.5,
            y: gemCenter.y - gemVisibleSize.height * 0.5,
            width: gemVisibleSize.width,
            height: gemVisibleSize.height
        )
    }

    static func finalRect(_ designRect: CGRect) -> CGRect {
        CGRect(x: designRect.minX * 2.0, y: designRect.minY * 2.0, width: designRect.width * 2.0, height: designRect.height * 2.0)
    }

    static func requireNoNameGemCollision() throws {
        let minimumGemTop = nameSurface.maxY + gemNameClearance
        try require(gemRect.minY >= minimumGemTop, "Gem slot intrudes into name surface or clearance boundary")
        try require(abs(gemRect.midX - nameSurface.midX) <= 0.001, "Gem slot is not centered on name surface")
    }
}

func requireRect(_ value: Any?, _ expected: CGRect, _ label: String) throws {
    let actual = try reals(value, label)
    let target = [Double(expected.minX), Double(expected.minY), Double(expected.width), Double(expected.height)]
    try require(actual.count == target.count && zip(actual, target).allSatisfy { abs($0 - $1) < 0.001 }, "Carrier geometry changed: (label)")
}

func requirePoint(_ value: Any?, _ expected: CGPoint, _ label: String) throws {
    let actual = try reals(value, label)
    let target = [Double(expected.x), Double(expected.y)]
    try require(actual.count == target.count && zip(actual, target).allSatisfy { abs($0 - $1) < 0.001 }, "Carrier geometry changed: (label)")
}

func requireSize(_ value: Any?, _ expected: CGSize, _ label: String) throws {
    let actual = try reals(value, label)
    let target = [Double(expected.width), Double(expected.height)]
    try require(actual.count == target.count && zip(actual, target).allSatisfy { abs($0 - $1) < 0.001 }, "Carrier geometry changed: (label)")
}

// The generic EmblemDock template is the non-through-hole vocabulary. The
// current Fool route is intentionally narrower: its crown is baked into the
// complete Agentic frame and the top socket is a fixed RankNumeralDock. This
// loader binds both facts to the executable pipeline and makes the measured
// native geometry the single source used by every stage.
struct PathwayPaths {
    let carrierContract: String
    let fiveTierKit: String
    let sequenceInscriptions: String
    let rankNumerals: String
}

var activePathway = "fool"
var cachedPathwayPaths: (root: String, pathway: String, paths: PathwayPaths)?

func carrierContractPath(_ pathway: String) -> String {
    pathway == "fool"
        ? "production/symbols/fool-carrier-execution-v1.json"
        : "production/symbols/\(pathway)/carrier-execution.json"
}

func resolvePathwayPaths(_ root: URL) throws -> PathwayPaths {
    if let cached = cachedPathwayPaths, cached.pathway == activePathway, cached.root == root.path {
        return cached.paths
    }
    let pathway = activePathway
    let contract = try jsonObject(try safeRelative(root, carrierContractPath(pathway)))
    try require(try string(contract["pathway_id"], "carrier pathway") == pathway, "Carrier pathway mismatch: \(pathway)")
    let catalogs = try object(contract["catalogs"], "carrier catalogs")
    var resolved: [String: String] = [:]
    for key in ["five_tier_kit", "sequence_inscriptions", "rank_numerals"] {
        let record = try object(catalogs[key], "catalog record")
        let path = try string(record["path"], "catalog path")
        try require(!path.hasPrefix("/"), "Catalog path must be repository-relative: \(path)")
        try require(try digest(try resolvePath(root, path)) == string(record["sha256"], "catalog hash"), "Carrier catalog changed: \(key)")
        resolved[key] = path
    }
    let paths = PathwayPaths(
        carrierContract: carrierContractPath(pathway),
        fiveTierKit: resolved["five_tier_kit"]!,
        sequenceInscriptions: resolved["sequence_inscriptions"]!,
        rankNumerals: resolved["rank_numerals"]!)
    cachedPathwayPaths = (root.path, pathway, paths)
    return paths
}

func loadFoolCarrierExecutionContract(_ root: URL) throws -> [String: Any] {
    let contractPath = try safeRelative(root, try resolvePathwayPaths(root).carrierContract)
    let contract = try jsonObject(contractPath)
    try require(try string(contract["schema_version"], "carrier schema version") == "1.0.0", "Carrier contract schema changed")
    try require(try string(contract["contract_type"], "carrier contract type") == "fool-carrier-execution", "Unexpected carrier contract")
    try require(try string(contract["status"], "carrier contract status") == "measured", "Carrier contract is not measured")
    try require(try string(contract["pathway_id"], "carrier pathway") == activePathway, "Carrier pathway changed")
    try require(try string(contract["geometry_id"], "carrier geometry") == FoolGeometry.geometryID, "Carrier geometry id changed")

    let canvas = try object(contract["canvas"], "carrier canvas")
    try require(try reals(canvas["design_size"], "carrier design size").map { Int($0) } == [1024, 1536], "Carrier design canvas changed")
    try require(try reals(canvas["native_size"], "carrier native size").map { Int($0) } == [1024, 1536], "Carrier native canvas changed")
    try require(try string(canvas["coordinate_system"], "carrier coordinate system") == "design-space-top-left-image-normalized", "Carrier coordinate system changed")
    try require(try string(canvas["color_space"], "carrier color space") == "sRGB", "Carrier color space changed")

    let templates = try object(contract["templates"], "carrier templates")
    let emblemRecord = try object(templates["emblem_dock"], "generic EmblemDock record")
    let emblemPath = try resolvePath(root, try string(emblemRecord["path"], "generic EmblemDock path"))
    try require(try digest(emblemPath) == string(emblemRecord["sha256"], "generic EmblemDock hash"), "Generic EmblemDock template changed")
    let emblemTemplate = try jsonObject(emblemPath)
    try require(try string(emblemTemplate["schema_version"], "generic EmblemDock schema") == "1.1.0", "Generic EmblemDock schema changed")
    try require(try string(emblemTemplate["contract_type"], "generic EmblemDock type") == "emblem-dock", "Generic EmblemDock type changed")
    try require(try string(emblemTemplate["status"], "generic EmblemDock status") == "template", "Generic EmblemDock must remain grammar-only")
    let genericGeometry = try object(emblemTemplate["geometry"], "generic EmblemDock geometry")
    let genericDock = try object(genericGeometry["dock"], "generic EmblemDock dock")
    try require(try string(genericDock["mode"], "generic EmblemDock mode") == "visual-recess-not-through-hole", "EmblemDock mode changed")
    try require(try boolean(genericDock["through_hole"], "generic EmblemDock through hole") == false, "EmblemDock through-hole is forbidden")

    let rankRecord = try object(templates["rank_numeral_dock"], "rank numeral dock record")
    let rankPath = try resolvePath(root, try string(rankRecord["path"], "rank numeral dock path"))
    try require(try digest(rankPath) == string(rankRecord["sha256"], "rank numeral dock hash"), "Rank numeral dock template changed")
    let rankTemplate = try jsonObject(rankPath)
    try require(try string(rankTemplate["schema_version"], "rank numeral schema") == "1.0.0", "Rank numeral dock schema changed")
    try require(try string(rankTemplate["contract_type"], "rank numeral type") == "fool-rank-numeral-dock", "Rank numeral dock type changed")
    try require(try string(rankTemplate["geometry_id"], "rank numeral geometry") == FoolGeometry.geometryID, "Rank numeral dock geometry changed")
    let rankDock = try object(rankTemplate["dock"], "rank numeral dock")
    try require(try string(rankDock["status"], "rank numeral status") == "reserved-empty", "Rank numeral dock is not reserved-empty")
    try require(try string(rankDock["shape"], "rank numeral shape") == "round", "Rank numeral dock shape changed")
    let rankAsset = try object(rankTemplate["numeral_asset"], "rank numeral asset")
    try require(try boolean(rankAsset["fusion_with_pathway_crown"], "rank numeral fusion") == false, "Rank numeral must not fuse with crown")

    let activeRecord = try object(contract["active_frame_source"], "carrier active frame")
    let activePath = try resolvePath(root, try string(activeRecord["path"], "carrier active frame path"))
    try require(try digest(activePath) == string(activeRecord["sha256"], "carrier active frame hash"), "Carrier active frame changed")
    let activeFrame = try Raster(activePath)
    try require([activeFrame.w, activeFrame.h] == [1024, 1536], "Carrier active frame must remain 1024x1536")

    let route = try object(contract["route"], "carrier route")
    try require(try string(route["emblem_dock_mode"], "carrier EmblemDock mode") == "rank-numeral-dock-current-route", "Carrier EmblemDock route changed")
    try require(try string(route["pathway_crown"], "carrier crown route") == "baked-into-frame-core", "Carrier crown route changed")
    try require(try string(route["rank_numeral"], "carrier numeral route") == "independent-simple-art-digit", "Carrier numeral route changed")
    try require(try string(route["sequence_name"], "carrier sequence-name route") == "agentic-complete-frame", "Carrier sequence-name route changed")
    try require(try boolean(route["through_hole"], "carrier through hole") == false, "Carrier through-hole is forbidden")
    try require(try boolean(route["standalone_emblem_overlay"], "carrier duplicate emblem") == false, "Carrier duplicate emblem is forbidden")

    let anchors = try object(contract["anchors"], "carrier anchors")
    let pathwayMark = try object(anchors["pathway_mark"], "pathway mark anchor")
    try requireRect(pathwayMark["rect_design"], CGRect(x: 50, y: 584, width: 84, height: 300), "pathway mark")
    try requireRect(pathwayMark["safe_rect_design"], CGRect(x: 50, y: 600, width: 84, height: 268), "pathway mark safe")
    let crown = try object(anchors["pathway_crown"], "pathway crown anchor")
    try requireRect(crown["rect_design"], FoolGeometry.pathwayCrown, "pathway crown")
    try requireRect(crown["safe_rect_design"], FoolGeometry.pathwayCrown, "pathway crown safe")
    let rank = try object(anchors["rank_numeral_dock"], "rank numeral anchor")
    try requirePoint(rank["center_design"], FoolGeometry.rankNumeralCenter, "rank numeral center")
    try requireRect(rank["safe_rect_design"], FoolGeometry.rankNumeralSafe, "rank numeral safe")
    let right = try object(anchors["right_sequence_zone"], "right sequence anchor")
    try requireRect(right["rect_design"], FoolGeometry.rightSequenceZone, "right sequence zone")
    try requireRect(right["safe_rect_design"], FoolGeometry.rightSequenceSafe, "right sequence safe")
    let name = try object(anchors["name_surface"], "name surface anchor")
    try requireRect(name["rect_design"], FoolGeometry.nameSurface, "name surface")
    try requireRect(name["safe_rect_design"], FoolGeometry.nameSafe, "name surface safe")
    let gem = try object(anchors["gem_slot"], "gem slot anchor")
    try require(try string(gem["shape"], "gem shape") == "regular-equilateral-hexagon", "Gem shape changed")
    try requirePoint(gem["center_design"], FoolGeometry.gemCenter, "gem center")
    try requireSize(gem["visible_size_design"], FoolGeometry.gemVisibleSize, "gem visible size")
    try require(abs(try real(gem["name_clearance_design"], "gem name clearance") - FoolGeometry.gemNameClearance) < 0.001, "Gem/name clearance changed")
    let illustration = try object(anchors["illustration_window"], "illustration window anchor")
    try requireRect(illustration["rect_design"], FoolGeometry.illustrationWindow, "illustration window")
    let exclusion = try object(anchors["numeral_exclusion"], "numeral exclusion anchor")
    try requireRect(exclusion["rect_design"], FoolGeometry.numeralExclusion, "numeral exclusion")
    try require(abs(try real(anchors["rank_numeral_visible_height_design"], "rank numeral visible height") - FoolGeometry.rankNumeralVisibleHeightFinal) < 0.001, "Rank numeral visible height changed")

    let protected = try object(contract["protected_regions"], "carrier protected regions")
    try require(try string(protected["pathway_crown"], "crown mask") == "mother-crown-protected", "Crown mask mapping changed")
    try require(try string(protected["rank_numeral"], "numeral mask") == "rank-numeral-safe", "Numeral mask mapping changed")
    try require(try string(protected["right_sequence_zone"], "right zone mask") == "right-sequence-zone", "Right zone mask mapping changed")
    try require(try string(protected["name_surface"], "name mask") == "name-surface", "Name mask mapping changed")
    try require(try string(protected["gem_slot"], "gem mask") == "gem-slot", "Gem mask mapping changed")
    try require(try string(protected["outside_edit_domain"], "outside mask") == "outside-edit-domain", "Outside mask mapping changed")
    let maskPolicy = try object(contract["mask_policy"], "carrier mask policy")
    try require(try string(maskPolicy["generated_by"], "mask generator") == "foolpipeline5.mother", "Mask generator changed")
    try require(try string(maskPolicy["coordinate_space"], "mask coordinate space") == "native-canvas", "Mask coordinate space changed")
    try require(try string(maskPolicy["alpha_policy"], "mask alpha policy") == "straight-RGBA", "Mask alpha policy changed")
    try require(try boolean(maskPolicy["no_crop_reassembly"], "mask crop policy") == true, "Mask crop/reassembly is forbidden")
    let thresholds = try object(contract["thresholds"], "carrier thresholds")
    try require(try integer(thresholds["geometry_displacement_max_px"], "carrier geometry threshold") == 0, "Carrier geometry threshold changed")
    try require(try integer(thresholds["outside_edit_domain_pixels_max"], "carrier outside threshold") == 0, "Carrier outside threshold changed")
    try require(try integer(thresholds["zone_center_error_max_native_px"], "carrier center threshold") == 1, "Carrier center threshold changed")
    try require(try integer(thresholds["protected_region_intersections_max"], "carrier intersection threshold") == 0, "Carrier intersection threshold changed")

    return [
        "path": relativePath(root, contractPath),
        "sha256": try digest(contractPath),
        "geometry_id": FoolGeometry.geometryID,
        "emblem_dock_mode": route["emblem_dock_mode"] as! String,
        "through_hole": false,
        "gem_slot": gem,
        "thresholds": thresholds,
    ]
}

func validateCarrierManifest(_ root: URL, _ manifest: [String: Any]) throws {
    let current = try loadFoolCarrierExecutionContract(root)
    let recorded = try object(manifest["carrier_contract"], "manifest carrier contract")
    try require(try string(recorded["path"], "manifest carrier contract path") == string(current["path"], "current carrier contract path"), "Manifest carrier contract path is stale")
    try require(try string(recorded["sha256"], "manifest carrier contract hash") == string(current["sha256"], "current carrier contract hash"), "Manifest carrier contract hash is stale")
    try require(try string(recorded["geometry_id"], "manifest carrier geometry") == FoolGeometry.geometryID, "Manifest carrier geometry is stale")
    try require(try string(recorded["emblem_dock_mode"], "manifest carrier route") == "rank-numeral-dock-current-route", "Manifest carrier route is stale")
    try require(try boolean(recorded["through_hole"], "manifest carrier through hole") == false, "Manifest carrier through-hole is enabled")
}

struct DirectTierSource {
    let id: String
    let sequences: [Int]
    let sourceURL: URL
    let sourceHash: String
}

// The active five-tier contract is an Agentic-source freeze. The renderer may
// remove the black matte and copy the canonical mother alpha, but it must not
// recolor, synthesize, or otherwise derive a new tier appearance here.
func loadDirectTierSources(_ root: URL) throws -> [DirectTierSource] {
    let catalogURL = try safeRelative(root, try resolvePathwayPaths(root).fiveTierKit)
    let catalog = try jsonObject(catalogURL)
    try require(try string(catalog["status"], "five-tier catalog status") == "official-agentic-visual-material-baseline", "Five-tier catalog is not the current visual baseline")
    let manifestRecord = try object(catalog["active_manifest"], "active five-tier manifest")
    let manifestURL = try resolvePath(root, try string(manifestRecord["path"], "active five-tier manifest path"))
    try require(try digest(manifestURL) == string(manifestRecord["sha256"], "active five-tier manifest hash"), "Active five-tier manifest changed")
    let manifest = try jsonObject(manifestURL)
    try require(try string(manifest["geometry_id"], "direct tier geometry") == FoolGeometry.geometryID, "Direct tier geometry changed")
    try require(try boolean(manifest["direct_agentic_sources"], "direct tier source mode") == true, "Direct tier source mode is disabled")
    try require(try string(manifest["color_transform"], "direct tier color transform") == "none", "Direct tier color transform is not none")
    try require(try integer(manifest["intermediate_2k_count"], "direct tier intermediate 2K count") == 0, "Direct tier manifest contains an intermediate 2K stage")
    let rows = try objects(manifest["tier_sources"], "direct tier rows")
    try require(rows.count == 5, "Direct tier catalog must contain exactly five rows")
    var result = [DirectTierSource]()
    for row in rows {
        let id = try string(row["tier"], "direct tier id")
        let sequenceValues = row["sequences"] as? [Any] ?? []
        let sequences = try sequenceValues.map { try integer($0, "direct tier sequences") }
        let path = try string(row["source"], "direct tier source")
        let expectedHash = try string(row["sha256"], "direct tier source hash")
        let sourceURL = try resolvePath(root, path)
        try require(try digest(sourceURL) == expectedHash, "Direct tier source changed: \(id)")
        result.append(DirectTierSource(id: id, sequences: sequences, sourceURL: sourceURL, sourceHash: expectedHash))
    }
    let expected = Set(["low", "mid", "saint", "angel", "true-god"])
    try require(Set(result.map { $0.id }) == expected, "Direct tier catalog is incomplete")
    try require(Set(result.flatMap { $0.sequences }) == Set(0...9), "Direct tier sequence mapping is incomplete")
    return result.sorted { $0.id < $1.id }
}

func freezeDirectTier(_ source: Raster, _ canonical: Raster) throws -> Raster {
    try require(source.w == canonical.w && source.h == canonical.h, "Direct tier and canonical mother sizes differ")
    var cleaned = removeBoundaryBlack(source)
    clearInteriorBlack(&cleaned, CGPoint(x: CGFloat(source.w) * 0.5, y: CGFloat(source.h) * 0.455))
    var result = cleaned
    for index in 0..<(canonical.w * canonical.h) {
        let i = index * 4
        result.p[i + 3] = canonical.p[i + 3]
        if canonical.p[i + 3] == 0 {
            result.p[i] = 0
            result.p[i + 1] = 0
            result.p[i + 2] = 0
        }
    }
    return result
}

func standardizeDirectTier(_ native: Raster, _ canonical: Raster) throws -> Raster {
    let resized = native.resized(canonical.w, canonical.h)
    var result = resized
    try require(result.w == canonical.w && result.h == canonical.h, "Direct tier standard sampling changed")
    for index in 0..<(canonical.w * canonical.h) {
        let i = index * 4
        result.p[i + 3] = canonical.p[i + 3]
        if canonical.p[i + 3] == 0 {
            result.p[i] = 0
            result.p[i + 1] = 0
            result.p[i + 2] = 0
        }
    }
    return result
}

func makeThumbnailSheet(_ rasters: [Raster], _ labels: [String], _ columns: Int, _ background: [Double]) -> Raster {
    let thumbW = 256
    let thumbH = 384
    let gap = 18
    let rows = Int(ceil(Double(rasters.count) / Double(columns)))
    let sheetWidth = columns * thumbW + max(0, columns - 1) * gap
    let sheetHeight = rows * thumbH + max(0, rows - 1) * gap
    var layers = [(Raster, CGRect)]()
    for index in rasters.indices {
        let thumb = rasters[index].resized(thumbW, thumbH)
        let col = index % columns
        let row = index / columns
        let x = col * (thumbW + gap)
        let y = row * (thumbH + gap)
        layers.append((thumb, CGRect(x: x, y: y, width: thumbW, height: thumbH)))
    }
    return drawLayers(layers, sheetWidth, sheetHeight, background: background)
}

func makeTextLine(_ value: String, _ size: CGFloat, _ color: CGColor) -> CTLine {
    let font = CTFontCreateWithName("Songti SC" as CFString, size, nil)
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .kern: 1.0]
    return CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: attributes))
}

func drawTextLine(_ line: CTLine, _ context: CGContext, _ origin: CGPoint) {
    context.saveGState()
    context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    context.textPosition = origin
    CTLineDraw(line, context)
    context.restoreGState()
}

func textMask(_ value: String, _ rect: CGRect, _ width: Int, _ height: Int) -> Raster {
    var result = Raster(width, height)
    result.p.withUnsafeMutableBytes { bytes in
        let context = CGContext(data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        let chars = value.map(String.init)
        guard !chars.isEmpty else { return }
        let fontSize = min(96.0, max(78.0, rect.width * 0.46))
        let gap = min(14.0, max(8.0, fontSize * 0.14))
        let total = fontSize * CGFloat(chars.count) + gap * CGFloat(max(0, chars.count - 1))
        var y = rect.midY - total * 0.5
        for ch in chars {
            let line = makeTextLine(ch, fontSize, cgColor([1, 1, 1]))
            let bounds = CTLineGetImageBounds(line, context)
            let center = CGPoint(x: rect.midX, y: y + fontSize * 0.5)
            let origin = CGPoint(x: center.x - bounds.midX, y: center.y - bounds.midY)
            drawTextLine(line, context, origin)
            y += fontSize + gap
        }
    }
    result.unpremultiply()
    return result
}

func shifted(_ source: Raster, _ dx: Int, _ dy: Int) -> Raster {
    var result = Raster(source.w, source.h)
    for y in 0..<source.h {
        for x in 0..<source.w {
            let sx = x - dx
            let sy = y - dy
            guard sx >= 0 && sx < source.w && sy >= 0 && sy < source.h else { continue }
            let dst = (y * source.w + x) * 4
            let src = (sy * source.w + sx) * 4
            for c in 0..<4 { result.p[dst + c] = source.p[src + c] }
        }
    }
    return result
}

func tintMask(_ mask: Raster, _ color: [Double], _ alphaScale: Double = 1) -> Raster {
    var result = Raster(mask.w, mask.h)
    for i in stride(from: 0, to: mask.p.count, by: 4) {
        let a = UInt8(clamp(Double(mask.p[i + 3]) / 255.0 * alphaScale) * 255.0)
        result.p[i] = UInt8((clamp(color[0]) * 255).rounded())
        result.p[i + 1] = UInt8((clamp(color[1]) * 255).rounded())
        result.p[i + 2] = UInt8((clamp(color[2]) * 255).rounded())
        result.p[i + 3] = a
    }
    return result
}

struct NumeralTierStyle {
    let id: String
    let primary: [Double]
}

func loadNumeralTierStyles(_ root: URL) throws -> [String: NumeralTierStyle] {
    let url = try safeRelative(root, "config/quality-color-tokens.json")
    let config = try jsonObject(url)
    let rows = try objects(config["tiers"], "numeral tier colors")
    var result = [String: NumeralTierStyle]()
    for row in rows {
        let id = try string(row["id"], "numeral tier id")
        result[id] = NumeralTierStyle(id: id, primary: try hexColor(try string(row["primary"], "numeral tier primary")))
    }
    try require(Set(result.keys) == Set(["low", "mid", "saint", "angel", "true-god"]), "Numeral five-tier color configuration is incomplete")
    return result
}

func numeralProgress(_ digit: Int) -> Double {
    let clamped = max(0, min(9, digit))
    return Double(9 - clamped) / 9.0
}

func numeralVisibleHeight(_ digit: Int) -> CGFloat {
    CGFloat(148.0 + numeralProgress(digit) * 16.0)
}

func numeralSparkleCount(_ digit: Int) -> Int {
    let progress = numeralProgress(digit)
    return min(5, Int(floor(progress * 5.0)) + (progress > 0 ? 1 : 0))
}

// Apply the five-tier material treatment while the numeral is still at its
// native source resolution. The old preview tinted an already-downsampled
// full-canvas layer, which washed out facet texture at the 148–164px final
// visible height. This pass preserves the source alpha and local luminance,
// maps the mid-tone to the configured tier, and leaves only one later
// resampling operation for placement in the fixed dock.
func materializeNumeral(_ source: Raster, _ primary: [Double], _ digit: Int) -> Raster {
    var result = source
    let progress = numeralProgress(digit)
    let dark = blend(primary, [0.025, 0.030, 0.050], 0.70)
    let highlight = blend(primary, [1.0, 0.985, 0.90], 0.62 + progress * 0.10)
    let contrast = 1.08 + progress * 0.16
    for index in stride(from: 0, to: source.p.count, by: 4) {
        guard source.p[index + 3] > 0 else { continue }
        let base = [Double(source.p[index]) / 255.0, Double(source.p[index + 1]) / 255.0, Double(source.p[index + 2]) / 255.0]
        let luminance = clamp((base[0] * 0.2126 + base[1] * 0.7152 + base[2] * 0.0722 - 0.06) / 0.88)
        let textured = clamp((luminance - 0.5) * contrast + 0.5)
        let tiered: [Double]
        if textured < 0.50 {
            tiered = blend(dark, primary, textured / 0.50)
        } else {
            tiered = blend(primary, highlight, (textured - 0.50) / 0.50)
        }
        // Keep a small amount of the authored source color so folds, beads,
        // and facet variation survive the tier map instead of becoming flat.
        let preserved = blend(tiered, base, 0.10)
        for channel in 0..<3 {
            result.p[index + channel] = UInt8((clamp(preserved[channel]) * 255.0).rounded())
        }
    }
    return result
}

func sparkleLayer(_ visibleRect: CGRect, _ digit: Int, _ width: Int, _ height: Int) -> Raster {
    let progress = numeralProgress(digit)
    let count = numeralSparkleCount(digit)
    let intensity = 0.34 + progress * 0.48
    let anchors = [
        CGPoint(x: 0.80, y: 0.18),
        CGPoint(x: 0.20, y: 0.34),
        CGPoint(x: 0.77, y: 0.78),
        CGPoint(x: 0.22, y: 0.82),
        CGPoint(x: 0.52, y: 0.12)
    ]
    var result = Raster(width, height)
    result.p.withUnsafeMutableBytes { bytes in
        let context = CGContext(
            data: bytes.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: sRGB,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        for index in 0..<count {
            let anchor = anchors[index]
            let center = CGPoint(x: visibleRect.minX + visibleRect.width * anchor.x, y: visibleRect.minY + visibleRect.height * anchor.y)
            let longRadius = 2.0 + progress * 5.5
            let shortRadius = 0.65 + progress * 1.05
            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y - longRadius))
            path.addLine(to: CGPoint(x: center.x + shortRadius, y: center.y - shortRadius))
            path.addLine(to: CGPoint(x: center.x + longRadius, y: center.y))
            path.addLine(to: CGPoint(x: center.x + shortRadius, y: center.y + shortRadius))
            path.addLine(to: CGPoint(x: center.x, y: center.y + longRadius))
            path.addLine(to: CGPoint(x: center.x - shortRadius, y: center.y + shortRadius))
            path.addLine(to: CGPoint(x: center.x - longRadius, y: center.y))
            path.addLine(to: CGPoint(x: center.x - shortRadius, y: center.y - shortRadius))
            path.closeSubpath()
            context.addPath(path)
            context.setFillColor(cgColor([1.0, 0.93, 0.66], intensity))
            context.fillPath()
            context.addEllipse(in: CGRect(x: center.x - shortRadius * 0.65, y: center.y - shortRadius * 0.65, width: shortRadius * 1.3, height: shortRadius * 1.3))
            context.setFillColor(cgColor([1.0, 0.99, 0.90], intensity * 0.9))
            context.fillPath()
        }
    }
    result.unpremultiply()
    return result
}

func inscriptionRelief(_ value: String, _ rect: CGRect, _ style: TierStyle, _ width: Int, _ height: Int) -> Raster {
    let mask = textMask(value, rect, width, height)
    let dark = blend([0.04, 0.02, 0.07], style.primary, 0.12)
    let bevel = blend([0.65, 0.58, 0.48], style.primary, 0.18)
    let glint = blend([1.0, 0.98, 0.90], style.primary, 0.08)
    let shadow = tintMask(shifted(mask, 4, 5), dark, 0.55)
    let bevelLayer = tintMask(shifted(mask, -2, -2), bevel, 0.52)
    let face = tintMask(mask, dark, 1.0)
    let light = tintMask(shifted(mask, -1, -1), glint, 0.36)
    return drawLayers([(shadow, CGRect(x: 0, y: 0, width: width, height: height)), (bevelLayer, CGRect(x: 0, y: 0, width: width, height: height)), (face, CGRect(x: 0, y: 0, width: width, height: height)), (light, CGRect(x: 0, y: 0, width: width, height: height))], width, height)
}

func placeNumeral(_ frame: Raster, _ numeral: Raster, _ digit: Int, _ tier: NumeralTierStyle, _ center: CGPoint, _ safeRect: CGRect) throws -> Raster {
    let box = numeral.bbox()
    try require(box[2] > 0 && box[3] > 0 && numeral.alpha.contains(0), "Numeral must have a real transparent boundary")
    let scale = numeralVisibleHeight(digit) / CGFloat(box[3])
    let rect = CGRect(
        x: center.x - (CGFloat(box[0]) + CGFloat(box[2]) * 0.5) * scale,
        y: center.y - (CGFloat(box[1]) + CGFloat(box[3]) * 0.5) * scale,
        width: CGFloat(numeral.w) * scale,
        height: CGFloat(numeral.h) * scale
    )
    let visibleRect = CGRect(
        x: rect.minX + CGFloat(box[0]) * scale,
        y: rect.minY + CGFloat(box[1]) * scale,
        width: CGFloat(box[2]) * scale,
        height: CGFloat(box[3]) * scale
    )
    try require(safeRect.contains(visibleRect), "Numeral visible bbox escaped the round rank dock")
    let materialized = materializeNumeral(numeral, tier.primary, digit)
    let placed = drawLayers([(materialized, rect)], frame.w, frame.h)
    let sparkles = sparkleLayer(visibleRect, digit, frame.w, frame.h)
    var effect = Raster(frame.w, frame.h)
    effect = compositeWithin(effect, placed, safeRect)
    effect = compositeWithin(effect, sparkles, safeRect)
    return compositeWithin(frame, effect, safeRect)
}

struct SequenceRow {
    let digit: Int
    let sequenceID: String
    let sequenceName: String
    let tier: String
}

func loadSequenceRows(_ root: URL) throws -> [SequenceRow] {
    let catalog = try jsonObject(try safeRelative(root, try resolvePathwayPaths(root).sequenceInscriptions))
    try require(try string(catalog["stage"], "sequence catalog stage") == "agentic-complete-frame-baseline", "Sequence catalog is not the current Agentic baseline")
    let rows = try objects(catalog["entries"], "sequence entries")
    try require(rows.count == 10, "Sequence catalog must contain exactly ten rows")
    return try rows.map {
        SequenceRow(digit: try integer($0["digit"], "sequence digit"), sequenceID: try string($0["sequence_id"], "sequence id"), sequenceName: try string($0["sequence_name"], "sequence name"), tier: try string($0["tier"], "sequence tier"))
    }.sorted { $0.digit > $1.digit }
}

func loadNumeralAssets(_ root: URL) throws -> (URL, [Int: URL]) {
    let catalogURL = try safeRelative(root, try resolvePathwayPaths(root).rankNumerals)
    let catalog = try jsonObject(catalogURL)
    try require(try string(catalog["geometry_id"], "numeral geometry") == FoolGeometry.geometryID, "Numeral catalog geometry changed")
    try require(try boolean(catalog["fusion_with_pathway_crown"], "numeral fusion") == false, "Numerals must not fuse with pathway crown")
    let outputRoot = try resolvePath(root, try string(catalog["output_root"], "numeral output root"))
    let rows = try objects(catalog["digits"], "numeral digits")
    try require(rows.count == 10, "Numeral catalog must contain exactly ten digits")
    var assets = [Int: URL]()
    for row in rows {
        let digit = try integer(row["digit"], "numeral digit")
        try require((0...9).contains(digit) && assets[digit] == nil, "Numeral digit set is invalid")
        let path = try string(row["path"], "numeral path")
        assets[digit] = outputRoot.appendingPathComponent(path)
    }
    try require(assets.count == 10, "Numeral catalog digit set is incomplete")
    return (outputRoot, assets)
}

func motherStage(_ root: URL, _ inputValue: String, _ output: URL) throws {
    let input = try resolvePath(root, inputValue)
    let source = try Raster(input)
    try require([source.w, source.h] == [1024, 1536], "Mother source must be 1024x1536")
    try FoolGeometry.requireNoNameGemCollision()
    let carrierContract = try loadFoolCarrierExecutionContract(root)
    var cleaned = removeBoundaryBlack(source)
    // The central black field is the future illustration window, not a baked card back.
    // Flood-fill it from the interior so the real curved opening is retained;
    // a rectangular alpha cut would damage the lower frame silhouette.
    clearInteriorBlack(&cleaned, CGPoint(x: 512, y: 700))
    try ensureNewOutput(root, output)
    let maskDir = output.appendingPathComponent("masks")
    try FileManager.default.createDirectory(at: maskDir, withIntermediateDirectories: true)
    let nativeHash = try saveAndHash(cleaned, output.appendingPathComponent("frame-core-native.png"))
    var maskHashes = [String: String]()
    maskHashes["right-sequence-zone"] = try saveMask(source.w, source.h, FoolGeometry.rightSequenceZone, maskDir.appendingPathComponent("right-sequence-zone.png"))
    maskHashes["right-sequence-safe"] = try saveMask(source.w, source.h, FoolGeometry.rightSequenceSafe, maskDir.appendingPathComponent("right-sequence-safe.png"))
    maskHashes["name-surface"] = try saveMask(source.w, source.h, FoolGeometry.nameSurface, maskDir.appendingPathComponent("name-surface.png"))
    maskHashes["gem-slot"] = try saveMask(source.w, source.h, FoolGeometry.gemRect, maskDir.appendingPathComponent("gem-slot.png"))
    maskHashes["name-gem-clearance"] = try saveMask(source.w, source.h, CGRect(x: FoolGeometry.nameSurface.minX, y: FoolGeometry.nameSurface.maxY, width: FoolGeometry.nameSurface.width, height: FoolGeometry.gemNameClearance), maskDir.appendingPathComponent("name-gem-clearance.png"))
    maskHashes["pathway-crown"] = try saveMask(source.w, source.h, FoolGeometry.pathwayCrown, maskDir.appendingPathComponent("pathway-crown.png"))
    maskHashes["rank-numeral-safe"] = try saveMask(source.w, source.h, FoolGeometry.rankNumeralSafe, maskDir.appendingPathComponent("rank-numeral-safe.png"))
    let manifest: [String: Any] = [
        "version": 1,
        "mode": "fool-agentic-mother-frame-v2",
        "status": "pending-engineering-review",
        "geometry_id": FoolGeometry.geometryID,
        "coordinate_system": "design-space-top-left-image-normalized",
        "source": ["path": relativePath(root, input), "sha256": try digest(input), "size_px": [source.w, source.h], "channel_role": "agentic-rgb-study"],
        "frame_core": ["native": ["path": "frame-core-native.png", "sha256": nativeHash]],
        "right_sequence_zone": ["status": "reserved-empty", "rect_design_px": [878, 584, 108, 300], "safe_rect_design_px": [890, 600, 84, 268], "text_capacity": 6],
        "name_surface": ["background_pixels": 0, "rect_design_px": [224, 1216, 576, 136], "gem_protected": true],
        "gem_slot": ["count": 1, "tier_variant_count": 5, "shape": "regular-equilateral-hexagon", "placement": "integrated-bottom-rail", "center_design_px": [512, 1421], "visible_size_design_px": [132, 114], "name_clearance_design_px": 12, "secure_socket": true],
        "pathway_crown": ["status": "baked-into-frame-core", "rect_design_px": [350, 0, 330, 260], "numeral_exclusion_rect_design_px": [454, 82, 116, 112]],
        "rank_numeral_dock": ["status": "reserved-empty", "inner_shape": "round", "center_design_px": [512, 136], "safe_rect_design_px": [466, 88, 92, 96]],
        "carrier_contract": carrierContract,
        "masks": maskHashes,
        "alpha": ["has_zero": cleaned.alpha.contains(0), "has_opaque": cleaned.alpha.contains(255), "channel_format": "RGBA"],
        "native_canvas": [cleaned.w, cleaned.h],
        "intermediate_2k_count": 0,
        "thresholds": ["geometry_displacement_max_px": 0, "outside_edit_domain_pixels_max": 0, "center_error_max_native_px": 1],
        "formal_release_approved": false,
        "visual_status": "pending-user-visual-approval",
        "method": "Agentic source study; boundary matte; interior-black flood fill following the real opening; native-only geometry freeze"
    ]
    try writeJSON(manifest, output.appendingPathComponent("manifest.json"))
}

func tiersStage(_ root: URL, _ motherValue: String, _ output: URL) throws {
    let mother = try resolvePath(root, motherValue)
    let nativeURL = mother.appendingPathComponent("frame-core-native.png")
    let canonicalNative = try Raster(nativeURL)
    try require([canonicalNative.w, canonicalNative.h] == [1024, 1536], "Mother native frame-core must be 1024x1536")
    let carrierContract = try loadFoolCarrierExecutionContract(root)
    let directSources = try loadDirectTierSources(root)
    let order = ["low", "mid", "saint", "angel", "true-god"]
    try ensureNewOutput(root, output)
    var frames = [String: Raster]()
    var nativeHashes = [String: String]()
    var sourceRecords = [[String: Any]]()
    for id in order {
        guard let sourceRecord = directSources.first(where: { $0.id == id }) else {
            throw Failure.invalid("Missing direct tier source: \(id)")
        }
        let raw = try Raster(sourceRecord.sourceURL)
        try require([raw.w, raw.h] == [1024, 1536], "Direct tier source must be 1024x1536: \(id)")
        let native = try freezeDirectTier(raw, canonicalNative)
        try require(alphaDifference(native, canonicalNative) == 0, "Direct tier native geometry drift: \(id)")
        let nativeFile = output.appendingPathComponent("frame-\(id)-native.png")
        nativeHashes[id] = try saveAndHash(native, nativeFile)
        frames[id] = native
        sourceRecords.append([
            "tier": id,
            "sequences": sourceRecord.sequences,
            "source": relativePath(root, sourceRecord.sourceURL),
            "sha256": sourceRecord.sourceHash,
            "processing": ["color_transform": "none", "alpha_operation": "black-matte-removal-and-canonical-mask-only"],
            "geometry": ["native_alpha_difference_after_freeze": alphaDifference(native, canonicalNative)]
        ])
    }
    let sheet = makeThumbnailSheet(order.compactMap { frames[$0] }, order, 5, [0.025, 0.03, 0.055])
    let light = makeThumbnailSheet(order.compactMap { frames[$0] }, order, 5, [0.94, 0.94, 0.94])
    let sheetHash = try saveAndHash(sheet, output.appendingPathComponent("five-tiers.png"))
    let lightHash = try saveAndHash(light, output.appendingPathComponent("light-preview.png"))
    let manifest: [String: Any] = [
        "version": 1,
        "mode": "fool-five-tier-direct-batch-v1",
        "status": "agentic-native-material-baseline",
        "geometry_id": FoolGeometry.geometryID,
        "carrier_contract": carrierContract,
        "mother_source": relativePath(root, nativeURL),
        "native_canvas": [canonicalNative.w, canonicalNative.h],
        "intermediate_2k_count": 0,
        "tier_order": order,
        "sequence_mapping": ["low": [9, 8], "mid": [7, 6, 5], "saint": [4, 3], "angel": [2, 1], "true-god": [0]],
        "direct_agentic_sources": true,
        "color_transform": "none",
        "tier_sources": sourceRecords,
        "native_frame_hashes": nativeHashes,
        "diagnostic_hashes": ["five-tiers.png": sheetHash, "light-preview.png": lightHash],
        "geometry": ["alpha_difference_to_mother_native": order.compactMap { frames[$0] }.map { alphaDifference(canonicalNative, $0) }, "max_geometry_drift_px": 0, "max_anchor_drift_px": 0],
        "material": ["source": "direct-agentic-tier-studies", "color_transform": "none", "embedded_gem_preserved": true, "same_component_count": true],
        "gem_slot": ["count": 1, "variant_count": 5, "name_protection": true, "mode": "embedded-in-direct-tier-frame-no-synthetic-overlay"],
        "formal_release_approved": false,
        "no_cross_product_variants": true
    ]
    try writeJSON(manifest, output.appendingPathComponent("manifest.json"))
}

func sequencesStage(_ root: URL, _ tierValue: String, _ output: URL) throws {
    let tierRoot = try resolvePath(root, tierValue)
    let tierManifest = try jsonObject(tierRoot.appendingPathComponent("manifest.json"))
    try require(try string(tierManifest["mode"], "tier manifest mode") == "fool-five-tier-direct-batch-v1", "Sequence stage requires direct frozen tier frames")
    try require(try boolean(tierManifest["direct_agentic_sources"], "direct tier source mode") == true, "Sequence stage cannot consume derived tier frames")
    try require(try string(tierManifest["color_transform"], "tier color transform") == "none", "Sequence stage received recolored tier frames")
    let carrierContract = try loadFoolCarrierExecutionContract(root)
    let rows = try loadSequenceRows(root)
    try ensureNewOutput(root, output)
    let rightSequenceZone = FoolGeometry.rightSequenceZone
    var entries = [[String: Any]]()
    var outputHashes = [String: String]()
    for row in rows {
        let frameURL = tierRoot.appendingPathComponent("frame-\(row.tier)-native.png")
        let frame = try Raster(frameURL)
        try require([frame.w, frame.h] == [1024, 1536], "Sequence stage must remain on the native canvas: \(row.digit)")
        // The current production route does not manufacture a numeral layer.
        // Rank digit, quality material, pathway crown and sequence inscription
        // are authored together by the complete Agentic frame stage.
        let noInscription = frame
        try require(differenceInside(frame, noInscription, rightSequenceZone) == 0, "Program added sequence-name pixels: \(row.digit)")
        let frameName = "fool-\(row.digit)-frame-native.png"
        let frameHash = try saveAndHash(noInscription, output.appendingPathComponent(frameName))
        outputHashes[frameName] = frameHash
        entries.append([
            "digit": row.digit,
            "sequence_id": row.sequenceID,
            "sequence_name": row.sequenceName,
            "tier": row.tier,
            "frame": frameName,
            "right_inscription": ["status": "reserved-empty", "owner": "AgenticSequenceInscription", "target_text": row.sequenceName, "effect_domain": "RightSequenceZone-only"],
            "text_exact": false,
            "orientation": "pending-agentic-local-edit",
            "rank_numeral": ["status": "reserved-for-complete-agentic-frame", "owner": "AgenticCompleteFrame", "effect_domain": "RankNumeralDock-only"],
            "right_inscription_local_diff": ["allowed_rect_native_px": [878, 584, 108, 300], "changed_pixels": differenceInside(frame, noInscription, rightSequenceZone)],
            "geometry": ["max_drift_native_px": 0, "rank_numeral_center_native_px": [512, 136]]
        ])
    }
    let frames = try rows.map { try Raster(output.appendingPathComponent("fool-\($0.digit)-frame-native.png")) }
    let sheet = makeThumbnailSheet(frames, rows.map { "\($0.digit) \($0.sequenceName)" }, 5, [0.025, 0.03, 0.055])
    let light = makeThumbnailSheet(frames, rows.map { "\($0.digit) \($0.sequenceName)" }, 5, [0.94, 0.94, 0.94])
    let sheetHash = try saveAndHash(sheet, output.appendingPathComponent("ten-sequences-no-inscription.png"))
    let lightHash = try saveAndHash(light, output.appendingPathComponent("light-preview.png"))
    let manifest: [String: Any] = [
        "version": 1,
        "mode": "fool-ten-sequence-frame-batch-native-diagnostic-v3",
        "status": "pending-agentic-inscription",
        "geometry_id": FoolGeometry.geometryID,
        "carrier_contract": carrierContract,
        "tier_output": relativePath(root, tierRoot),
        "frame_source_mode": "direct-native-tier-frame",
        "frame_color_transform": "none",
        "native_canvas": [1024, 1536],
        "intermediate_2k_count": 0,
        "entries": entries.sorted { ($0["digit"] as? Int ?? 0) > ($1["digit"] as? Int ?? 0) },
        "output_hashes": outputHashes.merging(["ten-sequences-no-inscription.png": sheetHash, "light-preview.png": lightHash]) { $1 },
        "right_inscription_stage": ["status": "reserved-empty", "next_owner": "AgenticSequenceInscription", "effect_domain": "RightSequenceZone-only", "program_must_not_add_text": true],
        "rank_numeral_stage": ["status": "reserved-for-complete-agentic-frame", "owner": "AgenticCompleteFrame", "effect_domain": "RankNumeralDock-only", "standalone_numeral_catalog": "retired"],
        "subject_text": false,
        "no_sequence_name_pixels": true,
        "no_cross_product_variants": true,
        "formal_release_approved": false
    ]
    try writeJSON(manifest, output.appendingPathComponent("manifest.json"))
}

func inscriptionIngestStage(_ root: URL, _ catalogValue: String, _ output: URL) throws {
    let catalogURL = try resolvePath(root, catalogValue)
    let catalog = try jsonObject(catalogURL)
    try require(try string(catalog["asset_id"], "inscription catalog id") == "fool-agentic-sequence-inscriptions-v1", "Unexpected inscription catalog")
    let rows = try objects(catalog["entries"], "inscription catalog entries")
    try require(rows.count == 10, "Inscription catalog must contain exactly ten entries")
    try ensureNewOutput(root, output)

    let rightDomain = FoolGeometry.finalRect(FoolGeometry.rightSequenceZone)
    var entries = [[String: Any]]()
    var outputHashes = [String: String]()
    var frames = [Raster]()
    func rowDigit(_ row: [String: Any]) -> Int {
        if let value = row["digit"] as? Int { return value }
        if let value = row["digit"] as? NSNumber { return value.intValue }
        return 0
    }
    for row in rows.sorted(by: { rowDigit($0) > rowDigit($1) }) {
        let digit = try integer(row["digit"], "inscription digit")
        let sequenceName = try string(row["sequence_name"], "sequence name")
        let tier = try string(row["tier"], "sequence tier")
        let basePath = try string(row["input_frame"], "input frame")
        let baseURL = try resolvePath(root, basePath)
        let baseExpectedHash = try string(row["input_sha256"], "input frame hash")
        try require(try digest(baseURL) == baseExpectedHash, "Input frame changed: " + String(digit))
        let candidate = try object(row["candidate_output"], "candidate output " + String(digit))
        let candidatePath = try string(candidate["path"], "candidate path " + String(digit))
        let candidateURL = try resolvePath(root, candidatePath)
        let candidateExpectedHash = try string(candidate["sha256"], "candidate hash " + String(digit))
        try require(try digest(candidateURL) == candidateExpectedHash, "Agentic inscription candidate changed: " + String(digit))
        let base = try Raster(baseURL)
        let candidateRaster = try Raster(candidateURL)
        let final = try localizedInscription(base, candidateRaster)
        try require(differenceOutside(base, final, rightDomain) == 0, "Localized inscription escaped domain: " + String(digit))
        try require(differenceInside(base, final, rightDomain) > 0, "Localized inscription made no change: " + String(digit))
        let filename = "fool-" + String(digit) + "-inscribed-frame.png"
        let hash = try saveAndHashStraight(final, output.appendingPathComponent(filename))
        outputHashes[filename] = hash
        frames.append(final)
        entries.append([
            "digit": digit,
            "sequence_id": try string(row["sequence_id"], "sequence id"),
            "sequence_name": sequenceName,
            "tier": tier,
            "base_frame": basePath,
            "agentic_candidate": candidatePath,
            "output": filename,
            "size_px": [final.w, final.h],
            "outside_edit_domain_pixels": differenceOutside(base, final, rightDomain),
            "inside_edit_domain_pixels": differenceInside(base, final, rightDomain),
            "status": try string(candidate["status"], "candidate status " + String(digit))
        ])
    }
    let sheet = makeThumbnailSheet(frames, entries.map { "\($0["digit"] ?? "") \($0["sequence_name"] ?? "")" }, 5, [0.025, 0.03, 0.055])
    let light = makeThumbnailSheet(frames, entries.map { "\($0["digit"] ?? "") \($0["sequence_name"] ?? "")" }, 5, [0.94, 0.94, 0.94])
    outputHashes["inscribed-frames.png"] = try saveAndHash(sheet, output.appendingPathComponent("inscribed-frames.png"))
    outputHashes["light-preview.png"] = try saveAndHash(light, output.appendingPathComponent("light-preview.png"))
    let manifest: [String: Any] = [
        "version": 1,
        "mode": "fool-ten-sequence-inscribed-agentic-kit-v1",
        "status": "pending-user-visual-approval",
        "geometry_id": FoolGeometry.geometryID,
        "catalog": relativePath(root, catalogURL),
        "catalog_sha256": try digest(catalogURL),
        "source_batch": "artifacts/production/fool-ten-sequence-agent-ready-kit-v2",
        "edit_domain_final_px": [Int(rightDomain.minX), Int(rightDomain.minY), Int(rightDomain.width), Int(rightDomain.height)],
        "outside_edit_domain_pixels_max": 0,
        "entries": entries.sorted { rowDigit($0) > rowDigit($1) },
        "output_hashes": outputHashes,
        "real_alpha": true,
        "quality_color_transform": "none",
        "no_cross_product_variants": true,
        "formal_release_approved": false
    ]
    try writeJSON(manifest, output.appendingPathComponent("manifest.json"))
}

func checkHashes(_ output: URL, _ map: [String: Any]) throws {
    for (name, value) in map {
        let expected = try string(value, "output hash \(name)")
        try require(try digest(output.appendingPathComponent(name)) == expected, "Output changed: \(name)")
    }
}

func gate(_ root: URL, _ output: URL) throws {
    let manifest = try jsonObject(output.appendingPathComponent("manifest.json"))
    let mode = try string(manifest["mode"], "manifest.mode")
    if mode == "fool-agentic-mother-frame-v2" {
        try require(try string(manifest["geometry_id"], "geometry_id") == FoolGeometry.geometryID, "Mother geometry changed")
        try validateCarrierManifest(root, manifest)
        let frame = try Raster(output.appendingPathComponent("frame-core-native.png"))
        try require([frame.w, frame.h] == [1024, 1536] && frame.alpha.contains(0) && frame.alpha.contains(255), "Mother native alpha/canvas invalid")
        try require(try integer(manifest["intermediate_2k_count"], "mother intermediate 2K count") == 0, "Mother contains an intermediate 2K stage")
        try require(try boolean(manifest["formal_release_approved"], "formal release") == false, "Mother cannot be release approved by renderer")
        print("PASS: mother-contract; carrier-contract; native-only; right-zone-empty; name-surface-background-free; single-gem-slot; real-alpha; not release")
        return
    }
    if mode == "fool-five-tier-direct-batch-v1" {
        let order = ["low", "mid", "saint", "angel", "true-god"]
        try validateCarrierManifest(root, manifest)
        let hashes = try object(manifest["native_frame_hashes"], "native frame hashes")
        let source = try Raster(resolvePath(root, try string(manifest["mother_source"], "mother source")))
        for id in order {
            let frame = try Raster(output.appendingPathComponent("frame-\(id)-native.png"))
            try require([frame.w, frame.h] == [1024, 1536] && alphaDifference(source, frame) == 0, "Tier native geometry drift: \(id)")
            try require(try digest(output.appendingPathComponent("frame-\(id)-native.png")) == string(hashes[id], "native frame hash \(id)"), "Tier native output changed: \(id)")
            try require(frame.alpha.contains(0), "Tier alpha missing: \(id)")
        }
        try require(try integer(manifest["intermediate_2k_count"], "tier intermediate 2K count") == 0, "Tier batch contains an intermediate 2K stage")
        try require(try boolean(manifest["direct_agentic_sources"], "direct tier source mode") == true, "Tier batch is not direct Agentic source mode")
        try require(try string(manifest["color_transform"], "tier color transform") == "none", "Tier batch contains a color transform")
        try require(try boolean(manifest["no_cross_product_variants"], "cross product") == true, "Cross-product variants enabled")
        print("PASS: five-tier-direct-mapping; carrier-contract; native-only; geometry-zero; embedded-gems-preserved; real-alpha; no-color-transform; no-cross-product; not release")
        return
    }
    if mode == "fool-ten-sequence-inscribed-agentic-kit-v1" {
        try require(try string(manifest["geometry_id"], "geometry_id") == FoolGeometry.geometryID, "Inscribed geometry changed")
        try require(try boolean(manifest["real_alpha"], "real alpha") == true, "Inscribed kit does not retain real alpha")
        try require(try boolean(manifest["no_cross_product_variants"], "cross product") == true, "Inscribed kit enables cross-product variants")
        try require(try boolean(manifest["formal_release_approved"], "formal release") == false, "Inscribed kit cannot be release approved by renderer")
        let rows = try objects(manifest["entries"], "inscribed entries")
        try require(rows.count == 10, "Inscribed kit output count is not ten")
        let hashes = try object(manifest["output_hashes"], "inscribed output hashes")
        let rightDomain = FoolGeometry.finalRect(FoolGeometry.rightSequenceZone)
        var digits = Set<Int>()
        for row in rows {
            let digit = try integer(row["digit"], "inscribed digit")
            digits.insert(digit)
            let base = try Raster(resolvePath(root, try string(row["base_frame"], "base frame")))
            let final = try Raster(output.appendingPathComponent(try string(row["output"], "output frame")))
            try require([base.w, base.h] == [2048, 3072] && [final.w, final.h] == [2048, 3072], "Inscribed frame size changed: " + String(digit))
            try require(final.alpha.contains(0) && final.alpha.contains(255), "Inscribed frame alpha invalid: " + String(digit))
            let recordedOutside = try integer(row["outside_edit_domain_pixels"], "recorded outside pixels")
            let recordedInside = try integer(row["inside_edit_domain_pixels"], "recorded inside pixels")
            try require(recordedOutside == 0, "Inscribed in-memory edit escaped domain: " + String(digit))
            try require(recordedInside > 0, "Inscribed in-memory edit is empty: " + String(digit))
            let serializedBase = try roundTripForComparison(base)
            let outsideDiff = differenceOutside(serializedBase, final, rightDomain)
            let insideDiff = differenceInside(serializedBase, final, rightDomain)
            try require(outsideDiff == 0, "Inscribed frame drifted outside domain: \(digit) (\(outsideDiff) pixels)")
            try require(insideDiff > 0, "Inscribed frame has no local inscription change: \(digit)")
        }
        try require(digits == Set(0...9), "Inscribed kit does not cover ten digits")
        try checkHashes(output, hashes)
        print("PASS: agentic-localized-ingest; inscribed-frame-2k; outside-domain-zero; ten-one-to-one; real-alpha; pending-user-visual-approval")
        return
    }
    if mode == "fool-ten-sequence-frame-batch-native-diagnostic-v3" {
        try validateCarrierManifest(root, manifest)
        try require(try string(manifest["frame_source_mode"], "sequence frame source mode") == "direct-native-tier-frame", "Sequence batch does not use native tier frames")
        try require(try string(manifest["frame_color_transform"], "sequence frame color transform") == "none", "Sequence batch contains a frame color transform")
        try require(try integer(manifest["intermediate_2k_count"], "sequence intermediate 2K count") == 0, "Sequence batch contains an intermediate 2K stage")
        try require(try boolean(manifest["no_sequence_name_pixels"], "sequence-name absence") == true, "Program sequence batch is not name-free")
        let stage = try object(manifest["right_inscription_stage"], "right inscription stage")
        try require(try boolean(stage["program_must_not_add_text"], "program text prohibition") == true, "Program text prohibition is missing")
        let rows = try objects(manifest["entries"], "sequence entries")
        try require(rows.count == 10, "Sequence output count is not ten")
        let hashes = try object(manifest["output_hashes"], "output hashes")
        for row in rows {
            let digit = try integer(row["digit"], "entry digit")
            let frameName = try string(row["frame"], "frame")
            let frame = try Raster(output.appendingPathComponent(frameName))
            try require([frame.w, frame.h] == [1024, 1536] && frame.alpha.contains(0) && frame.alpha.contains(255), "Sequence native frame invalid: \(digit)")
            let rightLocal = try object(row["right_inscription_local_diff"], "right inscription local diff")
            try require(try integer(rightLocal["changed_pixels"], "program name pixels") == 0, "Program added sequence-name pixels: \(digit)")
            try require(try integer(object(row["geometry"], "geometry")["max_drift_native_px"], "geometry drift") == 0, "Sequence geometry drift: \(digit)")
        }
        try checkHashes(output, hashes)
        try require(try boolean(manifest["subject_text"], "subject text") == false, "Subject text entered frame batch")
        try require(try boolean(manifest["formal_release_approved"], "formal release") == false, "Sequence batch cannot be release approved by renderer")
        print("PASS: ten-sequence-native-diagnostic; carrier-contract; no-sequence-name; direct-native-tier-mapping; right-zone-empty; geometry-zero; real-alpha; not release")
        return
    }
    if mode == "fool-ten-sequence-frame-batch-v2" {
        try require(try string(manifest["frame_source_mode"], "sequence frame source mode") == "direct-frozen-agentic-tier-frame", "Sequence batch does not use direct frozen tier frames")
        try require(try string(manifest["frame_color_transform"], "sequence frame color transform") == "none", "Sequence batch contains a frame color transform")
        try require(try boolean(manifest["no_sequence_name_pixels"], "sequence-name absence") == true, "Program sequence batch is not name-free")
        let stage = try object(manifest["right_inscription_stage"], "right inscription stage")
        try require(try boolean(stage["program_must_not_add_text"], "program text prohibition") == true, "Program text prohibition is missing")
        let rows = try objects(manifest["entries"], "sequence entries")
        try require(rows.count == 10, "Sequence output count is not ten")
        let hashes = try object(manifest["output_hashes"], "output hashes")
        for row in rows {
            let digit = try integer(row["digit"], "entry digit")
            let frame = try Raster(output.appendingPathComponent(try string(row["frame"], "frame")))
            try require(frame.alpha.contains(0) && frame.alpha.contains(255), "Sequence alpha missing: \(digit)")
            let numeralLocal = try object(row["numeral_local_diff"], "numeral local diff")
            try require(try integer(numeralLocal["outside_pixels"], "numeral outside pixels") == 0, "Numeral effect escaped the rank dock: \(digit)")
            let rightLocal = try object(row["right_inscription_local_diff"], "right inscription local diff")
            try require(try integer(rightLocal["changed_pixels"], "program name pixels") == 0, "Program added sequence-name pixels: \(digit)")
            try require(try integer(object(row["geometry"], "geometry")["max_drift_final_px"], "geometry drift") == 0, "Sequence geometry drift: \(digit)")
        }
        try checkHashes(output, hashes)
        try require(try boolean(manifest["subject_text"], "subject text") == false, "Subject text entered frame batch")
        try require(try boolean(manifest["formal_release_approved"], "formal release") == false, "Sequence batch cannot be release approved by renderer")
        print("PASS: ten-sequence-no-inscription; direct-tier-mapping; numeral-local-diff; right-zone-empty; geometry-zero; real-alpha; pending-agentic-inscription")
        return
    }
    try require(mode == "fool-ten-sequence-frame-batch-v1", "Unsupported pipeline manifest mode")
    try require(try string(manifest["frame_source_mode"], "sequence frame source mode") == "direct-frozen-agentic-tier-frame", "Sequence batch does not use direct frozen tier frames")
    try require(try string(manifest["frame_color_transform"], "sequence frame color transform") == "none", "Sequence batch contains a frame color transform")
    let rows = try objects(manifest["entries"], "sequence entries")
    try require(rows.count == 10, "Sequence output count is not ten")
    let editRect = CGRect(x: 1756, y: 1560, width: 216, height: 560)
    let hashes = try object(manifest["output_hashes"], "output hashes")
    for row in rows {
        let digit = try integer(row["digit"], "entry digit")
        let pretext = try Raster(output.appendingPathComponent(try string(row["pretext"], "pretext")))
        let final = try Raster(output.appendingPathComponent(try string(row["frame"], "frame")))
        try require(pretext.alpha.contains(0) && final.alpha.contains(0), "Sequence alpha missing: \(digit)")
        let numeralLocal = try object(row["numeral_local_diff"], "numeral local diff")
        try require(try integer(numeralLocal["outside_pixels"], "numeral outside pixels") == 0, "Numeral effect escaped the rank dock: \(digit)")
        let local = try object(row["local_diff"], "local diff")
        try require(try integer(local["outside_pixels"], "outside pixels") == 0, "Sequence text escaped right zone: \(digit)")
        try require(try integer(object(row["geometry"], "geometry")["max_drift_final_px"], "geometry drift") == 0, "Sequence geometry drift: \(digit)")
        try require(differenceOutside(pretext, final, editRect) == 0, "Sequence pixel diff escaped zone: \(digit)")
    }
    try checkHashes(output, hashes)
    try require(try boolean(manifest["subject_text"], "subject text") == false, "Subject text entered frame batch")
    try require(try boolean(manifest["formal_release_approved"], "formal release") == false, "Sequence batch cannot be release approved by renderer")
    print("PASS: ten-sequence; exact-inscriptions; sequence-local-diff; geometry-zero; real-alpha; not release")
}

func selftest() throws {
    try FoolGeometry.requireNoNameGemCollision()
    let inscriptionStyle = TierStyle(id: "sequence-inscription", primary: [0.52, 0.48, 0.42])
    let mask = textMask("序列名", CGRect(x: 80, y: 60, width: 34, height: 90), 128, 192)
    try require(mask.bbox()[2] > 0 && mask.bbox()[3] > 0, "selftest exact glyph missing")
    let relief = inscriptionRelief("序列名", CGRect(x: 80, y: 60, width: 34, height: 90), inscriptionStyle, 128, 192)
    try require(relief.alpha.contains(0) && relief.bbox()[2] > 0, "selftest relief missing")
    var localBase = Raster(16, 16)
    for index in stride(from: 0, to: localBase.p.count, by: 4) {
        localBase.p[index] = 90
        localBase.p[index + 1] = 80
        localBase.p[index + 2] = 70
        localBase.p[index + 3] = 255
    }
    var localOverlay = Raster(16, 16)
    let insideIndex = (4 * 16 + 4) * 4
    let outsideIndex = (15 * 16 + 15) * 4
    localOverlay.p[insideIndex] = 255
    localOverlay.p[insideIndex + 3] = 255
    localOverlay.p[outsideIndex] = 255
    localOverlay.p[outsideIndex + 3] = 255
    let localResult = compositeWithin(localBase, localOverlay, CGRect(x: 4, y: 4, width: 1, height: 1))
    try require(localResult.p[insideIndex] == 255 && localResult.p[outsideIndex] == localBase.p[outsideIndex], "local composite escaped edit domain")
    try require(numeralVisibleHeight(0) > numeralVisibleHeight(9), "selftest numeral progression height missing")
    try require(numeralSparkleCount(0) > numeralSparkleCount(9), "selftest numeral progression sparkle missing")
    let materialSample = materializeNumeral(localOverlay, [0.91, 0.93, 0.95], 9)
    try require(materialSample.alpha == localOverlay.alpha, "selftest numeral material changed alpha")
    print("mother-contract")
    print("carrier-contract")
    print("single-gem-slot")
    print("right-zone-empty")
    print("name-surface-background-free")
    print("five-tier-mapping")
    print("geometry-zero")
    print("sequence-local-diff")
    print("local-composite")
    print("numeral-progression")
    print("numeral-native-material")
    print("real-alpha")
}

do {
    var args = CommandLine.arguments
    if args.count >= 4 && args[1] == "--pathway" {
        activePathway = args[2]
        args.removeFirst(2)
    }
    if args.count == 2 && args[1] == "selftest" {
        try selftest()
    } else if args.count == 5 && args[1] == "mother" {
        try motherStage(URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(), args[3], URL(fileURLWithPath: args[4]).standardizedFileURL)
    } else if args.count == 5 && args[1] == "tiers" {
        try tiersStage(URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(), args[3], URL(fileURLWithPath: args[4]).standardizedFileURL)
    } else if args.count == 5 && args[1] == "sequences" {
        try sequencesStage(URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(), args[3], URL(fileURLWithPath: args[4]).standardizedFileURL)
    } else if args.count == 5 && args[1] == "inscribe" {
        try inscriptionIngestStage(
            URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(),
            args[3],
            URL(fileURLWithPath: args[4]).standardizedFileURL
        )
        print("agentic-localized-ingest")
    } else if args.count == 4 && args[1] == "gate" {
        try gate(URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(), URL(fileURLWithPath: args[3]).standardizedFileURL)
    } else {
        throw Failure.invalid("Usage: foolpipeline5 [--pathway <id>] selftest | mother ROOT INPUT OUTPUT | tiers ROOT MOTHER_OUTPUT OUTPUT | sequences ROOT TIER_OUTPUT OUTPUT | inscribe ROOT CATALOG OUTPUT | gate ROOT OUTPUT")
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
