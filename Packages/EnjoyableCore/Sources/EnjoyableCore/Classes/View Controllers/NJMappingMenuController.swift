import AppKit

private let maximumMappingsInMenu = 15

@objc protocol NJMappingMenuDelegate {
    @objc(mappingWasChosen:) func mappingWasChosen(_ mapping: NJMapping)
    @objc(mappingListShouldOpen) func mappingListShouldOpen()
}

@objc(NJMappingMenuController)
class NJMappingMenuController: NSObject {
    @objc var menu: NSMenu!
    @objc weak var delegate: NJMappingMenuDelegate?
    @objc var firstMappingIndex: Int = 0
    @objc var hasKeyEquivalents: Bool = false
    @objc var eventSimulationToggle: NSMenuItem?

    override init() {
        super.init()
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(mappingsListDidChange(_:)), name: Notification.Name(NJEventMappingListChanged), object: nil)
        center.addObserver(self, selector: #selector(mappingDidChange(_:)), name: Notification.Name(NJEventMappingChanged), object: nil)
        center.addObserver(self, selector: #selector(eventSimulationStarted(_:)), name: Notification.Name(NJEventSimulationStarted), object: nil)
        center.addObserver(self, selector: #selector(eventSimulationStopped(_:)), name: Notification.Name(NJEventSimulationStopped), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc(_mappingWasChosen:)
    func _mappingWasChosen(_ sender: NSMenuItem) {
        guard let mapping = sender.representedObject as? NJMapping else { return }
        delegate?.mappingWasChosen(mapping)
    }

    @objc(_mappingListWasChosen:)
    func _mappingListWasChosen(_ sender: NSMenuItem) {
        delegate?.mappingListShouldOpen()
    }

    @objc(mappingsListDidChange:)
    func mappingsListDidChange(_ note: Notification) {
        let mappings = note.userInfo?[NJMappingListKey] as? [NJMapping] ?? []
        let currentMapping = note.userInfo?[NJMappingKey] as? NJMapping

        while menu.numberOfItems > firstMappingIndex,
              let toRemove = menu.item(at: firstMappingIndex),
              toRemove.representedObject is NJMapping || (toRemove.representedObject as AnyObject?) === NJMappingMenuController.self {
            menu.removeItem(at: firstMappingIndex)
        }

        var added = 0
        var index = firstMappingIndex
        for mapping in mappings {
            added += 1
            let keyEquiv = (added < 10 && hasKeyEquivalents) ? String(added) : ""
            let item = NSMenuItem(title: mapping.name, action: #selector(_mappingWasChosen(_:)), keyEquivalent: keyEquiv)
            item.representedObject = mapping
            item.state = mapping === currentMapping ? .on : .off
            item.target = self
            menu.insertItem(item, at: index)
            index += 1

            if added == maximumMappingsInMenu && mappings.count > maximumMappingsInMenu + 1 {
                let msg = String(format: NSLocalizedString("mapping overflow %lu", comment: "menu item when mappings list overflows"), mappings.count - maximumMappingsInMenu)
                let end = NSMenuItem(title: msg, action: #selector(_mappingListWasChosen(_:)), keyEquivalent: "")
                end.representedObject = NJMappingMenuController.self
                end.target = self
                menu.insertItem(end, at: index)
                break
            }
        }
    }

    @objc(mappingDidChange:)
    func mappingDidChange(_ note: Notification) {
        let mapping = note.userInfo?[NJMappingKey] as? NJMapping
        for item in menu.items where item.representedObject is NJMapping {
            item.state = (item.representedObject as? NJMapping) === mapping ? .on : .off
        }
    }

    @objc(eventSimulationStarted:)
    func eventSimulationStarted(_ note: Notification) {
        eventSimulationToggle?.title = NSLocalizedString("Disable", comment: "menu item text to disable event simulation")
    }

    @objc(eventSimulationStopped:)
    func eventSimulationStopped(_ note: Notification) {
        eventSimulationToggle?.title = NSLocalizedString("Enable", comment: "menu item text to enable event simulation")
    }
}
