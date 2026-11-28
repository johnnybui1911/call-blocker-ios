import XCTest
@testable import BlockerCore

final class NumberInputTests: XCTestCase {
    func testSixDigitLandlinePrefixBlocksOneHundredThousandNumbers() {
        let reading = NumberInput.interpret("028888")
        XCTAssertEqual(reading.kind, .prefix)
        XCTAssertEqual(reading.targetLength, 12)
        XCTAssertNil(reading.preview.error)
        XCTAssertEqual(reading.preview.count, 100_000)
        XCTAssertEqual(reading.preview.first, 842_888_800_000)
        XCTAssertEqual(reading.preview.last, 842_888_899_999)
    }

    func testCompleteLandlineIsOneNumber() {
        let reading = NumberInput.interpret("028 3823 4567")
        XCTAssertEqual(reading.kind, .fullNumber)
        XCTAssertEqual(reading.preview.count, 1)
        XCTAssertEqual(reading.preview.normalized, "842838234567")
        XCTAssertTrue(reading.preview.canSave)
    }

    func testCompleteMobileIsOneNumber() {
        let reading = NumberInput.interpret("0901234567")
        XCTAssertEqual(reading.kind, .fullNumber)
        XCTAssertEqual(reading.targetLength, 11)
        XCTAssertEqual(reading.preview.count, 1)
    }

    func testMobilePrefixUsesMobileLength() {
        let reading = NumberInput.interpret("090123")
        XCTAssertEqual(reading.kind, .prefix)
        XCTAssertEqual(reading.targetLength, 11)
        XCTAssertEqual(reading.preview.count, 10_000)
    }

    func testInternationalFormsReadTheSameAsNational() {
        XCTAssertEqual(NumberInput.interpret("+84 28888"), NumberInput.interpret("+8428888"))
        XCTAssertEqual(NumberInput.interpret("+8428888").preview.normalized, NumberInput.interpret("028888").preview.normalized)
        XCTAssertEqual(NumberInput.interpret("8428888").kind, .prefix)
    }

    func testPrefixShorterThanSixDigitsIsRefused() {
        let reading = NumberInput.interpret("0288")
        XCTAssertEqual(reading.kind, .prefix)
        XCTAssertEqual(reading.preview.error, .prefixTooShort(digits: 4))
        XCTAssertFalse(reading.preview.canSave)
    }

    func testNumberLongerThanItsTypeIsRefused() {
        let reading = NumberInput.interpret("09012345678")
        XCTAssertEqual(reading.preview.error, .fullNumberTooLong(12))
        XCTAssertFalse(reading.preview.canSave)
    }

    func testEmptyAndForeignInputKeepTheNormalizerError() {
        XCTAssertEqual(NumberInput.interpret("").preview.error, .normalization(.empty))
        XCTAssertEqual(NumberInput.interpret("+1 415 555 0100").preview.error, .normalization(.notVietnamese))
    }

    func testOverridesWinOverDetection() {
        let forcedPrefix = NumberInput.interpret("0283823456", kind: .prefix, targetLength: 12)
        XCTAssertEqual(forcedPrefix.kind, .prefix)
        XCTAssertEqual(forcedPrefix.preview.count, 10)

        let customLength = NumberInput.interpret("028888", targetLength: 10)
        XCTAssertEqual(customLength.kind, .prefix)
        XCTAssertEqual(customLength.preview.count, 1_000)
    }

    func testInterpretedInputBuildsTheSameRuleAsTheFactory() throws {
        let reading = NumberInput.interpret("028888")
        let rule = try RuleFactory.make(kind: reading.kind, rawInput: "028888", targetLength: reading.targetLength, enabled: true, note: "").get()
        let legacy = try RuleFactory.make(id: rule.id, kind: .prefix, rawInput: "028888", targetLength: Limits.defaultTargetLength, enabled: true, note: "").get()
        XCTAssertEqual(rule, legacy)
    }

    func testDisplayFormatsNationalNumbers() {
        XCTAssertEqual(NumberDisplay.formatted(pattern: "842838234567"), "028 3823 4567")
        XCTAssertEqual(NumberDisplay.formatted(pattern: "84901234567"), "090 123 4567")
        XCTAssertEqual(NumberDisplay.formatted(pattern: "8428888"), "028 888")
        XCTAssertEqual(NumberDisplay.formatted(pattern: "842473"), "024 73")
        XCTAssertEqual(NumberDisplay.formatted(number: 842_888_800_000), "028 8880 0000")
        XCTAssertEqual(NumberDisplay.national("12345"), "12345")
    }
}
