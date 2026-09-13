// Deterministic, non-destructive preparation of the existing Fool artwork.
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
    init(_ w: Int, _ h: Int) { self.w = w; self.h = h; p = .init(repeating: 0, count: w*h*4) }
    init(_ url: URL) throws {
        let rep = NSBitmapImageRep(data: try Data(contentsOf: url))
        guard let image = rep?.cgImage else { throw Failure.invalid("Cannot decode \(url.path)") }
        self.init(image.width, image.height)
        p.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8,
                bytesPerRow: w*4, space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        for i in stride(from: 0, to: p.count, by: 4) {
            let a = Int(p[i+3])
            if a > 0 { for c in 0..<3 { p[i+c] = UInt8(min(255, Int(p[i+c])*255/a)) } }
        }
    }
    var image: CGImage {
        var bytes = p
        for i in stride(from: 0, to: bytes.count, by: 4) {
            for c in 0..<3 { bytes[i+c] = UInt8(Int(bytes[i+c])*Int(bytes[i+3])/255) }
        }
        return CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: w*4, space: srgb, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: CGDataProvider(data: Data(bytes) as CFData)!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    }
    func save(_ url: URL) throws {
        try require(!FileManager.default.fileExists(atPath: url.path), "Refusing overwrite: \(url.path)")
        let rep = NSBitmapImageRep(cgImage: image)
        try rep.representation(using: .png, properties: [:])!.write(to: url, options: .withoutOverwriting)
    }
    var alpha: [UInt8] { stride(from: 3, to: p.count, by: 4).map { p[$0] } }
    var bbox: [Int] {
        var x0=w, y0=h, x1 = -1, y1 = -1
        for y in 0..<h { for x in 0..<w where p[(y*w+x)*4+3] > 8 {
            x0=min(x0,x); y0=min(y0,y); x1=max(x1,x); y1=max(y1,y)
        } }
        return x1 < 0 ? [0,0,0,0] : [x0,y0,x1-x0+1,y1-y0+1]
    }
}
func sha(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
func digest(_ url: URL) throws -> String { sha(try Data(contentsOf: url)) }
func within(_ root: URL, _ relative: String) throws -> URL {
    try require(!relative.hasPrefix("/") && !relative.split(separator:"/").contains(".."),"Unsafe relative path")
    let file=root.appendingPathComponent(relative).resolvingSymlinksInPath()
    try require(file.path.hasPrefix(root.path+"/"),"Escaping path")
    return file
}

// Remove large neutral connected regions, including enclosed numeral/eye holes.
// Small neutral islands remain as specular highlights. This is not a semantic matte;
// every real asset requires black/white background visual review.
func cutout(_ source: Raster, tolerance: Int = 7, minRegion: Int = 1000, minNeutral: Int = 55, seeds: [[Int]] = []) -> Raster {
    var result = source
    var visited = [Bool](repeating: false, count: source.w*source.h)
    let forced=Set(seeds.filter { $0.count==2 && $0[0]>=0 && $0[0]<source.w && $0[1]>=0 && $0[1]<source.h }.map { $0[1]*source.w+$0[0] })
    func neutral(_ index: Int) -> Bool {
        let i=index*4, rgb=[Int(source.p[i]),Int(source.p[i+1]),Int(source.p[i+2])]
        return rgb.max()! - rgb.min()! <= tolerance && rgb.min()! >= minNeutral
    }
    for seed in 0..<visited.count where !visited[seed] && neutral(seed) {
        var queue=[seed], cursor=0
        visited[seed]=true
        while cursor < queue.count {
            let v=queue[cursor]; cursor += 1
            let x=v % source.w, y=v / source.w
            let neighbors=[x>0 ? v-1 : -1, x+1<source.w ? v+1 : -1,
                           y>0 ? v-source.w : -1, y+1<source.h ? v+source.w : -1]
            for n in neighbors where n >= 0 && !visited[n] && neutral(n) {
                visited[n]=true; queue.append(n)
            }
        }
        let border = queue.contains { $0 % source.w == 0 || $0 % source.w == source.w-1 || $0/source.w == 0 || $0/source.w == source.h-1 }
        let dark = queue.contains { source.p[$0*4] < 210 }
        if queue.contains(where: { forced.contains($0) }) || (queue.count >= minRegion && (border || dark || queue.count>8000)) {
            for v in queue { result.p[v*4+3]=0 }
        }
    }
    return result
}

// Strip the generated atmosphere from the mother only, then freeze this geometry.
func frameBody(_ source: Raster) -> Raster {
    var result=source
    for i in stride(from: 3, to: result.p.count, by: 4) {
        result.p[i]=UInt8(max(0, min(255, (Int(source.p[i])-128)*255/102)))
    }
    return result
}
func component(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> Int {
    if abs(Double(x)*1024/Double(w)-512)/39 + abs(Double(y)*1536/Double(h)-1429)/40 <= 1 { return 4 }
    if y*1536/h >= 1250 { return 3 } // lower rail + nameplate
    if y*1536/h < 350 { return x < w/2 ? 0 : 1 } // shoulders
    return 2 // side rails with fixed folds
}
func material(_ source: Raster, tier: Int) -> Raster {
    var result=source
    let gems:[[Double]]=[[0.88,0.89,0.93],[0.28,0.57,1.0],[0.69,0.32,1.0],[1.0,0.66,0.15]]
    for y in 0..<source.h { for x in 0..<source.w {
        let i=(y*source.w+x)*4
        if source.p[i+3]==0 { continue }
        let rgb=(0..<3).map { Double(source.p[i+$0])/255 }
        let l=0.2126*rgb[0]+0.7152*rgb[1]+0.0722*rgb[2]
        let jewel=component(x,y,source.w,source.h)==4
        let purple=rgb[2]>rgb[1]*1.08 && rgb[0]>rgb[1]*1.05
        for c in 0..<3 {
            var value=rgb[c]
            if jewel { value=l*(0.35+0.9*gems[tier][c]) }
            else if tier>0 {
                let contrast=[1.0,1.08,1.16,1.20][tier]
                value=(value-0.45)*contrast+0.45
                if purple { value *= [[1,1,1],[1.04,0.94,1.12],[1.12,0.86,1.25],[1.06,0.9,1.18]][tier][c] }
                else if tier==3 { value *= [1.13,1.02,0.80][c] }
                else if tier==2 { value *= [1.02,0.98,1.08][c] }
                else { value *= [0.98,1.02,1.08][c] }
            }
            result.p[i+c]=UInt8(max(0,min(255,(value*255).rounded())))
        }
    } }
    return result
}
func geometryDifference(_ a: Raster, _ b: Raster) throws -> Int {
    try require(a.w==b.w && a.h==b.h, "Geometry canvas mismatch")
    return zip(a.alpha,b.alpha).filter { $0 != $1 }.count
}
func render(_ layers: [(Raster,CGRect)], width: Int, height: Int, background: Bool = false) -> Raster {
    var result=Raster(width,height)
    result.p.withUnsafeMutableBytes { bytes in
        let context=CGContext(data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width*4, space: srgb, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        if background { context.setFillColor(CGColor(srgbRed: 0.035, green: 0.045, blue: 0.075, alpha: 1)); context.fill(CGRect(x:0,y:0,width:width,height:height)) }
        context.interpolationQuality = .high
        for (r,rect) in layers {
            let converted=CGRect(x:rect.minX, y:CGFloat(height)-rect.maxY, width:rect.width, height:rect.height)
            context.draw(r.image,in:converted)
        }
    }
    for i in stride(from:0,to:result.p.count,by:4) {
        let a=Int(result.p[i+3]); if a>0 { for c in 0..<3 { result.p[i+c]=UInt8(min(255,Int(result.p[i+c])*255/a)) } }
    }
    return result
}
func selftest() throws {
    var fixture=Raster(32,32)
    for i in stride(from:0,to:fixture.p.count,by:4) { fixture.p[i]=180;fixture.p[i+1]=180;fixture.p[i+2]=180;fixture.p[i+3]=255 }
    for y in 8..<24 { for x in 8..<24 { let i=(y*32+x)*4; fixture.p[i]=180;fixture.p[i+1]=90;fixture.p[i+2]=30 } }
    fixture.p[(16*32+16)*4]=255;fixture.p[(16*32+16)*4+1]=255;fixture.p[(16*32+16)*4+2]=255
    let clean=cutout(fixture,minRegion:10)
    try require(clean.p[3]==0,"checker matte failed"); print("checker-removed")
    try require(clean.p[(16*32+16)*4+3]==255,"highlight lost"); print("highlight-preserved")
    let seeded=cutout(fixture,minRegion:10,seeds:[[16,16]])
    try require(seeded.p[(16*32+16)*4+3]==0,"small seeded hole retained"); print("seed-hole-removed")
    try require(try geometryDifference(clean,material(clean,tier:3))==0,"material moved alpha"); print("material-alpha-unchanged")
    var shifted=clean;shifted.p[(8*32+8)*4+3]=0
    try require(try geometryDifference(clean,shifted)>0,"shift accepted"); print("shift-rejected")
}
func prepare(_ root: URL, _ out: URL, sample: Bool) throws {
    try require(out.path.hasPrefix(root.appendingPathComponent("artifacts/production/").path+"/"),"Output must be a new artifacts/production child")
    try require(!FileManager.default.fileExists(atPath:out.path),"Output already exists")
    let master=root.appendingPathComponent("artifacts/production/fool-quality-frame-low/v001/raw.png")
    try require(try digest(master)=="4eb5e5d4ce6943140e121b55699cfc3911c8e67450dda898ff77265ce3ed39e1","Master changed")
    try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
    let mattePath="production/symbols/fool-kit-matte.json"
    let matteURL=try within(root,mattePath)
    guard let matte=try JSONSerialization.jsonObject(with:Data(contentsOf:matteURL)) as? [String:Any],
          let settings=matte["entries"] as? [String:[String:Any]] else { throw Failure.invalid("Missing matte settings") }
    var inputs=["artifacts/production/fool-quality-frame-low/v001/raw.png":try digest(master),mattePath:try digest(matteURL)]
    let body=frameBody(try Raster(master))
    let tiers=["low","mid","high","true-god"]
    var frames=[Raster](), stats=[[String:Any]]()
    for tier in 0..<4 {
        let frame=material(body,tier:tier)
        try require(try geometryDifference(body,frame)==0,"Frame geometry drift")
        try frame.save(out.appendingPathComponent("frame-\(tiers[tier]).png"))
        frames.append(frame)
    }
    for part in 0..<5 {
        var mask=body
        for y in 0..<mask.h { for x in 0..<mask.w {
            let i=(y*mask.w+x)*4
            mask.p[i]=255;mask.p[i+1]=255;mask.p[i+2]=255
            if component(x,y,mask.w,mask.h) != part { mask.p[i+3]=0 }
        } }
        try mask.save(out.appendingPathComponent("structure-\(part).png"))
    }
    for digit in (sample ? [9] : Array(0...9)) {
        let source=root.appendingPathComponent("artifacts/production/fool-fusion-\(digit)/v001/raw.png")
        inputs["artifacts/production/fool-fusion-\(digit)/v001/raw.png"]=try digest(source)
        let original=try Raster(source)
        try require([original.w,original.h]==matte["source_size"] as? [Int],"Matte source size changed")
        guard let setting=settings[String(digit)] else { throw Failure.invalid("Missing digit matte") }
        let clean=cutout(original,minNeutral:setting["min_neutral"] as? Int ?? 55,seeds:setting["seeds"] as? [[Int]] ?? [])
        try clean.save(out.appendingPathComponent("emblem-\(digit).png"))
        let b=clean.bbox
        try require(b[3]>0 && clean.alpha.contains(0),"Empty or opaque emblem")
        let tier=digit==0 ? 3 : digit<=4 ? 2 : digit<=7 ? 1 : 0
        let scale=3072.0*0.15/Double(b[3])
        let rect=CGRect(x:1024-Double(b[0])*scale-Double(b[2])*scale/2,
            y:3072*230/1500-Double(b[1])*scale-Double(b[3])*scale/2,
            width:Double(clean.w)*scale,height:Double(clean.h)*scale)
        let layers=[(frames[tier],CGRect(x:0,y:0,width:2048,height:3072)),(clean,rect)]
        try render(layers,width:2048,height:3072).save(out.appendingPathComponent("fool-\(digit)-frame.png"))
        try render(layers,width:2048,height:3072,background:true).save(out.appendingPathComponent("fool-\(digit)-preview.png"))
        stats.append(["digit":digit,"tier":tiers[tier],"source_bbox":b,"visible_height_ratio":0.15,
                      "rect_px":[rect.minX,rect.minY,rect.width,rect.height],"geometry_difference_pixels":0])
    }
    var boardLayers=[(Raster,CGRect)]()
    for (index,item) in stats.enumerated() {
        let digit=item["digit"] as! Int
        let card=try Raster(out.appendingPathComponent("fool-\(digit)-frame.png"))
        boardLayers.append((card,CGRect(x:Double(index%5)*400+20,y:Double(index/5)*600+20,width:360,height:540)))
    }
    try render(boardLayers,width:2000,height:sample ? 600 : 1200,background:true).save(out.appendingPathComponent("contact-sheet.png"))
    let frameLayers=frames.enumerated().map { ($0.element,CGRect(x:$0.offset*400+20,y:20,width:360,height:540)) }
    try render(frameLayers,width:1600,height:600,background:true).save(out.appendingPathComponent("four-frames.png"))
    var white=Raster(1,1);white.p=[255,255,255,255]
    var emblemLayers=[(Raster,CGRect)]()
    for (index,item) in stats.enumerated() {
        let digit=item["digit"] as! Int
        emblemLayers.append((try Raster(out.appendingPathComponent("emblem-\(digit).png")),
                             CGRect(x:index%5*480+20,y:index/5*480+20,width:440,height:440)))
    }
    let atlasHeight=sample ? 480 : 960
    try render([(white,CGRect(x:0,y:0,width:2400,height:atlasHeight))]+emblemLayers,width:2400,height:atlasHeight).save(out.appendingPathComponent("emblems-white.png"))
    try render(emblemLayers,width:2400,height:atlasHeight,background:true).save(out.appendingPathComponent("emblems-dark.png"))
    var outputs=[String:String]()
    for file in try FileManager.default.contentsOfDirectory(at:out,includingPropertiesForKeys:nil) { outputs[file.lastPathComponent]=try digest(file) }
    let record:[String:Any]=["version":1,"mode":"material-study","created_at":ISO8601DateFormatter().string(from:Date()),
        "inputs":inputs,"outputs":outputs,"entries":stats,"native_frame_size":[body.w,body.h],"final_size":[2048,3072],
        "native_final":false,"visual_status":"pending","release_approved":false,
        "method":"native neutral-region matte; single mother structure; per-pixel material grading; fixed-anchor composition",
        "tool_sha256":try digest(root.appendingPathComponent("tools/render/foolkit.swift"))]
    try JSONSerialization.data(withJSONObject:record,options:[.prettyPrinted,.sortedKeys]).write(to:out.appendingPathComponent("manifest.json"),options:.withoutOverwriting)
    print(out.path)
}
func gate(_ root: URL, _ out: URL) throws {
    guard let record=try JSONSerialization.jsonObject(with:Data(contentsOf:out.appendingPathComponent("manifest.json"))) as? [String:Any],
        let inputs=record["inputs"] as? [String:String],let outputs=record["outputs"] as? [String:String],
        let entries=record["entries"] as? [[String:Any]] else { throw Failure.invalid("Bad manifest") }
    try require(record["mode"] as? String == "material-study", "Unsupported mode")
    try require(record["tool_sha256"] as? String == digest(root.appendingPathComponent("tools/render/foolkit.swift")),"Tool changed")
    for (file,hash) in inputs { try require(try digest(within(root,file))==hash,"Input changed: \(file)") }
    for (file,hash) in outputs { try require(try digest(within(out,file))==hash,"Output changed: \(file)") }
    let body=frameBody(try Raster(root.appendingPathComponent("artifacts/production/fool-quality-frame-low/v001/raw.png")))
    let tiers=["low","mid","high","true-god"]
    var frames=[Raster]()
    for tier in 0..<4 {
        let file="frame-\(tiers[tier]).png"
        try require(outputs[file] != nil,"Unbound frame")
        let actual=try Raster(within(out,file))
        let expected=material(body,tier:tier)
        try require(try geometryDifference(actual,expected)==0,"Geometry drift: \(file)")
        // PNG straight/premultiplied conversion may round RGB at semi-transparent edges.
        for i in stride(from:0,to:actual.p.count,by:4) where actual.p[i+3]==255 {
            for c in 0..<3 { try require(actual.p[i+c]==expected.p[i+c],"Internal structure/material differs") }
        }
        frames.append(actual)
    }
    let digits=entries.compactMap { $0["digit"] as? Int }
    try require(digits==[9] || digits==Array(0...9),"Missing/duplicate digits")
    for digit in digits {
        let file="fool-\(digit)-frame.png"
        try require(outputs[file] != nil && outputs["emblem-\(digit).png"] != nil,"Unbound composition")
        let actual=try Raster(within(out,file)), emblem=try Raster(within(out,"emblem-\(digit).png"))
        try require(actual.w==2048 && actual.h==3072 && actual.alpha.contains(0),"Invalid final canvas/alpha")
        let b=emblem.bbox,scale=3072.0*0.15/Double(b[3])
        let rect=CGRect(x:1024-Double(b[0])*scale-Double(b[2])*scale/2,
            y:3072*230/1500-Double(b[1])*scale-Double(b[3])*scale/2,width:Double(emblem.w)*scale,height:Double(emblem.h)*scale)
        let tier=digit==0 ? 3 : digit<=4 ? 2 : digit<=7 ? 1 : 0
        // Reproduce from the canonical material pixels (not redecoded PNG RGB).
        let expected=render([(material(body,tier:tier),CGRect(x:0,y:0,width:2048,height:3072)),(emblem,rect)],width:2048,height:3072)
        try require(try geometryDifference(actual,expected)==0,"Final structure/placement drift")
    }
    print("PASS: \(digits.count) compositions; 4 canonical frames; zero alpha/placement drift; visual review separate; not release")
}
do {
    let args=CommandLine.arguments
    if args.count==2 && args[1]=="selftest" { try selftest() }
    else if args.count==5 && args[1]=="prepare" {
        try require(["sample","all"].contains(args[4]),"Invalid mode")
        try prepare(URL(fileURLWithPath:args[2]).resolvingSymlinksInPath(),URL(fileURLWithPath:args[3]).resolvingSymlinksInPath(),sample:args[4]=="sample")
    } else if args.count==4 && args[1]=="gate" {
        try gate(URL(fileURLWithPath:args[2]).resolvingSymlinksInPath(),URL(fileURLWithPath:args[3]).resolvingSymlinksInPath())
    } else { throw Failure.invalid("Usage: foolkit selftest | prepare ROOT NEW_OUTPUT sample|all | gate ROOT OUTPUT") }
} catch { fputs("\(error)\n",stderr); exit(1) }
