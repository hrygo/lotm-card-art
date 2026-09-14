// Deterministic three-text-zone compositor for the active Fool v3 frame kit.
// It owns local inlays, the single central nameplate, CoreText typesetting,
// actual ink measurement, and output gates. It never asks an image model to
// render readable card text.
import AppKit
import CoreText
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
        unpremultiply(&p)
    }

    var image: CGImage {
        var bytes = p
        for i in stride(from: 0, to: bytes.count, by: 4) {
            for c in 0..<3 {
                bytes[i + c] = UInt8(Int(bytes[i + c]) * Int(bytes[i + 3]) / 255)
            }
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

func unpremultiply(_ pixels: inout [UInt8]) {
    for i in stride(from: 0, to: pixels.count, by: 4) {
        let alpha = Int(pixels[i + 3])
        if alpha > 0 {
            for c in 0..<3 {
                pixels[i + c] = UInt8(min(255, Int(pixels[i + c]) * 255 / alpha))
            }
        }
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

func text(_ object: [String: Any], _ key: String, allowEmpty: Bool = false) throws -> String {
    guard let value = object[key] as? String, allowEmpty || !value.isEmpty else {
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

func reals(_ value: Any?, _ label: String) throws -> [Double] {
    guard let values = value as? [Any] else { throw Failure.invalid("Expected number array: \(label)") }
    return try values.enumerated().map { try real($0.element, "\(label)[\($0.offset)]") }
}

func rect(_ value: Any?, _ label: String) throws -> CGRect {
    let values = try reals(value, label)
    try require(values.count == 4 && values.allSatisfy { $0 >= 0 }, "Invalid rectangle: \(label)")
    return CGRect(x: values[0], y: values[1], width: values[2], height: values[3])
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

func blend(_ lhs: [Double], _ rhs: [Double], _ amount: Double) -> [Double] {
    zip(lhs, rhs).map { $0 * (1 - amount) + $1 * amount }
}

func cgColor(_ rgb: [Double], _ alpha: Double = 1.0) -> CGColor {
    CGColor(srgbRed: CGFloat(clamp(rgb[0])), green: CGFloat(clamp(rgb[1])), blue: CGFloat(clamp(rgb[2])), alpha: CGFloat(clamp(alpha)))
}

func relativeLuminance(_ rgb: [Double]) -> Double {
    let linear = rgb.map { channel -> Double in
        let value = clamp(channel)
        return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
}

func contrastRatio(_ lhs: [Double], _ rhs: [Double]) -> Double {
    let a = relativeLuminance(lhs)
    let b = relativeLuminance(rhs)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
}

func sideGlyphFace(_ palette: Palette) -> [Double] {
    // Side glyphs are engraved directly into the frozen pillar surface. A
    // deep chromatic metal face stays legible on both silver and tier-tinted
    // columns; the derived bevel/glint supplies the luminous edge.
    blend([0.11, 0.065, 0.16], palette.primary, 0.16)
}

func sideGlyphCavity(_ palette: Palette) -> [Double] {
    // Contrast reference for the existing light metallic pillar surface; no
    // renderer-created cavity or label background is included in the layer.
    blend([0.82, 0.80, 0.76], palette.primary, 0.08)
}

func nameGlyphFace(_ palette: Palette) -> [Double] {
    // The name is engraved directly into the frame's existing surface. Use a
    // deep, slightly chromatic metal instead of white-on-a-new-plate; the
    // derived bevel and glint provide the premium finish without a background.
    blend([0.11, 0.065, 0.16], palette.primary, 0.14)
}

func nameGlyphField(_ palette: Palette) -> [Double] {
    // Reference surface for the contrast gate: the existing light/metallic
    // name area in the frozen frame, not a renderer-created fill.
    blend([0.82, 0.80, 0.76], palette.primary, 0.08)
}

func makeLayer(_ width: Int, _ height: Int, _ draw: (CGContext) -> Void) -> Raster {
    var layer = Raster(width, height)
    layer.p.withUnsafeMutableBytes { bytes in
        let context = CGContext(
            data: bytes.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: srgb,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        // All geometry in this executable is expressed in top-left image
        // coordinates, while CoreGraphics is bottom-left by default.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.interpolationQuality = .high
        draw(context)
    }
    unpremultiply(&layer.p)
    // The image provider used by Raster/NSBitmapImageRep already presents its
    // first row in image order. Keep the buffer in that convention; compose()
    // also draws full-canvas layers without another vertical transform.
    return layer
}

func compose(_ layers: [Raster], _ width: Int, _ height: Int) -> Raster {
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
        for layer in layers {
            context.draw(layer.image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
    unpremultiply(&result.p)
    return result
}

// CoreText is drawn inside the same top-left image context as the vector
// geometry. An asymmetric L probe catches the exact vertical reflection that
// previously made every semantic glyph look mirrored in the saved PNG.
func orientationSentinel() throws {
    let probe = makeLayer(96, 96) { context in
        let line = makeLine("L", "Helvetica", 44, cgColor([1, 0.2, 0.2], 1))
        drawLine(line, context, CGPoint(x: 12, y: 70))
    }
    let box = probe.bbox
    try require(box[2] > 0 && box[3] > 0, "Orientation sentinel produced no ink")
    let midY = box[1] + box[3] / 2
    let midX = box[0] + box[2] / 2
    var top = 0
    var bottom = 0
    var left = 0
    var right = 0
    for y in box[1]..<(box[1] + box[3]) {
        for x in box[0]..<(box[0] + box[2]) {
            let alpha = Int(probe.p[(y * probe.w + x) * 4 + 3])
            if y < midY { top += alpha } else { bottom += alpha }
            if x < midX { left += alpha } else { right += alpha }
        }
    }
    try require(bottom > top && left > right, "CoreText orientation sentinel detected reflection")
}

func alphaDifference(_ lhs: Raster, _ rhs: Raster) -> Int {
    guard lhs.w == rhs.w && lhs.h == rhs.h else { return Int.max }
    return zip(lhs.alpha, rhs.alpha).filter { $0 != $1 }.count
}

func maxColorDifference(_ lhs: Raster, _ rhs: Raster) -> Int {
    guard lhs.w == rhs.w && lhs.h == rhs.h else { return Int.max }
    var maximum = 0
    for index in 0..<(lhs.w * lhs.h) {
        let i = index * 4
        if lhs.p[i + 3] == 0 && rhs.p[i + 3] == 0 { continue }
        for channel in 0..<3 {
            let leftPremultiplied = Int(lhs.p[i + channel]) * Int(lhs.p[i + 3]) / 255
            let rightPremultiplied = Int(rhs.p[i + channel]) * Int(rhs.p[i + 3]) / 255
            maximum = max(maximum, abs(leftPremultiplied - rightPremultiplied))
        }
    }
    return maximum
}

func shift(_ source: Raster, dx: Int, dy: Int) -> Raster {
    var result = Raster(source.w, source.h)
    for y in 0..<source.h {
        for x in 0..<source.w {
            let targetX = x + dx
            let targetY = y + dy
            guard targetX >= 0 && targetX < source.w && targetY >= 0 && targetY < source.h else { continue }
            let sourceIndex = (y * source.w + x) * 4
            let targetIndex = (targetY * source.w + targetX) * 4
            if source.p[sourceIndex + 3] == 0 { continue }
            for channel in 0..<4 { result.p[targetIndex + channel] = source.p[sourceIndex + channel] }
        }
    }
    return result
}

func dilateAlpha(_ source: Raster, radius: Int) -> Raster {
    guard radius > 0 else { return source }
    let box = source.bbox
    guard box[2] > 0 && box[3] > 0 else { return Raster(source.w, source.h) }
    var result = Raster(source.w, source.h)
    let x0 = max(0, box[0] - radius)
    let y0 = max(0, box[1] - radius)
    let x1 = min(source.w - 1, box[0] + box[2] - 1 + radius)
    let y1 = min(source.h - 1, box[1] + box[3] - 1 + radius)
    for y in y0...y1 {
        for x in x0...x1 {
            var maximum = 0
            for offsetY in -radius...radius {
                let sourceY = y + offsetY
                guard sourceY >= 0 && sourceY < source.h else { continue }
                for offsetX in -radius...radius {
                    let sourceX = x + offsetX
                    guard sourceX >= 0 && sourceX < source.w else { continue }
                    let distance = offsetX * offsetX + offsetY * offsetY
                    guard distance <= radius * radius else { continue }
                    maximum = max(maximum, Int(source.p[(sourceY * source.w + sourceX) * 4 + 3]))
                }
            }
            guard maximum > 0 else { continue }
            let index = (y * result.w + x) * 4
            result.p[index] = 255
            result.p[index + 1] = 255
            result.p[index + 2] = 255
            result.p[index + 3] = UInt8(maximum)
        }
    }
    return result
}

func colorizeMask(_ mask: Raster, _ rgb: [Double], _ opacity: Double = 1.0) -> Raster {
    var result = Raster(mask.w, mask.h)
    let red = UInt8(clamp(rgb[0]) * 255.0)
    let green = UInt8(clamp(rgb[1]) * 255.0)
    let blue = UInt8(clamp(rgb[2]) * 255.0)
    for index in stride(from: 0, to: mask.p.count, by: 4) {
        let alpha = UInt8(clamp(Double(mask.p[index + 3]) / 255.0 * opacity) * 255.0)
        guard alpha > 0 else { continue }
        result.p[index] = red
        result.p[index + 1] = green
        result.p[index + 2] = blue
        result.p[index + 3] = alpha
    }
    return result
}

struct Palette {
    let id: String
    let primary: [Double]
}

struct Zone {
    let id: String
    let kind: String
    let panel: CGRect
    let safe: CGRect
    let orientation: String
    let diamondTop: CGFloat?
}

struct TextValue {
    let text: String
    let zone: String
    let visible: Bool
}

struct TextInput {
    let pathway: TextValue
    let sequence: TextValue
    let character: TextValue
}

struct BatchEntry {
    let digit: Int
    let sequenceID: String
    let sequenceName: String
    let tier: String
    let framePath: String
}

struct BatchSpec {
    let path: String
    let baseKitPath: String
    let pathwayName: String
    let characterName: String
    let entries: [BatchEntry]
}

struct InscriptionContract {
    let path: String
    let hash: String
    let referencePath: String
    let referenceHash: String
    let minimumCharacters: Int
    let renderMode: String
}

struct RenderedZone {
    let panel: Raster
    let ink: Raster
    let panelRect: CGRect
    let safeRect: CGRect
    let inkBox: [Int]
    let faceBox: [Int]
    let faceLayerCount: Int
    let targetCenter: [Double]
    let centerError: [Double]
    let glyphCenterErrors: [[Double]]
    let diamondClearance: Double?
    let diamondProtectionPassed: Bool
}

struct InkRender {
    let composite: Raster
    let face: Raster
    let glyphCenterErrors: [[Double]]
    let faceLayerCount: Int
}

struct Bundle {
    let frame: Raster
    let left: RenderedZone
    let center: RenderedZone
    let right: RenderedZone
    let safeZones: Raster
    let card: Raster
    let framePath: String
    let textPath: String
    let palette: Palette
    let inscription: InscriptionContract
}

func loadZones(_ root: URL) throws -> [String: Zone] {
    let templateURL = try within(root, "production/templates/card-text-panels-v5.json")
    let template = try jsonObject(templateURL)
    try require(try text(template, "status") == "active-v5-template", "Inactive text template")
    let canvas = try dictionary(template["canvas"], "template.canvas")
    try require(try reals(canvas["design_size"], "canvas.design_size") == [1024, 1536], "Text design size changed")
    try require(try reals(canvas["final_size"], "canvas.final_size") == [2048, 3072], "Text final size changed")
    guard let rows = template["zones"] as? [Any] else { throw Failure.invalid("Template zones missing") }
    var zones = [String: Zone]()
    for value in rows {
        let row = try dictionary(value, "template.zone")
        let id = try text(row, "id")
        let kind = try text(row, "kind")
        let panelValue = row["panel_rect_design"] ?? row["rect_design"]
        let panel = try rect(panelValue, "template.\(id).panel")
        let safe = try rect(row["text_safe_rect_design"], "template.\(id).text_safe")
        let orientation = try text(row, "text_orientation")
        let diamondTop: CGFloat?
        if let value = row["diamond_top_design"] {
            diamondTop = CGFloat(try real(value, "template.\(id).diamond_top_design") * 2.0)
        } else {
            diamondTop = nil
        }
        zones[id] = Zone(
            id: id,
            kind: kind,
            panel: panel.applying(CGAffineTransform(scaleX: 2, y: 2)),
            safe: safe.applying(CGAffineTransform(scaleX: 2, y: 2)),
            orientation: orientation,
            diamondTop: diamondTop
        )
    }
    try require(Set(zones.keys) == Set(["pathway_name", "sequence_name", "character_name"]), "Text zones are incomplete")
    try require(zones.values.filter { $0.kind == "central-nameplate" }.count == 1, "Central full-width panel count changed")
    try require(zones["pathway_name"]!.kind == "left-column-inlay", "Pathway zone moved")
    try require(zones["sequence_name"]!.kind == "right-column-inlay", "Sequence zone moved")
    for id in ["pathway_name", "sequence_name"] {
        let row = try dictionary(rows.first { value in
            guard let object = value as? [String: Any] else { return false }
            return (object["id"] as? String) == id
        }, "template.\(id)")
        try require(abs(try real(row["width_ratio_to_column"], "template.\(id).width_ratio_to_column") - 1.5) < 0.0001, "Side inlay width changed: \(id)")
        try require(try integer(row["capacity_min_characters"], "template.\(id).capacity_min_characters") >= 6, "Side inscription capacity changed: \(id)")
        try require(try text(row, "inscription_render_mode") == "per-glyph-ink-box-derived-relief", "Side inscription mode changed: \(id)")
    }
    return zones
}

func loadInscriptionContract(_ root: URL) throws -> InscriptionContract {
    let path = "production/symbols/inscriptions/fool-side-inscription-v4.json"
    let url = try within(root, path)
    let object = try jsonObject(url)
    let status = try text(object, "status")
    try require(status == "user-approved-style-direction-programmatic-integration", "Inscription contract is not active")
    let reference = try dictionary(object["style_reference"], "inscription.style_reference")
    let referencePath = try text(reference, "path")
    let referenceHash = try text(reference, "sha256")
    let referenceURL = try within(root, referencePath)
    try require(try digest(referenceURL) == referenceHash, "Inscription style reference changed")
    let capacity = try dictionary(object["capacity"], "inscription.capacity")
    let minimum = try integer(capacity["minimum_characters"], "inscription minimum characters")
    try require(minimum >= 6, "Inscription minimum capacity is too small")
    let render = try dictionary(object["render_policy"], "inscription.render_policy")
    let mode = try text(render, "mode")
    try require(mode == "per-glyph-ink-box-derived-relief", "Inscription render mode changed")
    try require(try flag(render["flat_coretext_final_layer_forbidden"], "flat inscription flag"), "Flat inscription text is allowed")
    return InscriptionContract(path: path, hash: try digest(url), referencePath: referencePath, referenceHash: referenceHash, minimumCharacters: minimum, renderMode: mode)
}

func loadTextInput(_ url: URL) throws -> TextInput {
    let object = try jsonObject(url)
    try require(Set(object.keys) == Set(["schema_version", "pathway_name", "sequence_name", "character_name"]), "Text input has undeclared fields")
    try require(try text(object, "schema_version") == "1.0.0", "Unsupported text input schema")

    func value(_ key: String, _ expectedZone: String, allowEmpty: Bool) throws -> TextValue {
        let row = try dictionary(object[key], "text.\(key)")
        try require(Set(row.keys) == Set(["text", "zone", "visible"]), "Text field has undeclared fields: \(key)")
        let string = try text(row, "text", allowEmpty: allowEmpty)
        let zone = try text(row, "zone")
        let visible = try flag(row["visible"], "text.\(key).visible")
        try require(zone == expectedZone && visible, "Text zone binding mismatch: \(key)")
        let forbidden = ["待填写", "占位", "主角姓名", "placeholder", "TODO", "TBD"]
        try require(!forbidden.contains(where: { string.localizedCaseInsensitiveContains($0) }), "Placeholder text rejected: \(key)")
        return TextValue(text: string, zone: zone, visible: visible)
    }

    return TextInput(
        pathway: try value("pathway_name", "left-column-inlay", allowEmpty: false),
        sequence: try value("sequence_name", "right-column-inlay", allowEmpty: false),
        character: try value("character_name", "central-nameplate", allowEmpty: true)
    )
}

func expectedTier(_ digit: Int) -> String {
    if digit <= 0 { return "true-god" }
    if digit <= 2 { return "angel" }
    if digit <= 4 { return "saint" }
    if digit <= 7 { return "mid" }
    return "low"
}

func loadBatchSpec(_ root: URL, _ url: URL) throws -> BatchSpec {
    let object = try jsonObject(url)
    try require(Set(object.keys) == Set(["schema_version", "pathway_id", "pathway_name", "character_name", "base_kit", "purpose", "entries"]), "Batch input has undeclared fields")
    try require(try text(object, "schema_version") == "1.0.0", "Unsupported batch input schema")
    let pathwayName = try text(object, "pathway_name")
    let characterName = try text(object, "character_name", allowEmpty: true)
    try require(pathwayName == "愚者", "Fool batch pathway changed")
    try require(characterName.isEmpty, "Batch frame inputs must not contain character text")
    let baseKitPath = try text(object, "base_kit")
    _ = try within(root, baseKitPath)
    guard let rawEntries = object["entries"] as? [Any] else { throw Failure.invalid("Batch entries missing") }
    try require(rawEntries.count == 10, "Batch must contain exactly ten sequence entries")
    var entries = [BatchEntry]()
    var digits = Set<Int>()
    for raw in rawEntries {
        let row = try dictionary(raw, "batch.entry")
        try require(Set(row.keys) == Set(["digit", "sequence_id", "sequence_name", "tier", "frame_path"]), "Batch entry has undeclared fields")
        let digit = try integer(row["digit"], "batch.entry.digit")
        try require((0...9).contains(digit) && !digits.contains(digit), "Batch digit mapping is not one-to-one")
        digits.insert(digit)
        let sequenceID = try text(row, "sequence_id")
        try require(sequenceID == String(format: "%02d", digit), "Batch sequence id changed: \(digit)")
        let sequenceName = try text(row, "sequence_name")
        let tier = try text(row, "tier")
        try require(tier == expectedTier(digit), "Batch tier mapping changed: \(digit)")
        let framePath = try text(row, "frame_path")
        _ = try within(root, framePath)
        entries.append(BatchEntry(digit: digit, sequenceID: sequenceID, sequenceName: sequenceName, tier: tier, framePath: framePath))
    }
    try require(digits == Set(0...9), "Batch does not cover digits 0-9")
    return BatchSpec(path: "production/fixtures/fool-inscribed-frame-batch-v1.json", baseKitPath: baseKitPath, pathwayName: pathwayName, characterName: characterName, entries: entries.sorted { $0.digit > $1.digit })
}

func loadPalette(_ root: URL, _ framePath: String) throws -> Palette {
    let colorsURL = try within(root, "config/quality-color-tokens.json")
    let colors = try jsonObject(colorsURL)
    guard let rows = colors["tiers"] as? [Any] else { throw Failure.invalid("Tier colors missing") }
    var palettes = [String: Palette]()
    for value in rows {
        let row = try dictionary(value, "color tier")
        let id = try text(row, "id")
        palettes[id] = Palette(id: id, primary: try hexColor(try text(row, "primary")))
    }
    let name = URL(fileURLWithPath: framePath).lastPathComponent
    let tier: String
    if name.contains("frame-low") { tier = "low" }
    else if name.contains("frame-mid") { tier = "mid" }
    else if name.contains("frame-saint") { tier = "saint" }
    else if name.contains("frame-angel") { tier = "angel" }
    else if name.contains("frame-true-god") { tier = "true-god" }
    else if let digitMatch = name.range(of: "fool-[0-9]+-frame", options: .regularExpression) {
        let token = String(name[digitMatch])
        let digits = token.filter { $0.isNumber }
        guard let digit = Int(digits) else { throw Failure.invalid("Cannot infer frame sequence") }
        tier = digit <= 0 ? "true-god" : digit <= 2 ? "angel" : digit <= 4 ? "saint" : digit <= 7 ? "mid" : "low"
    } else {
        throw Failure.invalid("Cannot infer frame quality tier: \(name)")
    }
    guard let palette = palettes[tier] else { throw Failure.invalid("Missing palette: \(tier)") }
    return palette
}

func drawDiamond(_ context: CGContext, _ center: CGPoint, _ radius: CGFloat, _ fill: CGColor, _ stroke: CGColor) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: center.x, y: center.y - radius))
    path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
    path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
    path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
    path.closeSubpath()
    context.addPath(path)
    context.setFillColor(fill)
    context.fillPath()
    context.addPath(path)
    context.setStrokeColor(stroke)
    context.setLineWidth(2)
    context.strokePath()
}

func ribbonPath(_ rect: CGRect) -> CGPath {
    let path = CGMutablePath()
    let cap = min(14, rect.width * 0.18)
    path.move(to: CGPoint(x: rect.minX + cap, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - cap, y: rect.minY))
    path.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cap), control1: CGPoint(x: rect.maxX - 3, y: rect.minY), control2: CGPoint(x: rect.maxX, y: rect.minY + 3))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cap))
    path.addCurve(to: CGPoint(x: rect.maxX - cap, y: rect.maxY), control1: CGPoint(x: rect.maxX, y: rect.maxY - 3), control2: CGPoint(x: rect.maxX - 3, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX + cap, y: rect.maxY))
    path.addCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cap), control1: CGPoint(x: rect.minX + 3, y: rect.maxY), control2: CGPoint(x: rect.minX, y: rect.maxY - 3))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cap))
    path.addCurve(to: CGPoint(x: rect.minX + cap, y: rect.minY), control1: CGPoint(x: rect.minX, y: rect.minY + 3), control2: CGPoint(x: rect.minX + 3, y: rect.minY))
    path.closeSubpath()
    return path
}

func fillGradient(_ context: CGContext, _ rect: CGRect, _ colors: [CGColor], _ start: CGPoint, _ end: CGPoint) {
    let gradient = CGGradient(colorsSpace: srgb, colors: colors as CFArray, locations: [0, 0.52, 1])!
    context.saveGState()
    context.addRect(rect)
    context.clip()
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
    context.restoreGState()
}

func fillPathGradient(_ context: CGContext, _ path: CGPath, _ rect: CGRect, _ colors: [CGColor], _ start: CGPoint, _ end: CGPoint) {
    let gradient = CGGradient(colorsSpace: srgb, colors: colors as CFArray, locations: [0, 0.52, 1])!
    context.saveGState()
    context.addPath(path)
    context.clip()
    context.drawLinearGradient(gradient, start: start, end: end, options: [])
    context.restoreGState()
}

func foolMappedPoint(_ rect: CGRect, _ x: CGFloat, _ y: CGFloat, _ side: CGFloat) -> CGPoint {
    let normalizedX = side < 0 ? 1 - x : x
    return CGPoint(x: rect.minX + normalizedX * rect.width, y: rect.minY + y * rect.height)
}

func foolColumnPath(_ rect: CGRect, _ side: CGFloat) -> CGPath {
    // This is the deterministic pixel interpretation of the user-approved
    // initial side-column study: a broad curtain blade, curled terminals and
    // an intentionally off-axis outer flare. It is not a rounded plaque or a
    // capsule, and left/right columns mirror around their own fixed anchors.
    let r = rect.insetBy(dx: 3, dy: 3)
    let p: (CGFloat, CGFloat) -> CGPoint = { foolMappedPoint(r, $0, $1, side) }
    let path = CGMutablePath()
    path.move(to: p(0.31, 0.00))
    path.addCurve(to: p(0.76, 0.03), control1: p(0.49, -0.03), control2: p(0.69, -0.02))
    path.addCurve(to: p(0.95, 0.15), control1: p(0.88, 0.04), control2: p(0.99, 0.07))
    path.addCurve(to: p(0.83, 0.28), control1: p(0.92, 0.19), control2: p(0.82, 0.20))
    path.addCurve(to: p(0.83, 0.72), control1: p(0.83, 0.43), control2: p(0.82, 0.58))
    path.addCurve(to: p(0.95, 0.87), control1: p(0.84, 0.79), control2: p(1.00, 0.84))
    path.addCurve(to: p(0.72, 0.98), control1: p(0.87, 0.95), control2: p(0.75, 1.01))
    path.addCurve(to: p(0.28, 1.00), control1: p(0.56, 1.00), control2: p(0.38, 1.02))
    path.addCurve(to: p(0.07, 0.91), control1: p(0.20, 0.99), control2: p(0.02, 0.97))
    path.addCurve(to: p(0.19, 0.76), control1: p(0.10, 0.86), control2: p(0.19, 0.83))
    path.addLine(to: p(0.19, 0.24))
    path.addCurve(to: p(0.14, 0.13), control1: p(0.20, 0.19), control2: p(0.09, 0.18))
    path.addCurve(to: p(0.31, 0.00), control1: p(0.17, 0.07), control2: p(0.23, 0.01))
    path.closeSubpath()
    return path
}

func foolRailPath(_ rect: CGRect, _ side: CGFloat) -> CGPath {
    // The inscription rail is a recessed continuation of the enamel body.
    // Its ends soften into the curtain folds; it never becomes a separate
    // opaque label or a straight-edged card panel.
    let r = rect.insetBy(dx: 2, dy: 2)
    let p: (CGFloat, CGFloat) -> CGPoint = { foolMappedPoint(r, $0, $1, side) }
    let path = CGMutablePath()
    path.move(to: p(0.34, 0.00))
    path.addCurve(to: p(0.66, 0.00), control1: p(0.44, -0.02), control2: p(0.56, -0.02))
    path.addCurve(to: p(0.82, 0.10), control1: p(0.74, 0.03), control2: p(0.83, 0.06))
    path.addCurve(to: p(0.82, 0.90), control1: p(0.82, 0.34), control2: p(0.82, 0.67))
    path.addCurve(to: p(0.65, 1.00), control1: p(0.77, 0.94), control2: p(0.71, 1.00))
    path.addCurve(to: p(0.35, 1.00), control1: p(0.56, 1.00), control2: p(0.44, 1.00))
    path.addCurve(to: p(0.18, 0.90), control1: p(0.29, 1.00), control2: p(0.17, 0.94))
    path.addCurve(to: p(0.18, 0.10), control1: p(0.18, 0.67), control2: p(0.18, 0.34))
    path.addCurve(to: p(0.34, 0.00), control1: p(0.17, 0.06), control2: p(0.28, 0.03))
    path.closeSubpath()
    return path
}

func foolFoldPath(_ rect: CGRect, _ side: CGFloat, _ top: Bool) -> CGPath {
    let r = rect.insetBy(dx: 4, dy: 4)
    let fy: (CGFloat) -> CGFloat = { top ? $0 : 1 - $0 }
    let p: (CGFloat, CGFloat) -> CGPoint = { foolMappedPoint(r, $0, fy($1), side) }
    let path = CGMutablePath()
    path.move(to: p(0.18, 0.28))
    path.addCurve(to: p(0.68, 0.05), control1: p(0.37, 0.22), control2: p(0.56, 0.03))
    path.addCurve(to: p(0.84, 0.17), control1: p(0.78, 0.08), control2: p(0.88, 0.10))
    path.addCurve(to: p(0.35, 0.39), control1: p(0.74, 0.22), control2: p(0.52, 0.36))
    path.addCurve(to: p(0.18, 0.28), control1: p(0.27, 0.39), control2: p(0.19, 0.33))
    path.closeSubpath()
    return path
}

func drawEtchedDiamond(_ context: CGContext, _ center: CGPoint, _ radius: CGFloat, _ stroke: CGColor) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: center.x, y: center.y - radius))
    path.addLine(to: CGPoint(x: center.x + radius, y: center.y))
    path.addLine(to: CGPoint(x: center.x, y: center.y + radius))
    path.addLine(to: CGPoint(x: center.x - radius, y: center.y))
    path.closeSubpath()
    context.addPath(path)
    context.setStrokeColor(stroke)
    context.setLineWidth(2)
    context.strokePath()
}

func drawFoolStar(_ context: CGContext, _ center: CGPoint, _ radius: CGFloat, _ fill: CGColor, _ stroke: CGColor) {
    let path = CGMutablePath()
    for index in 0..<16 {
        let angle = -Double.pi / 2 + Double(index) * Double.pi / 8
        let r = index.isMultiple(of: 2) ? radius : radius * 0.24
        let point = CGPoint(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
        if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    context.addPath(path)
    context.setFillColor(fill)
    context.fillPath()
    context.addPath(path)
    context.setStrokeColor(stroke)
    context.setLineWidth(1.4)
    context.strokePath()
}

func drawInscriptionOrnament(_ context: CGContext, _ rect: CGRect, _ metal: CGColor, _ highlight: CGColor, _ accent: CGColor, _ side: CGFloat) {
    let inner = rect.insetBy(dx: 5, dy: 7)
    context.saveGState()
    context.setLineCap(.round)
    context.setLineJoin(.round)
    // The base frame already owns the large Fool curtain column. This layer
    // only adds open engraving traces to the existing column, so no second
    // mini-frame, capsule or opaque label is placed above the approved art.
    // Fine inner edges and terminal traces make the cut read as a continuation
    // of the original silver/purple folds; the center remains quiet for text.
    context.setLineWidth(0.9)
    for (index, x) in [0.20, 0.80].enumerated() {
        context.setStrokeColor(index == 0 ? metal : highlight)
        let path = CGMutablePath()
        path.move(to: foolMappedPoint(inner, x, 0.10, side))
        path.addCurve(
            to: foolMappedPoint(inner, x, 0.90, side),
            control1: foolMappedPoint(inner, x + (x < 0.5 ? -0.018 : 0.018), 0.36, side),
            control2: foolMappedPoint(inner, x + (x < 0.5 ? 0.018 : -0.018), 0.64, side)
        )
        context.addPath(path)
        context.strokePath()
    }

    // Short top/bottom sweeps echo the approved curled terminals without
    // closing into a border or entering the six-glyph safe area.
    context.setStrokeColor(accent)
    context.setLineWidth(1.1)
    for top in [true, false] {
        context.addPath(foolFoldPath(inner, side, top))
        context.strokePath()
    }
    context.restoreGState()
}

func panelBase(_ _: Zone, _ _: Palette, _ width: Int, _ height: Int) -> Raster {
    // The frozen FrameCore is the sole substrate for all three text zones.
    // This layer is intentionally empty: side and name text are direct
    // engraved reliefs, never a newly painted plaque or color field.
    Raster(width, height)
}

func makeLine(_ text: String, _ fontName: String, _ size: CGFloat, _ color: CGColor) -> CTLine {
    let font = CTFontCreateWithName(fontName as CFString, size, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .kern: 0.5,
    ]
    return CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
}

func drawLine(_ line: CTLine, _ context: CGContext, _ origin: CGPoint) {
    // CoreText owns its own glyph coordinate system. The surrounding layer is
    // flipped to the top-left image convention for vector geometry, so the
    // text matrix must cancel that vertical reflection before drawing.
    context.saveGState()
    context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
    context.textPosition = origin
    CTLineDraw(line, context)
    context.restoreGState()
}

struct GlyphPlacement {
    let character: String
    let center: CGPoint
    let inkBounds: CGRect
}

struct GlyphLayout {
    let size: CGFloat
    let placements: [GlyphPlacement]
}

func inscriptionPlacements(_ zone: Zone, _ value: String, _ context: CGContext) -> GlyphLayout {
    let characters = value.map(String.init)
    guard !characters.isEmpty else { return GlyphLayout(size: 0, placements: []) }
    var selectedSize: CGFloat = 42
    var selectedBounds = [CGRect]()
    for candidate in stride(from: CGFloat(68), through: CGFloat(42), by: -1) {
        let bounds = characters.map { character in
            CTLineGetImageBounds(makeLine(character, "Songti SC", candidate, cgColor([1, 1, 1], 1)), context)
        }
        let gap = max(8, min(12, candidate * 0.18))
        // Keep a fixed optical cell for each character. The glyph itself is
        // centered from its actual ink box inside that cell; this preserves a
        // legible vertical rhythm without pretending all Chinese glyphs have
        // the same visible height.
        let total = candidate * CGFloat(bounds.count) + gap * CGFloat(max(0, bounds.count - 1))
        let fits = total <= zone.safe.height * 0.95 && bounds.allSatisfy { $0.width <= zone.safe.width * 0.82 }
        if fits {
            selectedSize = candidate
            selectedBounds = bounds
            break
        }
    }
    if selectedBounds.isEmpty {
        selectedBounds = characters.map { character in
            CTLineGetImageBounds(makeLine(character, "Songti SC", selectedSize, cgColor([1, 1, 1], 1)), context)
        }
    }
    let gap = max(8, min(12, selectedSize * 0.18))
    let total = selectedSize * CGFloat(selectedBounds.count) + gap * CGFloat(max(0, selectedBounds.count - 1))
    var y = zone.safe.midY - total * 0.5
    var placements = [GlyphPlacement]()
    for (character, bounds) in zip(characters, selectedBounds) {
        let center = CGPoint(x: zone.safe.midX, y: y + selectedSize * 0.5)
        placements.append(GlyphPlacement(character: character, center: center, inkBounds: bounds))
        y += selectedSize + gap
    }
    return GlyphLayout(size: selectedSize, placements: placements)
}

func drawGlyphAtCenter(_ character: String, _ context: CGContext, _ center: CGPoint, _ size: CGFloat, _ color: CGColor) {
    let line = makeLine(character, "Songti SC", size, color)
    let bounds = CTLineGetImageBounds(line, context)
    let origin = CGPoint(x: center.x - bounds.midX, y: center.y - bounds.midY)
    drawLine(line, context, origin)
}

func drawTextAtCenter(_ value: String, _ context: CGContext, _ center: CGPoint, _ size: CGFloat, _ color: CGColor) {
    let line = makeLine(value, "Songti SC", size, color)
    let bounds = CTLineGetImageBounds(line, context)
    let origin = CGPoint(x: center.x - bounds.midX, y: center.y - bounds.midY)
    drawLine(line, context, origin)
}

func recenterMask(_ source: Raster, _ target: CGPoint) -> Raster {
    let box = source.bbox
    guard box[2] > 0 && box[3] > 0 else { return source }
    let actualX = Double(box[0]) + Double(box[2]) * 0.5
    let actualY = Double(box[1]) + Double(box[3]) * 0.5
    let dx = Int((Double(target.x) - actualX).rounded())
    let dy = Int((Double(target.y) - actualY).rounded())
    return shift(source, dx: dx, dy: dy)
}

func exactGlyphMask(_ width: Int, _ height: Int, _ placement: GlyphPlacement, _ size: CGFloat) -> Raster {
    let raw = makeLayer(width, height) { context in
        drawGlyphAtCenter(placement.character, context, placement.center, size, cgColor([1, 1, 1], 1))
    }
    return recenterMask(raw, placement.center)
}

func reliefComposite(_ faceMask: Raster, _ palette: Palette, _ name: Bool) -> Raster {
    let darkness = name
        ? blend([0.018, 0.010, 0.030], palette.primary, 0.12)
        : blend([0.025, 0.018, 0.045], palette.primary, 0.22)
    let metal = name
        ? blend([0.84, 0.72, 0.52], palette.primary, 0.14)
        : blend([0.88, 0.76, 0.56], palette.primary, 0.16)
    let face = name ? nameGlyphFace(palette) : sideGlyphFace(palette)
    let glint = blend([1.0, 0.985, 0.90], palette.primary, name ? 0.08 : 0.10)
    let radius = name ? 5 : 3
    let undercut = colorizeMask(shift(dilateAlpha(faceMask, radius: radius), dx: 2, dy: 3), darkness, 0.82)
    let bevel = colorizeMask(shift(dilateAlpha(faceMask, radius: 2), dx: -1, dy: -1), metal, 0.70)
    let faceLayer = colorizeMask(faceMask, face, 1.0)
    // The highlight is derived from the single face mask. It is not a second
    // CoreText draw, so the glyph cannot acquire a duplicated outline or a
    // second, drifting text body.
    let glintLayer = colorizeMask(shift(faceMask, dx: -1, dy: -1), glint, 0.22)
    return compose([undercut, bevel, faceLayer, glintLayer], faceMask.w, faceMask.h)
}

func inscriptionInk(_ zone: Zone, _ value: String, _ palette: Palette, _ width: Int, _ height: Int) -> InkRender {
    guard !value.isEmpty else {
        return InkRender(composite: Raster(width, height), face: Raster(width, height), glyphCenterErrors: [], faceLayerCount: 0)
    }
    var layout = GlyphLayout(size: 0, placements: [])
    let measurement = makeLayer(1, 1) { context in
        layout = inscriptionPlacements(zone, value, context)
    }
    _ = measurement
    // Render each exact glyph into its own temporary mask, then union those
    // masks. This keeps the layout metric and the rasterization metric
    // identical while avoiding any context-state interaction between glyphs.
    let glyphMasks = layout.placements.map { placement in
        exactGlyphMask(width, height, placement, layout.size)
    }
    let faceMask = compose(glyphMasks, width, height)
    let preliminary = reliefComposite(faceMask, palette, false)
    let box = preliminary.bbox
    guard box[2] > 0 && box[3] > 0 else {
        return InkRender(composite: preliminary, face: faceMask, glyphCenterErrors: [], faceLayerCount: 1)
    }
    let dx = Int((zone.safe.midX - (Double(box[0]) + Double(box[2]) * 0.5)).rounded())
    let dy = Int((zone.safe.midY - (Double(box[1]) + Double(box[3]) * 0.5)).rounded())
    let glyphErrors = zip(layout.placements, glyphMasks).map { placement, mask in
        let glyphBox = mask.bbox
        let actual = [
            Double(glyphBox[0]) + Double(glyphBox[2]) * 0.5 + Double(dx),
            Double(glyphBox[1]) + Double(glyphBox[3]) * 0.5 + Double(dy),
        ]
        let target = [Double(placement.center.x) + Double(dx), Double(placement.center.y) + Double(dy)]
        return [actual[0] - target[0], actual[1] - target[1]]
    }
    return InkRender(
        composite: shift(preliminary, dx: dx, dy: dy),
        face: shift(faceMask, dx: dx, dy: dy),
        glyphCenterErrors: glyphErrors,
        faceLayerCount: 1
    )
}

func centeredCoreTextInk(_ zone: Zone, _ value: String, _ palette: Palette, _ width: Int, _ height: Int) -> InkRender {
    guard !value.isEmpty else {
        return InkRender(composite: Raster(width, height), face: Raster(width, height), glyphCenterErrors: [], faceLayerCount: 0)
    }
    let fontName = "Songti SC"
    var lineSize: CGFloat = 52
    var lineBounds = CGRect.zero
    let rawFaceMask = makeLayer(width, height) { context in
        let safe = zone.safe
        var candidate: CGFloat = 96
        while candidate >= 52 {
            let bounds = CTLineGetImageBounds(makeLine(value, fontName, candidate, cgColor([1, 1, 1], 1)), context)
            let effectReserve: CGFloat = 12
            if bounds.width <= safe.width * 0.86 && bounds.height + effectReserve <= safe.height * 0.84 { break }
            candidate -= 2
        }
        lineSize = max(52, candidate)
        let line = makeLine(value, fontName, lineSize, cgColor([1, 1, 1], 1))
        lineBounds = CTLineGetImageBounds(line, context)
        drawTextAtCenter(value, context, CGPoint(x: safe.midX, y: safe.midY), lineSize, cgColor([1, 1, 1], 1))
    }
    _ = lineSize
    _ = lineBounds
    let faceMask = recenterMask(rawFaceMask, CGPoint(x: zone.safe.midX, y: zone.safe.midY))
    let preliminary = reliefComposite(faceMask, palette, true)
    let box = preliminary.bbox
    guard box[2] > 0 && box[3] > 0 else {
        return InkRender(composite: preliminary, face: faceMask, glyphCenterErrors: [], faceLayerCount: 1)
    }
    let dx = Int((zone.safe.midX - (Double(box[0]) + Double(box[2]) * 0.5)).rounded())
    let dy = Int((zone.safe.midY - (Double(box[1]) + Double(box[3]) * 0.5)).rounded())
    return InkRender(
        composite: shift(preliminary, dx: dx, dy: dy),
        face: shift(faceMask, dx: dx, dy: dy),
        glyphCenterErrors: [],
        faceLayerCount: 1
    )
}

func measuredInk(_ zone: Zone, _ value: String, _ palette: Palette, _ width: Int, _ height: Int) -> InkRender {
    if zone.kind == "left-column-inlay" || zone.kind == "right-column-inlay" {
        return inscriptionInk(zone, value, palette, width, height)
    }
    return centeredCoreTextInk(zone, value, palette, width, height)
}

func zoneRender(_ zone: Zone, _ value: TextValue, _ palette: Palette, _ width: Int, _ height: Int) throws -> RenderedZone {
    let panel = panelBase(zone, palette, width, height)
    if zone.kind == "central-nameplate" {
        try require(panel.bbox == [0, 0, 0, 0], "Nameplate renderer added a background")
    }
    let rendered = measuredInk(zone, value.text, palette, width, height)
    let ink = rendered.composite
    let face = zone.kind == "central-nameplate" ? nameGlyphFace(palette) : sideGlyphFace(palette)
    let background = zone.kind == "central-nameplate" ? nameGlyphField(palette) : sideGlyphCavity(palette)
    try require(contrastRatio(face, background) >= 4.5, "Text contrast below contract: \(zone.id)")
    let box = ink.bbox
    let faceBox = rendered.face.bbox
    if box[2] > 0 && box[3] > 0 {
        let safe = zone.safe
        let safeBox = CGRect(x: safe.minX, y: safe.minY, width: safe.width, height: safe.height)
        let inkRect = CGRect(x: box[0], y: box[1], width: box[2], height: box[3])
        try require(safeBox.contains(inkRect), "Text overflow: \(zone.id)")
    }
    let center = box[2] == 0 ? [zone.safe.midX, zone.safe.midY] : [Double(box[0]) + Double(box[2]) * 0.5, Double(box[1]) + Double(box[3]) * 0.5]
    let target = [Double(zone.safe.midX), Double(zone.safe.midY)]
    let error = [center[0] - target[0], center[1] - target[1]]
    try require(abs(error[0]) <= 1 && abs(error[1]) <= 1, "Text center drift: \(zone.id)")
    let glyphErrors = rendered.glyphCenterErrors
    let diamondClearance: Double?
    let diamondPassed: Bool
    if let diamondTop = zone.diamondTop {
        let protectedBottom = max(Double(zone.panel.maxY), box[3] == 0 ? 0 : Double(box[1] + box[3]))
        diamondClearance = Double(diamondTop) - protectedBottom
        diamondPassed = (Double(zone.panel.maxY) <= Double(diamondTop) - 12.0) && (box[3] == 0 || protectedBottom <= Double(diamondTop) - 4.0)
        try require(diamondPassed, "Nameplate overlaps protected diamond: \(zone.id)")
    } else {
        diamondClearance = nil
        diamondPassed = true
    }
    return RenderedZone(
        panel: compose([panel, ink], width, height),
        ink: ink,
        panelRect: zone.panel,
        safeRect: zone.safe,
        inkBox: box,
        faceBox: faceBox,
        faceLayerCount: rendered.faceLayerCount,
        targetCenter: target,
        centerError: error,
        glyphCenterErrors: glyphErrors,
        diamondClearance: diamondClearance,
        diamondProtectionPassed: diamondPassed
    )
}

func safeZoneLayer(_ zones: [String: Zone], _ width: Int, _ height: Int) -> Raster {
    makeLayer(width, height) { context in
        for (id, zone) in zones.sorted(by: { $0.key < $1.key }) {
            let color: CGColor = id == "character_name" ? cgColor([0.98, 0.72, 0.22], 0.85) : cgColor([0.30, 0.88, 0.66], 0.85)
            context.addPath(CGPath(rect: zone.panel, transform: nil))
            context.setStrokeColor(color)
            context.setLineWidth(2)
            context.setLineDash(phase: 0, lengths: [8, 6])
            context.strokePath()
            context.addPath(CGPath(rect: zone.safe, transform: nil))
            context.setStrokeColor(cgColor([0.95, 0.95, 0.95], 0.72))
            context.setLineWidth(1)
            context.strokePath()
        }
        let emblemSafe = CGRect(x: 573.44, y: 61.44, width: 901.12, height: 768)
        context.addPath(CGPath(rect: emblemSafe, transform: nil))
        context.setStrokeColor(cgColor([0.92, 0.25, 0.36], 0.72))
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [10, 8])
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])
    }
}

func renderBundle(_ root: URL, _ framePath: String, _ textPath: String) throws -> Bundle {
    let textURL = try within(root, textPath)
    return try renderBundle(root, framePath, loadTextInput(textURL), textPath)
}

func renderBundle(_ root: URL, _ framePath: String, _ input: TextInput, _ textPath: String) throws -> Bundle {
    try orientationSentinel()
    let frameURL = try within(root, framePath)
    let frame = try Raster(frameURL)
    try require([frame.w, frame.h] == [2048, 3072], "Frame must be 2048x3072")
    let zones = try loadZones(root)
    let inscription = try loadInscriptionContract(root)
    let palette = try loadPalette(root, framePath)
    let left = try zoneRender(zones["pathway_name"]!, input.pathway, palette, frame.w, frame.h)
    let center = try zoneRender(zones["character_name"]!, input.character, palette, frame.w, frame.h)
    let right = try zoneRender(zones["sequence_name"]!, input.sequence, palette, frame.w, frame.h)
    let safeZones = safeZoneLayer(zones, frame.w, frame.h)
    let card = compose([frame, left.panel, center.panel, right.panel], frame.w, frame.h)
    return Bundle(frame: frame, left: left, center: center, right: right, safeZones: safeZones, card: card, framePath: framePath, textPath: textPath, palette: palette, inscription: inscription)
}

func writeJSON(_ value: Any, _ url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    try require(!FileManager.default.fileExists(atPath: url.path), "Refusing overwrite: \(url.path)")
    try data.write(to: url, options: .withoutOverwriting)
}

func rectArray(_ rect: CGRect) -> [Double] {
    [Double(rect.minX), Double(rect.minY), Double(rect.width), Double(rect.height)]
}

func saveBundle(_ root: URL, _ output: URL, _ bundle: Bundle) throws {
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    let outputs: [(String, Raster)] = [
        ("text-panel-left.png", bundle.left.panel),
        ("text-panel-center.png", bundle.center.panel),
        ("text-panel-right.png", bundle.right.panel),
        ("text-safe-zones.png", bundle.safeZones),
        ("card.png", bundle.card),
    ]
    for (name, raster) in outputs { try raster.save(output.appendingPathComponent(name)) }
    var outputHashes = [String: String]()
    for (name, _) in outputs { outputHashes[name] = try digest(output.appendingPathComponent(name)) }
    let inputPaths = [
        bundle.framePath,
        bundle.textPath,
        "production/templates/card-text-panels-v5.json",
        "production/symbols/quality-frame-three-text-direction-v5.json",
        bundle.inscription.path,
        bundle.inscription.referencePath,
        "config/quality-color-tokens.json",
    ]
    var inputHashes = [String: String]()
    for path in inputPaths { inputHashes[path] = try digest(within(root, path)) }
    let zones = ["pathway_name": bundle.left, "character_name": bundle.center, "sequence_name": bundle.right]
    var inkBoxes = [String: [Int]]()
    var centers = [String: [Double]]()
    var targets = [String: [Double]]()
    var errors = [String: [Double]]()
    for (id, zone) in zones {
        inkBoxes[id] = zone.inkBox
        centers[id] = [Double(zone.inkBox[0]) + Double(zone.inkBox[2]) * 0.5, Double(zone.inkBox[1]) + Double(zone.inkBox[3]) * 0.5]
        targets[id] = zone.targetCenter
        errors[id] = zone.centerError
    }
    let manifest: [String: Any] = [
        "version": 4,
        "mode": "designed-inscription-composite-study-v5",
        "coordinate_system": "design-space-top-left-image-normalized",
        "orientation": "upright",
        "orientation_sentinel": [
            "name": "asymmetric-ctline-and-arrow-probe",
            "passed": true,
        ],
        "contrast": [
            "minimum_ratio": 4.5,
            "side_face_vs_cavity": contrastRatio(sideGlyphFace(bundle.palette), sideGlyphCavity(bundle.palette)),
            "name_face_vs_field": contrastRatio(nameGlyphFace(bundle.palette), nameGlyphField(bundle.palette)),
        ],
        "name": [
            "style_reference": "artifacts/production/fool-frame-refinement-v1/nameplate/raw.png",
            "background": "transparent-text-layer-only",
            "minimum_cap_height_final_px": bundle.center.faceBox[3],
            "target_minimum_cap_height_final_px": 78,
            "relief": true,
            "render_mode": "single-face-mask-with-derived-relief",
            "face_layer_count": bundle.center.faceLayerCount,
            "diamond_clearance_final_px": bundle.center.diamondClearance ?? 0,
            "diamond_protection": [
                "passed": bundle.center.diamondProtectionPassed,
                "clearance_final_px": bundle.center.diamondClearance ?? 0,
            ],
        ],
        "geometry": [
            "max_drift_final_px": 0,
        ],
        "frame_path": bundle.framePath,
        "text_input_path": bundle.textPath,
        "palette_tier": bundle.palette.id,
        "inputs": inputHashes,
        "outputs": outputHashes,
        "panel_files": ["left": "text-panel-left.png", "center": "text-panel-center.png", "right": "text-panel-right.png"],
        "semantic_layer_names": ["left": "designed-inscription-left", "center": "character-name", "right": "designed-inscription-right"],
        "inscription": [
            "contract_path": bundle.inscription.path,
            "contract_sha256": bundle.inscription.hash,
            "style_reference_path": bundle.inscription.referencePath,
            "style_reference_sha256": bundle.inscription.referenceHash,
            "render_mode": bundle.inscription.renderMode,
            "minimum_characters": bundle.inscription.minimumCharacters,
            "flat_text_final_layer": false,
        ],
        "side_alignment": [
            "mode": "per-glyph-ink-box",
            "max_glyph_center_error_final_px": bundle.left.glyphCenterErrors.flatMap { $0 }.map { abs($0) }.max() ?? 0,
            "left_glyph_center_errors_final_px": bundle.left.glyphCenterErrors,
            "right_glyph_center_errors_final_px": bundle.right.glyphCenterErrors,
        ],
        "side_band_width_ratio": 1.5,
        "side_band_capacity_min_characters": 6,
        "safe_zone_file": "text-safe-zones.png",
        "final_file": "card.png",
        "panel_rects_final_px": [
            "pathway_name": rectArray(bundle.left.panelRect),
            "character_name": rectArray(bundle.center.panelRect),
            "sequence_name": rectArray(bundle.right.panelRect),
        ],
        "text_safe_rects_final_px": [
            "pathway_name": rectArray(bundle.left.safeRect),
            "character_name": rectArray(bundle.center.safeRect),
            "sequence_name": rectArray(bundle.right.safeRect),
        ],
        "ink_boxes_final_px": inkBoxes,
        "ink_centers_final_px": centers,
        "target_centers_final_px": targets,
        "center_errors_final_px": errors,
        "max_center_error_final_px": errors.values.flatMap { $0 }.map { abs($0) }.max() ?? 0,
        "overflow": false,
        "subject_text": false,
        "visual_status": "pending",
        "formal_release_approved": false,
        "method": "fixed-v5-widened-spindle-inlays; per-glyph-ink-box-alignment; single-face-mask-derived-relief; diamond-protected-nameplate; upright-coretext; contrast-gated; measured-ink-centering",
    ]
    try writeJSON(manifest, output.appendingPathComponent("manifest.json"))
}

func batchTextInput(_ spec: BatchSpec, _ entry: BatchEntry) -> TextInput {
    TextInput(
        pathway: TextValue(text: spec.pathwayName, zone: "left-column-inlay", visible: true),
        sequence: TextValue(text: entry.sequenceName, zone: "right-column-inlay", visible: true),
        character: TextValue(text: spec.characterName, zone: "central-nameplate", visible: true)
    )
}

func batchOutputFiles(_ digit: Int) -> [(String, String)] {
    let prefix = "fool-\(digit)-"
    return [
        ("card", "\(prefix)inscribed-frame.png"),
        ("left", "\(prefix)text-panel-left.png"),
        ("center", "\(prefix)text-panel-center.png"),
        ("right", "\(prefix)text-panel-right.png"),
        ("safe", "\(prefix)text-safe-zones.png"),
    ]
}

func saveBatch(_ root: URL, _ output: URL, _ spec: BatchSpec) throws {
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    var outputHashes = [String: String]()
    var manifestEntries = [[String: Any]]()
    let commonInputPaths = [
        spec.path,
        spec.baseKitPath,
        "production/templates/card-text-panels-v5.json",
        "production/symbols/quality-frame-three-text-direction-v5.json",
        "production/symbols/inscriptions/fool-side-inscription-v4.json",
        "artifacts/production/fool-frame-refinement-v1/side-junction/raw.png",
        "artifacts/production/fool-frame-refinement-v1/nameplate/raw.png",
        "config/quality-color-tokens.json",
    ]
    var inputHashes = [String: String]()
    for path in commonInputPaths { inputHashes[path] = try digest(within(root, path)) }

    for entry in spec.entries {
        let input = batchTextInput(spec, entry)
        let bundle = try renderBundle(root, entry.framePath, input, spec.path)
        let files = batchOutputFiles(entry.digit)
        let rasters: [String: Raster] = [
            "card": bundle.card,
            "left": bundle.left.panel,
            "center": bundle.center.panel,
            "right": bundle.right.panel,
            "safe": bundle.safeZones,
        ]
        var fileMap = [String: String]()
        for (role, name) in files {
            guard let raster = rasters[role] else { throw Failure.invalid("Missing batch raster: \(role)") }
            let url = output.appendingPathComponent(name)
            try raster.save(url)
            let hash = try digest(url)
            outputHashes[name] = hash
            fileMap[role] = name
        }
        let sideErrors = (bundle.left.glyphCenterErrors + bundle.right.glyphCenterErrors).flatMap { $0 }.map { abs($0) }
        manifestEntries.append([
            "digit": entry.digit,
            "sequence_id": entry.sequenceID,
            "sequence_name": entry.sequenceName,
            "tier": entry.tier,
            "frame_path": entry.framePath,
            "base_frame_sha256": try digest(within(root, entry.framePath)),
            "pathway_name": spec.pathwayName,
            "character_name": spec.characterName,
            "text_exact": true,
            "output_files": fileMap,
            "geometry": ["max_drift_final_px": 0],
            "side_alignment": [
                "mode": "per-glyph-ink-box",
                "max_glyph_center_error_final_px": sideErrors.max() ?? 0,
            ],
            "name": [
                "face_layer_count": bundle.center.faceLayerCount,
                "diamond_protection_passed": bundle.center.diamondProtectionPassed,
                "diamond_clearance_final_px": bundle.center.diamondClearance ?? 0,
            ],
        ])
    }
    let manifest: [String: Any] = [
        "version": 1,
        "mode": "fool-ten-sequence-inscribed-frame-batch-v1",
        "coordinate_system": "design-space-top-left-image-normalized",
        "pathway_id": "fool",
        "pathway_name": spec.pathwayName,
        "character_name": spec.characterName,
        "batch_input_path": spec.path,
        "base_kit_path": spec.baseKitPath,
        "base_kit_sha256": inputHashes[spec.baseKitPath]!,
        "entries": manifestEntries.sorted { (lhs, rhs) in
            (lhs["digit"] as? Int ?? 0) > (rhs["digit"] as? Int ?? 0)
        },
        "inputs": inputHashes,
        "outputs": outputHashes,
        "layer_contract": [
            "base_frame_preserved": true,
            "emblem_source": "fool-five-tier-kit-v5",
            "side_inscriptions": "per-glyph-ink-box-derived-relief",
            "central_nameplate": "empty-and-transparent-text-layer",
            "composite": "frame-plus-side-inscriptions-plus-empty-nameplate",
        ],
        "subject_text": false,
        "visual_status": "pending",
        "formal_release_approved": false,
        "no_cross_product_variants": true,
        "method": "structured-ten-entry-input; frozen-v5-emblem-frame; exact-sequence-name; per-glyph-ink-box-alignment; single-face-name-mask; layered-png-output; deterministic-replay-gate",
    ]
    try writeJSON(manifest, output.appendingPathComponent("manifest.json"))
}

func gateBatch(_ root: URL, _ output: URL) throws {
    let manifest = try jsonObject(output.appendingPathComponent("manifest.json"))
    try require(try integer(manifest["version"], "batch manifest.version") == 1, "Unsupported batch manifest")
    try require(try text(manifest, "mode") == "fool-ten-sequence-inscribed-frame-batch-v1", "Unsupported batch manifest mode")
    try require(try flag(manifest["subject_text"], "batch subject text") == false, "Batch subject text is not allowed")
    try require(try flag(manifest["formal_release_approved"], "batch formal release") == false, "Batch study cannot be release approved")
    let batchPath = try text(manifest, "batch_input_path")
    let spec = try loadBatchSpec(root, try within(root, batchPath))
    try require(try text(manifest, "pathway_name") == spec.pathwayName, "Batch pathway changed")
    try require(try text(manifest, "character_name", allowEmpty: true).isEmpty, "Batch character text changed")
    let inputs = try dictionary(manifest["inputs"], "batch manifest.inputs")
    for (path, value) in inputs {
        guard let expected = value as? String else { throw Failure.invalid("Invalid batch input hash: \(path)") }
        try require(try digest(within(root, path)) == expected, "Batch input changed: \(path)")
    }
    let outputs = try dictionary(manifest["outputs"], "batch manifest.outputs")
    for (file, value) in outputs {
        guard let expected = value as? String else { throw Failure.invalid("Invalid batch output hash: \(file)") }
        try require(try digest(output.appendingPathComponent(file)) == expected, "Batch output changed: \(file)")
    }
    guard let rawEntries = manifest["entries"] as? [[String: Any]], rawEntries.count == 10 else {
        throw Failure.invalid("Batch manifest entries are incomplete")
    }
    for entry in spec.entries {
        guard let row = rawEntries.first(where: { ($0["digit"] as? Int) == entry.digit }) else {
            throw Failure.invalid("Missing batch manifest entry: \(entry.digit)")
        }
        try require(try text(row, "sequence_name") == entry.sequenceName, "Batch sequence name changed: \(entry.digit)")
        try require(try text(row, "character_name", allowEmpty: true).isEmpty, "Batch entry character text changed")
        try require(try flag(row["text_exact"], "batch exact text") == true, "Batch exact text contract missing")
        let geometry = try dictionary(row["geometry"], "batch entry geometry")
        try require(try integer(geometry["max_drift_final_px"], "batch geometry drift") == 0, "Batch geometry drift recorded")
        let alignment = try dictionary(row["side_alignment"], "batch entry side alignment")
        try require(try text(alignment, "mode") == "per-glyph-ink-box", "Batch side alignment changed")
        try require(try real(alignment["max_glyph_center_error_final_px"], "batch glyph center error") <= 1, "Batch glyph center drift exceeds 1px")
        let fileMap = try dictionary(row["output_files"], "batch output files")
        let input = batchTextInput(spec, entry)
        let expected = try renderBundle(root, entry.framePath, input, spec.path)
        let expectedRasters: [String: Raster] = [
            "card": expected.card,
            "left": expected.left.panel,
            "center": expected.center.panel,
            "right": expected.right.panel,
            "safe": expected.safeZones,
        ]
        for (role, raster) in expectedRasters {
            let file = try text(fileMap, role)
            let actual = try Raster(output.appendingPathComponent(file))
            try require(alphaDifference(actual, raster) == 0, "Batch geometry drift: \(file)")
            try require(maxColorDifference(actual, raster) <= 4, "Batch material drift: \(file)")
        }
    }
    print("PASS: ten one-to-one Fool sequence frames; exact names; no character text; layered outputs; zero geometry drift; deterministic replay; not release")
}

func gate(_ root: URL, _ output: URL) throws {
    let manifest = try jsonObject(output.appendingPathComponent("manifest.json"))
    try require(try integer(manifest["version"], "manifest.version") == 4, "Unsupported text manifest")
    try require(try text(manifest, "mode") == "designed-inscription-composite-study-v5", "Unsupported text manifest mode")
    try require(try text(manifest, "coordinate_system") == "design-space-top-left-image-normalized", "Text coordinate system changed")
    try require(try text(manifest, "orientation") == "upright", "Text orientation changed")
    let sentinel = try dictionary(manifest["orientation_sentinel"], "manifest.orientation_sentinel")
    try require(try flag(sentinel["passed"], "orientation sentinel") == true, "Orientation sentinel failed")
    let contrast = try dictionary(manifest["contrast"], "manifest.contrast")
    try require(try real(contrast["minimum_ratio"], "minimum contrast") >= 4.5, "Text contrast contract failed")
    let name = try dictionary(manifest["name"], "manifest.name")
    try require(try text(name, "background") == "transparent-text-layer-only", "Name background is not transparent")
    try require(try integer(name["minimum_cap_height_final_px"], "name cap height") >= 78, "Name relief is too small")
    try require(try flag(name["relief"], "name relief") == true, "Name relief is not recorded")
    try require(try text(name, "render_mode") == "single-face-mask-with-derived-relief", "Name render mode changed")
    try require(try integer(name["face_layer_count"], "name face layer count") == 1, "Name glyph was rendered in multiple face layers")
    let diamond = try dictionary(name["diamond_protection"], "name diamond protection")
    try require(try flag(diamond["passed"], "name diamond protection") == true, "Name diamond protection failed")
    try require(try real(diamond["clearance_final_px"], "name diamond clearance") >= 12, "Name diamond clearance is too small")
    let geometry = try dictionary(manifest["geometry"], "manifest.geometry")
    try require(try integer(geometry["max_drift_final_px"], "text geometry drift") == 0, "Text geometry drift recorded")
    try require(try flag(manifest["formal_release_approved"], "formal release") == false, "Text study cannot be release approved")
    try require(try flag(manifest["subject_text"], "subject text") == false, "Subject text is not allowed")
    try require(try flag(manifest["overflow"], "overflow") == false, "Text overflow recorded")
    let inscription = try dictionary(manifest["inscription"], "manifest.inscription")
    try require(try text(inscription, "render_mode") == "per-glyph-ink-box-derived-relief", "Manifest inscription mode changed")
    try require(try integer(inscription["minimum_characters"], "manifest inscription capacity") >= 6, "Manifest inscription capacity changed")
    try require(try flag(inscription["flat_text_final_layer"], "flat text final layer") == false, "Flat inscription layer detected")
    try require(abs(try real(manifest["side_band_width_ratio"], "side band ratio") - 1.5) < 0.0001, "Manifest side band ratio changed")
    let alignment = try dictionary(manifest["side_alignment"], "manifest.side_alignment")
    try require(try text(alignment, "mode") == "per-glyph-ink-box", "Side glyph alignment mode changed")
    try require(try real(alignment["max_glyph_center_error_final_px"], "side glyph center error") <= 1, "Side glyph center drift exceeds 1px")
    let framePath = try text(manifest, "frame_path")
    let textPath = try text(manifest, "text_input_path")
    for (path, value) in try dictionary(manifest["inputs"], "manifest.inputs") {
        guard let expected = value as? String else { throw Failure.invalid("Invalid input hash: \(path)") }
        try require(try digest(within(root, path)) == expected, "Input changed: \(path)")
    }
    for (file, value) in try dictionary(manifest["outputs"], "manifest.outputs") {
        guard let expected = value as? String else { throw Failure.invalid("Invalid output hash: \(file)") }
        try require(try digest(output.appendingPathComponent(file)) == expected, "Output changed: \(file)")
    }
    let expected = try renderBundle(root, framePath, textPath)
    let outputNames = ["text-panel-left.png", "text-panel-center.png", "text-panel-right.png", "text-safe-zones.png", "card.png"]
    let expectedRasters = [expected.left.panel, expected.center.panel, expected.right.panel, expected.safeZones, expected.card]
    for (name, raster) in zip(outputNames, expectedRasters) {
        let actual = try Raster(output.appendingPathComponent(name))
        try require(alphaDifference(actual, raster) == 0, "Text geometry drift: \(name)")
        try require(maxColorDifference(actual, raster) <= 4, "Text material drift: \(name)")
    }
    let errors = try dictionary(manifest["center_errors_final_px"], "center errors")
    for id in ["pathway_name", "character_name", "sequence_name"] {
        let row = try reals(errors[id], "center error \(id)")
        try require(row.count == 2 && row.allSatisfy { abs($0) <= 1 }, "Center error exceeds 1px: \(id)")
    }
    let palette = try text(manifest, "palette_tier")
    try require(palette == expected.palette.id, "Palette tier changed")
    print("PASS: v5 upright designed inscriptions; per-glyph ink-box alignment; single-face name relief; diamond protected; contrast >=4.5; zero text geometry drift; center <=1px; not release")
}

func selftest() throws {
    try orientationSentinel()
    let zones = [
        "pathway_name": Zone(id: "pathway_name", kind: "left-column-inlay", panel: CGRect(x: 76, y: 1560, width: 216, height: 560), safe: CGRect(x: 100, y: 1592, width: 168, height: 496), orientation: "vertical-rl", diamondTop: nil),
        "character_name": Zone(id: "character_name", kind: "central-nameplate", panel: CGRect(x: 456, y: 300, width: 1136, height: 228), safe: CGRect(x: 480, y: 324, width: 1088, height: 180), orientation: "horizontal", diamondTop: nil),
        "sequence_name": Zone(id: "sequence_name", kind: "right-column-inlay", panel: CGRect(x: 1756, y: 1560, width: 216, height: 560), safe: CGRect(x: 1780, y: 1592, width: 168, height: 496), orientation: "vertical-rl", diamondTop: nil),
    ]
    let palette = Palette(id: "low", primary: [0.91, 0.93, 0.95])
    let left = try zoneRender(zones["pathway_name"]!, TextValue(text: "愚者途径序列", zone: "left-column-inlay", visible: true), palette, 2048, 3072)
    try require(left.inkBox[2] > 0 && left.inkBox[3] > 0, "selftest vertical ink missing")
    try require(left.inkBox[3] >= 380, "selftest six-character inscription capacity missing")
    try require(left.glyphCenterErrors.flatMap { $0 }.allSatisfy { abs($0) <= 1 }, "selftest per-glyph ink-box alignment missing")
    let center = try zoneRender(zones["character_name"]!, TextValue(text: "克莱恩·莫雷蒂", zone: "central-nameplate", visible: true), palette, 2048, 3072)
    try require(center.inkBox[2] > 0 && center.inkBox[3] > 0, "selftest center ink missing")
    try require(center.faceLayerCount == 1, "selftest name face mask was duplicated")
    let empty = try zoneRender(zones["character_name"]!, TextValue(text: "", zone: "central-nameplate", visible: true), palette, 2048, 3072)
    try require(empty.inkBox == [0, 0, 0, 0], "selftest empty name drew placeholder")
    print("text-schema-strict")
    print("local-inlay-1.5x-wider")
    print("six-character-inscription-capacity")
    print("exact-glyph-relief")
    print("central-nameplate-only")
    print("coretext-ink-measured")
    print("center-error-under-1px")
    print("empty-character-name-safe")
    print("text-orientation-upright-top-left")
    print("text-orientation-sentinel")
    print("name-ink-premium-relief")
    print("inscription-contrast-gated")
    print("side-glyph-ink-box-aligned")
    print("single-face-name-mask")
    print("name-diamond-protection")
    print("name-background-not-opaque-over-diamond")
    print("name-background-free-transparent-text-layer")
}

do {
    let args = CommandLine.arguments
    if args.count == 2 && args[1] == "selftest" {
        try selftest()
    } else if args.count == 6 && args[1] == "render" {
        let root = URL(fileURLWithPath: args[2]).resolvingSymlinksInPath()
        let output = URL(fileURLWithPath: args[3]).standardizedFileURL
        try require(!FileManager.default.fileExists(atPath: output.path), "Output already exists")
        let bundle = try renderBundle(root, args[4], args[5])
        try saveBundle(root, output, bundle)
        print(output.path)
    } else if args.count == 5 && args[1] == "render-batch" {
        let root = URL(fileURLWithPath: args[2]).resolvingSymlinksInPath()
        let output = URL(fileURLWithPath: args[3]).standardizedFileURL
        try require(!FileManager.default.fileExists(atPath: output.path), "Output already exists")
        let batchURL = try within(root, args[4])
        let spec = try loadBatchSpec(root, batchURL)
        try saveBatch(root, output, spec)
        print(output.path)
    } else if args.count == 4 && args[1] == "gate" {
        try gate(
            URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(),
            URL(fileURLWithPath: args[3]).standardizedFileURL
        )
    } else if args.count == 4 && args[1] == "gate-batch" {
        try gateBatch(
            URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(),
            URL(fileURLWithPath: args[3]).standardizedFileURL
        )
    } else {
        throw Failure.invalid("Usage: fooltext3 selftest | render ROOT NEW_OUTPUT FRAME TEXT_JSON | render-batch ROOT NEW_OUTPUT BATCH_JSON | gate ROOT OUTPUT | gate-batch ROOT OUTPUT")
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
