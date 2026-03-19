import AppKit

private let pbRow = "com.yukkurigames.Enjoyable.MappingRow"

@objc protocol NJMappingsViewControllerDelegate {
    @objc(numberOfMappings:) func numberOfMappings(_ dvc: NJMappingsViewController) -> Int
    @objc(mappingsViewController:mappingForIndex:) func mappingsViewController(_ dvc: NJMappingsViewController, mappingForIndex idx: UInt) -> NJMapping

    @objc(mappingsViewController:renameMappingAtIndex:toName:) func mappingsViewController(_ mvc: NJMappingsViewController, renameMappingAtIndex index: Int, toName name: String)

    @objc(mappingsViewController:canMoveMappingFromIndex:toIndex:) func mappingsViewController(_ mvc: NJMappingsViewController, canMoveMappingFromIndex fromIdx: Int, toIndex toIdx: Int) -> Bool
    @objc(mappingsViewController:moveMappingFromIndex:toIndex:) func mappingsViewController(_ mvc: NJMappingsViewController, moveMappingFromIndex fromIdx: Int, toIndex toIdx: Int)

    @objc(mappingsViewController:canRemoveMappingAtIndex:) func mappingsViewController(_ mvc: NJMappingsViewController, canRemoveMappingAtIndex idx: Int) -> Bool
    @objc(mappingsViewController:removeMappingAtIndex:) func mappingsViewController(_ mvc: NJMappingsViewController, removeMappingAtIndex idx: Int)

    @objc(mappingsViewController:importMappingFromURL:atIndex:error:) func mappingsViewController(_ mvc: NJMappingsViewController, importMappingFrom url: URL, atIndex index: Int, error: NSErrorPointer) -> Bool
    @objc(mappingsViewController:addMapping:) func mappingsViewController(_ mvc: NJMappingsViewController, addMapping mapping: NJMapping)

    @objc(mappingsViewController:choseMappingAtIndex:) func mappingsViewController(_ mvc: NJMappingsViewController, choseMappingAtIndex idx: Int)
}

@objc(NJMappingsViewController)
class NJMappingsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSOpenSavePanelDelegate, NSPopoverDelegate {
    @objc weak var delegate: NJMappingsViewControllerDelegate?

    @objc var removeMapping: NSButton!
    @objc var mappingList: NSTableView!
    @objc var mappingListTrigger: NSButton!
    @objc var mappingListPopover: NSPopover!
    @objc var moveUp: NSButton!
    @objc var moveDown: NSButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        mappingList.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: pbRow), .URL])
        mappingList.setDraggingSourceOperationMask(.copy, forLocal: false)
    }

    @objc(addClicked:)
    func addClicked(_ sender: Any?) {
        delegate?.mappingsViewController(self, addMapping: NJMapping())
    }

    @objc(removeClicked:)
    func removeClicked(_ sender: Any?) {
        delegate?.mappingsViewController(self, removeMappingAtIndex: mappingList.selectedRow)
    }

    @objc(moveUpClicked:)
    func moveUpClicked(_ sender: Any?) {
        let fromIdx = mappingList.selectedRow
        let toIdx = fromIdx - 1
        delegate?.mappingsViewController(self, moveMappingFromIndex: fromIdx, toIndex: toIdx)
        mappingList.scrollRowToVisible(toIdx)
        mappingList.selectRowIndexes(IndexSet(integer: toIdx), byExtendingSelection: false)
    }

    @objc(moveDownClicked:)
    func moveDownClicked(_ sender: Any?) {
        let fromIdx = mappingList.selectedRow
        let toIdx = fromIdx + 1
        delegate?.mappingsViewController(self, moveMappingFromIndex: fromIdx, toIndex: toIdx)
        mappingList.scrollRowToVisible(toIdx)
        mappingList.selectRowIndexes(IndexSet(integer: toIdx), byExtendingSelection: false)
    }

    @objc(mappingTriggerClicked:)
    func mappingTriggerClicked(_ sender: Any?) {
        mappingListPopover.show(relativeTo: mappingListTrigger.bounds, of: mappingListTrigger, preferredEdge: .minX)
        mappingListTrigger.state = .on
    }

    func popoverWillShow(_ notification: Notification) {
        mappingListTrigger.state = .on
    }

    func popoverWillClose(_ notification: Notification) {
        mappingListTrigger.state = .off
    }

    @objc func beginUpdates() {
        mappingList.beginUpdates()
    }

    @objc func endUpdates() {
        mappingList.endUpdates()
        changedActiveMapping(toIndex: mappingList.selectedRow)
    }

    @objc(addedMappingAtIndex:startEditing:)
    func addedMapping(at index: Int, startEditing: Bool) {
        mappingList.abortEditing()
        mappingList.insertRows(at: IndexSet(integer: index), withAnimation: startEditing ? [] : .slideLeft)
        if startEditing {
            mappingListTrigger.performClick(self)
            mappingList.editColumn(0, row: index, with: nil, select: true)
            mappingList.scrollRowToVisible(index)
        }
    }

    @objc(removedMappingAtIndex:)
    func removedMapping(at index: Int) {
        mappingList.abortEditing()
        mappingList.removeRows(at: IndexSet(integer: index), withAnimation: .effectFade)
    }

    @objc(changedActiveMappingToIndex:)
    func changedActiveMapping(toIndex index: Int) {
        guard index >= 0,
              let mapping = delegate?.mappingsViewController(self, mappingForIndex: UInt(index)) else { return }

        removeMapping.isEnabled = delegate?.mappingsViewController(self, canRemoveMappingAtIndex: index) ?? false
        moveUp.isEnabled = delegate?.mappingsViewController(self, canMoveMappingFromIndex: index, toIndex: index - 1) ?? false
        moveDown.isEnabled = delegate?.mappingsViewController(self, canMoveMappingFromIndex: index, toIndex: index + 1) ?? false
        mappingListTrigger.title = mapping.name
        mappingList.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        mappingList.scrollRowToVisible(index)
        UserDefaults.standard.set(index, forKey: "selected")
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        mappingList.abortEditing()
        delegate?.mappingsViewController(self, choseMappingAtIndex: (notification.object as! NSTableView).selectedRow)
    }

    func tableView(_ view: NSTableView, objectValueFor tableColumn: NSTableColumn?, row index: Int) -> Any? {
        delegate?.mappingsViewController(self, mappingForIndex: UInt(index)).name
    }

    func tableView(_ view: NSTableView, setObjectValue obj: Any?, for tableColumn: NSTableColumn?, row index: Int) {
        delegate?.mappingsViewController(self, renameMappingAtIndex: index, toName: obj as? String ?? "")
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        delegate?.numberOfMappings(self) ?? 0
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: any NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let pboard = info.draggingPasteboard
        let types = pboard.types ?? []

        if types.contains(NSPasteboard.PasteboardType(rawValue: pbRow)) {
            let value = pboard.string(forType: NSPasteboard.PasteboardType(rawValue: pbRow)) ?? "0"
            let srcRow = Int(value) ?? 0
            let adjustedRow = row - (srcRow < row ? 1 : 0)
            delegate?.mappingsViewController(self, moveMappingFromIndex: srcRow, toIndex: adjustedRow)
            return true
        } else if types.contains(.URL),
                  let str = pboard.string(forType: .URL),
                  let url = URL(string: str) {
            var error: NSError?
            if !(delegate?.mappingsViewController(self, importMappingFrom: url, atIndex: row, error: &error) ?? false) {
                if let error { tableView.presentError(error) }
                return false
            }
            return true
        }

        return false
    }

    func tableView(_ tableView: NSTableView, validateDrop info: any NSDraggingInfo, proposedRow row: Int, proposedDropOperation: NSTableView.DropOperation) -> NSDragOperation {
        let pboard = info.draggingPasteboard
        let types = pboard.types ?? []

        if types.contains(NSPasteboard.PasteboardType(rawValue: pbRow)) {
            tableView.setDropRow(max(1, row), dropOperation: .above)
            return .move
        } else if types.contains(.URL),
                  let str = pboard.string(forType: .URL),
                  let url = URL(string: str),
                  url.pathExtension == "enjoyable" {
            tableView.setDropRow(max(1, row), dropOperation: .above)
            return .copy
        }

        return []
    }

    func tableView(_ tableView: NSTableView, namesOfPromisedFilesDroppedAtDestination dropDestination: URL, forDraggedRowsWith rowIndexes: IndexSet) -> [String] {
        guard let firstIndex = rowIndexes.first,
              let toSave = delegate?.mappingsViewController(self, mappingForIndex: UInt(firstIndex)) else {
            return []
        }

        let filename = (toSave.name.stringByFixingPathComponentCompat() as NSString).appendingPathExtension("enjoyable") ?? "mapping.enjoyable"
        var dst = dropDestination.appendingPathComponent(filename)
        dst = FileManager.default.generateUniqueURL(withBase: dst)

        var error: NSError?
        if !toSave.write(to: dst, error: &error) {
            if let error { tableView.presentError(error) }
            return []
        }

        return [dst.lastPathComponent]
    }

    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        if rowIndexes.count == 1, let first = rowIndexes.first, first != 0 {
            pboard.declareTypes([NSPasteboard.PasteboardType(rawValue: pbRow), .filePromise], owner: nil)
            pboard.setString(String(first), forType: NSPasteboard.PasteboardType(rawValue: pbRow))
            pboard.setPropertyList(["enjoyable"], forType: .filePromise)
            return true
        } else if rowIndexes.count == 1, rowIndexes.first == 0 {
            pboard.declareTypes([.filePromise], owner: nil)
            pboard.setPropertyList(["enjoyable"], forType: .filePromise)
            return true
        }
        return false
    }

    @objc func reloadData() {
        mappingList.reloadData()
    }
}
