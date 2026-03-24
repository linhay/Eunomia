import AppKit

class NJOutputMouseScroll: NJOutput {
    var direction: Int32 = 0
    var speed: Float = 0
    var smooth: Bool = false

    override class func serializationCode() -> String {
        "mouse scroll"
    }

    override func serialize() -> [String: Any]? {
        ["type": Self.serializationCode(), "direction": direction, "speed": speed, "smooth": smooth]
    }

    override class func output(withSerialization serialization: [String : Any]?) -> NJOutput? {
        let output = NJOutputMouseScroll()
        output.direction = (serialization?["direction"] as? NSNumber)?.int32Value ?? 0
        output.speed = (serialization?["speed"] as? NSNumber)?.floatValue ?? 0
        output.smooth = (serialization?["smooth"] as? NSNumber)?.boolValue ?? false
        return output
    }

    override var isContinuous: Bool {
        smooth
    }

    private func wheel(_ n: Int32) -> Int32 {
        var amount: Int32 = abs(direction) == n ? direction / n : 0
        if smooth {
            amount = Int32(lrintf(Float(amount) * speed * magnitude))
        }
        return amount
    }

    override func trigger() {
        if !smooth {
            guard let scroll = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: Int32(wheel(1)), wheel2: Int32(wheel(2)), wheel3: 0) else { return }
            scroll.post(tap: .cghidEventTap)
        }
    }

    override func update(_ ic: NJInputController) -> Bool {
        if magnitude < 0.05 { return false }
        guard let scroll = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: Int32(wheel(1)), wheel2: Int32(wheel(2)), wheel3: 0) else { return false }
        scroll.post(tap: .cghidEventTap)
        return true
    }
}
