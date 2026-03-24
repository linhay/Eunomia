import AppKit

extension NSView {
    func resignIfFirstResponderCompat() -> Bool {
        guard let window else { return false }
        if window.firstResponder === self {
            return window.makeFirstResponder(nil)
        }
        return false
    }
}
