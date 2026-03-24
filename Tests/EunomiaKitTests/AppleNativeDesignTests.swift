import XCTest
import SwiftUI
@testable import EunomiaKit

final class AppleNativeDesignTests: XCTestCase {
    func testAppleDesignMetricsUsesExpectedCornerRadiusScale() {
        XCTAssertEqual(AppleNativeDesignMetrics.sidebarCornerRadius, 14)
        XCTAssertEqual(AppleNativeDesignMetrics.cardCornerRadius, 16)
        XCTAssertEqual(AppleNativeDesignMetrics.compactCardCornerRadius, 12)
    }

    func testAppleDesignMetricsUsesExpectedSpacingScale() {
        XCTAssertEqual(AppleNativeDesignMetrics.spacingXS, 6)
        XCTAssertEqual(AppleNativeDesignMetrics.spacingS, 10)
        XCTAssertEqual(AppleNativeDesignMetrics.spacingM, 14)
        XCTAssertEqual(AppleNativeDesignMetrics.spacingL, 20)
        XCTAssertEqual(AppleNativeDesignMetrics.sidebarToolsSpacing, 10)
        XCTAssertEqual(AppleNativeDesignMetrics.panelBackgroundOpacity, 0.84)
        XCTAssertEqual(AppleNativeDesignMetrics.inputFieldBackgroundOpacity, 0.7)
    }

    func testAppleDesignMetricsUsesNativeSplitViewRatios() {
        XCTAssertEqual(AppleNativeDesignMetrics.sidebarMinWidth, 240)
        XCTAssertEqual(AppleNativeDesignMetrics.sidebarIdealWidth, 280)
        XCTAssertEqual(AppleNativeDesignMetrics.sidebarMaxWidth, 320)
        XCTAssertEqual(AppleNativeDesignMetrics.mainMinWidth, 560)
        XCTAssertEqual(AppleNativeDesignMetrics.inspectorIdealWidth, 340)
        XCTAssertEqual(AppleNativeDesignMetrics.inspectorMaxWidth, 420)
    }

    func testAppleDesignMetricsStatusSymbolsRemainSemantic() {
        XCTAssertEqual(DashboardStatusKind.monitoringStopped.icon, "pause.circle")
        XCTAssertEqual(DashboardStatusKind.noController.icon, "exclamationmark.triangle")
        XCTAssertEqual(DashboardStatusKind.liveInput.icon, "dot.radiowaves.left.and.right")
    }

    func testControllerCardUsesSolidSurfaceStyle() {
        XCTAssertEqual(RootCardSurfacePolicy.controllerCardStyle, .solid)
        XCTAssertEqual(RootCardSurfacePolicy.liveAxisCardStyle, .solid)
        XCTAssertEqual(RootCardSurfacePolicy.mappingManagerCardStyle, .solid)
        XCTAssertEqual(RootCardSurfacePolicy.outputEditorCardStyle, .solid)
    }

    func testDeviceAndInspectorUseUnifiedSidebarBackgroundPolicy() {
        XCTAssertTrue(SidebarSurfacePolicy.usesUnifiedBackground)
    }

    func testInspectorUsesModernCardLayoutPolicy() {
        XCTAssertTrue(InspectorPanelPresentationPolicy.usesModernCardLayout)
    }

    func testNativePanelCardCanBeConstructedWithSolidSurface() {
        let card = NativePanelCard(
            title: "Demo",
            symbol: "star.fill",
            surfaceStyle: .solid
        ) {
            Text("Body")
        }

        XCTAssertNotNil(card)
    }

    func testStepSelectionNormalizesIntoBounds() {
        XCTAssertNil(AppleKeyMappingEditorSheet.normalizedSelectedStepIndex(nil, stepCount: 0))
        XCTAssertEqual(AppleKeyMappingEditorSheet.normalizedSelectedStepIndex(nil, stepCount: 3), 0)
        XCTAssertEqual(AppleKeyMappingEditorSheet.normalizedSelectedStepIndex(-2, stepCount: 3), 0)
        XCTAssertEqual(AppleKeyMappingEditorSheet.normalizedSelectedStepIndex(8, stepCount: 3), 2)
    }
}
