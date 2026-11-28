import BlockerCore
import SwiftUI
import UIKit

@main
struct ChanCuocGoiApp: App {
    @StateObject private var store: RuleStore
    @StateObject private var status: ExtensionStatus
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system.rawValue
    private let demoInput: String?
    private let demoAction: String?

    init() {
        let demo = DemoState.fromLaunchArguments()
        _store = StateObject(wrappedValue: demo?.store ?? RuleStore())
        _status = StateObject(wrappedValue: demo?.status ?? ExtensionStatus())
        demoInput = demo?.input
        demoAction = demo?.action
    }

    var body: some Scene {
        WindowGroup {
            HomeView(demoInput: demoInput, demoAction: demoAction)
                .environmentObject(store)
                .environmentObject(status)
                .tint(Theme.accent)
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
        }
    }
}

/// In-memory states for Simulator screenshots, where Call Directory does not run.
/// Debug builds only: `-demoState home|empty|off|add-full|add-prefix|add-empty|add-short|add-dup`.
@MainActor
struct DemoState {
    let store: RuleStore
    let status: ExtensionStatus
    let input: String?
    /// `block`, `unblock` or `fail`: performed once, shortly after launch.
    let action: String?

    static func fromLaunchArguments() -> DemoState? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-demoState"), arguments.indices.contains(flag + 1) else { return nil }
        let name = arguments[flag + 1]
        let rules = name == "empty" ? [] : sampleRules()
        let store = RuleStore(preview: true, previewRules: rules, previewReachesSystem: true)
        store.previewSaveFails = name == "act-fail"
        return DemoState(
            store: store,
            status: ExtensionStatus(preview: name == "off" ? .disabled : .enabled),
            input: name == "add-full" ? "028 3823 4567" : (name == "add-prefix" ? "028888" : (name == "add-empty" ? "" : (name == "add-short" ? "0288" : (name == "add-dup" ? "0283999" : nil)))),
            action: name.hasPrefix("act-") ? String(name.dropFirst(4)) : nil
        )
        #else
        return nil
        #endif
    }

    private static func sampleRules() -> [BlockRule] {
        let samples: [(String, String, Bool)] = [("0283999", "Tổng đài quảng cáo", true), ("0901234567", "Môi giới bất động sản", true), ("0247300", "", false)]
        return samples.compactMap { raw, note, enabled in
            let reading = NumberInput.interpret(raw)
            return try? RuleFactory.make(kind: reading.kind, rawInput: raw, targetLength: reading.targetLength, enabled: enabled, note: note).get()
        }
    }
}
