import BlockerCore
import SwiftUI

enum BlockNumberRoute: Identifiable {
    case create(prefill: String)
    case edit(UUID)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let identifier): return identifier.uuidString
        }
    }
}

/// The one place a number is added or changed. The user types a number; the sheet
/// works out whether that is one number or a whole range and shows the result live.
struct BlockNumberSheet: View {
    @EnvironmentObject private var store: RuleStore
    @Environment(\.dismiss) private var dismiss
    let route: BlockNumberRoute
    /// False in the screenshot demo so the keyboard does not cover the sheet.
    var focusOnAppear = true

    @State private var rawInput = ""
    @State private var note = ""
    @State private var enabled = true
    @State private var kindOverride: RuleKind?
    @State private var lengthOverride: Int?
    @State private var didLoad = false
    @FocusState private var numberFocused: Bool

    private var editingID: UUID? {
        if case .edit(let identifier) = route { return identifier }
        return nil
    }

    private var reading: InputReading {
        NumberInput.interpret(rawInput, kind: kindOverride, targetLength: lengthOverride)
    }

    private var combined: BlocklistBuild? {
        let reading = reading
        guard reading.preview.error == nil, let pattern = reading.preview.normalized else { return nil }
        let rule = BlockRule(id: editingID ?? UUID(), kind: reading.kind, rawInput: rawInput, pattern: pattern,
                             targetLength: reading.targetLength, enabled: enabled, note: note)
        var next = store.rules.filter { $0.id != editingID }
        next.append(rule)
        return BlocklistBuild.evaluate(rules: next)
    }

    private var listWouldBeFull: Bool { enabled && combined?.hardCapExceeded == true }
    private var canSave: Bool { reading.preview.canSave && !listWouldBeFull }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    label("Số điện thoại hoặc đầu số")
                    numberField
                    liveCard
                    label("Ghi chú").padding(.top, 8)
                    TextField("Ví dụ: spam vay tiền", text: $note)
                        .font(Theme.font(.body))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 56)
                        .background(Theme.field, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
                    Toggle("Chặn ngay", isOn: $enabled)
                        .font(Theme.font(.body, weight: .semibold))
                        .tint(Theme.accent)
                        .padding(.top, 8)
                    advanced
                }
                .padding(20)
            }
            .background(Theme.sheet.ignoresSafeArea())
            .navigationTitle(editingID == nil ? "Chặn số" : "Sửa số chặn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Text(editingID == nil ? "Chặn" : "Lưu")
                        .font(Theme.font(.headline, weight: .heavy))
                        .frame(maxWidth: .infinity, minHeight: Theme.Size.buttonHeight)
                        .foregroundStyle(canSave ? Theme.onAccent : Theme.muted)
                        .background(canSave ? Theme.accent : Theme.field, in: Capsule())
                }
                .buttonStyle(PressableStyle())
                .disabled(!canSave)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .background(Theme.sheet)
            }
            .onAppear(perform: load)
        }
        .tint(Theme.protectedText)
        .presentationDetents([.large])
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(.subheadline))
            .foregroundStyle(Theme.muted)
    }

    private var numberField: some View {
        HStack(spacing: 8) {
            TextField("Ví dụ 028 888 hoặc 090 123 4567", text: $rawInput)
                .font(Theme.font(.title2, weight: .heavy))
                .keyboardType(.phonePad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($numberFocused)
                .accessibilityLabel("Số điện thoại hoặc đầu số")
            PasteButton(payloadType: String.self) { strings in
                if let first = strings.first { rawInput = first.trimmingCharacters(in: .whitespacesAndNewlines) }
            }
            .labelStyle(.titleOnly)
            .buttonBorderShape(.capsule)
            .tint(Theme.accent)
        }
        .padding(.leading, 16)
        .padding(.trailing, 10)
        .frame(minHeight: 60)
        .background(Theme.field, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
    }

    @ViewBuilder
    private var liveCard: some View {
        let reading = reading
        let result = Self.describe(reading, input: rawInput)
        VStack(alignment: .leading, spacing: 4) {
            if let title = result.title {
                Text(title)
                    .font(Theme.font(.headline, weight: .heavy))
                    .foregroundStyle(result.isValid ? Theme.okInk : Theme.ink)
            }
            Text(result.message)
                .font(Theme.font(.subheadline))
                .foregroundStyle(result.isError ? Theme.warnText : (result.isValid ? Theme.okInk : Theme.muted))
            if result.isValid, reading.preview.reachesSoftCap {
                Text("Dải số này rất lớn. Thêm chữ số để chặn chắc hơn.")
                    .font(Theme.font(.footnote))
                    .foregroundStyle(Theme.warnText)
            }
            if let combined, listWouldBeFull {
                Text(Vietnamese.hardCapMessage(count: combined.mergedCount))
                    .font(Theme.font(.footnote))
                    .foregroundStyle(Theme.warnText)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(result.isValid ? Theme.okBg : Theme.field, in: RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var advanced: some View {
        DisclosureGroup("Nâng cao") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Cách chặn", selection: $kindOverride) {
                    Text("Tự nhận").tag(RuleKind?.none)
                    Text("Một số").tag(RuleKind?.some(.fullNumber))
                    Text("Cả dải số").tag(RuleKind?.some(.prefix))
                }
                .pickerStyle(.segmented)
                if reading.kind == .prefix {
                    Stepper(
                        "Số đầy đủ dài \(reading.targetLength - 1) chữ số",
                        value: Binding(get: { reading.targetLength }, set: { lengthOverride = $0 }),
                        in: Limits.minimumTargetLength...Limits.maximumTargetLength
                    )
                    Text("Tự nhận theo đầu số: số bàn 11 chữ số, di động 10. Chỉ đổi khi số bạn muốn chặn có độ dài khác.")
                        .font(Theme.font(.footnote))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 8)
        }
        .font(Theme.font(.subheadline, weight: .semibold))
        .padding(.top, 8)
    }

    struct LiveResult: Equatable {
        var title: String?
        var message: String
        var isValid: Bool
        var isError: Bool
    }

    /// Turns a reading into the two lines under the field.
    static func describe(_ reading: InputReading, input: String) -> LiveResult {
        let preview = reading.preview
        if case .normalization(.empty)? = preview.error {
            return LiveResult(title: "Nhập số bạn muốn chặn.", message: "Một số đầy đủ, hoặc ít nhất 6 số đầu để chặn cả dải số.", isValid: false, isError: false)
        }
        if let error = preview.error {
            return LiveResult(title: nil, message: Vietnamese.message(for: error), isValid: false, isError: true)
        }
        guard let pattern = preview.normalized, let count = preview.count else {
            return LiveResult(title: nil, message: Vietnamese.message(for: NormalizeError.empty), isValid: false, isError: false)
        }
        let name = NumberDisplay.formatted(pattern: pattern)
        if reading.kind == .fullNumber {
            return LiveResult(title: "Sẽ chặn 1 số: \(name)", message: "Chỉ chặn đúng số này.", isValid: true, isError: false)
        }
        var message = "Mọi số bắt đầu bằng \(name)"
        if let first = preview.first, let last = preview.last {
            message += ", từ \(NumberDisplay.formatted(number: first)) đến \(NumberDisplay.formatted(number: last))"
        }
        return LiveResult(title: "Sẽ chặn \(Vietnamese.count(count)) số", message: message + ".", isValid: true, isError: false)
    }

    private func load() {
        guard !didLoad else { return }
        didLoad = true
        switch route {
        case .create(let prefill):
            rawInput = prefill
        case .edit(let identifier):
            guard let rule = store.rules.first(where: { $0.id == identifier }) else { break }
            rawInput = rule.rawInput
            enabled = rule.enabled
            note = rule.note
            // Keep what was stored when it differs from what detection would pick today.
            let detected = NumberInput.interpret(rule.rawInput)
            if detected.kind != rule.kind { kindOverride = rule.kind }
            if rule.kind == .prefix, detected.targetLength != rule.targetLength { lengthOverride = rule.targetLength }
        }
        if focusOnAppear { numberFocused = true }
    }

    private func save() {
        let reading = reading
        let result = RuleFactory.make(id: editingID ?? UUID(), kind: reading.kind, rawInput: rawInput,
                                      targetLength: reading.targetLength, enabled: enabled, note: note)
        switch result {
        case .failure(let error):
            store.banner = .error(Vietnamese.message(for: error))
        case .success(let rule):
            guard !listWouldBeFull else {
                store.banner = .error(Vietnamese.hardCapMessage(count: combined?.mergedCount ?? 0))
                return
            }
            store.upsert(rule)
            dismiss()
        }
    }
}
