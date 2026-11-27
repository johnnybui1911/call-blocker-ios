import XCTest
@testable import BlockerCore

final class RuleArchiveTests: XCTestCase {
    func testRoundTrip() throws {
        let prefix = try RuleFactory.make(
            kind: .prefix,
            rawInput: "028888",
            targetLength: 12,
            enabled: true,
            note: "số bàn"
        ).get()
        let full = try RuleFactory.make(
            kind: .fullNumber,
            rawInput: "0901234567",
            targetLength: 11,
            enabled: false,
            note: ""
        ).get()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rules-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertEqual(try RuleArchive.loadIfPresent(from: url), [])
        try RuleArchive.save([prefix, full], to: url)
        let loaded = try RuleArchive.loadIfPresent(from: url)
        XCTAssertEqual(loaded, [prefix, full])
    }
}
