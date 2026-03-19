import Foundation

@objc(NJMapping)
class NJMapping: NSObject {
    @objc var name: String
    private var entries: [String: NJOutput] = [:]

    @objc override init() {
        name = NSLocalizedString("Untitled", comment: "name for new mappings")
        super.init()
    }

    @objc(initWithName:)
    init(name: String?) {
        self.name = name ?? NSLocalizedString("Untitled", comment: "name for new mappings")
        super.init()
    }

    @objc(initWithSerialization:)
    init(serialization: [String: Any]) {
        name = (serialization["name"] as? String) ?? NSLocalizedString("Untitled", comment: "name for new mappings")
        super.init()
        if let serializedEntries = serialization["entries"] as? [String: Any] {
            for (key, value) in serializedEntries {
                if let output = NJOutput.output(withSerialization: value as? [String: Any]) {
                    entries[key] = output
                }
            }
        }
    }

    @objc(mappingWithContentsOfURL:error:)
    class func mapping(withContentsOf url: URL, error: NSErrorPointer) -> Any? {
        do {
            let data = try Data(contentsOf: url)
            let obj = try JSONSerialization.jsonObject(with: data)
            guard let serialization = obj as? [String: Any],
                  serialization["name"] is String,
                  serialization["entries"] is [String: Any] else {
                error?.pointee = NSError.error(withDomain: "Enjoyable", code: 0, description: NSLocalizedString("invalid mapping file", comment: "error when imported file was JSON but not a mapping"))
                return nil
            }
            return NJMapping(serialization: serialization)
        } catch let e as NSError {
            error?.pointee = e
            return nil
        }
    }

    @objc var count: UInt {
        UInt(entries.count)
    }

    subscript(input: NJInput?) -> NJOutput? {
        get {
            guard let input else { return nil }
            return entries[input.uid]
        }
        set {
            guard let input else { return }
            if let newValue {
                entries[input.uid] = newValue
            } else {
                entries.removeValue(forKey: input.uid)
            }
        }
    }

    @objc(objectForKeyedSubscript:)
    func object(forKeyedSubscript input: NJInput?) -> NJOutput? {
        self[input]
    }

    @objc(setObject:forKeyedSubscript:)
    func setObject(_ output: NJOutput?, forKeyedSubscript input: NJInput?) {
        self[input] = output
    }

    @objc func serialize() -> [String: Any] {
        var serializedEntries: [String: Any] = [:]
        for (key, value) in entries {
            if let serialized = value.serialize() {
                serializedEntries[key] = serialized
            }
        }
        return ["name": name, "entries": serializedEntries]
    }

    @objc(writeToURL:error:)
    func write(to url: URL, error: NSErrorPointer) -> Bool {
        ProcessInfo.processInfo.disableSuddenTermination()
        defer { ProcessInfo.processInfo.enableSuddenTermination() }
        do {
            let json = try JSONSerialization.data(withJSONObject: serialize(), options: [.prettyPrinted])
            try json.write(to: url, options: [.atomic])
            return true
        } catch let e as NSError {
            error?.pointee = e
            return false
        }
    }

    @objc(hasConflictWith:)
    func hasConflict(with other: NJMapping) -> Bool {
        if other.count < count {
            return other.hasConflict(with: self)
        }
        for (uid, entry) in entries {
            if let otherEntry = other.entries[uid], !otherEntry.isEqual(entry) {
                return true
            }
        }
        return false
    }

    @objc(mergeEntriesFrom:)
    func mergeEntries(from other: NJMapping?) {
        guard let other else { return }
        entries.merge(other.entries) { _, new in new }
    }

    @objc(postLoadProcess:)
    func postLoadProcess(_ allMappings: NSFastEnumeration) {
        for output in entries.values {
            output.postLoadProcess(allMappings)
        }
    }
}
