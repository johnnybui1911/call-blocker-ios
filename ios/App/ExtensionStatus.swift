import CallKit
import SwiftUI
import UIKit

@MainActor
final class ExtensionStatus: ObservableObject {
    enum Phase: Equatable {
        case unknown
        case enabled
        case disabled
        case failed(String)
    }

    @Published private(set) var phase: Phase = .unknown
    @Published var settingsNote: String?
    private let previewMode: Bool

    init(preview: Phase? = nil) {
        if let preview {
            previewMode = true
            phase = preview
        } else {
            previewMode = false
        }
    }

    func refresh() {
        guard !previewMode else { return }
        let identifier = SharedConfig.extensionBundleIdentifier
        guard SharedConfig.isConfigured(identifier) else {
            phase = .failed("Thiếu mã extension trong bản build.")
            return
        }
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: identifier) { status, error in
            Task { @MainActor in
                if let error {
                    self.phase = .failed(error.localizedDescription)
                    return
                }
                switch status {
                case .enabled:
                    self.phase = .enabled
                case .disabled:
                    self.phase = .disabled
                case .unknown:
                    self.phase = .unknown
                @unknown default:
                    self.phase = .unknown
                }
            }
        }
    }

    func openCallBlockingSettings() {
        guard !previewMode else { return }
        CXCallDirectoryManager.sharedInstance.openSettings { error in
            Task { @MainActor in
                if let error {
                    self.settingsNote = "Không mở thẳng được mục chặn cuộc gọi. Đã mở Cài đặt. Đi tiếp: Điện thoại > Chặn cuộc gọi & Nhận dạng."
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    _ = error.localizedDescription
                } else {
                    self.settingsNote = nil
                }
            }
        }
    }
}
