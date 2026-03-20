
import AppKit
import EnjoyableKit
import SwiftUI

final class EnjoyableSPMAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = EnjoyableRootView()
        let hosting = NSHostingView(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Enjoyable"
        window.center()
        window.contentView = hosting
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// Global reference to keep delegate alive
var appDelegate: EnjoyableSPMAppDelegate!

func main() {
    let app = NSApplication.shared
    appDelegate = EnjoyableSPMAppDelegate()
    app.delegate = appDelegate
    app.setActivationPolicy(.regular)
    app.run()
}

main()
