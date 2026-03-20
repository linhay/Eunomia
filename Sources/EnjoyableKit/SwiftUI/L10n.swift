import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: key, table: "Localizable")
    }
}
