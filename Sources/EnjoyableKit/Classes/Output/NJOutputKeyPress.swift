import AppKit
import Carbon

struct NJKeySequenceStep: Equatable {
    var keys: [CGKeyCode]
    var delayMilliseconds: Int

    init(keys: [CGKeyCode], delayMilliseconds: Int) {
        self.keys = keys
        self.delayMilliseconds = delayMilliseconds
    }

    init(keyCode: CGKeyCode, delayMilliseconds: Int) {
        if keyCode == NJKeyInputFieldEmpty {
            self.keys = []
        } else {
            self.keys = [keyCode]
        }
        self.delayMilliseconds = delayMilliseconds
    }

    // Compatibility shim for existing single-key editors and tests.
    var keyCode: CGKeyCode {
        get { keys.first ?? NJKeyInputFieldEmpty }
        set {
            if newValue == NJKeyInputFieldEmpty {
                keys = []
            } else {
                keys = [newValue]
            }
        }
    }
}

class NJOutputKeyPress: NJOutput {
    static let defaultActivationThreshold: Float = 0.3

    var keyCode: CGKeyCode = NJKeyInputFieldEmpty
    var activationThreshold: Float = defaultActivationThreshold
    var keySequence: [NJKeySequenceStep] = []
    private var sequenceGeneration: UInt = 0
    private var functionKeyCode: CGKeyCode { CGKeyCode(UInt16(kVK_Function)) }

    override class func serializationCode() -> String {
        "key press"
    }

    override func serialize() -> [String: Any]? {
        let steps = serializedSteps()
        guard !steps.isEmpty else { return nil }

        var payload: [String: Any] = [
            "type": Self.serializationCode(),
            "activationThreshold": activationThreshold
        ]
        payload["steps"] = steps
        return payload
    }

    override class func output(withSerialization serialization: [String : Any]?) -> NJOutput? {
        guard let serialization else { return nil }

        let output = NJOutputKeyPress()
        if let threshold = serialization["activationThreshold"] as? NSNumber {
            output.activationThreshold = min(max(threshold.floatValue, 0), 1)
        } else {
            output.activationThreshold = defaultActivationThreshold
        }

        if let steps = serialization["steps"] as? [[String: Any]] {
            output.keySequence = steps.compactMap(parseStepV2)
        } else {
            // Backward compatibility: read historical key/sequence payload.
            let serializedKey = (serialization["key"] as? NSNumber).map { CGKeyCode($0.uint16Value) } ?? NJKeyInputFieldEmpty
            if let sequence = serialization["sequence"] as? [[String: Any]] {
                output.keySequence = sequence.compactMap { item in
                    guard let key = item["key"] as? NSNumber else { return nil }
                    let delay = (item["delayMs"] as? NSNumber)?.intValue ?? 0
                    return NJKeySequenceStep(
                        keys: [CGKeyCode(key.uint16Value)],
                        delayMilliseconds: max(0, delay)
                    )
                }
            } else if serializedKey != NJKeyInputFieldEmpty {
                output.keySequence = [NJKeySequenceStep(keys: [serializedKey], delayMilliseconds: 0)]
            }
        }

        output.keySequence = output.keySequence.filter { !$0.keys.isEmpty }
        output.keyCode = output.keySequence.first?.keys.first ?? NJKeyInputFieldEmpty
        if output.keySequence.isEmpty && output.keyCode == NJKeyInputFieldEmpty {
            return nil
        }
        return output
    }

    override func trigger() {
        let sequence = sanitizedSequence()
        guard !sequence.isEmpty else {
            guard keyCode != NJKeyInputFieldEmpty,
                  let keyDown = keyboardEvent(keyCode: keyCode, keyDown: true, containsFunctionKey: keyCode == functionKeyCode) else { return }
            keyDown.post(tap: .cghidEventTap)
            return
        }

        // Preserve hold semantics for a single zero-delay step (single key or combo).
        if usesHoldSemantics(for: sequence) {
            press(step: sequence[0])
            return
        }

        triggerSequence(sequence)
    }

    override func untrigger() {
        let sequence = sanitizedSequence()
        guard !sequence.isEmpty else {
            guard keyCode != NJKeyInputFieldEmpty,
                  let keyUp = keyboardEvent(keyCode: keyCode, keyDown: false, containsFunctionKey: keyCode == functionKeyCode) else { return }
            keyUp.post(tap: .cghidEventTap)
            return
        }

        if usesHoldSemantics(for: sequence) {
            release(step: sequence[0])
            return
        }

        sequenceGeneration &+= 1
    }

    private func sanitizedSequence() -> [NJKeySequenceStep] {
        keySequence
            .map { step in
                let keys = step.keys.filter { $0 != NJKeyInputFieldEmpty }
                return NJKeySequenceStep(keys: keys, delayMilliseconds: max(0, step.delayMilliseconds))
            }
            .filter { !$0.keys.isEmpty }
    }

    private func serializedSteps() -> [[String: Any]] {
        let sequence = sanitizedSequence()
        if !sequence.isEmpty {
            return sequence.map { step in
                [
                    "keys": step.keys.map { Int($0) },
                    "delayMs": max(0, step.delayMilliseconds)
                ]
            }
        }
        guard keyCode != NJKeyInputFieldEmpty else { return [] }
        return [[
            "keys": [Int(keyCode)],
            "delayMs": 0
        ]]
    }

    private func triggerSequence(_ sequence: [NJKeySequenceStep]) {
        sequenceGeneration &+= 1
        let generation = sequenceGeneration
        var accumulatedDelay: TimeInterval = 0

        for step in sequence {
            accumulatedDelay += TimeInterval(max(0, step.delayMilliseconds)) / 1000.0
            DispatchQueue.main.asyncAfter(deadline: .now() + accumulatedDelay) { [weak self] in
                guard let self, self.sequenceGeneration == generation else { return }
                self.press(step: step)
                self.release(step: step)
            }
        }
    }

    func usesHoldSemantics(for sequence: [NJKeySequenceStep]) -> Bool {
        sequence.count == 1 && sequence[0].delayMilliseconds == 0
    }

    private func press(step: NJKeySequenceStep) {
        emit(step: step, keyDown: true)
    }

    private func release(step: NJKeySequenceStep) {
        emit(step: step, keyDown: false)
    }

    private func emit(step: NJKeySequenceStep, keyDown: Bool) {
        let containsFunctionKey = step.keys.contains(functionKeyCode)
        let keysToEmit = step.keys.filter { $0 != functionKeyCode }
        let effectiveKeys = keysToEmit.isEmpty ? step.keys : keysToEmit

        if keyDown {
            for key in effectiveKeys {
                guard let event = keyboardEvent(
                    keyCode: key,
                    keyDown: true,
                    containsFunctionKey: containsFunctionKey
                ) else { continue }
                event.post(tap: .cghidEventTap)
            }
            return
        }

        for key in effectiveKeys.reversed() {
            guard let event = keyboardEvent(
                keyCode: key,
                keyDown: false,
                containsFunctionKey: containsFunctionKey
            ) else { continue }
            event.post(tap: .cghidEventTap)
        }
    }

    private func keyboardEvent(
        keyCode: CGKeyCode,
        keyDown: Bool,
        containsFunctionKey: Bool
    ) -> CGEvent? {
        if keyCode == functionKeyCode {
            return functionKeyEvent(keyDown: keyDown)
        }

        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else {
            return nil
        }
        // For Fn-compatible combos, keep SecondaryFn on key-down only.
        // Applying this flag on key-up may cause macOS to treat the key as still held.
        if containsFunctionKey && keyDown {
            event.flags.insert(.maskSecondaryFn)
        }
        return event
    }

    private func functionKeyEvent(keyDown: Bool) -> CGEvent? {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: functionKeyCode, keyDown: keyDown) else {
            return nil
        }
        if keyDown {
            event.flags.insert(.maskSecondaryFn)
        } else {
            event.flags.remove(.maskSecondaryFn)
        }
        return event
    }

    private class func parseStepV2(_ item: [String: Any]) -> NJKeySequenceStep? {
        let keysAny = item["keys"] as? [Any] ?? []
        let keys: [CGKeyCode] = keysAny.compactMap { raw in
            if let number = raw as? NSNumber {
                return CGKeyCode(number.uint16Value)
            }
            if let intValue = raw as? Int {
                return CGKeyCode(UInt16(intValue))
            }
            return nil
        }.filter { $0 != NJKeyInputFieldEmpty }
        guard !keys.isEmpty else { return nil }
        let delay = (item["delayMs"] as? NSNumber)?.intValue ?? 0
        return NJKeySequenceStep(keys: keys, delayMilliseconds: max(0, delay))
    }
}
