import BlockerCore
import SwiftUI
import UniformTypeIdentifiers

private struct ExportPayload: Identifiable {
    let id = UUID()
    let url: URL
}

private enum HomeSheet: Identifiable {
    case block(BlockNumberRoute)
    case setup

    var id: String {
        switch self {
        case .block(let route): return "block-" + route.id
        case .setup: return "setup"
        }
    }
}

/// Layout A "Lá chắn": one status, the blocked numbers, one "Chặn số" button.
struct HomeView: View {
    @EnvironmentObject private var store: RuleStore
    @EnvironmentObject private var status: ExtensionStatus
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(Appearance.storageKey) private var appearance = Appearance.system.rawValue

    /// Debug demo only: opens the sheet with this text typed in.
    var demoInput: String?

    @State private var sheet: HomeSheet?
    @State private var pendingDelete: BlockRule?
    @State private var importing = false
    @State private var pendingImport: [BlockRule]?
    @State private var exportPayload: ExportPayload?
    @State private var toastTask: Task<Void, Never>?

    private var homeStatus: HomeStatus {
        HomeStatus.resolve(
            blockingSwitch: status.blockingSwitch,
            listReachesSystem: store.usesAppGroup,
            numbersCovered: store.build.mergedCount
        )
    }

    var body: some View {
        List {
            Section {
                hero
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            if store.build.reachesSoftCap && !store.build.hardCapExceeded {
                Section {
                    Text(Vietnamese.softCapMessage)
                        .font(Theme.font(.subheadline))
                        .foregroundStyle(Theme.warnText)
                        .listRowBackground(Theme.surface)
                }
            }
            Section {
                if store.rules.isEmpty {
                    emptyState
                        .listRowBackground(Theme.surface)
                } else {
                    ForEach(store.rules) { rule in
                        row(rule)
                            .listRowBackground(Theme.surface)
                            .listRowSeparatorTint(Theme.hairline)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Bỏ chặn") { pendingDelete = rule }
                                    .tint(Theme.danger)
                                Button("Sửa") { sheet = .block(.edit(rule.id)) }
                                    .tint(Theme.muted)
                            }
                    }
                }
            } header: {
                Text("Số đang chặn (\(store.rules.count))")
                    .font(Theme.font(.subheadline, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .textCase(nil)
            } footer: {
                VStack(spacing: 6) {
                    if !store.rules.isEmpty {
                        Text("Vuốt một dòng sang trái để sửa hoặc bỏ chặn.")
                    }
                    Text("Số bạn chặn sẽ không làm máy đổ chuông.\nKhông cần tài khoản. Không đọc danh bạ.")
                }
                .font(Theme.font(.footnote))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.backdrop.ignoresSafeArea())
        .animation(reduceMotion ? nil : Theme.Motion.spring, value: store.rules)
        .safeAreaInset(edge: .top, spacing: 0) { topBar }
        .safeAreaInset(edge: .bottom, spacing: 0) { dock }
        .overlay(alignment: .top) { toast }
        .overlay(alignment: .top) {
            ConfettiBurst(trigger: reduceMotion ? 0 : store.blockedCount)
                .padding(.top, 150)
        }
        .onAppear {
            status.refresh()
            if let demoInput { sheet = .block(.create(prefill: demoInput)) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            status.refresh()
        }
        .onChange(of: store.banner) { scheduleToastDismissal(for: $0) }
        .onChange(of: store.blockedCount) { _ in Haptics.blocked() }
        .sheet(item: $sheet) { item in
            switch item {
            case .block(let route):
                BlockNumberSheet(route: route, focusOnAppear: demoInput == nil)
            case .setup:
                SetupSheet()
            }
        }
        .sheet(item: $exportPayload) { payload in
            ActivityView(items: [payload.url])
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json], onCompletion: importFile)
        .confirmationDialog(
            "Bỏ chặn \(pendingDelete.map(Vietnamese.name(for:)) ?? "")?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Bỏ chặn", role: .destructive) {
                if let pendingDelete { store.delete(pendingDelete.id) }
                pendingDelete = nil
            }
            Button("Giữ lại", role: .cancel) { pendingDelete = nil }
        }
        .confirmationDialog(
            "Thay danh sách hiện tại?",
            isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } }),
            titleVisibility: .visible
        ) {
            Button("Thay thế", role: .destructive) {
                if let pendingImport { store.replaceAll(with: pendingImport) }
                pendingImport = nil
            }
            Button("Hủy", role: .cancel) { pendingImport = nil }
        } message: {
            Text("Các số đang chặn sẽ được thay bằng danh sách trong tệp.")
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            Text("Chặn cuộc gọi")
                .font(Theme.font(.headline, weight: .heavy))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button(action: toggleAppearance) {
                circleIcon(colorScheme == .dark ? "sun.max.fill" : "moon.fill")
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(colorScheme == .dark ? "Chuyển sang giao diện sáng" : "Chuyển sang giao diện tối")
            Menu {
                Button { sheet = .setup } label: { Label("Cách bật chặn cuộc gọi", systemImage: "questionmark.circle") }
                Button(action: exportList) { Label("Sao lưu danh sách", systemImage: "square.and.arrow.up") }
                Button { importing = true } label: { Label("Khôi phục danh sách", systemImage: "square.and.arrow.down") }
                Picker("Giao diện", selection: $appearance) {
                    Text("Theo hệ thống").tag(Appearance.system.rawValue)
                    Text("Sáng").tag(Appearance.light.rawValue)
                    Text("Tối").tag(Appearance.dark.rawValue)
                }
            } label: {
                circleIcon("ellipsis")
            }
            .accessibilityLabel("Thêm tùy chọn")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private func circleIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(.body, design: .rounded).weight(.heavy))
            .foregroundStyle(Theme.protectedText)
            .frame(width: Theme.Size.touchTarget, height: Theme.Size.touchTarget)
            .background(Theme.surface, in: Circle())
            .shadow(color: Theme.shadow, radius: 8, y: 4)
    }

    private func toggleAppearance() {
        Haptics.tap()
        appearance = (colorScheme == .dark ? Appearance.light : Appearance.dark).rawValue
    }

    // MARK: Hero

    private struct HeroCopy {
        var title: String
        var detail: String
        var action: String?
    }

    private var heroCopy: HeroCopy {
        switch homeStatus {
        case .protecting:
            return HeroCopy(title: "Đang bảo vệ", detail: "Đang chặn \(Vietnamese.count(store.build.mergedCount)) số.")
        case .readyButEmpty:
            return HeroCopy(title: "Đã bật", detail: "Thêm số đầu tiên để bắt đầu chặn.")
        case .off:
            return HeroCopy(title: "Chưa bật chặn", detail: "Còn một bước trong Cài đặt để bắt đầu chặn.", action: "Bật ngay")
        case .unchecked:
            return HeroCopy(title: "Chưa kiểm tra được", detail: "Mở Cài đặt để xem chặn cuộc gọi đã bật chưa.", action: "Mở Cài đặt")
        case .listUnavailable:
            return HeroCopy(title: "Chưa chặn được", detail: "Bản cài thử này chưa chặn được cuộc gọi. Số bạn nhập vẫn được lưu.", action: "Xem chi tiết")
        }
    }

    private var isProtectedLook: Bool { homeStatus == .protecting || homeStatus == .readyButEmpty }

    private var hero: some View {
        let copy = heroCopy
        return VStack(spacing: 4) {
            ShieldView(isProtected: isProtectedLook, stampTrigger: store.blockedCount)
            Text(copy.title)
                .font(Theme.font(.title, weight: .heavy))
                .foregroundStyle(isProtectedLook ? Theme.protectedText : Theme.dangerText)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)
            Text(copy.detail)
                .font(Theme.font(.body))
                .foregroundStyle(Theme.muted)
                .monospacedDigit()
            if let action = copy.action {
                Button { sheet = .setup } label: {
                    Text(action)
                        .font(Theme.font(.headline, weight: .heavy))
                        .foregroundStyle(Theme.onDanger)
                        .padding(.horizontal, 24)
                        .frame(minHeight: 48)
                        .background(Theme.danger, in: Capsule())
                        .shadow(color: Theme.glowOff, radius: 12, y: 8)
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 12)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    // MARK: List

    private var emptyState: some View {
        VStack(spacing: 4) {
            Text("Chưa chặn số nào")
                .font(Theme.font(.headline, weight: .heavy))
                .foregroundStyle(Theme.ink)
            Text("Nhập một số, hoặc vài số đầu để chặn cả dải số.")
                .font(Theme.font(.subheadline))
                .foregroundStyle(Theme.muted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func row(_ rule: BlockRule) -> some View {
        let estimate = store.build.estimates.first { $0.id == rule.id }
        return HStack(spacing: 12) {
            Button { sheet = .block(.edit(rule.id)) } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Vietnamese.tag(for: rule))
                        .font(Theme.font(.caption2, weight: .heavy))
                        .foregroundStyle(Theme.tagInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Theme.tagBg, in: Capsule())
                    Text(Vietnamese.title(for: rule))
                        .font(Theme.font(.headline, weight: .heavy))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                    if estimate?.invalid == true {
                        Text("Đầu số này quá ngắn nên chưa được chặn. Chạm để sửa.")
                            .font(Theme.font(.footnote))
                            .foregroundStyle(Theme.dangerText)
                    } else if let detail = Vietnamese.detail(for: rule, count: estimate?.count ?? 0) {
                        Text(detail)
                            .font(Theme.font(.footnote))
                            .foregroundStyle(Theme.muted)
                            .monospacedDigit()
                    }
                    if !rule.note.isEmpty {
                        Text(rule.note)
                            .font(Theme.font(.footnote))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(rule.enabled ? 1 : 0.5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Chạm để sửa")

            Toggle(isOn: Binding(get: { rule.enabled }, set: { Haptics.tap(); store.setEnabled(rule.id, $0) })) {
                Text("Chặn")
            }
            .labelsHidden()
            .tint(Theme.accent)
            .accessibilityLabel("Chặn \(Vietnamese.name(for: rule))")
            .accessibilityValue(rule.enabled ? "Đang chặn" : "Tạm ngưng")
        }
        .padding(.vertical, 4)
    }

    // MARK: Dock and toast

    private var dock: some View {
        Button {
            Haptics.tap()
            sheet = .block(.create(prefill: ""))
        } label: {
            Text("Chặn số")
                .font(Theme.font(.headline, weight: .heavy))
                .frame(maxWidth: .infinity, minHeight: Theme.Size.buttonHeight)
                .foregroundStyle(Theme.onAccent)
                .background(Theme.accent, in: Capsule())
                .shadow(color: Theme.glowOn, radius: 14, y: 10)
        }
        .buttonStyle(PressableStyle())
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(LinearGradient(colors: [Theme.bg.opacity(0), Theme.bg], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.45)).ignoresSafeArea())
    }

    @ViewBuilder
    private var toast: some View {
        if let banner = store.banner {
            ToastView(banner: banner, onRetry: store.reloadFailed ? { store.reloadFromUser() } : nil)
                .padding(.top, 56)
                .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                .onTapGesture { store.banner = nil }
                .accessibilityAddTraits(.isStaticText)
        }
    }

    private func scheduleToastDismissal(for banner: RuleStore.Banner?) {
        toastTask?.cancel()
        guard let banner else { return }
        if case .error = banner { return } // Errors stay until the user reads and taps them.
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : Theme.Motion.fast) { store.banner = nil }
        }
    }

    // MARK: Backup and restore

    private func exportList() {
        do {
            exportPayload = ExportPayload(url: try store.exportFileURL())
        } catch {
            store.banner = .error("Không sao lưu được. \(error.localizedDescription)")
        }
    }

    private func importFile(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            store.banner = .error("Không mở được tệp. \(error.localizedDescription)")
        case .success(let url):
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            do {
                let decoded = try JSONDecoder().decode([BlockRule].self, from: Data(contentsOf: url))
                if store.rules.isEmpty {
                    store.replaceAll(with: decoded)
                } else {
                    pendingImport = decoded
                }
            } catch {
                store.banner = .error("Tệp này không phải bản sao lưu của Chặn cuộc gọi.")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(RuleStore(preview: true))
            .environmentObject(ExtensionStatus(preview: .disabled))
    }
}
