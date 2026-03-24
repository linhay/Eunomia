import Foundation

class NJOutput: NSObject {
    var magnitude: Float = 0
    private var _running = false

    required override init() {
        super.init()
    }

    class func serializationCode() -> String {
        fatalError("Subclasses must override serializationCode()")
    }

    func serialize() -> [String: Any]? {
        fatalError("Subclasses must override serialize()")
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NJOutput else { return false }
        return serialize() as NSDictionary? == other.serialize() as NSDictionary?
    }

    override var hash: Int {
        (serialize() as NSDictionary?)?.hash ?? 0
    }

    class func output(withSerialization serialization: [String: Any]?) -> NJOutput? {
        guard let serialization, let type = serialization["type"] as? String else { return nil }
        for cls in [NJOutputKeyPress.self, NJOutputMapping.self, NJOutputMouseMove.self, NJOutputMouseButton.self, NJOutputMouseScroll.self] {
            if type == cls.serializationCode() {
                return cls.output(withSerialization: serialization)
            }
        }
        return nil
    }

    func trigger() {}
    func untrigger() {}

    func update(_ ic: NJInputController) -> Bool {
        false
    }

    var isContinuous: Bool { false }

    var running: Bool {
        get { _running }
        set {
            if _running != newValue {
                _running = newValue
                if _running { trigger() } else { untrigger() }
            }
        }
    }

    func postLoadProcess(_ allMappings: NSFastEnumeration) {}
}
