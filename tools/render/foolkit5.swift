// Deterministic, non-destructive preparation of the active Fool five-tier kit.
// Agentic material studies may inform the recipe, but this renderer owns geometry,
// alpha, placement and release gates.
import AppKit
import CryptoKit

enum Failure: Error { case invalid(String) }

func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw Failure.invalid(message) }
}

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

struct Raster {
    var w: Int
    var h: Int
    var p: [UInt8] // straight RGBA, row-major in image coordinates

    init(_ w: Int, _ h: Int) {
        self.w = w
        self.h = h
        p = .init(repeating: 0, count: w * h * 4)
    }

    init(_ url: URL) throws {
        guard let rep = NSBitmapImageRep(data: try Data(contentsOf: url)),
              let image = rep.cgImage else {
            throw Failure.invalid("Cannot decode \(url.path)")
        }
        self.init(image.width, image.height)
        p.withUnsafeMutableBytes { bytes in
            let context = CGContext(
                data: bytes.baseAddress,
                width: w,
                height: h,
                bitsPerComponent: 8,
                bytesPerRow: w * 4,
                space: srgb,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )!
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        for i in stride(from: 0, to: p.count, by: 4) {
            let a = Int(p[i + 3])
            if a > 0 {
                for c in 0..<3 { p[i + c] = UInt8(min(255, Int(p[i + c]) * 255 / a)) }
            }
        }
    }

    var image: CGImage {
        var bytes = p
        for i in stride(from: 0, to: bytes.count, by: 4) {
            for c in 0..<3 { bytes[i + c] = UInt8(Int(bytes[i + c]) * Int(bytes[i + 3]) / 255) }
        }
        return CGImage(
            width: w,
            height: h,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: w * 4,
            space: srgb,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: Data(bytes) as CFData)!,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )!
    }

    func save(_ url: URL) throws {
        try require(!FileManager.default.fileExists(atPath: url.path), "Refusing overwrite: \(url.path)")
        let rep = NSBitmapImageRep(cgImage: image)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw Failure.invalid("Cannot encode \(url.path)")
        }
        try data.write(to: url, options: .withoutOverwriting)
    }

    var alpha: [UInt8] { stride(from: 3, to: p.count, by: 4).map { p[$0] } }

    var bbox: [Int] {
        var x0 = w
        var y0 = h
        var x1 = -1
        var y1 = -1
        for y in 0..<h {
            for x in 0..<w where p[(y * w + x) * 4 + 3] > 8 {
                x0 = min(x0, x)
                y0 = min(y0, y)
                x1 = max(x1, x)
                y1 = max(y1, y)
            }
        }
        return x1 < 0 ? [0, 0, 0, 0] : [x0, y0, x1 - x0 + 1, y1 - y0 + 1]
    }
}

func sha(_ data: Data) -> String {
    SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

func digest(_ url: URL) throws -> String { sha(try Data(contentsOf: url)) }

func within(_ root: URL, _ relative: String) throws -> URL {
    try require(
        !relative.hasPrefix("/") && !relative.split(separator: "/").contains(".."),
        "Unsafe relative path: \(relative)"
    )
    let base = root.resolvingSymlinksInPath()
    let file = base.appendingPathComponent(relative).resolvingSymlinksInPath()
    try require(file.path.hasPrefix(base.path + "/"), "Escaping path: \(relative)")
    return file
}

func jsonObject(_ url: URL) throws -> [String: Any] {
    guard let value = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] else {
        throw Failure.invalid("Expected JSON object: \(url.path)")
    }
    return value
}

func dictionary(_ value: Any?, _ label: String) throws -> [String: Any] {
    guard let value = value as? [String: Any] else { throw Failure.invalid("Expected object: \(label)") }
    return value
}

func dictionaries(_ value: Any?, _ label: String) throws -> [[String: Any]] {
    guard let values = value as? [Any] else { throw Failure.invalid("Expected object array: \(label)") }
    return try values.enumerated().map { index, value in
        try dictionary(value, "\(label)[\(index)]")
    }
}

func text(_ object: [String: Any], _ key: String) throws -> String {
    guard let value = object[key] as? String, !value.isEmpty else {
        throw Failure.invalid("Missing text \(key)")
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

func flag(_ value: Any?, _ label: String) throws -> Bool {
    guard let value = value as? Bool else { throw Failure.invalid("Expected boolean: \(label)") }
    return value
}

func integers(_ value: Any?, _ label: String) throws -> [Int] {
    guard let values = value as? [Any] else { throw Failure.invalid("Expected integer array: \(label)") }
    return try values.enumerated().map { try integer($0.element, "\(label)[\($0.offset)]") }
}

func reals(_ value: Any?, _ label: String) throws -> [Double] {
    guard let values = value as? [Any] else { throw Failure.invalid("Expected number array: \(label)") }
    return try values.enumerated().map { try real($0.element, "\(label)[\($0.offset)]") }
}

func hexColor(_ value: String) throws -> [Double] {
    let raw = String(value.dropFirst())
    try require(value.hasPrefix("#") && raw.count == 6, "Invalid color: \(value)")
    guard let number = Int(raw, radix: 16) else { throw Failure.invalid("Invalid color: \(value)") }
    return [
        Double((number >> 16) & 0xff) / 255.0,
        Double((number >> 8) & 0xff) / 255.0,
        Double(number & 0xff) / 255.0,
    ]
}

func clamp(_ value: Double) -> Double { max(0, min(1, value)) }

// Remove large neutral connected regions, including enclosed numeral/eye holes.
// Small neutral islands remain as specular highlights. This is a recorded matte,
// not a claim that the generated artwork has native transparency.
func cutout(
    _ source: Raster,
    tolerance: Int = 7,
    minRegion: Int = 1000,
    minNeutral: Int = 55,
    seeds: [[Int]] = []
) -> Raster {
    var result = source
    var visited = [Bool](repeating: false, count: source.w * source.h)
    let forced = Set(
        seeds.filter { $0.count == 2 && $0[0] >= 0 && $0[0] < source.w && $0[1] >= 0 && $0[1] < source.h }
            .map { $0[1] * source.w + $0[0] }
    )

    func neutral(_ index: Int) -> Bool {
        let i = index * 4
        let rgb = [Int(source.p[i]), Int(source.p[i + 1]), Int(source.p[i + 2])]
        return rgb.max()! - rgb.min()! <= tolerance && rgb.min()! >= minNeutral
    }

    for seed in 0..<visited.count where !visited[seed] && neutral(seed) {
        var queue = [seed]
        var cursor = 0
        visited[seed] = true
        while cursor < queue.count {
            let v = queue[cursor]
            cursor += 1
            let x = v % source.w
            let y = v / source.w
            let neighbors = [
                x > 0 ? v - 1 : -1,
                x + 1 < source.w ? v + 1 : -1,
                y > 0 ? v - source.w : -1,
                y + 1 < source.h ? v + source.w : -1,
            ]
            for n in neighbors where n >= 0 && !visited[n] && neutral(n) {
                visited[n] = true
                queue.append(n)
            }
        }
        let border = queue.contains {
            $0 % source.w == 0 || $0 % source.w == source.w - 1 ||
                $0 / source.w == 0 || $0 / source.w == source.h - 1
        }
        let dark = queue.contains { source.p[$0 * 4] < 210 }
        if queue.contains(where: { forced.contains($0) }) ||
            (queue.count >= minRegion && (border || dark || queue.count > 8000)) {
            for v in queue { result.p[v * 4 + 3] = 0 }
        }
    }
    return result
}

// Strip the generated atmosphere from the frozen mother while retaining its
// exact source coordinates and silhouette alpha relationship.
func frameBody(_ source: Raster) -> Raster {
    var result = source
    for i in stride(from: 3, to: result.p.count, by: 4) {
        result.p[i] = UInt8(max(0, min(255, (Int(source.p[i]) - 128) * 255 / 102)))
    }
    return result
}

func materialRegion(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> Int {
    let designX = Double(x) * 1024.0 / Double(w)
    let designY = Double(y) * 1536.0 / Double(h)
    if abs(designX - 512) / 39.0 + abs(designY - 1429) / 40.0 <= 1 { return 4 }
    if designY >= 1250 { return 3 }
    if designY < 350 { return x < w / 2 ? 0 : 1 }
    return 2
}

struct MaterialMasks {
    let regions: [UInt8]
}

func makeMasks(_ source: Raster) -> MaterialMasks {
    var regions = [UInt8](repeating: 255, count: source.w * source.h)
    for y in 0..<source.h {
        for x in 0..<source.w {
            let index = y * source.w + x
            if source.p[index * 4 + 3] > 0 { regions[index] = UInt8(materialRegion(x, y, source.w, source.h)) }
        }
    }
    return MaterialMasks(regions: regions)
}

struct TierSpec {
    let id: String
    let sequences: [Int]
    let primary: [Double]
    let gem: [Double]
    let surfaceBlend: Double
    let contrast: Double
    let highlight: Double
    let pathwayStrength: Double
    let hueDriftEnabled: Bool
    let gemLuminanceEnabled: Bool
}

func tierParameters(_ id: String) throws -> (Double, Double, Double, Double) {
    switch id {
    case "low": return (0.18, 0.04, 0.04, 0.80)
    case "mid": return (0.42, 0.10, 0.08, 0.80)
    case "saint": return (0.56, 0.15, 0.12, 0.80)
    case "angel": return (0.67, 0.20, 0.16, 0.80)
    case "true-god": return (0.78, 0.26, 0.21, 0.80)
    default: throw Failure.invalid("Unknown five-tier id: \(id)")
    }
}

func fixedMaterial(_ source: Raster, tier: TierSpec, masks: MaterialMasks) -> Raster {
    var result = source
    for y in 0..<source.h {
        for x in 0..<source.w {
            let index = y * source.w + x
            let i = index * 4
            if source.p[i + 3] == 0 { continue }
            let base = (0..<3).map { Double(source.p[i + $0]) / 255.0 }
            let luminance = 0.2126 * base[0] + 0.7152 * base[1] + 0.0722 * base[2]
            let region = Int(masks.regions[index])
            let violet = base[2] > base[1] * 1.08 && base[0] > base[1] * 1.05

            for c in 0..<3 {
                var value: Double
                if region == 4 {
                    // Keep dark crystal body, colored interior refraction and a
                    // local facet highlight together; no white clipping blanket.
                    let darkBody = 0.32 + 0.58 * luminance
                    let facet = max(0, luminance - 0.62) * (0.26 + tier.highlight)
                    value = tier.gem[c] * darkBody + facet * (0.34 + tier.gem[c] * 0.56)
                } else if violet {
                    // The Fool identity remains in the recessed violet channels;
                    // the configured tier color enters as a controlled reflection.
                    let violetBase = [0.20, 0.10, 0.29][c]
                    let colorShare = 0.12 + tier.surfaceBlend * 0.28
                    let target = violetBase * (1 - colorShare) + tier.primary[c] * colorShare
                    value = base[c] * (1 - tier.pathwayStrength) + target * tier.pathwayStrength
                } else {
                    let relief = 0.72 + luminance * 0.42
                    let target = tier.primary[c] * relief
                    value = base[c] * (1 - tier.surfaceBlend) + target * tier.surfaceBlend
                }

                // Deterministic relief-driven hue drift. It is local surface
                // variation, not a coordinate or anchor offset.
                if tier.hueDriftEnabled {
                    let wave = (sin(Double(x) * 0.037 + Double(y) * 0.019) + 1) * 0.5
                    let drift = (wave - 0.5) * 0.045 * (0.55 + luminance)
                    if c == 0 { value += drift * 0.55 }
                    if c == 1 { value -= drift * 0.18 }
                    if c == 2 { value += drift * 0.85 }
                }
                value = (value - 0.5) * (1 + tier.contrast) + 0.5
                let specular = max(0, luminance - 0.70) * tier.highlight
                value += specular * (0.30 + tier.primary[c] * 0.70)
                result.p[i + c] = UInt8((clamp(value) * 255.0).rounded())
            }
        }
    }
    return result
}

func geometryDifference(_ lhs: Raster, _ rhs: Raster) throws -> Int {
    try require(lhs.w == rhs.w && lhs.h == rhs.h, "Geometry canvas mismatch")
    return zip(lhs.alpha, rhs.alpha).filter { $0 != $1 }.count
}

func render(_ layers: [(Raster, CGRect)], width: Int, height: Int, background: Bool = false) -> Raster {
    var result = Raster(width, height)
    result.p.withUnsafeMutableBytes { bytes in
        let context = CGContext(
            data: bytes.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: srgb,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        if background {
            context.setFillColor(CGColor(srgbRed: 0.035, green: 0.045, blue: 0.075, alpha: 1))
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        context.interpolationQuality = .high
        for (raster, rect) in layers {
            let converted = CGRect(
                x: rect.minX,
                y: CGFloat(height) - rect.maxY,
                width: rect.width,
                height: rect.height
            )
            context.draw(raster.image, in: converted)
        }
    }
    for i in stride(from: 0, to: result.p.count, by: 4) {
        let a = Int(result.p[i + 3])
        if a > 0 {
            for c in 0..<3 { result.p[i + c] = UInt8(min(255, Int(result.p[i + c]) * 255 / a)) }
        }
    }
    return result
}

struct GeometrySpec {
    let nativeSize: [Int]
    let finalSize: [Int]
    let designSize: [Double]
    let emblemCenterDesign: [Double]
    let emblemVisibleHeightRatio: Double
}

func placementRect(_ emblem: Raster, _ geometry: GeometrySpec, _ sequence: Int) throws -> CGRect {
    try require((0...9).contains(sequence), "Invalid sequence placement: \(sequence)")
    let bbox = emblem.bbox
    try require(bbox[3] > 0 && emblem.alpha.contains(0), "Emblem has no transparent boundary: \(sequence)")
    let finalW = Double(geometry.finalSize[0])
    let finalH = Double(geometry.finalSize[1])
    let designW = geometry.designSize[0]
    let designH = geometry.designSize[1]
    let centerX = finalW * geometry.emblemCenterDesign[0] / designW
    let centerY = finalH * geometry.emblemCenterDesign[1] / designH
    let visibleHeight = finalH * geometry.emblemVisibleHeightRatio
    let scale = visibleHeight / Double(bbox[3])
    return CGRect(
        x: centerX - Double(bbox[0]) * scale - Double(bbox[2]) * scale / 2,
        y: centerY - Double(bbox[1]) * scale - Double(bbox[3]) * scale / 2,
        width: Double(emblem.w) * scale,
        height: Double(emblem.h) * scale
    )
}

func sequenceLayers(frame: Raster, emblem: Raster, sequence: Int, geometry: GeometrySpec) throws -> [(Raster, CGRect)] {
    let rect = try placementRect(emblem, geometry, sequence)
    return [
        (frame, CGRect(x: 0, y: 0, width: geometry.finalSize[0], height: geometry.finalSize[1])),
        (emblem, rect),
    ]
}

func renderSequenceFrame(frame: Raster, emblem: Raster, sequence: Int, geometry: GeometrySpec) throws -> Raster {
    render(
        try sequenceLayers(frame: frame, emblem: emblem, sequence: sequence, geometry: geometry),
        width: geometry.finalSize[0],
        height: geometry.finalSize[1]
    )
}

struct EmblemInput {
    let digit: Int
    let url: URL
    let path: String
    let hash: String
    let seeds: [[Int]]
    let minNeutral: Int
}

struct Kit {
    let catalogURL: URL
    let recipeURL: URL
    let recipeHash: String
    let masterURL: URL
    let masterHash: String
    let body: Raster
    let masks: MaterialMasks
    let styles: [String: TierSpec]
    let mapping: [String: [Int]]
    let geometry: GeometrySpec
    let emblems: [EmblemInput]
    let inputHashes: [String: String]
}

func dependency(_ root: URL, _ value: Any?, _ label: String) throws -> (URL, String) {
    let object = try dictionary(value, label)
    let path = try text(object, "path")
    let expected = try text(object, "sha256")
    let url = try within(root, path)
    try require(FileManager.default.fileExists(atPath: url.path), "Missing dependency: \(path)")
    try require(try digest(url) == expected, "Stale dependency: \(path)")
    return (url, expected)
}

func parseMapping(_ value: Any?) throws -> [String: [Int]] {
    let object = try dictionary(value, "sequence_mapping")
    let keys = ["low", "mid", "saint", "angel", "true-god"]
    var result = [String: [Int]]()
    for key in keys { result[key] = try integers(object[key], "sequence_mapping.\(key)") }
    let expected: [String: [Int]] = [
        "low": [9, 8],
        "mid": [7, 6, 5],
        "saint": [4, 3],
        "angel": [2, 1],
        "true-god": [0],
    ]
    try require(result == expected, "Five-tier mapping is not exact")
    return result
}

func qualityTier(for sequence: Int, mapping: [String: [Int]]) throws -> String {
    try require((0...9).contains(sequence), "Invalid sequence: \(sequence)")
    let matches = mapping.filter { $0.value.contains(sequence) }.map { $0.key }
    try require(matches.count == 1 && matches.first != "high", "Missing or ambiguous five-tier sequence")
    return matches[0]
}

func loadKit(_ root: URL) throws -> Kit {
    let catalogURL = try within(root, "production/symbols/fool-five-tier-kit.json")
    let catalog = try jsonObject(catalogURL)
    try require(try text(catalog, "version") == "2.0.0", "Unsupported five-tier catalog version")

    let direction = try dependency(root, catalog["direction"], "direction")
    let geometry = try dependency(root, catalog["geometry_lock"], "geometry_lock")
    let colors = try dependency(root, catalog["color_tokens"], "color_tokens")
    let hierarchy = try dependency(root, catalog["sequence_hierarchy"], "sequence_hierarchy")
    let matte = try dependency(root, catalog["matte"], "matte")
    let recipe = try dependency(root, catalog["recipe"], "recipe")

    let directionObject = try jsonObject(direction.0)
    try require(try text(directionObject, "geometry_id") == "fool-quality-frame-locked-master-v1", "Direction geometry mismatch")
    let directionMaster = try dictionary(directionObject["master"], "direction.master")
    let master = try dependency(root, directionMaster, "direction.master")
    let masterRaster = try Raster(master.0)
    try require([masterRaster.w, masterRaster.h] == [1024, 1536], "Frozen master size changed")

    let geometryObject = try jsonObject(geometry.0)
    let geometryMaster = try dictionary(geometryObject["master"], "geometry.master")
    try require(try text(geometryMaster, "sha256") == master.1, "Geometry lock master mismatch")

    let colorObject = try jsonObject(colors.0)
    let application = try dictionary(colorObject["application"], "color.application")
    let hueDrift = try dictionary(application["hue_drift"], "color.application.hue_drift")
    let gemLuminance = try dictionary(application["gem_luminance"], "color.application.gem_luminance")
    let hueEnabled = try flag(hueDrift["enabled"], "color hue drift")
    _ = try text(hueDrift, "meaning")
    _ = try text(gemLuminance, "intent")
    let gemEnabled = true
    try require(hueEnabled && gemEnabled, "Color config lacks active hue/gem rules")

    let tierRows = try dictionaries(colorObject["tiers"], "color.tiers")
    var styles = [String: TierSpec]()
    for row in tierRows {
        let id = try text(row, "id")
        let sequences = try integers(row["sequences"], "color.tiers.\(id).sequences")
        let primary = try hexColor(try text(row, "primary"))
        let params = try tierParameters(id)
        let gem = primary.map { clamp($0 * 1.08 + 0.01) }
        styles[id] = TierSpec(
            id: id,
            sequences: sequences,
            primary: primary,
            gem: gem,
            surfaceBlend: params.0,
            contrast: params.1,
            highlight: params.2,
            pathwayStrength: params.3,
            hueDriftEnabled: hueEnabled,
            gemLuminanceEnabled: gemEnabled
        )
    }
    try require(Set(styles.keys) == Set(["low", "mid", "saint", "angel", "true-god"]), "Tier color config is incomplete")

    let mapping = try parseMapping(catalog["sequence_mapping"])
    for id in mapping.keys { try require(styles[id]!.sequences == mapping[id]!, "Color/mapping mismatch: \(id)") }

    let recipeObject = try jsonObject(recipe.0)
    try require(try text(recipeObject, "geometry_id") == "fool-quality-frame-locked-master-v1", "Recipe geometry mismatch")
    let recipeMapping = try parseMapping(recipeObject["tier_sequence_mapping"])
    try require(recipeMapping == mapping, "Recipe/catalog mapping mismatch")
    let recipeGeometry = try dictionary(recipeObject["geometry"], "recipe.geometry")
    let nativeSize = try integers(recipeGeometry["native_size"], "recipe.geometry.native_size")
    let finalSize = try integers(recipeGeometry["final_size"], "recipe.geometry.final_size")
    let fullDesignRect = try reals(recipeGeometry["design_rect"], "recipe.geometry.design_rect")
    let designDimensions = Array(fullDesignRect.dropFirst(2))
    let center = try reals(recipeGeometry["emblem_center_design"], "recipe.geometry.emblem_center_design")
    let ratio = try real(recipeGeometry["emblem_visible_height_ratio"], "recipe.geometry.emblem_visible_height_ratio")
    try require(nativeSize == [1024, 1536] && finalSize == [2048, 3072], "Recipe canvas size mismatch")
    try require(designDimensions == [1000, 1500] && center == [500, 230] && ratio > 0 && ratio < 0.5, "Recipe geometry placement mismatch")
    let geometrySpec = GeometrySpec(
        nativeSize: nativeSize,
        finalSize: finalSize,
        designSize: designDimensions,
        emblemCenterDesign: center,
        emblemVisibleHeightRatio: ratio
    )

    let matteObject = try jsonObject(matte.0)
    let matteSize = try integers(matteObject["source_size"], "matte.source_size")
    let matteEntries = try dictionary(matteObject["entries"], "matte.entries")
    var emblems = [EmblemInput]()
    var inputHashes: [String: String] = [
        "production/symbols/fool-five-tier-kit.json": try digest(catalogURL),
        "production/symbols/quality-frame-five-tier-direction.json": direction.1,
        "production/symbols/quality-geometry-lock.json": geometry.1,
        "config/quality-color-tokens.json": colors.1,
        "config/sequence-hierarchy.json": hierarchy.1,
        "production/symbols/fool-kit-matte.json": matte.1,
        "production/symbols/recipes/fool-five-tier-materials.json": recipe.1,
    ]
    for row in try dictionaries(catalog["emblem_inputs"], "emblem_inputs") {
        let digit = try integer(row["digit"], "emblem digit")
        let path = try text(row, "path")
        let expected = try text(row, "sha256")
        let url = try within(root, path)
        try require(try digest(url) == expected, "Emblem input changed: \(path)")
        let source = try Raster(url)
        try require([source.w, source.h] == matteSize, "Matte source size changed for \(digit)")
        let settings = try dictionary(matteEntries[String(digit)], "matte.entries.\(digit)")
        // JSON seed arrays are intentionally read separately to avoid accepting
        // arbitrary dictionary-shaped matte data.
        let rawSeeds: [[Int]]
        if let seedValues = settings["seeds"] as? [Any] {
            rawSeeds = try seedValues.enumerated().map { index, value in
                try integers(value, "matte.entries.\(digit).seeds[\(index)]")
            }
        } else {
            rawSeeds = []
        }
        let minimum = try settings["min_neutral"].map { try integer($0, "min_neutral") } ?? 55
        emblems.append(EmblemInput(digit: digit, url: url, path: path, hash: expected, seeds: rawSeeds, minNeutral: minimum))
        inputHashes[path] = expected
    }
    emblems.sort { $0.digit < $1.digit }
    try require(emblems.map { $0.digit } == Array(0...9), "Emblem inputs must cover 0-9 exactly")
    try require(try integers(catalog["approved_emblems"], "approved_emblems") == Array(0...9), "Approved emblem set is incomplete")
    let legacy = try dictionary(catalog["legacy_four_tier_status"], "legacy_four_tier_status")
    try require(!(try flag(legacy["active"], "legacy_four_tier_status.active")), "Legacy four-tier kit is active")

    return Kit(
        catalogURL: catalogURL,
        recipeURL: recipe.0,
        recipeHash: recipe.1,
        masterURL: master.0,
        masterHash: master.1,
        body: frameBody(masterRaster),
        masks: makeMasks(frameBody(masterRaster)),
        styles: styles,
        mapping: mapping,
        geometry: geometrySpec,
        emblems: emblems,
        inputHashes: inputHashes
    )
}

func writeJSON(_ value: Any, _ url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    try require(!FileManager.default.fileExists(atPath: url.path), "Refusing overwrite: (url.path)")
    try data.write(to: url, options: .withoutOverwriting)
}

func outputURL(_ root: URL, _ output: URL, _ name: String) -> URL {
    output.appendingPathComponent(name)
}

func prepare(_ root: URL, _ output: URL, _ mode: String) throws {
    let artifactBase = root.appendingPathComponent("artifacts/production").resolvingSymlinksInPath().path + "/"
    let resolvedOutput = output.standardizedFileURL
    try require(resolvedOutput.path.hasPrefix(artifactBase), "Output must be a new artifacts/production child")
    try require(!FileManager.default.fileExists(atPath: resolvedOutput.path), "Output already exists")
    try require(mode == "all" || mode == "sample", "Invalid prepare mode")
    let kit = try loadKit(root)
    try FileManager.default.createDirectory(at: resolvedOutput, withIntermediateDirectories: true)

    let tierOrder = ["low", "mid", "saint", "angel", "true-god"]
    var frameRasters = [String: Raster]()
    var frameFiles = [String]()
    for id in tierOrder {
        guard let style = kit.styles[id] else { throw Failure.invalid("Missing style \(id)") }
        let fixed = fixedMaterial(kit.body, tier: style, masks: kit.masks)
        try require(try geometryDifference(kit.body, fixed) == 0, "Native material changed frame geometry")
        let final = render(
            [(fixed, CGRect(x: 0, y: 0, width: kit.geometry.finalSize[0], height: kit.geometry.finalSize[1]))],
            width: kit.geometry.finalSize[0],
            height: kit.geometry.finalSize[1]
        )
        let file = "frame-\(id).png"
        try final.save(outputURL(root, resolvedOutput, file))
        frameRasters[id] = final
        frameFiles.append(file)
    }

    for region in 0...4 {
        var mask = Raster(kit.body.w, kit.body.h)
        for index in 0..<(kit.body.w * kit.body.h) {
            mask.p[index * 4] = 255
            mask.p[index * 4 + 1] = 255
            mask.p[index * 4 + 2] = 255
            mask.p[index * 4 + 3] = kit.masks.regions[index] == UInt8(region) ? kit.body.p[index * 4 + 3] : 0
        }
        try mask.save(outputURL(root, resolvedOutput, "structure-\(region).png"))
    }

    let selectedDigits = mode == "sample" ? [9] : Array(0...9)
    var emblemRasters = [Int: Raster]()
    var cardRasters = [Int: Raster]()
    var entries = [[String: Any]]()
    for digit in selectedDigits {
        guard let source = kit.emblems.first(where: { $0.digit == digit }) else {
            throw Failure.invalid("Missing emblem input \(digit)")
        }
        let clean = cutout(try Raster(source.url), minNeutral: source.minNeutral, seeds: source.seeds)
        try require(clean.bbox[3] > 0 && clean.alpha.contains(0), "Empty or opaque emblem \(digit)")
        try clean.save(outputURL(root, resolvedOutput, "emblem-\(digit).png"))
        emblemRasters[digit] = clean
        let tier = try qualityTier(for: digit, mapping: kit.mapping)
        guard let frame = frameRasters[tier] else { throw Failure.invalid("Missing frame (tier)") }
        let card = try renderSequenceFrame(frame: frame, emblem: clean, sequence: digit, geometry: kit.geometry)
        try card.save(outputURL(root, resolvedOutput, "fool-\(digit)-frame.png"))
        try render(
            try sequenceLayers(frame: frame, emblem: clean, sequence: digit, geometry: kit.geometry),
            width: kit.geometry.finalSize[0],
            height: kit.geometry.finalSize[1],
            background: true
        ).save(outputURL(root, resolvedOutput, "fool-\(digit)-preview.png"))
        cardRasters[digit] = card
        let rect = try placementRect(clean, kit.geometry, digit)
        entries.append([
            "digit": digit,
            "tier": tier,
            "source_bbox": clean.bbox,
            "visible_height_ratio": kit.geometry.emblemVisibleHeightRatio,
            "rect_px": [rect.minX, rect.minY, rect.width, rect.height],
            "geometry_difference_pixels": 0,
            "placement_basis": "independent-visible-ink-bbox",
        ])
    }

    var contactLayers = [(Raster, CGRect)]()
    for (index, digit) in selectedDigits.enumerated() {
        guard let card = cardRasters[digit] else { continue }
        contactLayers.append((card, CGRect(x: Double(index % 5) * 400 + 20, y: Double(index / 5) * 600 + 20, width: 360, height: 540)))
    }
    try render(contactLayers, width: 2000, height: mode == "sample" ? 600 : 1200, background: true)
        .save(outputURL(root, resolvedOutput, "contact-sheet.png"))

    let fiveLayers = tierOrder.enumerated().compactMap { index, id -> (Raster, CGRect)? in
        guard let frame = frameRasters[id] else { return nil }
        return (frame, CGRect(x: Double(index) * 500 + 10, y: 10, width: 480, height: 720))
    }
    try render(fiveLayers, width: 2500, height: 740, background: true)
        .save(outputURL(root, resolvedOutput, "five-tiers.png"))

    let white = Raster(2400, mode == "sample" ? 480 : 960)
    var whiteBase = white
    for i in stride(from: 0, to: whiteBase.p.count, by: 4) {
        whiteBase.p[i] = 255
        whiteBase.p[i + 1] = 255
        whiteBase.p[i + 2] = 255
        whiteBase.p[i + 3] = 255
    }
    var emblemLayers = [(Raster, CGRect)]()
    for (index, digit) in selectedDigits.enumerated() {
        guard let emblem = emblemRasters[digit] else { continue }
        emblemLayers.append((emblem, CGRect(x: Double(index % 5) * 480 + 20, y: Double(index / 5) * 480 + 20, width: 440, height: 440)))
    }
    try render([(whiteBase, CGRect(x: 0, y: 0, width: 2400, height: mode == "sample" ? 480 : 960))] + emblemLayers,
               width: 2400, height: mode == "sample" ? 480 : 960)
        .save(outputURL(root, resolvedOutput, "emblems-white.png"))
    try render(emblemLayers, width: 2400, height: mode == "sample" ? 480 : 960, background: true)
        .save(outputURL(root, resolvedOutput, "emblems-dark.png"))

    let files = try FileManager.default.contentsOfDirectory(at: resolvedOutput, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        .filter { $0.lastPathComponent != "manifest.json" }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    var outputs = [String: String]()
    for file in files { outputs[file.lastPathComponent] = try digest(file) }
    var inputHashes = kit.inputHashes
    inputHashes["tools/render/foolkit5.swift"] = try digest(root.appendingPathComponent("tools/render/foolkit5.swift"))
    let alphaCounts = frameRasters.values.map { $0.alpha.filter { $0 == 0 }.count }
    let manifest: [String: Any] = [
        "version": 1,
        "mode": "material-study",
        "created_at": ISO8601DateFormatter().string(from: Date()),
        "renderer": "foolkit5",
        "tool_sha256": inputHashes["tools/render/foolkit5.swift"]!,
        "catalog_sha256": inputHashes["production/symbols/fool-five-tier-kit.json"]!,
        "recipe_sha256": kit.recipeHash,
        "inputs": inputHashes,
        "outputs": outputs,
        "sequence_mapping": kit.mapping,
        "frame_files": frameFiles,
        "entries": entries.sorted { ($0["digit"] as? Int ?? -1) < ($1["digit"] as? Int ?? -1) },
        "native_frame_size": kit.body.w > 0 ? [kit.body.w, kit.body.h] : [0, 0],
        "final_size": kit.geometry.finalSize,
        "native_final": false,
        "geometry_difference_pixels": 0,
        "alpha": [
            "frame_has_transparency": alphaCounts.allSatisfy { $0 > 0 },
            "frame_transparent_pixel_counts": alphaCounts,
            "emblems_have_transparency": emblemRasters.values.allSatisfy { $0.alpha.contains(0) },
        ],
        "material_rules": ["primary_targets": ["frame_texture", "existing_pathway_recess", "quality_marker_diamond"], "hue_drift": true, "gem_luminance": true],
        "visual_status": "pending",
        "formal_release_approved": false,
        "legacy_four_tier_rejected": true,
        "method": "frozen geometry master; fixed region masks; config-driven primary color; relief-driven hue drift; independent emblem visible-ink placement",
    ]
    try writeJSON(manifest, outputURL(root, resolvedOutput, "manifest.json"))
    print(resolvedOutput.path)
}

func gate(_ root: URL, _ output: URL) throws {
    let kit = try loadKit(root)
    let manifestURL = output.appendingPathComponent("manifest.json")
    let manifest = try jsonObject(manifestURL)
    try require(try text(manifest, "mode") == "material-study", "Unsupported manifest mode")
    try require(try flag(manifest["formal_release_approved"], "formal release") == false, "Material study cannot be release approved")
    try require(try flag(manifest["legacy_four_tier_rejected"], "legacy four-tier") == true, "Legacy four-tier was not rejected")
    try require(try text(manifest, "tool_sha256") == digest(root.appendingPathComponent("tools/render/foolkit5.swift")), "Renderer changed")
    try require(try text(manifest, "catalog_sha256") == digest(kit.catalogURL), "Catalog changed")
    try require(try text(manifest, "recipe_sha256") == kit.recipeHash, "Recipe changed")

    let inputs = try dictionary(manifest["inputs"], "manifest.inputs")
    for (path, value) in inputs {
        guard let expected = value as? String else { throw Failure.invalid("Invalid input hash: \(path)") }
        try require(try digest(within(root, path)) == expected, "Input changed: \(path)")
    }
    let outputs = try dictionary(manifest["outputs"], "manifest.outputs")
    for (file, value) in outputs {
        guard let expected = value as? String else { throw Failure.invalid("Invalid output hash: (file)") }
        try require(try digest(output.appendingPathComponent(file)) == expected, "Output changed: (file)")
    }

    let mapping = try parseMapping(manifest["sequence_mapping"])
    try require(mapping == kit.mapping, "Manifest mapping changed")
    try require(try integer(manifest["geometry_difference_pixels"], "geometry_difference_pixels") == 0, "Manifest geometry drift")
    let alpha = try dictionary(manifest["alpha"], "manifest.alpha")
    try require(try flag(alpha["frame_has_transparency"], "frame transparency"), "Frame alpha is not real")
    try require(try flag(alpha["emblems_have_transparency"], "emblem transparency"), "Emblem alpha is not real")

    let tierOrder = ["low", "mid", "saint", "angel", "true-god"]
    var frames = [String: Raster]()
    for id in tierOrder {
        guard let style = kit.styles[id] else { throw Failure.invalid("Missing style \(id)") }
        let expectedNative = fixedMaterial(kit.body, tier: style, masks: kit.masks)
        let expected = render(
            [(expectedNative, CGRect(x: 0, y: 0, width: kit.geometry.finalSize[0], height: kit.geometry.finalSize[1]))],
            width: kit.geometry.finalSize[0],
            height: kit.geometry.finalSize[1]
        )
        let actual = try Raster(output.appendingPathComponent("frame-\(id).png"))
        try require(try geometryDifference(actual, expected) == 0, "Geometry drift: frame-\(id).png")
        frames[id] = actual
    }

    let entryRows = try dictionaries(manifest["entries"], "manifest.entries")
    let digits = try entryRows.map { try integer($0["digit"], "entry digit") }.sorted()
    try require(digits == Array(0...9) || digits == [9], "Missing/duplicate emblem entries")
    for row in entryRows {
        let digit = try integer(row["digit"], "entry digit")
        let tier = try text(row, "tier")
        try require(try qualityTier(for: digit, mapping: kit.mapping) == tier, "Entry tier mismatch: \(digit)")
        let emblem = try Raster(output.appendingPathComponent("emblem-\(digit).png"))
        try require(emblem.alpha.contains(0) && emblem.bbox[3] > 0, "Invalid emblem layer: \(digit)")
        guard let frame = frames[tier] else { throw Failure.invalid("Missing frame for \(digit)") }
        let rect = try placementRect(emblem, kit.geometry, digit)
        let recorded = try reals(row["rect_px"], "entry.rect_px")
        let computed = [rect.minX, rect.minY, rect.width, rect.height]
        try require(zip(recorded, computed).allSatisfy { abs($0 - $1) < 0.01 }, "Placement recomputation mismatch: \(digit)")
        let actual = try Raster(output.appendingPathComponent("fool-\(digit)-frame.png"))
        try require(actual.w == kit.geometry.finalSize[0] && actual.h == kit.geometry.finalSize[1] && actual.alpha.contains(0), "Invalid final canvas: \(digit)")
        let expected = try renderSequenceFrame(frame: frame, emblem: emblem, sequence: digit, geometry: kit.geometry)
        try require(try geometryDifference(actual, expected) == 0, "Final structure/placement drift: \(digit)")
    }
    print("PASS: five-tier; \(digits.count) compositions; zero geometry/placement drift; real alpha; visual review separate; not release")
}

func selftest() throws {
    var fixture = Raster(64, 64)
    for y in 8..<60 {
        for x in 8..<56 {
            let i = (y * fixture.w + x) * 4
            fixture.p[i] = 180
            fixture.p[i + 1] = 95
            fixture.p[i + 2] = 150
            fixture.p[i + 3] = 255
        }
    }
    let gemIndex = (60 * fixture.w + 32) * 4
    fixture.p[gemIndex] = 220
    fixture.p[gemIndex + 1] = 220
    fixture.p[gemIndex + 2] = 220
    fixture.p[gemIndex + 3] = 255
    let style = TierSpec(id: "true-god", sequences: [0], primary: [0.94, 0.70, 0.25], gem: [1.0, 0.78, 0.28], surfaceBlend: 0.78, contrast: 0.26, highlight: 0.21, pathwayStrength: 0.80, hueDriftEnabled: true, gemLuminanceEnabled: true)
    let graded = fixedMaterial(fixture, tier: style, masks: makeMasks(fixture))
    try require(try geometryDifference(fixture, graded) == 0, "selftest geometry changed")
    try require(fixture.alpha.contains(0) && graded.alpha.contains(255), "selftest alpha missing")
    try require(graded.p[gemIndex] > 0 && graded.p[gemIndex + 1] > 0 && graded.p[gemIndex + 2] > 0, "selftest gem highlight lost")
    let mapping: [String: [Int]] = ["low": [9, 8], "mid": [7, 6, 5], "saint": [4, 3], "angel": [2, 1], "true-god": [0]]
    try require(mapping["saint"] == [4, 3] && mapping["angel"] == [2, 1], "selftest saint/angel split missing")
    try require(!mapping.keys.contains("high"), "legacy four-tier key accepted")
    print("five-tier-mapping")
    print("geometry-zero")
    print("alpha-real")
    print("gem-highlight-preserved")
    print("legacy-four-tier-rejected")
}

do {
    let args = CommandLine.arguments
    if args.count == 2 && args[1] == "selftest" {
        try selftest()
    } else if args.count == 5 && args[1] == "prepare" {
        try prepare(
            URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(),
            URL(fileURLWithPath: args[3]).standardizedFileURL,
            args[4]
        )
    } else if args.count == 4 && args[1] == "gate" {
        try gate(
            URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(),
            URL(fileURLWithPath: args[3]).standardizedFileURL
        )
    } else {
        throw Failure.invalid("Usage: foolkit5 selftest | prepare ROOT NEW_OUTPUT sample|all | gate ROOT OUTPUT")
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
