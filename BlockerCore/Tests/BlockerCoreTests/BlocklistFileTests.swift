import XCTest
@testable import BlockerCore

final class BlocklistFileTests: XCTestCase {
    func testRoundTripIsStrictlyAscending() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blocklist-\(UUID().uuidString).bin")
        defer { try? FileManager.default.removeItem(at: url) }

        let ranges = [
            NumberRange(lower: 20, upper: 20),
            NumberRange(lower: 10, upper: 12),
        ]
        // Writer requires the caller to pass already-merged ascending ranges.
        try BlocklistFile.write(ranges: NumberRange.merge(ranges), to: url)

        var numbers: [Int64] = []
        try BlocklistFile.forEachNumber(at: url) { numbers.append($0) }
        XCTAssertEqual(numbers, [10, 11, 12, 20])
    }

    func testSamplePrefixFileMatchesEndsAndCount() throws {
        let rule = try RuleFactory.make(
            kind: .prefix,
            rawInput: "028888",
            targetLength: 12,
            enabled: true,
            note: "test"
        ).get()
        let build = BlocklistBuild.evaluate(rules: [rule])
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blocklist-\(UUID().uuidString).bin")
        defer { try? FileManager.default.removeItem(at: url) }
        try BlocklistFile.write(ranges: build.ranges, to: url)

        var first: Int64?
        var last: Int64 = 0
        var count: UInt64 = 0
        var previous: Int64?
        var ordered = true
        try BlocklistFile.forEachNumber(at: url) { number in
            if first == nil { first = number }
            if let previous, number <= previous { ordered = false }
            previous = number
            last = number
            count += 1
        }
        XCTAssertTrue(ordered)
        XCTAssertEqual(count, 100_000)
        XCTAssertEqual(first, 842_888_800_000)
        XCTAssertEqual(last, 842_888_899_999)
    }

    func testEmptyListIsReadable() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blocklist-\(UUID().uuidString).bin")
        defer { try? FileManager.default.removeItem(at: url) }
        try BlocklistFile.write(ranges: [], to: url)
        var count = 0
        try BlocklistFile.forEachNumber(at: url) { _ in count += 1 }
        XCTAssertEqual(count, 0)
    }

    func testRejectsBadFiles() throws {
        let directory = FileManager.default.temporaryDirectory
        let badMagic = directory.appendingPathComponent("bad-magic-\(UUID().uuidString).bin")
        let unordered = directory.appendingPathComponent("unordered-\(UUID().uuidString).bin")
        let truncated = directory.appendingPathComponent("truncated-\(UUID().uuidString).bin")
        defer {
            try? FileManager.default.removeItem(at: badMagic)
            try? FileManager.default.removeItem(at: unordered)
            try? FileManager.default.removeItem(at: truncated)
        }

        var badHeader = Data("NOPE".utf8)
        badHeader.append(Data(count: 12))
        try badHeader.write(to: badMagic)
        XCTAssertThrowsError(try BlocklistFile.forEachNumber(at: badMagic) { _ in }) { error in
            XCTAssertEqual(error as? BlocklistFileError, .badMagic)
        }

        try Data([0x00]).write(to: truncated)
        XCTAssertThrowsError(try BlocklistFile.forEachNumber(at: truncated) { _ in }) { error in
            XCTAssertEqual(error as? BlocklistFileError, .truncated)
        }

        var unorderedData = Data("CBLK".utf8)
        unorderedData.appendLE(UInt16(1))
        unorderedData.appendLE(UInt16(0))
        unorderedData.appendLE(UInt64(2))
        unorderedData.appendLE(Int64(5))
        unorderedData.appendLE(Int64(4))
        try unorderedData.write(to: unordered)
        XCTAssertThrowsError(try BlocklistFile.forEachNumber(at: unordered) { _ in }) { error in
            XCTAssertEqual(error as? BlocklistFileError, .notStrictlyAscending)
        }
    }

    func testRefusesToWriteAboveHardCap() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blocklist-\(UUID().uuidString).bin")
        let huge = NumberRange(lower: 1, upper: Limits.hardCap + 1)
        XCTAssertThrowsError(try BlocklistFile.write(ranges: [huge], to: url)) { error in
            XCTAssertEqual(error as? BlocklistFileError, .exceedsHardCap)
        }
    }
}

private extension Data {
    mutating func appendLE<T: FixedWidthInteger>(_ value: T) {
        var little = value.littleEndian
        Swift.withUnsafeBytes(of: &little) { append(contentsOf: $0) }
    }
}
