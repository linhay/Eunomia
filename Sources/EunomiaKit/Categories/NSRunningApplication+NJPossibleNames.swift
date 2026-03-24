import AppKit

extension NSRunningApplication {
    func windowTitlesCompat() -> [String] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        var titles: [String] = []
        for props in windows {
            if let pid = props[kCGWindowOwnerPID as String] as? NSNumber,
               pid.intValue == processIdentifier,
               let title = props[kCGWindowName as String] as? String {
                titles.append(title)
            }
        }
        return titles
    }
    func frontWindowTitleCompat() -> String? {
        windowTitlesCompat().first
    }
    func possibleMappingNamesCompat() -> [String] {
        var names: [String] = []
        if let bundleIdentifier { names.append(bundleIdentifier) }
        if let localizedName { names.append(localizedName) }
        if let bundleURL { names.append(bundleURL.deletingPathExtension().lastPathComponent) }
        if let executableURL { names.append(executableURL.lastPathComponent) }
        if let frontWindowTitle = frontWindowTitleCompat() { names.append(frontWindowTitle) }
        return names
    }
    func bestMappingNameCompat() -> String {
        let genericBundles = ["com.macromedia.Flash Player Debugger.app", "com.macromedia.Flash Player.app"]
        let genericExecutables = ["wine.bin"]
        let probablyWrong = genericBundles.contains(bundleIdentifier ?? "") || genericExecutables.contains(localizedName ?? "")

        if !probablyWrong, let localizedName { return localizedName }
        if !probablyWrong, let bundleIdentifier { return bundleIdentifier }
        if let bundleURL { return bundleURL.deletingPathExtension().lastPathComponent }
        if let frontWindowTitle = frontWindowTitleCompat() { return frontWindowTitle }
        if let executableURL { return executableURL.lastPathComponent }
        if let localizedName { return localizedName }
        if let bundleIdentifier { return bundleIdentifier }

        return NSLocalizedString("@Application", comment: "Magic string to trigger automatic mapping renames. It should look like an identifier rather than normal word, with the @ on the front.")
    }
}
