import AppKit
import Carbon

let NJKeyInputFieldEmpty: CGKeyCode = 0xFFFF

@objc protocol NJKeyInputFieldDelegate {
    @objc(keyInputField:didChangeKey:) func keyInputField(_ keyInput: NJKeyInputField, didChangeKey keyCode: CGKeyCode)
    @objc(keyInputFieldDidClear:) func keyInputFieldDidClear(_ keyInput: NJKeyInputField)
}

@objc(NJKeyInputField)
class NJKeyInputField: NSControl, NSTextFieldDelegate {
    @objc weak var delegate: NJKeyInputFieldDelegate?

    @objc var keyCode: CGKeyCode = NJKeyInputFieldEmpty {
        didSet {
            field.stringValue = Self.displayName(forKeyCode: keyCode)
        }
    }

    @objc var hasKeyCode: Bool {
        keyCode != NJKeyInputFieldEmpty
    }

    private let field: NSTextField
    private let warning: NSImageView

    required init?(coder: NSCoder) {
        field = NSTextField(frame: .zero)
        warning = NSImageView(frame: .zero)
        super.init(coder: coder)
        commonInit()
    }

    override init(frame frameRect: NSRect) {
        field = NSTextField(frame: frameRect)
        warning = NSImageView(frame: .zero)
        super.init(frame: frameRect)
        commonInit()
    }

    private func commonInit() {
        field.frame = bounds
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

    @objc func clear() {
        keyCode = NJKeyInputFieldEmpty
        delegate?.keyInputFieldDidClear(self)
        _ = resignFirstResponder()
    }

    @objc(displayNameForKeyCode:)
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
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        field.backgroundColor = .textBackgroundColor
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
                field.isEditable = true
                field.isSelectable = true
                field.stringValue = ""
                (field.cell as? NSTextFieldCell)?.placeholderString = NSLocalizedString("enter key code", comment: "shown when user must enter a key code to map to")
                window?.makeFirstResponder(field)
            } else {
                if window?.firstResponder === self {
                    window?.makeFirstResponder(nil)
                } else if acceptsFirstResponder {
                    window?.makeFirstResponder(self)
                }
            }
        }
    }

    override func flagsChanged(with event: NSEvent) {
        if !field.isEditable && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            keyCode = event.keyCode
            delegate?.keyInputField(self, didChangeKey: keyCode)
        }
    }
}
