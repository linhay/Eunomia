import AppKit

struct NJKeySequenceStep: Equatable {
    var keyCode: CGKeyCode
    var delayMilliseconds: Int
}

class NJOutputKeyPress: NJOutput {
    static let defaultActivationThreshold: Float = 0.3

    var keyCode: CGKeyCode = NJKeyInputFieldEmpty
    var activationThreshold: Float = defaultActivationThreshold
    var keySequence: [NJKeySequenceStep] = []
    private var sequenceGeneration: UInt = 0

    override class func serializationCode() -> String {
        "key press"
    }

    override func serialize() -> [String: Any]? {
        let sequence = sanitizedSequence()
        guard keyCode != NJKeyInputFieldEmpty || !sequence.isEmpty else { return nil }

        var payload: [String: Any] = [
            "type": Self.serializationCode(),
            "key": keyCode,
            "activationThreshold": activationThreshold
        ]
        if sequence.count > 1 {
            payload["sequence"] = sequence.map {
                ["key": $0.keyCode, "delayMs": max(0, $0.delayMilliseconds)]
            }
        }
        return payload
    }

    override class func output(withSerialization serialization: [String : Any]?) -> NJOutput? {
        guard let serialization else { return nil }

        let legacyKey = (serialization["key"] as? NSNumber).map { CGKeyCode($0.uint16Value) } ?? NJKeyInputFieldEmpty
        let output = NJOutputKeyPress()
        output.keyCode = legacyKey
        if let threshold = serialization["activationThreshold"] as? NSNumber {
            output.activationThreshold = min(max(threshold.floatValue, 0), 1)
        } else {
            output.activationThreshold = defaultActivationThreshold
        }
        if let sequence = serialization["sequence"] as? [[String: Any]] {
            output.keySequence = sequence.compactMap { item in
                guard let key = item["key"] as? NSNumber else { return nil }
                let delay = (item["delayMs"] as? NSNumber)?.intValue ?? 0
                return NJKeySequenceStep(
                    keyCode: CGKeyCode(key.uint16Value),
                    delayMilliseconds: max(0, delay)
                )
            }.filter { $0.keyCode != NJKeyInputFieldEmpty }
            if output.keyCode == NJKeyInputFieldEmpty, let first = output.keySequence.first {
                output.keyCode = first.keyCode
            }
        }
        if output.keyCode == NJKeyInputFieldEmpty && output.keySequence.isEmpty {
            return nil
        }
        return output
    }

    override func trigger() {
        let sequence = sanitizedSequence()
        if sequence.count > 1 {
            triggerSequence(sequence)
            return
        }

        let targetKey = sequence.first?.keyCode ?? keyCode
        guard targetKey != NJKeyInputFieldEmpty,
              let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: targetKey, keyDown: true) else { return }
        keyDown.post(tap: .cghidEventTap)
    }

    override func untrigger() {
        let sequence = sanitizedSequence()
        if sequence.count > 1 {
            sequenceGeneration &+= 1
            return
        }

        let targetKey = sequence.first?.keyCode ?? keyCode
        guard targetKey != NJKeyInputFieldEmpty,
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: targetKey, keyDown: false) else { return }
        keyUp.post(tap: .cghidEventTap)
    }

    private func sanitizedSequence() -> [NJKeySequenceStep] {
        keySequence
            .filter { $0.keyCode != NJKeyInputFieldEmpty }
            .map { NJKeySequenceStep(keyCode: $0.keyCode, delayMilliseconds: max(0, $0.delayMilliseconds)) }
    }

    private func triggerSequence(_ sequence: [NJKeySequenceStep]) {
        sequenceGeneration &+= 1
        let generation = sequenceGeneration
        var accumulatedDelay: TimeInterval = 0

        for step in sequence {
            accumulatedDelay += TimeInterval(max(0, step.delayMilliseconds)) / 1000.0
            DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedDelay) { [weak self] in
                guard let self, self.sequenceGeneration == generation else { return }
                guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: step.keyCode, keyDown: true),
                      let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: step.keyCode, keyDown: false) else { return }
                keyDown.post(tap: .cghidEventTap)
                keyUp.post(tap: .cghidEventTap)
            }
        }
    }
}
