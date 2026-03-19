import AppKit

@objc protocol NJOutputViewControllerDelegate {
    @objc(outputViewController:mappingForIndex:) func outputViewController(_ ovc: NJOutputViewController, mappingForIndex index: UInt) -> NJMapping
    @objc(outputViewController:setOutput:forInput:) func outputViewController(_ ovc: NJOutputViewController, setOutput output: NJOutput?, forInput input: NJInput?)
}

@objc(NJOutputViewController)
class NJOutputViewController: NSObject, NJKeyInputFieldDelegate {
    @objc var keyInput: NJKeyInputField!
    @objc var radioButtons: NSMatrix!
    @objc var mouseDirSelect: NSSegmentedControl!
    @objc var mouseSpeedSlider: NSSlider!
    @objc var mouseBtnSelect: NSSegmentedControl!
    @objc var scrollDirSelect: NSSegmentedControl!
    @objc var scrollSpeedSlider: NSSlider!
    @objc var title: NSTextField!
    @objc var mappingPopup: NSPopUpButton!
    @objc var smoothCheck: NSButton!
    @objc var unknownMapping: NSButton!

    @objc weak var delegate: NJOutputViewControllerDelegate?

    private var input: NJInput?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(mappingListDidChange(_:)), name: Notification.Name(NJEventMappingListChanged), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func cleanUpInterface() {
        let row = radioButtons.selectedRow

        if row != 1 {
            keyInput.keyCode = NJKeyInputFieldEmpty
            _ = keyInput.resignIfFirstResponderCompat()
        }

        if row != 2 {
            mappingPopup.selectItem(at: -1)
            _ = mappingPopup.resignIfFirstResponderCompat()
            unknownMapping.isHidden = true
        }

        if row != 3 {
            mouseDirSelect.selectedSegment = -1
            mouseSpeedSlider.doubleValue = mouseSpeedSlider.minValue
            _ = mouseDirSelect.resignIfFirstResponderCompat()
        } else {
            if mouseDirSelect.selectedSegment == -1 {
                mouseDirSelect.selectedSegment = 0
            }
            if mouseSpeedSlider.floatValue == 0 {
                mouseSpeedSlider.floatValue = 10
            }
        }

        if row != 4 {
            mouseBtnSelect.selectedSegment = -1
            _ = mouseBtnSelect.resignIfFirstResponderCompat()
        } else if mouseBtnSelect.selectedSegment == -1 {
            mouseBtnSelect.selectedSegment = 0
        }

        if row != 5 {
            scrollDirSelect.selectedSegment = -1
            scrollSpeedSlider.doubleValue = scrollSpeedSlider.minValue
            smoothCheck.state = .off
            _ = scrollDirSelect.resignIfFirstResponderCompat()
            _ = scrollSpeedSlider.resignIfFirstResponderCompat()
            _ = smoothCheck.resignIfFirstResponderCompat()
        } else if scrollDirSelect.selectedSegment == -1 {
            scrollDirSelect.selectedSegment = 0
        }
    }

    @objc(outputTypeChanged:)
    func outputTypeChanged(_ sender: NSView) {
        sender.window?.makeFirstResponder(sender)
        if radioButtons.selectedRow == 1 {
            keyInput.window?.makeFirstResponder(keyInput)
        }
        commit()
    }

    func keyInputField(_ keyInput: NJKeyInputField, didChangeKey keyCode: CGKeyCode) {
        radioButtons.selectCell(atRow: 1, column: 0)
        radioButtons.window?.makeFirstResponder(radioButtons)
        commit()
    }

    func keyInputFieldDidClear(_ keyInput: NJKeyInputField) {
        radioButtons.selectCell(atRow: 0, column: 0)
        commit()
    }

    @objc(mappingChosen:)
    func mappingChosen(_ sender: Any?) {
        radioButtons.selectCell(atRow: 2, column: 0)
        mappingPopup.window?.makeFirstResponder(mappingPopup)
        unknownMapping.isHidden = true
        commit()
    }

    @objc(mouseDirectionChanged:)
    func mouseDirectionChanged(_ sender: NSView) {
        radioButtons.selectCell(atRow: 3, column: 0)
        sender.window?.makeFirstResponder(sender)
        commit()
    }

    @objc(mouseSpeedChanged:)
    func mouseSpeedChanged(_ sender: NSSlider) {
        radioButtons.selectCell(atRow: 3, column: 0)
        sender.window?.makeFirstResponder(sender)
        commit()
    }

    @objc(mouseButtonChanged:)
    func mouseButtonChanged(_ sender: NSView) {
        radioButtons.selectCell(atRow: 4, column: 0)
        sender.window?.makeFirstResponder(sender)
        commit()
    }

    @objc(scrollDirectionChanged:)
    func scrollDirectionChanged(_ sender: NSView) {
        radioButtons.selectCell(atRow: 5, column: 0)
        sender.window?.makeFirstResponder(sender)
        commit()
    }

    @objc(scrollSpeedChanged:)
    func scrollSpeedChanged(_ sender: NSSlider) {
        radioButtons.selectCell(atRow: 5, column: 0)
        sender.window?.makeFirstResponder(sender)
        commit()
    }

    @objc(scrollTypeChanged:)
    func scrollTypeChanged(_ sender: NSButton) {
        radioButtons.selectCell(atRow: 5, column: 0)
        sender.window?.makeFirstResponder(sender)
        if sender.state == .on {
            scrollSpeedSlider.doubleValue = scrollSpeedSlider.minValue + (scrollSpeedSlider.maxValue - scrollSpeedSlider.minValue) / 2
            scrollSpeedSlider.isEnabled = true
        } else {
            scrollSpeedSlider.doubleValue = scrollSpeedSlider.minValue
            scrollSpeedSlider.isEnabled = false
        }
        commit()
    }

    private func makeOutput() -> NJOutput? {
        switch radioButtons.selectedRow {
        case 0:
            return nil
        case 1:
            guard keyInput.hasKeyCode else { return nil }
            let output = NJOutputKeyPress()
            output.keyCode = keyInput.keyCode
            return output
        case 2:
            let output = NJOutputMapping()
            output.mapping = delegate?.outputViewController(self, mappingForIndex: UInt(mappingPopup.indexOfSelectedItem))
            return output
        case 3:
            let output = NJOutputMouseMove()
            output.axis = Int32(mouseDirSelect.selectedSegment)
            output.speed = mouseSpeedSlider.floatValue
            return output
        case 4:
            let output = NJOutputMouseButton()
            let tag = mouseBtnSelect.tag(forSegment: mouseBtnSelect.selectedSegment)
            output.button = CGMouseButton(rawValue: UInt32(tag)) ?? .left
            return output
        case 5:
            let output = NJOutputMouseScroll()
            let dirTag = scrollDirSelect.tag(forSegment: scrollDirSelect.selectedSegment)
            output.direction = Int32(dirTag)
            output.speed = scrollSpeedSlider.floatValue
            output.smooth = smoothCheck.state == .on
            return output
        default:
            return nil
        }
    }

    private func commit() {
        cleanUpInterface()
        delegate?.outputViewController(self, setOutput: makeOutput(), forInput: input)
    }

    @objc var enabled: Bool {
        get { radioButtons.isEnabled }
        set {
            radioButtons.isEnabled = newValue
            keyInput.isEnabled = newValue
            mappingPopup.isEnabled = newValue
            mouseDirSelect.isEnabled = newValue
            mouseSpeedSlider.isEnabled = newValue
            mouseBtnSelect.isEnabled = newValue
            scrollDirSelect.isEnabled = newValue
            smoothCheck.isEnabled = newValue
            scrollSpeedSlider.isEnabled = newValue && smoothCheck.state == .on
            if !newValue {
                unknownMapping.isHidden = true
            }
        }
    }

    @objc(loadOutput:forInput:)
    func loadOutput(_ output: NJOutput?, forInput input: NJInput?) {
        self.input = input
        if let input {
            enabled = true
            var fullName = input.name
            var cur = input.parent
            while let c = cur {
                fullName = "\(c.name) ▸ \(fullName)"
                cur = c.parent
            }
            title.stringValue = fullName
        } else {
            enabled = false
            title.stringValue = ""
        }

        if let output = output as? NJOutputKeyPress {
            radioButtons.selectCell(atRow: 1, column: 0)
            keyInput.keyCode = output.keyCode
        } else if let output = output as? NJOutputMapping {
            radioButtons.selectCell(atRow: 2, column: 0)
            let item = mappingPopup.item(withIdenticalRepresentedObject: output.mapping)
            mappingPopup.select(item)
            unknownMapping.isHidden = item != nil
            unknownMapping.title = output.mappingName ?? ""
        } else if let output = output as? NJOutputMouseMove {
            radioButtons.selectCell(atRow: 3, column: 0)
            mouseDirSelect.selectedSegment = Int(output.axis)
            mouseSpeedSlider.floatValue = output.speed
        } else if let output = output as? NJOutputMouseButton {
            radioButtons.selectCell(atRow: 4, column: 0)
            mouseBtnSelect.selectSegment(withTag: Int(output.button.rawValue))
        } else if let output = output as? NJOutputMouseScroll {
            radioButtons.selectCell(atRow: 5, column: 0)
            scrollDirSelect.selectSegment(withTag: Int(output.direction))
            scrollSpeedSlider.floatValue = output.speed
            smoothCheck.state = output.smooth ? .on : .off
            scrollSpeedSlider.isEnabled = output.smooth
        } else {
            radioButtons.selectCell(atRow: enabled ? 0 : -1, column: 0)
        }

        cleanUpInterface()
    }

    @objc func focusKey() {
        if radioButtons.selectedRow <= 1 {
            keyInput.window?.makeFirstResponder(keyInput)
        } else {
            _ = keyInput.resignIfFirstResponderCompat()
        }
    }

    @objc(mappingListDidChange:)
    func mappingListDidChange(_ note: Notification) {
        let mappings = note.userInfo?[NJMappingListKey] as? [NJMapping] ?? []
        let current = mappingPopup.selectedItem?.representedObject
        mappingPopup.menu?.removeAllItems()

        for mapping in mappings {
            let item = NSMenuItem(title: mapping.name, action: #selector(mappingChosen(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mapping
            mappingPopup.menu?.addItem(item)
        }

        mappingPopup.selectItem(withIdenticalRepresentedObject: current)
    }
}
