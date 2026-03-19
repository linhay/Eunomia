import Foundation

class NJInputPathElement: NSObject {
    weak var parent: NJInputPathElement?
    var name: String
    var children: [NJInputPathElement]?

    private let eid: String?

    init(name: String, eid: String?, parent: NJInputPathElement?) {
        self.name = name
        self.eid = eid
        self.parent = parent
        super.init()
    }

    var uid: String {
        "\(parent?.uid ?? "")~\(eid ?? "")"
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NJInputPathElement else { return false }
        return other.uid == uid
    }

    override var hash: Int {
        uid.hashValue
    }

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
