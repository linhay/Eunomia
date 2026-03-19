import AppKit

@objc(EnjoyableApplicationDelegate)
class EnjoyableApplicationDelegate: NSObject,
    NSApplicationDelegate,
    NJInputControllerDelegate,
    NJDeviceViewControllerDelegate,
    NJMappingsViewControllerDelegate,
    NJOutputViewControllerDelegate,
    NJMappingMenuDelegate,
    NSWindowDelegate
{
    @objc var ic: NJInputController!
    @objc var oc: NJOutputViewController!
    @objc var mvc: NJMappingsViewController!
    @objc var dvc: NJDeviceViewController!

    @objc var dockMenu: NSMenu!
    @objc var statusItemMenu: NSMenu!
    @objc var window: NSWindow!
    @objc var simulatingEventsButton: NSButton!

    private var statusItem: NSStatusItem!
    private var errors: [NSError] = []

    @objc(didSwitchApplication:)
    func didSwitchApplication(_ note: Notification) {
        if let activeApp = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            ic.activateMapping(forProcess: activeApp)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(mappingDidChange(_:)), name: Notification.Name(NJEventMappingChanged), object: nil)
        center.addObserver(self, selector: #selector(eventSimulationStarted(_:)), name: Notification.Name(NJEventSimulationStarted), object: nil)
        center.addObserver(self, selector: #selector(eventSimulationStopped(_:)), name: Notification.Name(NJEventSimulationStopped), object: nil)

        ic.load()
        mvc.mappingList.reloadData()
        mvc.changedActiveMapping(toIndex: ic.indexOfMapping(ic.currentMapping))

        statusItem = NSStatusBar.system.statusItem(withLength: 36)
        statusItem.image = NSImage(named: "Status Menu Icon Disabled")
        statusItem.menu = statusItemMenu
        statusItem.target = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "hidden in status item") && NSRunningApplication.current.wasLaunchedAsLoginItemOrResume() {
            transformIntoElement(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        restoreToForeground(sender)
        return false
    }

    @objc(restoreToForeground:)
    func restoreToForeground(_ sender: Any?) {
        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToForegroundApplication))
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(sender)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(transformIntoElement(_:)), object: self)
        UserDefaults.standard.set(false, forKey: "hidden in status item")
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        if window.isVisible {
            restoreToForeground(notification)
        }
    }

    @objc(transformIntoElement:)
    func transformIntoElement(_ sender: Any?) {
        var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
        TransformProcessType(&psn, ProcessApplicationTransformState(kProcessTransformToUIElementApplication))
        UserDefaults.standard.set(true, forKey: "hidden in status item")
    }

    @objc func flashStatusItem() {
        if statusItem.image?.name() == "Status Menu Icon" {
            statusItem.image = NSImage(named: "Status Menu Icon Disabled")
        } else {
            statusItem.image = NSImage(named: "Status Menu Icon")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        sender.hide(sender)
        perform(#selector(transformIntoElement(_:)), with: self, afterDelay: 0.001)
        return false
    }

    @objc(eventSimulationStarted:)
    func eventSimulationStarted(_ note: Notification) {
        simulatingEventsButton.state = .on
        statusItem.image = NSImage(named: "Status Menu Icon")
        ProcessInfo.processInfo.disableAutomaticTermination("Event simulation running.")
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didSwitchApplication(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    @objc(eventSimulationStopped:)
    func eventSimulationStopped(_ note: Notification) {
        simulatingEventsButton.state = .off
        statusItem.image = NSImage(named: "Status Menu Icon Disabled")
        ProcessInfo.processInfo.enableAutomaticTermination("Event simulation running.")
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didActivateApplicationNotification, object: nil)
    }

    @objc(mappingDidChange:)
    func mappingDidChange(_ note: Notification) {
        let idx = (note.userInfo?[NJMappingIndexKey] as? NSNumber)?.intValue ?? 0
        mvc.changedActiveMapping(toIndex: idx)

        if !window.isVisible {
            for i in 0..<4 {
                perform(#selector(flashStatusItem), with: self, afterDelay: 0.2 * Double(i))
            }
        }
        loadOutput(forInput: dvc.selectedHandler)
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        dockMenu
    }

    private func showNextError() {
        if window.attachedSheet == nil, let error = errors.last {
            errors.removeLast()
            NSApplication.shared.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            window.presentError(error, modalFor: window, delegate: self, didPresent: #selector(didPresentErrorWithRecovery(_:contextInfo:)), contextInfo: nil)
        }
    }

    @objc(didPresentErrorWithRecovery:contextInfo:)
    func didPresentErrorWithRecovery(_ didRecover: Bool, contextInfo: UnsafeMutableRawPointer?) {
        showNextError()
    }

    func presentErrorSheet(_ error: NSError) {
        errors.insert(error, at: 0)
        showNextError()
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        restoreToForeground(sender)

        var error: NSError?
        let url = URL(fileURLWithPath: filename)
        guard let mapping = NJMapping.mapping(withContentsOf: url, error: &error) as? NJMapping else {
            if let error { presentErrorSheet(error) }
            return false
        }

        if ic.mapping(forKey: mapping.name)?.hasConflict(with: mapping) == true {
            promptForMapping(mapping, atIndex: ic.mappings.count)
        } else if let existing = ic.mapping(forKey: mapping.name) {
            existing.mergeEntries(from: mapping)
        } else {
            mvc.beginUpdates()
            ic.addMapping(mapping)
            mvc.addedMapping(at: ic.mappings.count - 1, startEditing: false)
            mvc.endUpdates()
            ic.activateMapping(mapping)
        }

        return true
    }

    func mappingWasChosen(_ mapping: NJMapping) {
        ic.activateMapping(mapping)
    }

    func mappingListShouldOpen() {
        restoreToForeground(self)
        mvc.mappingTriggerClicked(self)
    }

    @objc(importMappingClicked:)
    func importMappingClicked(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["enjoyable", "json", "txt"]
        panel.beginSheetModal(for: window) { [weak self] result in
            guard result == .OK, let self, let url = panel.url else { return }
            var error: NSError?
            guard let mapping = NJMapping.mapping(withContentsOf: url, error: &error) as? NJMapping else {
                if let error { self.presentErrorSheet(error) }
                return
            }
            if self.ic.mapping(forKey: mapping.name)?.hasConflict(with: mapping) == true {
                self.promptForMapping(mapping, atIndex: self.ic.mappings.count)
            } else if let existing = self.ic.mapping(forKey: mapping.name) {
                existing.mergeEntries(from: mapping)
            } else {
                self.ic.addMapping(mapping)
            }
        }
    }

    @objc(exportMappingClicked:)
    func exportMappingClicked(_ sender: Any?) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["enjoyable"]
        let mapping = ic.currentMapping
        panel.nameFieldStringValue = mapping.name.stringByFixingPathComponentCompat()
        panel.beginSheetModal(for: window) { [weak self] result in
            guard result == .OK, let self, let url = panel.url else { return }
            var error: NSError?
            if !mapping.write(to: url, error: &error), let error {
                self.presentErrorSheet(error)
            }
        }
    }

    private func promptForMapping(_ mapping: NJMapping, atIndex idx: Int) {
        let mergeInto = ic.mapping(forKey: mapping.name)
        let conflictAlert = NSAlert()
        conflictAlert.messageText = NSLocalizedString("import conflict prompt", comment: "Title of import conflict alert")
        conflictAlert.informativeText = String(format: NSLocalizedString("import conflict in %@", comment: "Explanation of import conflict"), mapping.name)
        conflictAlert.addButton(withTitle: NSLocalizedString("import and merge", comment: "button to merge imported mappings"))
        conflictAlert.addButton(withTitle: NSLocalizedString("cancel import", comment: "button to cancel import"))
        conflictAlert.addButton(withTitle: NSLocalizedString("import new mapping", comment: "button to import as new mapping"))

        conflictAlert.beginSheetModal(for: window) { [weak self] code in
            guard let self else { return }
            if code == .alertFirstButtonReturn, let mergeInto {
                self.ic.mergeMapping(mapping, into: mergeInto)
                self.ic.activateMapping(mergeInto)
            } else if code == .alertThirdButtonReturn {
                self.mvc.beginUpdates()
                self.ic.addMapping(mapping)
                self.mvc.addedMapping(at: idx, startEditing: true)
                self.mvc.endUpdates()
                self.ic.activateMapping(mapping)
            }
        }
    }

    func numberOfMappings(_ dvc: NJMappingsViewController) -> Int { ic.mappings.count }
    func mappingsViewController(_ dvc: NJMappingsViewController, mappingForIndex idx: UInt) -> NJMapping { ic.mappings[Int(idx)] }
    func mappingsViewController(_ mvc: NJMappingsViewController, renameMappingAtIndex index: Int, toName name: String) { ic.renameMapping(ic.mappings[index], to: name) }
    func mappingsViewController(_ mvc: NJMappingsViewController, canMoveMappingFromIndex fromIdx: Int, toIndex toIdx: Int) -> Bool {
        fromIdx != toIdx && fromIdx != 0 && toIdx != 0 && toIdx < ic.mappings.count
    }
    func mappingsViewController(_ mvc: NJMappingsViewController, moveMappingFromIndex fromIdx: Int, toIndex toIdx: Int) {
        mvc.beginUpdates()
        mvc.mappingList.moveRow(at: fromIdx, to: toIdx)
        ic.moveMoveMapping(fromIndex: fromIdx, toIndex: toIdx)
        mvc.endUpdates()
    }
    func mappingsViewController(_ mvc: NJMappingsViewController, canRemoveMappingAtIndex idx: Int) -> Bool { idx != 0 }
    func mappingsViewController(_ mvc: NJMappingsViewController, removeMappingAtIndex idx: Int) {
        mvc.beginUpdates(); mvc.removedMapping(at: idx); ic.removeMapping(at: idx); mvc.endUpdates()
    }

    func mappingsViewController(_ mvc: NJMappingsViewController, importMappingFrom url: URL, atIndex index: Int, error: NSErrorPointer) -> Bool {
        guard let mapping = NJMapping.mapping(withContentsOf: url, error: error) as? NJMapping else { return false }
        if ic.mapping(forKey: mapping.name)?.hasConflict(with: mapping) == true {
            promptForMapping(mapping, atIndex: index)
        } else if let existing = ic.mapping(forKey: mapping.name) {
            existing.mergeEntries(from: mapping)
        } else {
            self.mvc.beginUpdates()
            self.mvc.addedMapping(at: index, startEditing: false)
            ic.insertMapping(mapping, at: index)
            self.mvc.endUpdates()
        }
        return true
    }

    func mappingsViewController(_ mvc: NJMappingsViewController, addMapping mapping: NJMapping) {
        mvc.beginUpdates(); mvc.addedMapping(at: ic.mappings.count, startEditing: true); ic.addMapping(mapping); mvc.endUpdates(); ic.activateMapping(mapping)
    }
    func mappingsViewController(_ mvc: NJMappingsViewController, choseMappingAtIndex idx: Int) { ic.activateMapping(ic.mappings[idx]) }

    func deviceViewController(_ dvc: NJDeviceViewController, elementForUID uid: String) -> NJInputPathElement? { ic.element(forUID: uid) }

    func loadOutput(forInput input: NJInput?) {
        oc.loadOutput(input.flatMap { ic.currentMapping[$0] }, forInput: input)
    }

    func deviceViewControllerDidSelectNothing(_ dvc: NJDeviceViewController) { loadOutput(forInput: nil) }
    func deviceViewController(_ dvc: NJDeviceViewController, didSelectBranch handler: NJInputPathElement) { loadOutput(forInput: dvc.selectedHandler) }
    func deviceViewController(_ dvc: NJDeviceViewController, didSelectHandler handler: NJInputPathElement) { loadOutput(forInput: dvc.selectedHandler) }
    func deviceViewController(_ dvc: NJDeviceViewController, didSelectDevice device: NJInputPathElement) { loadOutput(forInput: dvc.selectedHandler) }

    func inputController(_ ic: NJInputController, didAddDevice device: NJDevice) { dvc.addedDevice(device, at: UInt(ic.devices.count - 1)) }
    func inputController(_ ic: NJInputController, didRemoveDeviceAtIndex idx: Int) { dvc.removedDevice(at: UInt(idx)) }
    func inputControllerDidStartHID(_ ic: NJInputController) { dvc.hidStarted() }
    func inputControllerDidStopHID(_ ic: NJInputController) { dvc.hidStopped() }
    func inputController(_ ic: NJInputController, didInput input: NJInput) { dvc.expandAndSelectItem(input); loadOutput(forInput: input); oc.focusKey() }
    func inputController(_ ic: NJInputController, didError error: NSError) { presentErrorSheet(error) }

    func numberOfDevices(in dvc: NJDeviceViewController) -> Int { ic.devices.count }
    func deviceViewController(_ dvc: NJDeviceViewController, deviceForIndex idx: UInt) -> NJDevice { ic.devices[Int(idx)] }

    @objc(simulatingEventsChanged:)
    func simulatingEventsChanged(_ sender: NSButton) { ic.simulatingEvents = sender.state == .on }

    func outputViewController(_ ovc: NJOutputViewController, setOutput output: NJOutput?, forInput input: NJInput?) {
        if let input { ic.currentMapping[input] = output; ic.save() }
    }

    func outputViewController(_ ovc: NJOutputViewController, mappingForIndex index: UInt) -> NJMapping { ic.mappings[Int(index)] }
}
