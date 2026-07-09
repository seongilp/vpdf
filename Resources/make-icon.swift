// 앱 아이콘(1024px PNG) 생성 스크립트. build 시가 아니라 아이콘 갱신 때만 수동 실행.
// 사용: swift Resources/make-icon.swift <출력경로.png>
import AppKit

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "icon_1024.png"

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// macOS 아이콘 표준 여백을 가진 라운드 사각형 배경
let margin: CGFloat = 100
let bgRect = NSRect(x: margin, y: margin, width: size - margin * 2, height: size - margin * 2)
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 185, yRadius: 185)
let gradient = NSGradient(
    starting: NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.21, alpha: 1),
    ending: NSColor(calibratedRed: 0.05, green: 0.05, blue: 0.08, alpha: 1)
)!
gradient.draw(in: bgPath, angle: -90)

// 흰 문서 페이지
let pageWidth: CGFloat = 430
let pageHeight: CGFloat = 560
let pageRect = NSRect(x: (size - pageWidth) / 2, y: (size - pageHeight) / 2 - 10,
                      width: pageWidth, height: pageHeight)
let pagePath = NSBezierPath(roundedRect: pageRect, xRadius: 36, yRadius: 36)
NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
pagePath.fill()

// 페이지 위 텍스트 라인 느낌
NSColor(calibratedWhite: 0.78, alpha: 1).setFill()
for i in 0..<4 {
    let lineWidth: CGFloat = (i == 3) ? 180 : 300
    let line = NSRect(x: pageRect.minX + 65,
                      y: pageRect.maxY - 110 - CGFloat(i) * 62,
                      width: lineWidth, height: 26)
    NSBezierPath(roundedRect: line, xRadius: 13, yRadius: 13).fill()
}

// 번개 (속도 상징)
let bolt = NSBezierPath()
bolt.move(to: NSPoint(x: 585, y: 640))
bolt.line(to: NSPoint(x: 440, y: 430))
bolt.line(to: NSPoint(x: 525, y: 430))
bolt.line(to: NSPoint(x: 465, y: 260))
bolt.line(to: NSPoint(x: 645, y: 480))
bolt.line(to: NSPoint(x: 550, y: 480))
bolt.line(to: NSPoint(x: 585, y: 640))
bolt.close()
NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.0, alpha: 1).setFill()
bolt.fill()
NSColor(calibratedRed: 0.85, green: 0.55, blue: 0.0, alpha: 1).setStroke()
bolt.lineWidth = 8
bolt.stroke()

// PDF 뱃지
let badgeRect = NSRect(x: pageRect.minX - 40, y: pageRect.minY + 40, width: 300, height: 130)
let badgePath = NSBezierPath(roundedRect: badgeRect, xRadius: 30, yRadius: 30)
NSColor(calibratedRed: 0.86, green: 0.18, blue: 0.16, alpha: 1).setFill()
badgePath.fill()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 96, weight: .heavy),
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraph,
]
let text = NSAttributedString(string: "PDF", attributes: attrs)
text.draw(in: NSRect(x: badgeRect.minX, y: badgeRect.minY + 8,
                     width: badgeRect.width, height: badgeRect.height - 20))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("PNG 인코딩 실패")
}
try! png.write(to: URL(fileURLWithPath: outputPath))
print("saved: \(outputPath)")
