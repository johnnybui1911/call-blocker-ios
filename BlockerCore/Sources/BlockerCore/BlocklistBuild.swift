import Foundation

public struct RuleEstimate: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let count: UInt64
    public let enabled: Bool
    public let invalid: Bool

    public var reachesSoftCap: Bool {
        count >= Limits.softCap
    }
}

public struct BlocklistBuild: Equatable, Sendable {
    public let estimates: [RuleEstimate]
    /// Sum of enabled rules before overlap is removed.
    public let enabledSum: UInt64
    /// Numbers that will actually be written, after merge and dedup.
    public let mergedCount: UInt64
    public let ranges: [NumberRange]
    public let skippedRuleIDs: [UUID]

    public var reachesSoftCap: Bool {
        mergedCount >= Limits.softCap
    }

    public var hardCapExceeded: Bool {
        mergedCount > Limits.hardCap
    }

    public static func evaluate(rules: [BlockRule]) -> BlocklistBuild {
        var estimates: [RuleEstimate] = []
        var enabledRanges: [NumberRange] = []
        var skipped: [UUID] = []
        estimates.reserveCapacity(rules.count)

        for rule in rules {
            switch ExpansionMath.range(for: rule) {
            case .failure:
                skipped.append(rule.id)
                estimates.append(RuleEstimate(id: rule.id, count: 0, enabled: rule.enabled, invalid: true))
            case .success(let range):
                estimates.append(RuleEstimate(
                    id: rule.id,
                    count: range.count,
                    enabled: rule.enabled,
                    invalid: false
                ))
                if rule.enabled {
                    enabledRanges.append(range)
                }
            }
        }

        let merged = NumberRange.merge(enabledRanges)
        var mergedCount: UInt64 = 0
        var overflow = false
        for range in merged {
            let (sum, didOverflow) = mergedCount.addingReportingOverflow(range.count)
            if didOverflow {
                overflow = true
                break
            }
            mergedCount = sum
        }

        var enabledSum: UInt64 = 0
        for estimate in estimates where estimate.enabled && !estimate.invalid {
            let (sum, didOverflow) = enabledSum.addingReportingOverflow(estimate.count)
            if didOverflow {
                overflow = true
                break
            }
            enabledSum = sum
        }

        if overflow {
            mergedCount = UInt64.max
        }

        return BlocklistBuild(
            estimates: estimates,
            enabledSum: enabledSum,
            mergedCount: mergedCount,
            ranges: merged,
            skippedRuleIDs: skipped
        )
    }

    public func forEach(_ body: (UInt64) throws -> Void) rethrows {
        for range in ranges {
            var value = range.lower
            while true {
                try body(value)
                if value == range.upper { break }
                value += 1
            }
        }
    }
}
