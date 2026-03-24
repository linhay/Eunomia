import Foundation
import IOKit.hid

protocol NJHIDManagerDelegate: AnyObject {
    func HIDManagerDidStart(_ manager: NJHIDManager)
    func HIDManagerDidStop(_ manager: NJHIDManager)
    func HIDManager(_ manager: NJHIDManager, deviceAdded device: IOHIDDevice)
    func HIDManager(_ manager: NJHIDManager, deviceRemoved device: IOHIDDevice)
    func HIDManager(_ manager: NJHIDManager, valueChanged value: IOHIDValue)
    func HIDManager(_ manager: NJHIDManager, didError error: NSError)
}

class NJHIDManager: NSObject {
    weak var delegate: NJHIDManagerDelegate?
    var criteria: [Any] = [] {
        didSet {
            if oldValue as NSArray != criteria as NSArray {
                let wasRunning = running
                stop()
                if wasRunning { start() }
            }
        }
    }

    private var manager: IOHIDManager?

    init(criteria: [Any], delegate: NJHIDManagerDelegate?) {
        self.criteria = criteria
        self.delegate = delegate
    }

    deinit {
        stop()
    }

    var running: Bool {
        get { manager != nil }
        set { newValue ? start() : stop() }
    }

    func start() {
        if running { return }
        let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatchingMultiple(mgr, criteria as CFArray)
        let ret = IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))

        guard ret == kIOReturnSuccess else {
            let error = NSError(domain: NSMachErrorDomain, code: Int(ret))
            IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
            delegate?.HIDManager(self, didError: error)
            NSLog("Error starting HID manager: %@.", error)
            return
        }

        manager = mgr
        IOHIDManagerScheduleWithRunLoop(mgr, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

        IOHIDManagerRegisterInputValueCallback(mgr, { ctx, _, _, value in
            guard let ctx else { return }
            let me = Unmanaged<NJHIDManager>.fromOpaque(ctx).takeUnretainedValue()
            me.delegate?.HIDManager(me, valueChanged: value)
        }, Unmanaged.passUnretained(self).toOpaque())

        IOHIDManagerRegisterDeviceMatchingCallback(mgr, { ctx, _, _, device in
            guard let ctx else { return }
            let me = Unmanaged<NJHIDManager>.fromOpaque(ctx).takeUnretainedValue()
            me.delegate?.HIDManager(me, deviceAdded: device)
        }, Unmanaged.passUnretained(self).toOpaque())

        IOHIDManagerRegisterDeviceRemovalCallback(mgr, { ctx, _, _, device in
            guard let ctx else { return }
            let me = Unmanaged<NJHIDManager>.fromOpaque(ctx).takeUnretainedValue()
            me.delegate?.HIDManager(me, deviceRemoved: device)
        }, Unmanaged.passUnretained(self).toOpaque())

        delegate?.HIDManagerDidStart(self)
        NSLog("Started HID manager.")
    }

    func stop() {
        guard let mgr = manager else { return }
        IOHIDManagerUnscheduleFromRunLoop(mgr, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        manager = nil
        delegate?.HIDManagerDidStop(self)
        NSLog("Stopped HID manager.")
    }
}
