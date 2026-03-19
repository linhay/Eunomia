import Foundation

extension NSCharacterSet {
    @objc(invalidPathComponentCharacterSet)
    class func invalidPathComponentCharacterSetCompat() -> NSCharacterSet {
        NSCharacterSet(charactersIn: "\"\\/:*?<>|")
    }
}

extension NSString {
    @objc(stringByFixingPathComponent)
    func stringByFixingPathComponentCompat() -> String {
        let invalid = NSCharacterSet.invalidPathComponentCharacterSetCompat() as CharacterSet
        let whitespace = CharacterSet.whitespacesAndNewlines

        let parts = (self as String).components(separatedBy: invalid)
        var name = parts.joined(separator: "_").trimmingCharacters(in: whitespace)

        if name.isEmpty {
            return "_"
        }

        if let first = name.first, first == "." || first == "-" {
            name = "_" + name
        }
        return name
    }
}
