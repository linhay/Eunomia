import Foundation
import IOKit.hid

private let activeEightWay: [Bool] = [
    false, false, false, false,
    true, false, false, false,
    true, false, false, true,
    false, false, false, true,
    false, true, false, true,
    false, true, false, false,
    false, true, true, false,
    false, false, true, false,
    true, false, true, false,
]

private let activeFourWay: [Bool] = [
    false, false, false, false,
    true, false, false, false,
    false, false, false, true,
    false, true, false, false,
    false, false, true, false,
]

@objc(NJInputHat)
class NJInputHat: NJInput {
    private let maxValue: CFIndex

    @objc(initWithElement:index:parent:)
    init(element: IOHIDElement, index: Int32, parent: NJInputPathElement?) {
        maxValue = IOHIDElementGetLogicalMax(element)
        let name = String(format: NSLocalizedString("hat switch %d", comment: "hat switch name"), Int(index))
        let eid = String(format: "Hat Switch %d", Int(index))
        super.init(name: name, eid: eid, element: element, parent: parent)
        children = [
            NJInput(name: NSLocalizedString("hat up", comment: "hat switch up state"), eid: "Up", parent: self),
            NJInput(name: NSLocalizedString("hat down", comment: "hat switch down state"), eid: "Down", parent: self),
            NJInput(name: NSLocalizedString("hat left", comment: "hat switch left state"), eid: "Left", parent: self),
            NJInput(name: NSLocalizedString("hat right", comment: "hat switch right state"), eid: "Right", parent: self),
        ]
    }

    @objc override func findSubInput(for value: IOHIDValue) -> Any? {
        let parsed = IOHIDValueGetIntegerValue(value)
        switch maxValue {
        case 7:
            switch parsed { case 0: return children?[0]; case 4: return children?[1]; case 6: return children?[2]; case 2: return children?[3]; default: return nil }
        case 8:
            switch parsed { case 1: return children?[0]; case 5: return children?[1]; case 7: return children?[2]; case 3: return children?[3]; default: return nil }
        case 3:
            switch parsed { case 0: return children?[0]; case 2: return children?[1]; case 3: return children?[2]; case 1: return children?[3]; default: return nil }
        case 4:
            switch parsed { case 1: return children?[0]; case 3: return children?[1]; case 4: return children?[2]; case 2: return children?[3]; default: return nil }
        default:
            return nil
        }
    }

    @objc override func notifyEvent(_ value: IOHIDValue) {
        var parsed = IOHIDValueGetIntegerValue(value)
        var size = maxValue
        if size & 1 == 1 {
            parsed += 1
            size += 1
        }
        let activeChildren = size == 8 ? activeEightWay : activeFourWay
        for i in 0..<4 {
            let active = activeChildren[Int(parsed) * 4 + i]
            let child = children?[i] as? NJInput
            child?.active = active
            child?.magnitude = active ? 1 : 0
        }
    }
}
