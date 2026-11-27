import SwiftUI
import UIKit

struct StatusCard: View {
    @EnvironmentObject private var status: ExtensionStatus
    @EnvironmentObject private var store: RuleStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            if store.usesAppGroup {
                Text("Danh sách nằm trong App Group, extension đọc được.")
                    .font(.footnote)
                    .foregroundStyle(Theme.ok)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch status.phase {
        case .enabled:
            return "Đã bật"
        case .disabled:
            return "Chưa bật"
        case .unknown:
            return "Chưa rõ"
        case .failed:
            return "Không đọc được"
        }
    }

    private var detail: String {
        switch status.phase {
        case .enabled:
            return store.usesAppGroup
                ? "iOS đang dùng extension này cho cuộc gọi đến."
                : "Extension đang bật, nhưng danh sách đang trống vì chưa có App Group."
        case .disabled:
            return "Vào Cài đặt > Điện thoại > Chặn cuộc gọi & Nhận dạng và bật công tắc của app."
        case .unknown:
            return "Chưa xác định được. Hãy mở Cài đặt và kiểm tra công tắc."
        case .failed(let message):
            return message
        }
    }

    private var color: Color {
        switch status.phase {
        case .enabled:
            return Theme.ok
        case .disabled, .failed:
            return Theme.seal
        case .unknown:
            return Theme.warn
        }
    }
}

struct GuideView: View {
    @EnvironmentObject private var status: ExtensionStatus
    @EnvironmentObject private var store: RuleStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Bật chặn cuộc gọi")
                        .font(.system(.largeTitle, design: .serif))
                        .foregroundStyle(Theme.ink)
                    Text("Call Directory chỉ có tác dụng trên iPhone thật, sau khi bạn bật extension trong Cài đặt. Simulator không chặn cuộc gọi.")
                        .foregroundStyle(Theme.muted)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trạng thái")
                            .font(.headline)
                        StatusCard()
                        if let note = status.settingsNote {
                            Text(note)
                                .font(.footnote)
                                .foregroundStyle(Theme.warn)
                        }
                        Button(action: status.openCallBlockingSettings) {
                            Text("Mở phần Chặn cuộc gọi")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Button(action: openAppSettings) {
                            Text("Mở Cài đặt của app")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(16)
                    .background(card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Trong Cài đặt")
                            .font(.headline)
                        step("1", "Mở ứng dụng Cài đặt.")
                        step("2", "Chọn Điện thoại.")
                        step("3", "Chọn Chặn cuộc gọi & Nhận dạng.")
                        step("4", "Bật công tắc cạnh “Chặn cuộc gọi”.")
                        Text("Sau khi sửa quy tắc, app gọi tải lại extension. Nếu trạng thái vẫn là Chưa bật, cuộc gọi không bị chặn.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(16)
                    .background(card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Personal Team và App Group")
                            .font(.headline)
                        Text("Extension và app là hai tiến trình. iOS chỉ cho extension đọc danh sách nếu cả hai cùng một App Group. Không có cách khác (Keychain dùng chung cũng cần tài khoản trả phí).")
                            .foregroundStyle(Theme.ink)
                        Text("Tài khoản Apple ID miễn phí (Personal Team) thường không ký được capability App Groups, dù trang capability của Apple hiện có cột cho tài khoản miễn phí. Khi ký lỗi, giữ ENABLE_APP_GROUPS = NO trong Config/Signing.xcconfig. App vẫn cài được, quy tắc lưu trên máy, và extension nạp danh sách trống — chưa chặn cuộc gọi.")
                            .foregroundStyle(Theme.ink)
                        Text("Trước khi xóa app để đổi sang team trả phí, mở tab Quy tắc, menu …, chọn Xuất quy tắc. Cài lại rồi Nhập quy tắc.")
                            .foregroundStyle(Theme.ink)
                        if SharedConfig.isConfigured(store.expectedGroupID) {
                            Text("App Group dự kiến")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.muted)
                            Text(store.expectedGroupID)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                        if SharedConfig.isConfigured(store.extensionIdentifier) {
                            Text("Bundle ID extension")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.muted)
                            Text(store.extensionIdentifier)
                                .font(.system(.footnote, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    .padding(16)
                    .background(card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text("Chặn im lặng là hành vi của Call Directory: máy không đổ chuông. App không xem lịch sử cuộc gọi và không lưu số đã chặn.")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                }
                .padding(20)
            }
            .background(Theme.background)
            .navigationTitle("Hướng dẫn")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var card: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1)
                : UIColor(red: 0.995, green: 0.988, blue: 0.973, alpha: 1)
        })
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(number)
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.seal)
                .frame(width: 24, alignment: .leading)
            Text(text)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
