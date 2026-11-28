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
    /// True after the last attempt to hand the list to iOS failed, so the UI can offer a retry.
    @Published private(set) var reloadFailed = false
    /// Goes up each time a new number starts being blocked. The home screen answers with feedback.
    @Published private(set) var blockedCount = 0

    private let previewMode: Bool
    private var directory: URL?

    var usesAppGroup: Bool {
        if case .appGroup = storageKind { return true }
        return false
    }

    var expectedGroupID: String { SharedConfig.appGroupIdentifier }
    var extensionIdentifier: String { SharedConfig.extensionBundleIdentifier }

    /// - Parameters:
    ///   - preview: Keeps everything in memory. Used by previews and the debug demo state.
    ///   - previewRules: Starting list for a preview store.
    ///   - previewReachesSystem: Lets a preview store behave as if iOS could read its list.
    init(preview: Bool = false, previewRules: [BlockRule] = [], previewReachesSystem: Bool = false) {
        previewMode = preview
        if preview {
            storageKind = previewReachesSystem ? .appGroup : .localOnly(.turnedOffInBuild)
            directory = nil
            rules = previewRules
            build = BlocklistBuild.evaluate(rules: previewRules)
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
            banner = .error("Không đọc được danh sách đã lưu. \(error.localizedDescription)")
        }
        build = BlocklistBuild.evaluate(rules: rules)
        if usesAppGroup, !build.hardCapExceeded {
            try? writeBlocklist(build.ranges, in: directory)
        }
    }

    func upsert(_ rule: BlockRule) {
        // The same numbers must not appear twice, whichever way they were typed.
        guard rules.firstDuplicate(of: rule) == nil else {
            banner = .warning(Vietnamese.alreadyInList)
            return
        }
        var next = rules
        let isNew: Bool
        if let index = next.firstIndex(where: { $0.id == rule.id }) {
            next[index] = rule
            isNew = false
        } else {
            next.insert(rule, at: 0)
            isNew = true
        }
        let name = Vietnamese.name(for: rule)
        let blocksNow = isNew && rule.enabled
        let saved = commit(next, reloadAfterSave: true, success: blocksNow ? "Đã chặn \(name)." : "Đã lưu \(name).")
        if saved && blocksNow {
            blockedCount += 1
        }
    }

    func delete(_ id: UUID) {
        guard let rule = rules.first(where: { $0.id == id }) else { return }
        commit(rules.filter { $0.id != id }, reloadAfterSave: true, success: "Đã bỏ chặn \(Vietnamese.name(for: rule)).")
    }

    func setEnabled(_ id: UUID, _ enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == id }) else { return }
        guard rules[index].enabled != enabled else { return }
        var next = rules
        next[index].enabled = enabled
        let name = Vietnamese.name(for: next[index])
        commit(next, reloadAfterSave: true, success: enabled ? "Đang chặn \(name)." : "Đã tạm ngưng chặn \(name).")
    }

    func replaceAll(with imported: [BlockRule]) {
        let importedBuild = BlocklistBuild.evaluate(rules: imported)
        if importedBuild.hardCapExceeded {
            do {
                try persist(imported, publishBlocklist: false)
            } catch {
                banner = .error("Không khôi phục được. \(error.localizedDescription)")
                return
            }
            rules = imported
            build = importedBuild
            banner = .error(Vietnamese.hardCapMessage(count: importedBuild.mergedCount) + " Đã khôi phục danh sách nhưng chưa chặn số nào.")
            return
        }
        commit(imported, reloadAfterSave: true, success: "Đã khôi phục \(imported.count) số chặn.")
    }

    func exportFileURL() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("chan-cuoc-goi-sao-luu.json")
        try RuleArchive.save(rules, to: url)
        return url
    }

    func reloadFromUser() {
        reload(success: usesAppGroup ? "Đã cập nhật danh sách chặn." : Vietnamese.localOnlySaved, quietPersonalTeamFailure: false)
    }

    @discardableResult
    private func commit(_ next: [BlockRule], reloadAfterSave: Bool, success: String) -> Bool {
        let nextBuild = BlocklistBuild.evaluate(rules: next)
        if nextBuild.hardCapExceeded {
            banner = .error(Vietnamese.hardCapMessage(count: nextBuild.mergedCount))
            return false
        }
        if previewMode {
            rules = next
            build = nextBuild
            banner = .success(success)
            return true
        }
        do {
            try persist(next, publishBlocklist: usesAppGroup)
        } catch {
            banner = .error("Không lưu được. \(error.localizedDescription)")
            return false
        }
        rules = next
        build = nextBuild
        guard reloadAfterSave else {
            banner = .success(success)
            return true
        }
        if usesAppGroup {
            reload(success: success, quietPersonalTeamFailure: false)
        } else {
            reload(success: Vietnamese.localOnlySaved, quietPersonalTeamFailure: true)
        }
        return true
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
            banner = .error("Bản cài này thiếu cấu hình chặn cuộc gọi.")
            return
        }
        isReloading = true
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: identifier) { error in
            Task { @MainActor in
                self.isReloading = false
                self.reloadFailed = error != nil && self.usesAppGroup
                if let error {
                    if quietPersonalTeamFailure || !self.usesAppGroup {
                        self.banner = .warning(Vietnamese.localOnlySaved)
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
            banner = .warning("Chưa chuyển được danh sách cũ sang bản cài mới. \(error.localizedDescription)")
        }
    }
}

private enum StoreError: LocalizedError {
    case missingDirectory

    var errorDescription: String? {
        "Không có chỗ lưu danh sách chặn."
    }
}
