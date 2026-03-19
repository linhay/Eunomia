import AppKit

@objc(NJOutputKeyPress)
class NJOutputKeyPress: NJOutput {
    @objc var keyCode: CGKeyCode = NJKeyInputFieldEmpty

    override class func serializationCode() -> String {
        "key press"
    }

    override func serialize() -> [String: Any]? {
        guard keyCode != NJKeyInputFieldEmpty else { return nil }
        return ["type": Self.serializationCode(), "key": keyCode]
    }

    override class func output(withSerialization serialization: [String : Any]?) -> NJOutput? {
        guard let key = serialization?["key"] as? NSNumber else { return nil }
        let output = NJOutputKeyPress()
        output.keyCode = CGKeyCode(key.uint16Value)
        return output
    }

    override func trigger() {
        guard keyCode != NJKeyInputFieldEmpty,
              let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else { return }
        keyDown.post(tap: .cghidEventTap)
    }

    override func untrigger() {
        guard keyCode != NJKeyInputFieldEmpty,
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else { return }
        keyUp.post(tap: .cghidEventTap)
    }
}
