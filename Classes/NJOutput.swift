import Foundation

@objc(NJOutput)
class NJOutput: NSObject {
    @objc var magnitude: Float = 0
    private var _running = false

    required override init() {
        super.init()
    }

    @objc class func serializationCode() -> String {
        self.init().doesNotRecognizeSelector(#selector(serializationCode))
        return ""
    }

    @objc func serialize() -> [String: Any]? {
        doesNotRecognizeSelector(#selector(serialize))
        return nil
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NJOutput else { return false }
        return serialize() as NSDictionary? == other.serialize() as NSDictionary?
    }

    override var hash: Int {
        (serialize() as NSDictionary?)?.hash ?? 0
    }

    @objc(outputWithSerialization:)
    class func output(withSerialization serialization: [String: Any]?) -> NJOutput? {
        guard let serialization, let type = serialization["type"] as? String else { return nil }
        for cls in [NJOutputKeyPress.self, NJOutputMapping.self, NJOutputMouseMove.self, NJOutputMouseButton.self, NJOutputMouseScroll.self] {
            if type == cls.serializationCode() {
                return cls.output(withSerialization: serialization)
            }
        }
        return nil
    }

    @objc func trigger() {}
    @objc func untrigger() {}

    @objc(update:)
    func update(_ ic: NJInputController) -> Bool {
        false
    }

    @objc var isContinuous: Bool { false }

    @objc var running: Bool {
        get { _running }
        set {
            if _running != newValue {
                _running = newValue
                if _running { trigger() } else { untrigger() }
            }
        }
    }

    @objc(postLoadProcess:)
    func postLoadProcess(_ allMappings: NSFastEnumeration) {}
}
