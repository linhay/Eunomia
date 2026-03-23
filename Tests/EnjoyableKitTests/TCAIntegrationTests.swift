import ComposableArchitecture
import XCTest
@testable import EnjoyableKit

@MainActor
final class TCAIntegrationTests: XCTestCase {
    func testToggleAndThresholdFlow() async {
        let store = TestStore(
            initialState: KeyMappingEditorTCAFeature.State(
                isEnabled: true,
                threshold: 0.5
            )
        ) {
            KeyMappingEditorTCAFeature()
        }

        await store.send(.setEnabled(false)) {
            $0.isEnabled = false
        }

        await store.send(.setThreshold(0.72)) {
            $0.threshold = 0.72
        }
    }
}
