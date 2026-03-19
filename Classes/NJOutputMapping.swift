import AppKit

@objc(NJOutputMapping)
class NJOutputMapping: NJOutput {
    @objc weak var mapping: NJMapping?
    @objc var mappingName: String?

    override class func serializationCode() -> String {
        "mapping"
    }

    override func serialize() -> [String: Any]? {
        let name = mapping?.name ?? mappingName
        guard let name else { return nil }
        return ["type": Self.serializationCode(), "name": name]
    }

    override class func output(withSerialization serialization: [String : Any]?) -> NJOutput? {
        guard let name = serialization?["name"] as? String else { return nil }
        let output = NJOutputMapping()
        output.mappingName = name
        return output
    }

    override func trigger() {
        guard let ctrl = NSApplication.shared.delegate as? EnjoyableApplicationDelegate else { return }
        if let mapping {
            ctrl.ic.activateMapping(mapping)
            mappingName = mapping.name
        }
    }

    override func postLoadProcess(_ allMappings: NSFastEnumeration) {
        guard mapping == nil, let mappingName else { return }
        for case let m as NJMapping in allMappings as? [Any] ?? [] {
            if m.name == mappingName {
                mapping = m
                break
            }
        }
    }
}
