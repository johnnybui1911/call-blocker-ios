import Foundation

enum LocalOnlyReason: Equatable {
    /// ENABLE_APP_GROUPS = NO in Signing.xcconfig.
    case turnedOffInBuild
    /// The entitlement was compiled in, but iOS did not hand back a container.
    case containerUnavailable
    case missingConfiguration
}

enum SharedConfig {
    static var appGroupIdentifier: String {
        string("AppGroupIdentifier")
    }

    static var extensionBundleIdentifier: String {
        string("ExtensionBundleIdentifier")
    }

    /// Build setting ENABLE_APP_GROUPS, baked into Info.plist as YES or NO.
    static var appGroupsBuildEnabled: Bool {
        let value = string("AppGroupsBuildEnabled").trimmingCharacters(in: .whitespacesAndNewlines)
        return value == "YES" || value == "true" || value == "1"
    }

    static func isConfigured(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.contains("$(") && !trimmed.contains("${")
    }

    /// Application Support of *this* process. Only the host app should use it
    /// for rule files. The extension has a different sandbox.
    static func localDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("ChanCuocGoi", isDirectory: true)
    }

    static func appGroupContainer() -> URL? {
        let groupID = appGroupIdentifier
        guard isConfigured(groupID) else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    private static func string(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}
