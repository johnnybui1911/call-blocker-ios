import BlockerCore
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

    /// The state in the platform-neutral form the home status is built from.
    var blockingSwitch: BlockingSwitch {
        switch phase {
        case .enabled: return .on
        case .disabled: return .off
        case .unknown, .failed: return .unknown
        }
    }

    func refresh() {
        guard !previewMode else { return }
        let identifier = SharedConfig.extensionBundleIdentifier
        guard SharedConfig.isConfigured(identifier) else {
            phase = .failed("Bản cài này thiếu cấu hình chặn cuộc gọi.")
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
                    self.settingsNote = "Đã mở Cài đặt. Đi tiếp: Điện thoại, rồi Chặn cuộc gọi & Nhận dạng."
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
