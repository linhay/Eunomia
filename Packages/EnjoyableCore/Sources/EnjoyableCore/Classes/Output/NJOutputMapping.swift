import AppKit

protocol NJOutputMappingActivationDelegate: AnyObject {
    func outputMapping(_ output: NJOutputMapping, activate mapping: NJMapping)
}

private enum NJOutputMappingActivationHub {
    static weak var delegate: NJOutputMappingActivationDelegate?
}

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
        if let mapping {
            if let delegate = NJOutputMappingActivationHub.delegate {
                delegate.outputMapping(self, activate: mapping)
            } else if let ctrl = NSApplication.shared.delegate as? EnjoyableApplicationDelegate {
                ctrl.ic.activateMapping(mapping)
            }
            mappingName = mapping.name
        }
    }

    class func setActivationDelegate(_ delegate: NJOutputMappingActivationDelegate?) {
        NJOutputMappingActivationHub.delegate = delegate
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
