import AppKit

private func pointRectSquaredDistance(_ p: NSPoint, _ r: NSRect) -> CGFloat {
    let dx = p.x - max(min(p.x, r.origin.x + r.size.width), r.origin.x)
    let dy = p.y - max(min(p.y, r.origin.y + r.size.height), r.origin.y)
    return dx * dx + dy * dy
}

@objc(NJOutputMouseMove)
class NJOutputMouseMove: NJOutput {
    @objc var axis: Int32 = 0
    @objc var speed: Float = 10

    override class func serializationCode() -> String {
        "mouse move"
    }

    override func serialize() -> [String: Any]? {
        ["type": Self.serializationCode(), "axis": axis, "speed": speed]
    }

    override class func output(withSerialization serialization: [String : Any]?) -> NJOutput? {
        let output = NJOutputMouseMove()
        output.axis = (serialization?["axis"] as? NSNumber)?.int32Value ?? 0
        output.speed = (serialization?["speed"] as? NSNumber)?.floatValue ?? 10
        if output.speed == 0 { output.speed = 10 }
        return output
    }

    override var isContinuous: Bool { true }

    override func update(_ ic: NJInputController) -> Bool {
        if magnitude < 0.05 { return false }

        var dx: CGFloat = 0
        var dy: CGFloat = 0
        switch axis {
        case 0: dx = -CGFloat(magnitude * speed)
        case 1: dx = CGFloat(magnitude * speed)
        case 2: dy = -CGFloat(magnitude * speed)
        case 3: dy = CGFloat(magnitude * speed)
        default: break
        }

        var mouseLoc = ic.mouseLoc
        mouseLoc.x += dx
        mouseLoc.y -= dy

        var inScreen = false
        for screen in NSScreen.screens where NSMouseInRect(mouseLoc, screen.frame, false) {
            inScreen = true
            break
        }

        if !inScreen {
            let nearestScreen: NSScreen
            if let first = NSScreen.screens.first {
                nearestScreen = NSScreen.screens.min(by: { pointRectSquaredDistance(mouseLoc, $0.frame) < pointRectSquaredDistance(mouseLoc, $1.frame) }) ?? first
            } else {
                return false
            }
            let frame = nearestScreen.frame
            mouseLoc.x = min(max(mouseLoc.x, NSMinX(frame)), NSMaxX(frame) - 1)
            mouseLoc.y = min(max(mouseLoc.y, NSMinY(frame) + 1), NSMaxY(frame))
        }

        ic.mouseLoc = mouseLoc

        guard let screen = NSScreen.screens.first,
              let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: mouseLoc.x, y: screen.frame.height - mouseLoc.y), mouseButton: .left) else {
            return false
        }

        move.setIntegerValueField(.mouseEventDeltaX, value: Int64(dx))
        move.setIntegerValueField(.mouseEventDeltaY, value: Int64(dy))
        move.post(tap: .cghidEventTap)

        if CGEventSource.buttonState(.hidSystemState, button: .left) {
            move.type = .leftMouseDragged
            move.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.left.rawValue))
            move.post(tap: .cghidEventTap)
        }
        if CGEventSource.buttonState(.hidSystemState, button: .right) {
            move.type = .rightMouseDragged
            move.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.right.rawValue))
            move.post(tap: .cghidEventTap)
        }
        if CGEventSource.buttonState(.hidSystemState, button: .center) {
            move.type = .otherMouseDragged
            move.setIntegerValueField(.mouseEventButtonNumber, value: Int64(CGMouseButton.center.rawValue))
            move.post(tap: .cghidEventTap)
        }

        return true
    }
}
