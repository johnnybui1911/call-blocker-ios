import Foundation

/// Whether iOS has the call-blocking switch for this app turned on.
public enum BlockingSwitch: Equatable, Sendable {
    case on
    case off
    /// iOS did not answer, or answered with an error.
    case unknown
}

/// The single status the home screen shows. Android mirrors these cases.
public enum HomeStatus: Equatable, Sendable {
    /// Blocking is on and at least one number is covered.
    case protecting
    /// Blocking is on but nothing is being blocked yet.
    case readyButEmpty
    /// The user still has to turn blocking on in Settings.
    case off
    /// The state could not be read.
    case unchecked
    /// This build cannot hand its list to the system, so nothing is blocked.
    case listUnavailable

    public static func resolve(
        blockingSwitch: BlockingSwitch,
        listReachesSystem: Bool,
        numbersCovered: UInt64
    ) -> HomeStatus {
        guard listReachesSystem else { return .listUnavailable }
        switch blockingSwitch {
        case .off:
            return .off
        case .unknown:
            return .unchecked
        case .on:
            return numbersCovered == 0 ? .readyButEmpty : .protecting
        }
    }

    /// True only when calls are really being blocked right now.
    public var isProtecting: Bool { self == .protecting }
}
