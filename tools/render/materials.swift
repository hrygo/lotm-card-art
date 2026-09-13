import AppKit
import CoreText
import ImageIO
import CoreImage
import UniformTypeIdentifiers

enum RenderError: Error { case invalid(String) }
func fail(_ message: String) throws -> Never { throw RenderError.invalid(message) }
func number(_ value: Any?) -> CGFloat { (value as? NSNumber).map { CGFloat(truncating: $0) } ?? 0 }
func rectangle(_ value: Any?) throws -> CGRect {
    guard let a = value as? [NSNumber], a.count == 4 else { try fail("invalid rect") }
    return CGRect(x: CGFloat(truncating:a[0]), y: CGFloat(truncating:a[1]),
                  width: CGFloat(truncating:a[2]), height: CGFloat(truncating:a[3]))
}
func color(_ hex: String) throws -> CGColor {
    guard hex.count == 7, hex.first == "#", let n = UInt32(hex.dropFirst(),radix:16) else { try fail("invalid color") }
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    return CGColor(colorSpace: space, components: [CGFloat((n>>16)&255)/255,CGFloat((n>>8)&255)/255,CGFloat(n&255)/255,1])!
}
func image(_ path: String) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath:path) as CFURL,nil),
          let img = CGImageSourceCreateImageAtIndex(source,0,[kCGImageSourceShouldCacheImmediately:true] as CFDictionary)
    else { try fail("cannot decode image: "+path) }
    return img
}
func save(_ img: CGImage, _ url: URL) throws {
    guard !FileManager.default.fileExists(atPath:url.path),
          let dest = CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)
    else { try fail("output exists/unavailable") }
    CGImageDestinationAddImage(dest,img,[kCGImagePropertyPNGDictionary:[kCGImagePropertyPNGsRGBIntent:0]] as CFDictionary)
    guard CGImageDestinationFinalize(dest) else { try fail("PNG write failed") }
}
func context(_ width: Int,_ height: Int) throws -> CGContext {
    guard let c=CGContext(data:nil,width:width,height:height,bitsPerComponent:8,bytesPerRow:width*4,
        space:CGColorSpace(name:CGColorSpace.sRGB)!,
        bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else { try fail("cannot allocate bitmap") }
    c.interpolationQuality = .high
    return c
}
func paintSource(_ request: [String:Any], _ width: Int, _ height: Int) throws -> (CGImage,[[String:Any]]) {
    let c=try context(width,height)
    if request["background"] as? String != "none" {
        c.setFillColor(try color(request["background"] as! String))
        c.fill(CGRect(x:0,y:0,width:width,height:height))
    }
    c.translateBy(x:0,y:CGFloat(height));c.scaleBy(x:CGFloat(width)/1000,y: -CGFloat(height)/1500)
    var fonts=[[String:Any]]()
    for layer in request["layers"] as! [[String:Any]] {
        let img=try image(layer["path"] as! String)
        let r=try rectangle(layer["rect"])
        let sx=r.width/CGFloat(img.width),sy=r.height/CGFloat(img.height)
        let scale=(layer["fit"] as! String)=="cover" ? max(sx,sy):min(sx,sy)
        let target=CGRect(x:r.midX-CGFloat(img.width)*scale/2,y:r.midY-CGFloat(img.height)*scale/2,
                          width:CGFloat(img.width)*scale,height:CGFloat(img.height)*scale)
        c.saveGState();c.clip(to:r);c.setAlpha(number(layer["opacity"]))
        c.translateBy(x:target.minX,y:target.maxY);c.scaleBy(x:1,y:-1)
        c.draw(img,in:CGRect(origin:.zero,size:target.size));c.restoreGState()
    }
    for s in request["shapes"] as! [[String:Any]] {
        let r=try rectangle(s["rect"]);let kind=s["kind"] as! String
        if kind=="text" {
            let text=s["text"] as! String, requested=s["font"] as! String
            let font=CTFontCreateWithName(requested as CFString,number(s["size"]),nil)
            let resolved=CTFontCopyPostScriptName(font) as String
            let paragraph=NSMutableParagraphStyle()
            switch s["align"] as? String ?? "left" {
                case "center":paragraph.alignment = .center
                case "right":paragraph.alignment = .right
                default:paragraph.alignment = .left
            }
            paragraph.lineBreakMode = .byWordWrapping
            let attrs:[NSAttributedString.Key:Any]=[
                NSAttributedString.Key(kCTFontAttributeName as String):font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String):try color(s["fill"] as? String ?? "#ffffff"),
                .paragraphStyle:paragraph]
            let attributed=NSAttributedString(string:text,attributes:attrs)
            let setter=CTFramesetterCreateWithAttributedString(attributed)
            let size=CTFramesetterSuggestFrameSizeWithConstraints(setter,CFRange(location:0,length:0),nil,CGSize(width:r.width,height:10000),nil)
            guard ceil(size.height)<=r.height+1 else { try fail("text overflow: "+text) }
            // CoreText requires y-up glyph space within the y-down design canvas.
            c.saveGState();c.translateBy(x:r.minX,y:r.maxY);c.scaleBy(x:1,y:-1);c.textMatrix = .identity
            let path=CGPath(rect:CGRect(x:0,y:0,width:r.width,height:r.height),transform:nil)
            let frame=CTFramesetterCreateFrame(setter,CFRange(location:0,length:attributed.length),path,nil)
            let visible=CTFrameGetVisibleStringRange(frame)
            guard visible.length==attributed.length else { try fail("text truncated: "+text) }
            CTFrameDraw(frame,c);c.restoreGState()
            var used=Set<String>()
            for line in CTFrameGetLines(frame) as! [CTLine] {
                for run in CTLineGetGlyphRuns(line) as! [CTRun] {
                    let runAttrs=CTRunGetAttributes(run) as NSDictionary
                    if let runFont=runAttrs[kCTFontAttributeName] {
                        let actual=runFont as! CTFont
                        used.insert(CTFontCopyPostScriptName(actual) as String)
                    }
                    let count=CTRunGetGlyphCount(run)
                    var glyphs=[CGGlyph](repeating:0,count:count)
                    CTRunGetGlyphs(run,CFRange(location:0,length:0),&glyphs)
                    guard !glyphs.contains(0) else { try fail("missing glyph in: "+text) }
                }
            }
            fonts.append(["requested":requested,"resolved":resolved,"runs":used.sorted(),"text":text])
            continue
        }
        let p=CGMutablePath()
        if kind=="rect" { p.addRect(r) }
        else if kind=="ellipse" { p.addEllipse(in:r) }
        else if kind=="path" {
            for command in s["commands"] as! [[Any]] {
                switch command[0] as! String {
                case "M":p.move(to:CGPoint(x:number(command[1]),y:number(command[2])))
                case "L":p.addLine(to:CGPoint(x:number(command[1]),y:number(command[2])))
                case "C":p.addCurve(to:CGPoint(x:number(command[5]),y:number(command[6])),
                    control1:CGPoint(x:number(command[1]),y:number(command[2])),
                    control2:CGPoint(x:number(command[3]),y:number(command[4])))
                case "Z":p.closeSubpath()
                default:try fail("unsupported path command")
                }
            }
        } else { try fail("unknown shape") }
        if let fill=s["fill"] as? String,fill != "none" {
            c.addPath(p);c.setFillColor(try color(fill));c.fillPath(using: .evenOdd)
        }
        if let stroke=s["stroke"] as? String,stroke != "none" {
            c.addPath(p);c.setStrokeColor(try color(stroke));c.setLineWidth(number(s["line_width"] ?? 1))
            c.setLineJoin(.round);c.setLineCap(.round);c.strokePath()
        }
    }
    guard let img=c.makeImage() else { try fail("bitmap failed") }
    return (img,fonts)
}
let ci = CIContext(options: [.workingColorSpace:CGColorSpace(name:CGColorSpace.sRGB)!,
                            .outputColorSpace:CGColorSpace(name:CGColorSpace.sRGB)!])
func pixelData(_ img: CGImage) throws -> CGContext {
    let c=try context(img.width,img.height)
    c.draw(img,in:CGRect(x:0,y:0,width:img.width,height:img.height))
    return c
}
func alphaStats(_ img: CGImage) throws -> [String:Any] {
    let c=try pixelData(img)
    let bytes=c.data!.assumingMemoryBound(to:UInt8.self)
    var transparent=0,partial=0,opaque=0
    for i in 0..<(img.width*img.height) {
        switch bytes[i*4+3] {
        case 0:transparent += 1
        case 255:opaque += 1
        default:partial += 1
        }
    }
    return ["width":img.width,"height":img.height,"transparent":transparent,
            "partial":partial,"opaque":opaque,"has_real_transparency":transparent+partial>0]
}
func paintNodes(_ req:[String:Any],_ width:Int,_ height:Int) throws -> (CGImage,[[String:Any]]) {
    let c=try context(width,height)
    let extent=CGRect(x:0,y:0,width:width,height:height)
    if req["background"] as? String != "none" {
        c.setFillColor(try color(req["background"] as! String));c.fill(extent)
    }
    var fonts=[[String:Any]]()
    let scale=CGFloat(width)/1000
    for node in req["nodes"] as! [[String:Any]] {
        var layers=[[String:Any]]()
        if let path=node["path"] as? String {
            layers=[["path":path,"rect":node["rect"]!,"fit":node["fit"] ?? "cover","opacity":1]]
        }
        let sourceReq:[String:Any]=["background":"none","layers":layers,"shapes":node["shapes"] ?? []]
        let (raw,used)=try paintSource(sourceReq,width,height)
        fonts += used
        var processed=CIImage(cgImage:raw)
        if node["brightness"] != nil || node["saturation"] != nil {
            processed=processed.applyingFilter("CIColorControls",parameters:[
                kCIInputBrightnessKey:number(node["brightness"]),
                kCIInputSaturationKey:number(node["saturation"] ?? 1)])
        }
        if let masks=node["mask"] as? [[String:Any]] {
            let maskReq:[String:Any]=["background":"none","layers":[],"shapes":masks]
            let (mask,_)=try paintSource(maskReq,width,height)
            var maskCI=CIImage(cgImage:mask)
            let feather=number(node["feather"])*scale
            if feather>0 {
                maskCI=maskCI.applyingFilter("CIGaussianBlur",parameters:[kCIInputRadiusKey:feather]).cropped(to:extent)
            }
            processed=processed.applyingFilter("CIBlendWithAlphaMask",parameters:[
                kCIInputBackgroundImageKey:CIImage(color:.clear).cropped(to:extent),
                kCIInputMaskImageKey:maskCI])
        }
        guard let img=ci.createCGImage(processed,from:extent) else { try fail("material filter failed") }
        c.saveGState()
        let modes:[String:CGBlendMode]=["normal":.normal,"multiply":.multiply,"screen":.screen,"soft-light":.softLight]
        guard let blend=modes[node["blend"] as? String ?? "normal"] else { try fail("invalid blend") }
        c.setBlendMode(blend);c.setAlpha(number(node["opacity"] ?? 1))
        if let shadow=node["shadow"] as? [String:Any] {
            c.setShadow(offset:CGSize(width:number(shadow["x"])*scale,height: -number(shadow["y"])*scale),
                        blur:number(shadow["blur"])*scale,
                        color:CGColor(gray:0,alpha:number(shadow["opacity"])))
        }
        c.draw(img,in:extent);c.restoreGState()
    }
    guard let result=c.makeImage() else { try fail("material bitmap failed") }
    return (result,fonts)
}
do {
    guard CommandLine.arguments.count==3 else { try fail("usage: materials request.json output-dir") }
    let data=try Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1]))
    guard let req=try JSONSerialization.jsonObject(with:data) as? [String:Any],
          let width=req["width"] as? Int,let height=req["height"] as? Int,
          width>0,height>0,width<=8192,height<=8192 else { try fail("bad request") }
    let out=URL(fileURLWithPath:CommandLine.arguments[2],isDirectory:true)
    let (img,fonts)=try paintNodes(req,width,height)
    try save(img,out.appendingPathComponent("final.png"))
    let (preview,_)=try paintNodes(req,360,540)
    try save(preview,out.appendingPathComponent("preview.png"))
    var inputs=[[String:Any]](),seen=Set<String>()
    for node in req["nodes"] as! [[String:Any]] {
        if let path=node["path"] as? String,seen.insert(path).inserted {
            inputs.append(["path":path,"alpha":try alphaStats(image(path))])
        }
    }
    var probes=[[String:Any]]()
    let pixels=try pixelData(img)
    let bytes=pixels.data!.assumingMemoryBound(to:UInt8.self)
    for point in req["probes"] as? [[Double]] ?? [] {
        guard point.count==2 else { try fail("bad probe") }
        let x=min(width-1,max(0,Int(point[0]*Double(width)/1000)))
        let y=min(height-1,max(0,Int(point[1]*Double(height)/1500)))
        let i=(y*width+x)*4
        probes.append(["point":point,"rgba":(0..<4).map { Int(bytes[i+$0]) }])
    }
    let metadata:[String:Any]=["engine":"Swift material compositor v2","width":width,"height":height,
        "color_space":"sRGB","fonts":fonts,"decode":"CGImageSource full raster decode",
        "inputs":inputs,"output_alpha":try alphaStats(img),"probes":probes,
        "node_order":(req["nodes"] as! [[String:Any]]).map { $0["id"] as! String }]
    try JSONSerialization.data(withJSONObject:metadata,options:[.prettyPrinted,.sortedKeys])
        .write(to:out.appendingPathComponent("renderer.json"),options:.withoutOverwriting)
} catch {
    FileHandle.standardError.write(Data(("render error: \(error)\n").utf8));exit(2)
}

