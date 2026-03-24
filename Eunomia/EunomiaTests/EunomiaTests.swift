//
//  EunomiaTests.swift
//  EunomiaTests
//
//  Created by linhey on 3/20/26.
//

import Testing
@testable import Eunomia

struct EunomiaTests {

    @Test func home_should_use_eunomia_root_outside_tests() async throws {
        let renderMode = ContentView.homeRenderMode(environment: [:])
        #expect(renderMode == .eunomiaRoot)
    }

    @Test func home_should_use_fallback_inside_tests() async throws {
        let renderMode = ContentView.homeRenderMode(environment: [
            "XCTestConfigurationFilePath": "/tmp/test.xctestconfiguration"
        ])
        #expect(renderMode == .testingFallback)
    }

    @Test func home_should_still_use_eunomia_root_with_unrelated_environment() async throws {
        let renderMode = ContentView.homeRenderMode(environment: [
            "FEATURE_FLAG": "1"
        ])
        #expect(renderMode == .eunomiaRoot)
    }

}
