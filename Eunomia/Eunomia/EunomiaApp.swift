//
//  EunomiaApp.swift
//  Eunomia
//
//  Created by linhey on 3/20/26.
//

import SwiftUI
import EunomiaKit

@main
struct EunomiaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            EunomiaSettingsView()
        }
    }
}
