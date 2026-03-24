import XCTest
@testable import EunomiaKit

final class MappingRenamePanelStateTests: XCTestCase {
    func testHasPendingChangesWhenDraftDiffersFromCurrent() {
        let state = MappingRenamePanelState(currentName: "Racing", draftName: "Racing Pro")
        XCTAssertTrue(state.hasPendingChanges)
    }

    func testHasNoPendingChangesWhenTrimmedValueMatches() {
        let state = MappingRenamePanelState(currentName: "Racing", draftName: "  Racing  ")
        XCTAssertFalse(state.hasPendingChanges)
    }

    func testCannotSaveWithEmptyTrimmedDraft() {
        let state = MappingRenamePanelState(currentName: "Racing", draftName: "   ")
        XCTAssertFalse(state.canSave)
    }

    func testCanSaveWithNonEmptyChangedDraft() {
        let state = MappingRenamePanelState(currentName: "Racing", draftName: "Arcade")
        XCTAssertTrue(state.canSave)
    }
}
