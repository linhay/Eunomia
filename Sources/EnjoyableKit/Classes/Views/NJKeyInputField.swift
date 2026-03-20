import AppKit
import Carbon

let NJKeyInputFieldEmpty: CGKeyCode = 0xFFFF

private final class ClickForwardingTextField: NSTextField {
    weak var forwardingTarget: NJKeyInputField?

    override func mouseDown(with event: NSEvent) {
        forwardingTarget?.mouseDown(with: event)
    }
}

protocol NJKeyInputFieldDelegate: AnyObject {
    func keyInputField(_ keyInput: NJKeyInputField, didChangeKey keyCode: CGKeyCode)
    func keyInputFieldDidClear(_ keyInput: NJKeyInputField)
}

class NJKeyInputField: NSControl, NSTextFieldDelegate {
    weak var delegate: NJKeyInputFieldDelegate?

    var keyCode: CGKeyCode = NJKeyInputFieldEmpty {
        didSet {
            field.stringValue = Self.displayName(forKeyCode: keyCode)
        }
    }

    var hasKeyCode: Bool {
        keyCode != NJKeyInputFieldEmpty
    }

    private let field: ClickForwardingTextField
    private let warning: NSImageView
    private var keyMonitor: Any?

    required init?(coder: NSCoder) {
        field = ClickForwardingTextField(frame: .zero)
        warning = NSImageView(frame: .zero)
        super.init(coder: coder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        field = ClickForwardingTextField(frame: frameRect)
        warning = NSImageView(frame: .zero)
        super.init(frame: frameRect)
        commonInit()
    }

    private func commonInit() {
        field.forwardingTarget = self
        field.frame = bounds
        field.autoresizingMask = [.width, .height]
        field.alignment = .center
        field.isEditable = false
        field.isSelectable = false
        field.delegate = self
        addSubview(field)

        warning.image = NSImage(named: NSImage.Name("NSInvalidDataFreestanding"))
        let imgSize = warning.image?.size ?? .zero
        let b = bounds
        warning.frame = CGRect(x: b.size.width - (imgSize.width + 4), y: (b.size.height - imgSize.height) / 2, width: imgSize.width, height: imgSize.height)
        warning.toolTip = NSLocalizedString("invalid key code", comment: "shown when the user types an invalid key code")
        warning.isHidden = true
        addSubview(warning)
    }

    override func layout() {
        super.layout()
        field.frame = bounds
        let imgSize = warning.image?.size ?? .zero
        warning.frame = CGRect(
            x: bounds.size.width - (imgSize.width + 4),
            y: (bounds.size.height - imgSize.height) / 2,
            width: imgSize.width,
            height: imgSize.height
        )
    }

    func clear() {
        keyCode = NJKeyInputFieldEmpty
        delegate?.keyInputFieldDidClear(self)
        stopKeyCapture()
        _ = resignFirstResponder()
    }

    class func displayName(forKeyCode keyCode: CGKeyCode) -> String {
        switch keyCode {
        case CGKeyCode(kVK_F1): return "F1"
        case CGKeyCode(kVK_F2): return "F2"
        case CGKeyCode(kVK_F3): return "F3"
        case CGKeyCode(kVK_F4): return "F4"
        case CGKeyCode(kVK_F5): return "F5"
        case CGKeyCode(kVK_F6): return "F6"
        case CGKeyCode(kVK_F7): return "F7"
        case CGKeyCode(kVK_F8): return "F8"
        case CGKeyCode(kVK_F9): return "F9"
        case CGKeyCode(kVK_F10): return "F10"
        case CGKeyCode(kVK_F11): return "F11"
        case CGKeyCode(kVK_F12): return "F12"
        case CGKeyCode(kVK_F13): return "F13"
        case CGKeyCode(kVK_F14): return "F14"
        case CGKeyCode(kVK_F15): return "F15"
        case CGKeyCode(kVK_F16): return "F16"
        case CGKeyCode(kVK_F17): return "F17"
        case CGKeyCode(kVK_F18): return "F18"
        case CGKeyCode(kVK_F19): return "F19"
        case CGKeyCode(kVK_F20): return "F20"
        case CGKeyCode(kVK_Escape): return "⎋"
        case CGKeyCode(kVK_ANSI_Grave): return "`"
        case CGKeyCode(kVK_ANSI_1): return "1"
        case CGKeyCode(kVK_ANSI_2): return "2"
        case CGKeyCode(kVK_ANSI_3): return "3"
        case CGKeyCode(kVK_ANSI_4): return "4"
        case CGKeyCode(kVK_ANSI_5): return "5"
        case CGKeyCode(kVK_ANSI_6): return "6"
        case CGKeyCode(kVK_ANSI_7): return "7"
        case CGKeyCode(kVK_ANSI_8): return "8"
        case CGKeyCode(kVK_ANSI_9): return "9"
        case CGKeyCode(kVK_ANSI_0): return "0"
        case CGKeyCode(kVK_ANSI_Minus): return "-"
        case CGKeyCode(kVK_ANSI_Equal): return "="
        case CGKeyCode(kVK_Function): return "Fn"
        case CGKeyCode(kVK_CapsLock): return "⇪"
        case CGKeyCode(kVK_Command): return NSLocalizedString("Left ⌘", comment: "keyboard key")
        case CGKeyCode(kVK_RightCommand): return NSLocalizedString("Right ⌘", comment: "keyboard key")
        case CGKeyCode(kVK_Option): return NSLocalizedString("Left ⌥", comment: "keyboard key")
        case CGKeyCode(kVK_RightOption): return NSLocalizedString("Right ⌥", comment: "keyboard key")
        case CGKeyCode(kVK_Control): return NSLocalizedString("Left ⌃", comment: "keyboard key")
        case CGKeyCode(kVK_RightControl): return NSLocalizedString("Right ⌃", comment: "keyboard key")
        case CGKeyCode(kVK_Shift): return NSLocalizedString("Left ⇧", comment: "keyboard key")
        case CGKeyCode(kVK_RightShift): return NSLocalizedString("Right ⇧", comment: "keyboard key")
        case CGKeyCode(kVK_Home): return "↖"
        case CGKeyCode(kVK_PageUp): return "⇞"
        case CGKeyCode(kVK_End): return "↘"
        case CGKeyCode(kVK_PageDown): return "⇟"
        case CGKeyCode(kVK_ForwardDelete): return "⌦"
        case CGKeyCode(kVK_Delete): return "⌫"
        case CGKeyCode(kVK_Tab): return "⇥"
        case CGKeyCode(kVK_Return): return "↩"
        case CGKeyCode(kVK_Space): return "␣"
        case CGKeyCode(kVK_LeftArrow): return "←"
        case CGKeyCode(kVK_RightArrow): return "→"
        case CGKeyCode(kVK_UpArrow): return "↑"
        case CGKeyCode(kVK_DownArrow): return "↓"
        case NJKeyInputFieldEmpty: return ""
        default:
            return String(format: NSLocalizedString("key 0x%x", comment: "unknown key code"), keyCode)
        }
    }

    override var acceptsFirstResponder: Bool {
        isEnabled
    }

    override func becomeFirstResponder() -> Bool {
        field.backgroundColor = .selectedTextBackgroundColor
        startKeyCaptureIfNeeded()
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        field.backgroundColor = .textBackgroundColor
        stopKeyCapture()
        return super.resignFirstResponder()
    }

    override func keyDown(with event: NSEvent) {
        let ignore: NSEvent.ModifierFlags = [.option, .command]
        if !event.isARepeat {
            if event.modifierFlags.intersection(ignore).isEmpty == false && event.keyCode == UInt16(kVK_Delete) {
                keyCode = NJKeyInputFieldEmpty
                delegate?.keyInputFieldDidClear(self)
            } else if event.modifierFlags.intersection(ignore).isEmpty {
                keyCode = event.keyCode
                delegate?.keyInputField(self, didChangeKey: keyCode)
            }
            _ = resignFirstResponder()
        }
    }

    private func isValidKeyCode(_ code: Int) -> Bool {
        code >= 0 && code < 0xFFFF
    }

    func controlTextDidChange(_ obj: Notification) {
        let code = Int(strtol(field.stringValue, nil, 16))
        warning.isHidden = (isValidKeyCode(code) && !field.stringValue.isEmpty) || field.stringValue.isEmpty
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        (field.cell as? NSTextFieldCell)?.placeholderString = ""
        field.isEditable = false
        field.isSelectable = false
        warning.isHidden = true

        let code = Int(strtol(field.stringValue, nil, 16))
        if !field.stringValue.isEmpty, isValidKeyCode(code) {
            keyCode = CGKeyCode(code)
            delegate?.keyInputField(self, didChangeKey: keyCode)
        } else {
            field.stringValue = Self.displayName(forKeyCode: keyCode)
        }
    }

    override func mouseDown(with event: NSEvent) {
        if isEnabled {
            if event.modifierFlags.contains(.command) {
                stopKeyCapture()
                field.isEditable = true
                field.isSelectable = true
                field.stringValue = ""
                (field.cell as? NSTextFieldCell)?.placeholderString = NSLocalizedString("enter key code", comment: "shown when user must enter a key code to map to")
                window?.makeFirstResponder(field)
            } else {
                _ = window?.makeFirstResponder(self)
                startKeyCaptureIfNeeded()
            }
        }
    }

    override func flagsChanged(with event: NSEvent) {
        if !field.isEditable && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            keyCode = event.keyCode
            delegate?.keyInputField(self, didChangeKey: keyCode)
        }
    }

    private func startKeyCaptureIfNeeded() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self else { return event }
            guard self.window?.firstResponder === self else { return event }
            guard self.field.isEditable == false else { return event }

            if event.type == .keyDown {
                let ignore: NSEvent.ModifierFlags = [.option, .command]
                if event.isARepeat { return nil }
                if event.modifierFlags.intersection(ignore).isEmpty == false && event.keyCode == UInt16(kVK_Delete) {
                    self.keyCode = NJKeyInputFieldEmpty
                    self.delegate?.keyInputFieldDidClear(self)
                } else if event.modifierFlags.intersection(ignore).isEmpty {
                    self.keyCode = event.keyCode
                    self.delegate?.keyInputField(self, didChangeKey: self.keyCode)
                }
                _ = self.resignFirstResponder()
                return nil
            }

            if event.type == .flagsChanged,
               event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                self.keyCode = event.keyCode
                self.delegate?.keyInputField(self, didChangeKey: self.keyCode)
                _ = self.resignFirstResponder()
                return nil
            }
            return event
        }
    }

    private func stopKeyCapture() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    deinit {
        stopKeyCapture()
    }
}
