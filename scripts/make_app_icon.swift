// Draws Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png (1024², no alpha).
// Run (the `swift` interpreter crashes on AppKit drawing — compile it):
//   xcrun swiftc -sdk "$(xcrun --sdk macosx --show-sdk-path)" scripts/make_app_icon.swift -o /tmp/make_icon && /tmp/make_icon
import AppKit

let size = 1024
guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                 bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false,
                                 isPlanar: false, colorSpaceName: .deviceRGB,
                                 bytesPerRow: 0, bitsPerPixel: 32),
      let context = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("no bitmap") }
NSGraphicsContext.current = context
let s = CGFloat(size)

// Table: #00cc00 fading to the deeper green, as in the app.
NSGradient(starting: NSColor(red: 0, green: 0.80, blue: 0, alpha: 1),
           ending: NSColor(red: 0, green: 0.55, blue: 0, alpha: 1))?
  .draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -90)

let red = NSColor(red: 0.80, green: 0, blue: 0, alpha: 1)

func drawCard(rank: String, suit: String, color: NSColor, center: CGPoint, angle: CGFloat) {
  let w: CGFloat = 470, h: CGFloat = 690
  guard let ctx = NSGraphicsContext.current?.cgContext else { return }
  ctx.saveGState()
  ctx.translateBy(x: center.x, y: center.y)
  ctx.rotate(by: angle * .pi / 180)
  let rect = NSRect(x: -w / 2, y: -h / 2, width: w, height: h)
  let path = NSBezierPath(roundedRect: rect, xRadius: 22, yRadius: 22)
  NSColor(white: 0.99, alpha: 1).setFill()
  path.fill()
  NSColor.black.setStroke()
  path.lineWidth = 9
  path.stroke()

  func text(_ str: String, _ pt: CGFloat, _ weight: NSFont.Weight, at p: CGPoint, centered: Bool) {
    let attrs: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: pt, weight: weight), .foregroundColor: color,
    ]
    let a = NSAttributedString(string: str, attributes: attrs)
    let sz = a.size()
    a.draw(at: centered ? CGPoint(x: p.x - sz.width / 2, y: p.y - sz.height / 2) : p)
  }
  text(rank, 190, .heavy, at: CGPoint(x: -w / 2 + 30, y: h / 2 - 225), centered: false)
  text(suit, 330, .regular, at: CGPoint(x: 0, y: -40), centered: true)
  ctx.restoreGState()
}

drawCard(rank: "A", suit: "♥", color: red, center: CGPoint(x: 400, y: 530), angle: 12)
drawCard(rank: "2", suit: "♠", color: .black, center: CGPoint(x: 610, y: 490), angle: -8)

NSGraphicsContext.current = nil
guard let png = rep.representation(using: .png, properties: [:]) else { fatalError("no png") }
try png.write(to: URL(fileURLWithPath: "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))
print("wrote AppIcon.png")
