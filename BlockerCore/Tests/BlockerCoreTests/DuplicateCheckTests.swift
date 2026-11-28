import XCTest
@testable import BlockerCore

final class DuplicateCheckTests: XCTestCase {
    private func rule(_ raw: String, kind: RuleKind? = nil, targetLength: Int? = nil, id: UUID = UUID()) throws -> BlockRule {
        let reading = NumberInput.interpret(raw, kind: kind, targetLength: targetLength)
        return try RuleFactory.make(id: id, kind: reading.kind, rawInput: raw, targetLength: reading.targetLength, enabled: true, note: "").get()
    }

    func testSameFullNumberTypedDifferentlyIsADuplicate() throws {
        let existing = [try rule("02838234567")]
        XCTAssertNotNil(existing.firstDuplicate(of: try rule("028 3823 4567")))
        XCTAssertNotNil(existing.firstDuplicate(of: try rule("+84 28 3823 4567")))
        XCTAssertNotNil(existing.firstDuplicate(of: try rule("842838234567")))
    }

    func testSamePrefixTypedDifferentlyIsADuplicate() throws {
        let existing = [try rule("028888")]
        XCTAssertEqual(existing.firstDuplicate(of: try rule("+8428888"))?.id, existing[0].id)
    }

    func testDifferentNumbersAreNotDuplicates() throws {
        let existing = [try rule("028888"), try rule("0901234567")]
        XCTAssertNil(existing.firstDuplicate(of: try rule("028889")))
        XCTAssertNil(existing.firstDuplicate(of: try rule("0901234568")))
    }

    func testPrefixAndNumberInsideItAreNotDuplicates() throws {
        let existing = [try rule("028888")]
        XCTAssertNil(existing.firstDuplicate(of: try rule("02888801234")))
    }

    func testSamePrefixWithAnotherLengthBlocksOtherNumbers() throws {
        let existing = [try rule("028888")]
        XCTAssertNil(existing.firstDuplicate(of: try rule("028888", targetLength: 11)))
    }

    func testPausedEntryStillCountsAsADuplicate() throws {
        var paused = try rule("0901234567")
        paused.enabled = false
        XCTAssertNotNil([paused].firstDuplicate(of: try rule("0901234567")))
    }

    func testEditingAnEntryIsNotADuplicateOfItself() throws {
        let original = try rule("028888")
        var edited = original
        edited.note = "Spam vay tiền"
        XCTAssertNil([original].firstDuplicate(of: edited))
    }

    func testInvalidEntryMatchesNothing() throws {
        let short = BlockRule(id: UUID(), kind: .prefix, rawInput: "0288", pattern: "84288", targetLength: 12, enabled: true, note: "")
        XCTAssertFalse(short.blocksSameNumbers(as: short))
        XCTAssertNil([short].firstDuplicate(of: try rule("028888")))
    }
}
