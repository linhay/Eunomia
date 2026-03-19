import AppKit

extension NSMenu {
    @objc(itemWithRepresentedObject:)
    func item(withRepresentedObject object: Any?) -> NSMenuItem? {
        items.first { ($0.representedObject as AnyObject?)?.isEqual(object) == true }
    }

    @objc(itemWithIdenticalRepresentedObject:)
    func item(withIdenticalRepresentedObject object: Any?) -> NSMenuItem? {
        items.first { $0.representedObject as AnyObject? === object as AnyObject? }
    }

    @objc(lastItem)
    func lastItemCompat() -> NSMenuItem? {
        items.last
    }

    @objc(removeLastItem)
    func removeLastItemCompat() {
        guard numberOfItems > 0 else { return }
        removeItem(at: numberOfItems - 1)
    }
}

extension NSPopUpButton {
    @objc(itemWithRepresentedObject:)
    func item(withRepresentedObject object: Any?) -> NSMenuItem? {
        menu?.item(withRepresentedObject: object)
    }

    @objc(itemWithIdenticalRepresentedObject:)
    func item(withIdenticalRepresentedObject object: Any?) -> NSMenuItem? {
        menu?.item(withIdenticalRepresentedObject: object)
    }

    @objc(selectItemWithRepresentedObject:)
    func selectItem(withRepresentedObject object: Any?) {
        selectItem(at: indexOfItem(withRepresentedObject: object))
    }

    @objc(selectItemWithIdenticalRepresentedObject:)
    func selectItem(withIdenticalRepresentedObject object: Any?) {
        select(menu?.item(withIdenticalRepresentedObject: object))
    }
}
