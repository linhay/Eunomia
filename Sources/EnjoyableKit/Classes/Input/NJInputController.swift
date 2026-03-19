import AppKit
import CoreVideo
import IOKit.hid

@objc protocol NJInputControllerDelegate {
    @objc(inputController:didAddDevice:) func inputController(_ ic: NJInputController, didAddDevice device: NJDevice)
    @objc(inputController:didRemoveDeviceAtIndex:) func inputController(_ ic: NJInputController, didRemoveDeviceAtIndex idx: Int)
    @objc(inputController:didInput:) func inputController(_ ic: NJInputController, didInput input: NJInput)
    @objc(inputControllerDidStartHID:) func inputControllerDidStartHID(_ ic: NJInputController)
    @objc(inputControllerDidStopHID:) func inputControllerDidStopHID(_ ic: NJInputController)
    @objc(inputController:didError:) func inputController(_ ic: NJInputController, didError error: NSError)
}

private let ioStrDeviceUsagePageKey = kIOHIDDeviceUsagePageKey as String
private let ioStrDeviceUsageKey = kIOHIDDeviceUsageKey as String

@objc(NJInputController)
class NJInputController: NSObject, NJHIDManagerDelegate {
    @objc weak var delegate: NJInputControllerDelegate?

    @objc var mouseLoc: NSPoint = .zero
    @objc var simulatingEvents: Bool = false {
        didSet {
            if simulatingEvents == oldValue { return }
            let name = simulatingEvents ? NJEventSimulationStarted : NJEventSimulationStopped
            NotificationCenter.default.post(name: Notification.Name(name), object: self)

            if !simulatingEvents && !NSApplication.shared.isActive {
                stopHid()
            } else {
                startHid()
            }
        }
    }

    @objc private(set) var devices: [NJDevice] = []
    @objc private(set) var currentMapping: NJMapping
    @objc private(set) var mappings: [NJMapping]

    private let hidManager: NJHIDManager
    private var continuousOutputs: [NJOutput] = []
    private var manualMapping: NJMapping
    private var displayLink: CVDisplayLink?

    override init() {
        let defaultMapping = NJMapping(name: NSLocalizedString("(default)", comment: "default name for first the mapping"))
        currentMapping = defaultMapping
        manualMapping = defaultMapping
        mappings = [defaultMapping]

        hidManager = NJHIDManager(criteria: [
            [ioStrDeviceUsagePageKey: NSNumber(value: kHIDPage_GenericDesktop), ioStrDeviceUsageKey: NSNumber(value: kHIDUsage_GD_Joystick)],
            [ioStrDeviceUsagePageKey: NSNumber(value: kHIDPage_GenericDesktop), ioStrDeviceUsageKey: NSNumber(value: kHIDUsage_GD_GamePad)],
            [ioStrDeviceUsagePageKey: NSNumber(value: kHIDPage_GenericDesktop), ioStrDeviceUsageKey: NSNumber(value: kHIDUsage_GD_MultiAxisController)],
        ], delegate: nil)

        super.init()

        hidManager.delegate = self

        var link: CVDisplayLink?
        let cvErr = CVDisplayLinkCreateWithActiveCGDisplays(&link)
        if cvErr == kCVReturnSuccess {
            displayLink = link
            if let displayLink {
                CVDisplayLinkSetOutputCallback(displayLink, { _, _, _, _, _, ctx in
                    guard let ctx else { return kCVReturnError }
                    let me = Unmanaged<NJInputController>.fromOpaque(ctx).takeUnretainedValue()
                    me.performSelector(onMainThread: #selector(NJInputController.updateContinuousOutputs), with: nil, waitUntilDone: false)
                    return kCVReturnSuccess
                }, Unmanaged.passUnretained(self).toOpaque())
            }
        } else {
            delegate?.inputController(self, didError: NSError(domain: NSCocoaErrorDomain, code: Int(cvErr)))
        }

        NotificationCenter.default.addObserver(self, selector: #selector(stopHidIfDisabled(_:)), name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startHid), name: NSApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }

    private func addRunningOutput(_ output: NJOutput) {
        if !continuousOutputs.contains(output) {
            continuousOutputs.append(output)
        }
        if let displayLink, !CVDisplayLinkIsRunning(displayLink) {
            CVDisplayLinkStart(displayLink)
        }
    }

    private func runOutput(for value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let deviceRef = IOHIDElementGetDevice(element)
        guard let dev = findDevice(by: deviceRef), let mainInput = dev.input(forEvent: value) else { return }

        mainInput.notifyEvent(value)

        let children: [NJInput]
        if let subs = mainInput.children as? [NJInput] {
            children = subs
        } else {
            children = [mainInput]
        }

        for subInput in children {
            guard let output = currentMapping[subInput] else { continue }
            output.magnitude = subInput.magnitude
            output.running = subInput.active
            if (output.running || output.magnitude != 0) && output.isContinuous {
                addRunningOutput(output)
            }
        }
    }

    private func showOutput(for value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let deviceRef = IOHIDElementGetDevice(element)
        guard let dev = findDevice(by: deviceRef), let handler = dev.handler(for: value) else { return }
        delegate?.inputController(self, didInput: handler)
    }

    @objc(updateContinuousOutputs)
    func updateContinuousOutputs() {
        mouseLoc = NSEvent.mouseLocation
        for output in continuousOutputs {
            if !output.update(self) {
                continuousOutputs.removeAll { $0 === output }
            }
        }
        if continuousOutputs.isEmpty, let displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }

    private func addDevice(_ device: NJDevice) {
        var candidate = device
        while devices.contains(where: { $0.isEqual(candidate) }) {
            candidate.index += 1
        }
        devices.append(candidate)
    }

    private func findDevice(by ref: IOHIDDevice) -> NJDevice? {
        devices.first { $0.device == ref }
    }

    @objc(startHid)
    func startHid() {
        hidManager.start()
    }

    @objc(stopHid)
    func stopHid() {
        hidManager.stop()
    }

    @objc(stopHidIfDisabled:)
    func stopHidIfDisabled(_ note: Notification) {
        if !simulatingEvents && !ProcessInfo.processInfo.isBeingDebuggedCompat() {
            stopHid()
        }
    }

    @objc(elementForUID:)
    func element(forUID uid: String) -> NJInputPathElement? {
        for dev in devices {
            if let item = dev.element(forUID: uid) {
                return item
            }
        }
        return nil
    }

    @objc(mappingForKey:)
    func mapping(forKey name: String) -> NJMapping? {
        mappings.first { $0.name == name }
    }

    private func mappingsSet() {
        postLoadProcess()
        NotificationCenter.default.post(
            name: Notification.Name(NJEventMappingListChanged),
            object: self,
            userInfo: [NJMappingListKey: mappings, NJMappingKey: currentMapping]
        )
    }

    private func mappingsChanged() {
        save()
        mappingsSet()
    }

    @objc(activateMappingForProcess:)
    func activateMapping(forProcess app: NSRunningApplication) {
        let oldMapping = manualMapping
        let names = app.possibleMappingNamesCompat()
        var found = false

        for name in names {
            if let mapping = mapping(forKey: name) {
                activateMapping(mapping)
                found = true
                break
            }
        }

        if !found {
            activateMapping(oldMapping)
            if oldMapping.name.lowercased() == "@application" || oldMapping.name.lowercased() == NSLocalizedString("@Application", comment: "").lowercased() {
                renameMapping(oldMapping, to: app.bestMappingNameCompat())
            }
        }
        manualMapping = oldMapping
    }

    func activateMappingForcibly(_ mapping: NJMapping) {
        NSLog("Switching to mapping %@.", mapping.name)
        currentMapping = mapping
        let idx = indexOfMapping(mapping)
        NotificationCenter.default.post(
            name: Notification.Name(NJEventMappingChanged),
            object: self,
            userInfo: [NJMappingKey: currentMapping, NJMappingIndexKey: idx]
        )
    }

    @objc(activateMapping:)
    func activateMapping(_ mapping: NJMapping?) {
        let target = mapping ?? manualMapping
        if target === currentMapping { return }
        manualMapping = target
        activateMappingForcibly(target)
    }

    @objc(save)
    func save() {
        NSLog("Saving mappings to defaults.")
        let ary = mappings.map { $0.serialize() }
        UserDefaults.standard.set(ary, forKey: "mappings")
    }

    func postLoadProcess() {
        for mapping in mappings {
            mapping.postLoadProcess(mappings as NSFastEnumeration)
        }
    }

    @objc(load)
    func load() {
        var selected = UserDefaults.standard.integer(forKey: "selected")
        let storedMappings = UserDefaults.standard.array(forKey: "mappings") as? [[String: Any]] ?? []
        let newMappings = storedMappings.map { NJMapping(serialization: $0) }

        if !newMappings.isEmpty {
            mappings = newMappings
            if selected >= newMappings.count { selected = 0 }
            activateMapping(mappings[selected])
            mappingsSet()
        }
    }

    @objc(indexOfMapping:)
    func indexOfMapping(_ mapping: NJMapping) -> Int {
        mappings.firstIndex(where: { $0 === mapping }) ?? NSNotFound
    }

    @objc(mergeMapping:intoMapping:)
    func mergeMapping(_ mapping: NJMapping, into existing: NJMapping) {
        existing.mergeEntries(from: mapping)
        mappingsChanged()
        if existing === currentMapping {
            activateMappingForcibly(mapping)
        }
    }

    @objc(renameMapping:to:)
    func renameMapping(_ mapping: NJMapping, to name: String) {
        mapping.name = name
        mappingsChanged()
        if mapping === currentMapping {
            activateMappingForcibly(mapping)
        }
    }

    @objc(addMapping:)
    func addMapping(_ mapping: NJMapping) {
        insertMapping(mapping, at: mappings.count)
    }

    @objc(insertMapping:atIndex:)
    func insertMapping(_ mapping: NJMapping, at idx: Int) {
        mappings.insert(mapping, at: idx)
        mappingsChanged()
    }

    @objc(removeMappingAtIndex:)
    func removeMapping(at idx: Int) {
        let currentIdx = indexOfMapping(currentMapping)
        mappings.remove(at: idx)
        let activeIdx = min(currentIdx, mappings.count - 1)
        activateMapping(mappings[activeIdx])
        mappingsChanged()
    }

    @objc(moveMoveMappingFromIndex:toIndex:)
    func moveMoveMapping(fromIndex: Int, toIndex: Int) {
        let item = mappings.remove(at: fromIndex)
        mappings.insert(item, at: toIndex)
        mappingsChanged()
    }

    // MARK: NJHIDManagerDelegate

    @objc(HIDManager:valueChanged:)
    func HIDManager(_ manager: NJHIDManager, valueChanged value: IOHIDValue) {
        if simulatingEvents && !NSApplication.shared.isActive {
            runOutput(for: value)
        } else {
            showOutput(for: value)
        }
    }

    @objc(HIDManager:deviceAdded:)
    func HIDManager(_ manager: NJHIDManager, deviceAdded device: IOHIDDevice) {
        let match = NJDevice(device: device)
        addDevice(match)
        delegate?.inputController(self, didAddDevice: match)
    }

    @objc(HIDManager:deviceRemoved:)
    func HIDManager(_ manager: NJHIDManager, deviceRemoved device: IOHIDDevice) {
        guard let match = findDevice(by: device), let idx = devices.firstIndex(where: { $0 === match }) else { return }
        devices.remove(at: idx)
        delegate?.inputController(self, didRemoveDeviceAtIndex: idx)
    }

    @objc(HIDManager:didError:)
    func HIDManager(_ manager: NJHIDManager, didError error: NSError) {
        delegate?.inputController(self, didError: error)
        simulatingEvents = false
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }

    @objc(HIDManagerDidStart:)
    func HIDManagerDidStart(_ manager: NJHIDManager) {
        delegate?.inputControllerDidStartHID(self)
    }

    @objc(HIDManagerDidStop:)
    func HIDManagerDidStop(_ manager: NJHIDManager) {
        devices.removeAll()
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
        delegate?.inputControllerDidStopHID(self)
    }
}
