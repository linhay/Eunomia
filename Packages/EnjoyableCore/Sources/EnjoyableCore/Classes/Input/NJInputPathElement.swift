import Foundation

@objc(NJInputPathElement)
class NJInputPathElement: NSObject {
    @objc weak var parent: NJInputPathElement?
    @objc var name: String
    @objc var children: [NJInputPathElement]?

    private let eid: String?

    @objc(initWithName:eid:parent:)
    init(name: String, eid: String?, parent: NJInputPathElement?) {
        self.name = name
        self.eid = eid
        self.parent = parent
        super.init()
    }

    @objc var uid: String {
        "\(parent?.uid ?? "")~\(eid ?? "")"
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NJInputPathElement else { return false }
        return other.uid == uid
    }

    override var hash: Int {
        uid.hashValue
    }

    @objc(elementForUID:)
    func element(forUID wantedUID: String) -> NJInputPathElement? {
        if wantedUID == uid { return self }
        if !wantedUID.hasPrefix(uid) { return nil }
        for child in children ?? [] {
            if let found = child.element(forUID: wantedUID) {
                return found
            }
        }
        return nil
    }
}
