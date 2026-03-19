import Foundation
import IOKit.hid

@objc(NJInput)
class NJInput: NJInputPathElement {
    @objc let cookie: IOHIDElementCookie
    @objc var active: Bool = false
    @objc var magnitude: Float = 0

    @objc(initWithName:eid:element:parent:)
    init(name: String, eid: String, element: IOHIDElement, parent: NJInputPathElement?) {
        var fullName = name
        if let elementName = IOHIDElementGetName(element) as String?, !elementName.isEmpty {
            fullName += "- \(elementName)"
        }
        cookie = IOHIDElementGetCookie(element)
        super.init(name: fullName, eid: eid, parent: parent)
    }

    @objc(initWithName:eid:parent:)
    override init(name: String, eid: String?, parent: NJInputPathElement?) {
        cookie = IOHIDElementCookie(0)
        super.init(name: name, eid: eid, parent: parent)
    }

    @objc(findSubInputForValue:)
    func findSubInput(for value: IOHIDValue) -> Any? {
        nil
    }

    @objc(notifyEvent:)
    func notifyEvent(_ value: IOHIDValue) {
        doesNotRecognizeSelector(#selector(notifyEvent(_:)))
    }
}
