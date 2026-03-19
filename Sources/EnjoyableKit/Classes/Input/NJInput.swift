import Foundation
import IOKit.hid

class NJInput: NJInputPathElement {
    let cookie: IOHIDElementCookie
    var active: Bool = false
    var magnitude: Float = 0

    init(name: String, eid: String, element: IOHIDElement, parent: NJInputPathElement?) {
        var fullName = name
        if let elementName = IOHIDElementGetName(element) as String?, !elementName.isEmpty {
            fullName += "- \(elementName)"
        }
        cookie = IOHIDElementGetCookie(element)
        super.init(name: fullName, eid: eid, parent: parent)
    }

    override init(name: String, eid: String?, parent: NJInputPathElement?) {
        cookie = IOHIDElementCookie(0)
        super.init(name: name, eid: eid, parent: parent)
    }

    func findSubInput(for value: IOHIDValue) -> Any? {
        nil
    }

    func notifyEvent(_ value: IOHIDValue) {
        fatalError("Subclasses must override notifyEvent(_:)")
    }
}
