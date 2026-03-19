import Foundation
import IOKit.hid

private let deadZone: Float = 0.3

private func normalize(_ p: CFIndex, _ min: CFIndex, _ max: CFIndex) -> Float {
    return 2 * Float(p - min) / Float(max - min) - 1
}

@objc(NJInputAnalog)
class NJInputAnalog: NJInput {
    private let rawMin: CFIndex
    private let rawMax: CFIndex

    @objc(initWithElement:index:parent:)
    init(element: IOHIDElement, index: Int32, parent: NJInputPathElement?) {
        rawMax = IOHIDElementGetPhysicalMax(element)
        rawMin = IOHIDElementGetPhysicalMin(element)
        let name = String(format: NSLocalizedString("axis %d", comment: "axis name"), Int(index))
        let eid = String(format: "Axis %d", Int(index))
        super.init(name: name, eid: eid, element: element, parent: parent)
        children = [
            NJInput(name: NSLocalizedString("axis low", comment: "axis low trigger"), eid: "Low", parent: self),
            NJInput(name: NSLocalizedString("axis high", comment: "axis high trigger"), eid: "High", parent: self)
        ]
    }

    @objc override func findSubInput(for value: IOHIDValue) -> Any? {
        let mag = normalize(IOHIDValueGetIntegerValue(value), rawMin, rawMax)
        if mag < -deadZone { return children?[0] }
        if mag > deadZone { return children?[1] }
        return nil
    }

    @objc override func notifyEvent(_ value: IOHIDValue) {
        var m = normalize(IOHIDValueGetIntegerValue(value), rawMin, rawMax)
        if fabsf(m) < deadZone { m = 0 }
        magnitude = m
        let low = children?[0] as? NJInput
        let high = children?[1] as? NJInput
        low?.magnitude = fabsf(Swift.min(m, 0))
        high?.magnitude = fabsf(Swift.max(m, 0))
        low?.active = m < -deadZone
        high?.active = m > deadZone
    }
}
