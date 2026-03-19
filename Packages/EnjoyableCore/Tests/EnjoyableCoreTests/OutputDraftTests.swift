import XCTest
@testable import EnjoyableCore

final class OutputDraftTests: XCTestCase {
    func testFromKeyOutput() {
        let output = NJOutputKeyPress()
        output.keyCode = 42

        let draft = OutputDraft.from(output: output, mappings: [])
        XCTAssertEqual(draft.type, .keyPress)
        XCTAssertEqual(draft.keyCode, 42)
    }

    func testBuildMouseMoveOutput() {
        var draft = OutputDraft()
        draft.type = .mouseMove
        draft.mouseAxis = 3
        draft.mouseSpeed = 27

        let built = draft.buildOutput(mappings: []) as? NJOutputMouseMove
        XCTAssertNotNil(built)
        XCTAssertEqual(built?.axis, 3)
        XCTAssertEqual(built?.speed, 27)
    }

    func testBuildMappingOutputUsesSelectedIndex() {
        let first = NJMapping(name: "A")
        let second = NJMapping(name: "B")

        var draft = OutputDraft()
        draft.type = .mapping
        draft.mappingIndex = 1

        let built = draft.buildOutput(mappings: [first, second]) as? NJOutputMapping
        XCTAssertTrue(built?.mapping === second)
        XCTAssertEqual(built?.mappingName, "B")
    }

    func testScrollSpeedIsZeroWhenNotSmooth() {
        var draft = OutputDraft()
        draft.type = .mouseScroll
        draft.scrollSmooth = false
        draft.scrollSpeed = 90

        let built = draft.buildOutput(mappings: []) as? NJOutputMouseScroll
        XCTAssertNotNil(built)
        XCTAssertEqual(built?.smooth, false)
        XCTAssertEqual(built?.speed, 0)
    }
}
