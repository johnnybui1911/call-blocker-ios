import BlockerCore
import SwiftUI
import UIKit

/// How to turn call blocking on in Settings, shown from the home screen when it is off
/// and from the menu afterwards. Developer details sit in a collapsed section.
struct SetupSheet: View {
    @EnvironmentObject private var status: ExtensionStatus
    @EnvironmentObject private var store: RuleStore
    @Environment(\.dismiss) private var dismiss

    private var isOn: Bool { status.phase == .enabled && store.usesAppGroup }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isOn {
                        done
                    } else {
                        steps
                    }
                    Text("Không cần tài khoản. Không đọc danh bạ hay lịch sử cuộc gọi. Mọi thứ nằm trên máy bạn.")
                        .font(Theme.font(.footnote))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    technical
                }
                .padding(20)
            }
            .background(Theme.sheet.ignoresSafeArea())
            .navigationTitle("Bật chặn cuộc gọi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { CircleIcon(systemName: "xmark", title: "Đóng") }
                        .buttonStyle(PressableStyle())
                }
            }
            .onAppear { status.refresh() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                status.refresh()
            }
        }
        .tint(Theme.protectedText)
        .presentationDetents([.large])
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !store.usesAppGroup {
                Text("Bản cài thử này chưa chặn được cuộc gọi. Số bạn nhập vẫn được lưu. Xem Thông tin kỹ thuật bên dưới.")
                    .font(Theme.font(.subheadline, weight: .semibold))
                    .foregroundStyle(Theme.warnText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("iPhone cần bạn cho phép một lần. Mất khoảng 10 giây.")
                .font(Theme.font(.subheadline))
                .foregroundStyle(Theme.muted)
            step(1, "Chạm “Mở Cài đặt” bên dưới.")
            step(2, "Chọn Điện thoại (iOS 18 trở lên: Ứng dụng, rồi Điện thoại).")
            step(3, "Chọn Chặn cuộc gọi & Nhận dạng.")
            step(4, "Bật công tắc “Chặn cuộc gọi”, rồi quay lại đây.")
            if let note = status.settingsNote {
                Text(note)
                    .font(Theme.font(.footnote))
                    .foregroundStyle(Theme.warnText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: status.openCallBlockingSettings) {
                Text("Mở Cài đặt")
                    .font(Theme.font(.headline, weight: .heavy))
                    .frame(maxWidth: .infinity, minHeight: Theme.Size.buttonHeight)
                    .foregroundStyle(Theme.onAccent)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 8)
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(Theme.font(.subheadline, weight: .heavy))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 28, height: 28)
                .background(Theme.accent, in: Circle())
            Text(text)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.field, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var done: some View {
        VStack(spacing: 8) {
            ShieldView(isProtected: true, stampTrigger: 0)
            Text("Đã bật")
                .font(Theme.font(.title2, weight: .heavy))
                .foregroundStyle(Theme.protectedText)
            Text("Máy sẽ không đổ chuông với số bạn chặn.")
                .font(Theme.font(.body))
                .foregroundStyle(Theme.ink)
            Text("Muốn kiểm tra? Chặn số của một máy khác rồi gọi thử.")
                .font(Theme.font(.subheadline))
                .foregroundStyle(Theme.muted)
            Button(action: { dismiss() }) {
                Text("Xong")
                    .font(Theme.font(.headline, weight: .heavy))
                    .frame(maxWidth: .infinity, minHeight: Theme.Size.buttonHeight)
                    .foregroundStyle(Theme.onAccent)
                    .background(Theme.accent, in: Capsule())
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 12)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    /// For whoever builds and signs the app. Technical terms are allowed here only.
    private var technical: some View {
        DisclosureGroup("Thông tin kỹ thuật") {
            VStack(alignment: .leading, spacing: 8) {
                detail("Trạng thái hệ thống", phaseText)
                detail("Nơi lưu danh sách", storageText)
                if SharedConfig.isConfigured(store.expectedGroupID) {
                    detail("App Group", store.expectedGroupID)
                }
                if SharedConfig.isConfigured(store.extensionIdentifier) {
                    detail("Bundle ID extension", store.extensionIdentifier)
                }
                Text("Call Directory chỉ chạy trên iPhone thật. Bản ký bằng Personal Team thường không có App Group, nên extension không đọc được danh sách. Trước khi xóa app để đổi team, dùng Sao lưu danh sách trong menu.")
                    .font(Theme.font(.footnote))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)
        }
        .font(Theme.font(.subheadline, weight: .semibold))
    }

    private func detail(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(Theme.font(.caption))
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(Theme.ink)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var phaseText: String {
        switch status.phase {
        case .enabled: return "Đã bật"
        case .disabled: return "Chưa bật"
        case .unknown: return "Chưa rõ"
        case .failed(let message): return "Không đọc được: \(message)"
        }
    }

    private var storageText: String {
        switch store.storageKind {
        case .appGroup:
            return "App Group, extension đọc được."
        case .localOnly(.turnedOffInBuild):
            return "Trên máy (ENABLE_APP_GROUPS = NO). Extension không đọc được."
        case .localOnly(.containerUnavailable):
            return "Trên máy. Đã bật App Group nhưng iOS không mở được container; kiểm tra capability của app và extension."
        case .localOnly(.missingConfiguration):
            return "Trên máy. Chưa đọc được APP_GROUP_ID; kiểm tra Config/Signing.xcconfig."
        }
    }
}
