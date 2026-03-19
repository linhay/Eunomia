import Foundation
import IOKit.hid

@objc protocol NJHIDManagerDelegate {
    @objc(HIDManagerDidStart:) func HIDManagerDidStart(_ manager: NJHIDManager)
    @objc(HIDManagerDidStop:) func HIDManagerDidStop(_ manager: NJHIDManager)
    @objc(HIDManager:deviceAdded:) func HIDManager(_ manager: NJHIDManager, deviceAdded device: IOHIDDevice)
    @objc(HIDManager:deviceRemoved:) func HIDManager(_ manager: NJHIDManager, deviceRemoved device: IOHIDDevice)
    @objc(HIDManager:valueChanged:) func HIDManager(_ manager: NJHIDManager, valueChanged value: IOHIDValue)
    @objc(HIDManager:didError:) func HIDManager(_ manager: NJHIDManager, didError error: NSError)
}

@objc(NJHIDManager)
class NJHIDManager: NSObject {
    @objc weak var delegate: NJHIDManagerDelegate?
    @objc var criteria: [Any] = [] {
        didSet {
            if oldValue as NSArray != criteria as NSArray {
                let wasRunning = running
                stop()
                if wasRunning { start() }
            }
        }
    }

    private var manager: IOHIDManager?

    @objc(initWithCriteria:delegate:)
    init(criteria: [Any], delegate: NJHIDManagerDelegate?) {
        self.criteria = criteria
        self.delegate = delegate
    }

    deinit {
        stop()
    }

    @objc var running: Bool {
        get { manager != nil }
        set { newValue ? start() : stop() }
    }

    @objc func start() {
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

    @objc func stop() {
        guard let mgr = manager else { return }
        IOHIDManagerUnscheduleFromRunLoop(mgr, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        manager = nil
        delegate?.HIDManagerDidStop(self)
        NSLog("Stopped HID manager.")
    }
}
