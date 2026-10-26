import AppKit
let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
NSColor(red: 0.89, green: 0.95, blue: 0.85, alpha: 1).setFill()
NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
let ink = NSColor(red: 0.12, green: 0.22, blue: 0.22, alpha: 1)
func round(_ rect: CGRect, radius: CGFloat, color: NSColor) {
    color.setFill(); NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
round(CGRect(x: 396, y: 735, width: 232, height: 140), radius: 60, color: ink)
round(CGRect(x: 430, y: 764, width: 164, height: 75), radius: 30, color: NSColor(red: 0.89, green: 0.95, blue: 0.85, alpha: 1))
round(CGRect(x: 225, y: 185, width: 574, height: 620), radius: 140, color: ink)
round(CGRect(x: 240, y: 200, width: 544, height: 590), radius: 128, color: NSColor(red: 0.29, green: 0.66, blue: 0.36, alpha: 1))
round(CGRect(x: 290, y: 245, width: 444, height: 210), radius: 75, color: NSColor(red: 0.89, green: 0.95, blue: 0.85, alpha: 1))
round(CGRect(x: 390, y: 550, width: 38, height: 68), radius: 19, color: ink)
round(CGRect(x: 596, y: 550, width: 38, height: 68), radius: 19, color: ink)
let smile = NSBezierPath(); smile.move(to: NSPoint(x: 460,y: 522)); smile.curve(to: NSPoint(x: 564,y: 522), controlPoint1: NSPoint(x: 480,y: 475), controlPoint2: NSPoint(x: 544,y: 475)); smile.lineWidth = 15; smile.lineCapStyle = .round; ink.setStroke(); smile.stroke()
round(CGRect(x: 330, y: 510, width: 58, height: 26), radius: 13, color: NSColor.systemPink.withAlphaComponent(0.5))
round(CGRect(x: 636, y: 510, width: 58, height: 26), radius: 13, color: NSColor.systemPink.withAlphaComponent(0.5))
image.unlockFocus()
let data = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: "DontForgetMe/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
