import Foundation

public enum NormalizeError: Error, Equatable {
    case empty
    case invalidCharacters
    /// The input is not a Vietnamese number in national (`0…`),
    /// international (`00 84…`), or E.164 (`84…` / `+84…`) form.
    case notVietnamese
    case tooLong
}

/// Turns user input into E.164 digits with no leading plus.
/// Accepted shapes: `0…`, `84…`, `+84…`, and `0084…`.
public enum PhoneNormalizer {
    public static func normalize(_ raw: String) -> Result<String, NormalizeError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .failure(.empty)
        }

        var sawPlus = false
        var digits = ""
        digits.reserveCapacity(trimmed.count)

        for character in trimmed {
            if isASCIIDigit(character) {
                digits.append(character)
                continue
            }
            switch character {
            case "+":
                if sawPlus || !digits.isEmpty {
                    return .failure(.invalidCharacters)
                }
                sawPlus = true
            case " ", "-", "(", ")", ".", "\u{00A0}", "\u{202F}":
                continue
            default:
                return .failure(.invalidCharacters)
            }
        }

        if digits.isEmpty {
            return .failure(.empty)
        }

        let normalized: String
        if sawPlus {
            guard digits.hasPrefix(Limits.countryCode) else {
                return .failure(.notVietnamese)
            }
            normalized = digits
        } else if digits.hasPrefix("00") {
            let international = digits.dropFirst(2)
            if international.isEmpty {
                return .failure(.empty)
            }
            guard international.hasPrefix(Limits.countryCode) else {
                return .failure(.notVietnamese)
            }
            normalized = String(international)
        } else if digits.hasPrefix("0") {
            normalized = Limits.countryCode + digits.dropFirst()
        } else if digits.hasPrefix(Limits.countryCode) {
            normalized = digits
        } else {
            return .failure(.notVietnamese)
        }

        if normalized.count > Limits.maximumFullNumberLength {
            return .failure(.tooLong)
        }
        return .success(normalized)
    }

    private static func isASCIIDigit(_ character: Character) -> Bool {
        guard let value = character.asciiValue else { return false }
        return value >= 48 && value <= 57
    }
}
