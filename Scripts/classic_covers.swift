import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let entries = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("catalog.json"))) as! [[String: Any]]
let colors: [(CGFloat,CGFloat,CGFloat)] = [(0.19,0.29,0.23),(0.13,0.24,0.28),(0.30,0.10,0.15),(0.13,0.18,0.28),(0.22,0.16,0.33),(0.25,0.23,0.11),(0.23,0.14,0.18),(0.30,0.16,0.10),(0.10,0.27,0.29),(0.16,0.18,0.35)]
for (index,entry) in entries.enumerated() {
 let context = CGContext(data:nil,width:600,height:900,bitsPerComponent:8,bytesPerRow:0,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
 let color=colors[index]
 context.setFillColor(CGColor(red:color.0,green:color.1,blue:color.2,alpha:1)); context.fill(CGRect(x:0,y:0,width:600,height:900))
 context.setStrokeColor(CGColor(red:0.83,green:0.70,blue:0.44,alpha:1));context.setLineWidth(2);context.stroke(CGRect(x:28,y:28,width:544,height:844))
 context.move(to:CGPoint(x:58,y:700));context.addLine(to:CGPoint(x:542,y:700));context.strokePath()
 func text(_ value:String,size:CGFloat,rect:CGRect,bold:Bool=false) {
  let font=CTFontCreateWithName((bold ? "Georgia-Bold" : "Georgia") as CFString,size,nil)
  let attributed=NSAttributedString(string:value,attributes:[NSAttributedString.Key(kCTFontAttributeName as String):font,NSAttributedString.Key(kCTForegroundColorAttributeName as String):CGColor(red:0.96,green:0.92,blue:0.81,alpha:1)])
  let frame=CTFramesetterCreateFrame(CTFramesetterCreateWithAttributedString(attributed),CFRange(location:0,length:0),CGPath(rect:rect,transform:nil),nil)
  CTFrameDraw(frame,context)
 }
 text("BOOK HUB\nCLASSICS",size:22,rect:CGRect(x:60,y:730,width:480,height:105))
 text(entry["title"] as! String,size:48,rect:CGRect(x:60,y:280,width:480,height:360),bold:true)
 text(entry["author"] as! String,size:26,rect:CGRect(x:60,y:160,width:480,height:80))
 text("ORIGINAL ENGLISH · \(entry["year"]!)",size:16,rect:CGRect(x:60,y:70,width:480,height:45))
 let url=root.appendingPathComponent(entry["coverFileName"] as! String)
 let output=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil)!
 CGImageDestinationAddImage(output,context.makeImage()!,nil); assert(CGImageDestinationFinalize(output))
}
