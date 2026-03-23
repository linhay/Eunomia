//
//  EnjoyableTests.swift
//  EnjoyableTests
//
//  Created by linhey on 3/20/26.
//

import Testing
@testable import Enjoyable

struct EnjoyableTests {

    @Test func home_should_use_enjoyable_root_outside_tests() async throws {
        let renderMode = ContentView.homeRenderMode(environment: [:])
        #expect(renderMode == .enjoyableRoot)
    }

    @Test func home_should_use_fallback_inside_tests() async throws {
        let renderMode = ContentView.homeRenderMode(environment: [
            "XCTestConfigurationFilePath": "/tmp/test.xctestconfiguration"
        ])
        #expect(renderMode == .testingFallback)
    }

    @Test func home_should_still_use_enjoyable_root_with_unrelated_environment() async throws {
        let renderMode = ContentView.homeRenderMode(environment: [
            "FEATURE_FLAG": "1"
        ])
        #expect(renderMode == .enjoyableRoot)
    }

}
