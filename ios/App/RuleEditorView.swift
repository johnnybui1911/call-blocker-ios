import BlockerCore
import SwiftUI

struct RuleEditorView: View {
    @EnvironmentObject private var store: RuleStore
    @Environment(\.dismiss) private var dismiss

    let route: RuleEditorRoute

    @State private var kind: RuleKind = .prefix
    @State private var rawInput = ""
    @State private var targetLength = Limits.defaultTargetLength
    @State private var enabled = true
    @State private var note = ""
    @State private var didLoad = false

    private var editingID: UUID? {
        if case .edit(let identifier) = route { return identifier }
        return nil
    }

    private var preview: DraftPreview {
        RuleFactory.preview(kind: kind, rawInput: rawInput, targetLength: targetLength)
    }

    private var combined: BlocklistBuild? {
        guard preview.error == nil, let pattern = preview.normalized else { return nil }
        let rule = BlockRule(
            id: editingID ?? UUID(),
            kind: kind,
            rawInput: rawInput,
            pattern: pattern,
            targetLength: targetLength,
            enabled: enabled,
            note: note
        )
        var next = store.rules.filter { $0.id != editingID }
        next.append(rule)
        return BlocklistBuild.evaluate(rules: next)
    }

    private var combinedExceedsHardCap: Bool {
        guard enabled else { return false }
        return combined?.hardCapExceeded == true
    }

    private var canSave: Bool {
        preview.canSave && !combinedExceedsHardCap
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Loại", selection: $kind) {
                        Text("Đầu số").tag(RuleKind.prefix)
                        Text("Số đầy đủ").tag(RuleKind.fullNumber)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(kind == .prefix
                         ? "Mọi số có đầu này, sau khi chuẩn hóa, sẽ bị chặn."
                         : "Chỉ đúng một số, sau khi chuẩn hóa sang E.164.")
                }

                Section {
                    TextField("0…, 84… hoặc +84…", text: $rawInput)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if let normalized = preview.normalized {
                        Text("Chuẩn hóa: \(normalized)")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                    }
                } header: {
                    Text("Số")
                } footer: {
                    if let error = preview.error {
                        Text(Vietnamese.message(for: error))
                            .foregroundStyle(Theme.seal)
                    }
                }

                if kind == .prefix {
                    Section {
                        Stepper(value: $targetLength, in: Limits.minimumTargetLength...Limits.maximumTargetLength) {
                            Text("Độ dài E.164: \(targetLength)")
                        }
                    } footer: {
                        Text("Mặc định \(Limits.defaultTargetLength) là số bàn Việt Nam: mã vùng kèm số 0, rồi 8 chữ số thuê bao, bỏ số 0 và thêm mã 84. Số di động thường dài 11. Hãy hạ độ dài nếu bạn chặn đầu số di động.")
                    }
                }

                Section("Ghi chú") {
                    TextField("Không bắt buộc", text: $note)
                }

                Section {
                    Toggle("Bật quy tắc này", isOn: $enabled)
                }

                Section("Ước tính") {
                    if let count = preview.count {
                        LabeledContent("Số lượng", value: Vietnamese.count(count))
                    }
                    if let first = preview.first, let last = preview.last, preview.error == nil {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Từ \(Vietnamese.digits(first))")
                            Text("Đến \(Vietnamese.digits(last))")
                        }
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                    }
                    if preview.reachesSoftCap && preview.error == nil {
                        Text(Vietnamese.softCapMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.warn)
                    }
                    if let combined, combined.hardCapExceeded, enabled {
                        Text(Vietnamese.hardCapMessage(count: combined.mergedCount))
                            .font(.footnote)
                            .foregroundStyle(Theme.seal)
                    }
                }
            }
            .navigationTitle(editingID == nil ? "Thêm quy tắc" : "Sửa quy tắc")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
        .presentationDetents([.large])
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        guard let editingID, let rule = store.rules.first(where: { $0.id == editingID }) else { return }
        kind = rule.kind
        rawInput = rule.rawInput
        targetLength = rule.targetLength
        enabled = rule.enabled
        note = rule.note
    }

    private func save() {
        let result = RuleFactory.make(
            id: editingID ?? UUID(),
            kind: kind,
            rawInput: rawInput,
            targetLength: targetLength,
            enabled: enabled,
            note: note
        )
        switch result {
        case .failure(let error):
            store.banner = .error(Vietnamese.message(for: error))
        case .success(let rule):
            guard !combinedExceedsHardCap else {
                store.banner = .error(Vietnamese.hardCapMessage(count: combined?.mergedCount ?? 0))
                return
            }
            store.upsert(rule)
            dismiss()
        }
    }
}

enum RuleEditorRoute: Identifiable {
    case create
    case edit(UUID)

    var id: String {
        switch self {
        case .create:
            return "create"
        case .edit(let identifier):
            return identifier.uuidString
        }
    }
}
