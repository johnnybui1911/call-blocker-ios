import BlockerCore
import CallKit
import Foundation

enum Vietnamese {
    static func count(_ value: UInt64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func digits(_ value: UInt64) -> String {
        String(value)
    }

    static func message(for error: RuleValidationError) -> String {
        switch error {
        case .normalization(let normalizeError):
            return message(for: normalizeError)
        case .targetLengthOutOfRange:
            return "Độ dài E.164 phải từ \(Limits.minimumTargetLength) đến \(Limits.maximumTargetLength)."
        case .prefixTooShort:
            return "Đầu số phải có ít nhất \(Limits.minimumPrefixDigits) chữ số, tính cả số 0 đầu. Ví dụ 028888 hoặc 090123."
        case .prefixNotShorterThanTarget:
            return "Đầu số đã dài bằng hoặc hơn độ dài đích. Hãy chọn Số đầy đủ, hoặc tăng độ dài E.164."
        case .fullNumberTooShort(let length):
            return "Số đầy đủ quá ngắn sau khi chuẩn hóa (\(length) chữ số). Cần ít nhất \(Limits.minimumFullNumberLength) chữ số E.164."
        case .fullNumberTooLong(let length):
            return "Số đầy đủ dài \(length) chữ số. E.164 tối đa \(Limits.maximumFullNumberLength)."
        case .expansionExceedsHardCap(let count):
            return "Đầu số này tạo ra \(self.count(count)) số, vượt giới hạn \(self.count(Limits.hardCap)). Hãy nhập thêm chữ số hoặc giảm độ dài E.164."
        case .expansionOverflow:
            return "Không tính được dải số. Hãy rút ngắn khoảng cách giữa đầu số và độ dài đích."
        }
    }

    static func message(for error: NormalizeError) -> String {
        switch error {
        case .empty:
            return "Hãy nhập đầu số hoặc số điện thoại."
        case .invalidCharacters:
            return "Chỉ dùng chữ số, dấu +, khoảng trắng, dấu gạch, dấu chấm hoặc ngoặc."
        case .notVietnamese:
            return "Chỉ nhận số Việt Nam dạng 0…, 84…, +84… hoặc 0084…."
        case .tooLong:
            return "Số dài hơn \(Limits.maximumFullNumberLength) chữ số."
        }
    }

    static func reloadMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == CXErrorDomainCallDirectoryManager,
              let code = CXErrorCodeCallDirectoryManagerError.Code(rawValue: nsError.code) else {
            return "Không tải lại được extension. \(nsError.localizedDescription)"
        }
        switch code {
        case .unknown:
            return "CallKit báo lỗi không xác định khi tải lại extension."
        case .noExtensionFound:
            return "Không tìm thấy extension. Kiểm tra EXTENSION_BUNDLE_ID và đã cài app lên iPhone thật."
        case .loadingInterrupted:
            return "Việc tải danh sách bị gián đoạn. Hãy thử lại."
        case .entriesOutOfOrder:
            return "Danh sách không tăng dần. Đây là lỗi của app, chưa phải do quy tắc bạn nhập."
        case .duplicateEntries:
            return "Danh sách có số trùng. Đây là lỗi của app, chưa phải do quy tắc bạn nhập."
        case .maximumEntriesExceeded:
            return "iOS từ chối vì quá nhiều số. Hãy thu hẹp đầu số. Ngưỡng \(count(Limits.hardCap)) trong app chưa được đo trên máy này."
        case .extensionDisabled:
            return "Extension chưa được bật. Vào Cài đặt > Điện thoại > Chặn cuộc gọi & Nhận dạng."
        case .currentlyLoading:
            return "Extension đang tải. Đợi vài giây rồi thử lại."
        case .unexpectedIncrementalRemoval:
            return "iOS từ chối cập nhật danh sách. Hãy tải lại một lần nữa."
        @unknown default:
            return "Không tải lại được extension. \(nsError.localizedDescription)"
        }
    }

    static func hardCapMessage(count: UInt64) -> String {
        "Tổng số sau khi gộp là \(self.count(count)), vượt giới hạn \(self.count(Limits.hardCap)). Hãy tắt bớt quy tắc hoặc nhập đầu số dài hơn."
    }

    static var softCapMessage: String {
        "Danh sách đang bật có từ \(count(Limits.softCap)) số trở lên. iOS có thể tắt extension vì thiếu bộ nhớ hoặc hết thời gian. Nên thu hẹp đầu số. Ngưỡng này chưa được đo trên iPhone của bạn."
    }
}
