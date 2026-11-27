import XCTest
@testable import BlockerCore

final class BlocklistTests: XCTestCase {
    func testDefaultLengths() {
        XCTAssertEqual(Limits.defaultTargetLength, 12)
        XCTAssertEqual(Limits.countryCode, "84")
        XCTAssertEqual(Limits.softCap, 1_000_000)
        XCTAssertEqual(Limits.hardCap, 2_000_000)
    }

    func testHoChiMinhLandlinePrefixExpandsToOneHundredThousand() throws {
        let rule = try make(kind: .prefix, raw: "028888", target: 12, enabled: true)
        XCTAssertEqual(rule.pattern, "8428888")

        let preview = RuleFactory.preview(kind: .prefix, rawInput: "028888", targetLength: 12)
        XCTAssertNil(preview.error)
        XCTAssertEqual(preview.count, 100_000)
        XCTAssertEqual(preview.first, 842_888_800_000)
        XCTAssertEqual(preview.last, 842_888_899_999)
        XCTAssertFalse(preview.reachesSoftCap)

        let build = BlocklistBuild.evaluate(rules: [rule])
        XCTAssertEqual(build.mergedCount, 100_000)
        XCTAssertEqual(build.enabledSum, 100_000)
        XCTAssertFalse(build.reachesSoftCap)
        XCTAssertFalse(build.hardCapExceeded)
        XCTAssertEqual(build.ranges.count, 1)
        XCTAssertEqual(build.ranges[0].lower, 842_888_800_000)
        XCTAssertEqual(build.ranges[0].upper, 842_888_899_999)

        var first: UInt64?
        var previous: UInt64?
        var count: UInt64 = 0
        var ordered = true
        build.forEach { number in
            if first == nil { first = number }
            if let previous, number <= previous { ordered = false }
            previous = number
            count += 1
        }
        XCTAssertTrue(ordered)
        XCTAssertEqual(count, 100_000)
        XCTAssertEqual(first, 842_888_800_000)
        XCTAssertEqual(previous, 842_888_899_999)
    }

    func testPlusAndBareCountryCodeMatchTheSamePrefix() throws {
        for raw in ["028888", "+8428888", "8428888", "0084 28888"] {
            let preview = RuleFactory.preview(kind: .prefix, rawInput: raw, targetLength: 12)
            XCTAssertEqual(preview.normalized, "8428888", raw)
            XCTAssertEqual(preview.count, 100_000, raw)
            XCTAssertEqual(preview.first, 842_888_800_000, raw)
            XCTAssertEqual(preview.last, 842_888_899_999, raw)
        }
    }

    func testOverlappingPrefixAndFullNumberDedup() throws {
        let wide = try make(kind: .prefix, raw: "028888", target: 12, enabled: true)
        let narrow = try make(kind: .prefix, raw: "0288880", target: 12, enabled: true)
        let inside = try make(kind: .fullNumber, raw: "02888812345", target: 12, enabled: true)
        XCTAssertEqual(narrow.pattern, "84288880")
        XCTAssertEqual(inside.pattern, "842888812345")

        let build = BlocklistBuild.evaluate(rules: [inside, narrow, wide])
        XCTAssertEqual(build.enabledSum, 100_000 + 10_000 + 1)
        XCTAssertEqual(build.mergedCount, 100_000)
        XCTAssertEqual(build.ranges.count, 1)
        XCTAssertEqual(build.ranges[0].lower, 842_888_800_000)
        XCTAssertEqual(build.ranges[0].upper, 842_888_899_999)
    }

    func testDisabledRulesAreExcludedAndDuplicatesCollapse() throws {
        let blocked = try make(kind: .fullNumber, raw: "0901111111", target: 12, enabled: true)
        let duplicate = try make(kind: .fullNumber, raw: "0901111111", target: 12, enabled: true)
        let off = try make(kind: .fullNumber, raw: "0902222222", target: 12, enabled: false)
        let build = BlocklistBuild.evaluate(rules: [duplicate, off, blocked])
        XCTAssertEqual(build.mergedCount, 1)
        XCTAssertEqual(build.enabledSum, 2)
        XCTAssertEqual(off.pattern, "84902222222")
        XCTAssertEqual(build.ranges[0].lower, UInt64(blocked.pattern))
    }

    func testDifferentLengthsSortNumerically() throws {
        let mobile = try make(kind: .fullNumber, raw: "0900000001", target: 12, enabled: true)
        let landline = try make(kind: .fullNumber, raw: "02873000000", target: 12, enabled: true)
        XCTAssertEqual(mobile.pattern, "84900000001")
        XCTAssertEqual(landline.pattern, "842873000000")
        let build = BlocklistBuild.evaluate(rules: [landline, mobile])
        XCTAssertEqual(build.ranges.map(\.lower), [84_900_000_001, 842_873_000_000])
    }

    func testSoftCapWarnsAndHardCapRefuses() throws {
        let tenLandlinePrefixes = try (0..<10).map {
            try make(kind: .prefix, raw: "02888\($0)", target: 12, enabled: true)
        }
        let atSoftCap = BlocklistBuild.evaluate(rules: tenLandlinePrefixes)
        XCTAssertEqual(atSoftCap.mergedCount, 1_000_000)
        XCTAssertTrue(atSoftCap.reachesSoftCap)
        XCTAssertFalse(atSoftCap.hardCapExceeded)

        let tooBroad = RuleFactory.preview(kind: .prefix, rawInput: "0288", targetLength: 12)
        XCTAssertEqual(tooBroad.normalized, "84288")
        XCTAssertEqual(tooBroad.error, .prefixTooShort(digits: 4))

        let atCap = BlocklistBuild.evaluate(rules: try landlinePrefixes(count: 20))
        XCTAssertEqual(atCap.mergedCount, 2_000_000)
        XCTAssertFalse(atCap.hardCapExceeded)

        let overCap = BlocklistBuild.evaluate(rules: try landlinePrefixes(count: 21))
        XCTAssertEqual(overCap.mergedCount, 2_100_000)
        XCTAssertTrue(overCap.hardCapExceeded)
    }

    func testHardCapStillRejectsASingleHugeSixDigitPrefix() {
        // Target 15 turns a 6-digit prefix into 10^8 numbers.
        XCTAssertEqual(
            RuleFactory.preview(kind: .prefix, rawInput: "028888", targetLength: 15).error,
            .expansionExceedsHardCap(count: 100_000_000)
        )
    }

    func testPrefixMinimumLength() throws {
        XCTAssertEqual(Limits.minimumPrefixDigits, 6)
        for raw in ["02888", "+842888", "842888", "0084 2888", "0", "09012"] {
            let error = RuleFactory.preview(kind: .prefix, rawInput: raw, targetLength: 12).error
            guard case .prefixTooShort(let digits)? = error else {
                return XCTFail("\(raw) should be too short, got \(String(describing: error))")
            }
            XCTAssertLessThan(digits, 6)
        }
        XCTAssertEqual(
            RuleFactory.preview(kind: .prefix, rawInput: "02888", targetLength: 12).error,
            .prefixTooShort(digits: 5)
        )
        XCTAssertEqual(RuleFactory.make(kind: .prefix, rawInput: "02888", targetLength: 12, enabled: true, note: ""),
                       .failure(.prefixTooShort(digits: 5)))

        // 6 digits counting the leading 0, in every accepted spelling.
        for raw in ["028888", "+8428888", "8428888", "090123"] {
            XCTAssertNil(RuleFactory.preview(kind: .prefix, rawInput: raw, targetLength: 12).error, raw)
        }
        XCTAssertEqual(RuleFactory.preview(kind: .prefix, rawInput: "090123", targetLength: 11).count, 10_000)
        // 7 or more digits.
        for raw in ["0288881", "02888812", "090123456"] {
            XCTAssertNil(RuleFactory.preview(kind: .prefix, rawInput: raw, targetLength: 12).error, raw)
        }
        // Full numbers are not subject to the prefix minimum.
        XCTAssertNil(RuleFactory.preview(kind: .fullNumber, rawInput: "0901234567", targetLength: 11).error)
    }

    func testShortPrefixFromImportedOrStoredRulesIsSkippedNotCrashed() throws {
        let valid = try make(kind: .prefix, raw: "028888", target: 12, enabled: true)
        let short = BlockRule(
            id: UUID(), kind: .prefix, rawInput: "02888", pattern: "842888",
            targetLength: 12, enabled: true, note: ""
        )
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rules-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try RuleArchive.save([short, valid], to: url)

        let loaded = try RuleArchive.loadIfPresent(from: url)
        XCTAssertEqual(loaded.count, 2)
        let build = BlocklistBuild.evaluate(rules: loaded)
        XCTAssertEqual(build.skippedRuleIDs, [short.id])
        XCTAssertTrue(build.estimates.first { $0.id == short.id }?.invalid == true)
        XCTAssertEqual(build.mergedCount, 100_000)
        XCTAssertFalse(build.hardCapExceeded)
    }

    func testRejectsBadRules() {
        XCTAssertEqual(
            RuleFactory.preview(kind: .fullNumber, rawInput: "028888", targetLength: 12).error,
            .fullNumberTooShort(7)
        )
        XCTAssertEqual(
            RuleFactory.preview(kind: .prefix, rawInput: "02888812345", targetLength: 12).error,
            .prefixNotShorterThanTarget(patternLength: 12, targetLength: 12)
        )
        XCTAssertEqual(
            RuleFactory.preview(kind: .prefix, rawInput: "028888", targetLength: 4).error,
            .targetLengthOutOfRange(4)
        )
        XCTAssertEqual(
            RuleFactory.preview(kind: .prefix, rawInput: "abc", targetLength: 12).error,
            .normalization(.invalidCharacters)
        )
        XCTAssertEqual(
            RuleFactory.preview(kind: .fullNumber, rawInput: "+12025550123", targetLength: 12).error,
            .normalization(.notVietnamese)
        )
    }

    func testMergeRanges() {
        let merged = NumberRange.merge([
            NumberRange(lower: 4, upper: 8),
            NumberRange(lower: 1, upper: 5),
            NumberRange(lower: 20, upper: 20),
            NumberRange(lower: 6, upper: 7),
        ])
        XCTAssertEqual(merged, [
            NumberRange(lower: 1, upper: 8),
            NumberRange(lower: 20, upper: 20),
        ])

        let adjacent = NumberRange.merge([
            NumberRange(lower: 1, upper: 2),
            NumberRange(lower: 3, upper: 4),
        ])
        XCTAssertEqual(adjacent, [NumberRange(lower: 1, upper: 4)])

        let gap = NumberRange.merge([
            NumberRange(lower: 1, upper: 2),
            NumberRange(lower: 4, upper: 5),
        ])
        XCTAssertEqual(gap.count, 2)

        let top = NumberRange.merge([
            NumberRange(lower: UInt64.max - 1, upper: UInt64.max),
            NumberRange(lower: UInt64.max, upper: UInt64.max),
        ])
        XCTAssertEqual(top, [NumberRange(lower: UInt64.max - 1, upper: UInt64.max)])
        XCTAssertEqual(NumberRange.merge([]), [])
    }

    private func landlinePrefixes(count: Int) throws -> [BlockRule] {
        try (0..<count).map { index in
            let area = 2_000 + index
            return try make(kind: .prefix, raw: "0\(area)0", target: 12, enabled: true)
        }
    }

    private func make(kind: RuleKind, raw: String, target: Int, enabled: Bool) throws -> BlockRule {
        try RuleFactory.make(
            kind: kind,
            rawInput: raw,
            targetLength: target,
            enabled: enabled,
            note: ""
        ).get()
    }
}
