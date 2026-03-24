import AppKit

extension NSOutlineView {
    func selectItemCompat(_ item: Any?) {
        let row = row(forItem: item)
        if row >= 0 {
            selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        } else {
            deselectAll(nil)
        }
    }
    func selectedItemCompat() -> Any? {
        selectedRow >= 0 ? item(atRow: selectedRow) : nil
    }
}
