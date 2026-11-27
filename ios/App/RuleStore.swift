import BlockerCore
import CallKit
import Foundation
import SwiftUI

enum RuleStorageKind: Equatable {
    case appGroup
    case localOnly(LocalOnlyReason)
}

@MainActor
final class RuleStore: ObservableObject {
    enum Banner: Equatable {
        case error(String)
        case success(String)
        case warning(String)
    }

    @Published private(set) var rules: [BlockRule] = []
    @Published private(set) var build: BlocklistBuild = .evaluate(rules: [])
    @Published private(set) var storageKind: RuleStorageKind = .localOnly(.turnedOffInBuild)
    @Published var banner: Banner?
    @Published private(set) var isReloading = false

    private let previewMode: Bool
    private var directory: URL?

    var usesAppGroup: Bool {
        if case .appGroup = storageKind { return true }
        return false
    }

    var expectedGroupID: String { SharedConfig.appGroupIdentifier }
    var extensionIdentifier: String { SharedConfig.extensionBundleIdentifier }

    init(preview: Bool = false) {
        previewMode = preview
        if preview {
            storageKind = .localOnly(.turnedOffInBuild)
            directory = nil
            return
        }

        let local = SharedConfig.localDirectory()
        if let container = SharedConfig.appGroupContainer() {
            migrateLocalRulesIfNeeded(into: container, from: local)
            directory = container
            storageKind = .appGroup
        } else if !SharedConfig.isConfigured(SharedConfig.appGroupIdentifier) {
            directory = local
            storageKind = .localOnly(.missingConfiguration)
        } else if SharedConfig.appGroupsBuildEnabled {
            directory = local
            storageKind = .localOnly(.containerUnavailable)
        } else {
            directory = local
            storageKind = .localOnly(.turnedOffInBuild)
        }

        guard let directory else { return }
        do {
            rules = try RuleArchive.loadIfPresent(from: directory.appendingPathComponent(RuleArchive.fileName))
        } catch {
            rules = []
            banner = .error("Không đọc được tệp quy tắc. \(error.localizedDescription)")
        }
        build = BlocklistBuild.evaluate(rules: rules)
        if usesAppGroup, !build.hardCapExceeded {
            try? writeBlocklist(build.ranges, in: directory)
        }
    }

    func upsert(_ rule: BlockRule) {
        var next = rules
        if let index = next.firstIndex(where: { $0.id == rule.id }) {
            next[index] = rule
        } else {
            next.insert(rule, at: 0)
        }
        commit(next, reloadAfterSave: true, success: "Đã lưu quy tắc.")
    }

    func delete(_ id: UUID) {
        commit(rules.filter { $0.id != id }, reloadAfterSave: true, success: "Đã xóa quy tắc.")
    }

    func setEnabled(_ id: UUID, _ enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        guard rules[index].enabled != enabled else { return }
        var next = rules
        next[index].enabled = enabled
        commit(next, reloadAfterSave: true, success: enabled ? "Đã bật quy tắc." : "Đã tắt quy tắc.")
    }

    func replaceAll(with imported: [BlockRule]) {
        let importedBuild = BlocklistBuild.evaluate(rules: imported)
        if importedBuild.hardCapExceeded {
            do {
                try persist(imported, publishBlocklist: false)
            } catch {
                banner = .error("Không nhập được. \(error.localizedDescription)")
                return
            }
            rules = imported
            build = importedBuild
            banner = .error(Vietnamese.hardCapMessage(count: importedBuild.mergedCount) + " Đã nhập quy tắc nhưng chưa ghi danh sách chặn.")
            return
        }
        commit(imported, reloadAfterSave: true, success: "Đã nhập \(imported.count) quy tắc.")
    }

    func exportFileURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("quy-tac-chan-cuoc-goi.json")
        try RuleArchive.save(rules, to: url)
        return url
    }

    func reloadFromUser() {
        let success = usesAppGroup
            ? "Đã nạp danh sách vào CallKit."
            : "Extension đã tải lại với danh sách trống. Chưa chặn cuộc gọi vì chưa có App Group."
        reload(success: success, quietPersonalTeamFailure: false)
    }

    private func commit(_ next: [BlockRule], reloadAfterSave: Bool, success: String) {
        let nextBuild = BlocklistBuild.evaluate(rules: next)
        if nextBuild.hardCapExceeded {
            banner = .error(Vietnamese.hardCapMessage(count: nextBuild.mergedCount))
            return
        }
        if previewMode {
            rules = next
            build = nextBuild
            banner = .success(success)
            return
        }
        do {
            try persist(next, publishBlocklist: usesAppGroup)
        } catch {
            banner = .error("Không ghi được dữ liệu. \(error.localizedDescription)")
            return
        }
        rules = next
        build = nextBuild
        guard reloadAfterSave else {
            banner = .success(success)
            return
        }
        if usesAppGroup {
            reload(success: success, quietPersonalTeamFailure: false)
        } else {
            reload(
                success: "Đã lưu trên máy. Chưa chặn được cuộc gọi vì chưa có App Group.",
                quietPersonalTeamFailure: true
            )
        }
    }

    private func persist(_ next: [BlockRule], publishBlocklist: Bool) throws {
        guard let directory else {
            throw StoreError.missingDirectory
        }
        let rulesURL = directory.appendingPathComponent(RuleArchive.fileName)
        try RuleArchive.save(next, to: rulesURL)
        loosenProtection(rulesURL)
        if publishBlocklist {
            try writeBlocklist(BlocklistBuild.evaluate(rules: next).ranges, in: directory)
        }
    }

    private func writeBlocklist(_ ranges: [NumberRange], in directory: URL) throws {
        let url = directory.appendingPathComponent(BlocklistFile.fileName)
        try BlocklistFile.write(ranges: ranges, to: url)
        loosenProtection(url)
    }

    private func loosenProtection(_ url: URL) {
        // The extension must be able to read the list after a reboot, before
        // the first unlock. Device encryption still covers the phone when it is off.
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.none],
            ofItemAtPath: url.path
        )
    }

    private func reload(success: String, quietPersonalTeamFailure: Bool) {
        let identifier = SharedConfig.extensionBundleIdentifier
        guard SharedConfig.isConfigured(identifier) else {
            banner = .error("Thiếu mã extension. Kiểm tra Config/Signing.xcconfig.")
            return
        }
        isReloading = true
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: identifier) { error in
            Task { @MainActor in
                self.isReloading = false
                if let error {
                    if quietPersonalTeamFailure {
                        self.banner = .warning("Đã lưu trên máy. Extension không đọc được danh sách này, nên chưa chặn cuộc gọi.")
                    } else if !self.usesAppGroup {
                        self.banner = .error("Chưa có App Group nên danh sách extension đang trống. \(Vietnamese.reloadMessage(for: error))")
                    } else {
                        self.banner = .error(Vietnamese.reloadMessage(for: error))
                    }
                } else {
                    self.banner = .success(success)
                }
            }
        }
    }

    private func migrateLocalRulesIfNeeded(into container: URL, from local: URL) {
        let destination = container.appendingPathComponent(RuleArchive.fileName)
        let source = local.appendingPathComponent(RuleArchive.fileName)
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: destination.path),
              fileManager.fileExists(atPath: source.path) else {
            return
        }
        do {
            try fileManager.createDirectory(at: container, withIntermediateDirectories: true)
            try fileManager.copyItem(at: source, to: destination)
        } catch {
            banner = .warning("Không copy được quy tắc cục bộ sang App Group. \(error.localizedDescription)")
        }
    }
}

private enum StoreError: LocalizedError {
    case missingDirectory

    var errorDescription: String? {
        "Không có thư mục lưu quy tắc."
    }
}
