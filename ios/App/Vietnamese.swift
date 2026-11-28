import BlockerCore
import CallKit
import Foundation

/// User-facing Vietnamese copy. The words "quy tắc", "extension", "CallKit" and
/// "E.164" stay out of anything a user reads.
enum Vietnamese {
    static func count(_ value: UInt64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// `028 888…` for a range, `090 123 4567` for one number.
    static func title(for rule: BlockRule) -> String {
        let number = NumberDisplay.formatted(pattern: rule.pattern)
        return rule.kind == .prefix ? number + "…" : number
    }

    static func name(for rule: BlockRule) -> String {
        NumberDisplay.formatted(pattern: rule.pattern)
    }

    static func tag(for rule: BlockRule) -> String {
        rule.kind == .prefix ? "Đầu số" : "Một số"
    }

    static func detail(for rule: BlockRule, count: UInt64) -> String? {
        guard rule.kind == .prefix else { return nil }
        return "\(self.count(count)) số bắt đầu bằng \(name(for: rule))"
    }

    static func message(for error: RuleValidationError) -> String {
        switch error {
        case .normalization(let normalizeError):
            return message(for: normalizeError)
        case .targetLengthOutOfRange:
            return "Độ dài số phải từ \(Limits.minimumTargetLength - 1) đến \(Limits.maximumTargetLength - 1) chữ số."
        case .prefixTooShort:
            return "Nhập ít nhất \(Limits.minimumPrefixDigits) số đầu, ví dụ 028 888. iPhone không cho chặn dải số rộng hơn."
        case .prefixNotShorterThanTarget:
            return "Số này đã đủ dài. Chọn “Một số” trong phần Nâng cao, hoặc tăng độ dài số."
        case .fullNumberTooShort:
            return "Số này còn thiếu chữ số."
        case .fullNumberTooLong:
            return "Số này dài quá. Kiểm tra lại giúp nhé."
        case .expansionExceedsHardCap:
            return "Dải số này quá lớn. Nhập thêm chữ số để thu hẹp."
        case .expansionOverflow:
            return "Dải số này quá lớn. Nhập thêm chữ số để thu hẹp."
        }
    }

    static func message(for error: NormalizeError) -> String {
        switch error {
        case .empty:
            return "Nhập số bạn muốn chặn."
        case .invalidCharacters:
            return "Số điện thoại chỉ gồm chữ số."
        case .notVietnamese:
            return "Hiện chỉ chặn được số Việt Nam (bắt đầu bằng 0 hoặc +84)."
        case .tooLong:
            return "Số này dài quá. Kiểm tra lại giúp nhé."
        }
    }

    static func reloadMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == CXErrorDomainCallDirectoryManager,
              let code = CXErrorCodeCallDirectoryManagerError.Code(rawValue: nsError.code) else {
            return "Chưa cập nhật được danh sách chặn. Chạm “Thử lại”."
        }
        switch code {
        case .unknown:
            return "Chưa cập nhật được danh sách chặn. Chạm “Thử lại”."
        case .noExtensionFound:
            return "Bản cài này thiếu phần chặn cuộc gọi. Hãy cài lại ứng dụng."
        case .loadingInterrupted:
            return "Cập nhật chưa xong. Chạm “Thử lại”."
        case .entriesOutOfOrder, .duplicateEntries:
            return "Có lỗi từ phía ứng dụng. Số của bạn vẫn được lưu. Chạm “Thử lại”."
        case .maximumEntriesExceeded:
            return "iPhone không nhận vì danh sách quá lớn. Bỏ bớt dải số rồi thử lại."
        case .extensionDisabled:
            return "Chưa bật chặn cuộc gọi trong Cài đặt. Chạm “Bật ngay”."
        case .currentlyLoading:
            return "Đang cập nhật danh sách. Đợi vài giây nhé."
        case .unexpectedIncrementalRemoval:
            return "Cập nhật chưa xong. Chạm “Thử lại”."
        @unknown default:
            return "Chưa cập nhật được danh sách chặn. Chạm “Thử lại”."
        }
    }

    static func hardCapMessage(count: UInt64) -> String {
        "Danh sách đã đầy (\(self.count(count))/\(self.count(Limits.hardCap)) số). Bỏ bớt một dải số rồi thử lại."
    }

    static var softCapMessage: String {
        "Danh sách đang rất lớn. Nếu thấy chặn không ổn định, hãy bỏ bớt dải số."
    }

    static let localOnlySaved = "Đã lưu trên máy. Bản cài thử này chưa chặn được cuộc gọi."
}
