import XCTest
@testable import BlockerCore

final class PhoneNormalizerTests: XCTestCase {
    func testNationalInternationalAndE164Forms() throws {
        XCTAssertEqual(try PhoneNormalizer.normalize("028888").get(), "8428888")
        XCTAssertEqual(try PhoneNormalizer.normalize("+8428888").get(), "8428888")
        XCTAssertEqual(try PhoneNormalizer.normalize("8428888").get(), "8428888")
        XCTAssertEqual(try PhoneNormalizer.normalize("+84 28888").get(), "8428888")
        XCTAssertEqual(try PhoneNormalizer.normalize("008428888").get(), "8428888")
        XCTAssertEqual(try PhoneNormalizer.normalize("  (028) 888  ").get(), "8428888")
        XCTAssertEqual(try PhoneNormalizer.normalize("84-28888").get(), "8428888")
        XCTAssertEqual(try PhoneNormalizer.normalize("+ 84 28888").get(), "8428888")
    }

    func testFullLandlineAndMobile() throws {
        XCTAssertEqual(try PhoneNormalizer.normalize("02888812345").get(), "842888812345")
        XCTAssertEqual(try PhoneNormalizer.normalize("0901234567").get(), "84901234567")
    }

    func testRejectsInvalidInput() {
        XCTAssertEqual(PhoneNormalizer.normalize(""), .failure(.empty))
        XCTAssertEqual(PhoneNormalizer.normalize("   "), .failure(.empty))
        XCTAssertEqual(PhoneNormalizer.normalize("+"), .failure(.empty))
        XCTAssertEqual(PhoneNormalizer.normalize("00"), .failure(.empty))
        XCTAssertEqual(PhoneNormalizer.normalize("abc"), .failure(.invalidCharacters))
        XCTAssertEqual(PhoneNormalizer.normalize("028888a"), .failure(.invalidCharacters))
        XCTAssertEqual(PhoneNormalizer.normalize("84+28888"), .failure(.invalidCharacters))
        XCTAssertEqual(PhoneNormalizer.normalize("++8428888"), .failure(.invalidCharacters))
        XCTAssertEqual(PhoneNormalizer.normalize("12345"), .failure(.notVietnamese))
        XCTAssertEqual(PhoneNormalizer.normalize("+12025550123"), .failure(.notVietnamese))
        XCTAssertEqual(PhoneNormalizer.normalize("008121234"), .failure(.notVietnamese))
        XCTAssertEqual(
            PhoneNormalizer.normalize("8412345678901234"),
            .failure(.tooLong)
        )
    }

    func testTrunkZeroAloneBecomesCountryCode() throws {
        XCTAssertEqual(try PhoneNormalizer.normalize("0").get(), "84")
    }
}
