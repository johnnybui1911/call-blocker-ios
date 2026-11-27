import BlockerCore
import SwiftUI
import UniformTypeIdentifiers

private struct ExportPayload: Identifiable {
    let id = UUID()
    let url: URL
}

struct RulesView: View {
    @EnvironmentObject private var store: RuleStore
    @EnvironmentObject private var status: ExtensionStatus
    @State private var editor: RuleEditorRoute?
    @State private var pendingDelete: UUID?
    @State private var importing = false
    @State private var pendingImport: [BlockRule]?
    @State private var exportPayload: ExportPayload?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Chặn cuộc gọi")
                            .font(.system(.largeTitle, design: .serif))
                            .foregroundStyle(Theme.ink)
                        Text("Chặn im lặng theo đầu số hoặc số đầy đủ. Máy không đổ chuông với số khớp quy tắc đang bật.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                if let reason = localReason {
                    Section {
                        StorageNotice(reason: reason, groupID: store.expectedGroupID)
                    }
                }

                if store.build.reachesSoftCap && !store.build.hardCapExceeded {
                    Section {
                        NoticeText(text: Vietnamese.softCapMessage, tint: Theme.warn)
                    }
                }

                if let banner = store.banner {
                    Section {
                        NoticeText(text: banner.text, tint: banner.tint)
                    }
                }

                Section {
                    StatusCard()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Đang chặn")
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                            Text("\(Vietnamese.count(store.build.mergedCount)) số")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(Theme.ink)
                        }
                        Spacer()
                        if store.build.enabledSum != store.build.mergedCount {
                            Text("Gộp từ \(Vietnamese.count(store.build.enabledSum))")
                                .font(.footnote)
                                .foregroundStyle(Theme.muted)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }

                Section("Quy tắc") {
                    if store.rules.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Chưa có quy tắc")
                                .font(.headline)
                            Text("Thêm một đầu số hoặc một số đầy đủ. Khi mọi quy tắc đều tắt, danh sách chặn để trống và không số nào bị chặn.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 6)
                    } else {
                        ForEach(store.rules) { rule in
                            ruleRow(rule)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        pendingDelete = rule.id
                                    } label: {
                                        Text("Xóa")
                                    }
                                    Button {
                                        editor = .edit(rule.id)
                                    } label: {
                                        Text("Sửa")
                                    }
                                    .tint(Theme.seal)
                                }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Quy tắc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            exportRules()
                        } label: {
                            Label("Xuất quy tắc…", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            importing = true
                        } label: {
                            Label("Nhập quy tắc…", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Xuất hoặc nhập quy tắc")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editor = .create
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Thêm quy tắc")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                reloadBar
            }
            .sheet(item: $editor) { route in
                RuleEditorView(route: route)
            }
            .sheet(item: $exportPayload) { payload in
                ActivityView(items: [payload.url])
            }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                importFile(result)
            }
            .confirmationDialog("Xóa quy tắc này?", isPresented: deletePresented, titleVisibility: .visible) {
                Button("Xóa", role: .destructive) {
                    if let pendingDelete {
                        store.delete(pendingDelete)
                    }
                    pendingDelete = nil
                }
                Button("Hủy", role: .cancel) {
                    pendingDelete = nil
                }
            }
            .confirmationDialog("Thay toàn bộ quy tắc hiện có?", isPresented: importPresented, titleVisibility: .visible) {
                Button("Thay thế", role: .destructive) {
                    if let pendingImport {
                        store.replaceAll(with: pendingImport)
                    }
                    pendingImport = nil
                }
                Button("Hủy", role: .cancel) {
                    pendingImport = nil
                }
            } message: {
                Text("File JSON sẽ thay danh sách đang có trên máy này.")
            }
        }
    }

    private var localReason: LocalOnlyReason? {
        if case .localOnly(let reason) = store.storageKind { return reason }
        return nil
    }

    private var deletePresented: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }

    private var importPresented: Binding<Bool> {
        Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } })
    }

    private var reloadBar: some View {
        VStack(spacing: 6) {
            Button(action: store.reloadFromUser) {
                Text(store.isReloading ? "Đang tải lại…" : "Tải lại danh sách chặn")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isReloading)
            Text(store.usesAppGroup
                 ? "\(Vietnamese.count(store.build.mergedCount)) số sẽ được nạp vào CallKit."
                 : "Extension sẽ nhận danh sách trống cho đến khi có App Group.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func ruleRow(_ rule: BlockRule) -> some View {
        let estimate = store.build.estimates.first { $0.id == rule.id }
        HStack(alignment: .center, spacing: 12) {
            Button {
                editor = .edit(rule.id)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.kind == .prefix ? "Đầu số" : "Số đầy đủ")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.seal)
                    Text(rule.rawInput)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    Text(detail(rule: rule, estimate: estimate))
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if !rule.note.isEmpty {
                        Text(rule.note)
                            .font(.footnote)
                            .foregroundStyle(Theme.ink.opacity(0.8))
                    }
                    if estimate?.invalid == true {
                        Text("Quy tắc không hợp lệ và không được đưa vào danh sách.")
                            .font(.footnote)
                            .foregroundStyle(Theme.seal)
                    } else if estimate?.reachesSoftCap == true {
                        Text("Nhiều số — dễ vượt giới hạn bộ nhớ của extension.")
                            .font(.footnote)
                            .foregroundStyle(Theme.warn)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Toggle(isOn: Binding(
                get: { rule.enabled },
                set: { store.setEnabled(rule.id, $0) }
            )) {
                Text("Bật")
            }
            .labelsHidden()
            .accessibilityLabel(rule.enabled ? "Tắt quy tắc \(rule.rawInput)" : "Bật quy tắc \(rule.rawInput)")
        }
        .opacity(rule.enabled ? 1 : 0.55)
        .padding(.vertical, 4)
    }

    private func detail(rule: BlockRule, estimate: RuleEstimate?) -> String {
        let count = Vietnamese.count(estimate?.count ?? 0)
        switch rule.kind {
        case .prefix:
            return "\(rule.pattern) · \(count) số · đủ \(rule.targetLength) chữ số"
        case .fullNumber:
            return "\(rule.pattern) · \(count) số"
        }
    }

    private func exportRules() {
        do {
            exportPayload = ExportPayload(url: try store.exportFileURL())
        } catch {
            store.banner = .error("Không xuất được file. \(error.localizedDescription)")
        }
    }

    private func importFile(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            store.banner = .error("Không mở được file. \(error.localizedDescription)")
        case .success(let url):
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([BlockRule].self, from: data)
                if store.rules.isEmpty {
                    store.replaceAll(with: decoded)
                } else {
                    pendingImport = decoded
                }
            } catch {
                store.banner = .error("File không phải danh sách quy tắc của app này.")
            }
        }
    }
}

private struct StorageNotice: View {
    let reason: LocalOnlyReason
    let groupID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Chưa chặn được cuộc gọi")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if SharedConfig.isConfigured(groupID) {
                Text(groupID)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 4)
    }

    private var message: String {
        switch reason {
        case .turnedOffInBuild:
            return "Bản cài này tắt App Group để ký được bằng Personal Team. Quy tắc lưu trên máy, extension không đọc được. Chi tiết ở tab Hướng dẫn."
        case .containerUnavailable:
            return "Bản build đã bật App Group nhưng iOS không mở được container. Kiểm tra capability của cả app và extension, đúng ID bên dưới, rồi cài lại."
        case .missingConfiguration:
            return "Chưa đọc được APP_GROUP_ID. Kiểm tra Config/Signing.xcconfig rồi build lại."
        }
    }
}

private struct NoticeText: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(tint)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 2)
    }
}

private extension RuleStore.Banner {
    var text: String {
        switch self {
        case .error(let value), .success(let value), .warning(let value):
            return value
        }
    }

    var tint: Color {
        switch self {
        case .error:
            return Theme.seal
        case .success:
            return Theme.ok
        case .warning:
            return Theme.warn
        }
    }
}
