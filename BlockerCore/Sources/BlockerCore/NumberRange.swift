import Foundation

public struct NumberRange: Equatable, Sendable {
    public let lower: UInt64
    public let upper: UInt64

    public init(lower: UInt64, upper: UInt64) {
        precondition(lower <= upper, "Number range is inverted")
        self.lower = lower
        self.upper = upper
    }

    public var count: UInt64 {
        upper - lower + 1
    }

    /// Merge overlapping and adjacent ranges. The result is strictly ascending
    /// and contains each number at most once.
    public static func merge(_ input: [NumberRange]) -> [NumberRange] {
        let sorted = input.sorted { lhs, rhs in
            if lhs.lower != rhs.lower { return lhs.lower < rhs.lower }
            return lhs.upper < rhs.upper
        }
        var result: [NumberRange] = []
        result.reserveCapacity(sorted.count)
        for range in sorted {
            guard let last = result.last else {
                result.append(range)
                continue
            }
            let touches: Bool
            if last.upper == UInt64.max {
                touches = true
            } else {
                touches = range.lower <= last.upper + 1
            }
            if touches {
                if range.upper > last.upper {
                    result[result.count - 1] = NumberRange(lower: last.lower, upper: range.upper)
                }
            } else {
                result.append(range)
            }
        }
        return result
    }
}
