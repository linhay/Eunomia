import AppKit

extension NSMenu {
    func item(withRepresentedObject object: Any?) -> NSMenuItem? {
        items.first { ($0.representedObject as AnyObject?)?.isEqual(object) == true }
    }
    func item(withIdenticalRepresentedObject object: Any?) -> NSMenuItem? {
        items.first { $0.representedObject as AnyObject? === object as AnyObject? }
    }
    func lastItemCompat() -> NSMenuItem? {
        items.last
    }
    func removeLastItemCompat() {
        guard numberOfItems > 0 else { return }
        removeItem(at: numberOfItems - 1)
    }
}

extension NSPopUpButton {
    func item(withRepresentedObject object: Any?) -> NSMenuItem? {
        menu?.item(withRepresentedObject: object)
    }
    func item(withIdenticalRepresentedObject object: Any?) -> NSMenuItem? {
        menu?.item(withIdenticalRepresentedObject: object)
    }
    func selectItem(withRepresentedObject object: Any?) {
        selectItem(at: indexOfItem(withRepresentedObject: object))
    }
    func selectItem(withIdenticalRepresentedObject object: Any?) {
        select(menu?.item(withIdenticalRepresentedObject: object))
    }
}
