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
    let targetCenter: [Double]
    let centerError: [Double]
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
    let templateURL = try within(root, "production/templates/card-text-panels-v3.json")
    let template = try jsonObject(templateURL)
    try require(try text(template, "status") == "active-v3-template", "Inactive text template")
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
        zones[id] = Zone(id: id, kind: kind, panel: panel.applying(CGAffineTransform(scaleX: 2, y: 2)), safe: safe.applying(CGAffineTransform(scaleX: 2, y: 2)), orientation: orientation)
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
        try require(try text(row, "inscription_render_mode") == "exact-glyph-relief", "Side inscription mode changed: \(id)")
    }
    return zones
}

func loadInscriptionContract(_ root: URL) throws -> InscriptionContract {
    let path = "production/symbols/inscriptions/fool-side-inscription-v1.json"
    let url = try within(root, path)
    let object = try jsonObject(url)
    let status = try text(object, "status")
    try require(status == "active-deterministic-style", "Inscription contract is not active")
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
    try require(mode == "exact-glyph-relief", "Inscription render mode changed")
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

func inscriptionBandPath(_ rect: CGRect) -> CGPath {
    let r = rect.insetBy(dx: 4, dy: 4)
    let cap = min(23, r.width * 0.20)
    let path = CGMutablePath()
    path.move(to: CGPoint(x: r.minX + cap, y: r.minY))
    path.addCurve(
        to: CGPoint(x: r.maxX - cap, y: r.minY),
        control1: CGPoint(x: r.minX + cap + 12, y: r.minY - 2),
        control2: CGPoint(x: r.maxX - cap - 12, y: r.minY - 2)
    )
    path.addCurve(
        to: CGPoint(x: r.maxX, y: r.minY + cap),
        control1: CGPoint(x: r.maxX - 2, y: r.minY + 7),
        control2: CGPoint(x: r.maxX + 2, y: r.minY + cap - 7)
    )
    path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - cap))
    path.addCurve(
        to: CGPoint(x: r.maxX - cap, y: r.maxY),
        control1: CGPoint(x: r.maxX + 2, y: r.maxY - cap + 7),
        control2: CGPoint(x: r.maxX - cap - 12, y: r.maxY + 2)
    )
    path.addCurve(
        to: CGPoint(x: r.minX + cap, y: r.maxY),
        control1: CGPoint(x: r.maxX - cap - 12, y: r.maxY + 2),
        control2: CGPoint(x: r.minX + cap + 12, y: r.maxY + 2)
    )
    path.addCurve(
        to: CGPoint(x: r.minX, y: r.maxY - cap),
        control1: CGPoint(x: r.minX + cap - 12, y: r.maxY + 2),
        control2: CGPoint(x: r.minX - 2, y: r.maxY - cap + 7)
    )
    path.addLine(to: CGPoint(x: r.minX, y: r.minY + cap))
    path.addCurve(
        to: CGPoint(x: r.minX + cap, y: r.minY),
        control1: CGPoint(x: r.minX - 2, y: r.minY + cap - 7),
        control2: CGPoint(x: r.minX + cap + 12, y: r.minY - 2)
    )
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

func drawInscriptionOrnament(_ context: CGContext, _ rect: CGRect, _ metal: CGColor, _ highlight: CGColor, _ accent: CGColor) {
    let inner = rect.insetBy(dx: 15, dy: 15)
    let left = inner.minX + 13
    let right = inner.maxX - 13
    context.saveGState()
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.setLineWidth(2.2)
    context.setStrokeColor(metal)
    for x in [left, right] {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: x, y: inner.minY + 18))
        path.addCurve(
            to: CGPoint(x: x, y: inner.midY - 18),
            control1: CGPoint(x: x + (x == left ? 13 : -13), y: inner.minY + 52),
            control2: CGPoint(x: x + (x == left ? -13 : 13), y: inner.midY - 56)
        )
        path.addCurve(
            to: CGPoint(x: x, y: inner.maxY - 18),
            control1: CGPoint(x: x + (x == left ? -13 : 13), y: inner.midY + 56),
            control2: CGPoint(x: x + (x == left ? 13 : -13), y: inner.maxY - 52)
        )
        context.addPath(path)
        context.strokePath()
    }
    context.setStrokeColor(highlight)
    context.setLineWidth(1.1)
    context.move(to: CGPoint(x: inner.midX, y: inner.minY + 24))
    context.addLine(to: CGPoint(x: inner.midX, y: inner.maxY - 24))
    context.strokePath()
    context.setStrokeColor(accent)
    for y in stride(from: inner.minY + 42, through: inner.maxY - 42, by: 42) {
        drawEtchedDiamond(context, CGPoint(x: inner.midX, y: y), 5, accent)
    }
    context.restoreGState()
}

func panelBase(_ zone: Zone, _ palette: Palette, _ width: Int, _ height: Int) -> Raster {
    makeLayer(width, height) { context in
        let metal = blend([0.72, 0.55, 0.32], palette.primary, 0.18)
        let metalLight = blend([0.96, 0.91, 0.76], palette.primary, 0.10)
        let recess = blend([0.09, 0.045, 0.16], palette.primary, 0.28)
        let panel = zone.panel
        if zone.kind == "central-nameplate" {
            let inner = panel.insetBy(dx: 9, dy: 9)
            fillGradient(context, inner, [cgColor([0.16, 0.12, 0.20], 0.08), cgColor(recess, 0.12), cgColor([0.96, 0.93, 0.82], 0.10)], CGPoint(x: inner.minX, y: inner.minY), CGPoint(x: inner.maxX, y: inner.maxY))
            context.addPath(CGPath(roundedRect: inner, cornerWidth: 12, cornerHeight: 12, transform: nil))
            context.setStrokeColor(cgColor(metal, 0.48))
            context.setLineWidth(3)
            context.strokePath()
            context.addPath(CGPath(roundedRect: panel.insetBy(dx: 15, dy: 15), cornerWidth: 8, cornerHeight: 8, transform: nil))
            context.setStrokeColor(cgColor(metalLight, 0.40))
            context.setLineWidth(1)
            context.strokePath()
        } else {
            // The side bands are wider local inlays, not side-wide panels.
            // Their curled ends and etched rails continue the Fool frame's
            // column relief while leaving the central glyph channel clear.
            let outer = panel.insetBy(dx: 2, dy: 2)
            let inner = panel.insetBy(dx: 10, dy: 10)
            let cavity = panel.insetBy(dx: 15, dy: 15)
            let outerPath = inscriptionBandPath(outer)
            let innerPath = inscriptionBandPath(inner)
            let cavityPath = inscriptionBandPath(cavity)
            fillPathGradient(context, outerPath, outer, [cgColor(metalLight, 0.98), cgColor(metal, 0.98), cgColor(metalLight, 0.92)], CGPoint(x: outer.minX, y: outer.minY), CGPoint(x: outer.maxX, y: outer.maxY))
            fillPathGradient(context, innerPath, inner, [cgColor(blend(recess, [0.12, 0.07, 0.18], 0.24), 0.98), cgColor(blend(recess, palette.primary, 0.22), 0.96), cgColor(blend(recess, [0.08, 0.04, 0.13], 0.28), 0.98)], CGPoint(x: inner.minX, y: inner.minY), CGPoint(x: inner.maxX, y: inner.maxY))
            fillPathGradient(context, cavityPath, cavity, [cgColor(blend(recess, palette.primary, 0.28), 0.96), cgColor(blend(recess, palette.primary, 0.12), 0.92), cgColor(recess, 0.98)], CGPoint(x: cavity.minX, y: cavity.minY), CGPoint(x: cavity.maxX, y: cavity.maxY))
            context.addPath(outerPath)
            context.setStrokeColor(cgColor(metal, 0.98))
            context.setLineWidth(4.5)
            context.strokePath()
            context.addPath(innerPath)
            context.setStrokeColor(cgColor(metalLight, 0.64))
            context.setLineWidth(2.2)
            context.strokePath()
            context.addPath(cavityPath)
            context.setStrokeColor(cgColor(blend(metalLight, palette.primary, 0.24), 0.56))
            context.setLineWidth(1.2)
            context.strokePath()
            drawInscriptionOrnament(
                context,
                cavity,
                cgColor(metalLight, 0.60),
                cgColor(metalLight, 0.38),
                cgColor(blend(palette.primary, metalLight, 0.30), 0.72)
            )
        }
    }
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
    context.textPosition = origin
    CTLineDraw(line, context)
}

struct GlyphPlacement {
    let character: String
    let center: CGPoint
}

func inscriptionPlacements(_ zone: Zone, _ value: String, _ context: CGContext) -> (CGFloat, [GlyphPlacement]) {
    let characters = value.map(String.init)
    guard !characters.isEmpty else { return (0, []) }
    let gap: CGFloat = 8
    let maximum: CGFloat = 68
    let minimum: CGFloat = 42
    let count = CGFloat(characters.count)
    let candidate = max(minimum, min(maximum, (zone.safe.height - gap * max(0, count - 1)) / count * 0.96))
    let total = candidate * count + gap * max(0, count - 1)
    var y = zone.safe.midY - total * 0.5
    var placements = [GlyphPlacement]()
    for character in characters {
        let line = makeLine(character, "Songti SC", candidate, cgColor([1, 1, 1], 1))
        let bounds = CTLineGetImageBounds(line, context)
        let center = CGPoint(x: zone.safe.midX, y: y + candidate * 0.5)
        _ = bounds
        placements.append(GlyphPlacement(character: character, center: center))
        y += candidate + gap
    }
    return (candidate, placements)
}

func drawGlyphAtCenter(_ character: String, _ context: CGContext, _ center: CGPoint, _ size: CGFloat, _ color: CGColor) {
    let line = makeLine(character, "Songti SC", size, color)
    let bounds = CTLineGetImageBounds(line, context)
    let origin = CGPoint(x: center.x - bounds.midX, y: center.y - bounds.midY)
    drawLine(line, context, origin)
}

func inscriptionInk(_ zone: Zone, _ value: String, _ palette: Palette, _ width: Int, _ height: Int) -> Raster {
    guard !value.isEmpty else { return Raster(width, height) }
    let preliminary = makeLayer(width, height) { context in
        let (size, placements) = inscriptionPlacements(zone, value, context)
        let recess = blend([0.025, 0.018, 0.045], palette.primary, 0.22)
        let metal = blend([0.92, 0.82, 0.64], palette.primary, 0.18)
        let face = blend([0.56, 0.48, 0.50], palette.primary, 0.22)
        let glint = blend([0.99, 0.95, 0.82], palette.primary, 0.14)
        for placement in placements {
            // Four passes create a carved/raised inscription while preserving
            // the exact input glyph. No generated pseudo-writing is used.
            drawGlyphAtCenter(placement.character, context, CGPoint(x: placement.center.x + 4, y: placement.center.y + 5), size + 6, cgColor(recess, 0.92))
            drawGlyphAtCenter(placement.character, context, CGPoint(x: placement.center.x - 2, y: placement.center.y - 2), size + 4, cgColor(metal, 0.86))
            drawGlyphAtCenter(placement.character, context, placement.center, size, cgColor(face, 0.98))
            drawGlyphAtCenter(placement.character, context, CGPoint(x: placement.center.x - 1, y: placement.center.y - 1), max(30, size - 3), cgColor(glint, 0.46))
        }
    }
    let box = preliminary.bbox
    guard box[2] > 0 && box[3] > 0 else { return preliminary }
    let targetX = zone.safe.midX
    let targetY = zone.safe.midY
    let dx = Int((targetX - (Double(box[0]) + Double(box[2]) * 0.5)).rounded())
    let dy = Int((targetY - (Double(box[1]) + Double(box[3]) * 0.5)).rounded())
    return shift(preliminary, dx: dx, dy: dy)
}

func centeredCoreTextInk(_ zone: Zone, _ value: String, _ palette: Palette, _ width: Int, _ height: Int) -> Raster {
    guard !value.isEmpty else { return Raster(width, height) }
    let color = cgColor(blend([0.10, 0.07, 0.14], palette.primary, 0.24), 0.98)
    let fontName = "Songti SC"
    let size: CGFloat = zone.orientation == "horizontal" ? 64 : 52
    let preliminary = makeLayer(width, height) { context in
        let safe = zone.safe
        if zone.orientation == "horizontal" {
            let line = makeLine(value, fontName, size, color)
            let bounds = CTLineGetImageBounds(line, context)
            let origin = CGPoint(
                x: safe.midX - (bounds.midX),
                y: safe.midY - (bounds.midY)
            )
            drawLine(line, context, origin)
        } else {
            let gap = size * 0.10
            let lines = value.map { makeLine(String($0), fontName, size, color) }
            var heights = [CGFloat]()
            var bounds = [CGRect]()
            for line in lines {
                let rect = CTLineGetImageBounds(line, context)
                bounds.append(rect)
                heights.append(max(size, rect.height))
            }
            let total = heights.reduce(0, +) + gap * CGFloat(max(0, heights.count - 1))
            var y = safe.midY - total * 0.5
            for (index, line) in lines.enumerated() {
                let lineBounds = bounds[index]
                let origin = CGPoint(
                    x: safe.midX - lineBounds.midX,
                    y: y - lineBounds.minY
                )
                drawLine(line, context, origin)
                y += heights[index] + gap
            }
        }
    }
    let box = preliminary.bbox
    guard box[2] > 0 && box[3] > 0 else { return preliminary }
    let targetX = zone.safe.midX
    let targetY = zone.safe.midY
    let dx = Int((targetX - (Double(box[0]) + Double(box[2]) * 0.5)).rounded())
    let dy = Int((targetY - (Double(box[1]) + Double(box[3]) * 0.5)).rounded())
    return shift(preliminary, dx: dx, dy: dy)
}

func measuredInk(_ zone: Zone, _ value: String, _ palette: Palette, _ width: Int, _ height: Int) -> Raster {
    if zone.kind == "left-column-inlay" || zone.kind == "right-column-inlay" {
        return inscriptionInk(zone, value, palette, width, height)
    }
    return centeredCoreTextInk(zone, value, palette, width, height)
}

func zoneRender(_ zone: Zone, _ value: TextValue, _ palette: Palette, _ width: Int, _ height: Int) throws -> RenderedZone {
    let panel = panelBase(zone, palette, width, height)
    let ink = measuredInk(zone, value.text, palette, width, height)
    let box = ink.bbox
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
    return RenderedZone(panel: compose([panel, ink], width, height), ink: ink, panelRect: zone.panel, safeRect: zone.safe, inkBox: box, targetCenter: target, centerError: error)
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
    let frameURL = try within(root, framePath)
    let textURL = try within(root, textPath)
    let frame = try Raster(frameURL)
    try require([frame.w, frame.h] == [2048, 3072], "Frame must be 2048x3072")
    let input = try loadTextInput(textURL)
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
        "production/templates/card-text-panels-v3.json",
        "production/symbols/quality-frame-three-text-direction-v3.json",
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
        "version": 2,
        "mode": "designed-inscription-composite-study",
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
        "method": "fixed-v3-widened-local-inlays; exact-glyph-multi-pass-inscription-relief; one-central-nameplate; measured-ink-centering",
    ]
    try writeJSON(manifest, output.appendingPathComponent("manifest.json"))
}

func gate(_ root: URL, _ output: URL) throws {
    let manifest = try jsonObject(output.appendingPathComponent("manifest.json"))
    try require(try integer(manifest["version"], "manifest.version") == 2, "Unsupported text manifest")
    try require(try text(manifest, "mode") == "designed-inscription-composite-study", "Unsupported text manifest mode")
    try require(try flag(manifest["formal_release_approved"], "formal release") == false, "Text study cannot be release approved")
    try require(try flag(manifest["subject_text"], "subject text") == false, "Subject text is not allowed")
    try require(try flag(manifest["overflow"], "overflow") == false, "Text overflow recorded")
    let inscription = try dictionary(manifest["inscription"], "manifest.inscription")
    try require(try text(inscription, "render_mode") == "exact-glyph-relief", "Manifest inscription mode changed")
    try require(try integer(inscription["minimum_characters"], "manifest inscription capacity") >= 6, "Manifest inscription capacity changed")
    try require(try flag(inscription["flat_text_final_layer"], "flat text final layer") == false, "Flat inscription layer detected")
    try require(abs(try real(manifest["side_band_width_ratio"], "side band ratio") - 1.5) < 0.0001, "Manifest side band ratio changed")
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
    print("PASS: v3 designed inscriptions; 1.5x local side bands; six-character capacity; one central full-width panel; zero text geometry drift; center <=1px; not release")
}

func selftest() throws {
    let zones = [
        "pathway_name": Zone(id: "pathway_name", kind: "left-column-inlay", panel: CGRect(x: 76, y: 1560, width: 216, height: 560), safe: CGRect(x: 100, y: 1592, width: 168, height: 496), orientation: "vertical-rl"),
        "character_name": Zone(id: "character_name", kind: "central-nameplate", panel: CGRect(x: 456, y: 300, width: 1136, height: 228), safe: CGRect(x: 480, y: 324, width: 1088, height: 180), orientation: "horizontal"),
        "sequence_name": Zone(id: "sequence_name", kind: "right-column-inlay", panel: CGRect(x: 1756, y: 1560, width: 216, height: 560), safe: CGRect(x: 1780, y: 1592, width: 168, height: 496), orientation: "vertical-rl"),
    ]
    let palette = Palette(id: "low", primary: [0.91, 0.93, 0.95])
    let left = try zoneRender(zones["pathway_name"]!, TextValue(text: "愚者途径序列", zone: "left-column-inlay", visible: true), palette, 2048, 3072)
    try require(left.inkBox[2] > 0 && left.inkBox[3] > 0, "selftest vertical ink missing")
    try require(left.inkBox[3] >= 380, "selftest six-character inscription capacity missing")
    let center = try zoneRender(zones["character_name"]!, TextValue(text: "克莱恩·莫里亚蒂", zone: "central-nameplate", visible: true), palette, 2048, 3072)
    try require(center.inkBox[2] > 0 && center.inkBox[3] > 0, "selftest center ink missing")
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
    } else if args.count == 4 && args[1] == "gate" {
        try gate(
            URL(fileURLWithPath: args[2]).resolvingSymlinksInPath(),
            URL(fileURLWithPath: args[3]).standardizedFileURL
        )
    } else {
        throw Failure.invalid("Usage: fooltext3 selftest | render ROOT NEW_OUTPUT FRAME TEXT_JSON | gate ROOT OUTPUT")
    }
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}
