import Foundation

/// What a typed value means once its kind and length have been worked out.
public struct InputReading: Equatable {
    public var kind: RuleKind
    /// E.164 length a prefix expands to.
    public var targetLength: Int
    public var preview: DraftPreview
}

/// Reads user input without asking for a kind: a complete number blocks one
/// number, anything shorter blocks the whole range that starts with it.
public enum NumberInput {
    /// E.164 length of a complete Vietnamese number that starts with `pattern`.
    /// Landlines (national `02…`) have 11 national digits, everything else 10.
    public static func fullLength(forPattern pattern: String) -> Int {
        pattern.hasPrefix(Limits.countryCode + "2") ? 12 : 11
    }

    /// - Parameters:
    ///   - kind: Pass a value to override the detected kind.
    ///   - targetLength: Pass a value to override the inferred full length.
    public static func interpret(
        _ raw: String,
        kind: RuleKind? = nil,
        targetLength: Int? = nil
    ) -> InputReading {
        guard case .success(let pattern) = PhoneNormalizer.normalize(raw) else {
            let length = targetLength ?? Limits.defaultTargetLength
            let fallback = kind ?? .fullNumber
            return InputReading(
                kind: fallback,
                targetLength: length,
                preview: RuleFactory.preview(kind: fallback, rawInput: raw, targetLength: length)
            )
        }

        let length = targetLength ?? fullLength(forPattern: pattern)
        let resolved = kind ?? (pattern.count >= length ? .fullNumber : .prefix)
        var preview = RuleFactory.preview(kind: resolved, rawInput: raw, targetLength: length)
        if kind == nil, preview.error == nil, pattern.count > length {
            // Longer than any number of this type, so it is a typo rather than a number.
            preview = DraftPreview(
                normalized: pattern,
                count: nil,
                first: nil,
                last: nil,
                reachesSoftCap: false,
                error: .fullNumberTooLong(pattern.count)
            )
        }
        return InputReading(kind: resolved, targetLength: length, preview: preview)
    }
}

/// Shows E.164 digits the way people in Vietnam write phone numbers.
public enum NumberDisplay {
    /// `8428888` becomes `028888`. Input that is not Vietnamese E.164 is returned as is.
    public static func national(_ pattern: String) -> String {
        guard pattern.hasPrefix(Limits.countryCode) else { return pattern }
        return "0" + pattern.dropFirst(Limits.countryCode.count)
    }

    /// Groups national digits: `028 3823 4567` for landlines, `090 123 4567` otherwise.
    /// Partial numbers keep the same grouping, so `028888` becomes `028 888`.
    public static func grouped(_ national: String) -> String {
        let cuts = national.hasPrefix("02") ? [3, 7] : [3, 6]
        var parts: [Substring] = []
        var rest = Substring(national)
        var taken = 0
        for cut in cuts {
            let size = cut - taken
            guard rest.count > size else { break }
            parts.append(rest.prefix(size))
            rest = rest.dropFirst(size)
            taken = cut
        }
        if !rest.isEmpty { parts.append(rest) }
        return parts.joined(separator: " ")
    }

    public static func formatted(pattern: String) -> String {
        grouped(national(pattern))
    }

    public static func formatted(number: UInt64) -> String {
        formatted(pattern: String(number))
    }
}
