import XCTest
@testable import BlockerCore

final class HomeStatusTests: XCTestCase {
    func testProtectingNeedsSwitchOnAndNumbers() {
        XCTAssertEqual(HomeStatus.resolve(blockingSwitch: .on, listReachesSystem: true, numbersCovered: 100_001), .protecting)
        XCTAssertTrue(HomeStatus.protecting.isProtecting)
    }

    func testSwitchOnWithNothingBlockedIsReadyButEmpty() {
        let status = HomeStatus.resolve(blockingSwitch: .on, listReachesSystem: true, numbersCovered: 0)
        XCTAssertEqual(status, .readyButEmpty)
        XCTAssertFalse(status.isProtecting)
    }

    func testSwitchOffAndUnknownAreNotProtecting() {
        XCTAssertEqual(HomeStatus.resolve(blockingSwitch: .off, listReachesSystem: true, numbersCovered: 5), .off)
        XCTAssertEqual(HomeStatus.resolve(blockingSwitch: .unknown, listReachesSystem: true, numbersCovered: 5), .unchecked)
    }

    func testListThatCannotReachTheSystemNeverClaimsProtection() {
        for blockingSwitch in [BlockingSwitch.on, .off, .unknown] {
            XCTAssertEqual(
                HomeStatus.resolve(blockingSwitch: blockingSwitch, listReachesSystem: false, numbersCovered: 5),
                .listUnavailable
            )
        }
    }
}
