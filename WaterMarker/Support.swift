import Cocoa
class MyWindowController: NSWindowController, NSWindowDelegate {

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
}
func / (left: NSSize, right: CGFloat) -> NSSize {
    return NSSize(width: left.width / right, height: left.height / right)
}

extension CGRect {
    /**
     * Extend CGRect by CGPoint
     */
    mutating func union(withPoint: CGPoint) {
        if withPoint.x < self.origin.x { self.size.width += self.origin.x - withPoint.x; self.origin.x = withPoint.x }
        if withPoint.y < self.origin.y { self.size.height += self.origin.y - withPoint.y; self.origin.y = withPoint.y }
        if withPoint.x > self.origin.x + self.size.width { self.size.width = withPoint.x - self.origin.x }
        if withPoint.y > self.origin.y + self.size.height { self.size.height = withPoint.y - self.origin.y; }
    }

    /**
     * Get end point of CGRect
     */
    func maxPoint() -> CGPoint {
        return CGPoint(x: self.origin.x + self.size.width, y: self.origin.y + self.size.height)
    }
}
