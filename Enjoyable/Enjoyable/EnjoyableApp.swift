//
//  EnjoyableApp.swift
//  Enjoyable
//
//  Created by linhey on 3/20/26.
//

import SwiftUI
import EnjoyableKit

@main
struct EnjoyableApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            EnjoyableSettingsView()
        }
    }
}
