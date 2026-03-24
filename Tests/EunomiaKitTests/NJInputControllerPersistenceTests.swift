import XCTest
@testable import EunomiaKit

final class NJInputControllerPersistenceTests: XCTestCase {
    private var originalValue: Any?

    override func setUp() {
        super.setUp()
        originalValue = UserDefaults.standard.object(forKey: NJInputController.simulatingEventsDefaultsKey)
        UserDefaults.standard.removeObject(forKey: NJInputController.simulatingEventsDefaultsKey)
    }

    override func tearDown() {
        if let originalValue {
            UserDefaults.standard.set(originalValue, forKey: NJInputController.simulatingEventsDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: NJInputController.simulatingEventsDefaultsKey)
        }
        super.tearDown()
    }

    func testLoadRestoresSimulatingEventsFromDefaults() {
        UserDefaults.standard.set(true, forKey: NJInputController.simulatingEventsDefaultsKey)

        let controller = NJInputController()
        controller.load()

        XCTAssertTrue(controller.simulatingEvents)
    }

    func testSettingSimulatingEventsPersistsToDefaults() {
        let controller = NJInputController()

        controller.simulatingEvents = true
        XCTAssertEqual(UserDefaults.standard.object(forKey: NJInputController.simulatingEventsDefaultsKey) as? Bool, true)

        controller.simulatingEvents = false
        XCTAssertEqual(UserDefaults.standard.object(forKey: NJInputController.simulatingEventsDefaultsKey) as? Bool, false)
    }
}
