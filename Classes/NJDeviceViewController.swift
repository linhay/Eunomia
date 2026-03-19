import AppKit

@objc protocol NJDeviceViewControllerDelegate {
    @objc(numberOfDevicesInDeviceList:) func numberOfDevices(in dvc: NJDeviceViewController) -> Int
    @objc(deviceViewController:deviceForIndex:) func deviceViewController(_ dvc: NJDeviceViewController, deviceForIndex idx: UInt) -> NJDevice
    @objc(deviceViewController:elementForUID:) func deviceViewController(_ dvc: NJDeviceViewController, elementForUID uid: String) -> NJInputPathElement?

    @objc(deviceViewController:didSelectDevice:) func deviceViewController(_ dvc: NJDeviceViewController, didSelectDevice device: NJInputPathElement)
    @objc(deviceViewController:didSelectBranch:) func deviceViewController(_ dvc: NJDeviceViewController, didSelectBranch handler: NJInputPathElement)
    @objc(deviceViewController:didSelectHandler:) func deviceViewController(_ dvc: NJDeviceViewController, didSelectHandler handler: NJInputPathElement)
    @objc(deviceViewControllerDidSelectNothing:) func deviceViewControllerDidSelectNothing(_ dvc: NJDeviceViewController)
}

@objc(NJDeviceViewController)
class NJDeviceViewController: NSObject, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @objc var inputsTree: NSOutlineView!
    @objc var noDevicesNotice: NSView!
    @objc var hidStoppedNotice: NSView!

    @objc weak var delegate: NJDeviceViewControllerDelegate?

    private var expanded: [String] = []

    override init() {
        super.init()
        let saved = UserDefaults.standard.object(forKey: "expanded rows") as? [String] ?? []
        expanded.append(contentsOf: saved)
    }

    private func expandRecursive(_ pathElement: NJInputPathElement?) {
        if let pathElement {
            expandRecursive(pathElement.parent)
            inputsTree.expandItem(pathElement)
        }
    }

    private func expandRecursive(uid: String) {
        expandRecursive(delegate?.deviceViewController(self, elementForUID: uid))
    }

    private func reexpandAll() {
        for uid in expanded { expandRecursive(uid: uid) }
        if inputsTree.selectedRow == -1 {
            let selectedUid = UserDefaults.standard.string(forKey: "selected input")
            let item = selectedUid.flatMap { delegate?.deviceViewController(self, elementForUID: $0) }
            inputsTree.selectItemCompat(item)
        }
    }

    @objc(addedDevice:atIndex:)
    func addedDevice(_ device: NJDevice, at idx: UInt) {
        inputsTree.beginUpdates()
        inputsTree.insertItems(at: IndexSet(integer: Int(idx)), inParent: nil, withAnimation: .effectFade)
        reexpandAll()
        inputsTree.endUpdates()
        noDevicesNotice.isHidden = true
    }

    @objc(removedDeviceAtIndex:)
    func removedDevice(at idx: UInt) {
        let anyDevices = (delegate?.numberOfDevices(in: self) ?? 0) > 0
        inputsTree.beginUpdates()
        inputsTree.removeItems(at: IndexSet(integer: Int(idx)), inParent: nil, withAnimation: .effectFade)
        inputsTree.endUpdates()
        noDevicesNotice.isHidden = anyDevices || !hidStoppedNotice.isHidden
    }

    @objc func hidStarted() {
        noDevicesNotice.isHidden = (delegate?.numberOfDevices(in: self) ?? 0) > 0
        hidStoppedNotice.isHidden = true
    }

    @objc func hidStopped() {
        noDevicesNotice.isHidden = true
        hidStoppedNotice.isHidden = false
        inputsTree.reloadData()
    }

    @objc(expandAndSelectItem:)
    func expandAndSelectItem(_ item: NJInputPathElement) {
        expandRecursive(item)
        let row = inputsTree.row(forItem: item)
        if row >= 0 {
            inputsTree.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            inputsTree.scrollRowToVisible(row)
        }
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item as? NJInputPathElement {
            return item.children?.count ?? 0
        }
        return delegate?.numberOfDevices(in: self) ?? 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? NJInputPathElement else { return true }
        return (item.children?.count ?? 0) > 0
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? NJInputPathElement {
            return item.children?[index] as Any
        }
        return delegate!.deviceViewController(self, deviceForIndex: UInt(index))
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        (item as? NJInputPathElement)?.name ?? "root"
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        let outlineView = notification.object as! NSOutlineView
        let item = outlineView.selectedItemCompat() as? NJInputPathElement

        if let item {
            UserDefaults.standard.set(item.uid, forKey: "selected input")
            if item.children == nil {
                delegate?.deviceViewController(self, didSelectHandler: item)
            } else if item.parent == nil {
                delegate?.deviceViewController(self, didSelectDevice: item)
            } else {
                delegate?.deviceViewController(self, didSelectBranch: item)
            }
        } else {
            delegate?.deviceViewControllerDidSelectNothing(self)
        }
    }

    func outlineViewItemDidExpand(_ notification: Notification) {
        guard let uid = (notification.userInfo?["NSObject"] as? NJInputPathElement)?.uid else { return }
        if !expanded.contains(uid) {
            expanded.append(uid)
            UserDefaults.standard.set(expanded, forKey: "expanded rows")
        }
    }

    func outlineViewItemDidCollapse(_ notification: Notification) {
        guard let uid = (notification.userInfo?["NSObject"] as? NJInputPathElement)?.uid else { return }
        expanded.removeAll { $0 == uid }
        UserDefaults.standard.set(expanded, forKey: "expanded rows")
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        (item as? NJInputPathElement)?.parent == nil
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        !self.outlineView(outlineView, isGroupItem: item)
    }

    @objc var selectedHandler: NJInput? {
        let element = inputsTree.selectedItemCompat() as? NJInputPathElement
        return element?.children == nil ? (element as? NJInput) : nil
    }
}
