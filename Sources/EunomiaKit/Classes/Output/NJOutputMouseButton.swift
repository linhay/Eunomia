import AppKit

class NJOutputMouseButton: NJOutput {
    var button: CGMouseButton = .left

    private var upTime: Date?
    private var clickCount = 0
    private var clickPosition = NSPoint.zero

    class func doubleClickInterval() -> TimeInterval {
        let threshold = UserDefaults.standard.object(forKey: "com.apple.mouse.doubleClickThreshold") as? NSNumber
        let t = threshold?.doubleValue ?? 1.0
        return t > 0 ? t : 1.0
    }

    class func dateWithClickInterval() -> Date {
        Date(timeIntervalSinceNow: doubleClickInterval())
    }

    override class func serializationCode() -> String {
        "mouse button"
    }

    override func serialize() -> [String: Any]? {
        ["type": Self.serializationCode(), "button": Int(button.rawValue)]
    }

    override class func output(withSerialization serialization: [String : Any]?) -> NJOutput? {
        let output = NJOutputMouseButton()
        output.button = CGMouseButton(rawValue: (serialization?["button"] as? NSNumber)?.uint32Value ?? 0) ?? .left
        return output
    }

    override func trigger() {
        guard let screen = NSScreen.screens.first else { return }
        let mouseLoc = NSEvent.mouseLocation
        let point = CGPoint(x: mouseLoc.x, y: screen.frame.height - mouseLoc.y)
        let eventType: CGEventType = button == .left ? .leftMouseDown : (button == .right ? .rightMouseDown : .otherMouseDown)
        guard let click = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: point, mouseButton: button) else { return }

        if clickCount >= 3 || (upTime?.compare(Date()) == .orderedAscending) || !NSEqualPoints(mouseLoc, clickPosition) {
            clickCount = 1
        } else {
            clickCount += 1
        }

        click.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
        click.post(tap: .cghidEventTap)
        clickPosition = mouseLoc
    }

    override func untrigger() {
        upTime = Self.dateWithClickInterval()
        guard let screen = NSScreen.screens.first else { return }
        let mouseLoc = NSEvent.mouseLocation
        let point = CGPoint(x: mouseLoc.x, y: screen.frame.height - mouseLoc.y)
        let eventType: CGEventType = button == .left ? .leftMouseUp : (button == .right ? .rightMouseUp : .otherMouseUp)
        guard let click = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: point, mouseButton: button) else { return }
        click.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
        click.post(tap: .cghidEventTap)
    }
}
