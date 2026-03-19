import AppKit
import CoreVideo
import IOKit.hid

protocol NJInputControllerDelegate: AnyObject {
    func inputController(_ ic: NJInputController, didAddDevice device: NJDevice)
    func inputController(_ ic: NJInputController, didRemoveDeviceAtIndex idx: Int)
    func inputController(_ ic: NJInputController, didInput input: NJInput)
    func inputControllerDidStartHID(_ ic: NJInputController)
    func inputControllerDidStopHID(_ ic: NJInputController)
    func inputController(_ ic: NJInputController, didError error: NSError)
}

private let ioStrDeviceUsagePageKey = kIOHIDDeviceUsagePageKey as String
private let ioStrDeviceUsageKey = kIOHIDDeviceUsageKey as String

class NJInputController: NSObject, NJHIDManagerDelegate {
    weak var delegate: NJInputControllerDelegate?

    var mouseLoc: NSPoint = .zero
    var simulatingEvents: Bool = false {
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

    private(set) var devices: [NJDevice] = []
    private(set) var currentMapping: NJMapping
    private(set) var mappings: [NJMapping]

    private let hidManager: NJHIDManager
    private var continuousOutputs: [NJOutput] = []
    private var manualMapping: NJMapping
    private var displayLink: CVDisplayLink?
    private var didResignObserver: NSObjectProtocol?
    private var didBecomeActiveObserver: NSObjectProtocol?

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
                    DispatchQueue.main.async {
                        me.updateContinuousOutputs()
                    }
                    return kCVReturnSuccess
                }, Unmanaged.passUnretained(self).toOpaque())
            }
        } else {
            delegate?.inputController(self, didError: NSError(domain: NSCocoaErrorDomain, code: Int(cvErr)))
        }

        didResignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopHidIfDisabled()
        }

        didBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startHid()
        }
    }

    deinit {
        if let didResignObserver {
            NotificationCenter.default.removeObserver(didResignObserver)
        }
        if let didBecomeActiveObserver {
            NotificationCenter.default.removeObserver(didBecomeActiveObserver)
        }
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
        guard let dev = findDevice(by: deviceRef), let mainInput = dev.input(forEvent: value) else { return }

        mainInput.notifyEvent(value)

        if let children = mainInput.children as? [NJInput], !children.isEmpty {
            for child in children {
                delegate?.inputController(self, didInput: child)
            }
        } else {
            delegate?.inputController(self, didInput: mainInput)
        }
    }

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
        let candidate = device
        while devices.contains(where: { $0.isEqual(candidate) }) {
            candidate.index += 1
        }
        devices.append(candidate)
    }

    private func findDevice(by ref: IOHIDDevice) -> NJDevice? {
        devices.first { $0.device == ref }
    }

    func startHid() {
        hidManager.start()
    }

    func stopHid() {
        hidManager.stop()
    }

    func stopHidIfDisabled() {
        if !simulatingEvents && !ProcessInfo.processInfo.isBeingDebuggedCompat() {
            stopHid()
        }
    }

    func element(forUID uid: String) -> NJInputPathElement? {
        for dev in devices {
            if let item = dev.element(forUID: uid) {
                return item
            }
        }
        return nil
    }

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

    func activateMapping(_ mapping: NJMapping?) {
        let target = mapping ?? manualMapping
        if target === currentMapping { return }
        manualMapping = target
        activateMappingForcibly(target)
    }

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

    func indexOfMapping(_ mapping: NJMapping) -> Int {
        mappings.firstIndex(where: { $0 === mapping }) ?? NSNotFound
    }

    func mergeMapping(_ mapping: NJMapping, into existing: NJMapping) {
        existing.mergeEntries(from: mapping)
        mappingsChanged()
        if existing === currentMapping {
            activateMappingForcibly(mapping)
        }
    }

    func renameMapping(_ mapping: NJMapping, to name: String) {
        mapping.name = name
        mappingsChanged()
        if mapping === currentMapping {
            activateMappingForcibly(mapping)
        }
    }

    func addMapping(_ mapping: NJMapping) {
        insertMapping(mapping, at: mappings.count)
    }

    func insertMapping(_ mapping: NJMapping, at idx: Int) {
        mappings.insert(mapping, at: idx)
        mappingsChanged()
    }

    func removeMapping(at idx: Int) {
        let currentIdx = indexOfMapping(currentMapping)
        mappings.remove(at: idx)
        let activeIdx = min(currentIdx, mappings.count - 1)
        activateMapping(mappings[activeIdx])
        mappingsChanged()
    }

    func moveMoveMapping(fromIndex: Int, toIndex: Int) {
        let item = mappings.remove(at: fromIndex)
        mappings.insert(item, at: toIndex)
        mappingsChanged()
    }

    // MARK: NJHIDManagerDelegate

    func HIDManager(_ manager: NJHIDManager, valueChanged value: IOHIDValue) {
        if simulatingEvents && !NSApplication.shared.isActive {
            runOutput(for: value)
        } else {
            showOutput(for: value)
        }
    }

    func HIDManager(_ manager: NJHIDManager, deviceAdded device: IOHIDDevice) {
        let match = NJDevice(device: device)
        addDevice(match)
        delegate?.inputController(self, didAddDevice: match)
    }

    func HIDManager(_ manager: NJHIDManager, deviceRemoved device: IOHIDDevice) {
        guard let match = findDevice(by: device), let idx = devices.firstIndex(where: { $0 === match }) else { return }
        devices.remove(at: idx)
        delegate?.inputController(self, didRemoveDeviceAtIndex: idx)
    }

    func HIDManager(_ manager: NJHIDManager, didError error: NSError) {
        delegate?.inputController(self, didError: error)
        simulatingEvents = false
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }

    func HIDManagerDidStart(_ manager: NJHIDManager) {
        delegate?.inputControllerDidStartHID(self)
    }

    func HIDManagerDidStop(_ manager: NJHIDManager) {
        devices.removeAll()
        if let displayLink {
            CVDisplayLinkStop(displayLink)
        }
        delegate?.inputControllerDidStopHID(self)
    }
}
