import Foundation
import IOKit.hid

private func inputsForDevice(_ device: IOHIDDevice, parent: NJInputPathElement) -> [NJInputPathElement] {
    guard let elements = IOHIDDeviceCopyMatchingElements(device, nil, IOOptionBits(kIOHIDOptionsTypeNone)) as? [IOHIDElement] else {
        return []
    }
    var children: [NJInputPathElement] = []
    var buttons: Int32 = 0
    var axes: Int32 = 0
    var hats: Int32 = 0

    for element in elements {
        let type = IOHIDElementGetType(element)
        let usage = IOHIDElementGetUsage(element)
        let usagePage = IOHIDElementGetUsagePage(element)
        let max = IOHIDElementGetPhysicalMax(element)
        let min = IOHIDElementGetPhysicalMin(element)

        if !(type == kIOHIDElementTypeInput_Misc || type == kIOHIDElementTypeInput_Axis || type == kIOHIDElementTypeInput_Button) {
            continue
        }

        let input: NJInput?
        if max - min == 1 || usagePage == kHIDPage_Button || type == kIOHIDElementTypeInput_Button {
            buttons += 1
            input = NJInputButton(element: element, index: buttons, parent: parent)
        } else if usage == kHIDUsage_GD_Hatswitch {
            hats += 1
            input = NJInputHat(element: element, index: hats, parent: parent)
        } else if usage >= kHIDUsage_GD_X && usage <= kHIDUsage_GD_Rz {
            axes += 1
            input = NJInputAnalog(element: element, index: axes, parent: parent)
        } else {
            input = nil
        }

        if let input { children.append(input) }
    }

    return children
}

class NJDevice: NJInputPathElement {
    var index: Int32 = 1
    var device: IOHIDDevice

    private let vendorId: Int32
    private let productId: Int32

    init(device dev: IOHIDDevice) {
        device = dev
        let rawName = IOHIDDeviceGetProperty(dev, kIOHIDProductKey as CFString) as? String ?? ""
        vendorId = (IOHIDDeviceGetProperty(dev, kIOHIDVendorIDKey as CFString) as? NSNumber)?.int32Value ?? 0
        productId = (IOHIDDeviceGetProperty(dev, kIOHIDProductIDKey as CFString) as? NSNumber)?.int32Value ?? 0
        super.init(name: rawName, eid: nil, parent: nil)
        children = inputsForDevice(dev, parent: self)
    }

    override var name: String {
        get { "\(super.name) #\(index)" }
        set { super.name = newValue }
    }

    override var uid: String {
        "\(vendorId):\(productId):\(index)"
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NJDevice else { return false }
        return other.name == name
    }

    func findInput(byCookie cookie: IOHIDElementCookie) -> NJInput? {
        for case let child as NJInput in children ?? [] {
            if child.cookie == cookie { return child }
        }
        return nil
    }

    func handler(for value: IOHIDValue) -> NJInput? {
        input(forEvent: value)?.findSubInput(for: value) as? NJInput
    }

    func input(forEvent value: IOHIDValue) -> NJInput? {
        let elt = IOHIDValueGetElement(value)
        let cookie = IOHIDElementGetCookie(elt)
        return findInput(byCookie: cookie)
    }
}
