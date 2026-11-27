import SwiftUI
import UIKit

@main
struct ChanCuocGoiApp: App {
    @StateObject private var store = RuleStore()
    @StateObject private var status = ExtensionStatus()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(status)
                .tint(Theme.seal)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var status: ExtensionStatus

    var body: some View {
        TabView {
            RulesView()
                .tabItem { Label("Quy tắc", systemImage: "phone.down.fill") }
            GuideView()
                .tabItem { Label("Hướng dẫn", systemImage: "book.closed") }
        }
        .onAppear { status.refresh() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            status.refresh()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(RuleStore(preview: true))
            .environmentObject(ExtensionStatus(preview: .disabled))
            .tint(Theme.seal)
    }
}
