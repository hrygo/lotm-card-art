// Frozen, single-card composition. This is not the general production release gate.
import AppKit
import CoreText
import ImageIO
import CryptoKit

enum Failure: Error { case invalid(String) }
func demand(_ ok: Bool, _ message: String) throws { if !ok { throw Failure.invalid(message) } }
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let framePath = "artifacts/production/fool-frame-kit-v3/fool-9-frame.png"
let frameHash = "dcb9b820c95e85707371be7515c17607e19f3817d6c82c3945925e0b1c20e7aa"
let width = 2048, height = 3072
let sceneRect = CGRect(x: 246, y: 780, width: 1556, height: 1730)
let nameRect = CGRect(x: 544, y: 2605, width: 960, height: 130)
let fm = FileManager.default
func digest(_ data: Data) -> String { SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined() }
func fileHash(_ path: String) throws -> String { digest(try Data(contentsOf:URL(fileURLWithPath:path))) }
func safe(_ root:String,_ relative:String) throws -> String {
    try demand(!relative.hasPrefix("/") && !relative.split(separator:"/").contains(".."),"relative path required")
    let base=URL(fileURLWithPath:root).resolvingSymlinksInPath().standardizedFileURL.path
    let path=URL(fileURLWithPath:base).appendingPathComponent(relative).resolvingSymlinksInPath().standardizedFileURL.path
    try demand(path.hasPrefix(base+"/"),"path escapes root"); return path
}
struct Raster {
    let w:Int, h:Int
    var bytes:[UInt8] // premultiplied RGBA, top-left rows
    init(_ w:Int,_ h:Int) { self.w=w;self.h=h;bytes=[UInt8](repeating:0,count:w*h*4) }
    init(_ image:CGImage) throws {
        self.init(image.width,image.height)
        let size=CGRect(x:0,y:0,width:image.width,height:image.height)
        try draw { c in c.draw(image,in:size) }
    }
    mutating func draw(_ body:(CGContext)->Void) throws {
        let w=self.w,h=self.h
        try bytes.withUnsafeMutableBytes { p in
            guard let c=CGContext(data:p.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:space,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue) else {throw Failure.invalid("context")}
            c.interpolationQuality = .high; body(c)
        }
    }
    func image() throws -> CGImage {
        guard let provider=CGDataProvider(data:Data(bytes) as CFData),let result=CGImage(width:w,height:h,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:w*4,space:space,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent) else {throw Failure.invalid("image")};return result
    }
    func save(_ path:String) throws {
        guard let d=CGImageDestinationCreateWithURL(URL(fileURLWithPath:path) as CFURL,"public.png" as CFString,1,nil) else {throw Failure.invalid("destination")}
        CGImageDestinationAddImage(d,try image(),nil);try demand(CGImageDestinationFinalize(d),"encode")
    }
    func bbox(_ threshold:UInt8=32) -> CGRect? {
        var x0=w,y0=h,x1 = -1,y1 = -1
        for y in 0..<h {for x in 0..<w where bytes[(y*w+x)*4+3]>threshold {x0=min(x0,x);y0=min(y0,y);x1=max(x1,x);y1=max(y1,y)}}
        return x1<0 ? nil : CGRect(x:x0,y:y0,width:x1-x0+1,height:y1-y0+1)
    }
}
func loadImage(_ path:String) throws -> Raster {
    guard let s=CGImageSourceCreateWithURL(URL(fileURLWithPath:path) as CFURL,nil),let i=CGImageSourceCreateImageAtIndex(s,0,nil) else {throw Failure.invalid("decode: "+path)}
    try demand(i.width*i.height<=40_000_000,"image too large"); return try Raster(i)
}
func canvas() -> Raster { Raster(width,height) }
func identical(_ a:Raster,_ b:Raster)->Bool {a.w==b.w && a.h==b.h && a.bytes==b.bytes}
func composite(_ under:Raster,_ over:Raster) throws -> Raster {
    try demand(under.w==over.w && under.h==over.h,"size mismatch");var out=under
    for i in stride(from:0,to:out.bytes.count,by:4) {let a=Int(over.bytes[i+3]);for k in 0..<4 {out.bytes[i+k]=UInt8(min(255,Int(over.bytes[i+k])+(Int(under.bytes[i+k])*(255-a)+127)/255))}}
    return out
}
func clipped(_ input:Raster,_ mask:Raster) throws -> Raster {
    try demand(input.w==mask.w && input.h==mask.h,"mask size");var out=input
    for i in stride(from:0,to:out.bytes.count,by:4) {for k in 0..<4 {out.bytes[i+k]=UInt8((Int(input.bytes[i+k])*Int(mask.bytes[i+3])+127)/255)}};return out
}
func domainOK(_ image:Raster,_ mask:Raster)->Bool {
    guard image.w==mask.w && image.h==mask.h else {return false}
    for i in stride(from:0,to:image.bytes.count,by:4) where mask.bytes[i+3]==0 {if image.bytes[i+3]>0{return false}};return true
}
func placed(_ src:Raster,_ rect:CGRect,_ ink:Bool=false,topAligned:Bool=false) throws -> Raster {
    let b=ink ? src.bbox() : CGRect(x:0,y:0,width:src.w,height:src.h)
    guard let b=b else {throw Failure.invalid("empty ink")}
    let s=ink ? min(rect.width/b.width,rect.height/b.height) : max(rect.width/b.width,rect.height/b.height)
    let r=CGRect(x:rect.midX-b.midX*s,y:topAligned ? rect.minY : rect.midY-b.midY*s,width:CGFloat(src.w)*s,height:CGFloat(src.h)*s)
    let image=try src.image();var out=canvas()
    try out.draw {c in c.translateBy(x:0,y:CGFloat(height));c.scaleBy(x:1,y:-1);c.clip(to:rect);c.translateBy(x:r.minX,y:r.maxY);c.scaleBy(x:1,y:-1);c.draw(image,in:CGRect(origin:.zero,size:r.size))};return out
}
func masks() throws -> (Raster,Raster) {
    var plate=canvas(),scene=canvas()
    try plate.draw {c in
        c.translateBy(x:0,y:CGFloat(height));c.scaleBy(x:2.048,y:-2.048)
        let p=CGMutablePath();p.move(to:CGPoint(x:62,y:170))
        p.addCurve(to:CGPoint(x:250,y:115),control1:CGPoint(x:150,y:178),control2:CGPoint(x:213,y:133))
        p.addCurve(to:CGPoint(x:750,y:115),control1:CGPoint(x:350,y:90),control2:CGPoint(x:650,y:90))
        p.addCurve(to:CGPoint(x:938,y:170),control1:CGPoint(x:787,y:133),control2:CGPoint(x:850,y:178))
        p.addLine(to:CGPoint(x:938,y:1290));p.addQuadCurve(to:CGPoint(x:864,y:1380),control:CGPoint(x:940,y:1380))
        p.addLine(to:CGPoint(x:136,y:1380));p.addQuadCurve(to:CGPoint(x:62,y:1290),control:CGPoint(x:60,y:1380));p.closeSubpath()
        c.setFillColor(CGColor(gray:1,alpha:1));c.addPath(p);c.fillPath()
    }
    try scene.draw {c in
        c.translateBy(x:0,y:CGFloat(height));c.scaleBy(x:1,y:-1)
        c.setFillColor(CGColor(gray:1,alpha:1));c.addPath(CGPath(roundedRect:sceneRect,cornerWidth:70,cornerHeight:70,transform:nil));c.fillPath()
    }
    // Fixed inward fade softens the art/lining interface, never the frame geometry.
    for y in 0..<height { for x in 0..<width {
        let d=min(CGFloat(x)-sceneRect.minX,sceneRect.maxX-CGFloat(x),CGFloat(y)-sceneRect.minY,sceneRect.maxY-CGFloat(y))
        let t=max(0,min(1,d/42));let weight=t*t*(3-2*t);let i=(y*width+x)*4
        for k in 0..<4 {scene.bytes[i+k]=UInt8((Double(scene.bytes[i+k])*weight).rounded())}
    }}
    return (plate,scene)
}
// Scoped to this neutral checkerboard source; enclosed silver stays opaque.
func neutralFlood(_ src:Raster) -> Raster {
    var out=src,queue=[Int](),seen=[Bool](repeating:false,count:src.w*src.h)
    func neutral(_ p:Int)->Bool {let i=p*4;let r=Int(src.bytes[i]),g=Int(src.bytes[i+1]),b=Int(src.bytes[i+2]);return max(r,g,b)-min(r,g,b)<24}
    func push(_ p:Int) {if !seen[p] && neutral(p){seen[p]=true;queue.append(p)}}
    for x in 0..<src.w {push(x);push((src.h-1)*src.w+x)}
    for y in 0..<src.h {push(y*src.w);push(y*src.w+src.w-1)}
    var head=0
    while head<queue.count {let p=queue[head];head+=1;let x=p%src.w,y=p/src.w
        if x>0{push(p-1)};if x+1<src.w{push(p+1)};if y>0{push(p-src.w)};if y+1<src.h{push(p+src.w)}
    }
    for p in queue {for k in 0..<4{out.bytes[p*4+k]=0}}
    return out
}
func cleanName(_ src:Raster) -> Raster {
    // White-paper generated lettering is converted to a single plum ink plate.
    var out=src;let opaque=stride(from:3,to:src.bytes.count,by:4).allSatisfy{src.bytes[$0]==255}
    for i in stride(from:0,to:out.bytes.count,by:4) {
        let a=opaque ? UInt8(255-Int(min(src.bytes[i],src.bytes[i+1],src.bytes[i+2]))) : src.bytes[i+3]
        out.bytes[i+3]=a
        for (k,v) in [47,34,55].enumerated(){out.bytes[i+k]=UInt8((v*Int(a)+127)/255)}
    };return out
}
func textLayer(_ root:String,centerY:CGFloat=725) throws -> Raster {
    let object=try JSONSerialization.jsonObject(with:Data(contentsOf:URL(fileURLWithPath:try safe(root,"pathways/fool/sequences/09/card.json")))) as! [String:Any]
    let cues=object["cues"] as! [[String:Any]]; var out=canvas()
    let ids=["identity"] // User requires no explanatory copy inside the artwork.
    let ys:[CGFloat]=[centerY]
    for (index,id) in ids.enumerated() {
        let text=cues.first{$0["id"] as? String==id}!["exact_text"] as! String
        let size:CGFloat=index==0 ? 52 : (id=="potion" ? 37 : 40)
        let font=CTFontCreateWithName("Songti SC" as CFString,size,nil)
        let attrs:[NSAttributedString.Key:Any]=[.font:font,.foregroundColor:NSColor(srgbRed:0.88,green:0.84,blue:0.75,alpha:1)]
        let line=CTLineCreateWithAttributedString(NSAttributedString(string:text,attributes:attrs))
        let bounds=CTLineGetBoundsWithOptions(line,[.useGlyphPathBounds]);try demand(bounds.width<=1450,"copy overflow")
        try out.draw {c in c.textMatrix = .identity;c.textPosition=CGPoint(x:1024-bounds.midX,y:CGFloat(height)-ys[index]-bounds.midY);CTLineDraw(line,c)}
    };return out
}
func newDirectory(_ path:String) throws {try demand(!fm.fileExists(atPath:path),"output exists");try fm.createDirectory(atPath:path,withIntermediateDirectories:true)}
func writeJSON(_ value:Any,_ path:String) throws {try JSONSerialization.data(withJSONObject:value,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:path),options:.withoutOverwriting)}
func frozenFrame(_ root:String) throws -> Raster {
    let p=try safe(root,framePath);try demand(try fileHash(p)==frameHash,"frozen frame source changed");let f=try loadImage(p);try demand(f.w==width && f.h==height,"frame sampling changed");return f
}
func drapeArms(_ source:Raster,_ emblem:Raster) throws -> Raster {
    let clean=neutralFlood(source)
    func crop(_ x0:Double,_ x1:Double)->Raster {
        let left=Int(Double(clean.w)*x0),right=Int(Double(clean.w)*x1)
        let top=Int(Double(clean.h)*0.18),bottom=Int(Double(clean.h)*0.50)
        var out=Raster(right-left,bottom-top)
        for y in top..<bottom {for x in left..<right {for k in 0..<4 {out.bytes[((y-top)*out.w+x-left)*4+k]=clean.bytes[(y*clean.w+x)*4+k]}}}
        return out
    }
    var arms=try composite(placed(crop(0.275,0.452),CGRect(x:420,y:130,width:540,height:300),true),placed(crop(0.548,0.725),CGRect(x:1088,y:130,width:540,height:300),true))
    // Between outer silhouette edges, retain connectors only under opaque emblem material.
    for y in 0..<height {
        let xs=(0..<width).filter{emblem.bytes[(y*width+$0)*4+3]>32}
        guard let left=xs.first,let right=xs.last else {continue}
        for x in left...right where emblem.bytes[(y*width+x)*4+3]<250 {for k in 0..<4 {arms.bytes[(y*width+x)*4+k]=0}}
    }
    return arms
}
func layers(_ root:String,_ paths:[String],drape:Bool=false) throws -> [String:Raster] {
    if paths.count == 5 {
        let (mask,_)=try masks()
        let scene=try clipped(placed(loadImage(safe(root,paths[0])),CGRect(x:0,y:0,width:width,height:height)),mask)
        let name=try placed(cleanName(loadImage(safe(root,paths[1]))),nameRect,true)
        try demand(try fileHash(safe(root,paths[2]))=="b029e388e28d55f2ed1fd55e6ed4b953f0921b21dcf4a1e616a131cdce293e3f","bare frame source changed")
        let frame=try placed(loadImage(safe(root,paths[2])),CGRect(x:0,y:0,width:width,height:height))
        let emblem=try placed(loadImage(safe(root,paths[3])),CGRect(x:800,y:75,width:448,height:353.28),true)
        let bridge=try drape ? drapeArms(loadImage(safe(root,paths[4])),emblem) : placed(neutralFlood(loadImage(safe(root,paths[4]))),CGRect(x:410,y:125,width:1228,height:360),true)
        let copy=try drape ? canvas() : textLayer(root,centerY:500)
        var identity=try composite(bridge,frame);identity=try composite(identity,emblem);identity=try composite(identity,name);identity=try composite(identity,copy)
        let final=try composite(scene,identity)
        let b=name.bbox()!
        try demand(abs(b.midX-1024)<=1 && abs(b.midY-2670)<=1,"name center")
        try demand(domainOK(scene,mask),"scene overflow")
        for i in stride(from:0,to:identity.bytes.count,by:4) where identity.bytes[i+3]==255 {
            try demand(Array(final.bytes[i..<i+4])==Array(identity.bytes[i..<i+4]),"protected pixel changed")
        }
        var white=canvas();white.bytes=[UInt8](repeating:255,count:width*height*4)
        return ["scene":scene,"name":name,"frame":frame,"emblem":emblem,"bridge":bridge,"bridge-white":try composite(white,bridge),"copy":copy,"identity":identity,"final":final,"plate-mask":mask]
    }
    if paths.count == 2 {
        let (mask,_)=try masks()
        let scene=try clipped(placed(loadImage(safe(root,paths[0])),CGRect(x:0,y:0,width:width,height:height)),mask)
        let name=try placed(cleanName(loadImage(safe(root,paths[1]))),nameRect,true)
        let frame=try frozenFrame(root),copy=try textLayer(root)
        let identity=try composite(composite(frame,name),copy)
        let final=try composite(scene,identity)
        let b=name.bbox()!
        try demand(abs(b.midX-1024)<=1 && abs(b.midY-2670)<=1,"name center")
        try demand(domainOK(scene,mask),"scene overflow")
        for i in stride(from:0,to:identity.bytes.count,by:4) where identity.bytes[i+3]==255 {
            try demand(Array(final.bytes[i..<i+4])==Array(identity.bytes[i..<i+4]),"protected pixel changed")
        }
        return ["scene":scene,"name":name,"frame":frame,"copy":copy,"identity":identity,"final":final,"plate-mask":mask]
    }
    let (plateMask,sceneMask)=try masks()
    let base=try clipped(placed(loadImage(safe(root,paths[0])),CGRect(x:0,y:0,width:width,height:height)),plateMask)
    let scene=try clipped(placed(loadImage(safe(root,paths[1])),sceneRect,topAligned:true),sceneMask)
    let name=try placed(cleanName(loadImage(safe(root,paths[2]))),nameRect,true)
    try demand(domainOK(base,plateMask) && domainOK(scene,sceneMask),"layer overflow")
    guard let b=name.bbox() else {throw Failure.invalid("empty name")}
    try demand(abs(b.midX-nameRect.midX)<=1 && abs(b.midY-nameRect.midY)<=1,"name center differs by >1 output raster pixel")
    let frame=try frozenFrame(root),copy=try textLayer(root)
    var final=try composite(base,scene);final=try composite(final,frame);final=try composite(final,name);final=try composite(final,copy)
    return ["carrier":base,"scene":scene,"name":name,"frame":frame,"copy":copy,"final":final,"plate-mask":plateMask,"scene-mask":sceneMask]
}
func selftest() throws {
    var a=Raster(8,8);a.bytes[(3*8+3)*4+3]=255;var moved=Raster(8,8);moved.bytes[(3*8+4)*4+3]=255
    var changed=a;changed.bytes[(3*8+3)*4]=1
    var mask=Raster(8,8);mask.bytes[(3*8+3)*4+3]=255
    var edge=a;edge.bytes[(3*8+3)*4+3]=254
    var padding=Raster(12,10);padding.bytes[(4*12+5)*4+3]=255
    let n1=try placed(a,nameRect,true),n2=try placed(padding,nameRect,true)
    var material=a;material.bytes[(3*8+3)*4]=100
    let tmp=fm.temporaryDirectory.appendingPathComponent("lotm-klein-"+UUID().uuidString).path
    try newDirectory(tmp);var overwrite=false;do{try newDirectory(tmp)}catch{overwrite=true};try fm.removeItem(atPath:tmp)
    var checker=Raster(5,5);for p in 0..<25 {checker.bytes[p*4]=150;checker.bytes[p*4+1]=150;checker.bytes[p*4+2]=150;checker.bytes[p*4+3]=255}
    for y in 1...3 {for x in 1...3 where x==1 || x==3 || y==1 || y==3 {let i=(y*5+x)*4;checker.bytes[i]=190;checker.bytes[i+1]=120;checker.bytes[i+2]=40}}
    let matte=neutralFlood(checker);let protected=try composite(changed,a)
    let checks:[String:Bool]=["pixel_shift":!identical(a,moved),"internal_change":!identical(a,changed),"hidden_overflow":!domainOK(moved,mask),"edge_alpha":!identical(a,edge),"name_padding":n1.bbox()==n2.bbox(),"material_legal":domainOK(material,mask) && material.bytes[111]==a.bytes[111],"sampling":!identical(a,Raster(9,8)),"source_hash":digest(Data(a.bytes)) != digest(Data(moved.bytes)),"overwrite":overwrite,"bridge_background":matte.bytes[3]==0,"bridge_enclosed_silver":matte.bytes[(2*5+2)*4+3]==255,"opaque_identity":protected.bytes[(3*8+3)*4]==a.bytes[(3*8+3)*4]]
    try demand(checks.values.allSatisfy{$0},"selftest failed: \(checks)")
    print(String(data:try JSONSerialization.data(withJSONObject:["passed":true,"checks":checks],options:.sortedKeys),encoding:.utf8)!)
}
do {
    let args=CommandLine.arguments;try demand(args.count>=2,"mode required")
    if args[1]=="selftest" {try selftest()}
    else {
        try demand(args.count>=4,"ROOT OUT required");let root=args[2],relative=args[3]
        try demand(relative.hasPrefix("artifacts/production/klein-"),"output scope")
        let out=try safe(root,relative)
        if args[1]=="identity" {
            try demand(args.count==5,"NAME required")
            let name=try placed(cleanName(loadImage(safe(root,args[4]))),nameRect,true)
            let identity=try composite(composite(frozenFrame(root),name),textLayer(root))
            var neutral=canvas();for i in stride(from:0,to:neutral.bytes.count,by:4){neutral.bytes[i]=35;neutral.bytes[i+1]=29;neutral.bytes[i+2]=43;neutral.bytes[i+3]=255}
            let (mask,_)=try masks();try newDirectory(out)
            try identity.save(out+"/identity.png")
            try composite(clipped(neutral,mask),identity).save(out+"/reference.png")
        } else if args[1]=="prepare" {
            try newDirectory(out);let (p,s)=try masks();try p.save(out+"/plate-mask.png");try s.save(out+"/scene-mask.png")
            var neutral=canvas();for i in stride(from:0,to:neutral.bytes.count,by:4){neutral.bytes[i]=35;neutral.bytes[i+1]=29;neutral.bytes[i+2]=43;neutral.bytes[i+3]=255}
            try composite(clipped(neutral,p),frozenFrame(root)).save(out+"/reference.png")
            try writeJSON(["geometry_id":"klein-seer-carrier-v2-art-only","size":[width,height],"frame_source":framePath,"frame_sha256":frameHash,"scene_rect":[246,780,1556,1730],"name_center":[1024,2670],"scope":"single low-tier study; no general internal-structure recognition"],out+"/geometry.json")
        } else if args[1]=="render" || args[1]=="render-drape" {
            try demand([6,7,9].contains(args.count),"SCENE NAME [BARE_FRAME EMBLEM BRIDGE] or BASE SCENE NAME required");let paths=Array(args[4...]);let all=try layers(root,paths,drape:args[1]=="render-drape")
            try newDirectory(out);for (key,value) in all{try value.save(out+"/"+key+".png")}
            var bindings=[[String:String]]();for p in paths+[framePath,"tools/render/klein_carrier.swift","pathways/fool/sequences/09/card.json"] {bindings.append(["path":p,"sha256":try fileHash(safe(root,p))])}
            var outputs=[String:String]();for key in all.keys{outputs[key+".png"]=try fileHash(out+"/"+key+".png")}
            let b=all["name"]!.bbox()!
            try writeJSON(["geometry_id":args[1]=="render-drape" ? "klein-drape-study-v1" : paths.count==5 ? "klein-crest-study-v1" : (paths.count==2 ? "klein-integrated-v1" : "klein-seer-carrier-v2-art-only"),"paths":paths,"bindings":bindings,"outputs":outputs,"name_ink_center":[b.midX,b.midY],"name_center_error_px":[b.midX-1024,b.midY-2670],"size":[width,height],"color_space":"sRGB","declared_native":false,"approved":false,"status":"rendered-pending-visual-review","created_at":ISO8601DateFormatter().string(from:Date()),"limitations":"Specialized deterministic gate, not generic segmentation or production.py release. Name rendered as single plum ink from Agentic letter shapes."],out+"/manifest.json")
        } else if args[1]=="gate" {
            let m=try JSONSerialization.jsonObject(with:Data(contentsOf:URL(fileURLWithPath:out+"/manifest.json"))) as! [String:Any]
            for b in m["bindings"] as! [[String:String]]{try demand(try fileHash(safe(root,b["path"]!))==b["sha256"]!,"input hash changed: "+b["path"]!)}
            let expected=try layers(root,m["paths"] as! [String],drape:m["geometry_id"] as? String=="klein-drape-study-v1");let outputs=m["outputs"] as! [String:String]
            for (key,raster) in expected {let p=out+"/"+key+".png";try demand(try fileHash(p)==outputs[key+".png"],"output hash changed");try demand(try identical(loadImage(p),raster),"render mismatch: "+key)}
            print("PASS: frozen source, all actual layers and masks, full RGBA rebuild, name center; visual review separate; not release")
        } else {throw Failure.invalid("unknown mode")}
    }
} catch {fputs("ERROR: \(error)\n",stderr);exit(1)}
