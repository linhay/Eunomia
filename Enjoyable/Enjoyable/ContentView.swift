//
//  ContentView.swift
//  Enjoyable
//
//  Created by linhey on 3/20/26.
//

import SwiftUI
import EnjoyableKit

enum HomeRenderMode: Equatable {
    case enjoyableRoot
    case testingFallback
}

struct ContentView: View {
    static func homeRenderMode(environment: [String: String]) -> HomeRenderMode {
        if environment["XCTestConfigurationFilePath"] != nil {
            return .testingFallback
        }
        return .enjoyableRoot
    }

    var body: some View {
        let env = ProcessInfo.processInfo.environment
        switch Self.homeRenderMode(environment: env) {
        case .enjoyableRoot:
            EnjoyableRootView()
        case .testingFallback:
            Text("Enjoyable Testing Host")
                .padding()
        }
    }
}

#Preview {
    ContentView()
}
