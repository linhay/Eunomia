//
//  ContentView.swift
//  Eunomia
//
//  Created by linhey on 3/20/26.
//

import SwiftUI
import EunomiaKit

enum HomeRenderMode: Equatable {
    case eunomiaRoot
    case testingFallback
}

struct ContentView: View {
    static func homeRenderMode(environment: [String: String]) -> HomeRenderMode {
        if environment["XCTestConfigurationFilePath"] != nil {
            return .testingFallback
        }
        return .eunomiaRoot
    }

    var body: some View {
        let env = ProcessInfo.processInfo.environment
        switch Self.homeRenderMode(environment: env) {
        case .eunomiaRoot:
            EunomiaRootView()
        case .testingFallback:
            Text("Eunomia Testing Host")
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
