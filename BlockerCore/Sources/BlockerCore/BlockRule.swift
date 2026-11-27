import Foundation

public enum RuleKind: String, Codable, Equatable, Sendable {
    case prefix
    case fullNumber
}

public struct BlockRule: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var kind: RuleKind
    /// What the user typed, kept so the editor can show it again.
    public var rawInput: String
    /// Normalized E.164 digits, no plus.
    public var pattern: String
    /// Full E.164 length a prefix expands to. Stored for full-number rules
    /// as well so editing can switch kind without losing the length.
    public var targetLength: Int
    public var enabled: Bool
    public var note: String

    public init(
        id: UUID,
        kind: RuleKind,
        rawInput: String,
        pattern: String,
        targetLength: Int,
        enabled: Bool,
        note: String
    ) {
        self.id = id
        self.kind = kind
        self.rawInput = rawInput
        self.pattern = pattern
        self.targetLength = targetLength
        self.enabled = enabled
        self.note = note
    }
}

public enum RuleValidationError: Error, Equatable {
    case normalization(NormalizeError)
    case targetLengthOutOfRange(Int)
    case prefixNotShorterThanTarget(patternLength: Int, targetLength: Int)
    case fullNumberTooShort(Int)
    case fullNumberTooLong(Int)
    case expansionExceedsHardCap(count: UInt64)
    case expansionOverflow
}

public struct DraftPreview: Equatable {
    public var normalized: String?
    public var count: UInt64?
    public var first: UInt64?
    public var last: UInt64?
    public var reachesSoftCap: Bool
    public var error: RuleValidationError?

    public var canSave: Bool { error == nil && normalized != nil }
}

public enum RuleFactory {
    public static func preview(
        kind: RuleKind,
        rawInput: String,
        targetLength: Int
    ) -> DraftPreview {
        let normalized: String
        switch PhoneNormalizer.normalize(rawInput) {
        case .failure(let error):
            return DraftPreview(
                normalized: nil,
                count: nil,
                first: nil,
                last: nil,
                reachesSoftCap: false,
                error: .normalization(error)
            )
        case .success(let digits):
            normalized = digits
        }

        let span: Result<NumberSpan, RuleValidationError>
        switch kind {
        case .prefix:
            span = ExpansionMath.prefixSpan(pattern: normalized, targetLength: targetLength)
        case .fullNumber:
            span = ExpansionMath.fullNumberSpan(pattern: normalized)
        }

        switch span {
        case .failure(let error):
            let count: UInt64?
            if case .expansionExceedsHardCap(let value) = error {
                count = value
            } else {
                count = nil
            }
            return DraftPreview(
                normalized: normalized,
                count: count,
                first: nil,
                last: nil,
                reachesSoftCap: (count ?? 0) >= Limits.softCap,
                error: error
            )
        case .success(let value):
            let overCap = value.count > Limits.hardCap
            return DraftPreview(
                normalized: normalized,
                count: value.count,
                first: value.first,
                last: value.last,
                reachesSoftCap: value.count >= Limits.softCap,
                error: overCap ? .expansionExceedsHardCap(count: value.count) : nil
            )
        }
    }

    public static func make(
        id: UUID = UUID(),
        kind: RuleKind,
        rawInput: String,
        targetLength: Int,
        enabled: Bool,
        note: String
    ) -> Result<BlockRule, RuleValidationError> {
        let preview = preview(kind: kind, rawInput: rawInput, targetLength: targetLength)
        if let error = preview.error {
            return .failure(error)
        }
        guard let pattern = preview.normalized else {
            return .failure(.normalization(.empty))
        }
        let rule = BlockRule(
            id: id,
            kind: kind,
            rawInput: rawInput.trimmingCharacters(in: .whitespacesAndNewlines),
            pattern: pattern,
            targetLength: targetLength,
            enabled: enabled,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        return .success(rule)
    }
}

struct NumberSpan: Equatable {
    var first: UInt64
    var last: UInt64
    var count: UInt64
}

enum ExpansionMath {
    static func pow10(_ exponent: Int) -> UInt64? {
        guard exponent >= 0 else { return nil }
        var value: UInt64 = 1
        for _ in 0..<exponent {
            let (next, overflow) = value.multipliedReportingOverflow(by: 10)
            if overflow { return nil }
            value = next
        }
        return value
    }

    static func prefixSpan(pattern: String, targetLength: Int) -> Result<NumberSpan, RuleValidationError> {
        guard (Limits.minimumTargetLength...Limits.maximumTargetLength).contains(targetLength) else {
            return .failure(.targetLengthOutOfRange(targetLength))
        }
        guard pattern.count < targetLength else {
            return .failure(.prefixNotShorterThanTarget(
                patternLength: pattern.count,
                targetLength: targetLength
            ))
        }
        let extra = targetLength - pattern.count
        guard let width = pow10(extra) else {
            return .failure(.expansionOverflow)
        }
        if width > Limits.hardCap {
            return .failure(.expansionExceedsHardCap(count: width))
        }
        guard let prefixValue = UInt64(pattern) else {
            return .failure(.expansionOverflow)
        }
        let (lower, multiplyOverflow) = prefixValue.multipliedReportingOverflow(by: width)
        if multiplyOverflow {
            return .failure(.expansionOverflow)
        }
        let (upper, addOverflow) = lower.addingReportingOverflow(width - 1)
        if addOverflow || lower > UInt64(Int64.max) || upper > UInt64(Int64.max) {
            return .failure(.expansionOverflow)
        }
        return .success(NumberSpan(first: lower, last: upper, count: width))
    }

    static func fullNumberSpan(pattern: String) -> Result<NumberSpan, RuleValidationError> {
        if pattern.count < Limits.minimumFullNumberLength {
            return .failure(.fullNumberTooShort(pattern.count))
        }
        if pattern.count > Limits.maximumFullNumberLength {
            return .failure(.fullNumberTooLong(pattern.count))
        }
        guard let value = UInt64(pattern), value <= UInt64(Int64.max) else {
            return .failure(.expansionOverflow)
        }
        return .success(NumberSpan(first: value, last: value, count: 1))
    }

    static func range(for rule: BlockRule) -> Result<NumberRange, RuleValidationError> {
        switch rule.kind {
        case .prefix:
            return prefixSpan(pattern: rule.pattern, targetLength: rule.targetLength).map { span in
                NumberRange(lower: span.first, upper: span.last)
            }
        case .fullNumber:
            return fullNumberSpan(pattern: rule.pattern).map { span in
                NumberRange(lower: span.first, upper: span.last)
            }
        }
    }
}
