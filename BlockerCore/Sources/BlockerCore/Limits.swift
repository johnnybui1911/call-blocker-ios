import Foundation

/// Caps and Vietnamese numbering defaults.
///
/// The entry caps are conservative placeholders. Call Directory extensions have
/// a tight, undocumented memory and time budget. Confirm on a real iPhone
/// before relying on a list near either cap.
public enum Limits {
    /// Warn in the UI when an enabled list reaches this many numbers.
    public static let softCap: UInt64 = 1_000_000

    /// Refuse to enable or publish a list larger than this.
    /// A list of exactly this size is still allowed.
    public static let hardCap: UInt64 = 2_000_000

    /// E.164 digit length for a Vietnam landline in a 2-digit area
    /// (trunk 0 + area + 8 subscriber digits, written without the trunk 0
    /// and with country code 84). Mobile numbers are usually 11 digits;
    /// the editor tells the user to lower the length for those.
    public static let defaultTargetLength = 12

    public static let minimumTargetLength = 8
    public static let maximumTargetLength = 15

    public static let minimumFullNumberLength = 10
    public static let maximumFullNumberLength = 15

    /// Vietnam E.164 country calling code. This is normalization input,
    /// not a blocklist entry.
    public static let countryCode = "84"
}
