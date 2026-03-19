import AppKit

extension NSOutlineView {
    @objc(selectItem:)
    func selectItemCompat(_ item: Any?) {
        let row = row(forItem: item)
        if row >= 0 {
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        } else {
            deselectAll(nil)
        }
    }

    @objc(selectedItem)
    func selectedItemCompat() -> Any? {
        selectedRow >= 0 ? item(atRow: selectedRow) : nil
    }
}
