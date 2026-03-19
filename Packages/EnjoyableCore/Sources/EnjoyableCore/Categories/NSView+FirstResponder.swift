import AppKit

extension NSView {
    @objc(resignIfFirstResponder)
    func resignIfFirstResponderCompat() -> Bool {
        guard let window else { return false }
        if window.firstResponder === self {
            return window.makeFirstResponder(nil)
        }
        return false
    }
}
