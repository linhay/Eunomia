import Foundation
import IOKit.hid

class NJInputButton: NJInput {
    private let maxValue: CFIndex

    init(element: IOHIDElement, index: Int32, parent: NJInputPathElement?) {
        maxValue = IOHIDElementGetLogicalMax(element)
        let name = String(format: NSLocalizedString("button %d", comment: "button name"), Int(index))
        let eid = String(format: "Button %d", Int(index))
        super.init(name: name, eid: eid, element: element, parent: parent)
    }

    override func findSubInput(for value: IOHIDValue) -> Any? {
        IOHIDValueGetIntegerValue(value) == maxValue ? self : nil
    }

    override func notifyEvent(_ value: IOHIDValue) {
        let v = IOHIDValueGetIntegerValue(value)
        active = v == maxValue
        magnitude = maxValue == 0 ? 0 : Float(v) / Float(maxValue)
    }
}
