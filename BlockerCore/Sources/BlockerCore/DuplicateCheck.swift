import Foundation

public extension BlockRule {
    /// True when both entries block exactly the same numbers, however they were typed.
    /// `028888` and `+84 28888` match; a prefix and a single number never do.
    /// An entry that does not expand to a valid range matches nothing.
    func blocksSameNumbers(as other: BlockRule) -> Bool {
        guard case .success(let mine) = ExpansionMath.range(for: self),
              case .success(let theirs) = ExpansionMath.range(for: other) else {
            return false
        }
        return mine == theirs
    }
}

public extension Sequence where Element == BlockRule {
    /// The entry already in the list that blocks the same numbers as `rule`, if any.
    /// The entry being edited (same id) does not count as its own duplicate.
    func firstDuplicate(of rule: BlockRule) -> BlockRule? {
        first { $0.id != rule.id && $0.blocksSameNumbers(as: rule) }
    }
}
